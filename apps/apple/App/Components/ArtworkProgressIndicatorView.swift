import UIKit
import SwiftUI

final class ArtworkProgressIndicatorView: UIView {
    private var hostingController: UIHostingController<WatchProgressBadge>?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setProgress(_ progress: Double?, isWatched: Bool) {
        let rootView = WatchProgressBadge(progress: progress, isWatched: isWatched)
        if let hostingController {
            hostingController.rootView = rootView
            return
        }

        let controller = UIHostingController(rootView: rootView)
        controller.view.backgroundColor = .clear
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(controller.view)
        NSLayoutConstraint.activate([
            controller.view.leadingAnchor.constraint(equalTo: leadingAnchor),
            controller.view.trailingAnchor.constraint(equalTo: trailingAnchor),
            controller.view.topAnchor.constraint(equalTo: topAnchor),
            controller.view.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        hostingController = controller
    }

    func pin(inside container: UIView) {
        translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(self)
        let inset = WatchProgressBadge.inset
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: inset),
            trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -inset),
            bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -inset),
            heightAnchor.constraint(equalToConstant: WatchProgressBadge.checkSize)
        ])
    }
}
