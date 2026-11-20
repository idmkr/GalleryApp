import Foundation
import Combine

@MainActor
final class FavouritesViewModel {
    @Published private(set) var photos: [Photo] = []
    @Published private(set) var errorMessage: String?

    let repository: FavouritesRepositoryProtocol

    init(repository: FavouritesRepositoryProtocol) {
        self.repository = repository
        self.photos = repository.favourites
        repository.favouritesPublisher.assign(to: &$photos)
    }

    func remove(_ photo: Photo) {
        do {
            try repository.remove(id: photo.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
