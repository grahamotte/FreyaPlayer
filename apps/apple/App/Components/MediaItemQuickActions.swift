import SwiftUI
import UIKit

@MainActor
final class MediaItemQuickActionHandler {
    private weak var presenter: UIViewController?
    private let model: AppModel
    private let focusedItem: () -> MediaItem?

    private var pressTask: Task<Void, Never>?
    private var didHandleLongPress = false

    init(
        presenter: UIViewController,
        model: AppModel,
        focusedItem: @escaping () -> MediaItem?
    ) {
        self.presenter = presenter
        self.model = model
        self.focusedItem = focusedItem
    }

    func pressesBegan(_ presses: Set<UIPress>) {
        guard presses.contains(where: { $0.type == .select }), let item = focusedItem() else { return }

        didHandleLongPress = false
        pressTask?.cancel()
        pressTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(450))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self?.presentQuickActions(for: item)
            }
        }
    }

    func pressesEnded(_ presses: Set<UIPress>) -> Bool {
        guard presses.contains(where: { $0.type == .select }) else { return false }

        pressTask?.cancel()
        pressTask = nil

        if didHandleLongPress {
            didHandleLongPress = false
            return true
        }

        return false
    }

    func pressesCancelled(_ presses: Set<UIPress>) {
        guard presses.contains(where: { $0.type == .select }) else { return }

        pressTask?.cancel()
        pressTask = nil
        didHandleLongPress = false
    }

    private func presentQuickActions(for item: MediaItem) {
        guard let presenter, presenter.presentedViewController == nil else { return }

        didHandleLongPress = true

        let alert = UIAlertController(title: item.title, message: nil, preferredStyle: .alert)
        if item.playbackID != nil || item.kind == .series {
            let playAction = UIAlertAction(title: MediaItemQuickActions.playTitle(model: model, item: item), style: .default) { [model] _ in
                MediaItemQuickActions.play(item, model: model)
            }
            playAction.isEnabled = !model.isOffline
            alert.addAction(playAction)
        }
        let markSeenAction = UIAlertAction(title: MediaWatchStatusDisplay.markSeenTitle, style: .default) { [weak self] _ in
            self?.model.setWatchStatus(for: item, isWatched: true)
        }
        markSeenAction.isEnabled = !model.isOffline
        alert.addAction(markSeenAction)
        let markUnseenAction = UIAlertAction(title: MediaWatchStatusDisplay.markUnseenTitle, style: .default) { [weak self] _ in
            self?.model.setWatchStatus(for: item, isWatched: false)
        }
        markUnseenAction.isEnabled = !model.isOffline
        alert.addAction(markUnseenAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        presenter.present(alert, animated: true)
    }
}

@MainActor
enum MediaItemQuickActions {
    static func playTitle(model: AppModel, item: MediaItem) -> String {
        (model.cachedQuickPlayItem(for: item) ?? item).playButtonTitle
    }

    static func play(_ item: MediaItem, model: AppModel) {
        Task {
            guard let playable = await model.quickPlayItem(for: item) else { return }
            MediaPlaybackSession(model: model).play([playable])
        }
    }
}

extension View {
    func mediaItemQuickActions(model: AppModel, item: MediaItem) -> some View {
        modifier(MediaItemQuickActionsModifier(model: model, item: item))
    }
}

private struct MediaItemQuickActionsModifier: ViewModifier {
    @ObservedObject var model: AppModel
    let item: MediaItem

    func body(content: Content) -> some View {
        content
            .contextMenu {
                if item.playbackID != nil || item.kind == .series {
                    Button {
                        MediaItemQuickActions.play(item, model: model)
                    } label: {
                        Label(MediaItemQuickActions.playTitle(model: model, item: item), systemImage: "play.fill")
                    }
                    .disabled(model.isOffline)
                }

                Button {
                    model.setWatchStatus(for: item, isWatched: true)
                } label: {
                    Label(MediaWatchStatusDisplay.markSeenTitle, systemImage: "checkmark.circle.fill")
                }
                .disabled(model.isOffline)

                Button {
                    model.setWatchStatus(for: item, isWatched: false)
                } label: {
                    Label(MediaWatchStatusDisplay.markUnseenTitle, systemImage: "circle")
                }
                .disabled(model.isOffline)
            }
    }
}
