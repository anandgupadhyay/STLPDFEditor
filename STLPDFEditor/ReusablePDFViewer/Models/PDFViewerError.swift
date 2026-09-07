import Foundation

/// Errors that can occur during PDF document loading and interaction.
public enum PDFViewerError: LocalizedError, Equatable {
    case fileNotFound
    case invalidDocument
    case emptyDocument
    case unableToLoad
    case passwordRequired
    case incorrectPassword
    case invalidPage

    public var errorDescription: String? {
        switch self {
        case .fileNotFound:       return "The PDF file could not be found."
        case .invalidDocument:    return "The file is not a valid PDF document."
        case .emptyDocument:      return "The PDF document contains no pages."
        case .unableToLoad:       return "Unable to open the PDF document."
        case .passwordRequired:   return "This PDF is password protected."
        case .incorrectPassword:  return "The password is incorrect."
        case .invalidPage:        return "The requested page number is invalid."
        }
    }

    /// Converts to NSError for Objective-C delegate callbacks.
    public var asNSError: NSError {
        NSError(
            domain: "PDFViewerError",
            code: errorCode,
            userInfo: [NSLocalizedDescriptionKey: errorDescription ?? ""]
        )
    }

    private var errorCode: Int {
        switch self {
        case .fileNotFound:      return 1
        case .invalidDocument:   return 2
        case .emptyDocument:     return 3
        case .unableToLoad:      return 4
        case .passwordRequired:  return 5
        case .incorrectPassword: return 6
        case .invalidPage:       return 7
        }
    }
}
