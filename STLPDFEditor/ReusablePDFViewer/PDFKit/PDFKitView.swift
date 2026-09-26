import SwiftUI
import PDFKit

/// SwiftUI wrapper for PDFView.
/// PDFView is created once and reused — updateUIView only applies configuration deltas
/// to prevent unnecessary document reloads on every SwiftUI state change.
struct PDFKitView: UIViewRepresentable {

    let document: PDFDocument
    let configuration: PDFViewerConfiguration
    @ObservedObject var viewModel: PDFViewerViewModel

    func makeCoordinator() -> PDFKitCoordinator {
        PDFKitCoordinator()
    }

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        configure(pdfView, with: configuration)
        pdfView.document = document

        let coordinator = context.coordinator
        coordinator.viewModel = viewModel
        coordinator.setup(with: pdfView)

        // Wire the controller so the ViewModel can issue navigation commands.
        // Stored strongly in the coordinator so it lives as long as the UIView.
        let controller = PDFViewerController(pdfView: pdfView)
        coordinator.pdfViewerController = controller
        viewModel.attachController(controller)

        // Navigate to the initial page after the view has its document.
        DispatchQueue.main.async {
            let behavior = configuration.behavior
            let zeroIndex = max(0, behavior.initialPage - 1)
            let clampedIndex = min(zeroIndex, document.pageCount - 1)
            if let page = document.page(at: clampedIndex) {
                pdfView.go(to: page)
            }
        }

        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        // Reopening a different document within the same viewer swaps the document in place.
        if pdfView.document !== document {
            pdfView.document = document
            DispatchQueue.main.async {
                if let page = document.page(at: 0) { pdfView.go(to: page) }
            }
        }

        // Compare against viewModel state, not the initial config.
        // Using initial config caused direction resets on every SwiftUI re-render.
        let targetDirection = viewModel.scrollDirection.pdfDisplayDirection
        if pdfView.displayDirection != targetDirection {
            let currentPage = pdfView.currentPage
            pdfView.displayDirection = targetDirection
            if let page = currentPage { pdfView.go(to: page) }
        }
        let targetMode = viewModel.displayMode.pdfDisplayMode
        if pdfView.displayMode != targetMode {
            let currentPage = pdfView.currentPage
            pdfView.displayMode = targetMode
            if let page = currentPage { pdfView.go(to: page) }
        }
    }

    static func dismantleUIView(_ pdfView: PDFView, coordinator: PDFKitCoordinator) {
        coordinator.teardown(from: pdfView)
    }

    // MARK: - Private

    private func configure(_ pdfView: PDFView, with config: PDFViewerConfiguration) {
        let behavior = config.behavior
        pdfView.autoScales = behavior.autoScales
        pdfView.minScaleFactor = behavior.minScaleFactor
        pdfView.maxScaleFactor = behavior.maxScaleFactor
        pdfView.displayDirection = behavior.initialScrollDirection.pdfDisplayDirection
        pdfView.displayMode = behavior.initialDisplayMode.pdfDisplayMode
        pdfView.displaysPageBreaks = behavior.pageBreaksEnabled
        pdfView.pageShadowsEnabled = behavior.pageShadowsEnabled
        pdfView.backgroundColor = config.theme.backgroundColor
        pdfView.usePageViewController(false)
    }
}
