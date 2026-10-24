import SwiftUI

struct LibrariesPage: View {
    @ObservedObject var model: AppModel
    @ObservedObject private var cache: LibraryCache
    @State private var isRefreshing = false
    @State private var isHoveringRefresh = false
    @State private var preferenceRevision = 0
    let server: ConnectedServer
    @Binding var path: [AppRoute]
    private let defaultsDidChange = NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)

    private var pagePadding: CGFloat { PlatformMetadata.pageGutter }
    private var sectionSpacing: CGFloat { PlatformMetadata.pageSectionSpacing }
    private var shelfSpacing: CGFloat { PlatformMetadata.shelfSpacing }
    private var cardSpacing: CGFloat { PlatformMetadata.tileSpacing }
    private var actionButtonStyle: GlassButtonStyle {
        .glass
    }

    init(model: AppModel, server: ConnectedServer, path: Binding<[AppRoute]>) {
        self.model = model
        self.cache = model.libraryCache
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
        ScrollView {
            VStack(alignment: .leading, spacing: sectionSpacing) {
                HStack(spacing: PlatformMetadata.controlSpacing) {
                    Text(projection.serverName)
                        .font(PlatformMetadata.pageTitleFont)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Spacer(minLength: AppTheme.Spacing.medium)

                    NavigationLink(value: projection.searchRoute) {
                        Label("Search", systemImage: "magnifyingglass")
                    }
                    .buttonStyle(actionButtonStyle)
                    .accessibilityLabel("Search Server")
                }
                .padding(.horizontal, pagePadding)
                .padding(.top, PlatformMetadata.isPhone ? AppTheme.Spacing.xSmall : AppTheme.Spacing.medium)

                ForEach(projection.shelves) { shelf in
                    let artworkStyle = shelf.artworkStyle
                    let cardWidth: CGFloat = artworkStyle == .poster ? (PlatformMetadata.isPhone ? 130 : 180) : (PlatformMetadata.isPhone ? 200 : 280)
                    VStack(alignment: .leading, spacing: shelfSpacing) {
                        Text(shelf.title)
                            .font(PlatformMetadata.sectionTitleFont)
                            .lineLimit(1)
                            .padding(.horizontal, pagePadding)

                        ScrollView(.horizontal) {
                            HStack(alignment: .top, spacing: cardSpacing) {
                                NavigationLink(value: shelf.libraryRoute) {
                                    OpenLibraryCard(artworkStyle: artworkStyle)
                                        .frame(width: cardWidth)
                                }
                                .buttonStyle(.plain)

                                ForEach(shelf.previewItems) { item in
                                    NavigationLink(value: item.route) {
                                        LibraryItemCard(item: item, artworkStyle: artworkStyle)
                                            .frame(width: cardWidth)
                                    }
                                    .buttonStyle(.plain)
                                    .mediaItemQuickActions(model: model, item: item)
                                }
                            }
                            .padding(.horizontal, pagePadding)
                            .padding(.vertical, AppTheme.Spacing.xxSmall)
                        }
                        .scrollIndicators(.hidden)

                        if let emptyMessage = shelf.emptyMessage {
                            Text(emptyMessage)
                                .font(PlatformMetadata.labelFont)
                                .foregroundStyle(AppTheme.secondaryText)
                                .padding(.horizontal, pagePadding)
                        }
                    }
                }

                HStack(spacing: PlatformMetadata.controlSpacing) {
                    Button {
                        if isRefreshing {
                            model.cancelLibraryRefresh()
                        } else {
                            model.refreshAllLibraries(server)
                        }
                    } label: {
                        if isHoveringRefresh, isRefreshing {
                            Text("Cancel Refresh")
                        } else if isRefreshing {
                            HStack(spacing: AppTheme.Spacing.xSmall) {
                                ProgressView()
                                    .controlSize(.small)
                                Text("Refreshing...")
                            }
                        } else {
                            Text("Refresh")
                        }
                    }
                    .buttonStyle(actionButtonStyle)
                    .disabled(model.isOffline)
                    .platformHover { isHoveringRefresh = $0 }
                    .help(isRefreshing ? "Cancel Refresh" : "Refresh")

                    NavigationLink(value: projection.manageRoute) {
                        Text("Manage")
                    }
                    .buttonStyle(actionButtonStyle)

                    NavigationLink(value: AppRoute.about) {
                        Text("About")
                    }
                    .buttonStyle(actionButtonStyle)
                }
                .padding(.horizontal, pagePadding)
                .padding(.top, AppTheme.Spacing.xSmall)
                .padding(.bottom, pagePadding)
            }
        }
        .scrollIndicators(.hidden)
        .background(BrowsingBackground())
        .onReceive(model.refreshTracker.$isLibraryRefreshInProgress) { isRefreshing in
            self.isRefreshing = isRefreshing
            if !isRefreshing {
                isHoveringRefresh = false
            }
        }
        .onReceive(defaultsDidChange) { _ in
            preferenceRevision &+= 1
        }
    }
}

private struct OpenLibraryCard: View {
    let artworkStyle: MediaArtworkStyle

    var body: some View {
        VStack(alignment: .leading, spacing: PlatformMetadata.tileTitleSpacing) {
            RoundedRectangle(cornerRadius: AppTheme.Radius.artwork, style: .continuous)
                .fill(AppTheme.surfaceFill)
                .overlay(alignment: .bottomLeading) {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                        Image(systemName: "arrow.right")
                            .font(.title2.weight(.semibold))

                        Text("Open Library")
                            .font(PlatformMetadata.tileTitleFont)
                    }
                    .foregroundStyle(AppTheme.secondaryText)
                    .padding(AppTheme.Spacing.medium)
                }
                .aspectRatio(artworkStyle.aspectRatio, contentMode: .fit)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
