import SwiftUI

struct IOSLibraryPageContent: View {
    @ObservedObject var model: AppModel
    let library: LibraryReference

    @StateObject private var state: LibraryPageState
    private let defaultsDidChange = NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)

    init(model: AppModel, library: LibraryReference) {
        self.model = model
        self.library = library
        _state = StateObject(wrappedValue: LibraryPageState(model: model, library: library))
    }

    var body: some View {
        Group {
            if state.isLoadingFirstPage {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: contentSpacing) {
                        header

                        LazyVGrid(columns: columns, alignment: .leading, spacing: rowSpacing) {
                            ForEach(state.displayedItems) { item in
                                itemLink(item)
                            }
                        }
                    }
                    .padding(contentPadding)
                }
            }
        }
        .background(BrowsingBackground())
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
            return Array(repeating: GridItem(.flexible(), spacing: gridSpacing), count: 2)
        }
        if PlatformMetadata.isMac {
            let minimum: CGFloat = state.library.artworkStyle == .poster ? 180 : 260
            return [GridItem(.adaptive(minimum: minimum, maximum: minimum + 40), spacing: gridSpacing)]
        }
        let count = state.library.artworkStyle == .poster ? 4 : 3
        return Array(repeating: GridItem(.flexible(), spacing: gridSpacing), count: count)
    }

    private var tileArtworkStyle: MediaArtworkStyle {
        state.library.artworkStyle == .poster ? .poster : .landscape
    }

    private var showsTileAddedAt: Bool {
        state.sort == .addedAt
    }

    private func itemLink(_ item: MediaItem) -> some View {
        NavigationLink(value: item.route) {
            LibraryItemCard(
                item: item,
                artworkStyle: tileArtworkStyle,
                showsAddedAt: showsTileAddedAt
            )
        }
        .buttonStyle(.plain)
        .mediaItemQuickActions(model: model, item: item)
    }

    private var header: some View {
        Group {
            if PlatformMetadata.isPhone {
                phoneHeader
            } else {
                padOrMacHeader
            }
        }
    }

    private var phoneHeader: some View {
        VStack(alignment: .leading, spacing: contentSpacing) {
            Text(state.library.title)
                .pageTitleFont()
                .lineLimit(1)

            HStack(alignment: .top, spacing: PlatformMetadata.controlSpacing) {
                filterAndSortControls
                Spacer(minLength: 0)
            }

            if state.libraryWatchStatusItem != nil {
                HStack(spacing: PlatformMetadata.controlSpacing) {
                    collectionControls
                }
            }

            Text(state.countText)
                .foregroundStyle(AppTheme.secondaryText)
        }
    }

    private var padOrMacHeader: some View {
        VStack(alignment: .leading, spacing: contentSpacing) {
            HStack(alignment: .firstTextBaseline) {
                Text(state.library.title)
                    .pageTitleFont()
                    .lineLimit(1)

                Spacer(minLength: 0)

                Text(state.countText)
                    .foregroundStyle(AppTheme.secondaryText)
                    .layoutPriority(1)
            }

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: PlatformMetadata.controlSpacing) {
                    filterAndSortControls
                    Spacer(minLength: 0)
                    collectionControls
                }

                VStack(alignment: .leading, spacing: PlatformMetadata.controlSpacing) {
                    filterAndSortControls
                    collectionControls
                }
            }
        }
    }

    @ViewBuilder
    private var filterAndSortControls: some View {
        LibraryPageFilterControl(filter: state.filter, onChange: state.setFilter)

        LibraryPageSortControl(
            sort: state.sort,
            order: state.sortOrder,
            onSortChange: state.setSort,
            onSortOrderChange: state.setSortOrder
        )
    }

    @ViewBuilder
    private var collectionControls: some View {
        if let item = state.libraryWatchStatusItem {
            MediaPlayAllButton(model: model, items: state.displayedPlayableItems)

            MediaCollectionWatchStatusButton(
                model: model,
                libraryItem: item,
                libraryID: state.library.id
            )
        }
    }
}
