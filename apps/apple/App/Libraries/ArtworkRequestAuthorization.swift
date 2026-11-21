import Foundation

struct ArtworkRequestAuthorization: Equatable {
    let serverURL: URL
    let headers: [String: String]

    init?(serverURL: String, headers: [String: String]) {
        guard let url = URL(string: serverURL), url.host != nil else { return nil }
        self.serverURL = url
        self.headers = headers
    }

    func headers(for url: URL) -> [String: String]? {
        guard
            url.scheme?.lowercased() == serverURL.scheme?.lowercased(),
            url.host?.lowercased() == serverURL.host?.lowercased(),
            Self.port(of: url) == Self.port(of: serverURL)
        else {
            return nil
        }

        let basePath = serverURL.path.hasSuffix("/") ? serverURL.path : serverURL.path + "/"
        guard (url.path + "/").hasPrefix(basePath) else { return nil }

        return headers
    }

    private static func port(of url: URL) -> Int? {
        if let port = url.port {
            return port
        }

        switch url.scheme?.lowercased() {
        case "http":
            return 80
        case "https":
            return 443
        default:
            return nil
        }
    }
}
