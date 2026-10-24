import AVKit
import Combine
import SwiftUI
import UIKit

@MainActor
final class MediaPlaybackSession: ObservableObject {
    @Published private(set) var isLoading = false

    private let model: AppModel
    private var queue = PlaybackQueue([])
    private var selection: MediaPlaybackSelection?
    private var controller: PlaybackSessionController?
    private var playerViewController: StockPlayerViewController?
    private var sessionID = UUID().uuidString
    private var remoteSession: RemoteSession?
    private var preparedNext: PreparedItem?
    private var pendingOffset: Int?
    private var lastKnownTime = 0
    private var hasLoadedCurrent = false
    private var didFinishCurrent = false
    private var didRetryCurrent = false
    private var loadTask: Task<Void, Never>?
    private var seekTask: Task<Void, Never>?
    private var recoveryTask: Task<Void, Never>?
    private var prepareTask: Task<Void, Never>?

    init(model: AppModel) {
        self.model = model
    }

    func play(
        _ items: [MediaItem],
        shuffled: Bool = false,
        selection resolveSelection: (() async throws -> MediaPlaybackSelection?)? = nil
    ) {
        stop()
        queue = PlaybackQueue(items, shuffled: shuffled)
        guard queue.current != nil else { return }

        let controller = PlaybackSessionController()
        self.controller = controller
        guard present(controller) else {
            stop()
            return
        }

        isLoading = true
        loadTask = Task { [weak self] in
            guard let self else { return }
            do {
                selection = try await resolveSelection?()
            } catch {
                guard !Task.isCancelled, self.controller === controller else { return }
                fail(PlaybackFailure(error))
                return
            }
            await loadCurrent()
        }
    }

    func stop() {
        cancelTasks()

        if let controller, hasLoadedCurrent, !didFinishCurrent, let id = queue.current?.playbackID {
            model.reportPlaybackTimeline(
                for: id,
                state: .stopped,
                time: max(controller.currentTimeMilliseconds, pendingOffset ?? lastKnownTime),
                duration: controller.durationMilliseconds,
                sessionID: sessionID
            )
        }

        controller?.stop()
        controller = nil
        stopRemoteSession()
        discardPreparedNext()
        playerViewController?.clearDismissHandler()
        playerViewController = nil
        pendingOffset = nil
        hasLoadedCurrent = false
        didFinishCurrent = false
        didRetryCurrent = false
        isLoading = false
    }

    private func loadCurrent(
        autoplay: Bool = true,
        failureSummary: String = "Freya couldn't start this item."
    ) async {
        guard let controller, let item = queue.current, let id = item.playbackID else { return }
        let index = queue.index

        isLoading = true
        defer { isLoading = false }

        do {
            let nextSessionID = UUID().uuidString
            let resource = try await model.playbackURL(
                for: id,
                selection: selection,
                sessionID: nextSessionID,
                offsetMilliseconds: pendingOffset ?? item.resumeOffsetMilliseconds
            )
            guard !Task.isCancelled, self.controller === controller, queue.index == index else {
                model.stopPlaybackSession(for: id, sessionID: resource.remoteSessionID)
                return
            }
            sessionID = nextSessionID
            load(resource, item: item, into: controller, autoplay: autoplay)
            schedulePrepareNext()
        } catch {
            guard !Task.isCancelled, self.controller === controller, queue.index == index else { return }
            if queue.hasNext {
                advance()
            } else {
                fail(PlaybackFailure(error, summary: failureSummary))
            }
        }
    }

    private func load(
        _ resource: MediaPlaybackResource,
        item: MediaItem,
        into controller: PlaybackSessionController,
        autoplay: Bool = true
    ) {
        guard let id = item.playbackID else { return }

        if remoteSession?.sessionID != resource.remoteSessionID {
            stopRemoteSession()
        }
        remoteSession = resource.remoteSessionID.map { RemoteSession(id: id, sessionID: $0) }
        lastKnownTime = pendingOffset ?? item.resumeOffsetMilliseconds ?? 0
        hasLoadedCurrent = true
        didFinishCurrent = false

        controller.load(
            item: MediaPlayerItemFactory.item(resource: resource, mediaItem: item),
            startOffsetMilliseconds: resource.localStartOffsetMilliseconds,
            timelineOffsetMilliseconds: resource.timelineStartOffsetMilliseconds,
            enableSubtitles: selection?.subtitleID != nil,
            autoplay: autoplay,
            onTimelineEvent: { [weak self] state, time, duration in
                self?.reportTimeline(state: state, time: time, duration: duration)
            },
            onPlaybackEnded: { [weak self] time, duration in
                self?.playbackEnded(time: time, duration: duration)
            },
            onRecoveryNeeded: { [weak self] savedTime, error in
                self?.recover(savedTime: savedTime, error: error)
            },
            onNavigationNeeded: resource.reloadsForSeek
                ? { [weak self] offset in self?.reload(at: offset) }
                : nil
        )
    }

    private func reportTimeline(state: MediaPlaybackTimelineState, time: Int, duration: Int?) {
        guard let id = queue.current?.playbackID else { return }
        if state == .playing {
            pendingOffset = nil
            didRetryCurrent = false
        }
        lastKnownTime = time
        model.reportPlaybackTimeline(for: id, state: state, time: time, duration: duration, sessionID: sessionID)
    }

    private func playbackEnded(time: Int, duration: Int?) {
        guard let id = queue.current?.playbackID else { return }

        didFinishCurrent = true
        model.reportPlaybackTimeline(for: id, state: .stopped, time: time, duration: duration, sessionID: sessionID)
        model.markPlaybackCompleted(for: id, sessionID: sessionID)

        if queue.hasNext {
            advance()
        } else {
            dismissPlayer()
        }
    }

    private func advance() {
        queue.advance()
        pendingOffset = nil
        didRetryCurrent = false
        hasLoadedCurrent = false

        guard let item = queue.current, let controller else {
            dismissPlayer()
            return
        }

        if let preparedNext, preparedNext.index == queue.index {
            self.preparedNext = nil
            sessionID = preparedNext.sessionID
            load(preparedNext.resource, item: item, into: controller)
            schedulePrepareNext()
        } else {
            discardPreparedNext()
            loadTask?.cancel()
            loadTask = Task { [weak self] in await self?.loadCurrent() }
        }
    }

    private func recover(savedTime: Int, error: Error?) {
        guard let controller, let item = queue.current else { return }

        guard !didRetryCurrent else {
            if queue.hasNext {
                advance()
            } else {
                fail(error.map {
                    PlaybackFailure($0, summary: "Playback failed after Freya restarted the stream.")
                } ?? PlaybackFailure(
                    summary: "Playback stopped responding.",
                    details: "The player failed again after Freya restarted the stream."
                ))
            }
            return
        }

        didRetryCurrent = true
        pendingOffset = PlaybackQueue.recoveryOffset(
            savedTime: savedTime,
            currentTime: controller.currentTimeMilliseconds,
            fallback: pendingOffset ?? item.resumeOffsetMilliseconds
        )
        stopRemoteSession()
        let autoplay = controller.prepareForRecovery()
        recoveryTask?.cancel()
        recoveryTask = Task { [weak self] in
            await self?.loadCurrent(autoplay: autoplay, failureSummary: "Freya couldn't restart playback.")
        }
    }

    private func reload(at offset: Int) {
        pendingOffset = offset
        seekTask?.cancel()
        seekTask = Task { [weak self] in
            await self?.loadCurrent(failureSummary: "Freya couldn't seek to that position.")
        }
    }

    private func schedulePrepareNext() {
        prepareTask?.cancel()
        let index = queue.index
        guard queue.hasNext else { return }

        prepareTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(10))
            guard !Task.isCancelled else { return }
            await self?.prepareNext(after: index)
        }
    }

    private func prepareNext(after index: Int) async {
        guard queue.index == index, let next = queue.next, let id = next.playbackID else { return }

        do {
            let nextSessionID = UUID().uuidString
            let resource = try await model.playbackURL(for: id, sessionID: nextSessionID)
            guard !Task.isCancelled, controller != nil, queue.index == index else {
                model.stopPlaybackSession(for: id, sessionID: resource.remoteSessionID)
                return
            }
            discardPreparedNext()
            preparedNext = PreparedItem(index: index + 1, id: id, resource: resource, sessionID: nextSessionID)
        } catch {
            preparedNext = nil
        }
    }

    private func present(_ controller: PlaybackSessionController) -> Bool {
        guard let presenter = UIViewController.topPresented else { return false }

        let playerViewController = StockPlayerViewController(
            playbackController: controller,
            onPictureInPictureChanged: { _ in },
            onDismiss: { self.stop() }
        )
        self.playerViewController = playerViewController
        presenter.present(playerViewController, animated: true)
        return true
    }

    private func dismissPlayer() {
        guard let playerViewController, playerViewController.presentingViewController != nil else {
            stop()
            return
        }
        playerViewController.dismiss(animated: true)
    }

    private func fail(_ failure: PlaybackFailure) {
        let playerViewController = playerViewController
        stop()

        guard let playerViewController, playerViewController.presentingViewController != nil else {
            Self.present(failure)
            return
        }
        playerViewController.dismiss(animated: true) {
            Self.present(failure)
        }
    }

    private func stopRemoteSession() {
        guard let remoteSession else { return }
        model.stopPlaybackSession(for: remoteSession.id, sessionID: remoteSession.sessionID)
        self.remoteSession = nil
    }

    private func discardPreparedNext() {
        guard let preparedNext else { return }
        model.stopPlaybackSession(for: preparedNext.id, sessionID: preparedNext.resource.remoteSessionID)
        self.preparedNext = nil
    }

    private func cancelTasks() {
        loadTask?.cancel()
        seekTask?.cancel()
        recoveryTask?.cancel()
        prepareTask?.cancel()
        loadTask = nil
        seekTask = nil
        recoveryTask = nil
        prepareTask = nil
    }

    static func present(_ failure: PlaybackFailure) {
        guard let presenter = UIViewController.topPresented else { return }
        let alert = UIAlertController(title: failure.title, message: failure.message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        presenter.present(alert, animated: true)
    }

    private struct RemoteSession {
        let id: MediaPlaybackID
        let sessionID: String
    }

    private struct PreparedItem {
        let index: Int
        let id: MediaPlaybackID
        let resource: MediaPlaybackResource
        let sessionID: String
    }
}

extension UIViewController {
    static var topPresented: UIViewController? {
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
        var controller = window?.rootViewController
        while let presented = controller?.presentedViewController {
            controller = presented
        }
        return controller
    }
}
