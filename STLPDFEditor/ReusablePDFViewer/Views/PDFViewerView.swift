import SwiftUI
import PDFKit

/// Root SwiftUI view for the PDF viewer module.
/// Instantiate directly from SwiftUI, or wrap via PDFViewerLauncher for UIKit/Obj-C.
public struct PDFViewerView: View {

    private let fileURL: URL
    private let configuration: PDFViewerConfiguration
    @StateObject private var viewModel: PDFViewerViewModel
    @Environment(\.dismiss) private var dismiss

    // MARK: - Sheet State

    @State private var showBookmarks = false
    @State private var showSearch = false
    @State private var showThumbnails = false
    @State private var showOutline = false
    @State private var showGoToPage = false
    @State private var showDocumentInfo = false
    @State private var showShare = false

    public init(
        fileURL: URL,
        configuration: PDFViewerConfiguration = .default,
        delegate: PDFViewerDelegate? = nil
    ) {
        self.fileURL = fileURL
        self.configuration = configuration
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
                Color.clear.onAppear { viewModel.load(from: fileURL) }

            case .loading:
                VStack(spacing: 12) {
                    ProgressView()
                    Text(configuration.strings.loading)
                        .foregroundColor(.secondary)
                }

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
                PDFThumbnailBrowser(document: document, viewModel: viewModel, strings: configuration.strings, isPresented: $showThumbnails)
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
            ActivitySheet(items: [fileURL])
        }
        // Propagates theme color to all SwiftUI interactive controls in the subtree:
        // buttons, selected list rows, progress indicators, etc.
        .tint(Color(configuration.theme.primaryColor))
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
                onClose: {
                    viewModel.requestClose()
                    dismiss()
                }
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
