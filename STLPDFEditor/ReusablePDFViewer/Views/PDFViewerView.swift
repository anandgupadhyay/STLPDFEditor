import SwiftUI
import PDFKit

/// Root SwiftUI view for the PDF viewer module.
/// Instantiate directly from SwiftUI, or wrap via PDFViewerLauncher for UIKit/Obj-C.
public struct PDFViewerView: View {

    private let configuration: PDFViewerConfiguration
    @StateObject private var viewModel: PDFViewerViewModel
    @ObservedObject private var session: PDFViewerSession
    @Environment(\.dismiss) private var dismiss

    /// URL of the document currently displayed. Changes when the user reopens a recent document.
    @State private var currentURL: URL

    /// Whether the current document has been seen in the session list. Prevents a premature
    /// dismissal before the document finishes registering on first load.
    @State private var currentIsTracked = false

    /// Index of the active document within the session list, used to choose the next document
    /// to display when the current one is closed.
    @State private var lastKnownIndex: Int?

    /// Optional external dismissal (used when hosted in UIKit/Objective-C, where SwiftUI's
    /// own dismiss environment cannot dismiss a manually presented hosting controller).
    private var onRequestDismiss: (() -> Void)?

    // MARK: - Sheet State

    @State private var showBookmarks = false
    @State private var showSearch = false
    @State private var showThumbnails = false
    @State private var showOutline = false
    @State private var showGoToPage = false
    @State private var showDocumentInfo = false
    @State private var showShare = false
    @State private var showRecents = false

    public init(
        fileURL: URL,
        configuration: PDFViewerConfiguration = .default,
        delegate: PDFViewerDelegate? = nil
    ) {
        self.configuration = configuration
        _currentURL = State(initialValue: fileURL)
        _session = ObservedObject(wrappedValue: .shared)
        _viewModel = StateObject(
            wrappedValue: PDFViewerViewModel(
                configuration: configuration,
                delegate: delegate
            )
        )
    }

    public var body: some View {
        ZStack {
            Color(configuration.theme.backgroundColor)
                .ignoresSafeArea()


            switch viewModel.loadingState {
            case .idle:
                Color.clear.onAppear { viewModel.load(from: currentURL) }

            case .loading:
                loadingView

            case .loaded:
                if let document = viewModel.document {
                    loadedView(document: document)
                }

            case .passwordRequired:
                PDFPasswordView(viewModel: viewModel, strings: configuration.strings)

            case .failed(let error):
                PDFErrorView(error: error, strings: configuration.strings)
            }
        }
        .sheet(isPresented: $showBookmarks) {
            PDFBookmarkListView(viewModel: viewModel, strings: configuration.strings, isPresented: $showBookmarks)
        }
        .sheet(isPresented: $showSearch) {
            PDFSearchView(viewModel: viewModel, strings: configuration.strings, isPresented: $showSearch)
        }
        .sheet(isPresented: $showThumbnails) {
            if let document = viewModel.document {
                PDFThumbnailBrowser(document: document, viewModel: viewModel, strings: configuration.strings, isPresented: $showThumbnails, allowEditing: configuration.features.pageEditing)
            }
        }
        .sheet(isPresented: $showOutline) {
            PDFOutlineView(viewModel: viewModel, strings: configuration.strings, isPresented: $showOutline)
        }
        .sheet(isPresented: $showGoToPage) {
            PDFGoToPageView(viewModel: viewModel, strings: configuration.strings, isPresented: $showGoToPage)
        }
        .sheet(isPresented: $showDocumentInfo) {
            if let metadata = viewModel.documentMetadata {
                PDFDocumentInfoView(metadata: metadata, strings: configuration.strings, isPresented: $showDocumentInfo)
            }
        }
        .sheet(isPresented: $showShare) {
            ActivitySheet(items: [currentURL])
        }
        .sheet(isPresented: $showRecents) {
            PDFRecentDocumentsView(
                session: session,
                strings: configuration.strings,
                currentURL: viewModel.activeDocumentURL ?? currentURL,
                isPresented: $showRecents,
                onSelect: { document in
                    showRecents = false
                    open(document.url)
                },
                onClose: { document in
                    // Removing from the session drives dismissal reactively (see onChange below).
                    session.remove(document)
                },
                onCloseAll: {
                    session.clear()
                }
            )
        }
        // Propagates theme color to all SwiftUI interactive controls in the subtree:
        // buttons, selected list rows, progress indicators, etc.
        .tint(Color(configuration.theme.primaryColor))
        // Reactive tracking: reacts whenever the session list changes (from the recents sheet,
        // the dashboard, or an external Objective-C call).
        .onChange(of: session.openDocuments) { documents in
            syncTracking(with: documents)
        }
        // Also re-evaluates once the active document loads, including the case where it was already
        // in the session (a dedup no-op that would not trigger the list's onChange).
        .onChange(of: viewModel.activeDocumentURL) { _ in
            syncTracking(with: session.openDocuments)
        }
    }

    /// Keeps the viewer in sync with the session list. When the document currently on screen is
    /// removed, the viewer switches to the next remaining document; if none remain, it closes.
    /// Comparison uses the session-registered URL (the stable copy), not the originally supplied URL.
    private func syncTracking(with documents: [OpenDocument]) {
        guard let activeURL = viewModel.activeDocumentURL else { return }

        if let index = documents.firstIndex(where: { $0.url == activeURL }) {
            currentIsTracked = true
            lastKnownIndex = index
            return
        }

        // The active document is no longer in the list.
        guard currentIsTracked else { return }
        currentIsTracked = false

        if documents.isEmpty {
            performClose()
        } else {
            // Switch to the document that took the closed one's place, clamped to the list bounds.
            let target = documents[min(lastKnownIndex ?? 0, documents.count - 1)]
            open(target.url)
        }
    }

    /// Reopens a different document in the current viewer without recreating it.
    private func open(_ url: URL) {
        guard url != currentURL else { return }
        currentIsTracked = false
        currentURL = url
        viewModel.load(from: url)
    }

    /// Dismisses the viewer using the external handler when hosted in UIKit, otherwise SwiftUI's own.
    /// If a sheet (e.g. the recents list) is presented, it is dismissed first so the viewer can
    /// close cleanly — iOS ignores an outer dismissal while an inner sheet is still animating.
    private func performClose() {
        if anySheetPresented {
            dismissAllSheets()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                finishClose()
            }
        } else {
            finishClose()
        }
    }

    private func finishClose() {
        viewModel.requestClose()
        if let onRequestDismiss {
            onRequestDismiss()
        } else {
            dismiss()
        }
    }

    private var anySheetPresented: Bool {
        showRecents || showBookmarks || showSearch || showThumbnails
            || showOutline || showGoToPage || showDocumentInfo || showShare
    }

    private func dismissAllSheets() {
        showRecents = false
        showBookmarks = false
        showSearch = false
        showThumbnails = false
        showOutline = false
        showGoToPage = false
        showDocumentInfo = false
        showShare = false
    }

    /// Attaches an external dismissal handler. Used by PDFViewerLauncher for UIKit/Objective-C hosting.
    func requestingDismiss(_ handler: @escaping () -> Void) -> PDFViewerView {
        var copy = self
        copy.onRequestDismiss = handler
        return copy
    }

    // MARK: - Loaded Layout

    @ViewBuilder
    private func loadedView(document: PDFDocument) -> some View {
        VStack(spacing: 0) {
            PDFViewerToolbar(
                viewModel: viewModel,
                configuration: configuration,
                showBookmarks: $showBookmarks,
                showSearch: $showSearch,
                showThumbnails: $showThumbnails,
                showOutline: $showOutline,
                showGoToPage: $showGoToPage,
                showDocumentInfo: $showDocumentInfo,
                showShare: $showShare,
                showRecents: $showRecents,
                onClose: { performClose() }
            )

            Divider()

            ZStack(alignment: .bottom) {
                PDFKitView(document: document, configuration: configuration, viewModel: viewModel)
                    .ignoresSafeArea(edges: .bottom)

                if viewModel.pageCount > 0 {
                    pageIndicatorPill
                }
            }
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.4)
            Text(configuration.strings.loading)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Floating Page Indicator

    private var pageIndicatorPill: some View {
        Button {
            if configuration.features.goToPage { showGoToPage = true }
        } label: {
            Text("\(viewModel.displayPageNumber)  \(configuration.strings.of)  \(viewModel.pageCount)")
                .font(.caption)
                .fontWeight(.semibold)
                .monospacedDigit()
                .foregroundColor(Color(configuration.theme.primaryColor))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(.regularMaterial, in: Capsule())
        }
        .buttonStyle(.plain)
        .padding(.bottom, 20)
        .accessibilityLabel("\(configuration.strings.page) \(viewModel.displayPageNumber) \(configuration.strings.of) \(viewModel.pageCount)")
    }
}

// MARK: - Share Sheet

/// UIActivityViewController wrapped for SwiftUI presentation.
private struct ActivitySheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
