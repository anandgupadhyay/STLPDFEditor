import SwiftUI

struct PDFDocumentInfoView: View {

    let metadata: PDFDocumentMetadata
    let strings: PDFViewerStrings
    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
            List {
                row(label: "Title", value: metadata.title)
                row(label: "Author", value: metadata.author)
                row(label: "Subject", value: metadata.subject)
                row(label: "Creator", value: metadata.creator)
                row(label: "Pages", value: "\(metadata.pageCount)")
            }
            .navigationTitle(strings.documentInfo)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(strings.done) { isPresented = false }
                }
            }
        }
    }

    @ViewBuilder
    private func row(label: String, value: String?) -> some View {
        if let value, !value.isEmpty {
            HStack {
                Text(label)
                    .foregroundColor(.secondary)
                Spacer()
                Text(value)
                    .multilineTextAlignment(.trailing)
            }
        }
    }
}
