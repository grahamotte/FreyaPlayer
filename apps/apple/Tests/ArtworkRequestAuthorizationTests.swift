import XCTest
@testable import FreyaPlayerCore

final class ArtworkRequestAuthorizationTests: XCTestCase {
    private let headers = ["X-Plex-Token": "secret"]

    func testRejectsServerURLWithoutHost() {
        XCTAssertNil(ArtworkRequestAuthorization(serverURL: "not a url", headers: headers))
        XCTAssertNil(ArtworkRequestAuthorization(serverURL: "/relative", headers: headers))
    }

    func testMatchesSameOriginIgnoringCase() throws {
        let authorization = try XCTUnwrap(
            ArtworkRequestAuthorization(serverURL: "https://Media.Example.com:32400", headers: headers)
        )

        XCTAssertEqual(
            authorization.headers(for: URL(string: "https://media.example.com:32400/photo/:/transcode?url=/a")!),
            headers
        )
        XCTAssertEqual(
            authorization.headers(for: URL(string: "HTTPS://MEDIA.EXAMPLE.COM:32400/library")!),
            headers
        )
    }

    func testRejectsDifferentSchemeHostOrPort() throws {
        let authorization = try XCTUnwrap(
            ArtworkRequestAuthorization(serverURL: "https://media.example.com:32400", headers: headers)
        )

        XCTAssertNil(authorization.headers(for: URL(string: "http://media.example.com:32400/photo")!))
        XCTAssertNil(authorization.headers(for: URL(string: "https://other.example.com:32400/photo")!))
        XCTAssertNil(authorization.headers(for: URL(string: "https://media.example.com:8096/photo")!))
        XCTAssertNil(authorization.headers(for: URL(string: "https://media.example.com/photo")!))
        XCTAssertNil(authorization.headers(for: URL(string: "https://media.example.com.evil.test:32400/photo")!))
    }

    func testTreatsDefaultPortsAsEqual() throws {
        let https = try XCTUnwrap(ArtworkRequestAuthorization(serverURL: "https://media.example.com", headers: headers))
        let http = try XCTUnwrap(ArtworkRequestAuthorization(serverURL: "http://media.example.com:80", headers: headers))

        XCTAssertEqual(https.headers(for: URL(string: "https://media.example.com:443/Items/1/Images/Primary")!), headers)
        XCTAssertEqual(http.headers(for: URL(string: "http://media.example.com/Items/1/Images/Primary")!), headers)
    }

    func testRequiresServerPathPrefix() throws {
        let authorization = try XCTUnwrap(
            ArtworkRequestAuthorization(serverURL: "https://example.com/jellyfin/", headers: headers)
        )

        XCTAssertEqual(authorization.headers(for: URL(string: "https://example.com/jellyfin/Items/1/Images/Primary")!), headers)
        XCTAssertEqual(authorization.headers(for: URL(string: "https://example.com/jellyfin")!), headers)
        XCTAssertNil(authorization.headers(for: URL(string: "https://example.com/jellyfinx/Items/1")!))
        XCTAssertNil(authorization.headers(for: URL(string: "https://example.com/Items/1")!))
    }
}
