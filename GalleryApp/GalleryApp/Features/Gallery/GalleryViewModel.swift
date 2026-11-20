import Foundation
import Combine

@MainActor
final class GalleryViewModel {
    @Published private(set) var photos: [Photo] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    let favourites: FavouritesRepositoryProtocol
    private let service: PhotosServiceProtocol
    private var currentPage = 0
    private var canLoadMore = true

    init(service: PhotosServiceProtocol, favourites: FavouritesRepositoryProtocol) {
        self.service = service
        self.favourites = favourites
    }

    func isFavourite(_ photo: Photo) -> Bool {
        favourites.isFavourite(id: photo.id)
    }

    func loadNextPage() async {
        guard !isLoading, canLoadMore else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let nextPage = currentPage + 1
            let newPhotos = try await service.fetchPhotos(page: nextPage)
            currentPage = nextPage
            canLoadMore = !newPhotos.isEmpty
            photos.append(contentsOf: newPhotos)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Called when a cell with the given index is about to be displayed.
    func loadMoreIfNeeded(currentIndex: Int) async {
        if currentIndex >= photos.count - 5 {
            await loadNextPage()
        }
    }
}
