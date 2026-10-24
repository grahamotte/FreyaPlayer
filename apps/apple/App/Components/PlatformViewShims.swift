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

    func pageTitleFont() -> some View {
        modifier(ScaledTitleFont(size: PlatformMetadata.pageTitleSize, relativeTo: .largeTitle))
    }

    func itemTitleFont() -> some View {
        modifier(ScaledTitleFont(size: PlatformMetadata.itemTitleSize, relativeTo: .title))
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
