import UIKit
import Combine

final class FavouritesViewController: UIViewController {
    private enum Section { case main }

    private let viewModel: FavouritesViewModel
    private var cancellables = Set<AnyCancellable>()
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Section, Photo>!
    private let emptyLabel = UILabel()

    init(viewModel: FavouritesViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        title = "Favourites"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupCollectionView()
        setupEmptyLabel()
        setupDataSource()
        bindViewModel()
    }

    // MARK: - Setup

    private func setupCollectionView() {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.delegate = self
        collectionView.register(PhotoCell.self, forCellWithReuseIdentifier: PhotoCell.reuseIdentifier)
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func setupEmptyLabel() {
        emptyLabel.text = "No favourites yet.\nTap the heart on a photo to add it."
        emptyLabel.numberOfLines = 0
        emptyLabel.textAlignment = .center
        emptyLabel.textColor = .secondaryLabel
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyLabel)
        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
            emptyLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32)
        ])
    }

    private func makeLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { _, environment in
            let width = environment.container.effectiveContentSize.width
            let columns = max(2, Int(width / 160))
            let fraction = 1 / CGFloat(columns)

            let item = NSCollectionLayoutItem(layoutSize: .init(
                widthDimension: .fractionalWidth(fraction),
                heightDimension: .fractionalHeight(1)))
            item.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4)

            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: .init(widthDimension: .fractionalWidth(1),
                                  heightDimension: .fractionalWidth(fraction)),
                repeatingSubitem: item,
                count: columns)
            return NSCollectionLayoutSection(group: group)
        }
    }

    private func setupDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Section, Photo>(
            collectionView: collectionView
        ) { collectionView, indexPath, photo in
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: PhotoCell.reuseIdentifier,
                for: indexPath) as? PhotoCell
            cell?.configure(with: photo, isFavourite: true)
            return cell
        }
    }

    // MARK: - Binding

    private func bindViewModel() {
        viewModel.$photos
            .receive(on: DispatchQueue.main)
            .sink { [weak self] photos in
                var snapshot = NSDiffableDataSourceSnapshot<Section, Photo>()
                snapshot.appendSections([.main])
                snapshot.appendItems(photos)
                self?.dataSource.apply(snapshot, animatingDifferences: true)
                self?.emptyLabel.isHidden = !photos.isEmpty
            }
            .store(in: &cancellables)

        viewModel.$errorMessage
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(alert, animated: true)
            }
            .store(in: &cancellables)
    }
}

// MARK: - UICollectionViewDelegate

extension FavouritesViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let pager = DetailPagerViewController(
            photos: viewModel.photos,
            startIndex: indexPath.item,
            favourites: viewModel.repository)
        navigationController?.pushViewController(pager, animated: true)
    }

    func collectionView(_ collectionView: UICollectionView,
                        contextMenuConfigurationForItemAt indexPath: IndexPath,
                        point: CGPoint) -> UIContextMenuConfiguration? {
        guard let photo = dataSource.itemIdentifier(for: indexPath) else { return nil }
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            let remove = UIAction(title: "Remove from favourites",
                                  image: UIImage(systemName: "heart.slash"),
                                  attributes: .destructive) { _ in
                self?.viewModel.remove(photo)
            }
            return UIMenu(children: [remove])
        }
    }
}
