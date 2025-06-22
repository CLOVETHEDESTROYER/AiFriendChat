import Foundation

/// Represents possible errors that can occur during call operations
enum CallError: Error {
    /// User is not authenticated
    case unauthorized
    /// User does not have permission to perform the action
    case forbidden
    /// Requested resource was not found
    case notFound
    /// The URL provided is invalid
    case invalidURL
    /// The server response was invalid or could not be parsed
    case invalidResponse
    /// An error returned from the API with a specific message
    case apiError(String)
    /// A network-related error occurred
    case networkError(Error)
    /// An unknown error occurred
    case unknown
    
    var localizedDescription: String {
        switch self {
        case .unauthorized:
            return "Please log in to continue"
        case .forbidden:
            return "You don't have permission to perform this action"
        case .notFound:
            return "The requested resource was not found"
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .apiError(let message):
            return message
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}

/// Represents an error response from the API
struct ErrorResponse: Codable {
    /// The error message returned by the server
    let message: String
} 