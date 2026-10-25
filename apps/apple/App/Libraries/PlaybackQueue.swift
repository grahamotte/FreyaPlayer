import Foundation

struct PlaybackQueue {
    private(set) var items: [MediaItem]
    private(set) var index = 0

    init(_ items: [MediaItem], shuffled: Bool = false) {
        let playable = items.filter { $0.playbackID != nil }
        self.items = shuffled ? playable.shuffled() : playable
    }

    var current: MediaItem? {
        items.indices.contains(index) ? items[index] : nil
    }

    var next: MediaItem? {
        items.indices.contains(index + 1) ? items[index + 1] : nil
    }

    var hasNext: Bool {
        next != nil
    }

    @discardableResult
    mutating func advance() -> MediaItem? {
        guard index < items.count else { return nil }
        index += 1
        return current
    }

    static func recoveryOffset(savedTime: Int, currentTime: Int, fallback: Int?) -> Int {
        savedTime > 0 ? savedTime : max(currentTime, fallback ?? 0)
    }
}
