import Foundation

/// Provides persistent on-disk locations for the viewer's working document copies and their
/// pristine originals. Application Support is used (not the temporary directory) so opened files
/// survive app relaunches and can be listed on the first screen.
enum PDFViewerStorage {

    /// Working copies of opened documents (the files the viewer actually displays and edits).
    static var documentsDirectory: URL {
        directory(named: "documents")
    }

    /// Pristine originals captured at first open, used by the reset feature.
    static var originalsDirectory: URL {
        directory(named: "originals")
    }

    private static func directory(named name: String) -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let directory = base
            .appendingPathComponent("PDFViewer", isDirectory: true)
            .appendingPathComponent(name, isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}
