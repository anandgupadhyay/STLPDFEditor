import UIKit
import SwiftUI

/// Objective-C and UIKit Swift entry point for the PDF viewer.
/// Wraps the SwiftUI PDFViewerView in a UIHostingController.
@objcMembers
public final class PDFViewerLauncher: NSObject {

    /// Creates a UIViewController presenting the PDF viewer for the given local file URL.
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
        let rootView = PDFViewerView(
            fileURL: fileURL,
            configuration: configuration,
            delegate: delegate
        )
        let hostingController = UIHostingController(rootView: rootView)
        hostingController.modalPresentationStyle = .fullScreen
        return hostingController
    }
}
