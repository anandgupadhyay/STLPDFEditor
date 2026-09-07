import SwiftUI

struct PDFBookmarkListView: View {

    @ObservedObject var viewModel: PDFViewerViewModel
    let strings: PDFViewerStrings
    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
            Group {
                if viewModel.bookmarks.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "bookmark.slash")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text(strings.noBookmarks)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(viewModel.bookmarks) { bookmark in
                            Button {
                                viewModel.navigate(to: bookmark)
                                isPresented = false
                            } label: {
                                HStack {
                                    Image(systemName: "bookmark.fill")
                                        .foregroundColor(.accentColor)
                                    Text("\(strings.page) \(bookmark.displayPageNumber)")
                                    if let label = bookmark.pageLabel, !label.isEmpty, label != "\(bookmark.displayPageNumber)" {
                                        Text("(\(label))")
                                            .foregroundColor(.secondary)
                                            .font(.caption)
                                    }
                                }
                            }
                            .foregroundColor(.primary)
                        }
                        .onDelete { indexSet in
                            indexSet.forEach { viewModel.remove(bookmark: viewModel.bookmarks[$0]) }
                        }
                    }
                }
            }
            .navigationTitle(strings.bookmarks)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(strings.done) { isPresented = false }
                }
            }
        }
    }
}
