import Foundation

enum APIConfig {
    static var unsplashAccessKey: String? {
        let key = Bundle.main.object(forInfoDictionaryKey: "UNSPLASH_ACCESS_KEY") as? String
        guard let key, !key.isEmpty, !key.contains("YOUR_ACCESS_KEY") else { return nil }
        return key
    }
}
