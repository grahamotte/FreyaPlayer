import Combine
import SwiftUI

struct LibrariesPage: View {
    @ObservedObject var model: AppModel
    @ObservedObject private var cache: LibraryCache
    @ObservedObject private var refreshTracker: RefreshTracker
    @StateObject private var light = AmbientLight()
    @State private var isRefreshing = false
    @State private var preferenceRevision = 0
    let server: ConnectedServer
    @Binding var path: [AppRoute]
    private let defaultsDidChange = NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)

    private var pagePadding: CGFloat { PlatformMetadata.pageGutter }
    private var sectionSpacing: CGFloat { PlatformMetadata.pageSectionSpacing }
    private var shelfSpacing: CGFloat { PlatformMetadata.shelfSpacing }
    private var cardSpacing: CGFloat { PlatformMetadata.tileSpacing }

    init(model: AppModel, server: ConnectedServer, path: Binding<[AppRoute]>) {
        self.model = model
        self.cache = model.libraryCache
        self.refreshTracker = model.refreshTracker
        _isRefreshing = State(initialValue: model.isLibraryRefreshInProgress)
        self.server = server
        _path = path
    }

    private var projection: LibrariesHomeProjection {
        _ = preferenceRevision
        return LibrariesHomeProjection(server: server, cache: cache)
    }

    var body: some View {
        PlatformLibrariesPageContent(model: model, server: server, path: $path, iOSLayout: AnyView(iOSLayout))
    }

    private var iOSLayout: some View {
        let projection = projection

        return ScrollView {
            VStack(alignment: .leading, spacing: sectionSpacing) {
                ForEach(projection.shelves) { shelf in
                    shelfView(shelf)
                }
            }
            .padding(.top, AppTheme.Spacing.xSmall)
            .padding(.bottom, pagePadding)
        }
        .scrollIndicators(.hidden)
        .navigationTitle(projection.serverName)
        .largeNavigationTitle()
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                toolbarItems(projection)
            }
        }
        .refreshable {
            await refresh()
        }
        .background(AmbientBackdrop(light: light))
        .task(id: leadArtworkURL(projection)) {
            light.light(leadArtworkURL(projection))
        }
        .onReceive(model.refreshTracker.$isLibraryRefreshInProgress) { isRefreshing in
            self.isRefreshing = isRefreshing
        }
        .onReceive(defaultsDidChange) { _ in
            preferenceRevision &+= 1
        }
    }

    @ViewBuilder
    private func toolbarItems(_ projection: LibrariesHomeProjection) -> some View {
        if isRefreshing {
            ProgressView()
                .accessibilityLabel("Refreshing")
        }

        NavigationLink(value: projection.searchRoute) {
            Label("Search", systemImage: "magnifyingglass")
        }

        Menu {
            Button {
                if isRefreshing {
                    model.cancelLibraryRefresh()
                } else {
                    model.refreshAllLibraries(server)
                }
            } label: {
                if isRefreshing {
                    Label("Cancel Refresh", systemImage: "xmark")
                } else {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }
            .disabled(model.isOffline)

            Button {
                path.append(projection.manageRoute)
            } label: {
                Label("Manage", systemImage: "gearshape")
            }

            Button {
                path.append(.about)
            } label: {
                Label("About", systemImage: "info.circle")
            }
        } label: {
            Label("More", systemImage: "ellipsis")
        }
    }

    private func shelfView(_ shelf: LibrariesHomeProjection.Shelf) -> some View {
        let style = shelf.artworkStyle
        let cardWidth: CGFloat = style == .poster
            ? (PlatformMetadata.isPhone ? 128 : 176)
            : (PlatformMetadata.isPhone ? 240 : 300)

        return VStack(alignment: .leading, spacing: shelfSpacing) {
            NavigationLink(value: shelf.libraryRoute) {
                HStack(spacing: AppTheme.Spacing.xSmall) {
                    Text(shelf.title)
                        .font(PlatformMetadata.sectionTitleFont)
                        .lineLimit(1)

                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(AppTheme.tertiaryText)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens the library")
            .padding(.horizontal, pagePadding)

            if shelf.previewItems.isEmpty, refreshTracker.isRefreshing(.library(shelf.id)) {
                skeletonRow(style: style, cardWidth: cardWidth)
            } else if let emptyMessage = shelf.emptyMessage {
                Text(emptyMessage)
                    .font(PlatformMetadata.labelFont)
                    .foregroundStyle(AppTheme.secondaryText)
                    .padding(.horizontal, pagePadding)
            } else {
                ScrollView(.horizontal) {
                    LazyHStack(alignment: .top, spacing: cardSpacing) {
                        ForEach(shelf.previewItems) { item in
                            NavigationLink(value: item.route) {
                                PosterTile(item: item, style: style)
                                    .frame(width: cardWidth)
                            }
                            .buttonStyle(.plain)
                            .mediaItemQuickActions(model: model, item: item)
                            .platformHover { isHovered in
                                if isHovered {
                                    light.light(item.artwork.url(for: style))
                                }
                            }
                        }
                    }
                    .padding(.horizontal, pagePadding)
                    .padding(.vertical, AppTheme.Spacing.xSmall)
                }
                .scrollIndicators(.hidden)
                .scrollClipDisabled()
            }
        }
    }

    private func skeletonRow(style: MediaArtworkStyle, cardWidth: CGFloat) -> some View {
        HStack(spacing: cardSpacing) {
            ForEach(0 ..< 6, id: \.self) { _ in
                RoundedRectangle(cornerRadius: AppTheme.Radius.artwork, style: .continuous)
                    .fill(AppTheme.surfaceFill)
                    .aspectRatio(style.aspectRatio, contentMode: .fit)
                    .frame(width: cardWidth)
            }
        }
        .padding(.horizontal, pagePadding)
        .padding(.vertical, AppTheme.Spacing.xSmall)
        .frame(maxWidth: .infinity, alignment: .leading)
        .clipped()
        .accessibilityLabel("Loading")
    }

    private func leadArtworkURL(_ projection: LibrariesHomeProjection) -> URL? {
        guard let shelf = projection.shelves.first(where: { !$0.previewItems.isEmpty }),
              let item = shelf.previewItems.first else { return nil }
        return item.artwork.url(for: shelf.artworkStyle)
    }

    private func refresh() async {
        guard !model.isOffline else { return }
        model.refreshAllLibraries(server)
        guard model.isLibraryRefreshInProgress else { return }
        for await isRefreshing in model.refreshTracker.$isLibraryRefreshInProgress.values where !isRefreshing {
            return
        }
    }
}
