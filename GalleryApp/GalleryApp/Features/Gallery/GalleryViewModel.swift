import Foundation
import Combine

@MainActor
final class GalleryViewModel {
    @Published private(set) var photos: [Photo] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let service: PhotosServiceProtocol
    private var currentPage = 0
    private var canLoadMore = true

    init(service: PhotosServiceProtocol = PhotosService()) {
        self.service = service
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

    /// Вызывается, когда на экране показывается ячейка с данным индексом.
    func loadMoreIfNeeded(currentIndex: Int) async {
        let threshold = photos.count - 5
        if currentIndex >= threshold {
            await loadNextPage()
        }
    }
}
