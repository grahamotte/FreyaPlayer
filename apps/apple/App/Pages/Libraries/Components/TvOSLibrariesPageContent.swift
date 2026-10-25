import Combine
import SwiftUI
import UIKit

struct TvOSLibrariesPageContent: View {
    @ObservedObject var model: AppModel
    let server: ConnectedServer
    @Binding var path: [AppRoute]
    @StateObject private var light = AmbientLight()

    var body: some View {
        LibrariesCollectionView(
            model: model,
            server: server,
            light: light,
            onSelectRoute: { path.append($0) }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AmbientBackdrop(light: light))
    }
}

private struct LibrariesCollectionView: UIViewControllerRepresentable {
    let model: AppModel
    let server: ConnectedServer
    let light: AmbientLight
    let onSelectRoute: (AppRoute) -> Void

    func makeUIViewController(context: Context) -> LibrariesCollectionViewController {
        LibrariesCollectionViewController(
            model: model,
            server: server,
            light: light,
            onSelectRoute: onSelectRoute
        )
    }

    func updateUIViewController(_ viewController: LibrariesCollectionViewController, context: Context) {
        viewController.update(server: server, isOffline: model.isOffline)
    }
}

private final class LibrariesCollectionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    private static let serverHeaderKind = "LibrariesServerHeader"

    private let model: AppModel
    private let light: AmbientLight
    private let onSelectRoute: (AppRoute) -> Void

    private var server: ConnectedServer
    private var sections: [LibrariesSection] = []
    private var preferredFocusItemID: String?
    private var prefetchedArtworkURLs: Set<URL> = []
    private var cacheSubscription: AnyCancellable?
    private var defaultsSubscription: AnyCancellable?
    private var refreshSubscription: AnyCancellable?
    private var isRefreshing = false
    private var isOffline: Bool
    private let searchFocusGuide = UIFocusGuide()
    private lazy var quickActionHandler = MediaItemQuickActionHandler(
        presenter: self,
        model: model,
        focusedItem: { [weak self] in self?.focusedQuickActionItem() }
    )

    private lazy var collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: makeLayout()
    )

    init(
        model: AppModel,
        server: ConnectedServer,
        light: AmbientLight,
        onSelectRoute: @escaping (AppRoute) -> Void
    ) {
        self.model = model
        self.light = light
        self.server = server
        self.onSelectRoute = onSelectRoute
        self.isRefreshing = model.isLibraryRefreshInProgress
        self.isOffline = model.isOffline
        super.init(nibName: nil, bundle: nil)
        sections = makeSections(from: server)
        if let section = sections.first(where: { $0.items.contains { $0.kind == .media } }) {
            light.light(leadArtworkURL(in: section, focusing: 0))
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .clear
        view.clipsToBounds = false
        view.insetsLayoutMarginsFromSafeArea = false

        collectionView.backgroundColor = .clear
        collectionView.clipsToBounds = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.remembersLastFocusedIndexPath = true
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.contentInset = .init(top: AppTheme.Spacing.small, left: 0, bottom: PlatformMetadata.pageGutter, right: 0)
        collectionView.insetsLayoutMarginsFromSafeArea = false
        collectionView.layoutMargins = .zero

        collectionView.register(PosterCell.self, forCellWithReuseIdentifier: PosterCell.reuseIdentifier)
        collectionView.register(LibrariesActionCell.self, forCellWithReuseIdentifier: LibrariesActionCell.reuseIdentifier)
        collectionView.register(
            LibrariesSectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: LibrariesSectionHeaderView.reuseIdentifier
        )
        collectionView.register(
            LibrariesSectionFooterView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: LibrariesSectionFooterView.reuseIdentifier
        )
        collectionView.register(
            LibrariesServerHeaderView.self,
            forSupplementaryViewOfKind: Self.serverHeaderKind,
            withReuseIdentifier: LibrariesServerHeaderView.reuseIdentifier
        )

        view.addSubview(collectionView)
        view.addLayoutGuide(searchFocusGuide)

        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            searchFocusGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: PlatformMetadata.pageGutter),
            searchFocusGuide.topAnchor.constraint(equalTo: view.topAnchor),
            searchFocusGuide.widthAnchor.constraint(equalToConstant: 480),
            searchFocusGuide.heightAnchor.constraint(equalToConstant: 184)
        ])

        cacheSubscription = model.libraryCache.snapshotDidChange
            .throttle(for: .milliseconds(250), scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] _ in
                self?.rebuildSectionsPreservingScrollPosition()
            }

        defaultsSubscription = NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .sink { [weak self] _ in
                self?.rebuildSectionsPreservingScrollPosition()
            }

        refreshSubscription = model.refreshTracker.$isLibraryRefreshInProgress
            .sink { [weak self] isRefreshing in
                guard let self else { return }
                guard self.isRefreshing != isRefreshing else { return }
                self.isRefreshing = isRefreshing
                self.reconfigureRefreshCell()
            }
    }

    func update(server: ConnectedServer, isOffline: Bool) {
        guard self.server != server || self.isOffline != isOffline else { return }
        let didChangeServer = self.server != server
        let didChangeServerIdentity = self.server.id != server.id
        let didChangeOfflineState = self.isOffline != isOffline
        self.server = server
        self.isOffline = isOffline
        isRefreshing = model.isLibraryRefreshInProgress

        guard isViewLoaded else {
            if didChangeServer {
                sections = makeSections(from: server)
            }
            return
        }
        if didChangeServerIdentity {
            sections = makeSections(from: server)
            reloadDataPreservingScrollPosition(false)
        } else if didChangeServer {
            rebuildSectionsPreservingScrollPosition()
            refreshServerHeader()
        }
        if didChangeOfflineState {
            reconfigureRefreshCell()
        }
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        sections.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        sections[section].items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let item = sections[indexPath.section].items[indexPath.item]

        switch item.kind {
        case .manageServer, .refresh:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: LibrariesActionCell.reuseIdentifier,
                for: indexPath
            ) as! LibrariesActionCell
            cell.configure(
                title: item.title,
                isRefreshing: item.kind == .refresh && isRefreshing,
                isEnabled: isEnabled(item)
            ) { [weak self] in
                self?.handlePrimaryAction(for: item)
            }
            return cell

        case .openLibrary, .media:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: PosterCell.reuseIdentifier,
                for: indexPath
            ) as! PosterCell
            configure(cell, with: item)
            return cell
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        if kind == Self.serverHeaderKind {
            let view = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: LibrariesServerHeaderView.reuseIdentifier,
                for: indexPath
            ) as! LibrariesServerHeaderView
            view.configure(title: server.serverName) { [weak self] in
                guard let self else { return }
                self.onSelectRoute(.search(self.server))
            }
            searchFocusGuide.preferredFocusEnvironments = [view.searchFocusTarget]
            return view
        }

        let section = sections[indexPath.section]
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let view = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: LibrariesSectionHeaderView.reuseIdentifier,
                for: indexPath
            ) as! LibrariesSectionHeaderView
            view.title = section.title
            return view

        default:
            let view = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: LibrariesSectionFooterView.reuseIdentifier,
                for: indexPath
            ) as! LibrariesSectionFooterView
            view.title = section.emptyMessage
            return view
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = sections[indexPath.section].items[indexPath.item]
        handlePrimaryAction(for: item)
    }

    func collectionView(_ collectionView: UICollectionView, canFocusItemAt indexPath: IndexPath) -> Bool {
        switch sections[indexPath.section].items[indexPath.item].kind {
        case .openLibrary, .media:
            return true
        case .manageServer, .refresh:
            return false
        }
    }

    func indexPathForPreferredFocusedView(in collectionView: UICollectionView) -> IndexPath? {
        guard let targetItemID = preferredFocusItemID else { return nil }

        for (sectionIndex, section) in sections.enumerated() {
            if let itemIndex = section.items.firstIndex(where: { $0.id == targetItemID }) {
                return IndexPath(item: itemIndex, section: sectionIndex)
            }
        }

        preferredFocusItemID = nil
        return nil
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        quickActionHandler.pressesBegan(presses)
        super.pressesBegan(presses, with: event)
    }

    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if quickActionHandler.pressesEnded(presses) {
            return
        }

        super.pressesEnded(presses, with: event)
    }

    override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        quickActionHandler.pressesCancelled(presses)
        super.pressesCancelled(presses, with: event)
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)

        guard let indexPath = indexPath(for: context.nextFocusedView),
              sections.indices.contains(indexPath.section),
              sections[indexPath.section].items.indices.contains(indexPath.item)
        else {
            return
        }

        preferredFocusItemID = nil
        light.light(leadArtworkURL(in: sections[indexPath.section], focusing: indexPath.item))
    }

    private func leadArtworkURL(in section: LibrariesSection, focusing index: Int) -> URL? {
        let item = section.items[index]
        if item.kind == .media {
            return item.artworkURL
        }
        return section.items.first { $0.kind == .media }?.artworkURL
    }

    private func configure(_ cell: PosterCell, with item: LibrariesItem) {
        cell.configure(
            title: item.title,
            subtitle: nil,
            artworkURL: item.artworkURL,
            style: item.style,
            progress: item.progress,
            isWatched: item.isWatched,
            placeholderIcon: item.iconName,
            placeholderTitle: item.kind == .openLibrary ? item.title : nil,
            captionMode: .focused
        )
    }

    private func makeLayout() -> UICollectionViewLayout {
        let horizontalInset = PlatformMetadata.pageGutter
        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        configuration.contentInsetsReference = .none
        configuration.interSectionSpacing = AppTheme.Spacing.xxLarge
        configuration.boundarySupplementaryItems = [
            NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(184)),
                elementKind: Self.serverHeaderKind,
                alignment: .top
            )
        ]

        return UICollectionViewCompositionalLayout(sectionProvider: { [weak self] sectionIndex, environment in
            guard let self else { return nil }
            let section = sections[sectionIndex]

            switch section.kind {
            case .library(let style):
                let cellSize = style.shelfCellSize(
                    for: environment.container.effectiveContentSize.width - (horizontalInset * 2)
                )
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .absolute(cellSize.width),
                    heightDimension: .absolute(cellSize.height + PosterCell.captionHeight(showsSubtitle: false))
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: itemSize, subitems: [item])
                let layoutSection = NSCollectionLayoutSection(group: group)
                layoutSection.interGroupSpacing = PlatformMetadata.tileSpacing
                layoutSection.orthogonalScrollingBehavior = .continuousGroupLeadingBoundary
                layoutSection.contentInsets = .init(top: AppTheme.Spacing.xLarge, leading: horizontalInset, bottom: 0, trailing: horizontalInset)

                let headerSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .absolute(56)
                )
                let header = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: headerSize,
                    elementKind: UICollectionView.elementKindSectionHeader,
                    alignment: .top
                )
                let footerSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .absolute(56)
                )
                let footer = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: footerSize,
                    elementKind: UICollectionView.elementKindSectionFooter,
                    alignment: .bottom
                )
                layoutSection.boundarySupplementaryItems = section.emptyMessage == nil ? [header] : [header, footer]
                return layoutSection

            case .manage:
                let buttonSize = PlatformMetadata.tvActionButtonSize
                let buttonWidth = buttonSize.width
                let buttonSpacing = PlatformMetadata.controlSpacing
                let buttonCount = section.items.count
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .absolute(buttonWidth),
                    heightDimension: .absolute(buttonSize.height)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                let groupWidth = (buttonWidth * CGFloat(buttonCount)) + (buttonSpacing * CGFloat(max(buttonCount - 1, 0)))
                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .absolute(groupWidth),
                    heightDimension: .absolute(buttonSize.height)
                )
                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: groupSize,
                    repeatingSubitem: item,
                    count: buttonCount
                )
                group.interItemSpacing = .fixed(buttonSpacing)
                let layoutSection = NSCollectionLayoutSection(group: group)
                layoutSection.contentInsets = .init(top: AppTheme.Spacing.large, leading: horizontalInset, bottom: AppTheme.Spacing.xLarge, trailing: horizontalInset)
                return layoutSection
            }
        }, configuration: configuration)
    }

    private func prefetchArtwork(for sections: [LibrariesSection]) {
        let urls = sections.flatMap { $0.items.compactMap(\.artworkURL) }.filter { !prefetchedArtworkURLs.contains($0) }
        guard !urls.isEmpty else { return }
        prefetchedArtworkURLs.formUnion(urls)
        Task {
            for url in urls {
                _ = await ArtworkImageCache.shared.loadImage(from: url)
            }
        }
    }

    private func makeSections(from server: ConnectedServer) -> [LibrariesSection] {
        let projection = LibrariesHomeProjection(server: server, cache: model.libraryCache)
        let librarySections = projection.shelves.map { shelf in
            let style = shelf.artworkStyle
            let openItem = LibrariesItem(
                id: "\(shelf.id)-open",
                title: "Open Library",
                artworkURL: nil,
                progress: nil,
                isWatched: false,
                mediaItem: nil,
                route: shelf.libraryRoute,
                style: style,
                kind: .openLibrary,
                iconName: "square.grid.2x2"
            )

            let mediaItems = shelf.previewItems.map { item in
                LibrariesItem(
                    id: item.id,
                    title: item.title,
                    artworkURL: item.artwork.url(for: style),
                    progress: item.progress,
                    isWatched: item.isWatched,
                    mediaItem: item,
                    route: item.route,
                    style: style,
                    kind: .media,
                    iconName: style.placeholderIconName
                )
            }

            return LibrariesSection(
                id: shelf.id,
                title: shelf.title,
                kind: .library(style),
                items: [openItem] + mediaItems,
                emptyMessage: shelf.emptyMessage
            )
        }

        let manageSection = LibrariesSection(
            id: "manage-server",
            title: nil,
            kind: .manage,
            items: [
                LibrariesItem(
                    id: "refresh",
                    title: "Refresh",
                    artworkURL: nil,
                    progress: nil,
                    isWatched: false,
                    mediaItem: nil,
                    route: nil,
                    style: .landscape,
                    kind: .refresh,
                    iconName: nil
                ),
                LibrariesItem(
                    id: "manage-server",
                    title: "Manage",
                    artworkURL: nil,
                    progress: nil,
                    isWatched: false,
                    mediaItem: nil,
                    route: projection.manageRoute,
                    style: .landscape,
                    kind: .manageServer,
                    iconName: nil
                ),
                LibrariesItem(
                    id: "about",
                    title: "About",
                    artworkURL: nil,
                    progress: nil,
                    isWatched: false,
                    mediaItem: nil,
                    route: .about,
                    style: .landscape,
                    kind: .manageServer,
                    iconName: nil
                )
            ],
            emptyMessage: nil
        )

        prefetchArtwork(for: librarySections)
        return librarySections + [manageSection]
    }

    private func refreshServerHeader() {
        let indexPath = IndexPath(item: 0, section: 0)
        let header = collectionView.supplementaryView(
            forElementKind: Self.serverHeaderKind,
            at: indexPath
        ) as? LibrariesServerHeaderView
        header?.configure(title: server.serverName) { [weak self] in
            guard let self else { return }
            self.onSelectRoute(.search(self.server))
        }
        if let header {
            searchFocusGuide.preferredFocusEnvironments = [header.searchFocusTarget]
        }
    }

    private func reloadDataPreservingScrollPosition(_ shouldPreserveScrollPosition: Bool) {
        let contentOffset = collectionView.contentOffset

        UIView.performWithoutAnimation {
            collectionView.reloadData()
            collectionView.layoutIfNeeded()
        }

        guard shouldPreserveScrollPosition else { return }

        let minOffsetY = -collectionView.adjustedContentInset.top
        let maxOffsetY = max(
            collectionView.contentSize.height - collectionView.bounds.height + collectionView.adjustedContentInset.bottom,
            minOffsetY
        )
        let restoredOffset = CGPoint(
            x: contentOffset.x,
            y: min(max(contentOffset.y, minOffsetY), maxOffsetY)
        )

        collectionView.setContentOffset(restoredOffset, animated: false)
    }

    private func indexPath(for focusedView: UIView?) -> IndexPath? {
        var view = focusedView

        while let current = view {
            if let cell = current as? UICollectionViewCell {
                return collectionView.indexPath(for: cell)
            }

            view = current.superview
        }

        return nil
    }

    private func handlePrimaryAction(for item: LibrariesItem) {
        guard isEnabled(item) else { return }
        if item.kind == .refresh {
            if isRefreshing {
                model.cancelLibraryRefresh()
            } else {
                model.refreshAllLibraries(server)
            }
            return
        }

        guard let route = item.route else { return }
        onSelectRoute(route)
    }

    private func focusedQuickActionItem() -> MediaItem? {
        guard let cell = collectionView.visibleCells.first(where: \.isFocused),
              let indexPath = collectionView.indexPath(for: cell)
        else {
            return nil
        }

        let item = sections[indexPath.section].items[indexPath.item]
        guard case .media = item.kind else { return nil }
        return item.mediaItem
    }

    private func isEnabled(_ item: LibrariesItem) -> Bool {
        if item.kind == .refresh {
            return !isOffline
        }
        return true
    }

    private func rebuildSectionsPreservingScrollPosition(preferredFocusItemID: String? = nil) {
        let previousReloadKey = reloadKey(for: sections)
        let nextSections = makeSections(from: server)
        let nextReloadKey = reloadKey(for: nextSections)
        let changedSectionIndexes = changedLibrarySectionIndexes(
            from: previousReloadKey,
            to: nextReloadKey
        )

        sections = nextSections

        guard isViewLoaded else { return }

        if previousReloadKey == nextReloadKey {
            reconfigureVisibleLibraryCells()
            requestPreferredFocusUpdateIfNeeded()
            return
        }

        self.preferredFocusItemID = preferredFocusItemID ?? focusedItemID()
        if let changedSectionIndexes {
            reloadSectionsPreservingScrollPosition(changedSectionIndexes)
        } else {
            reloadDataPreservingScrollPosition(true)
        }
        requestPreferredFocusUpdateIfNeeded()
    }

    private func requestPreferredFocusUpdateIfNeeded() {
        guard preferredFocusItemID != nil else { return }
        collectionView.setNeedsFocusUpdate()
        collectionView.updateFocusIfNeeded()
    }

    private func reconfigureVisibleLibraryCells() {
        for indexPath in collectionView.indexPathsForVisibleItems {
            guard sections.indices.contains(indexPath.section),
                  sections[indexPath.section].items.indices.contains(indexPath.item)
            else {
                continue
            }

            let item = sections[indexPath.section].items[indexPath.item]
            guard let cell = collectionView.cellForItem(at: indexPath) as? PosterCell else { continue }
            configure(cell, with: item)
        }
    }

    private func changedLibrarySectionIndexes(
        from previous: [LibrariesSectionReloadKey],
        to next: [LibrariesSectionReloadKey]
    ) -> IndexSet? {
        guard previous.count == next.count else { return nil }
        guard zip(previous, next).allSatisfy({
            $0.0.id == $0.1.id && $0.0.kind == $0.1.kind
        }) else {
            return nil
        }

        let changedIndexes = previous.indices.filter { previous[$0] != next[$0] }
        guard changedIndexes.allSatisfy({
            if case .library = next[$0].kind {
                return true
            }
            return false
        }) else {
            return nil
        }
        return IndexSet(changedIndexes)
    }

    private func reloadSectionsPreservingScrollPosition(_ sectionIndexes: IndexSet) {
        guard !sectionIndexes.isEmpty else { return }
        let contentOffset = collectionView.contentOffset

        UIView.performWithoutAnimation {
            collectionView.reloadSections(sectionIndexes)
            collectionView.layoutIfNeeded()
        }
        collectionView.setContentOffset(contentOffset, animated: false)
    }

    private func reconfigureRefreshCell() {
        guard isViewLoaded else { return }

        for indexPath in collectionView.indexPathsForVisibleItems {
            guard sections[indexPath.section].items[indexPath.item].kind == .refresh,
                  let cell = collectionView.cellForItem(at: indexPath) as? LibrariesActionCell
            else {
                continue
            }

            cell.update(isRefreshing: isRefreshing, isEnabled: !isOffline)
        }
    }

    private func focusedItemID() -> String? {
        guard let cell = collectionView.visibleCells.first(where: \.isFocused),
              let indexPath = collectionView.indexPath(for: cell),
              sections.indices.contains(indexPath.section),
              sections[indexPath.section].items.indices.contains(indexPath.item)
        else {
            return nil
        }

        return sections[indexPath.section].items[indexPath.item].id
    }

    private func reloadKey(for sections: [LibrariesSection]) -> [LibrariesSectionReloadKey] {
        sections.map { section in
            LibrariesSectionReloadKey(
                id: section.id,
                kind: section.kind,
                itemKeys: section.items.map {
                    LibrariesItemReloadKey(
                        id: $0.id,
                        artworkURL: $0.artworkURL,
                        route: $0.route,
                        style: $0.style,
                        kind: $0.kind,
                        iconName: $0.iconName
                    )
                }
            )
        }
    }
}

private struct LibrariesSection: Hashable {
    let id: String
    let title: String?
    let kind: LibrariesSectionKind
    let items: [LibrariesItem]
    let emptyMessage: String?
}

private enum LibrariesSectionKind: Hashable {
    case library(MediaArtworkStyle)
    case manage
}

private struct LibrariesItem: Hashable {
    let id: String
    let title: String
    let artworkURL: URL?
    let progress: Double?
    let isWatched: Bool
    let mediaItem: MediaItem?
    let route: AppRoute?
    let style: MediaArtworkStyle
    let kind: LibrariesItemKind
    let iconName: String?
}

private enum LibrariesItemKind: Hashable {
    case openLibrary
    case media
    case manageServer
    case refresh
}

private struct LibrariesSectionReloadKey: Equatable {
    let id: String
    let kind: LibrariesSectionKind
    let itemKeys: [LibrariesItemReloadKey]
}

private struct LibrariesItemReloadKey: Equatable {
    let id: String
    let artworkURL: URL?
    let route: AppRoute?
    let style: MediaArtworkStyle
    let kind: LibrariesItemKind
    let iconName: String?
}

private final class LibrariesActionCell: UICollectionViewCell {
    static let reuseIdentifier = "LibrariesActionCell"
    private let button = UIButton(configuration: .glass())
    private var title = ""
    private var isRefreshing = false
    private var onPrimaryAction: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = false
        contentView.clipsToBounds = false

        button.translatesAutoresizingMaskIntoConstraints = false
        button.addAction(UIAction { [weak self] _ in self?.onPrimaryAction?() }, for: .primaryActionTriggered)
        button.configurationUpdateHandler = { [weak self] button in
            guard let self, var configuration = button.configuration else { return }
            if isRefreshing {
                configuration.title = button.isFocused ? "Cancel Refresh" : "Refreshing..."
                configuration.showsActivityIndicator = !button.isFocused
            } else {
                configuration.title = title
                configuration.showsActivityIndicator = false
            }
            button.configuration = configuration
        }

        contentView.addSubview(button)
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            button.topAnchor.constraint(equalTo: contentView.topAnchor),
            button.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String, isRefreshing: Bool, isEnabled: Bool, onPrimaryAction: @escaping () -> Void) {
        self.title = title
        self.onPrimaryAction = onPrimaryAction
        update(isRefreshing: isRefreshing, isEnabled: isEnabled)
    }

    func update(isRefreshing: Bool, isEnabled: Bool) {
        self.isRefreshing = isRefreshing
        button.isEnabled = isEnabled
        button.setNeedsUpdateConfiguration()
    }
}

private final class LibrariesSectionFooterView: UICollectionReusableView {
    static let reuseIdentifier = "LibrariesSectionFooterView"
    private let verticalInset = AppTheme.Spacing.small

    private let label = UILabel()

    var title: String? {
        didSet {
            label.text = title
            setNeedsLayout()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = AppTheme.uiSecondaryText
        label.numberOfLines = 1
        label.lineBreakMode = .byClipping
        label.setContentCompressionResistancePriority(.required, for: .horizontal)

        addSubview(label)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let availableHeight = max(bounds.height - verticalInset, 0)
        let labelSize = label.sizeThatFits(
            CGSize(width: .greatestFiniteMagnitude, height: availableHeight)
        )
        label.frame = CGRect(
            x: 0,
            y: verticalInset,
            width: labelSize.width,
            height: min(labelSize.height, availableHeight)
        )
    }
}

private final class LibrariesServerHeaderView: UICollectionReusableView {
    static let reuseIdentifier = "LibrariesServerHeaderView"
    private let horizontalInset = PlatformMetadata.pageGutter
    private let label = UILabel()
    private let searchButton = UIButton()
    private var onSearch: (() -> Void)?

    var searchFocusTarget: UIView {
        searchButton
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        label.font = PlatformMetadata.uiPageTitleFont
        label.textColor = AppTheme.uiPrimaryText
        label.translatesAutoresizingMaskIntoConstraints = false

        var configuration = UIButton.Configuration.glass()
        configuration.title = "Search"
        configuration.image = UIImage(systemName: "magnifyingglass")
        configuration.imagePadding = AppTheme.Spacing.small
        searchButton.configuration = configuration
        searchButton.accessibilityLabel = "Search Server"
        searchButton.translatesAutoresizingMaskIntoConstraints = false
        searchButton.addTarget(self, action: #selector(search), for: .primaryActionTriggered)

        addSubview(label)
        addSubview(searchButton)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: horizontalInset),
            label.trailingAnchor.constraint(lessThanOrEqualTo: searchButton.leadingAnchor, constant: -AppTheme.Spacing.large),
            label.topAnchor.constraint(equalTo: topAnchor, constant: AppTheme.Spacing.xxLarge),
            label.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -AppTheme.Spacing.xxLarge),

            searchButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -horizontalInset),
            searchButton.centerYAnchor.constraint(equalTo: label.centerYAnchor),
            searchButton.widthAnchor.constraint(equalToConstant: PlatformMetadata.tvActionButtonSize.width),
            searchButton.heightAnchor.constraint(equalToConstant: PlatformMetadata.tvActionButtonSize.height)
        ])
    }

    func configure(title: String?, onSearch: @escaping () -> Void) {
        label.text = title
        self.onSearch = onSearch
    }

    @objc private func search() {
        onSearch?()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        label.text = nil
        onSearch = nil
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class LibrariesSectionHeaderView: UICollectionReusableView {
    static let reuseIdentifier = "LibrariesSectionHeaderView"
    private let verticalInset = AppTheme.Spacing.small

    private let label = UILabel()

    var title: String? {
        didSet { label.text = title }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        label.font = PlatformMetadata.uiSectionTitleFont
        label.textColor = AppTheme.uiPrimaryText
        label.translatesAutoresizingMaskIntoConstraints = false

        addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            label.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -verticalInset)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension MediaArtworkStyle {
    var shelfColumns: CGFloat {
        switch self {
        case .poster:
            return 6
        case .landscape:
            return 4
        }
    }

    func shelfCellSize(for availableWidth: CGFloat) -> CGSize {
        let spacing = PlatformMetadata.tileSpacing
        let width = floor((availableWidth - (spacing * (shelfColumns - 1))) / shelfColumns)
        let height = floor(width / aspectRatio)
        return CGSize(width: width, height: height)
    }
}
