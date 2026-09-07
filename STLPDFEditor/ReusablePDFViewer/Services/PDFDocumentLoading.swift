import PDFKit

/// Defines the contract for loading a PDF document from a source.
/// Abstracting this enables unit testing without real files.
public protocol PDFDocumentLoading {
    /// Attempts to load a PDFDocument from the given file URL.
    /// Returns a Result with the loaded document or a typed error.
    func load(from url: URL) -> Result<PDFDocument, PDFViewerError>
}
