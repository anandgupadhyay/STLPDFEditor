import Foundation

/// Optionally persists the last viewed page per document identifier.
/// Injected into the ViewModel when restoresLastViewedPage is enabled.
public protocol PDFLastPageStoring {
    func lastPage(for documentIdentifier: String) -> Int?
    func save(lastPage: Int, for documentIdentifier: String)
}

public final class UserDefaultsPDFLastPageStore: PDFLastPageStoring {

    private let defaults: UserDefaults
    private let key = "PDFViewerLastPages"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func lastPage(for documentIdentifier: String) -> Int? {
        let dict = defaults.dictionary(forKey: key) as? [String: Int] ?? [:]
        return dict[documentIdentifier]
    }

    public func save(lastPage: Int, for documentIdentifier: String) {
        var dict = defaults.dictionary(forKey: key) as? [String: Int] ?? [:]
        dict[documentIdentifier] = lastPage
        defaults.set(dict, forKey: key)
    }
}
