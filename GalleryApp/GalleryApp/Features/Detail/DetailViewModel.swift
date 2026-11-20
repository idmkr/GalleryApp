import Foundation
import Combine

@MainActor
final class DetailViewModel {
    let photo: Photo
    @Published private(set) var isFavourite: Bool
    @Published private(set) var errorMessage: String?

    private let repository: FavouritesRepositoryProtocol

    init(photo: Photo, repository: FavouritesRepositoryProtocol) {
        self.photo = photo
        self.repository = repository
        self.isFavourite = repository.isFavourite(id: photo.id)

        let photoID = photo.id
        repository.favouritesPublisher
            .map { favourites in favourites.contains { $0.id == photoID } }
            .removeDuplicates()
            .assign(to: &$isFavourite)
    }

    var title: String { photo.title }
    var author: String { "Photo by \(photo.user.name)" }
    var description: String? { photo.details ?? photo.altDescription }

    func toggleFavourite() {
        do {
            try repository.toggle(photo)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
