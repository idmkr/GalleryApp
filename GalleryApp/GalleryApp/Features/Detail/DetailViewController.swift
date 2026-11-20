import UIKit
import Combine

final class DetailViewController: UIViewController {
    let index: Int

    private let viewModel: DetailViewModel
    private let imageLoader: ImageLoading
    private var cancellables = Set<AnyCancellable>()

    private let scrollView = UIScrollView()
    private let imageView = UIImageView()
    private let favouriteButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let authorLabel = UILabel()
    private let descriptionLabel = UILabel()

    init(index: Int, viewModel: DetailViewModel, imageLoader: ImageLoading = ImageLoader.shared) {
        self.index = index
        self.viewModel = viewModel
        self.imageLoader = imageLoader
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupLayout()
        fillContent()
        bindViewModel()
        loadImage()
    }

    // MARK: - Setup

    private func setupLayout() {
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12
        imageView.backgroundColor = .secondarySystemBackground

        titleLabel.font = .preferredFont(forTextStyle: .title2)
        titleLabel.numberOfLines = 0
        authorLabel.font = .preferredFont(forTextStyle: .subheadline)
        authorLabel.textColor = .secondaryLabel
        descriptionLabel.font = .preferredFont(forTextStyle: .body)
        descriptionLabel.numberOfLines = 0

        favouriteButton.addTarget(self, action: #selector(favouriteTapped), for: .touchUpInside)
        favouriteButton.setContentHuggingPriority(.required, for: .horizontal)

        let textStack = UIStackView(arrangedSubviews: [titleLabel, authorLabel, descriptionLabel])
        textStack.axis = .vertical
        textStack.spacing = 8

        let headerStack = UIStackView(arrangedSubviews: [textStack, favouriteButton])
        headerStack.axis = .horizontal
        headerStack.alignment = .top
        headerStack.spacing = 12

        let stack = UIStackView(arrangedSubviews: [imageView, headerStack])
        stack.axis = .vertical
        stack.spacing = 16

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(stack)

        let photo = viewModel.photo
        let ratio = CGFloat(photo.height) / CGFloat(max(photo.width, 1))

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -16),
            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -16),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32),

            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: ratio),
            favouriteButton.widthAnchor.constraint(equalToConstant: 44),
            favouriteButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func fillContent() {
        titleLabel.text = viewModel.title
        authorLabel.text = viewModel.author
        descriptionLabel.text = viewModel.description
        descriptionLabel.isHidden = viewModel.description == nil
    }

    private func loadImage() {
        let url = viewModel.photo.urls.regular
        let loader = imageLoader
        Task { [weak self] in
            guard let image = try? await loader.loadImage(from: url) else { return }
            self?.imageView.image = image
        }
    }

    // MARK: - Binding

    private func bindViewModel() {
        viewModel.$isFavourite
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isFavourite in self?.updateButton(isFavourite: isFavourite) }
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

    private func updateButton(isFavourite: Bool) {
        let config = UIImage.SymbolConfiguration(pointSize: 24)
        let name = isFavourite ? "heart.fill" : "heart"
        favouriteButton.setImage(UIImage(systemName: name, withConfiguration: config), for: .normal)
        favouriteButton.tintColor = isFavourite ? .systemRed : .secondaryLabel
    }

    @objc private func favouriteTapped() {
        viewModel.toggleFavourite()
    }
}
