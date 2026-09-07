import Foundation

/// Objective-C compatible delegate for receiving PDF viewer lifecycle events.
/// Store weakly to avoid retain cycles.
@objc
public protocol PDFViewerDelegate: AnyObject {

    /// Called after the PDF document successfully opens.
    @objc optional func pdfViewerDidOpenDocument()

    /// Called when the viewer is dismissed or close is requested.
    @objc optional func pdfViewerDidClose()

    /// Called when the visible page changes for any reason.
    @objc optional func pdfViewerDidChangePage(_ page: Int, totalPages: Int)

    /// Called after a bookmark is added for the given page number.
    @objc optional func pdfViewerDidAddBookmark(atPage page: Int)

    /// Called after a bookmark is removed for the given page number.
    @objc optional func pdfViewerDidRemoveBookmark(atPage page: Int)

    /// Called when a document-level error occurs.
    @objc optional func pdfViewerDidFail(withError error: NSError)
}
