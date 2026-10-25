import SwiftUI

struct WatchProgressBadge: View {
    let progress: Double?
    let isWatched: Bool

    private var displayProgress: Double {
        min(max(progress ?? 0, 0), 1)
    }

    var body: some View {
        GeometryReader { proxy in
            let scale = min(1, proxy.size.width / Self.referenceWidth)
            let checkSize = max(Self.checkSize * scale, 14)
            let barHeight = max(Self.barHeight * scale, 3)
            let inset = Self.inset * scale

            Group {
                if isWatched {
                    Image(systemName: "checkmark")
                        .font(.system(size: checkSize * 0.46, weight: .heavy))
                        .foregroundStyle(AppTheme.onAccent)
                        .frame(width: checkSize, height: checkSize)
                        .background(AppTheme.accent, in: Circle())
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                        .accessibilityLabel("Seen")
                } else if displayProgress > 0 {
                    Capsule()
                        .fill(Color.black.opacity(0.55))
                        .overlay(alignment: .leading) {
                            GeometryReader { bar in
                                Capsule()
                                    .fill(AppTheme.accent)
                                    .frame(width: max(barHeight, bar.size.width * displayProgress))
                            }
                        }
                        .frame(height: barHeight)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                        .accessibilityLabel("\(Int((displayProgress * 100).rounded()))% watched")
                }
            }
            .padding(inset)
        }
    }
}

extension WatchProgressBadge {
    static var referenceWidth: CGFloat {
        PlatformMetadata.isTV ? 300 : 160
    }

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
