import PDFKit
import UIKit

/// Coordinator bridges PDFView delegate/notifications to the ViewModel.
/// Avoids retain cycles by holding a weak reference to the ViewModel.
final class PDFKitCoordinator: NSObject, PDFViewDelegate {

    weak var viewModel: PDFViewerViewModel?
    /// Strongly retains the controller so it lives as long as the UIView.
    /// ViewModel holds only a weak reference back, preventing a retain cycle.
    var pdfViewerController: PDFViewerController?
    private var notificationTokens: [NSObjectProtocol] = []

    func setup(with pdfView: PDFView) {
        pdfView.delegate = self
        observePageChanges(from: pdfView)
    }

    func teardown(from pdfView: PDFView) {
        pdfView.delegate = nil
        notificationTokens.forEach { NotificationCenter.default.removeObserver($0) }
        notificationTokens.removeAll()
    }

    // MARK: - PDFViewDelegate

    func pdfViewPageChanged(_ sender: PDFView) {
        guard let vm = viewModel,
              let doc = sender.document,
              let page = sender.currentPage else { return }
        let index = doc.index(for: page)
        // Guard against spurious callbacks that would re-enter state updates.
        if vm.currentPageIndex != index {
            vm.updateCurrentPage(to: index)
        }
    }

    // MARK: - Private

    private func observePageChanges(from pdfView: PDFView) {
        let token = NotificationCenter.default.addObserver(
            forName: Notification.Name.PDFViewPageChanged,
            object: pdfView,
            queue: .main
        ) { [weak self, weak pdfView] _ in
            guard let self, let pdfView else { return }
            self.pdfViewPageChanged(pdfView)
        }
        notificationTokens.append(token)
    }
}
