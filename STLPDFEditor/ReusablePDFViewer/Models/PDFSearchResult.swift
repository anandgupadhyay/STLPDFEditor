import PDFKit

/// Represents all search matches found on a single PDF page.
/// Groups multiple selections so the viewer can highlight every occurrence at once.
public struct PDFSearchResult: Identifiable {
    public let id: UUID
    /// Zero-based page index.
    public let pageIndex: Int
    /// Every PDFSelection matching the query on this page.
    public let selections: [PDFSelection]

    public init(pageIndex: Int, selections: [PDFSelection]) {
        self.id = UUID()
        self.pageIndex = pageIndex
        self.selections = selections
    }

    /// One-based page number for display.
    public var displayPageNumber: Int { pageIndex + 1 }
    /// Number of keyword occurrences on this page.
    public var matchCount: Int { selections.count }
}
