import SwiftUI

struct PDFOutlineView: View {

    @ObservedObject var viewModel: PDFViewerViewModel
    let strings: PDFViewerStrings
    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
            Group {
                if viewModel.outlineItems.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "list.bullet.indent")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text(strings.noOutline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(viewModel.outlineItems, id: \.id, children: \.optionalChildren) { item in
                        Button {
                            viewModel.navigate(to: item)
                            isPresented = false
                        } label: {
                            HStack {
                                Text(item.title.isEmpty ? strings.untitled : item.title)
                                Spacer()
                                if let page = item.pageIndex {
                                    Text("\(page + 1)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
            }
            .navigationTitle(strings.tableOfContents)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(strings.done) { isPresented = false }
                }
            }
        }
    }
}

private extension PDFOutlineItem {
    var optionalChildren: [PDFOutlineItem]? {
        children.isEmpty ? nil : children
    }
}
