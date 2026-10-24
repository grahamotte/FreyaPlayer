import SwiftUI

struct AboutPage: View {
    private let repositoryURL = URL(string: "https://github.com/grahamotte/FreyaPlayer")!

    var body: some View {
        Form {
            Section {
                Text("A small, native player for Jellyfin and Plex, built to feel like it came with the device.")
                    .tvOSFocusableRow()
            }

            section(
                title: "Free Forever",
                body: "Freya Player is free. No subscriptions, no upsell, no plus premium max whatever. Oh also, no ads."
            )

            section(
                title: "Private by Default",
                body: "Your data lives only on this device, so the app can talk to your server. There's no analytics or telemetry, not even a crash reporter."
            )

            section(
                title: "Open Source",
                body: "Read it, fork it, send a pull request."
            )

            Section("Bugs?") {
                Text("Open an issue!")
                    .foregroundStyle(AppTheme.secondaryText)
                repositoryLink
            }

            Section {
                LabeledContent("Version", value: appVersion)
                    .tvOSFocusableRow()
            }
        }
        .readableFormWidth()
        .navigationTitle("About Freya Player")
    }

    @ViewBuilder
    private var repositoryLink: some View {
        #if os(tvOS)
        Text(repositoryURL.absoluteString)
            .font(.body.monospaced())
            .tvOSFocusableRow()
        #else
        Link(repositoryURL.absoluteString, destination: repositoryURL)
            .font(.body.monospaced())
        #endif
    }

    private func section(title: String, body: String) -> some View {
        Section(title) {
            Text(body)
                .foregroundStyle(AppTheme.secondaryText)
                .tvOSFocusableRow()
        }
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }
}
