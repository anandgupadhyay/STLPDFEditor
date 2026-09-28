import PDFKit
import Foundation

/// Default implementation of PDFDocumentLoading that validates and loads local file URLs.
/// Handles security-scoped URLs (e.g. from UIDocumentPickerViewController / fileImporter)
/// by briefly acquiring access, copying to a persistent app-support location, then releasing.
/// The persistent copy lets opened files survive app relaunches.
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

        // Copy to a stable persistent path so PDFKit can keep the file open after the security
        // scope ends, and so the document remains available across future app launches.
        let stableURL: URL
        do {
            stableURL = try copyToPersistentLocation(url)
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

    private func copyToPersistentLocation(_ url: URL) throws -> URL {
        let destination = PDFViewerStorage.documentsDirectory
            .appendingPathComponent(url.lastPathComponent)

        // If the incoming URL is already our stable copy (e.g. reopening from the saved list),
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
