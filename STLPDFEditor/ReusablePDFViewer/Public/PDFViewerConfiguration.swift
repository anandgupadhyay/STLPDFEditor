import UIKit

/// Immutable configuration for the PDF viewer. Used by Swift clients directly.
public struct PDFViewerConfiguration {

    public var features: PDFViewerFeatures
    public var theme: PDFViewerTheme
    public var strings: PDFViewerStrings
    public var icons: PDFViewerIcons
    public var behavior: PDFViewerBehavior

    /// Unique identifier for the document. Defaults to the normalized file URL string.
    /// Host app may supply a stable identifier for consistent bookmark association.
    public var documentIdentifier: String?

    public init(
        features: PDFViewerFeatures = PDFViewerFeatures(),
        theme: PDFViewerTheme = PDFViewerTheme(),
        strings: PDFViewerStrings = PDFViewerStrings(),
        icons: PDFViewerIcons = PDFViewerIcons(),
        behavior: PDFViewerBehavior = PDFViewerBehavior(),
        documentIdentifier: String? = nil
    ) {
        self.features = features
        self.theme = theme
        self.strings = strings
        self.icons = icons
        self.behavior = behavior
        self.documentIdentifier = documentIdentifier
    }

    public static var `default`: PDFViewerConfiguration { PDFViewerConfiguration() }
}

// MARK: - Features

/// Granular feature flags. Defaults produce a fully featured viewer.
public struct PDFViewerFeatures {
    public var bookmarks: Bool
    public var search: Bool
    public var thumbnails: Bool
    public var outline: Bool
    public var pageNavigation: Bool
    public var goToPage: Bool
    public var scrollDirection: Bool
    public var zoomControls: Bool
    public var sharing: Bool
    public var printing: Bool
    public var documentInfo: Bool
    public var showsCloseButton: Bool
    public var restoresLastViewedPage: Bool

    public init(
        bookmarks: Bool = true,
        search: Bool = true,
        thumbnails: Bool = true,
        outline: Bool = true,
        pageNavigation: Bool = true,
        goToPage: Bool = true,
        scrollDirection: Bool = true,
        zoomControls: Bool = true,
        sharing: Bool = true,
        printing: Bool = true,
        documentInfo: Bool = true,
        showsCloseButton: Bool = false,
        restoresLastViewedPage: Bool = false
    ) {
        self.bookmarks = bookmarks
        self.search = search
        self.thumbnails = thumbnails
        self.outline = outline
        self.pageNavigation = pageNavigation
        self.goToPage = goToPage
        self.scrollDirection = scrollDirection
        self.zoomControls = zoomControls
        self.sharing = sharing
        self.printing = printing
        self.documentInfo = documentInfo
        self.showsCloseButton = showsCloseButton
        self.restoresLastViewedPage = restoresLastViewedPage
    }
}

// MARK: - Theme

/// Visual theme for the PDF viewer. UIColor is used for Objective-C compatibility.
public struct PDFViewerTheme {
    public var backgroundColor: UIColor
    public var toolbarBackgroundColor: UIColor
    public var primaryColor: UIColor
    public var secondaryColor: UIColor
    public var iconColor: UIColor
    public var textColor: UIColor

    public init(
        backgroundColor: UIColor = .systemBackground,
        toolbarBackgroundColor: UIColor = .systemBackground,
        primaryColor: UIColor = .systemBlue,
        secondaryColor: UIColor = .secondaryLabel,
        iconColor: UIColor = .label,
        textColor: UIColor = .label
    ) {
        self.backgroundColor = backgroundColor
        self.toolbarBackgroundColor = toolbarBackgroundColor
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
        self.iconColor = iconColor
        self.textColor = textColor
    }
}

// MARK: - Strings

/// All user-facing strings. Override to localize or white-label.
public struct PDFViewerStrings {
    public var bookmarks: String
    public var search: String
    public var goToPage: String
    public var cancel: String
    public var done: String
    public var page: String
    public var of: String
    public var vertical: String
    public var horizontal: String
    public var print: String
    public var share: String
    public var noBookmarks: String
    public var noSearchResults: String
    public var invalidPage: String
    public var unableToOpenPDF: String
    public var enterPassword: String
    public var tableOfContents: String
    public var thumbnails: String
    public var documentInfo: String
    public var scrollDirection: String
    public var displayMode: String
    public var more: String
    public var noOutline: String
    public var loading: String

    public init(
        bookmarks: String = "Bookmarks",
        search: String = "Search",
        goToPage: String = "Go to Page",
        cancel: String = "Cancel",
        done: String = "Done",
        page: String = "Page",
        of: String = "of",
        vertical: String = "Vertical",
        horizontal: String = "Horizontal",
        print: String = "Print",
        share: String = "Share",
        noBookmarks: String = "No Bookmarks",
        noSearchResults: String = "No Results",
        invalidPage: String = "Invalid page number.",
        unableToOpenPDF: String = "Unable to open PDF.",
        enterPassword: String = "Enter Password",
        tableOfContents: String = "Table of Contents",
        thumbnails: String = "Thumbnails",
        documentInfo: String = "Document Info",
        scrollDirection: String = "Scroll Direction",
        displayMode: String = "Display Mode",
        more: String = "More",
        noOutline: String = "This document does not contain a table of contents.",
        loading: String = "Loading\u{2026}"
    ) {
        self.bookmarks = bookmarks
        self.search = search
        self.goToPage = goToPage
        self.cancel = cancel
        self.done = done
        self.page = page
        self.of = of
        self.vertical = vertical
        self.horizontal = horizontal
        self.print = print
        self.share = share
        self.noBookmarks = noBookmarks
        self.noSearchResults = noSearchResults
        self.invalidPage = invalidPage
        self.unableToOpenPDF = unableToOpenPDF
        self.enterPassword = enterPassword
        self.tableOfContents = tableOfContents
        self.thumbnails = thumbnails
        self.documentInfo = documentInfo
        self.scrollDirection = scrollDirection
        self.displayMode = displayMode
        self.more = more
        self.noOutline = noOutline
        self.loading = loading
    }
}

// MARK: - Icons

/// SF Symbol names and optional UIImage overrides. UIImage is used for Objective-C compatibility.
public struct PDFViewerIcons {
    public var back: UIImage?
    public var bookmark: UIImage?
    public var bookmarkFill: UIImage?
    public var search: UIImage?
    public var thumbnails: UIImage?
    public var outline: UIImage?
    public var previousPage: UIImage?
    public var nextPage: UIImage?
    public var scrollDirection: UIImage?
    public var more: UIImage?
    public var share: UIImage?
    public var print: UIImage?

    public init() {}

    func resolved(_ override: UIImage?, sfSymbol: String) -> UIImage {
        override ?? UIImage(systemName: sfSymbol) ?? UIImage()
    }
}

// MARK: - Behavior

/// PDFView rendering and UX behavior configuration.
public struct PDFViewerBehavior {
    public var initialPage: Int
    public var initialScrollDirection: PDFViewerScrollDirection
    public var initialDisplayMode: PDFViewerDisplayMode
    public var autoScales: Bool
    public var minScaleFactor: CGFloat
    public var maxScaleFactor: CGFloat
    public var pageBreaksEnabled: Bool
    public var pageShadowsEnabled: Bool

    public init(
        initialPage: Int = 1,
        initialScrollDirection: PDFViewerScrollDirection = .vertical,
        initialDisplayMode: PDFViewerDisplayMode = .singlePageContinuous,
        autoScales: Bool = true,
        minScaleFactor: CGFloat = 0.5,
        maxScaleFactor: CGFloat = 4.0,
        pageBreaksEnabled: Bool = true,
        pageShadowsEnabled: Bool = true
    ) {
        self.initialPage = initialPage
        self.initialScrollDirection = initialScrollDirection
        self.initialDisplayMode = initialDisplayMode
        self.autoScales = autoScales
        self.minScaleFactor = minScaleFactor
        self.maxScaleFactor = maxScaleFactor
        self.pageBreaksEnabled = pageBreaksEnabled
        self.pageShadowsEnabled = pageShadowsEnabled
    }
}
