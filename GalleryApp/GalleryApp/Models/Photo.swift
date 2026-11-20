import Foundation

struct Photo: Codable, Identifiable, Hashable {
    let id: String
    let width: Int
    let height: Int
    let details: String?
    let altDescription: String?
    let urls: URLs
    let user: User

    struct URLs: Codable, Hashable {
        let regular: URL
        let small: URL
        let thumb: URL
    }

    struct User: Codable, Hashable {
        let name: String
    }

    /// Unsplash has no "title" field, so we use description or alt text.
    var title: String {
        details ?? altDescription ?? "Untitled"
    }

    enum CodingKeys: String, CodingKey {
        case id, width, height, urls, user, altDescription
        case details = "description"
    }
}
