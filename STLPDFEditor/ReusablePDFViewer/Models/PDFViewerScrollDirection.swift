import PDFKit

/// Scroll direction for the PDF viewer. Exposed as @objc Int enum for Objective-C compatibility.
@objc
public enum PDFViewerScrollDirection: Int {
    case vertical
    case horizontal

    var pdfDisplayDirection: PDFDisplayDirection {
        switch self {
        case .vertical:   return .vertical
        case .horizontal: return .horizontal
        }
    }
}
