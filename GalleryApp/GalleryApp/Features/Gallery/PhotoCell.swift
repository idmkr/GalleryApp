import UIKit

final class PhotoCell: UICollectionViewCell {
    static let reuseIdentifier = "PhotoCell"

    private let imageView = UIImageView()
    private let heartView = UIImageView(image: UIImage(systemName: "heart.fill"))
    private var loadTask: Task<Void, Never>?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        loadTask?.cancel()
        imageView.image = nil
        heartView.isHidden = true
    }

    func configure(with photo: Photo, isFavourite: Bool, imageLoader: ImageLoading = ImageLoader.shared) {
        heartView.isHidden = !isFavourite
        let url = photo.urls.small
        loadTask = Task { [weak self] in
            guard let image = try? await imageLoader.loadImage(from: url),
                  !Task.isCancelled else { return }
            self?.imageView.image = image
        }
    }

    private func setupViews() {
        contentView.backgroundColor = .secondarySystemBackground
        contentView.clipsToBounds = true
        contentView.layer.cornerRadius = 8

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false

        heartView.tintColor = .systemRed
        heartView.isHidden = true
        heartView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(imageView)
        contentView.addSubview(heartView)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            heartView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            heartView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            heartView.widthAnchor.constraint(equalToConstant: 22),
            heartView.heightAnchor.constraint(equalToConstant: 22)
        ])
    }
}
