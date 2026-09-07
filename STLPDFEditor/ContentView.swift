import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {

    @State private var showFilePicker = false
    @State private var showPDFViewer = false
    @State private var selectedURL: URL?

    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Image(systemName: "doc.richtext")
                    .font(.system(size: 72))
                    .foregroundStyle(.tint)

                VStack(spacing: 8) {
                    Text("STL PDF Editor")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Pick any PDF from your device to open it in the viewer.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Button {
                    showFilePicker = true
                } label: {
                    Label("Choose PDF", systemImage: "folder")
                        .frame(minWidth: 200)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                if let url = selectedURL {
                    Button {
                        showPDFViewer = true
                    } label: {
                        Label(url.lastPathComponent, systemImage: "doc.fill")
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .frame(minWidth: 200)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
            }
            .padding()
            .navigationTitle("PDF Editor")
            // File picker — iOS 14+ fileImporter handles security-scoped access.
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [UTType.pdf],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    selectedURL = url
                    showPDFViewer = true
                }
            }
            .fullScreenCover(isPresented: $showPDFViewer) {
                if let url = selectedURL {
                    PDFViewerView(
                        fileURL: url,
                        configuration: PDFViewerConfiguration(
                            features: PDFViewerFeatures(showsCloseButton: true),
                            theme: PDFViewerTheme(primaryColor: UIColor.systemIndigo)
                        )
                    )
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
