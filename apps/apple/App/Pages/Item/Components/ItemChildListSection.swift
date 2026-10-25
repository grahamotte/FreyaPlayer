import SwiftUI

struct ItemChildListSection: View {
    @ObservedObject var model: AppModel
    @ObservedObject var cache: LibraryCache
    @ObservedObject var refreshTracker: RefreshTracker
    let item: MediaItem
    let title: String
    let emptyMessage: String
    let destination: (MediaItem) -> AppRoute
    let rowStyle: RowStyle
    let autoFocusNextUnwatched: Bool

    @State private var didApplyAutoFocus = false
    @FocusState private var focusedChildID: String?

    init(
        model: AppModel,
        item: MediaItem,
        title: String,
        emptyMessage: String,
        destination: @escaping (MediaItem) -> AppRoute,
        rowStyle: RowStyle,
        autoFocusNextUnwatched: Bool = false
    ) {
        self.model = model
        self.cache = model.libraryCache
        self.refreshTracker = model.refreshTracker
        self.item = item
        self.title = title
        self.emptyMessage = emptyMessage
        self.destination = destination
        self.rowStyle = rowStyle
        self.autoFocusNextUnwatched = autoFocusNextUnwatched
    }

    private var children: [MediaItem] {
        cache.children(of: item.id)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            if !PlatformMetadata.isTV {
                Text(title)
                    .font(PlatformMetadata.sectionTitleFont)
            }

            if children.isEmpty {
                if refreshTracker.isRefreshing(.children(item.id)) {
                    ProgressView()
                } else {
                    Text(emptyMessage)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            } else {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
                    ForEach(Array(children.enumerated()), id: \.element.id) { position, child in
                        NavigationLink(value: destination(child)) {
                            MediaRow(
                                item: child,
                                position: rowStyle == .numbered ? position + 1 : nil,
                                showsSynopsis: child.kind == .episode
                            )
                            .padding(.vertical, AppTheme.Spacing.small)
                            .padding(.horizontal, PlatformMetadata.isTV ? AppTheme.Spacing.small : 0)
                        }
                        .buttonStyle(MediaSurfaceButtonStyle(restingFill: PlatformMetadata.isTV ? AppTheme.subtleSurfaceFill : Color.clear))
                        .id(child.id)
                        .focused($focusedChildID, equals: child.id)
                    }
                }
            }
        }
        .task(id: item.id) {
            focusedChildID = nil
            didApplyAutoFocus = false
            applyAutoFocusIfNeeded()
            model.refreshChildren(of: item)
        }
        .onChange(of: children.count) { _, _ in
            applyAutoFocusIfNeeded()
        }
    }

    private func applyAutoFocusIfNeeded() {
        guard autoFocusNextUnwatched, !didApplyAutoFocus else { return }
        guard let nextID = nextUnwatchedChildID(in: children) else { return }

        didApplyAutoFocus = true
        Task {
            await Task.yield()
            focusedChildID = nextID
        }
    }

    private func nextUnwatchedChildID(in children: [MediaItem]) -> String? {
        children.first(where: { !$0.isWatched })?.id
    }
}

extension ItemChildListSection {
    enum RowStyle {
        case standard
        case numbered
    }
}
