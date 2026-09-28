import SwiftUI
import PDFKit
import Combine

/// Browses page thumbnails. In view mode, tapping a page navigates to it. In edit mode, pages can be
/// reordered and removed; Save writes the changes to the working PDF and Reset restores the original.
struct PDFThumbnailBrowser: View {

    let document: PDFDocument
    @ObservedObject var viewModel: PDFViewerViewModel
    let strings: PDFViewerStrings
    @Binding var isPresented: Bool
    let allowEditing: Bool

    @StateObject private var cache = PDFThumbnailCache()
    @State private var editMode: EditMode = .inactive
    @State private var pages: [EditablePage] = []
    @State private var showSaveConfirmation = false
    @State private var showResetConfirmation = false
    @State private var errorMessage: String?
    @State private var isSaving = false

    private var isEditing: Bool { editMode.isEditing }
    private let columns = [GridItem(.adaptive(minimum: 100, maximum: 140))]

    var body: some View {
        ZStack {
            navigationContent
            if isSaving {
                savingOverlay
            }
        }
    }

    private var navigationContent: some View {
        NavigationView {
            Group {
                if isEditing {
                    editList
                } else {
                    thumbnailGrid
                }
            }
            .navigationTitle(isEditing ? strings.editPages : strings.thumbnails)
            .navigationBarTitleDisplayMode(.inline)
            .environment(\.editMode, $editMode)
            .toolbar { toolbarContent }
            .alert(strings.saveChangesTitle, isPresented: $showSaveConfirmation) {
                Button(strings.cancel, role: .cancel) {}
                Button(strings.save) { performSave() }
            } message: {
                Text(strings.saveChangesMessage)
            }
            .alert(strings.resetChangesTitle, isPresented: $showResetConfirmation) {
                Button(strings.cancel, role: .cancel) {}
                Button(strings.reset, role: .destructive) { performReset() }
            } message: {
                Text(strings.resetChangesMessage)
            }
            .alert(
                errorMessage ?? "",
                isPresented: Binding(
                    get: { errorMessage != nil },
                    set: { if !$0 { errorMessage = nil } }
                )
            ) {
                Button(strings.done, role: .cancel) {}
            }
        }
        .onAppear {
            rebuildPages()
            // Warm the cache so drag previews render immediately in edit mode.
            cache.preload(pageCount: document.pageCount, in: document)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            if isEditing {
                Button(strings.cancel) {
                    rebuildPages()
                    withAnimation { editMode = .inactive }
                }
            } else {
                Button(strings.done) { isPresented = false }
            }
        }

        ToolbarItem(placement: .primaryAction) {
            if isEditing {
                Button(strings.save) { showSaveConfirmation = true }
                    .disabled(pages.isEmpty)
            } else if allowEditing {
                Button(strings.edit) {
                    withAnimation { editMode = .active }
                }
            }
        }

        if isEditing {
            ToolbarItem(placement: .bottomBar) {
                Button(role: .destructive) {
                    showResetConfirmation = true
                } label: {
                    Label(strings.reset, systemImage: "arrow.counterclockwise")
                }
            }
        }
    }

    // MARK: - View Mode Grid

    private var thumbnailGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(0..<document.pageCount, id: \.self) { index in
                    Button {
                        viewModel.controller?.go(toPageIndex: index)
                        isPresented = false
                    } label: {
                        VStack(spacing: 6) {
                            CachedThumbnail(cache: cache, document: document, index: index)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(
                                            viewModel.currentPageIndex == index ? Color.accentColor : Color.clear,
                                            lineWidth: 2
                                        )
                                )
                            Text("\(index + 1)")
                                .font(.caption2)
                                .foregroundColor(viewModel.currentPageIndex == index ? .accentColor : .secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(strings.page) \(index + 1)")
                }
            }
            .padding()
        }
    }

    // MARK: - Edit Mode List

    private var editList: some View {
        List {
            ForEach(pages) { page in
                HStack(spacing: 12) {
                    CachedThumbnail(cache: cache, document: document, index: page.originalIndex)
                        .frame(width: 46, height: 60)
                    Text("\(strings.page) \(page.originalIndex + 1)")
                        .font(.body)
                    Spacer()
                }
                .padding(.vertical, 4)
                .contentShape(Rectangle())
            }
            .onMove { indices, newOffset in
                pages.move(fromOffsets: indices, toOffset: newOffset)
            }
            .onDelete { offsets in
                removePages(at: offsets)
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Actions

    private func rebuildPages() {
        pages = (0..<document.pageCount).map { EditablePage(originalIndex: $0) }
    }

    private func removePages(at offsets: IndexSet) {
        guard pages.count - offsets.count >= 1 else {
            errorMessage = strings.minOnePage
            return
        }
        pages.remove(atOffsets: offsets)
    }

    private func performSave() {
        let order = pages.map { $0.originalIndex }
        isSaving = true
        Task {
            let success = await viewModel.applyPageEdits(orderedOriginalIndices: order)
            isSaving = false
            if success {
                editMode = .inactive
                isPresented = false
            } else {
                errorMessage = strings.saveFailed
            }
        }
    }

    private func performReset() {
        if viewModel.resetToOriginal() {
            editMode = .inactive
            isPresented = false
        } else {
            errorMessage = strings.resetFailed
        }
    }

    // MARK: - Saving Overlay

    private var savingOverlay: some View {
        ZStack {
            Color.black.opacity(0.25)
                .ignoresSafeArea()
            VStack(spacing: 14) {
                ProgressView()
                    .scaleEffect(1.3)
                Text(strings.saving)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(28)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        }
        .transition(.opacity)
    }
}

/// A page entry in the edit list. Identity is stable across reordering; originalIndex maps back to
/// the source document's page.
private struct EditablePage: Identifiable {
    let id = UUID()
    let originalIndex: Int
}

// MARK: - Thumbnail Cache

/// Renders and memoizes page thumbnails on a background queue so rows appear instantly and provide a
/// proper drag preview during reordering.
@MainActor
private final class PDFThumbnailCache: ObservableObject {

    @Published private(set) var images: [Int: UIImage] = [:]
    private var inFlight: Set<Int> = []
    private let renderSize = CGSize(width: 220, height: 300)

    func requestThumbnail(for index: Int, in document: PDFDocument) {
        guard images[index] == nil, !inFlight.contains(index),
              let page = document.page(at: index) else { return }
        inFlight.insert(index)
        let size = renderSize
        Task.detached(priority: .userInitiated) {
            let image = page.thumbnail(of: size, for: .cropBox)
            await MainActor.run {
                self.images[index] = image
                self.inFlight.remove(index)
            }
        }
    }

    func preload(pageCount: Int, in document: PDFDocument) {
        for index in 0..<pageCount {
            requestThumbnail(for: index, in: document)
        }
    }
}

/// Displays a cached thumbnail, requesting a render the first time it appears.
private struct CachedThumbnail: View {

    @ObservedObject var cache: PDFThumbnailCache
    let document: PDFDocument
    let index: Int

    var body: some View {
        ZStack {
            if let image = cache.images[index] {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(4)
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.secondarySystemBackground))
                    .aspectRatio(0.75, contentMode: .fit)
                ProgressView()
            }
        }
        .onAppear { cache.requestThumbnail(for: index, in: document) }
    }
}
