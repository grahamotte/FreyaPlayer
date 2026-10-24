import SwiftUI

struct WatchProgressBadge: View {
    let progress: Double?
    let isWatched: Bool

    private var displayProgress: Double {
        min(max(progress ?? 0, 0), 1)
    }

    var body: some View {
        if isWatched {
            Image(systemName: "checkmark")
                .font(.system(size: Self.checkSize * 0.46, weight: .heavy))
                .foregroundStyle(AppTheme.onAccent)
                .frame(width: Self.checkSize, height: Self.checkSize)
                .background(AppTheme.accent, in: Circle())
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .accessibilityLabel("Seen")
        } else if displayProgress > 0 {
            Capsule()
                .fill(Color.black.opacity(0.55))
                .overlay(alignment: .leading) {
                    GeometryReader { proxy in
                        Capsule()
                            .fill(AppTheme.accent)
                            .frame(width: max(Self.barHeight, proxy.size.width * displayProgress))
                    }
                }
                .frame(height: Self.barHeight)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .accessibilityLabel("\(Int((displayProgress * 100).rounded()))% watched")
        }
    }
}

extension WatchProgressBadge {
    static var inset: CGFloat {
        PlatformMetadata.isTV ? 18 : 10
    }

    static var checkSize: CGFloat {
        PlatformMetadata.isTV ? 34 : 22
    }

    static var barHeight: CGFloat {
        PlatformMetadata.isTV ? 8 : 5
    }
}
