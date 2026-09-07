import PDFKit
import UIKit
import Combine

/// Central presentation state for the PDF viewer.
/// Owns document lifecycle, page state, bookmarks, search, and navigation commands.
/// Does not hold a direct reference to PDFView — commands flow through PDFViewing protocol.
@MainActor
final class PDFViewerViewModel: ObservableObject {

    // MARK: - Published State

    @Published private(set) var loadingState: PDFViewerLoadingState = .idle
    @Published private(set) var currentPageIndex: Int = 0
    @Published private(set) var pageCount: Int = 0
    @Published private(set) var bookmarks: [PDFViewerBookmark] = []
    @Published private(set) var isCurrentPageBookmarked: Bool = false
    @Published var scrollDirection: PDFViewerScrollDirection
    @Published var displayMode: PDFViewerDisplayMode
    @Published var searchText: String = ""
    @Published private(set) var searchResults: [PDFSearchResult] = []
    @Published private(set) var currentSearchResultIndex: Int = 0
    @Published private(set) var isSearching: Bool = false
    @Published private(set) var outlineItems: [PDFOutlineItem] = []
    @Published private(set) var hasOutline: Bool = false
    @Published private(set) var documentMetadata: PDFDocumentMetadata?
    @Published private(set) var documentTitle: String = ""
    @Published var showPasswordPrompt: Bool = false
    @Published var passwordError: String? = nil

    // MARK: - Dependencies

    private let loader: PDFDocumentLoading
    private let bookmarkStore: PDFBookmarkStoring
    private let lastPageStore: PDFLastPageStoring?
    private(set) var document: PDFDocument?
    private(set) var documentIdentifier: String = ""
    private var loadedFileURL: URL?
    weak var controller: PDFViewing?
    private let configuration: PDFViewerConfiguration
    weak var delegate: PDFViewerDelegate?

    // MARK: - Private

    private var searchCancellable: AnyCancellable?
    private var pendingFileURL: URL?

    // MARK: - Init

    init(
        configuration: PDFViewerConfiguration,
        loader: PDFDocumentLoading = PDFDocumentLoader(),
        bookmarkStore: PDFBookmarkStoring = UserDefaultsPDFBookmarkStore(),
        lastPageStore: PDFLastPageStoring? = nil,
        delegate: PDFViewerDelegate? = nil
    ) {
        self.configuration = configuration
        self.loader = loader
        self.bookmarkStore = bookmarkStore
        self.lastPageStore = lastPageStore
        self.delegate = delegate
        self.scrollDirection = configuration.behavior.initialScrollDirection
        self.displayMode = configuration.behavior.initialDisplayMode
    }

    // MARK: - Document Loading

    func load(from url: URL) {
        loadingState = .loading
        pendingFileURL = url
        loadedFileURL = url
        documentIdentifier = configuration.documentIdentifier ?? url.standardizedFileURL.absoluteString

        switch loader.load(from: url) {
        case .success(let doc):
            if doc.isLocked {
                document = doc
                loadingState = .passwordRequired
                showPasswordPrompt = true
            } else {
                finalizeLoad(doc)
            }
        case .failure(let error):
            loadingState = .failed(error)
            delegate?.pdfViewerDidFail?(withError: error.asNSError)
        }
    }

    func submitPassword(_ password: String) {
        guard let doc = document else { return }
        if doc.unlock(withPassword: password) {
            showPasswordPrompt = false
            passwordError = nil
            finalizeLoad(doc)
        } else {
            passwordError = configuration.strings.invalidPage
            delegate?.pdfViewerDidFail?(withError: PDFViewerError.incorrectPassword.asNSError)
        }
    }

    private func finalizeLoad(_ doc: PDFDocument) {
        document = doc
        pageCount = doc.pageCount
        loadingState = .loaded

        let behavior = configuration.behavior
        let targetIndex: Int
        if configuration.features.restoresLastViewedPage,
           let stored = lastPageStore?.lastPage(for: documentIdentifier) {
            targetIndex = min(stored, pageCount - 1)
        } else {
            targetIndex = min(max(0, behavior.initialPage - 1), pageCount - 1)
        }
        currentPageIndex = targetIndex

        loadBookmarks()
        buildOutline(from: doc)
        buildMetadata(from: doc)
        resolveDocumentTitle(from: doc)
        delegate?.pdfViewerDidOpenDocument?()
    }

    // MARK: - Page Navigation

    func goToNextPage() {
        guard currentPageIndex < pageCount - 1 else { return }
        controller?.goToNextPage()
    }

    func goToPreviousPage() {
        guard currentPageIndex > 0 else { return }
        controller?.goToPreviousPage()
    }

    func goToFirstPage() {
        controller?.goToFirstPage()
    }

    func goToLastPage() {
        controller?.goToLastPage()
    }

    /// Validates and navigates to a one-based user-facing page number.
    func goToPage(_ oneBased: Int) -> Bool {
        let index = oneBased - 1
        guard index >= 0, index < pageCount else { return false }
        controller?.go(toPageIndex: index)
        return true
    }

    /// Called by the Coordinator when PDFView reports a page change.
    func updateCurrentPage(to index: Int) {
        guard index != currentPageIndex else { return }
        currentPageIndex = index
        updateBookmarkState()
        lastPageStore?.save(lastPage: index, for: documentIdentifier)
        delegate?.pdfViewerDidChangePage?(index + 1, totalPages: pageCount)
    }

    // MARK: - Bookmarks

    func toggleBookmark() {
        if isCurrentPageBookmarked {
            removeBookmarkForCurrentPage()
        } else {
            addBookmarkForCurrentPage()
        }
    }

    func addBookmarkForCurrentPage() {
        let bookmark = PDFViewerBookmark(
            documentIdentifier: documentIdentifier,
            pageIndex: currentPageIndex,
            pageLabel: document?.page(at: currentPageIndex)?.label
        )
        bookmarkStore.save(bookmark)
        loadBookmarks()
        delegate?.pdfViewerDidAddBookmark?(atPage: currentPageIndex + 1)
    }

    func removeBookmarkForCurrentPage() {
        guard let existing = bookmarks.first(where: { $0.pageIndex == currentPageIndex }) else { return }
        bookmarkStore.remove(existing)
        loadBookmarks()
        delegate?.pdfViewerDidRemoveBookmark?(atPage: currentPageIndex + 1)
    }

    func navigate(to bookmark: PDFViewerBookmark) {
        controller?.go(toPageIndex: bookmark.pageIndex)
    }

    func remove(bookmark: PDFViewerBookmark) {
        bookmarkStore.remove(bookmark)
        loadBookmarks()
    }

    private func loadBookmarks() {
        bookmarks = bookmarkStore.bookmarks(for: documentIdentifier)
            .sorted { $0.pageIndex < $1.pageIndex }
        updateBookmarkState()
    }

    private func updateBookmarkState() {
        isCurrentPageBookmarked = bookmarks.contains { $0.pageIndex == currentPageIndex }
    }

    // MARK: - Scroll Direction

    func changeScrollDirection(to direction: PDFViewerScrollDirection) {
        scrollDirection = direction
        controller?.setScrollDirection(direction)
    }

    func changeDisplayMode(to mode: PDFViewerDisplayMode) {
        displayMode = mode
        controller?.setDisplayMode(mode)
    }

    // MARK: - Zoom

    func zoomIn() { controller?.zoomIn() }
    func zoomOut() { controller?.zoomOut() }
    func resetZoom() { controller?.resetZoom() }

    // MARK: - History

    var canGoBack: Bool { controller?.canGoBack ?? false }
    var canGoForward: Bool { controller?.canGoForward ?? false }
    func goBack() { controller?.goBack() }
    func goForward() { controller?.goForward() }

    // MARK: - Search

    /// Runs findString on a background thread, groups matches by page, then updates state.
    func performSearch() {
        guard let doc = document, !searchText.trimmingCharacters(in: .whitespaces).isEmpty else {
            clearSearch()
            return
        }
        isSearching = true
        searchResults = []

        let query = searchText
        let docRef = doc
        Task.detached(priority: .userInitiated) { [weak self] in
            let allSelections = docRef.findString(query, withOptions: .caseInsensitive)

            // Group individual selections by page index, preserving page order.
            var byPage: [Int: [PDFSelection]] = [:]
            for selection in allSelections {
                guard let page = selection.pages.first else { continue }
                let idx = docRef.index(for: page)
                byPage[idx, default: []].append(selection)
            }
            let grouped: [PDFSearchResult] = byPage.keys.sorted().map { idx in
                PDFSearchResult(pageIndex: idx, selections: byPage[idx]!)
            }

            await MainActor.run {
                self?.searchResults = grouped
                self?.isSearching = false
            }
        }
    }

    /// Navigates to the tapped page result, highlights every occurrence on the document,
    /// then automatically clears highlights after 2.5 seconds.
    func navigateToSearchResult(_ result: PDFSearchResult) {
        let allSelections = searchResults.flatMap { $0.selections }
        controller?.highlightAll(selections: allSelections, goToPageIndex: result.pageIndex)
        scheduleHighlightClear()
    }

    func clearSearch() {
        searchText = ""
        searchResults = []
        isSearching = false
        controller?.clearHighlights()
    }

    private func scheduleHighlightClear() {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            controller?.clearHighlights()
        }
    }

    private func clearSearchResults() {
        searchResults = []
        isSearching = false
    }

    // MARK: - Outline

    private func buildOutline(from doc: PDFDocument) {
        guard let root = doc.outlineRoot else {
            hasOutline = false
            outlineItems = []
            return
        }
        var items: [PDFOutlineItem] = []
        for i in 0..<root.numberOfChildren {
            if let child = root.child(at: i) {
                items.append(PDFOutlineItem.build(from: child, document: doc))
            }
        }
        outlineItems = items
        hasOutline = !items.isEmpty
    }

    func navigate(to outlineItem: PDFOutlineItem) {
        guard let index = outlineItem.pageIndex else { return }
        controller?.go(toPageIndex: index)
    }

    // MARK: - Metadata

    private func buildMetadata(from doc: PDFDocument) {
        documentMetadata = PDFDocumentMetadata(
            title: doc.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String,
            author: doc.documentAttributes?[PDFDocumentAttribute.authorAttribute] as? String,
            subject: doc.documentAttributes?[PDFDocumentAttribute.subjectAttribute] as? String,
            creator: doc.documentAttributes?[PDFDocumentAttribute.creatorAttribute] as? String,
            pageCount: doc.pageCount
        )
    }

    private func resolveDocumentTitle(from doc: PDFDocument) {
        // Prefer the embedded PDF title; fall back to the filename without extension.
        if let pdfTitle = doc.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String,
           !pdfTitle.trimmingCharacters(in: .whitespaces).isEmpty {
            documentTitle = pdfTitle
        } else {
            documentTitle = loadedFileURL?.deletingPathExtension().lastPathComponent ?? ""
        }
    }

    // MARK: - Close

    func requestClose() {
        delegate?.pdfViewerDidClose?()
    }

    // MARK: - Internal

    func attachController(_ controller: PDFViewing) {
        self.controller = controller
    }

    // MARK: - Computed

    var displayPageNumber: Int { currentPageIndex + 1 }
    var canGoToPreviousPage: Bool { currentPageIndex > 0 }
    var canGoToNextPage: Bool { currentPageIndex < pageCount - 1 }
}

// MARK: - Supporting Types

struct PDFDocumentMetadata {
    let title: String?
    let author: String?
    let subject: String?
    let creator: String?
    let pageCount: Int
}
