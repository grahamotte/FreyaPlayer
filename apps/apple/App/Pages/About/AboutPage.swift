import SwiftUI

struct AboutPage: View {
    private let repositoryURL = URL(string: "https://github.com/grahamotte/FreyaPlayer")!

    var body: some View {
        Form {
            Section {
                VStack(spacing: AppTheme.Spacing.small) {
                    Image("FreyaLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: PlatformMetadata.isTV ? 160 : 96, height: PlatformMetadata.isTV ? 160 : 96)
                        .accessibilityHidden(true)

                    Text("Freya Player")
                        .font(.title2.weight(.bold))

                    Text("A small, native player for Jellyfin and Plex, built to feel like it came with the device.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText)
                        .multilineTextAlignment(.center)

                    Text("Version \(appVersion)")
                        .font(PlatformMetadata.labelFont)
                        .foregroundStyle(AppTheme.tertiaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.Spacing.small)
                .listRowBackground(Color.clear)
                .tvOSFocusableRow()
            }

            Section {
                point("Free Forever", "No subscriptions, no upsell, no plus premium max whatever. Oh also, no ads.")
                point("Private by Default", "Your data lives only on this device, so the app can talk to your server. There's no analytics or telemetry, not even a crash reporter.")
                point("Open Source", "Read it, fork it, send a pull request.")
            }

            Section {
                repositoryLink
            } header: {
                Text("Bugs?")
            } footer: {
                Text("Open an issue on GitHub.")
            }
        }
        .readableFormWidth()
        .formBackdrop(.brand)
        .tint(AppTheme.primaryText)
        .navigationTitle("About")
        .aboutTitleDisplayMode()
    }

    @ViewBuilder
    private var repositoryLink: some View {
        #if os(tvOS)
        LabeledContent("GitHub", value: "grahamotte/FreyaPlayer")
            .tvOSFocusableRow()
        #else
        Link(destination: repositoryURL) {
            LabeledContent("GitHub", value: "grahamotte/FreyaPlayer")
        }
        #endif
    }

    private func point(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xxSmall) {
            Text(title)
                .font(.body.weight(.semibold))
            Text(body)
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryText)
        }
        .padding(.vertical, AppTheme.Spacing.xxSmall)
        .tvOSFocusableRow()
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }
}

private extension View {
    @ViewBuilder
    func aboutTitleDisplayMode() -> some View {
        #if os(tvOS)
        self
        #else
        navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
