import Combine
import SwiftUI
import UIKit

struct AmbientPalette: Equatable {
    let id: String
    let colors: [Color]

    nonisolated static let neutral = AmbientPalette(
        id: "neutral",
        colors: [
            Color(red: 0.16, green: 0.2, blue: 0.3),
            Color(red: 0.1, green: 0.13, blue: 0.22),
            Color(red: 0.22, green: 0.2, blue: 0.3),
            Color(red: 0.12, green: 0.16, blue: 0.2)
        ]
    )

    nonisolated static let brand = AmbientPalette(
        id: "brand",
        colors: [
            Color(red: 0.55, green: 0.38, blue: 0.08),
            Color(red: 0.2, green: 0.14, blue: 0.08),
            Color(red: 0.36, green: 0.24, blue: 0.06),
            Color(red: 0.12, green: 0.1, blue: 0.12)
        ]
    )

    @MainActor private static var cache: [URL: AmbientPalette] = [:]

    @MainActor
    static func cached(for url: URL) -> AmbientPalette? {
        cache[url]
    }

    @MainActor
    static func load(for url: URL) async -> AmbientPalette? {
        if let cached = cache[url] {
            return cached
        }
        guard let image = await ArtworkImageCache.shared.loadImage(from: url) else { return nil }
        let colors = ArtworkPalette.colors(from: image)
        guard !colors.isEmpty else { return nil }
        let palette = AmbientPalette(id: url.absoluteString, colors: colors)
        cache[url] = palette
        return palette
    }
}

@MainActor
final class AmbientLight: ObservableObject {
    @Published private(set) var palette: AmbientPalette
    @Published private(set) var fromColors: [Color]?
    @Published private(set) var transitionStart: Date = .distantPast

    private var url: URL?
    private var task: Task<Void, Never>?

    init(palette: AmbientPalette = .neutral) {
        self.palette = palette
    }

    func light(_ url: URL?) {
        guard url != self.url else { return }
        self.url = url
        task?.cancel()
        guard let url else { return }

        if let cached = AmbientPalette.cached(for: url) {
            show(cached)
            return
        }

        task = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled, let palette = await AmbientPalette.load(for: url), !Task.isCancelled else { return }
            self?.show(palette)
        }
    }

    private func show(_ palette: AmbientPalette) {
        guard palette != self.palette else { return }
        let now = Date()
        if UIAccessibility.isReduceMotionEnabled {
            fromColors = nil
        } else {
            fromColors = AmbientMeshBackground.blendedColors(
                from: fromColors,
                to: self.palette.colors,
                progress: AmbientMeshBackground.transitionProgress(since: transitionStart, at: now)
            )
        }
        transitionStart = now
        self.palette = palette
    }
}

struct AmbientBackdrop: View {
    @ObservedObject var light: AmbientLight

    var body: some View {
        ZStack {
            AppBackground()

            AmbientMeshBackground(
                colors: light.palette.colors,
                fromColors: light.fromColors,
                transitionStart: light.transitionStart,
                saturation: 1.05,
                opacity: 0.8
            )

            LinearGradient(
                colors: [
                    .clear,
                    Color.black.opacity(0.18),
                    Color.black.opacity(0.5)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            LinearGradient(
                colors: [
                    Color.black.opacity(0.22),
                    .clear
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

struct ArtworkLitBackground: View {
    let url: URL?
    var fallback: AmbientPalette = .neutral

    @StateObject private var light: AmbientLight

    init(url: URL?, fallback: AmbientPalette = .neutral) {
        self.url = url
        self.fallback = fallback
        _light = StateObject(wrappedValue: AmbientLight(palette: url.flatMap { AmbientPalette.cached(for: $0) } ?? fallback))
    }

    var body: some View {
        AmbientBackdrop(light: light)
            .task(id: url) {
                light.light(url)
            }
    }
}
