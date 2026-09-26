import SwiftUI
import PDFKit

/// Browses page thumbnails. In view mode, tapping a page navigates to it. In edit mode, pages can be
/// reordered and removed; Save writes the changes to the working PDF and Reset restores the original.
struct PDFThumbnailBrowser: View {

    let document: PDFDocument
    @ObservedObject var viewModel: PDFViewerViewModel
    let strings: PDFViewerStrings
    @Binding var isPresented: Bool
    let allowEditing: Bool

    @State private var isEditing = false
    @State private var pages: [EditablePage] = []
    @State private var showSaveConfirmation = false
    @State private var showResetConfirmation = false
    @State private var errorMessage: String?

    private let columns = [GridItem(.adaptive(minimum: 100, maximum: 140))]

    var body: some View {
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
            .environment(\.editMode, .constant(isEditing ? .active : .inactive))
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
        .onAppear(perform: rebuildPages)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            if isEditing {
                Button(strings.cancel) {
                    isEditing = false
                    rebuildPages()
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
                Button(strings.edit) { isEditing = true }
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
                    ThumbnailCell(
                        document: document,
                        pageIndex: index,
                        isCurrentPage: viewModel.currentPageIndex == index,
                        strings: strings
                    ) {
                        viewModel.controller?.go(toPageIndex: index)
                        isPresented = false
                    }
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
                    PageThumbnailImage(
                        document: document,
                        pageIndex: page.originalIndex,
                        size: CGSize(width: 44, height: 58)
                    )
                    Text("\(strings.page) \(page.originalIndex + 1)")
                        .font(.body)
                    Spacer()
                }
                .padding(.vertical, 2)
            }
            .onMove { indices, newOffset in
                pages.move(fromOffsets: indices, toOffset: newOffset)
            }
            .onDelete { offsets in
                removePages(at: offsets)
            }
        }
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
        if viewModel.applyPageEdits(orderedOriginalIndices: order) {
            isEditing = false
            isPresented = false
        } else {
            errorMessage = strings.saveFailed
        }
    }

    private func performReset() {
        if viewModel.resetToOriginal() {
            isEditing = false
            isPresented = false
        } else {
            errorMessage = strings.resetFailed
        }
    }
}

/// A page entry in the edit list. Identity is stable across reordering; originalIndex maps back to
/// the source document's page.
private struct EditablePage: Identifiable {
    let id = UUID()
    let originalIndex: Int
}

// MARK: - Thumbnail Views

private struct ThumbnailCell: View {

    let document: PDFDocument
    let pageIndex: Int
    let isCurrentPage: Bool
    let strings: PDFViewerStrings
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                PageThumbnailImage(
                    document: document,
                    pageIndex: pageIndex,
                    size: CGSize(width: 120, height: 160)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(isCurrentPage ? Color.accentColor : Color.clear, lineWidth: 2)
                )

                Text("\(pageIndex + 1)")
                    .font(.caption2)
                    .foregroundColor(isCurrentPage ? .accentColor : .secondary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(strings.page) \(pageIndex + 1)")
    }
}

/// Lazily renders a single PDF page thumbnail off the main thread.
private struct PageThumbnailImage: View {

    let document: PDFDocument
    let pageIndex: Int
    let size: CGSize

    @State private var image: UIImage?

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(4)
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.secondarySystemBackground))
                    .aspectRatio(size.width / size.height, contentMode: .fit)
                ProgressView()
            }
        }
        .frame(maxWidth: size.width, maxHeight: size.height)
        .task {
            await loadThumbnail()
        }
    }

    private func loadThumbnail() async {
        guard image == nil, let page = document.page(at: pageIndex) else { return }
        let renderSize = CGSize(width: size.width * 2, height: size.height * 2)
        let rendered = await Task.detached(priority: .background) {
            page.thumbnail(of: renderSize, for: .cropBox)
        }.value
        image = rendered
    }
}
