import Foundation
import Combine

/// Registry of opened documents, persisted across app launches.
///
/// A shared instance is used because the open-document list is genuinely global state shared
/// between the dashboard and any number of independently created viewer instances. The list is
/// persisted in UserDefaults (storing each document's file name and title) and the working files
/// live in `PDFViewerStorage.documentsDirectory`, so opened files remain available after relaunch.
@MainActor
public final class PDFViewerSession: ObservableObject {

    /// Shared session used by default. Custom instances may be injected for testing.
    public static let shared = PDFViewerSession()

    /// Documents opened by the user, in the order they were first opened.
    @Published public private(set) var openDocuments: [OpenDocument] = []

    private let defaults: UserDefaults
    private let storageKey = "PDFViewerOpenDocuments"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        loadPersisted()
    }

    /// Registers a document. Ignores duplicates that share the same URL.
    public func register(url: URL, title: String) {
        guard !openDocuments.contains(where: { $0.url == url }) else { return }
        openDocuments.append(OpenDocument(title: title, url: url))
        persist()
    }

    /// Removes a single document from the list and deletes its stored copies.
    public func remove(_ document: OpenDocument) {
        openDocuments.removeAll { $0.id == document.id }
        deleteStoredFile(named: document.url.lastPathComponent)
        persist()
    }

    /// Removes any document matching the given URL. Used by external (e.g. Objective-C) callers.
    public func remove(url: URL) {
        openDocuments.removeAll { $0.url == url }
        deleteStoredFile(named: url.lastPathComponent)
        persist()
    }

    /// Clears the entire open-document list and deletes all stored copies.
    public func clear() {
        let names = openDocuments.map { $0.url.lastPathComponent }
        openDocuments.removeAll()
        names.forEach { deleteStoredFile(named: $0) }
        persist()
    }

    // MARK: - Persistence

    /// Codable record persisted per document. Only the file name is stored so the URL can be
    /// rebuilt against the current app-support container, which may change between launches.
    private struct Record: Codable {
        let title: String
        let fileName: String
    }

    private func persist() {
        let records = openDocuments.map { Record(title: $0.title, fileName: $0.url.lastPathComponent) }
        if let data = try? JSONEncoder().encode(records) {
            defaults.set(data, forKey: storageKey)
        }
    }

    private func loadPersisted() {
        guard let data = defaults.data(forKey: storageKey),
              let records = try? JSONDecoder().decode([Record].self, from: data) else {
            return
        }
        let directory = PDFViewerStorage.documentsDirectory
        openDocuments = records.compactMap { record in
            let url = directory.appendingPathComponent(record.fileName)
            guard FileManager.default.fileExists(atPath: url.path) else { return nil }
            return OpenDocument(title: record.title, url: url)
        }
        // Drop any entries whose files no longer exist.
        if openDocuments.count != records.count {
            persist()
        }
    }

    private func deleteStoredFile(named fileName: String) {
        let working = PDFViewerStorage.documentsDirectory.appendingPathComponent(fileName)
        let original = PDFViewerStorage.originalsDirectory.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: working)
        try? FileManager.default.removeItem(at: original)
    }
}
