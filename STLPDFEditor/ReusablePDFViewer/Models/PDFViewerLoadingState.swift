import Foundation

/// Represents the document loading lifecycle of the PDF viewer.
public enum PDFViewerLoadingState {
    case idle
    case loading
    case loaded
    case passwordRequired
    case failed(PDFViewerError)
}
