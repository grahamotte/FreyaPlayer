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

    func readableFormWidth() -> some View {
        frame(maxWidth: PlatformMetadata.readableFormWidth)
            .frame(maxWidth: .infinity)
    }
}

extension Scene {
    func macOSCommands() -> some Scene {
        PlatformMetadata.macCommandsModifier(self)
    }
}
