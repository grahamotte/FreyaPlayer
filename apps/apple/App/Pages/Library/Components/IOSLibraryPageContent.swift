import SwiftUI

struct IOSLibraryPageContent: View {
    @ObservedObject var model: AppModel
    let library: LibraryReference

    @StateObject private var state: LibraryPageState
    @StateObject private var light = AmbientLight()
    private let defaultsDidChange = NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)

    init(model: AppModel, library: LibraryReference) {
        self.model = model
        self.library = library
        _state = StateObject(wrappedValue: LibraryPageState(model: model, library: library))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: contentSpacing) {
                header

                if state.isLoadingFirstPage {
                    skeletonGrid
                } else if state.displayedItems.isEmpty {
                    ContentUnavailableView(
                        state.filter.emptyStateText(for: state.library.itemTitle),
                        systemImage: tileArtworkStyle.placeholderIconName
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.top, AppTheme.Spacing.xxLarge)
                } else {
                    LazyVGrid(columns: columns, alignment: .leading, spacing: rowSpacing) {
                        ForEach(state.displayedItems) { item in
                            itemLink(item)
                        }
                    }
                }
            }
            .padding(contentPadding)
        }
        .scrollIndicators(.hidden)
        .navigationTitle(state.library.title)
        .largeNavigationTitle(subtitle: state.countText)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                LibraryPageOptionsMenu(
                    filter: state.filter,
                    sort: state.sort,
                    order: state.sortOrder,
                    onFilterChange: state.setFilter,
                    onSortChange: state.setSort,
                    onSortOrderChange: state.setSortOrder
                )
            }
        }
        .background(AmbientBackdrop(light: light))
        .task(id: leadArtworkURL) {
            light.light(leadArtworkURL)
        }
        .task(id: library.id) {
            state.update(library: library)
        }
        .onReceive(defaultsDidChange) { _ in
            state.loadSavedControls()
        }
    }

    private var contentPadding: CGFloat { PlatformMetadata.pageGutter }
    private var contentSpacing: CGFloat { PlatformMetadata.pageSectionSpacing }
    private var gridSpacing: CGFloat { PlatformMetadata.tileSpacing }
    private var rowSpacing: CGFloat { PlatformMetadata.pageSectionSpacing }

    private var columns: [GridItem] {
        if PlatformMetadata.isPhone {
            let count = tileArtworkStyle == .poster ? 3 : 2
            return Array(repeating: GridItem(.flexible(), spacing: gridSpacing, alignment: .top), count: count)
        }
        let minimum: CGFloat = tileArtworkStyle == .poster ? 160 : 260
        return [GridItem(.adaptive(minimum: minimum, maximum: minimum * 1.3), spacing: gridSpacing, alignment: .top)]
    }

    private var tileArtworkStyle: MediaArtworkStyle {
        state.library.artworkStyle
    }

    private var showsTileAddedAt: Bool {
        state.sort == .addedAt
    }

    private var leadArtworkURL: URL? {
        state.displayedItems.first?.artwork.url(for: tileArtworkStyle)
    }

    private var skeletonGrid: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: rowSpacing) {
            ForEach(0 ..< 12, id: \.self) { _ in
                RoundedRectangle(cornerRadius: AppTheme.Radius.artwork, style: .continuous)
                    .fill(AppTheme.surfaceFill)
                    .aspectRatio(tileArtworkStyle.aspectRatio, contentMode: .fit)
            }
        }
        .accessibilityLabel("Loading")
    }

    private func itemLink(_ item: MediaItem) -> some View {
        NavigationLink(value: item.route) {
            PosterTile(
                item: item,
                style: tileArtworkStyle,
                showsAddedAt: showsTileAddedAt
            )
        }
        .buttonStyle(.plain)
        .mediaItemQuickActions(model: model, item: item)
        .platformHover { isHovered in
            if isHovered {
                light.light(item.artwork.url(for: tileArtworkStyle))
            }
        }
    }

    @ViewBuilder
    private var header: some View {
        if let item = state.libraryWatchStatusItem {
            HStack(spacing: PlatformMetadata.controlSpacing) {
                MediaPlayAllButton(model: model, items: state.displayedPlayableItems)

                MediaCollectionWatchStatusButton(
                    model: model,
                    libraryItem: item,
                    libraryID: state.library.id
                )
            }
            .controlSize(.large)
        }
    }
}
