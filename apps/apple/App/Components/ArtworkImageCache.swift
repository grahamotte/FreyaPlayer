import UIKit

@MainActor
final class ArtworkImageCache {
    static let shared = ArtworkImageCache()

    private let session: URLSession
    private let cache = NSCache<NSURL, UIImage>()
    var requestHeaders: @MainActor (URL) -> [String: String]? = { _ in nil }

    init(session: URLSession = .shared) {
        self.session = session
    }

    func image(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }

    func clear() {
        cache.removeAllObjects()
    }

    func loadImage(from url: URL) async -> UIImage? {
        if let cached = image(for: url) {
            return cached
        }

        do {
            var request = URLRequest(url: url)
            for (field, value) in requestHeaders(url) ?? [:] {
                request.setValue(value, forHTTPHeaderField: field)
            }
            let (data, _) = try await session.data(for: request)
            guard let image = UIImage(data: data) else { return nil }
            cache.setObject(image, forKey: url as NSURL)
            return image
        } catch {
            return nil
        }
    }
}
