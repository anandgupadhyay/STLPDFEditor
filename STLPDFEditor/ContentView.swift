import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {

    @State private var showFilePicker = false
    /// The document to present. Using an item-driven cover (instead of a separate boolean + URL)
    /// avoids a state race where the cover could build before the URL was set.
    @State private var openTarget: OpenTarget?

    /// Shared session so the dashboard can list and close documents opened in the viewer.
    @ObservedObject private var session = PDFViewerSession.shared

    private let themeColor = UIColor.systemIndigo

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Image(systemName: "doc.richtext")
                    .font(.system(size: 64))
                    .foregroundStyle(.tint)

                VStack(spacing: 8) {
                    Text(PDFViewerLocalization.string("appTitle"))
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text(PDFViewerLocalization.string("appSubtitle"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Button {
                    showFilePicker = true
                } label: {
                    Label(PDFViewerLocalization.string("appChoosePDF"), systemImage: "folder")
                        .frame(minWidth: 200)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                openDocumentsSection
            }
            .padding()
            .navigationTitle(PDFViewerLocalization.string("appNavTitle"))
            // File picker — iOS 14+ fileImporter handles security-scoped access.
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [UTType.pdf],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    openTarget = OpenTarget(url: url)
                }
            }
            .fullScreenCover(item: $openTarget) { target in
                PDFViewerView(
                    fileURL: target.url,
                    configuration: PDFViewerConfiguration(
                        features: PDFViewerFeatures(showsCloseButton: true),
                        theme: PDFViewerTheme(primaryColor: themeColor)
                    )
                )
            }
        }
        .tint(Color(themeColor))
    }

    // MARK: - Open Documents (session)

    @ViewBuilder
    private var openDocumentsSection: some View {
        if !session.openDocuments.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(PDFViewerLocalization.string("openDocuments"))
                        .font(.headline)
                    Spacer()
                    Button(PDFViewerLocalization.string("closeAll"), role: .destructive) {
                        session.clear()
                        openTarget = nil
                    }
                    .font(.subheadline)
                }

                List {
                    ForEach(session.openDocuments) { document in
                        Button {
                            openTarget = OpenTarget(url: document.url)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "doc.text.fill")
                                    .foregroundColor(.accentColor)
                                Text(document.title)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { session.remove(session.openDocuments[$0]) }
                    }
                }
                .listStyle(.plain)
                .frame(maxHeight: 240)
            }
            .padding(.top, 8)
        }
    }
}

/// Identifiable wrapper so the viewer can be presented via `fullScreenCover(item:)`.
/// A fresh id per selection guarantees the cover re-presents even for the same URL.
private struct OpenTarget: Identifiable {
    let id = UUID()
    let url: URL
}

#Preview {
    ContentView()
}
