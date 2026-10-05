import SwiftUI

struct AboutPage: View {
    var body: some View {
        VStack(spacing: AppTheme.Spacing.xLarge) {
            Spacer()

            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                Label("About Freya Player", systemImage: "info.circle")
                    .font(PlatformMetadata.sectionTitleFont)

                Text("A small, native player for Jellyfin and Plex, built to feel like it came with the device.")
                    .foregroundStyle(AppTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)

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

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
                    sectionTitle("Bugs?")
                    Text("Open an issue!")
                        .foregroundStyle(AppTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("https://github.com/grahamotte/FreyaPlayer")
                        .font(.body.monospaced())
                        .foregroundStyle(AppTheme.primaryText)
                        .userSelectableText()
                }

                Text("Version \(appVersion)")
                    .font(PlatformMetadata.labelFont)
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .frame(maxWidth: PlatformMetadata.isTV ? 1200 : 720, alignment: .leading)
            .padding(PlatformMetadata.panelPadding)
            .background(PanelBackground())

            Spacer()
        }
        .padding(PlatformMetadata.pageGutter)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppBackground())
        .navigationTitle("About")
    }

    private func section(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
            sectionTitle(title)
            Text(body)
                .foregroundStyle(AppTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(AppTheme.primaryText)
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }
}
