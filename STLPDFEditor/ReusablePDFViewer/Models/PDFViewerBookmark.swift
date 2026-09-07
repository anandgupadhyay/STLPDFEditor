import Foundation

/// A lightweight, persistable bookmark referencing a specific page in a PDF document.
public struct PDFViewerBookmark: Codable, Identifiable, Equatable {
    public let id: UUID
    /// Identifies the PDF document this bookmark belongs to.
    public let documentIdentifier: String
    /// Zero-based PDFKit page index.
    public let pageIndex: Int
    public let createdAt: Date
    /// Optional human-readable label (e.g. PDF-embedded page label).
    public let pageLabel: String?

    public init(
        id: UUID = UUID(),
        documentIdentifier: String,
        pageIndex: Int,
        createdAt: Date = Date(),
        pageLabel: String? = nil
    ) {
        self.id = id
        self.documentIdentifier = documentIdentifier
        self.pageIndex = pageIndex
        self.createdAt = createdAt
        self.pageLabel = pageLabel
    }

    /// One-based page number for display purposes.
    public var displayPageNumber: Int { pageIndex + 1 }
}
