import Foundation
import Combine
@testable import GalleryApp

extension Photo {
    static func fixture(id: String = "1") -> Photo {
        Photo(
            id: id,
            width: 400,
            height: 300,
            details: "Description \(id)",
            altDescription: nil,
            urls: .init(
                regular: URL(string: "https://example.com/\(id)/regular.jpg")!,
                small: URL(string: "https://example.com/\(id)/small.jpg")!,
                thumb: URL(string: "https://example.com/\(id)/thumb.jpg")!),
            user: .init(name: "Author"))
    }
}

final class MockNetworkSession: NetworkSession {
    var result: Result<(Data, URLResponse), Error>
    private(set) var lastRequest: URLRequest?

    init(result: Result<(Data, URLResponse), Error>) {
        self.result = result
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        lastRequest = request
        return try result.get()
    }

    static func response(status: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: URL(string: "https://api.unsplash.com")!,
                        statusCode: status,
                        httpVersion: nil,
                        headerFields: nil)!
    }
}

final class MockPhotosService: PhotosServiceProtocol {
    var result: Result<[Photo], Error>
    private(set) var requestedPages: [Int] = []

    init(result: Result<[Photo], Error>) {
        self.result = result
    }

    func fetchPhotos(page: Int) async throws -> [Photo] {
        requestedPages.append(page)
        return try result.get()
    }
}

@MainActor
final class MockFavourites: FavouritesRepositoryProtocol {
    @Published private(set) var favourites: [Photo] = []

    var favouritesPublisher: AnyPublisher<[Photo], Never> {
        $favourites.eraseToAnyPublisher()
    }

    func isFavourite(id: String) -> Bool {
        favourites.contains { $0.id == id }
    }

    func toggle(_ photo: Photo) throws {
        if isFavourite(id: photo.id) {
            try remove(id: photo.id)
        } else {
            favourites.append(photo)
        }
    }

    func remove(id: String) throws {
        favourites.removeAll { $0.id == id }
    }
}
