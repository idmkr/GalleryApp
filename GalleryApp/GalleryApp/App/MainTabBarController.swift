import UIKit

final class MainTabBarController: UITabBarController {
    init(favourites: FavouritesRepositoryProtocol, service: PhotosServiceProtocol) {
        super.init(nibName: nil, bundle: nil)

        let galleryViewModel = GalleryViewModel(service: service, favourites: favourites)
        let gallery = UINavigationController(
            rootViewController: GalleryViewController(viewModel: galleryViewModel))
        gallery.tabBarItem = UITabBarItem(title: "Gallery",
                                          image: UIImage(systemName: "photo.on.rectangle"),
                                          tag: 0)

        let favouritesViewModel = FavouritesViewModel(repository: favourites)
        let favouritesList = UINavigationController(
            rootViewController: FavouritesViewController(viewModel: favouritesViewModel))
        favouritesList.tabBarItem = UITabBarItem(title: "Favourites",
                                                 image: UIImage(systemName: "heart"),
                                                 tag: 1)

        viewControllers = [gallery, favouritesList]
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
