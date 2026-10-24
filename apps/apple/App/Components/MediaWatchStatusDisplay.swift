import SwiftUI

enum MediaWatchStatusDisplay {
    static let markSeenTitle = "Mark Seen"
    static let markUnseenTitle = "Mark Unseen"

    static func title(progress: Double?, isWatched: Bool) -> String {
        if isWatched {
            return "Seen"
        }

        let percent = progressPercent(progress)
        return percent == 0 ? "Unseen" : "\(percent)%"
    }

    private static func progressPercent(_ progress: Double?) -> Int {
        let value = clampedProgress(progress, isWatched: false)

        guard value > 0 else { return 0 }
        guard value < 1 else { return 100 }

        return min(max(Int((value * 100).rounded()), 1), 99)
    }

    private static func clampedProgress(_ progress: Double?, isWatched: Bool) -> Double {
        if isWatched {
            return 1
        }

        return min(max(progress ?? 0, 0), 1)
    }
}
