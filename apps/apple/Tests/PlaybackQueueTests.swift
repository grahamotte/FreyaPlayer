import XCTest
@testable import FreyaPlayerCore

final class PlaybackQueueTests: XCTestCase {
    func testQueueKeepsPlayableItemsInOrderAndAdvances() {
        var queue = PlaybackQueue([
            makeMediaItem(id: "a"),
            makeMediaItem(id: "season", kind: .season),
            makeMediaItem(id: "b", kind: .episode),
        ])

        XCTAssertEqual(queue.items.map(\.id), ["a", "b"])
        XCTAssertEqual(queue.current?.id, "a")
        XCTAssertEqual(queue.next?.id, "b")
        XCTAssertTrue(queue.hasNext)

        XCTAssertEqual(queue.advance()?.id, "b")
        XCTAssertFalse(queue.hasNext)
        XCTAssertNil(queue.advance())
        XCTAssertNil(queue.current)
        XCTAssertNil(queue.advance())
        XCTAssertEqual(queue.index, 2)
    }

    func testShuffledQueueKeepsTheSameItems() {
        let items = (0 ..< 20).map { makeMediaItem(id: "\($0)") }
        let queue = PlaybackQueue(items, shuffled: true)

        XCTAssertEqual(Set(queue.items.map(\.id)), Set(items.map(\.id)))
        XCTAssertEqual(queue.items.count, items.count)
    }

    func testEmptyQueueHasNoCurrentItem() {
        let queue = PlaybackQueue([makeMediaItem(kind: .series)])

        XCTAssertNil(queue.current)
        XCTAssertFalse(queue.hasNext)
    }

    func testRecoveryOffsetPrefersSavedTimeThenFurthestKnownPosition() {
        XCTAssertEqual(PlaybackQueue.recoveryOffset(savedTime: 5_000, currentTime: 9_000, fallback: 1_000), 5_000)
        XCTAssertEqual(PlaybackQueue.recoveryOffset(savedTime: 0, currentTime: 9_000, fallback: 1_000), 9_000)
        XCTAssertEqual(PlaybackQueue.recoveryOffset(savedTime: 0, currentTime: 0, fallback: 4_000), 4_000)
        XCTAssertEqual(PlaybackQueue.recoveryOffset(savedTime: 0, currentTime: 0, fallback: nil), 0)
    }
}
