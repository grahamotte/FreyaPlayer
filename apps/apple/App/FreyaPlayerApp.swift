import SwiftUI

@main
struct FreyaPlayerApp: App {
    init() {
        PlaybackAudioSession.activate()
        #if APP_DEV && os(macOS)
        DebugHooks.install()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            AppView()
        }
        .macOSCommands()
    }
}
