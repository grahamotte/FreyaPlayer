import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

enum AppTheme {
    static let backgroundTop = Color(red: 0.08, green: 0.09, blue: 0.12)
    static let backgroundBottom = Color(red: 0.04, green: 0.05, blue: 0.07)

    static let accent = Color(red: 0.89, green: 0.686, blue: 0.196)
    static let onAccent = Color.black

    static let primaryText = Color.white
    static let secondaryText = Color.white.opacity(0.72)
    static let tertiaryText = Color.white.opacity(0.5)
    static let hairline = Color.white.opacity(0.1)

    static let surfaceFill = Color.white.opacity(0.08)
    static let surfaceBorder = Color.white.opacity(0.12)
    static let subtleSurfaceFill = Color.white.opacity(0.05)
    static let focusedSurfaceFill = Color.white.opacity(0.16)

    static let scrim = Color.black.opacity(0.4)
    static let modalScrim = Color.black.opacity(0.5)
    static let artworkShadow = Color.black.opacity(0.35)

    static let pressedScale = 0.98
    static let focusedCardScale = 1.02
    static let focusAnimation = Animation.easeOut(duration: 0.16)

#if canImport(UIKit)
    static let uiAccent = UIColor(red: 0.89, green: 0.686, blue: 0.196, alpha: 1)
    static let uiPrimaryText = UIColor.white
    static let uiSecondaryText = UIColor.white.withAlphaComponent(0.72)
    static let uiSurfaceFill = UIColor.white.withAlphaComponent(0.08)
    static let uiHairline = UIColor.white.withAlphaComponent(0.1)
#endif
    static let warning = Color.orange
    static let positive = Color.green
    static let destructive = Color.red

    enum Radius {
        static let inline: CGFloat = 16
        static let card: CGFloat = 20
        static let large: CGFloat = 28

        static var artwork: CGFloat {
            PlatformMetadata.isTV ? 24 : 18
        }
    }

    enum Spacing {
        static let xxSmall: CGFloat = 4
        static let xSmall: CGFloat = 8
        static let small: CGFloat = 12
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let xLarge: CGFloat = 32
        static let xxLarge: CGFloat = 48
    }
}

private struct AppChromeModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .preferredColorScheme(.dark)
    }
}

private struct FocusSurfaceModifier<Background: ShapeStyle>: ViewModifier {
    let isFocused: Bool
    let restingFill: Background
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(isFocused ? AnyShapeStyle(AppTheme.focusedSurfaceFill) : AnyShapeStyle(restingFill))
            }
            .scaleEffect(isFocused && PlatformMetadata.isTV ? AppTheme.focusedCardScale : 1)
            .animation(AppTheme.focusAnimation, value: isFocused)
    }
}

struct MediaSurfaceButtonStyle<Background: ShapeStyle>: ButtonStyle {
    let restingFill: Background
    var cornerRadius: CGFloat = AppTheme.Radius.card

    func makeBody(configuration: Configuration) -> some View {
        MediaSurfaceButtonBody(configuration: configuration, restingFill: restingFill, cornerRadius: cornerRadius)
    }
}

private struct MediaSurfaceButtonBody<Background: ShapeStyle>: View {
    let configuration: ButtonStyle.Configuration
    let restingFill: Background
    let cornerRadius: CGFloat
    @Environment(\.isFocused) private var isFocused

    var body: some View {
        configuration.label
            .foregroundStyle(AppTheme.primaryText)
            .focusSurface(isFocused: isFocused, restingFill: restingFill, cornerRadius: cornerRadius)
            .scaleEffect(configuration.isPressed ? AppTheme.pressedScale : 1)
    }
}

extension View {
    func appChrome() -> some View {
        modifier(AppChromeModifier())
    }

    func focusSurface<Background: ShapeStyle>(
        isFocused: Bool,
        restingFill: Background,
        cornerRadius: CGFloat = AppTheme.Radius.card
    ) -> some View {
        modifier(FocusSurfaceModifier(isFocused: isFocused, restingFill: restingFill, cornerRadius: cornerRadius))
    }
}
