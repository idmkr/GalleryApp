import Foundation

/// Abstraction over URLSession so the network can be mocked in tests.
protocol NetworkSession {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: NetworkSession {}

protocol PhotosServiceProtocol {
    func fetchPhotos(page: Int) async throws -> [Photo]
}

final class PhotosService: PhotosServiceProtocol {
    private let session: NetworkSession
    private let accessKey: String?
    private let perPage = 30

    init(session: NetworkSession = URLSession.shared,
         accessKey: String? = APIConfig.unsplashAccessKey) {
        self.session = session
        self.accessKey = accessKey
    }

    func fetchPhotos(page: Int) async throws -> [Photo] {
        guard let accessKey else { throw NetworkError.missingAPIKey }

        var components = URLComponents(string: "https://api.unsplash.com/photos")
        components?.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "per_page", value: String(perPage))
        ]
        guard let url = components?.url else { throw NetworkError.invalidURL }

        var request = URLRequest(url: url)
        request.setValue("Client-ID \(accessKey)", forHTTPHeaderField: "Authorization")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw NetworkError.transport(error)
        }

        if let http = response as? HTTPURLResponse {
            switch http.statusCode {
            case 200..<300: break
            case 403: throw NetworkError.rateLimitExceeded
            default: throw NetworkError.badStatusCode(http.statusCode)
            }
        }

        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode([Photo].self, from: data)
        } catch {
            throw NetworkError.decodingFailed
        }
    }
}
