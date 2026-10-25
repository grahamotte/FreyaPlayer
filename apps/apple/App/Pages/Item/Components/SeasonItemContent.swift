import SwiftUI

struct SeasonItemContent: View {
    @ObservedObject var model: AppModel
    @ObservedObject var cache: LibraryCache
    let originalItem: MediaItem

    init(model: AppModel, item: MediaItem) {
        self.model = model
        self.cache = model.libraryCache
        self.originalItem = item
    }

    private var item: MediaItem {
        cache.item(originalItem.id) ?? originalItem
    }

    var body: some View {
        MediaView(model: model, data: item.mediaViewData()) {
            MediaPlayAllButton(model: model, items: playableItems, isProminent: true)
            MediaCollectionWatchStatusButton(model: model, item: item)
        } below: {
            ItemChildListSection(
                model: model,
                item: item,
                title: "Episodes",
                emptyMessage: "No episodes yet.",
                destination: { $0.route },
                rowStyle: .numbered,
                autoFocusNextUnwatched: true
            )
            .padding(.top, PlatformMetadata.isTV ? 0 : AppTheme.Spacing.medium)
        }
        .task(id: originalItem.id) { model.refreshItem(originalItem) }
    }

    private var playableItems: [MediaItem] {
        cache.leaves(under: item.id).filter { !$0.isWatched }
    }
}
