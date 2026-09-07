import SwiftUI

struct PDFGoToPageView: View {

    @ObservedObject var viewModel: PDFViewerViewModel
    let strings: PDFViewerStrings
    @Binding var isPresented: Bool

    @State private var inputText: String = ""
    @State private var showError: Bool = false

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("\(strings.page) 1–\(viewModel.pageCount)", text: $inputText)
                        .keyboardType(.numberPad)
                }

                if showError {
                    Section {
                        Text(strings.invalidPage)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle(strings.goToPage)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(strings.cancel) { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(strings.done) { commit() }
                        .disabled(inputText.isEmpty)
                }
            }
        }
    }

    private func commit() {
        guard let page = Int(inputText) else {
            showError = true
            return
        }
        if viewModel.goToPage(page) {
            isPresented = false
        } else {
            showError = true
        }
    }
}
