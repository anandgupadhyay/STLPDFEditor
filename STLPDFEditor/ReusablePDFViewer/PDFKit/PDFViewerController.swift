import PDFKit
import UIKit

/// Protocol isolating ViewModel from the concrete PDFView.
protocol PDFViewing: AnyObject {
    func go(toPageIndex index: Int)
    func goToNextPage()
    func goToPreviousPage()
    func goToFirstPage()
    func goToLastPage()
    func setScrollDirection(_ direction: PDFViewerScrollDirection)
    func setDisplayMode(_ mode: PDFViewerDisplayMode)
    func zoomIn()
    func zoomOut()
    func resetZoom()
    func goBack()
    func goForward()
    /// Highlights every selection in the array across all pages, then navigates to the given page index.
    func highlightAll(selections: [PDFSelection], goToPageIndex index: Int)
    func clearHighlights()
    var canGoBack: Bool { get }
    var canGoForward: Bool { get }
}

/// Concrete wrapper around PDFView. Owned by the Coordinator to prevent premature deallocation.
final class PDFViewerController: PDFViewing {

    private weak var pdfView: PDFView?

    init(pdfView: PDFView) {
        self.pdfView = pdfView
    }

    func go(toPageIndex index: Int) {
        guard let view = pdfView, let doc = view.document,
              let page = doc.page(at: index) else { return }
        view.go(to: page)
    }

    func goToNextPage() {
        pdfView?.goToNextPage(nil)
    }

    func goToPreviousPage() {
        pdfView?.goToPreviousPage(nil)
    }

    func goToFirstPage() {
        guard let view = pdfView, let page = view.document?.page(at: 0) else { return }
        view.go(to: page)
    }

    func goToLastPage() {
        guard let view = pdfView, let doc = view.document,
              let page = doc.page(at: doc.pageCount - 1) else { return }
        view.go(to: page)
    }

    func setScrollDirection(_ direction: PDFViewerScrollDirection) {
        guard let view = pdfView else { return }
        let currentPage = view.currentPage
        view.displayDirection = direction.pdfDisplayDirection
        if let page = currentPage { view.go(to: page) }
    }

    func setDisplayMode(_ mode: PDFViewerDisplayMode) {
        guard let view = pdfView else { return }
        let currentPage = view.currentPage
        view.displayMode = mode.pdfDisplayMode
        if let page = currentPage { view.go(to: page) }
    }

    func zoomIn() { pdfView?.zoomIn(nil) }
    func zoomOut() { pdfView?.zoomOut(nil) }

    func resetZoom() {
        pdfView?.scaleFactor = pdfView?.scaleFactorForSizeToFit ?? 1.0
    }

    func goBack() { pdfView?.goBack(nil) }
    func goForward() { pdfView?.goForward(nil) }

    func highlightAll(selections: [PDFSelection], goToPageIndex index: Int) {
        guard let view = pdfView, let doc = view.document,
              let targetPage = doc.page(at: index) else { return }
        // Apply yellow highlight color to every match before handing to PDFView.
        selections.forEach { $0.color = UIColor.yellow }
        view.highlightedSelections = selections
        view.go(to: targetPage)
    }

    func clearHighlights() {
        pdfView?.highlightedSelections = nil
    }

    var canGoBack: Bool { pdfView?.canGoBack ?? false }
    var canGoForward: Bool { pdfView?.canGoForward ?? false }
}
