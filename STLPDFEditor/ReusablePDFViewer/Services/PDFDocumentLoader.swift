import PDFKit
import Foundation

/// Default implementation of PDFDocumentLoading that validates and loads local file URLs.
/// Handles security-scoped URLs (e.g. from UIDocumentPickerViewController / fileImporter)
/// by briefly acquiring access, copying to a stable temp location, then releasing.
public final class PDFDocumentLoader: PDFDocumentLoading {

    public init() {}

    public func load(from url: URL) -> Result<PDFDocument, PDFViewerError> {
        // Security-scoped URLs from the document picker require explicit access.
        let needsSecurityScope = url.startAccessingSecurityScopedResource()
        defer {
            if needsSecurityScope { url.stopAccessingSecurityScopedResource() }
        }

        guard FileManager.default.fileExists(atPath: url.path) else {
            return .failure(.fileNotFound)
        }

        // Copy to a stable temp path so PDFKit can keep the file open after
        // the security scope ends (security-scoped access is released on defer).
        let stableURL: URL
        do {
            stableURL = try copyToTemporaryLocation(url)
        } catch {
            return .failure(.unableToLoad)
        }

        guard let document = PDFDocument(url: stableURL) else {
            return .failure(.invalidDocument)
        }
        guard document.pageCount > 0 else {
            return .failure(.emptyDocument)
        }
        return .success(document)
    }

    // MARK: - Private

    private func copyToTemporaryLocation(_ url: URL) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("PDFViewer", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let destination = tempDir.appendingPathComponent(url.lastPathComponent)

        // If the incoming URL is already our stable copy (e.g. reopening from the recents list),
        // reuse it in place. Copying onto itself would delete the source before the copy.
        if url.standardizedFileURL == destination.standardizedFileURL {
            return url
        }

        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.copyItem(at: url, to: destination)
        return destination
    }
}
