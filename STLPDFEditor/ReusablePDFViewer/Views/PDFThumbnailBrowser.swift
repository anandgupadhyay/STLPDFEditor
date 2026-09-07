import SwiftUI
import PDFKit

struct PDFThumbnailBrowser: View {

    let document: PDFDocument
    @ObservedObject var viewModel: PDFViewerViewModel
    let strings: PDFViewerStrings
    @Binding var isPresented: Bool

    private let columns = [GridItem(.adaptive(minimum: 100, maximum: 140))]

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(0..<document.pageCount, id: \.self) { index in
                        ThumbnailCell(
                            document: document,
                            pageIndex: index,
                            isCurrentPage: viewModel.currentPageIndex == index,
                            strings: strings
                        ) {
                            viewModel.controller?.go(toPageIndex: index)
                            isPresented = false
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(strings.thumbnails)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(strings.done) { isPresented = false }
                }
            }
        }
    }
}

private struct ThumbnailCell: View {

    let document: PDFDocument
    let pageIndex: Int
    let isCurrentPage: Bool
    let strings: PDFViewerStrings
    let action: () -> Void

    @State private var thumbnail: UIImage?

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    if let image = thumbnail {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(4)
                    } else {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.secondarySystemBackground))
                            .aspectRatio(0.75, contentMode: .fit)
                        ProgressView()
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(isCurrentPage ? Color.accentColor : Color.clear, lineWidth: 2)
                )

                Text("\(pageIndex + 1)")
                    .font(.caption2)
                    .foregroundColor(isCurrentPage ? .accentColor : .secondary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(strings.page) \(pageIndex + 1)")
        .task {
            await loadThumbnail()
        }
    }

    private func loadThumbnail() async {
        guard thumbnail == nil, let page = document.page(at: pageIndex) else { return }
        let size = CGSize(width: 120, height: 160)
        let image = await Task.detached(priority: .background) {
            page.thumbnail(of: size, for: .cropBox)
        }.value
        thumbnail = image
    }
}

