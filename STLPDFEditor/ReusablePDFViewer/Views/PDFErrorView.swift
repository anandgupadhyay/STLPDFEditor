import SwiftUI

struct PDFErrorView: View {

    let error: PDFViewerError
    let strings: PDFViewerStrings

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text(strings.unableToOpenPDF)
                .font(.headline)

            Text(error.errorDescription ?? "")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding()
    }
}
