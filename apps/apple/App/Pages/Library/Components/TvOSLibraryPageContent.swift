import SwiftUI
import UIKit

struct TvOSLibraryPageContent: View {
    @ObservedObject var model: AppModel
    let library: LibraryReference
    @Binding var path: [AppRoute]

    @StateObject private var state: LibraryPageState
    @StateObject private var light = AmbientLight()
    private let defaultsDidChange = NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)

    init(model: AppModel, library: LibraryReference, path: Binding<[AppRoute]>) {
        self.model = model
        self.library = library
        _path = path
        _state = StateObject(wrappedValue: LibraryPageState(model: model, library: library))
    }

    var body: some View {
        Group {
            if state.isLoadingFirstPage {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                LibraryPageCollectionView(
                    state: state,
                    light: light,
                    onSelectRoute: { path.append($0) }
                )
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .background(AmbientBackdrop(light: light))
        .task(id: library.id) {
            state.update(library: library)
        }
        .onReceive(defaultsDidChange) { _ in
            state.loadSavedControls()
        }
    }
}

private struct LibraryPageCollectionView: UIViewControllerRepresentable {
    let state: LibraryPageState
    let light: AmbientLight
    let onSelectRoute: (AppRoute) -> Void

    func makeUIViewController(context: Context) -> LibraryPageCollectionViewController {
        LibraryPageCollectionViewController(
            state: state,
            light: light,
            onSelectRoute: onSelectRoute
        )
    }

    func updateUIViewController(_ viewController: LibraryPageCollectionViewController, context: Context) {
        viewController.update(state: state)
    }
}

private final class LibraryPageCollectionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    private static let headerKind = "LibraryPageHeader"

    private let onSelectRoute: (AppRoute) -> Void
    private let light: AmbientLight

    private var state: LibraryPageState
    private var renderedLibrary: LibraryReference
    private var renderedItemIDs: [String] = []
    private lazy var quickActionHandler = MediaItemQuickActionHandler(
        presenter: self,
        model: state.model,
        focusedItem: { [weak self] in self?.focusedQuickActionItem() }
    )

    private lazy var collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: makeLayout()
    )
    private let emptyLabel = UILabel()
    private let headerFocusGuide = UIFocusGuide()
    private var headerFocusGuideTopConstraint: NSLayoutConstraint?
    private var headerFocusGuideHeightConstraint: NSLayoutConstraint?

    init(
        state: LibraryPageState,
        light: AmbientLight,
        onSelectRoute: @escaping (AppRoute) -> Void
    ) {
        self.state = state
        self.light = light
        self.renderedLibrary = state.library
        self.onSelectRoute = onSelectRoute
        super.init(nibName: nil, bundle: nil)
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

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.clipsToBounds = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.remembersLastFocusedIndexPath = true
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.contentInset = .zero
        collectionView.insetsLayoutMarginsFromSafeArea = false
        collectionView.layoutMargins = .zero
        collectionView.register(PosterCell.self, forCellWithReuseIdentifier: PosterCell.reuseIdentifier)
        collectionView.register(
            LibraryPageHeaderView.self,
            forSupplementaryViewOfKind: Self.headerKind,
            withReuseIdentifier: LibraryPageHeaderView.reuseIdentifier
        )

        emptyLabel.font = .preferredFont(forTextStyle: .title3)
        emptyLabel.textColor = AppTheme.uiSecondaryText
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        collectionView.backgroundView = emptyLabel

        collectionView.addLayoutGuide(headerFocusGuide)
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        headerFocusGuideTopConstraint = headerFocusGuide.topAnchor.constraint(equalTo: collectionView.topAnchor)
        headerFocusGuideHeightConstraint = headerFocusGuide.heightAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            headerFocusGuide.leadingAnchor.constraint(equalTo: collectionView.leadingAnchor),
            headerFocusGuide.trailingAnchor.constraint(equalTo: collectionView.trailingAnchor),
            headerFocusGuideTopConstraint!,
            headerFocusGuideHeightConstraint!
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateHeaderFocusGuide()
    }

    func update(state: LibraryPageState) {
        let didChangeLibrary = renderedLibrary != state.library
        self.state = state
        renderedLibrary = state.library

        guard isViewLoaded else { return }

        let newIDs = state.displayedItems.map(\.id)
        let structureChanged = newIDs != renderedItemIDs
        renderedItemIDs = newIDs

        if structureChanged {
            reloadDataPreservingScrollPosition(!didChangeLibrary)
        } else {
            reconfigureVisibleCells()
        }

        updateEmptyState()
        refreshHeader()
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        state.displayedItems.count
    }

    func indexTitles(for collectionView: UICollectionView) -> [String]? {
        let titles = indexTitleTargets.map(\.title)
        return titles.count > 1 ? titles : nil
    }

    func collectionView(_ collectionView: UICollectionView, indexPathForIndexTitle title: String, at index: Int) -> IndexPath {
        guard indexTitleTargets.indices.contains(index) else {
            return IndexPath(item: 0, section: 0)
        }

        return indexTitleTargets[index].indexPath
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: PosterCell.reuseIdentifier,
            for: indexPath
        ) as! PosterCell
        configure(cell, with: state.displayedItems[indexPath.item])
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: LibraryPageHeaderView.reuseIdentifier,
            for: indexPath
        ) as! LibraryPageHeaderView

        header.configure(
            title: state.library.title,
            countText: state.countText,
            selectedFilter: state.filter,
            selectedSort: state.sort,
            selectedSortOrder: state.sortOrder,
            playAllButton: libraryPlayAllButtonView(),
            watchButton: libraryWatchButtonView(),
            onFilterChange: { [weak self] filter in
                self?.setFilter(filter)
            },
            onSortChange: { [weak self] sort in
                self?.setSort(sort)
            },
            onSortOrderChange: { [weak self] order in
                self?.setSortOrder(order)
            }
        )
        return header
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        onSelectRoute(state.displayedItems[indexPath.item].route)
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

        var view = context.nextFocusedView
        while let current = view, !(current is UICollectionViewCell) {
            view = current.superview
        }
        guard let cell = view as? UICollectionViewCell,
              let indexPath = collectionView.indexPath(for: cell),
              state.displayedItems.indices.contains(indexPath.item)
        else {
            return
        }
        light.light(artworkURL(for: state.displayedItems[indexPath.item]))
    }

    private func configure(_ cell: PosterCell, with item: MediaItem) {
        cell.configure(
            title: item.title,
            subtitle: item.libraryTileSubtitle(showsAddedAt: state.sort == .addedAt) ?? "",
            artworkURL: artworkURL(for: item),
            style: tileStyle,
            progress: item.progress,
            isWatched: item.isWatched,
            captionMode: .always
        )
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let topOffset = -scrollView.adjustedContentInset.top
        if scrollView.contentOffset.y > topOffset, focusedRow() == 0 {
            scrollView.contentOffset.y = topOffset
        }
        updateHeaderFocusGuide()
    }

    private func focusedRow() -> Int? {
        guard let cell = collectionView.visibleCells.first(where: \.isFocused),
              let indexPath = collectionView.indexPath(for: cell)
        else {
            return nil
        }
        return indexPath.item / tileStyle.gridColumns
    }

    private var tileStyle: MediaArtworkStyle {
        state.library.artworkStyle
    }

    private func artworkURL(for item: MediaItem) -> URL? {
        item.artwork.url(for: tileStyle)
    }

    private var indexTitleTargets: [(title: String, indexPath: IndexPath)] {
        var seen = Set<String>()
        return state.displayedItems.enumerated().compactMap { offset, item in
            guard let title = indexTitle(for: item), seen.insert(title).inserted else { return nil }
            return (title, IndexPath(item: offset, section: 0))
        }
    }

    private func indexTitle(for item: MediaItem) -> String? {
        switch state.sort {
        case .addedAt:
            guard let addedAt = item.addedAt else { return "No Date" }
            return addedAtIndexTitle(Date(timeIntervalSince1970: TimeInterval(addedAt)))
        case .duration:
            guard let duration = item.durationMilliseconds else { return "No Runtime" }
            let minutes = duration / 60_000
            if minutes < 30 { return "<30m" }
            if minutes < 60 { return "30m" }
            return "\(minutes / 60)h"
        case .title:
            break
        }

        guard let scalar = item.title.trimmingCharacters(in: .whitespacesAndNewlines).unicodeScalars.first else { return nil }
        return CharacterSet.letters.contains(scalar) ? String(scalar).uppercased() : "#"
    }

    private func addedAtIndexTitle(_ date: Date) -> String {
        let days = max(Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0, 0) + 1
        if days < 7 { return "\(days)d" }
        if days < 31 { return "\(min((days - 1) / 7 + 1, 4))w" }
        if days < 365 { return "\(min((days - 1) / 30 + 1, 3))m" }
        if days < 1_095 { return "\(min((days - 1) / 365 + 1, 2))y" }
        return ">3y"
    }

    private func libraryWatchButtonView() -> AnyView? {
        guard let item = state.libraryWatchStatusItem else { return nil }

        return AnyView(
            MediaCollectionWatchStatusButton(
                model: state.model,
                libraryItem: item,
                libraryID: state.library.id
            )
        )
    }

    private func libraryPlayAllButtonView() -> AnyView {
        AnyView(MediaPlayAllButton(model: state.model, items: state.displayedPlayableItems))
    }

    private func setFilter(_ filter: LibraryPageFilter) {
        state.setFilter(filter)
        rebuildVisibleStatePreservingScroll()
    }

    private func setSort(_ sort: LibraryPageSort) {
        state.setSort(sort)
        rebuildVisibleStatePreservingScroll()
    }

    private func setSortOrder(_ order: LibraryPageSortOrder) {
        state.setSortOrder(order)
        rebuildVisibleStatePreservingScroll()
    }

    private func updateEmptyState() {
        emptyLabel.text = state.displayedItems.isEmpty ? state.filter.emptyStateText(for: state.library.itemTitle) : nil
    }

    private func focusedQuickActionItem() -> MediaItem? {
        guard let cell = collectionView.visibleCells.first(where: \.isFocused),
              let indexPath = collectionView.indexPath(for: cell)
        else {
            return nil
        }

        return state.displayedItems[indexPath.item]
    }

    private func refreshHeader() {
        let headerIndexPath = IndexPath(item: 0, section: 0)
        let header = collectionView.supplementaryView(
            forElementKind: Self.headerKind,
            at: headerIndexPath
        ) as? LibraryPageHeaderView

        header?.configure(
            title: state.library.title,
            countText: state.countText,
            selectedFilter: state.filter,
            selectedSort: state.sort,
            selectedSortOrder: state.sortOrder,
            playAllButton: libraryPlayAllButtonView(),
            watchButton: libraryWatchButtonView(),
            onFilterChange: { [weak self] filter in
                self?.setFilter(filter)
            },
            onSortChange: { [weak self] sort in
                self?.setSort(sort)
            },
            onSortOrderChange: { [weak self] order in
                self?.setSortOrder(order)
            }
        )

        updateHeaderFocusGuide()
    }

    private func updateHeaderFocusGuide() {
        let headerIndexPath = IndexPath(item: 0, section: 0)
        guard
            let header = collectionView.supplementaryView(
                forElementKind: Self.headerKind,
                at: headerIndexPath
            ) as? LibraryPageHeaderView
        else {
            headerFocusGuide.preferredFocusEnvironments = []
            headerFocusGuideHeightConstraint?.constant = 0
            return
        }

        headerFocusGuide.preferredFocusEnvironments = [header.focusTargetView]
        headerFocusGuideTopConstraint?.constant = header.frame.minY
        headerFocusGuideHeightConstraint?.constant = max(header.frame.height, 0)
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

    private func reconfigureVisibleCells() {
        for indexPath in collectionView.indexPathsForVisibleItems {
            guard indexPath.item < state.displayedItems.count,
                  let cell = collectionView.cellForItem(at: indexPath) as? PosterCell
            else { continue }
            configure(cell, with: state.displayedItems[indexPath.item])
        }
    }

    private func rebuildVisibleStatePreservingScroll() {
        guard isViewLoaded else { return }
        reloadDataPreservingScrollPosition(true)
        updateEmptyState()
        refreshHeader()
    }

    private func makeLayout() -> UICollectionViewLayout {
        let style = tileStyle
        let horizontalInset = PlatformMetadata.pageGutter
        let interItemSpacing = PlatformMetadata.tileSpacing
        let lineSpacing = PlatformMetadata.pageSectionSpacing

        let titleFont = PlatformMetadata.uiPageTitleFont
        let titleHeight = ceil(titleFont.lineHeight)
        let titleTop = AppTheme.Spacing.xxLarge
        let gapBetweenTitleAndButtons = AppTheme.Spacing.large

        let measurementButton = GlassMenuButton()
        measurementButton.title = "Width"
        measurementButton.icon = UIImage(systemName: "line.3.horizontal.decrease")
        let buttonHeight = ceil(measurementButton.systemLayoutSizeFitting(
            CGSize(width: 300, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .fittingSizeLevel,
            verticalFittingPriority: .fittingSizeLevel
        ).height)

        let headerHeight = titleTop + titleHeight + gapBetweenTitleAndButtons + buttonHeight + AppTheme.Spacing.xLarge

        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        configuration.contentInsetsReference = .none
        configuration.boundarySupplementaryItems = [
            NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(headerHeight)),
                elementKind: Self.headerKind,
                alignment: .top
            )
        ]

        return UICollectionViewCompositionalLayout(sectionProvider: { _, environment in
            let columns = style.gridColumns
            let availableWidth = environment.container.effectiveContentSize.width - (horizontalInset * 2)
            let cellWidth = style.gridCellWidth(for: availableWidth, spacing: interItemSpacing)
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .absolute(cellWidth),
                heightDimension: .absolute(style.gridCellHeight(for: cellWidth))
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            let groupWidth = (cellWidth * CGFloat(columns)) + (interItemSpacing * CGFloat(columns - 1))
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .absolute(groupWidth),
                heightDimension: .absolute(style.gridCellHeight(for: cellWidth))
            )
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, repeatingSubitem: item, count: columns)
            group.interItemSpacing = .fixed(interItemSpacing)

            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = lineSpacing
            section.contentInsets = .init(top: AppTheme.Spacing.medium, leading: horizontalInset, bottom: AppTheme.Spacing.xxLarge, trailing: horizontalInset)
            return section
        }, configuration: configuration)
    }
}

private extension MediaArtworkStyle {
    var gridColumns: Int {
        switch self {
        case .poster:
            return 4
        case .landscape:
            return 3
        }
    }

    func gridCellWidth(for availableWidth: CGFloat, spacing: CGFloat) -> CGFloat {
        floor((availableWidth - (spacing * CGFloat(gridColumns - 1))) / CGFloat(gridColumns))
    }

    func gridImageHeight(for width: CGFloat) -> CGFloat {
        floor(width / aspectRatio)
    }

    func gridCellHeight(for width: CGFloat) -> CGFloat {
        gridImageHeight(for: width) + PosterCell.captionHeight(showsSubtitle: true)
    }
}

private final class LibraryPageHeaderView: UICollectionReusableView {
    static let reuseIdentifier = "LibraryPageHeaderView"

    private let titleLabel = UILabel()
    private let countLabel = UILabel()
    private let filterButton = GlassMenuButton()
    private let sortButton = GlassMenuButton()
    private let shuffleButtonHostView = UIView()
    private let watchButtonHostView = UIView()
    private var shuffleButtonHostingController: UIHostingController<AnyView>?
    private var watchButtonHostingController: UIHostingController<AnyView>?
    private var onFilterChange: ((LibraryPageFilter) -> Void)?
    private var onSortChange: ((LibraryPageSort) -> Void)?

    var focusTargetView: UIView {
        filterButton
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        titleLabel.font = PlatformMetadata.uiPageTitleFont
        titleLabel.textColor = AppTheme.uiPrimaryText
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        countLabel.font = PlatformMetadata.uiSectionTitleFont
        countLabel.textColor = AppTheme.uiSecondaryText
        countLabel.translatesAutoresizingMaskIntoConstraints = false

        filterButton.translatesAutoresizingMaskIntoConstraints = false
        filterButton.showsMenuAsPrimaryAction = true
        filterButton.icon = UIImage(systemName: "line.3.horizontal.decrease")

        sortButton.translatesAutoresizingMaskIntoConstraints = false
        sortButton.showsMenuAsPrimaryAction = true

        shuffleButtonHostView.translatesAutoresizingMaskIntoConstraints = false
        shuffleButtonHostView.backgroundColor = .clear
        shuffleButtonHostView.clipsToBounds = false
        shuffleButtonHostView.setContentHuggingPriority(.required, for: .horizontal)
        shuffleButtonHostView.setContentCompressionResistancePriority(.required, for: .horizontal)

        watchButtonHostView.translatesAutoresizingMaskIntoConstraints = false
        watchButtonHostView.backgroundColor = .clear
        watchButtonHostView.clipsToBounds = false
        watchButtonHostView.setContentHuggingPriority(.required, for: .horizontal)
        watchButtonHostView.setContentCompressionResistancePriority(.required, for: .horizontal)

        addSubview(titleLabel)
        addSubview(countLabel)
        addSubview(filterButton)
        addSubview(sortButton)
        addSubview(shuffleButtonHostView)
        addSubview(watchButtonHostView)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: PlatformMetadata.pageGutter),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: AppTheme.Spacing.xxLarge),

            countLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -PlatformMetadata.pageGutter),
            countLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),

            filterButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: PlatformMetadata.pageGutter),
            filterButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: AppTheme.Spacing.large),

            sortButton.leadingAnchor.constraint(equalTo: filterButton.trailingAnchor, constant: PlatformMetadata.controlSpacing),
            sortButton.centerYAnchor.constraint(equalTo: filterButton.centerYAnchor),
            sortButton.heightAnchor.constraint(equalTo: filterButton.heightAnchor),
            sortButton.trailingAnchor.constraint(lessThanOrEqualTo: shuffleButtonHostView.leadingAnchor, constant: -PlatformMetadata.controlSpacing),

            shuffleButtonHostView.leadingAnchor.constraint(greaterThanOrEqualTo: sortButton.trailingAnchor, constant: PlatformMetadata.controlSpacing),
            shuffleButtonHostView.centerYAnchor.constraint(equalTo: filterButton.centerYAnchor),
            shuffleButtonHostView.heightAnchor.constraint(equalTo: filterButton.heightAnchor),

            watchButtonHostView.leadingAnchor.constraint(equalTo: shuffleButtonHostView.trailingAnchor, constant: PlatformMetadata.controlSpacing),
            watchButtonHostView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -PlatformMetadata.pageGutter),
            watchButtonHostView.centerYAnchor.constraint(equalTo: filterButton.centerYAnchor),
            watchButtonHostView.heightAnchor.constraint(equalTo: filterButton.heightAnchor),

            filterButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -AppTheme.Spacing.xLarge),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(
        title: String,
        countText: String,
        selectedFilter: LibraryPageFilter,
        selectedSort: LibraryPageSort,
        selectedSortOrder: LibraryPageSortOrder,
        playAllButton: AnyView,
        watchButton: AnyView?,
        onFilterChange: @escaping (LibraryPageFilter) -> Void,
        onSortChange: @escaping (LibraryPageSort) -> Void,
        onSortOrderChange: @escaping (LibraryPageSortOrder) -> Void
    ) {
        titleLabel.text = title
        countLabel.text = countText
        self.onFilterChange = onFilterChange
        self.onSortChange = onSortChange
        updateFilterButton(for: selectedFilter)
        updateSortButton(for: selectedSort, order: selectedSortOrder, onSortOrderChange: onSortOrderChange)
        updateHostedButton(playAllButton, in: shuffleButtonHostView, hostingController: &shuffleButtonHostingController)
        updateWatchButton(watchButton)
    }

    private func updateFilterButton(for filter: LibraryPageFilter) {
        filterButton.title = filter.title
        filterButton.menu = UIMenu(children: LibraryPageFilter.allCases.map { candidate in
            UIAction(title: candidate.title, state: candidate == filter ? .on : .off) { [weak self] _ in
                self?.onFilterChange?(candidate)
            }
        })
    }

    private func updateSortButton(
        for sort: LibraryPageSort,
        order: LibraryPageSortOrder,
        onSortOrderChange: @escaping (LibraryPageSortOrder) -> Void
    ) {
        sortButton.title = sort.title
        sortButton.icon = UIImage(systemName: order.iconName)
        sortButton.menu = UIMenu(children: [
            UIMenu(title: "Field", options: .displayInline, children: LibraryPageSort.allCases.map { candidate in
                UIAction(title: candidate.title, state: candidate == sort ? .on : .off) { [weak self] _ in
                    self?.onSortChange?(candidate)
                }
            }),
            UIMenu(title: "Order", options: .displayInline, children: LibraryPageSortOrder.allCases.map { candidate in
                UIAction(title: candidate.title, state: candidate == order ? .on : .off) { _ in
                    onSortOrderChange(candidate)
                }
            })
        ])
    }

    private func updateWatchButton(_ watchButton: AnyView?) {
        guard let watchButton else {
            watchButtonHostView.isHidden = true
            watchButtonHostingController?.rootView = AnyView(EmptyView())
            return
        }

        watchButtonHostView.isHidden = false

        updateHostedButton(watchButton, in: watchButtonHostView, hostingController: &watchButtonHostingController)
    }

    private func updateHostedButton(
        _ button: AnyView,
        in hostView: UIView,
        hostingController: inout UIHostingController<AnyView>?
    ) {
        if let hostingController {
            hostingController.rootView = button
            return
        }

        let nextHostingController = UIHostingController(rootView: button)
        if #available(tvOS 16.0, *) {
            nextHostingController.sizingOptions = [.intrinsicContentSize]
        }
        nextHostingController.safeAreaRegions = []
        nextHostingController.view.translatesAutoresizingMaskIntoConstraints = false
        nextHostingController.view.backgroundColor = .clear
        nextHostingController.view.clipsToBounds = false
        nextHostingController.view.setContentHuggingPriority(.required, for: .horizontal)
        nextHostingController.view.setContentCompressionResistancePriority(.required, for: .horizontal)

        hostView.addSubview(nextHostingController.view)

        NSLayoutConstraint.activate([
            nextHostingController.view.leadingAnchor.constraint(equalTo: hostView.leadingAnchor),
            nextHostingController.view.trailingAnchor.constraint(equalTo: hostView.trailingAnchor),
            nextHostingController.view.topAnchor.constraint(equalTo: hostView.topAnchor),
            nextHostingController.view.bottomAnchor.constraint(equalTo: hostView.bottomAnchor)
        ])

        hostingController = nextHostingController
    }
}

private final class GlassMenuButton: UIButton {
    var title: String? {
        didSet { setNeedsUpdateConfiguration() }
    }
    var icon: UIImage? {
        didSet { setNeedsUpdateConfiguration() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = false
        configuration = .glass()
        configurationUpdateHandler = { [weak self] button in
            guard let self, var configuration = button.configuration else { return }
            configuration.title = self.title
            configuration.image = self.icon
            configuration.imagePlacement = .leading
            configuration.imagePadding = AppTheme.Spacing.small
            button.configuration = configuration
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
