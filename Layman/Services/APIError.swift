import Foundation

enum APIError: LocalizedError {
    case missingConfiguration(String)
    case invalidResponse
    case server(String)

    var errorDescription: String? {
        switch self {
        case .missingConfiguration(let message):
            return message
        case .invalidResponse:
            return "The server response could not be read."
        case .server(let message):
            return message
        }
    }
}
