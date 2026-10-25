import AVKit
import UIKit

final class StockPlayerViewController: AVPlayerViewController, AVPlayerViewControllerDelegate {
    var playbackController: PlaybackSessionController
    private var onPictureInPictureChanged: (Bool) -> Void
    private var onDismiss: (() -> Void)?

    private var didDismiss = false
    private var isPictureInPictureActive = false
    private weak var pictureInPicturePresenter: UIViewController?

    init(
        playbackController: PlaybackSessionController,
        onPictureInPictureChanged: @escaping (Bool) -> Void,
        onDismiss: (() -> Void)? = nil
    ) {
        self.playbackController = playbackController
        self.onPictureInPictureChanged = onPictureInPictureChanged
        self.onDismiss = onDismiss
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
        bindPlayerChanges()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        delegate = self
        player = playbackController.player
#if os(iOS)
        allowsPictureInPicturePlayback = true
#endif
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        pictureInPicturePresenter = presentingViewController ?? pictureInPicturePresenter
        playbackController.play()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        guard !isPictureInPictureActive else { return }
        playbackController.pause()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        guard !isPictureInPictureActive else { return }
        finishDismissalIfNeeded()
    }

    func configure(
        to playbackController: PlaybackSessionController,
        onPictureInPictureChanged: @escaping (Bool) -> Void
    ) {
        self.onPictureInPictureChanged = onPictureInPictureChanged

        guard self.playbackController !== playbackController else {
            bindPlayerChanges()
            playbackController.play()
            return
        }

        self.playbackController.setPlayerChangeHandler(nil)
        self.playbackController = playbackController
        bindPlayerChanges()
        player = playbackController.player
        playbackController.play()
    }

    private func bindPlayerChanges() {
        playbackController.setPlayerChangeHandler { [weak self, weak playbackController] player in
            guard let self, let playbackController,
                  self.playbackController === playbackController else { return }
            self.player = player
        }
    }

    func clearDismissHandler() {
        onDismiss = nil
    }

#if os(tvOS)
    func playerViewController(
        _ playerViewController: AVPlayerViewController,
        timeToSeekAfterUserNavigatedFrom oldTime: CMTime,
        to targetTime: CMTime
    ) -> CMTime {
        playbackController.userNavigated(to: targetTime)
        return targetTime
    }

    func playerViewController(
        _ playerViewController: AVPlayerViewController,
        willResumePlaybackAfterUserNavigatedFrom oldTime: CMTime,
        to targetTime: CMTime
    ) {
        playbackController.userWillResumeAfterNavigation()
    }
#endif

    private func finishDismissalIfNeeded() {
        guard !didDismiss else { return }
        didDismiss = true
        onDismiss?()
    }

    func playerViewControllerWillStartPictureInPicture(_ playerViewController: AVPlayerViewController) {
        isPictureInPictureActive = true
        onPictureInPictureChanged(true)
    }

    func playerViewControllerDidStopPictureInPicture(_ playerViewController: AVPlayerViewController) {
        isPictureInPictureActive = false
        onPictureInPictureChanged(false)
        if view.window == nil {
            finishDismissalIfNeeded()
        }
    }

    func playerViewController(
        _ playerViewController: AVPlayerViewController,
        restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void
    ) {
        guard view.window == nil else {
            completionHandler(true)
            return
        }

        guard let pictureInPicturePresenter, pictureInPicturePresenter.view.window != nil else {
            completionHandler(false)
            return
        }

        pictureInPicturePresenter.present(playerViewController, animated: true) {
            completionHandler(true)
        }
    }
}
