import SwiftUI

/// Top toolbar. Uses a ZStack so the document title is truly centered
/// regardless of how many buttons appear on the leading/trailing sides.
struct PDFViewerToolbar: View {

    @ObservedObject var viewModel: PDFViewerViewModel
    let configuration: PDFViewerConfiguration
    @Binding var showBookmarks: Bool
    @Binding var showSearch: Bool
    @Binding var showThumbnails: Bool
    @Binding var showOutline: Bool
    @Binding var showGoToPage: Bool
    @Binding var showDocumentInfo: Bool
    @Binding var showShare: Bool
    @Binding var showRecents: Bool
    var onClose: (() -> Void)?

    private var features: PDFViewerFeatures { configuration.features }
    private var strings: PDFViewerStrings { configuration.strings }
    private var theme: PDFViewerTheme { configuration.theme }

    var body: some View {
        ZStack {
            // Center — document title
            if !viewModel.documentTitle.isEmpty {
                Text(viewModel.documentTitle)
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .padding(.horizontal, 110) // reserve room for leading/trailing buttons
            }

            // Leading + trailing buttons
            HStack(spacing: 0) {
                if features.showsCloseButton {
                    Button(action: { onClose?() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .accessibilityLabel(strings.back)
                    .padding(.trailing, 20)
                }

                Button { showRecents = true } label: {
                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 17))
                }
                .accessibilityLabel(strings.openDocuments)

                Spacer()

                HStack(spacing: 20) {
                    if features.bookmarks {
                        bookmarkButton
                    }
                    if features.search {
                        Button { showSearch = true } label: {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 17))
                        }
                        .accessibilityLabel(strings.search)
                    }
                    moreMenu
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 10)
        .background(Color(theme.toolbarBackgroundColor))
    }

    // MARK: - Subviews

    private var bookmarkButton: some View {
        Button(action: viewModel.toggleBookmark) {
            Image(systemName: viewModel.isCurrentPageBookmarked ? "bookmark.fill" : "bookmark")
                .font(.system(size: 17))
        }
        .accessibilityLabel(viewModel.isCurrentPageBookmarked ? strings.removeBookmark : strings.addBookmark)
    }

    private var moreMenu: some View {
        Menu {
            if features.pageNavigation {
                Section {
                    Button { viewModel.goToFirstPage() } label: {
                        Label(strings.firstPage, systemImage: "arrow.up.to.line")
                    }
                    Button { viewModel.goToPreviousPage() } label: {
                        Label(strings.previousPage, systemImage: "chevron.up")
                    }
                    Button { viewModel.goToNextPage() } label: {
                        Label(strings.nextPage, systemImage: "chevron.down")
                    }
                    Button { viewModel.goToLastPage() } label: {
                        Label(strings.lastPage, systemImage: "arrow.down.to.line")
                    }
                }
            }

            Section {
                if features.bookmarks {
                    Button { showBookmarks = true } label: {
                        Label(strings.bookmarks, systemImage: "bookmark")
                    }
                }
                if features.thumbnails {
                    Button { showThumbnails = true } label: {
                        Label(strings.thumbnails, systemImage: "square.grid.2x2")
                    }
                }
                if features.outline && viewModel.hasOutline {
                    Button { showOutline = true } label: {
                        Label(strings.tableOfContents, systemImage: "list.bullet.indent")
                    }
                }
                if features.goToPage {
                    Button { showGoToPage = true } label: {
                        Label(strings.goToPage, systemImage: "number")
                    }
                }
            }

            if features.scrollDirection {
                Section(strings.scrollDirection) {
                    Button { viewModel.changeScrollDirection(to: .vertical) } label: {
                        Label(
                            strings.vertical,
                            systemImage: viewModel.scrollDirection == .vertical ? "checkmark" : "arrow.up.arrow.down"
                        )
                    }
                    Button { viewModel.changeScrollDirection(to: .horizontal) } label: {
                        Label(
                            strings.horizontal,
                            systemImage: viewModel.scrollDirection == .horizontal ? "checkmark" : "arrow.left.arrow.right"
                        )
                    }
                }
            }

            if features.zoomControls {
                Section {
                    Button { viewModel.zoomIn() } label: {
                        Label(strings.zoomIn, systemImage: "plus.magnifyingglass")
                    }
                    Button { viewModel.zoomOut() } label: {
                        Label(strings.zoomOut, systemImage: "minus.magnifyingglass")
                    }
                    Button { viewModel.resetZoom() } label: {
                        Label(strings.resetZoom, systemImage: "arrow.up.left.and.arrow.down.right")
                    }
                }
            }

            Section {
                if features.documentInfo {
                    Button { showDocumentInfo = true } label: {
                        Label(strings.documentInfo, systemImage: "info.circle")
                    }
                }
                if features.sharing {
                    Button { showShare = true } label: {
                        Label(strings.share, systemImage: "square.and.arrow.up")
                    }
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.system(size: 17))
        }
        .accessibilityLabel(strings.more)
    }
}
