import XCTest
@testable import GalleryApp

final class PhotosServiceTests: XCTestCase {
    private let json = """
    [{
        "id": "abc",
        "width": 4000,
        "height": 3000,
        "description": "A mountain",
        "alt_description": "snowy peak",
        "urls": {
            "regular": "https://example.com/regular.jpg",
            "small": "https://example.com/small.jpg",
            "thumb": "https://example.com/thumb.jpg"
        },
        "user": { "name": "Jane" }
    }]
    """

    func test_fetchPhotos_decodesResponseAndSendsAuthHeader() async throws {
        let session = MockNetworkSession(result: .success((Data(json.utf8), MockNetworkSession.response(status: 200))))
        let service = PhotosService(session: session, accessKey: "test-key")

        let photos = try await service.fetchPhotos(page: 2)

        XCTAssertEqual(photos.count, 1)
        XCTAssertEqual(photos.first?.id, "abc")
        XCTAssertEqual(photos.first?.title, "A mountain")
        XCTAssertEqual(session.lastRequest?.value(forHTTPHeaderField: "Authorization"), "Client-ID test-key")
        XCTAssertEqual(session.lastRequest?.url?.query?.contains("page=2"), true)
        XCTAssertEqual(session.lastRequest?.url?.query?.contains("per_page=30"), true)
    }

    func test_fetchPhotos_withoutKey_throwsMissingAPIKey() async {
        let session = MockNetworkSession(result: .success((Data(), MockNetworkSession.response(status: 200))))
        let service = PhotosService(session: session, accessKey: nil)

        do {
            _ = try await service.fetchPhotos(page: 1)
            XCTFail("Expected an error")
        } catch NetworkError.missingAPIKey {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_fetchPhotos_status403_throwsRateLimit() async {
        let session = MockNetworkSession(result: .success((Data(), MockNetworkSession.response(status: 403))))
        let service = PhotosService(session: session, accessKey: "test-key")

        do {
            _ = try await service.fetchPhotos(page: 1)
            XCTFail("Expected an error")
        } catch NetworkError.rateLimitExceeded {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_fetchPhotos_invalidJSON_throwsDecodingFailed() async {
        let session = MockNetworkSession(result: .success((Data("oops".utf8), MockNetworkSession.response(status: 200))))
        let service = PhotosService(session: session, accessKey: "test-key")

        do {
            _ = try await service.fetchPhotos(page: 1)
            XCTFail("Expected an error")
        } catch NetworkError.decodingFailed {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
