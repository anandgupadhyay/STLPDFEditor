import Foundation
import Combine

/// In-memory, session-scoped registry of opened documents.
///
/// A shared instance is used because the open-document list is genuinely global state
/// shared between the dashboard and any number of independently created viewer instances.
/// It holds no persistence, so the list is naturally cleared when the app is relaunched.
@MainActor
public final class PDFViewerSession: ObservableObject {

    /// Shared session used by default. Custom instances may be injected for testing.
    public static let shared = PDFViewerSession()

    /// Documents opened during the current app session, in the order they were first opened.
    @Published public private(set) var openDocuments: [OpenDocument] = []

    public init() {}

    /// Registers a document. Ignores duplicates that share the same URL.
    public func register(url: URL, title: String) {
        guard !openDocuments.contains(where: { $0.url == url }) else { return }
        openDocuments.append(OpenDocument(title: title, url: url))
    }

    /// Removes a single document from the list.
    public func remove(_ document: OpenDocument) {
        openDocuments.removeAll { $0.id == document.id }
    }

    /// Removes any document matching the given URL. Used by external (e.g. Objective-C) callers.
    public func remove(url: URL) {
        openDocuments.removeAll { $0.url == url }
    }

    /// Clears the entire open-document list.
    public func clear() {
        openDocuments.removeAll()
    }
}
