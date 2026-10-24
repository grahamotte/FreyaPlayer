import SwiftUI

struct BrowsingBackground: View {
    private static let colors = AmbientMeshBackground.randomColors()

    var body: some View {
        ZStack {
            AppBackground()

            AmbientMeshBackground(colors: Self.colors)

            LinearGradient(
                colors: [
                    Color.black.opacity(0.08),
                    Color.black.opacity(0.18),
                    Color.black.opacity(0.34)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            LinearGradient(
                colors: [
                    Color.black.opacity(0.16),
                    .clear,
                    Color.black.opacity(0.14)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
        .ignoresSafeArea()
    }
}
