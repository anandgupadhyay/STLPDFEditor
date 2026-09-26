import SwiftUI

/// Lists documents opened during the current session and lets the user reopen one
/// or close them all. Session-scoped; the list is empty again after an app relaunch.
struct PDFRecentDocumentsView: View {

    @ObservedObject var session: PDFViewerSession
    let strings: PDFViewerStrings
    /// URL of the document currently shown, so it can be marked in the list.
    let currentURL: URL
    @Binding var isPresented: Bool
    let onSelect: (OpenDocument) -> Void
    let onClose: (OpenDocument) -> Void
    let onCloseAll: () -> Void

    var body: some View {
        NavigationView {
            Group {
                if session.openDocuments.isEmpty {
                    emptyState
                } else {
                    documentList
                }
            }
            .navigationTitle(strings.openDocuments)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(strings.done) { isPresented = false }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(strings.closeAll, role: .destructive) {
                        onCloseAll()
                    }
                    .disabled(session.openDocuments.isEmpty)
                }
            }
        }
    }

    private var documentList: some View {
        List {
            ForEach(session.openDocuments) { document in
                Button {
                    onSelect(document)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(.accentColor)
                            .font(.system(size: 22))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(document.title)
                                .font(.body)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            Text(document.url.lastPathComponent)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }

                        Spacer()

                        if document.url == currentURL {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                    .padding(.vertical, 2)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button {
                        onClose(document)
                    } label: {
                        Label(strings.close, systemImage: "xmark.circle")
                    }
                    .tint(.red)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "rectangle.stack.badge.xmark")
                .font(.system(size: 44))
                .foregroundColor(.secondary)
            Text(strings.noOpenDocuments)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
