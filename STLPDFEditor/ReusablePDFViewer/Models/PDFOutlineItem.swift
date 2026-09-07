import PDFKit

/// A presentation-layer-safe representation of a PDF outline entry.
/// Decouples SwiftUI views from direct PDFOutline dependency.
public final class PDFOutlineItem: Identifiable {
    public let id: UUID
    public let title: String
    public let pageIndex: Int?
    public let children: [PDFOutlineItem]

    public init(title: String, pageIndex: Int?, children: [PDFOutlineItem] = []) {
        self.id = UUID()
        self.title = title
        self.pageIndex = pageIndex
        self.children = children
    }

    /// Recursively builds a tree from a PDFOutline node.
    static func build(from outline: PDFOutline, document: PDFDocument) -> PDFOutlineItem {
        var children: [PDFOutlineItem] = []
        for i in 0..<outline.numberOfChildren {
            if let child = outline.child(at: i) {
                children.append(PDFOutlineItem.build(from: child, document: document))
            }
        }
        let pageIndex: Int? = outline.destination?.page.flatMap { document.index(for: $0) }
        return PDFOutlineItem(
            title: outline.label ?? "",
            pageIndex: pageIndex,
            children: children
        )
    }
}
