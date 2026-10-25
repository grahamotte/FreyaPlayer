import SwiftUI
import UIKit

struct ArtworkImage: View {
    let url: URL?
    let style: MediaArtworkStyle

    @State private var image: UIImage?

    init(url: URL?, style: MediaArtworkStyle) {
        self.url = url
        self.style = style
        _image = State(initialValue: url.flatMap { ArtworkImageCache.shared.image(for: $0) })
    }

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                GeometryReader { proxy in
                    Image(systemName: style.placeholderIconName)
                        .font(.system(size: max(min(proxy.size.width, proxy.size.height) * 0.22, 12), weight: .medium))
                        .foregroundStyle(AppTheme.tertiaryText)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .task(id: url) {
            guard let url else {
                image = nil
                return
            }
            if let cached = ArtworkImageCache.shared.image(for: url) {
                image = cached
                return
            }
            image = nil
            let loaded = await ArtworkImageCache.shared.loadImage(from: url)
            guard !Task.isCancelled else { return }
            image = loaded
        }
    }
}

@MainActor
final class ArtworkImageLoader {
    static let placeholderImage = UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8)).image { context in
        AppTheme.uiSurfaceFill.setFill()
        context.fill(CGRect(origin: .zero, size: CGSize(width: 8, height: 8)))
    }

    private var task: Task<Void, Never>?
    private var currentURL: URL?
    private var isLoaded = false

    func load(_ url: URL?, apply: @escaping (UIImage?) -> Void) {
        if currentURL != url {
            reset()
            currentURL = url
            apply(nil)
        }

        guard let url else {
            apply(nil)
            return
        }
        guard !isLoaded, task == nil else { return }

        if let image = ArtworkImageCache.shared.image(for: url) {
            isLoaded = true
            apply(image)
            return
        }

        task = Task { [weak self] in
            let image = await ArtworkImageCache.shared.loadImage(from: url)
            guard let self, !Task.isCancelled, currentURL == url else { return }
            task = nil
            guard let image else { return }
            isLoaded = true
            apply(image)
        }
    }

    func reset() {
        task?.cancel()
        task = nil
        currentURL = nil
        isLoaded = false
    }
}
