import PDFKit

/// Display mode for the PDF viewer. Exposed as @objc Int enum for Objective-C compatibility.
@objc
public enum PDFViewerDisplayMode: Int {
    case singlePage
    case singlePageContinuous
    case twoUp
    case twoUpContinuous

    var pdfDisplayMode: PDFDisplayMode {
        switch self {
        case .singlePage:           return .singlePage
        case .singlePageContinuous: return .singlePageContinuous
        case .twoUp:                return .twoUp
        case .twoUpContinuous:      return .twoUpContinuous
        }
    }
}
