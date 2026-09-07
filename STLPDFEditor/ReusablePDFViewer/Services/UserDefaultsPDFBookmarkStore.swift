import Foundation

/// Lightweight bookmark persistence using UserDefaults.
/// Suitable for most use cases; can be replaced by injecting a custom PDFBookmarkStoring.
public final class UserDefaultsPDFBookmarkStore: PDFBookmarkStoring {

    private let defaults: UserDefaults
    private let storageKey = "PDFViewerBookmarks"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func bookmarks(for documentIdentifier: String) -> [PDFViewerBookmark] {
        allBookmarks().filter { $0.documentIdentifier == documentIdentifier }
    }

    public func save(_ bookmark: PDFViewerBookmark) {
        var all = allBookmarks()
        // Enforce one bookmark per document/page combination.
        all.removeAll { $0.documentIdentifier == bookmark.documentIdentifier && $0.pageIndex == bookmark.pageIndex }
        all.append(bookmark)
        persist(all)
    }

    public func remove(_ bookmark: PDFViewerBookmark) {
        var all = allBookmarks()
        all.removeAll { $0.id == bookmark.id }
        persist(all)
    }

    // MARK: - Private

    private func allBookmarks() -> [PDFViewerBookmark] {
        guard let data = defaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([PDFViewerBookmark].self, from: data) else {
            return []
        }
        return decoded
    }

    private func persist(_ bookmarks: [PDFViewerBookmark]) {
        guard let data = try? JSONEncoder().encode(bookmarks) else { return }
        defaults.set(data, forKey: storageKey)
    }
}
