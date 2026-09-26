import UIKit
import SwiftUI

/// Objective-C and UIKit Swift entry point for the PDF viewer.
/// Wraps the SwiftUI PDFViewerView in a UIHostingController and exposes
/// session open/close controls that are callable from Objective-C.
@objcMembers
public final class PDFViewerLauncher: NSObject {

    // MARK: - Opening

    /// Creates a UIViewController presenting the PDF viewer for the given local file URL.
    /// Opening a document automatically registers it in the shared session list.
    /// - Parameters:
    ///   - fileURL: Local file URL of the PDF to open.
    ///   - configuration: Optional Objective-C compatible configuration. Defaults are used when nil.
    ///   - delegate: Optional delegate for receiving viewer lifecycle events.
    @objc(makeViewControllerWithFileURL:configuration:delegate:)
    public static func makeViewController(
        fileURL: URL,
        configuration: PDFViewerObjCConfiguration?,
        delegate: PDFViewerDelegate?
    ) -> UIViewController {
        let swiftConfig = configuration?.toConfiguration() ?? .default
        return makeViewControllerSwift(fileURL: fileURL, configuration: swiftConfig, delegate: delegate)
    }

    /// Swift-native convenience that accepts PDFViewerConfiguration directly.
    public static func makeViewControllerSwift(
        fileURL: URL,
        configuration: PDFViewerConfiguration = .default,
        delegate: PDFViewerDelegate? = nil
    ) -> UIViewController {
        // Holder lets the SwiftUI view dismiss the UIKit-presented hosting controller,
        // which SwiftUI's own dismiss environment cannot do for a manually presented controller.
        let dismisser = ViewerDismisser()

        let rootView = PDFViewerView(
            fileURL: fileURL,
            configuration: configuration,
            delegate: delegate
        )
        .requestingDismiss { [weak dismisser] in
            dismisser?.dismiss()
        }

        let hostingController = UIHostingController(rootView: rootView)
        hostingController.modalPresentationStyle = .fullScreen
        dismisser.controller = hostingController
        return hostingController
    }

    // MARK: - Closing (Objective-C accessible)

    /// Closes a specific document by URL. Removes it from the open-document list; if it is the
    /// document currently on screen, the viewer dismisses automatically and returns to the previous view.
    @objc(closeDocumentAtURL:)
    @MainActor
    public static func closeDocument(at fileURL: URL) {
        PDFViewerSession.shared.remove(url: fileURL)
    }

    /// Closes every open document and dismisses any presented viewer.
    @objc
    @MainActor
    public static func closeAllDocuments() {
        PDFViewerSession.shared.clear()
    }

    /// The URLs of all documents currently open in this session.
    @objc
    @MainActor
    public static var openDocumentURLs: [URL] {
        PDFViewerSession.shared.openDocuments.map { $0.url }
    }
}

/// Retains a weak reference to the hosting controller so the SwiftUI viewer can dismiss it.
final class ViewerDismisser {
    weak var controller: UIViewController?

    @MainActor
    func dismiss() {
        controller?.dismiss(animated: true)
    }
}
