import SwiftUI

struct PDFSearchView: View {

    @ObservedObject var viewModel: PDFViewerViewModel
    let strings: PDFViewerStrings
    @Binding var isPresented: Bool
    @FocusState private var isFieldFocused: Bool

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                searchBar
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(.systemBackground))

                Divider()

                content
            }
            .navigationTitle(strings.search)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(strings.cancel) {
                        viewModel.clearSearch()
                        isPresented = false
                    }
                }
            }
        }
        .onAppear { isFieldFocused = true }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField(strings.search, text: $viewModel.searchText)
                .focused($isFieldFocused)
                .submitLabel(.search)
                .onSubmit { viewModel.performSearch() }
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.clearSearch()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }

            Button {
                isFieldFocused = false
                viewModel.performSearch()
            } label: {
                Text("Search")
                    .fontWeight(.medium)
            }
            .disabled(viewModel.searchText.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(10)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if viewModel.isSearching {
            Spacer()
            VStack(spacing: 12) {
                ProgressView()
                Text("Searching\u{2026}")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            }
            Spacer()
        } else if !viewModel.searchText.isEmpty && viewModel.searchResults.isEmpty {
            emptyState
        } else if !viewModel.searchResults.isEmpty {
            resultsList
        } else {
            Spacer()
            Text("Enter a keyword to search the document.")
                .foregroundColor(.secondary)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }

    // MARK: - Results List

    private var resultsList: some View {
        List {
            Section {
                let totalMatches = viewModel.searchResults.reduce(0) { $0 + $1.matchCount }
                Text("\(totalMatches) match\(totalMatches == 1 ? "" : "es") on \(viewModel.searchResults.count) page\(viewModel.searchResults.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            ForEach(viewModel.searchResults) { result in
                Button {
                    viewModel.navigateToSearchResult(result)
                    isPresented = false
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(.accentColor)
                            .font(.system(size: 20))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(strings.page) \(result.displayPageNumber)")
                                .font(.body)
                                .foregroundColor(.primary)
                            Text("\(result.matchCount) occurrence\(result.matchCount == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text(strings.noSearchResults)
                .font(.headline)
                .foregroundColor(.secondary)
            Text("No matches found for \"\(viewModel.searchText)\"")
                .font(.subheadline)
                .foregroundColor(Color(.tertiaryLabel))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }
}
