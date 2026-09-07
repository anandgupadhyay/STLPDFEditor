import UIKit

/// Presents share sheet or print dialog from UIKit, safely handling iPad popover requirements.
final class PDFSharePrintHelper {

    static func share(fileURL: URL, from sourceView: UIView?) {
        let activity = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        activity.popoverPresentationController?.sourceView = sourceView
        activity.popoverPresentationController?.sourceRect = sourceView?.bounds ?? .zero
        presentFromTop(activity)
    }

    static func print(fileURL: URL, from sourceView: UIView?) {
        let info = UIPrintInfo(dictionary: nil)
        info.outputType = .general
        info.jobName = fileURL.lastPathComponent

        let controller = UIPrintInteractionController.shared
        controller.printInfo = info
        controller.printingItem = fileURL

        if let view = sourceView {
            controller.present(from: view.bounds, in: view, animated: true, completionHandler: nil)
        } else {
            controller.present(animated: true, completionHandler: nil)
        }
    }

    private static func presentFromTop(_ viewController: UIViewController) {
        guard let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController else { return }
        var presenter = root
        while let presented = presenter.presentedViewController {
            presenter = presented
        }
        presenter.present(viewController, animated: true)
    }
}
