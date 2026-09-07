import SwiftUI

struct PDFPasswordView: View {

    @ObservedObject var viewModel: PDFViewerViewModel
    let strings: PDFViewerStrings
    @State private var password: String = ""

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.doc.fill")
                .font(.system(size: 56))
                .foregroundColor(.secondary)

            Text(strings.enterPassword)
                .font(.title2)
                .fontWeight(.semibold)

            SecureField(strings.enterPassword, text: $password)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 32)

            if let error = viewModel.passwordError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }

            Button(strings.done) {
                viewModel.submitPassword(password)
            }
            .buttonStyle(.borderedProminent)
            .disabled(password.isEmpty)
        }
        .padding()
    }
}
