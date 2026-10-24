import Fuse
import SwiftUI

struct ServerSearchPage: View {
    @StateObject private var search: ServerTitleSearch
    @FocusState private var isSearchFieldFocused: Bool

    init(model: AppModel, server: ConnectedServer) {
        _search = StateObject(
            wrappedValue: ServerTitleSearch(cache: model.libraryCache, server: server)
        )
    }

    var body: some View {
        pageContent
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background {
                BrowsingBackground()
                    .ignoresSafeArea()
            }
            .searchable(text: $search.query, placement: searchPlacement, prompt: "Search titles")
            .iOSSearchFocused($isSearchFieldFocused)
            .navigationTitle("Search")
            .task {
                guard !PlatformMetadata.isTV else { return }
                isSearchFieldFocused = true
            }
    }

    private var searchPlacement: SearchFieldPlacement {
        #if os(tvOS)
        .automatic
        #else
        .navigationBarDrawer(displayMode: .always)
        #endif
    }

    @ViewBuilder
    private var pageContent: some View {
        if search.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            ContentUnavailableView(
                "Search Titles",
                systemImage: "magnifyingglass",
                description: Text("Type or dictate a few characters from a title.")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if search.results.isEmpty {
            ContentUnavailableView.search(text: search.query)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            searchResults
        }
    }

    private var searchResults: some View {
        ScrollView {
            LazyVStack(spacing: PlatformMetadata.isTV ? AppTheme.Spacing.large : AppTheme.Spacing.medium) {
                ForEach(search.results) { result in
                    NavigationLink(value: result.item.route) {
                        SearchResultRow(
                            item: result.item,
                            title: highlightedTitle(for: result)
                        )
                    }
                    .buttonStyle(MediaSurfaceButtonStyle(restingFill: AppTheme.surfaceFill))
                }
            }
            .padding(.horizontal, contentHorizontalPadding)
            .padding(.top, PlatformMetadata.isTV ? AppTheme.Spacing.large : 0)
            .padding(.bottom, contentHorizontalPadding)
        }
        .scrollIndicators(.hidden)
    }

    private var contentHorizontalPadding: CGFloat {
        PlatformMetadata.pageGutter
    }

    private func highlightedTitle(for result: ServerTitleSearch.Result) -> Text {
        let units = Array(result.item.title.utf16)
        var text = Text("")
        var cursor = 0

        for range in result.matchedRanges {
            let start = min(max(range.start, cursor), units.count)
            let end = min(max(range.end + 1, start), units.count)
            if start > cursor {
                let unmatched = Text(String(decoding: units[cursor..<start], as: UTF16.self))
                    .foregroundColor(AppTheme.secondaryText)
                text = Text("\(text)\(unmatched)")
            }
            if end > start {
                let matched = Text(String(decoding: units[start..<end], as: UTF16.self))
                    .fontWeight(.heavy)
                    .foregroundColor(AppTheme.primaryText)
                text = Text("\(text)\(matched)")
            }
            cursor = end
        }

        if cursor < units.count {
            let unmatched = Text(String(decoding: units[cursor..<units.count], as: UTF16.self))
                .foregroundColor(AppTheme.secondaryText)
            text = Text("\(text)\(unmatched)")
        }
        return text
    }
}

private extension View {
    @ViewBuilder
    func iOSSearchFocused(_ isFocused: FocusState<Bool>.Binding) -> some View {
        #if os(tvOS)
        self
        #else
        searchFocused(isFocused)
        #endif
    }
}

private struct SearchResultRow: View {
    let item: MediaItem
    let title: Text

    var body: some View {
        HStack(spacing: PlatformMetadata.isTV ? AppTheme.Spacing.xLarge : AppTheme.Spacing.large) {
            SearchResultArtwork(item: item)

            VStack(alignment: .leading, spacing: PlatformMetadata.isTV ? AppTheme.Spacing.small : AppTheme.Spacing.xSmall) {
                title
                    .font(PlatformMetadata.isTV ? .title2 : .title3)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                if let metadata {
                    Text(metadata)
                        .font(PlatformMetadata.labelFont.weight(.medium))
                        .foregroundStyle(AppTheme.secondaryText)
                        .lineLimit(1)
                }

                if let synopsis {
                    Text(synopsis)
                        .font(PlatformMetadata.isTV ? .body : .subheadline)
                        .foregroundStyle(AppTheme.secondaryText)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            }

            Spacer(minLength: AppTheme.Spacing.large)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(resultPadding)
        .contentShape(Rectangle())
    }

    private var metadata: String? {
        if let releasedAt = item.releasedAtFormatted {
            return releasedAt
        }
        return item.year.map(String.init)
    }

    private var synopsis: String? {
        let value = item.synopsis.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    private var resultPadding: CGFloat {
        PlatformMetadata.isPhone ? AppTheme.Spacing.medium : AppTheme.Spacing.large
    }
}

private struct SearchResultArtwork: View {
    let item: MediaItem

    private var style: MediaArtworkStyle {
        item.kind.artworkStyle
    }

    var body: some View {
        ArtworkImage(url: item.artwork.url(for: style), style: style)
            .background(AppTheme.surfaceFill)
            .frame(width: imageSize.width, height: imageSize.height)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.inline, style: .continuous))
            .frame(width: previewDimension, height: previewDimension)
    }

    private var previewDimension: CGFloat {
        if PlatformMetadata.isTV { return 240 }
        if PlatformMetadata.isPhone { return 140 }
        return 200
    }

    private var imageSize: CGSize {
        if style.aspectRatio >= 1 {
            return CGSize(
                width: previewDimension,
                height: previewDimension / style.aspectRatio
            )
        }
        return CGSize(
            width: previewDimension * style.aspectRatio,
            height: previewDimension
        )
    }
}
