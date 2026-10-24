import SwiftUI

struct PosterArtwork: View {
    let url: URL?
    let style: MediaArtworkStyle
    var progress: Double?
    var isWatched = false

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: AppTheme.Radius.artwork, style: .continuous)
    }

    var body: some View {
        shape
            .fill(AppTheme.surfaceFill)
            .overlay {
                ArtworkImage(url: url, style: style)
            }
            .overlay {
                WatchProgressBadge(progress: progress, isWatched: isWatched)
                    .padding(WatchProgressBadge.inset)
            }
            .aspectRatio(style.aspectRatio, contentMode: .fit)
            .clipShape(shape)
            .overlay {
                shape.strokeBorder(AppTheme.hairline, lineWidth: 1)
            }
    }
}

struct PosterTile: View {
    let item: MediaItem
    let style: MediaArtworkStyle
    var showsAddedAt = false

    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: PlatformMetadata.tileTitleSpacing) {
            PosterArtwork(
                url: item.artwork.url(for: style),
                style: style,
                progress: item.progress,
                isWatched: item.isWatched
            )
            .scaleEffect(isHovered ? 1.03 : 1)
            .shadow(color: AppTheme.artworkShadow.opacity(isHovered ? 1 : 0), radius: 18, y: 10)
            .animation(AppTheme.focusAnimation, value: isHovered)

            VStack(alignment: .leading, spacing: PlatformMetadata.tileSubtitleSpacing) {
                MarqueeText(
                    text: item.title,
                    font: PlatformMetadata.tileTitleFont,
                    isActive: PlatformMetadata.supportsItemTitleHoverMarquee && isHovered
                )

                if let subtitle = item.libraryTileSubtitle(showsAddedAt: showsAddedAt) {
                    Text(subtitle)
                        .font(PlatformMetadata.labelFont)
                        .foregroundStyle(AppTheme.secondaryText)
                        .lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .platformHover { isHovered = $0 }
        .accessibilityElement(children: .combine)
    }
}
