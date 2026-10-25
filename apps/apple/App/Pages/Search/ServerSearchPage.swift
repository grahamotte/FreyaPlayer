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
                ArtworkLitBackground(url: search.results.first.map { $0.item.artwork.url(for: $0.item.kind.artworkStyle) } ?? nil)
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
            LazyVStack(spacing: PlatformMetadata.isTV ? AppTheme.Spacing.medium : AppTheme.Spacing.xSmall) {
                ForEach(search.results) { result in
                    NavigationLink(value: result.item.route) {
                        MediaRow(
                            item: result.item,
                            title: highlightedTitle(for: result),
                            usesUniformThumbnail: true
                        )
                        .padding(.vertical, AppTheme.Spacing.small)
                        .padding(.horizontal, PlatformMetadata.isTV ? AppTheme.Spacing.medium : 0)
                    }
                    .buttonStyle(MediaSurfaceButtonStyle(restingFill: PlatformMetadata.isTV ? AppTheme.subtleSurfaceFill : Color.clear))
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
