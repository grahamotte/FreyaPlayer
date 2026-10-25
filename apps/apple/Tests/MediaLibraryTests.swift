import XCTest
@testable import FreyaPlayerCore

final class MediaLibraryTests: XCTestCase {
    func testPreviewItemsUseLibraryControlsAndAreLimited() {
        let items = (0..<25).map {
            makeMediaItem(
                id: String($0),
                title: "Movie \($0)",
                addedAt: $0,
                isWatched: $0 == 24
            )
        }
        let shelf = makeLibraryShelf(items: items)

        let previewItems = shelf.previewItems(
            from: items,
            filter: .unwatched,
            sort: .addedAt,
            order: .descending
        )

        XCTAssertEqual(previewItems.count, 20)
        XCTAssertEqual(previewItems.first?.id, "23")
        XCTAssertEqual(
            shelf.previewItems(
                from: items,
                filter: .all,
                sort: .addedAt,
                order: .descending
            ).first?.id,
            "24"
        )
        XCTAssertFalse(shelf.settingHidden(true).items.isEmpty)
    }

    func testCountTextPluralizesAndNamesTheFilter() {
        let reference = makeLibraryReference()

        XCTAssertEqual(reference.countText(1), "1 Movie")
        XCTAssertEqual(reference.countText(34), "34 Movies")
        XCTAssertEqual(reference.countText(0, unseenOnly: true), "0 unseen Movies")
    }

    func testLibraryWatchStatusUsesVisibleItems() {
        let reference = makeLibraryReference()
        let item = reference.watchStatusItem(from: [
            makeMediaItem(id: "watched", isWatched: true),
            makeMediaItem(id: "started", progress: 0.5),
        ])

        XCTAssertEqual(item?.id, "library:library")
        XCTAssertEqual(item?.progress, 0.75)
        XCTAssertFalse(item?.isWatched ?? true)
    }
}
