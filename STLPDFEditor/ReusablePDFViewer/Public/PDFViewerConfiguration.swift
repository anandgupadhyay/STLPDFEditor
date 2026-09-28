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
    /// Enables reordering/removing pages from the thumbnail browser and saving the result.
    public var pageEditing: Bool

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
        restoresLastViewedPage: Bool = false,
        pageEditing: Bool = true
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
        self.pageEditing = pageEditing
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

/// All user-facing strings. Defaults are localized for the device language.
/// Override any value to white-label or force a specific wording.
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
    public var back: String
    public var firstPage: String
    public var previousPage: String
    public var nextPage: String
    public var lastPage: String
    public var zoomIn: String
    public var zoomOut: String
    public var resetZoom: String
    public var addBookmark: String
    public var removeBookmark: String
    public var openDocuments: String
    public var closeAll: String
    public var close: String
    public var noOpenDocuments: String
    public var searching: String
    public var enterKeyword: String
    public var title: String
    public var author: String
    public var subject: String
    public var creator: String
    public var pages: String
    public var untitled: String
    /// Format string with two integer arguments: total matches and total pages.
    public var searchSummaryFormat: String
    /// Format string with one integer argument: number of occurrences on a page.
    public var occurrencesFormat: String
    /// Format string with one string argument: the search query.
    public var noMatchesForFormat: String
    public var edit: String
    public var save: String
    public var reset: String
    public var editPages: String
    public var saveChangesTitle: String
    public var saveChangesMessage: String
    public var resetChangesTitle: String
    public var resetChangesMessage: String
    public var saveFailed: String
    public var resetFailed: String
    public var minOnePage: String
    public var saving: String

    public init(
        bookmarks: String = PDFViewerLocalization.string("bookmarks"),
        search: String = PDFViewerLocalization.string("search"),
        goToPage: String = PDFViewerLocalization.string("goToPage"),
        cancel: String = PDFViewerLocalization.string("cancel"),
        done: String = PDFViewerLocalization.string("done"),
        page: String = PDFViewerLocalization.string("page"),
        of: String = PDFViewerLocalization.string("of"),
        vertical: String = PDFViewerLocalization.string("vertical"),
        horizontal: String = PDFViewerLocalization.string("horizontal"),
        print: String = PDFViewerLocalization.string("print"),
        share: String = PDFViewerLocalization.string("share"),
        noBookmarks: String = PDFViewerLocalization.string("noBookmarks"),
        noSearchResults: String = PDFViewerLocalization.string("noSearchResults"),
        invalidPage: String = PDFViewerLocalization.string("invalidPage"),
        unableToOpenPDF: String = PDFViewerLocalization.string("unableToOpenPDF"),
        enterPassword: String = PDFViewerLocalization.string("enterPassword"),
        tableOfContents: String = PDFViewerLocalization.string("tableOfContents"),
        thumbnails: String = PDFViewerLocalization.string("thumbnails"),
        documentInfo: String = PDFViewerLocalization.string("documentInfo"),
        scrollDirection: String = PDFViewerLocalization.string("scrollDirection"),
        displayMode: String = PDFViewerLocalization.string("displayMode"),
        more: String = PDFViewerLocalization.string("more"),
        noOutline: String = PDFViewerLocalization.string("noOutline"),
        loading: String = PDFViewerLocalization.string("loading"),
        back: String = PDFViewerLocalization.string("back"),
        firstPage: String = PDFViewerLocalization.string("firstPage"),
        previousPage: String = PDFViewerLocalization.string("previousPage"),
        nextPage: String = PDFViewerLocalization.string("nextPage"),
        lastPage: String = PDFViewerLocalization.string("lastPage"),
        zoomIn: String = PDFViewerLocalization.string("zoomIn"),
        zoomOut: String = PDFViewerLocalization.string("zoomOut"),
        resetZoom: String = PDFViewerLocalization.string("resetZoom"),
        addBookmark: String = PDFViewerLocalization.string("addBookmark"),
        removeBookmark: String = PDFViewerLocalization.string("removeBookmark"),
        openDocuments: String = PDFViewerLocalization.string("openDocuments"),
        closeAll: String = PDFViewerLocalization.string("closeAll"),
        close: String = PDFViewerLocalization.string("close"),
        noOpenDocuments: String = PDFViewerLocalization.string("noOpenDocuments"),
        searching: String = PDFViewerLocalization.string("searching"),
        enterKeyword: String = PDFViewerLocalization.string("enterKeyword"),
        title: String = PDFViewerLocalization.string("title"),
        author: String = PDFViewerLocalization.string("author"),
        subject: String = PDFViewerLocalization.string("subject"),
        creator: String = PDFViewerLocalization.string("creator"),
        pages: String = PDFViewerLocalization.string("pages"),
        untitled: String = PDFViewerLocalization.string("untitled"),
        searchSummaryFormat: String = PDFViewerLocalization.string("searchSummaryFormat"),
        occurrencesFormat: String = PDFViewerLocalization.string("occurrencesFormat"),
        noMatchesForFormat: String = PDFViewerLocalization.string("noMatchesForFormat"),
        edit: String = PDFViewerLocalization.string("edit"),
        save: String = PDFViewerLocalization.string("save"),
        reset: String = PDFViewerLocalization.string("reset"),
        editPages: String = PDFViewerLocalization.string("editPages"),
        saveChangesTitle: String = PDFViewerLocalization.string("saveChangesTitle"),
        saveChangesMessage: String = PDFViewerLocalization.string("saveChangesMessage"),
        resetChangesTitle: String = PDFViewerLocalization.string("resetChangesTitle"),
        resetChangesMessage: String = PDFViewerLocalization.string("resetChangesMessage"),
        saveFailed: String = PDFViewerLocalization.string("saveFailed"),
        resetFailed: String = PDFViewerLocalization.string("resetFailed"),
        minOnePage: String = PDFViewerLocalization.string("minOnePage"),
        saving: String = PDFViewerLocalization.string("saving")
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
        self.back = back
        self.firstPage = firstPage
        self.previousPage = previousPage
        self.nextPage = nextPage
        self.lastPage = lastPage
        self.zoomIn = zoomIn
        self.zoomOut = zoomOut
        self.resetZoom = resetZoom
        self.addBookmark = addBookmark
        self.removeBookmark = removeBookmark
        self.openDocuments = openDocuments
        self.closeAll = closeAll
        self.close = close
        self.noOpenDocuments = noOpenDocuments
        self.searching = searching
        self.enterKeyword = enterKeyword
        self.title = title
        self.author = author
        self.subject = subject
        self.creator = creator
        self.pages = pages
        self.untitled = untitled
        self.searchSummaryFormat = searchSummaryFormat
        self.occurrencesFormat = occurrencesFormat
        self.noMatchesForFormat = noMatchesForFormat
        self.edit = edit
        self.save = save
        self.reset = reset
        self.editPages = editPages
        self.saveChangesTitle = saveChangesTitle
        self.saveChangesMessage = saveChangesMessage
        self.resetChangesTitle = resetChangesTitle
        self.resetChangesMessage = resetChangesMessage
        self.saveFailed = saveFailed
        self.resetFailed = resetFailed
        self.minOnePage = minOnePage
        self.saving = saving
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
