import UIKit

protocol ImageLoading {
    func loadImage(from url: URL) async throws -> UIImage
}

final class ImageLoader: ImageLoading {
    static let shared = ImageLoader()

    private let cache = NSCache<NSURL, UIImage>()
    private let session: NetworkSession

    init(session: NetworkSession = URLSession.shared) {
        self.session = session
        cache.countLimit = 200
    }

    func loadImage(from url: URL) async throws -> UIImage {
        if let cached = cache.object(forKey: url as NSURL) {
            return cached
        }
        let (data, _) = try await session.data(for: URLRequest(url: url))
        guard let image = UIImage(data: data) else {
            throw NetworkError.decodingFailed
        }
        cache.setObject(image, forKey: url as NSURL)
        return image
    }
}
