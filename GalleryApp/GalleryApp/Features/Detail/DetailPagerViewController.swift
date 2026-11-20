import UIKit

/// Container that lets the user swipe left/right between photos.
final class DetailPagerViewController: UIPageViewController {
    private let photos: [Photo]
    private let startIndex: Int
    private let favourites: FavouritesRepositoryProtocol

    init(photos: [Photo], startIndex: Int, favourites: FavouritesRepositoryProtocol) {
        self.photos = photos
        self.startIndex = startIndex
        self.favourites = favourites
        super.init(transitionStyle: .scroll,
                   navigationOrientation: .horizontal,
                   options: [.interPageSpacing: 16])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.largeTitleDisplayMode = .never
        dataSource = self
        setViewControllers([makePage(at: startIndex)], direction: .forward, animated: false)
    }

    private func makePage(at index: Int) -> DetailViewController {
        let viewModel = DetailViewModel(photo: photos[index], repository: favourites)
        return DetailViewController(index: index, viewModel: viewModel)
    }
}

// MARK: - UIPageViewControllerDataSource

extension DetailPagerViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let page = viewController as? DetailViewController, page.index > 0 else { return nil }
        return makePage(at: page.index - 1)
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let page = viewController as? DetailViewController, page.index < photos.count - 1 else { return nil }
        return makePage(at: page.index + 1)
    }
}
