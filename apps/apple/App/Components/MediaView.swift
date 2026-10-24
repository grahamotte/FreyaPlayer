import SwiftUI

struct MediaViewData {
    let title: String
    let facts: [String]
    let remainingText: String?
    let progress: Double?
    let detailSections: [MediaItemDetailSection]
    let detailArtwork: [Artwork]
    let synopsis: String
    let artworkURL: URL?
    let artworkStyle: MediaArtworkStyle
    let backdropURL: URL?
    let playbackID: MediaPlaybackID?
    let hasResume: Bool
    let resumeOffsetMilliseconds: Int?

    struct Artwork: Identifiable {
        let label: String
        let url: URL
        let style: MediaArtworkStyle

        var id: String { "\(label):\(url.absoluteString)" }
    }
}

struct MediaView<Actions: View, Below: View>: View {
    @ObservedObject var model: AppModel
    let data: MediaViewData
    let actions: Actions
    let below: Below
    @State private var isShowingDetails = false
    @State private var detailScrollOffset: CGFloat = 0

    init(
        model: AppModel,
        data: MediaViewData,
        @ViewBuilder actions: () -> Actions,
        @ViewBuilder below: () -> Below
    ) {
        self.model = model
        self.data = data
        self.actions = actions()
        self.below = below()
    }

    var body: some View {
        GeometryReader { proxy in
            let metrics = MediaViewMetrics.current

            if usesPortraitLayout(proxy) {
                portraitLayout(proxy: proxy, metrics: metrics)
            } else {
                splitLayout(proxy: proxy, metrics: metrics)
            }
        }
        .background {
            MediaBackdropView(artworkURL: data.artworkURL, backdropURL: data.backdropURL)
        }
        .fullScreenCover(isPresented: $isShowingDetails) {
            FullItemDetailsView(
                title: data.title,
                synopsis: data.synopsis,
                sections: data.detailSections,
                artwork: data.detailArtwork,
                artworkURL: data.artworkURL,
                backdropURL: data.backdropURL
            )
                .presentationBackground(.clear)
        }
    }

    private func usesPortraitLayout(_ proxy: GeometryProxy) -> Bool {
        !PlatformMetadata.isTV && proxy.size.height > proxy.size.width
    }

    private func portraitLayout(proxy: GeometryProxy, metrics: MediaViewMetrics) -> some View {
        let metrics = metrics.balancedPanelPadding
        let availableWidth = proxy.size.width - (metrics.horizontalPadding * 2)
        let synopsisWidth = availableWidth - metrics.panelHorizontalPadding
        let fade = min(max(detailScrollOffset / 160, 0), 1)
        let fadeOpacity = Double(fade)
        let artworkSectionHeight = proxy.size.height * 0.38
        let artworkBounds = CGSize(
            width: availableWidth,
            height: max(artworkSectionHeight - metrics.topPadding, 1)
        )
        let artworkSize = data.artworkStyle.fittedSize(in: artworkBounds)

        return VStack(spacing: 0) {
            VStack {
                Spacer(minLength: metrics.topPadding)

                MediaArtworkView(url: data.artworkURL, title: data.title, style: data.artworkStyle)
                    .frame(width: artworkSize.width, height: artworkSize.height)
                    .overlay {
                        RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        .black.opacity(fadeOpacity * 0.12),
                                        .black.opacity(fadeOpacity * 0.96)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                    .opacity(1 - fadeOpacity)

                Spacer(minLength: 0)
            }
            .frame(height: artworkSectionHeight)

            detailsPanel(
                width: availableWidth,
                synopsisWidth: synopsisWidth,
                metrics: metrics,
                tracksOffset: true
            )
        }
        .padding(.horizontal, metrics.horizontalPadding)
        .padding(.bottom, metrics.bottomPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func splitLayout(proxy: GeometryProxy, metrics: MediaViewMetrics) -> some View {
        let availableWidth = proxy.size.width - (metrics.horizontalPadding * 2) - metrics.artworkSpacing
        let detailWidth = availableWidth * 0.62
        let artworkWidth = availableWidth * 0.38
        let synopsisWidth = min(detailWidth - metrics.panelHorizontalPadding, 980)
        let artworkBounds = CGSize(width: artworkWidth, height: proxy.size.height - (metrics.verticalPadding * 2))
        let artworkSize = data.artworkStyle.fittedSize(in: artworkBounds)

        return HStack(spacing: metrics.artworkSpacing) {
            detailsPanel(
                width: detailWidth,
                synopsisWidth: synopsisWidth,
                metrics: metrics,
                tracksOffset: false
            )

            VStack {
                MediaArtworkView(url: data.artworkURL, title: data.title, style: data.artworkStyle)
                    .frame(width: artworkSize.width, height: artworkSize.height)
            }
            .frame(width: artworkWidth)
        }
        .padding(.horizontal, metrics.horizontalPadding)
        .padding(.top, metrics.topPadding)
        .padding(.bottom, metrics.bottomPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func detailsPanel(
        width: CGFloat,
        synopsisWidth: CGFloat,
        metrics: MediaViewMetrics,
        tracksOffset: Bool
    ) -> some View {
        if PlatformMetadata.isTV {
            VStack(alignment: .leading, spacing: metrics.contentSpacing) {
                detailsHeader(synopsisWidth: synopsisWidth, metrics: metrics)

                ScrollView {
                    below
                        .padding(.horizontal, AppTheme.Spacing.small)
                        .padding(.top, AppTheme.Spacing.small)
                        .padding(.bottom, AppTheme.Spacing.large)
                        .frame(maxWidth: synopsisWidth, alignment: .leading)
                }
                .padding(.horizontal, -AppTheme.Spacing.small)
                .scrollIndicators(.hidden)
                .mask {
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .black, location: 0.06),
                            .init(color: .black, location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .padding(.horizontal, -AppTheme.Spacing.xLarge)
                }
            }
            .frame(maxWidth: synopsisWidth, alignment: .leading)
            .padding(.leading, metrics.panelLeadingPadding)
            .padding(.trailing, metrics.panelTrailingPadding)
            .padding(.vertical, metrics.panelVerticalPadding)
            .frame(width: width, alignment: .leading)
            .frame(maxHeight: .infinity, alignment: .topLeading)
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: metrics.contentSpacing) {
                    detailsHeader(synopsisWidth: synopsisWidth, metrics: metrics)
                    below
                }
                .frame(maxWidth: synopsisWidth, alignment: .leading)
            }
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                guard tracksOffset else { return 0 }
                return max(geometry.contentOffset.y + geometry.contentInsets.top, 0)
            } action: { _, offset in
                detailScrollOffset = offset
            }
            .padding(.leading, metrics.panelLeadingPadding)
            .padding(.trailing, metrics.panelTrailingPadding)
            .padding(.vertical, metrics.panelVerticalPadding)
            .frame(width: width, alignment: .leading)
            .frame(maxHeight: .infinity, alignment: .leading)
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize, axes: .vertical)
            .scrollClipDisabled()
        }
    }

    private func detailsHeader(synopsisWidth: CGFloat, metrics: MediaViewMetrics) -> some View {
        VStack(alignment: .leading, spacing: metrics.contentSpacing) {
            Text(data.title)
                .itemTitleFont()
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)

            if !data.facts.isEmpty {
                Text(data.facts.joined(separator: "  ·  "))
                    .font(PlatformMetadata.isTV ? .callout.weight(.medium) : .subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineLimit(1)
            }

            Button {
                isShowingDetails = true
            } label: {
                Text(data.synopsis)
                    .font(.body)
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineLimit(PlatformMetadata.isTV ? 2 : 5)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: synopsisWidth, alignment: .topLeading)
            }
            .buttonStyle(MediaDetailTextButtonStyle())
            .accessibilityHint("Shows all details")

            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                MediaItemActionRow {
                    actions

                    Button {
                        isShowingDetails = true
                    } label: {
                        Label("Details", systemImage: "info")
                    }
                    .glassIconButton()
                }

                if let remainingText = data.remainingText {
                    HStack(spacing: AppTheme.Spacing.small) {
                        ProgressView(value: min(max(data.progress ?? 0, 0), 1))
                            .tint(AppTheme.accent)
                            .frame(width: PlatformMetadata.isTV ? 180 : 96)

                        Text(remainingText)
                            .font(PlatformMetadata.labelFont.weight(.medium))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            .controlSize(.large)
        }
        .frame(maxWidth: synopsisWidth, alignment: .leading)
    }
}


struct MediaItemActionRow<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        HStack(alignment: .center, spacing: PlatformMetadata.controlSpacing) {
            content
        }
    }
}

extension MediaView where Below == EmptyView {
    init(model: AppModel, data: MediaViewData, @ViewBuilder actions: () -> Actions) {
        self.init(model: model, data: data, actions: actions) {
            EmptyView()
        }
    }
}

private struct FullScreenLayout {
    let size: CGSize

    var horizontalPadding: CGFloat {
        if PlatformMetadata.isTV {
            return min(72, max(32, size.width * 0.04))
        }

        return size.width < 600 ? AppTheme.Spacing.medium : AppTheme.Spacing.xLarge
    }

    var controlTopPadding: CGFloat {
        PlatformMetadata.isTV ? AppTheme.Spacing.xLarge : AppTheme.Spacing.medium
    }

    var contentBottomPadding: CGFloat {
        PlatformMetadata.isTV ? AppTheme.Spacing.xxLarge : AppTheme.Spacing.xLarge
    }

    func contentWidth(maximum: CGFloat) -> CGFloat {
        min(maximum, max(size.width - (horizontalPadding * 2), 1))
    }
}

private struct FullItemDetailsView: View {
    let title: String
    let synopsis: String
    let sections: [MediaItemDetailSection]
    let artwork: [MediaViewData.Artwork]
    let artworkURL: URL?
    let backdropURL: URL?
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedItemID: String?

    var body: some View {
        GeometryReader { proxy in
            let layout = FullScreenLayout(size: proxy.size)
            let contentWidth = layout.contentWidth(maximum: PlatformMetadata.isTV ? 1600 : 1040)

            ZStack {
                MediaBackdropView(artworkURL: artworkURL, backdropURL: backdropURL)

                AppTheme.scrim
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: contentSpacing) {
                        closeButton
                        header
                        descriptionSection

                        if !artwork.isEmpty {
                            artworkGallery(availableWidth: contentWidth)
                        }

                        LazyVStack(alignment: .leading, spacing: sectionSpacing) {
                            ForEach(sections) { section in
                                if !section.rows.isEmpty {
                                    detailSection(section, availableWidth: contentWidth)
                                }
                            }
                        }
                    }
                    .frame(width: contentWidth, alignment: .leading)
                    .padding(.top, layout.controlTopPadding)
                    .padding(.bottom, layout.contentBottomPadding)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .tvOSFocusSection()
                }
                .scrollIndicators(.hidden)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .tvExitCommand { dismiss() }
        .defaultFocus($focusedItemID, initialFocusID)
    }

    private var header: some View {
        Text(title)
            .itemTitleFont()
            .frame(maxWidth: 1100, alignment: .leading)
    }

    private var descriptionSection: some View {
        let focusID = "description"
        let isFocused = focusedItemID == focusID

        return VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            detailHeading("Description", caption: nil)

            Text(synopsis)
                .font(.body)
                .foregroundStyle(AppTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
                .userSelectableText()
                .padding(PlatformMetadata.isTV ? AppTheme.Spacing.large : AppTheme.Spacing.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
                .focusSurface(isFocused: isFocused, restingFill: AppTheme.subtleSurfaceFill, cornerRadius: AppTheme.Radius.inline)
                .focusable(PlatformMetadata.isTV)
                .focused($focusedItemID, equals: focusID)
        }
        .tvOSFocusSection()
    }

    private func artworkGallery(availableWidth: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            detailHeading("Artwork", caption: nil)

            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: PlatformMetadata.isTV ? AppTheme.Spacing.large : AppTheme.Spacing.medium) {
                    ForEach(artwork) { image in
                        let focusID = "artwork:\(image.id)"

                        FullItemDetailArtwork(
                            image: image,
                            isFocused: focusedItemID == focusID,
                            availableWidth: availableWidth
                        )
                            .focusable(PlatformMetadata.isTV)
                            .focused($focusedItemID, equals: focusID)
                    }
                }
                .padding(.vertical, AppTheme.Spacing.xSmall)
                .padding(.horizontal, AppTheme.Spacing.xxSmall)
            }
            .scrollIndicators(.hidden)
        }
        .tvOSFocusSection()
    }

    private func detailSection(_ section: MediaItemDetailSection, availableWidth: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: PlatformMetadata.isTV ? AppTheme.Spacing.large : AppTheme.Spacing.medium) {
            detailHeading(
                section.title,
                caption: "\(section.rows.count) \(section.rows.count == 1 ? "field" : "fields")"
            )

            LazyVGrid(
                columns: detailColumns(availableWidth: availableWidth),
                alignment: .leading,
                spacing: gridSpacing
            ) {
                ForEach(section.rows) { row in
                    let focusID = rowFocusID(section: section, row: row)

                    FullItemDetailRow(row: row, isFocused: focusedItemID == focusID)
                        .focusable(PlatformMetadata.isTV)
                        .focused($focusedItemID, equals: focusID)
                }
            }
        }
        .padding(.vertical, PlatformMetadata.isTV ? AppTheme.Spacing.large : AppTheme.Spacing.small)
        .overlay(alignment: .top) {
            Divider()
                .overlay(AppTheme.surfaceBorder)
        }
        .tvOSFocusSection()
    }

    private func detailHeading(_ title: String, caption: String?) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: AppTheme.Spacing.medium) {
                Text(title)
                    .font(PlatformMetadata.sectionTitleFont)

                Spacer(minLength: 0)

                if let caption {
                    Text(caption)
                        .font(PlatformMetadata.labelFont)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxSmall) {
                Text(title)
                    .font(PlatformMetadata.sectionTitleFont)

                if let caption {
                    Text(caption)
                        .font(PlatformMetadata.labelFont)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
        }
    }

    private func detailColumns(availableWidth: CGFloat) -> [GridItem] {
        let preferredMinimum: CGFloat = PlatformMetadata.isTV ? 360 : (PlatformMetadata.isPhone ? 220 : 280)
        let minimum = min(preferredMinimum, max(availableWidth, 1))
        return [GridItem(.adaptive(minimum: minimum), spacing: gridSpacing, alignment: .top)]
    }

    private var contentSpacing: CGFloat {
        PlatformMetadata.isTV ? AppTheme.Spacing.xxLarge : AppTheme.Spacing.xLarge
    }

    private var sectionSpacing: CGFloat {
        PlatformMetadata.pageSectionSpacing
    }

    private var gridSpacing: CGFloat {
        PlatformMetadata.isTV ? AppTheme.Spacing.medium : AppTheme.Spacing.small
    }

    private var initialFocusID: String? {
        guard PlatformMetadata.isTV else { return nil }
        return "description"
    }

    private func rowFocusID(section: MediaItemDetailSection, row: MediaItemDetailSection.Row) -> String {
        return "\(section.id):\(row.id)"
    }

    private var closeButton: some View {
        Button { dismiss() } label: {
            Label("Close", systemImage: "xmark")
        }
        .buttonStyle(.glass)
    }
}

private struct FullItemDetailArtwork: View {
    let image: MediaViewData.Artwork
    let isFocused: Bool
    let availableWidth: CGFloat

    private var height: CGFloat {
        let preferredHeight: CGFloat = PlatformMetadata.isTV ? 280 : 210
        let availableImageWidth = max(availableWidth - (AppTheme.Spacing.xSmall * 2), 1)
        return min(preferredHeight, availableImageWidth / image.style.aspectRatio)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            MediaArtworkView(url: image.url, title: image.label, style: image.style)
                .frame(width: height * image.style.aspectRatio, height: height)

            Text(image.label)
                .font(PlatformMetadata.labelFont.weight(.semibold))
                .foregroundStyle(AppTheme.secondaryText)
        }
        .padding(AppTheme.Spacing.xSmall)
        .focusSurface(isFocused: isFocused, restingFill: Color.clear, cornerRadius: AppTheme.Radius.large)
    }
}

private struct FullItemDetailRow: View {
    let row: MediaItemDetailSection.Row
    let isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
            Text(row.label)
                .font(PlatformMetadata.labelFont.weight(.semibold))
                .foregroundStyle(AppTheme.secondaryText)

            Text(row.value)
                .font(.body.monospaced())
                .foregroundStyle(AppTheme.primaryText)
                .fixedSize(horizontal: false, vertical: true)
                .userSelectableText()
        }
        .frame(maxWidth: .infinity, minHeight: PlatformMetadata.isTV ? 86 : 72, alignment: .topLeading)
        .padding(PlatformMetadata.isTV ? AppTheme.Spacing.large : AppTheme.Spacing.medium)
        .focusSurface(isFocused: isFocused, restingFill: AppTheme.subtleSurfaceFill, cornerRadius: AppTheme.Radius.inline)
    }
}

private struct MediaViewMetrics {
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat
    let artworkSpacing: CGFloat
    let panelLeadingPadding: CGFloat
    let panelTrailingPadding: CGFloat
    let panelVerticalPadding: CGFloat
    let contentSpacing: CGFloat
    let headerOffset: CGFloat

    var panelHorizontalPadding: CGFloat {
        panelLeadingPadding + panelTrailingPadding
    }

    var topPadding: CGFloat {
        verticalPadding - headerOffset
    }

    var bottomPadding: CGFloat {
        verticalPadding + headerOffset
    }

    var balancedPanelPadding: MediaViewMetrics {
        MediaViewMetrics(
            horizontalPadding: horizontalPadding,
            verticalPadding: verticalPadding,
            artworkSpacing: artworkSpacing,
            panelLeadingPadding: 0,
            panelTrailingPadding: 0,
            panelVerticalPadding: panelVerticalPadding,
            contentSpacing: contentSpacing,
            headerOffset: headerOffset
        )
    }

    static let current: MediaViewMetrics = {
        if PlatformMetadata.isTV {
            return MediaViewMetrics(
                horizontalPadding: 72,
                verticalPadding: 48,
                artworkSpacing: 72,
                panelLeadingPadding: 36,
                panelTrailingPadding: 36,
                panelVerticalPadding: 24,
                contentSpacing: 24,
                headerOffset: 0
            )
        }
        if PlatformMetadata.isMac {
            return MediaViewMetrics(
                horizontalPadding: 32,
                verticalPadding: 32,
                artworkSpacing: 32,
                panelLeadingPadding: 0,
                panelTrailingPadding: 40,
                panelVerticalPadding: 16,
                contentSpacing: 24,
                headerOffset: 18
            )
        }
        if PlatformMetadata.isPhone {
            return MediaViewMetrics(
                horizontalPadding: PlatformMetadata.pageGutter,
                verticalPadding: AppTheme.Spacing.medium,
                artworkSpacing: AppTheme.Spacing.large,
                panelLeadingPadding: 0,
                panelTrailingPadding: 0,
                panelVerticalPadding: 12,
                contentSpacing: 16,
                headerOffset: 0
            )
        }
        return MediaViewMetrics(
            horizontalPadding: 32,
            verticalPadding: 32,
            artworkSpacing: 32,
            panelLeadingPadding: 0,
            panelTrailingPadding: 40,
            panelVerticalPadding: 16,
            contentSpacing: 24,
            headerOffset: 0
        )
    }()
}

private struct MediaDetailTextButtonStyle: ButtonStyle {
    @Environment(\.isFocused) private var isFocused

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, AppTheme.Spacing.xSmall)
            .padding(.horizontal, AppTheme.Spacing.medium)
            .focusSurface(isFocused: isFocused, restingFill: Color.clear, cornerRadius: AppTheme.Radius.inline)
            .scaleEffect(configuration.isPressed ? AppTheme.pressedScale : 1)
            .padding(.horizontal, -AppTheme.Spacing.medium)
    }
}

private extension View {
    func tvExitCommand(_ action: @escaping () -> Void) -> some View {
        #if os(tvOS)
        return onExitCommand(perform: action)
        #else
        return self
        #endif
    }
}

private struct MediaBackdropView: View {
    let artworkURL: URL?
    let backdropURL: URL?

    var body: some View {
        ZStack {
            ArtworkLitBackground(url: artworkURL ?? backdropURL)

            AsyncImage(url: backdropURL) { phase in
                if case .success(let image) = phase {
                    image
                        .resizable()
                        .scaledToFill()
                        .blur(radius: 40)
                        .opacity(0.22)
                }
            }
            .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color.black.opacity(0.55),
                    Color.black.opacity(0.1),
                    .clear
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .ignoresSafeArea()
        }
        .accessibilityHidden(true)
    }
}

private struct MediaArtworkView: View {
    let url: URL?
    let title: String
    let style: MediaArtworkStyle
    private let shape = RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)

    var body: some View {
        shape
            .fill(AppTheme.surfaceFill)
            .overlay {
                ArtworkImage(url: url, style: style)
            }
            .aspectRatio(style.aspectRatio, contentMode: .fit)
            .clipShape(shape)
            .overlay {
                shape.strokeBorder(AppTheme.hairline, lineWidth: 1)
            }
            .shadow(color: AppTheme.artworkShadow, radius: 32, y: 20)
            .accessibilityLabel(title)
    }
}
