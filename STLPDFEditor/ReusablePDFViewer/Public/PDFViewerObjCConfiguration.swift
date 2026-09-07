import UIKit

/// Mutable NSObject facade for Objective-C callers.
/// Translated to PDFViewerConfiguration internally — Swift callers should use PDFViewerConfiguration directly.
@objcMembers
public final class PDFViewerObjCConfiguration: NSObject {

    public var bookmarksEnabled: Bool = true
    public var searchEnabled: Bool = true
    public var thumbnailsEnabled: Bool = true
    public var outlineEnabled: Bool = true
    public var printingEnabled: Bool = true
    public var sharingEnabled: Bool = true
    public var scrollDirectionEnabled: Bool = true
    public var showsCloseButton: Bool = false

    public var initialPage: Int = 1
    public var initialScrollDirection: PDFViewerScrollDirection = .vertical
    public var initialDisplayMode: PDFViewerDisplayMode = .singlePageContinuous

    public var toolbarBackgroundColor: UIColor?
    public var toolbarTintColor: UIColor?
    public var viewerBackgroundColor: UIColor?

    public var documentIdentifier: String?

    /// Converts to the internal Swift configuration model.
    func toConfiguration() -> PDFViewerConfiguration {
        var features = PDFViewerFeatures()
        features.bookmarks = bookmarksEnabled
        features.search = searchEnabled
        features.thumbnails = thumbnailsEnabled
        features.outline = outlineEnabled
        features.printing = printingEnabled
        features.sharing = sharingEnabled
        features.scrollDirection = scrollDirectionEnabled
        features.showsCloseButton = showsCloseButton

        var theme = PDFViewerTheme()
        if let bg = viewerBackgroundColor { theme.backgroundColor = bg }
        if let tb = toolbarBackgroundColor { theme.toolbarBackgroundColor = tb }
        if let tint = toolbarTintColor {
            theme.primaryColor = tint
            theme.iconColor = tint
        }

        var behavior = PDFViewerBehavior()
        behavior.initialPage = initialPage
        behavior.initialScrollDirection = initialScrollDirection
        behavior.initialDisplayMode = initialDisplayMode

        return PDFViewerConfiguration(
            features: features,
            theme: theme,
            strings: PDFViewerStrings(),
            icons: PDFViewerIcons(),
            behavior: behavior,
            documentIdentifier: documentIdentifier
        )
    }
}
