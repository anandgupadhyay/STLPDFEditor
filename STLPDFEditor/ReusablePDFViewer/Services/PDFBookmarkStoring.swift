import Foundation

/// Contract for bookmark persistence. Implementations may use UserDefaults, Core Data, CloudKit, etc.
/// Dependency Inversion: the ViewModel depends on this protocol, not a concrete store.
public protocol PDFBookmarkStoring {
    func bookmarks(for documentIdentifier: String) -> [PDFViewerBookmark]
    func save(_ bookmark: PDFViewerBookmark)
    func remove(_ bookmark: PDFViewerBookmark)
}
