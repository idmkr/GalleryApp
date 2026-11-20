import CoreData
import Combine

@MainActor
protocol FavouritesRepositoryProtocol: AnyObject {
    var favouritesPublisher: AnyPublisher<[Photo], Never> { get }
    var favourites: [Photo] { get }
    func isFavourite(id: String) -> Bool
    func toggle(_ photo: Photo) throws
    func remove(id: String) throws
}

@MainActor
final class FavouritesRepository: FavouritesRepositoryProtocol {
    @Published private(set) var favourites: [Photo] = []

    var favouritesPublisher: AnyPublisher<[Photo], Never> {
        $favourites.eraseToAnyPublisher()
    }

    private let context: NSManagedObjectContext

    init(stack: CoreDataStack) {
        self.context = stack.viewContext
        reload()
    }

    func isFavourite(id: String) -> Bool {
        favourites.contains { $0.id == id }
    }

    func toggle(_ photo: Photo) throws {
        if isFavourite(id: photo.id) {
            try remove(id: photo.id)
        } else {
            try add(photo)
        }
    }

    func remove(id: String) throws {
        let request = FavouritePhotoEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        try context.fetch(request).forEach(context.delete)
        try saveAndReload()
    }

    // MARK: - Private

    private func add(_ photo: Photo) throws {
        let entity = FavouritePhotoEntity(context: context)
        entity.id = photo.id
        entity.width = Int32(photo.width)
        entity.height = Int32(photo.height)
        entity.details = photo.details
        entity.altDescription = photo.altDescription
        entity.authorName = photo.user.name
        entity.thumbURL = photo.urls.thumb.absoluteString
        entity.smallURL = photo.urls.small.absoluteString
        entity.regularURL = photo.urls.regular.absoluteString
        entity.addedAt = Date()
        try saveAndReload()
    }

    private func saveAndReload() throws {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                context.rollback()
                throw error
            }
        }
        reload()
    }

    private func reload() {
        let request = FavouritePhotoEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "addedAt", ascending: false)]
        let entities = (try? context.fetch(request)) ?? []
        favourites = entities.compactMap(Self.makePhoto)
    }

    private static func makePhoto(from entity: FavouritePhotoEntity) -> Photo? {
        guard let id = entity.id,
              let thumb = entity.thumbURL.flatMap(URL.init(string:)),
              let small = entity.smallURL.flatMap(URL.init(string:)),
              let regular = entity.regularURL.flatMap(URL.init(string:)) else { return nil }
        return Photo(
            id: id,
            width: Int(entity.width),
            height: Int(entity.height),
            details: entity.details,
            altDescription: entity.altDescription,
            urls: .init(regular: regular, small: small, thumb: thumb),
            user: .init(name: entity.authorName ?? "")
        )
    }
}
