import SwiftUI

struct LibraryItemCard: View {
    let item: MediaItem
    let artworkStyle: MediaArtworkStyle
    let showsAddedAt: Bool

    @State private var isHovered = false

    private var artworkURL: URL? {
        item.artwork.url(for: artworkStyle)
    }

    init(item: MediaItem, artworkStyle: MediaArtworkStyle, showsAddedAt: Bool = false) {
        self.item = item
        self.artworkStyle = artworkStyle
        self.showsAddedAt = showsAddedAt
    }

    var body: some View {
        VStack(alignment: .leading, spacing: PlatformMetadata.tileTitleSpacing) {
            artwork

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
        .platformHover { isHovered = $0 }
    }

    private var artwork: some View {
        RoundedRectangle(cornerRadius: AppTheme.Radius.artwork, style: .continuous)
            .fill(AppTheme.surfaceFill)
            .overlay {
                ArtworkImage(url: artworkURL, style: artworkStyle)
            }
            .overlay(alignment: .bottomTrailing) {
                WatchProgressCircle(progress: item.progress, isWatched: item.isWatched)
                    .padding(WatchProgressCircle.padding)
            }
            .aspectRatio(artworkStyle.aspectRatio, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.artwork, style: .continuous))
    }
}
