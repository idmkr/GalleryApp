import XCTest
@testable import GalleryApp

@MainActor
final class GalleryViewModelTests: XCTestCase {
    func test_loadNextPage_appendsPhotos() async {
        let service = MockPhotosService(result: .success([.fixture(id: "1"), .fixture(id: "2")]))
        let viewModel = GalleryViewModel(service: service, favourites: MockFavourites())

        await viewModel.loadNextPage()
        await viewModel.loadNextPage()

        XCTAssertEqual(service.requestedPages, [1, 2])
        XCTAssertEqual(viewModel.photos.count, 4)
        XCTAssertFalse(viewModel.isLoading)
    }

    func test_loadNextPage_onError_setsErrorMessage() async {
        let service = MockPhotosService(result: .failure(NetworkError.rateLimitExceeded))
        let viewModel = GalleryViewModel(service: service, favourites: MockFavourites())

        await viewModel.loadNextPage()

        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.photos.isEmpty)
    }

    func test_loadNextPage_afterEmptyPage_stopsRequesting() async {
        let service = MockPhotosService(result: .success([]))
        let viewModel = GalleryViewModel(service: service, favourites: MockFavourites())

        await viewModel.loadNextPage()
        await viewModel.loadNextPage()

        XCTAssertEqual(service.requestedPages, [1])
    }

    func test_loadMoreIfNeeded_nearEnd_loadsNextPage() async {
        let service = MockPhotosService(result: .success((1...10).map { .fixture(id: "\($0)") }))
        let viewModel = GalleryViewModel(service: service, favourites: MockFavourites())
        await viewModel.loadNextPage()

        await viewModel.loadMoreIfNeeded(currentIndex: 9)

        XCTAssertEqual(service.requestedPages, [1, 2])
    }

    func test_loadMoreIfNeeded_farFromEnd_doesNothing() async {
        let service = MockPhotosService(result: .success((1...10).map { .fixture(id: "\($0)") }))
        let viewModel = GalleryViewModel(service: service, favourites: MockFavourites())
        await viewModel.loadNextPage()

        await viewModel.loadMoreIfNeeded(currentIndex: 0)

        XCTAssertEqual(service.requestedPages, [1])
    }

    func test_isFavourite_reflectsRepository() async throws {
        let favourites = MockFavourites()
        let viewModel = GalleryViewModel(service: MockPhotosService(result: .success([])), favourites: favourites)
        let photo = Photo.fixture(id: "7")

        XCTAssertFalse(viewModel.isFavourite(photo))
        try favourites.toggle(photo)
        XCTAssertTrue(viewModel.isFavourite(photo))
    }
}
