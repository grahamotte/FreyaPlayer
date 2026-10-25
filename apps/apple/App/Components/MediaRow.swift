import SwiftUI

struct MediaRow: View {
    let item: MediaItem
    var title: Text?
    var position: Int?
    var showsSynopsis = true
    var usesUniformThumbnail = false

    private var style: MediaArtworkStyle {
        item.kind.artworkStyle
    }

    var body: some View {
        HStack(alignment: .center, spacing: PlatformMetadata.isTV ? AppTheme.Spacing.xLarge : AppTheme.Spacing.medium) {
            thumbnail

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxSmall) {
                (title ?? Text(displayTitle))
                    .font(PlatformMetadata.isTV ? .title3.weight(.semibold) : .headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                if !facts.isEmpty {
                    Text(facts)
                        .font(PlatformMetadata.labelFont)
                        .foregroundStyle(AppTheme.secondaryText)
                        .lineLimit(1)
                }

                if showsSynopsis, let synopsis {
                    Text(synopsis)
                        .font(PlatformMetadata.isTV ? .callout : .subheadline)
                        .foregroundStyle(AppTheme.secondaryText)
                        .lineLimit(PlatformMetadata.isPhone ? 2 : 3)
                        .multilineTextAlignment(.leading)
                        .padding(.top, AppTheme.Spacing.xxSmall)
                }
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    private var thumbnail: some View {
        let thumbnailStyle = usesUniformThumbnail ? MediaArtworkStyle.landscape : style
        let url = usesUniformThumbnail && style == .poster
            ? item.artwork.widescreenURL
            : item.artwork.url(for: thumbnailStyle)

        return PosterArtwork(
            url: url,
            style: thumbnailStyle,
            progress: item.kind.isPlayable ? item.progress : nil,
            isWatched: item.isWatched,
            cornerRadius: AppTheme.Radius.thumbnail
        )
        .frame(width: Self.thumbnailWidth(for: thumbnailStyle))
        .zoomSource(id: item.id, cornerRadius: AppTheme.Radius.thumbnail)
    }

    private var displayTitle: String {
        guard let position else { return item.title }
        return "\(position). \(item.title)"
    }

    private var facts: String {
        let runtime = item.kind.isPlayable ? item.runtimeText : nil
        let remaining = item.kind.isPlayable ? item.remainingText : nil
        return ([item.releasedAtFormatted ?? item.year.map(String.init), runtime, remaining].compactMap { $0 })
            .joined(separator: " · ")
    }

    private var synopsis: String? {
        let value = item.synopsis.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    private static func thumbnailWidth(for style: MediaArtworkStyle) -> CGFloat {
        switch style {
        case .poster:
            if PlatformMetadata.isTV { return 104 }
            return PlatformMetadata.isPhone ? 72 : 96
        case .landscape:
            if PlatformMetadata.isTV { return 260 }
            return PlatformMetadata.isPhone ? 136 : 200
        }
    }
}
