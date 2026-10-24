import SwiftUI
import UIKit

struct MediaPlayButton: View {
    @ObservedObject var model: AppModel
    let item: MediaItem
    let id: MediaPlaybackID

    @StateObject private var session: MediaPlaybackSession
    @FocusState private var isPlayFocused: Bool

    @State private var isLoadingOptions = false
    @State private var playbackOptions: MediaPlaybackOptions?
    @State private var playbackFailure: PlaybackFailure?
    @State private var isShowingPlaybackDialog = false
    @State private var isHandlingLongPress = false
    @State private var draftQuality: MediaPlaybackQuality = .automatic
    @State private var draftAudioID: String?
    @State private var draftSubtitleID: String?

    init(model: AppModel, item: MediaItem, id: MediaPlaybackID) {
        self.model = model
        self.item = item
        self.id = id
        _session = StateObject(wrappedValue: MediaPlaybackSession(model: model))
    }

    var body: some View {
        Button {
            guard !isHandlingLongPress else {
                isHandlingLongPress = false
                return
            }
            playWithRememberedSettings()
        } label: {
            Label {
                Text(item.playButtonTitle)
            } icon: {
                Image(systemName: "play.fill")
                    .opacity(isLoadingOptions ? 0 : 1)
                    .overlay {
                        if isLoadingOptions {
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
            }
        }
        .buttonStyle(.glassProminent)
        .focused($isPlayFocused)
        .disabled(model.isOffline || session.isLoading || isLoadingOptions)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    isHandlingLongPress = true
                    Task {
                        await showPlaybackDialog()
                        try? await Task.sleep(for: .milliseconds(700))
                        isHandlingLongPress = false
                    }
                }
        )
        .task(id: id) {
            isPlayFocused = true
        }
        .modifier(PlaybackDialogModifier(
            isPresented: $isShowingPlaybackDialog,
            isLoading: session.isLoading,
            isOffline: model.isOffline,
            qualityOptions: qualityOptions,
            defaultResolutionTitle: defaultResolutionTitle,
            playbackOptions: playbackOptions,
            audioOptions: playbackOptions?.audioOptions ?? [],
            subtitleOptions: playbackOptions?.subtitleOptions ?? [],
            selectedAudioID: playbackOptions?.selectedAudioID,
            selectedSubtitleID: playbackOptions?.selectedSubtitleID,
            draftQuality: $draftQuality,
            draftAudioID: $draftAudioID,
            draftSubtitleID: $draftSubtitleID,
            playTitle: item.playButtonTitle,
            onClose: {
                isShowingPlaybackDialog = false
            },
            onPlay: {
                let selection = draftPlaybackSelection
                model.setPlaybackSettings(MediaPlaybackSettings(selection: selection), for: id)
                isShowingPlaybackDialog = false
                session.play([item]) { selection }
            }
        ))
        .alert(item: $playbackFailure) { failure in
            Alert(
                title: Text(failure.title),
                message: Text(failure.message),
                dismissButton: .cancel(Text("OK"))
            )
        }
    }

    private var qualityOptions: [MediaPlaybackQuality] {
        [.automatic] + (playbackOptions?.qualityOptions
            ?? MediaPlaybackQuality.transcodingOptions(forVideoHeight: nil))
    }

    private var defaultResolutionTitle: String {
        playbackOptions?.defaultResolutionTitle ?? "Automatic (Default)"
    }

    private func playWithRememberedSettings() {
        guard let settings = model.playbackSettings(for: id) else {
            session.play([item])
            return
        }

        session.play([item]) {
            let options = try await rememberedPlaybackOptions()
            return playbackSelection(for: settings, options: options)
        }
    }

    private func rememberedPlaybackOptions() async throws -> MediaPlaybackOptions? {
        if let playbackOptions {
            return playbackOptions
        }

        let options = try await model.playbackOptions(for: id)
        playbackOptions = options
        return options
    }

    private func playbackSelection(
        for settings: MediaPlaybackSettings,
        options: MediaPlaybackOptions?
    ) -> MediaPlaybackSelection {
        guard let options else {
            return MediaPlaybackSelection(
                quality: settings.quality,
                audioID: settings.audioID,
                subtitleID: settings.subtitleID
            )
        }

        let availableQualities = [.automatic] + options.qualityOptions
        return MediaPlaybackSelection(
            quality: availableQualities.contains(settings.quality) ? settings.quality : .automatic,
            audioID: restoredTrackID(
                settings.audioID,
                options: options.audioOptions,
                defaultID: options.selectedAudioID
            ),
            subtitleID: restoredTrackID(
                settings.subtitleID,
                options: options.subtitleOptions,
                defaultID: options.selectedSubtitleID
            ),
            defaultAudioID: options.selectedAudioID,
            defaultSubtitleID: options.selectedSubtitleID
        )
    }

    private func showPlaybackDialog() async {
        do {
            try await fetchPlaybackOptions()
            playbackFailure = nil
            resetDraftSelection()
            isShowingPlaybackDialog = true
        } catch {
            playbackFailure = PlaybackFailure(error, summary: "Freya couldn't load playback options.")
        }
    }

    private func fetchPlaybackOptions() async throws {
        guard !isLoadingOptions else { return }
        isLoadingOptions = true
        defer { isLoadingOptions = false }

        let options = try await model.playbackOptions(for: id)
        playbackOptions = options
        playbackFailure = nil
    }

    private func resetDraftSelection() {
        guard let settings = model.playbackSettings(for: id) else {
            draftQuality = .automatic
            draftAudioID = playbackOptions?.selectedAudioID
            draftSubtitleID = playbackOptions?.selectedSubtitleID
            return
        }

        draftQuality = qualityOptions.contains(settings.quality) ? settings.quality : .automatic
        draftAudioID = restoredTrackID(
            settings.audioID,
            options: playbackOptions?.audioOptions ?? [],
            defaultID: playbackOptions?.selectedAudioID
        )
        draftSubtitleID = restoredTrackID(
            settings.subtitleID,
            options: playbackOptions?.subtitleOptions ?? [],
            defaultID: playbackOptions?.selectedSubtitleID
        )
    }

    private func restoredTrackID(
        _ storedID: String?,
        options: [MediaPlaybackOption],
        defaultID: String?
    ) -> String? {
        guard let storedID else { return nil }
        return options.contains(where: { $0.id == storedID }) ? storedID : defaultID
    }

    private var draftPlaybackSelection: MediaPlaybackSelection {
        MediaPlaybackSelection(
            quality: draftQuality,
            audioID: draftAudioID,
            subtitleID: draftSubtitleID,
            defaultAudioID: playbackOptions?.selectedAudioID,
            defaultSubtitleID: playbackOptions?.selectedSubtitleID
        )
    }
}

private struct PlaybackDialogModifier: ViewModifier {
    @Binding var isPresented: Bool
    let isLoading: Bool
    let isOffline: Bool
    let qualityOptions: [MediaPlaybackQuality]
    let defaultResolutionTitle: String
    let playbackOptions: MediaPlaybackOptions?
    let audioOptions: [MediaPlaybackOption]
    let subtitleOptions: [MediaPlaybackOption]
    let selectedAudioID: String?
    let selectedSubtitleID: String?
    @Binding var draftQuality: MediaPlaybackQuality
    @Binding var draftAudioID: String?
    @Binding var draftSubtitleID: String?
    let playTitle: String
    let onClose: () -> Void
    let onPlay: () -> Void

    @ViewBuilder
    func body(content: Content) -> some View {
        if PlatformMetadata.isPhone {
            content
                .fullScreenCover(isPresented: $isPresented) {
                    ZStack {
                        AppTheme.modalScrim
                            .ignoresSafeArea()

                        playbackDialog
                            .background(AppTheme.backgroundTop)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous))
                            .shadow(color: AppTheme.artworkShadow, radius: 28, y: 12)
                    }
                    .presentationBackground(.clear)
                }
        } else {
            content
                .sheet(isPresented: $isPresented) {
                    playbackDialog
                }
        }
    }

    private var playbackDialog: some View {
        PlaybackOptionsDialog(
            isLoading: isLoading,
            isOffline: isOffline,
            qualityOptions: qualityOptions,
            defaultResolutionTitle: defaultResolutionTitle,
            playbackOptions: playbackOptions,
            audioOptions: audioOptions,
            subtitleOptions: subtitleOptions,
            selectedAudioID: selectedAudioID,
            selectedSubtitleID: selectedSubtitleID,
            draftQuality: $draftQuality,
            draftAudioID: $draftAudioID,
            draftSubtitleID: $draftSubtitleID,
            playTitle: playTitle,
            onClose: onClose,
            onPlay: onPlay
        )
    }
}

private struct PlaybackOptionsDialog: View {
    let isLoading: Bool
    let isOffline: Bool
    let qualityOptions: [MediaPlaybackQuality]
    let defaultResolutionTitle: String
    let playbackOptions: MediaPlaybackOptions?
    let audioOptions: [MediaPlaybackOption]
    let subtitleOptions: [MediaPlaybackOption]
    let selectedAudioID: String?
    let selectedSubtitleID: String?
    @Binding var draftQuality: MediaPlaybackQuality
    @Binding var draftAudioID: String?
    @Binding var draftSubtitleID: String?
    let playTitle: String
    let onClose: () -> Void
    let onPlay: () -> Void

    @FocusState private var isPlayFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
            Text("Play Options")
                .font(PlatformMetadata.sectionTitleFont)

            VStack(spacing: AppTheme.Spacing.small) {
                playbackMenu(title: title(for: draftQuality), systemImage: "display") {
                    ForEach(qualityOptions) { quality in
                        Button {
                            draftQuality = quality
                        } label: {
                            PlaybackOptionsMenuItem(
                                title: title(for: quality),
                                isSelected: quality == draftQuality
                            )
                        }
                    }
                }

                playbackMenu(title: audioTitle, systemImage: "speaker.wave.3.fill") {
                    ForEach(audioOptions) { option in
                        Button {
                            draftAudioID = option.id
                        } label: {
                            PlaybackOptionsMenuItem(
                                title: trackTitle(option, defaultID: selectedAudioID),
                                isSelected: option.id == draftAudioID
                            )
                        }
                    }

                    Button {
                        draftAudioID = nil
                    } label: {
                        PlaybackOptionsMenuItem(
                            title: noneTitle(defaultID: selectedAudioID),
                            isSelected: draftAudioID == nil
                        )
                    }
                }

                playbackMenu(title: subtitleTitle, systemImage: "captions.bubble") {
                    ForEach(subtitleOptions) { option in
                        Button {
                            draftSubtitleID = option.id
                        } label: {
                            PlaybackOptionsMenuItem(
                                title: trackTitle(option, defaultID: selectedSubtitleID),
                                isSelected: option.id == draftSubtitleID
                            )
                        }
                    }

                    Button {
                        draftSubtitleID = nil
                    } label: {
                        PlaybackOptionsMenuItem(
                            title: noneTitle(defaultID: selectedSubtitleID),
                            isSelected: draftSubtitleID == nil
                        )
                    }
                }
            }

            playbackPlanBlock

            VStack(spacing: AppTheme.Spacing.small) {
                Button(action: play) {
                    Group {
                        if isLoading {
                            ProgressView()
                        } else {
                            Label(playTitle, systemImage: "play.fill")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .focused($isPlayFocused)
                .disabled(isOffline || isLoading)

                Button(role: .cancel, action: cancel) {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glass)
            }
        }
        .padding(AppTheme.Spacing.xLarge)
        .foregroundStyle(AppTheme.primaryText)
        .frame(width: dialogWidth)
        .presentationSizing(.fitted)
        .task {
            isPlayFocused = true
        }
    }

    private func cancel() {
#if targetEnvironment(macCatalyst)
        dismissPresentation(completion: onClose)
#else
        onClose()
#endif
    }

    private func play() {
        dismissPresentation(completion: onPlay)
    }

    private func dismissPresentation(completion: @escaping () -> Void) {
        guard let controller = UIViewController.topPresented, controller.presentingViewController != nil else {
            completion()
            return
        }
        controller.dismiss(animated: false, completion: completion)
    }

    private var audioTitle: String {
        guard let draftAudioID,
              let option = audioOptions.first(where: { $0.id == draftAudioID }) else {
            return noneTitle(defaultID: selectedAudioID)
        }
        return trackTitle(option, defaultID: selectedAudioID)
    }

    private var subtitleTitle: String {
        guard let draftSubtitleID,
              let option = subtitleOptions.first(where: { $0.id == draftSubtitleID }) else {
            return noneTitle(defaultID: selectedSubtitleID)
        }
        return trackTitle(option, defaultID: selectedSubtitleID)
    }

    private func title(for quality: MediaPlaybackQuality) -> String {
        quality == .automatic ? defaultResolutionTitle : quality.title
    }

    private var dialogWidth: CGFloat {
#if os(tvOS)
        720
#else
        guard PlatformMetadata.isPhone else { return 640 }
        let screenWidth = UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.screen.bounds.width }
            .first ?? 390
        return min(screenWidth - (PlatformMetadata.pageGutter * 2), 640)
#endif
    }

    private var playbackPlanBlock: some View {
        Group {
            if let plan = playbackOptions?.playbackPlan(for: draftSelection) {
                Grid(
                    alignment: .leadingFirstTextBaseline,
                    horizontalSpacing: AppTheme.Spacing.xSmall,
                    verticalSpacing: AppTheme.Spacing.xSmall
                ) {
                    ForEach(plan.conversions) { conversion in
                        playbackPlanLine(conversion)
                    }
                }
            } else {
                Text("Source format information is unavailable.")
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
        .font(transcodingTextFont)
        .padding(AppTheme.Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.surfaceFill)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous))
    }

    private var draftSelection: MediaPlaybackSelection {
        MediaPlaybackSelection(
            quality: draftQuality,
            audioID: draftAudioID,
            subtitleID: draftSubtitleID,
            defaultAudioID: selectedAudioID,
            defaultSubtitleID: selectedSubtitleID
        )
    }

    private func playbackPlanLine(_ conversion: MediaPlaybackConversion) -> some View {
        GridRow {
            Text("\(conversion.element.rawValue):")
                .foregroundStyle(AppTheme.secondaryText)
            Text(conversion.description)
                .foregroundStyle(conversion.isConverted ? AppTheme.warning : AppTheme.primaryText)
        }
    }

    private var transcodingTextFont: Font {
        PlatformMetadata.isTV ? PlatformMetadata.labelFont : .callout
    }

    private func trackTitle(_ option: MediaPlaybackOption, defaultID: String?) -> String {
        option.id == defaultID ? "\(option.title) (Default)" : option.title
    }

    private func noneTitle(defaultID: String?) -> String {
        defaultID == nil ? "None (Default)" : "None"
    }

    private func playbackMenu<Content: View>(
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        Menu(content: content) {
            HStack(spacing: AppTheme.Spacing.small) {
                Label(title, systemImage: systemImage)
                    .lineLimit(1)

                Spacer(minLength: 0)

                Image(systemName: "chevron.up.chevron.down")
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .menuStyle(.button)
        .buttonStyle(.glass)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct PlaybackOptionsMenuItem: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        if isSelected {
            Label(title, systemImage: "checkmark")
        } else {
            Text(title)
        }
    }
}

