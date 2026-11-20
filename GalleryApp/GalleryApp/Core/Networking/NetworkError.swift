import Foundation

enum NetworkError: LocalizedError {
    case missingAPIKey
    case invalidURL
    case rateLimitExceeded
    case badStatusCode(Int)
    case decodingFailed
    case transport(Error)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey: return "API key is missing. Check Config.xcconfig."
        case .invalidURL: return "Invalid request URL."
        case .rateLimitExceeded: return "Request limit reached. Try again later."
        case .badStatusCode(let code): return "Server error (\(code))."
        case .decodingFailed: return "Could not read server response."
        case .transport(let error): return error.localizedDescription
        }
    }
}
