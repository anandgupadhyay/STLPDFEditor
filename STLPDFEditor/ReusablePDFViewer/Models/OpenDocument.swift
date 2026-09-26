import Foundation

/// A document opened during the current app session.
/// Holds a stable URL that remains readable for the lifetime of the session.
public struct OpenDocument: Identifiable, Equatable {
    public let id: UUID
    public let title: String
    /// Stable file URL used to reopen the document (a session-local copy, not the original picker URL).
    public let url: URL

    public init(id: UUID = UUID(), title: String, url: URL) {
        self.id = id
        self.title = title
        self.url = url
    }
}
