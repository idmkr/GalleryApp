import XCTest
@testable import GalleryApp

@MainActor
final class FavouritesRepositoryTests: XCTestCase {
    private func makeRepository() -> FavouritesRepository {
        FavouritesRepository(stack: CoreDataStack(inMemory: true))
    }

    func test_toggle_addsPhotoToFavourites() throws {
        let repository = makeRepository()

        try repository.toggle(.fixture(id: "1"))

        XCTAssertTrue(repository.isFavourite(id: "1"))
        XCTAssertEqual(repository.favourites.count, 1)
        XCTAssertEqual(repository.favourites.first?.user.name, "Author")
    }

    func test_toggleTwice_removesPhoto() throws {
        let repository = makeRepository()

        try repository.toggle(.fixture(id: "1"))
        try repository.toggle(.fixture(id: "1"))

        XCTAssertFalse(repository.isFavourite(id: "1"))
        XCTAssertTrue(repository.favourites.isEmpty)
    }

    func test_remove_deletesOnlyRequestedPhoto() throws {
        let repository = makeRepository()
        try repository.toggle(.fixture(id: "1"))
        try repository.toggle(.fixture(id: "2"))

        try repository.remove(id: "1")

        XCTAssertEqual(repository.favourites.map(\.id), ["2"])
    }
}
