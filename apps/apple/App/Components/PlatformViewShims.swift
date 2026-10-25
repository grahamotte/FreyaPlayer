import SwiftUI

extension Notification.Name {
    static let navigateToAbout = Notification.Name("com.grahamotte.freyaplayer.navigateToAbout")
}

extension View {
    func userSelectableText() -> some View {
        PlatformMetadata.textSelectionModifier(self)
    }

    func tvOSFocusSection() -> some View {
        PlatformMetadata.focusSectionModifier(self)
    }

    func tvOSFocusableRow() -> some View {
        PlatformMetadata.focusableRowModifier(self)
    }

    func itemTitleFont() -> some View {
        modifier(ScaledTitleFont(size: PlatformMetadata.itemTitleSize, relativeTo: .title))
    }

    func macWindowChrome() -> some View {
        PlatformMetadata.macWindowModifier(self)
    }

    func readableFormWidth() -> some View {
        frame(maxWidth: PlatformMetadata.readableFormWidth)
            .frame(maxWidth: .infinity)
    }
}

private struct ScaledTitleFont: ViewModifier {
    @ScaledMetric private var size: CGFloat

    init(size: CGFloat, relativeTo textStyle: Font.TextStyle) {
        _size = ScaledMetric(wrappedValue: size, relativeTo: textStyle)
    }

    func body(content: Content) -> some View {
        content.font(.system(size: size, weight: .bold))
    }
}

extension Scene {
    func macOSCommands() -> some Scene {
        PlatformMetadata.macCommandsModifier(self)
    }
}

extension View {
    func glassIconButton() -> some View {
        labelStyle(GlassIconLabelStyle())
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
    }
}

private struct PlayActionStyle: ViewModifier {
    let isProminent: Bool

    func body(content: Content) -> some View {
        if isProminent {
            content
                .buttonStyle(.glassProminent)
                .tint(AppTheme.accent)
        } else {
            content
                .buttonStyle(.glass)
        }
    }
}

extension View {
    func playActionStyle(isProminent: Bool = true) -> some View {
        modifier(PlayActionStyle(isProminent: isProminent))
    }
}

extension View {
    @ViewBuilder
    func formBackdrop(_ palette: AmbientPalette = .neutral) -> some View {
        #if os(tvOS)
        background(ArtworkLitBackground(url: nil, fallback: palette))
        #else
        scrollContentBackground(.hidden)
            .background(ArtworkLitBackground(url: nil, fallback: palette))
        #endif
    }
}

private struct GlassIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        IconOnlyLabelStyle().makeBody(configuration: configuration)
            .font(PlatformMetadata.isTV ? .title3.weight(.semibold) : .body.weight(.semibold))
            .frame(width: PlatformMetadata.controlContentSide, height: PlatformMetadata.controlContentSide)
    }
}

struct GlassPillLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        TitleAndIconLabelStyle().makeBody(configuration: configuration)
            .frame(minHeight: PlatformMetadata.controlContentSide)
    }
}

extension View {
    func glassPillLabel() -> some View {
        labelStyle(GlassPillLabelStyle())
    }
}

extension View {
    @ViewBuilder
    func largeNavigationTitle(subtitle: String? = nil) -> some View {
        #if os(tvOS)
        self
        #elseif targetEnvironment(macCatalyst)
        navigationBarTitleDisplayMode(.inline)
            .navigationSubtitle(subtitle ?? "")
        #else
        navigationBarTitleDisplayMode(.large)
            .navigationSubtitle(subtitle ?? "")
        #endif
    }
}
