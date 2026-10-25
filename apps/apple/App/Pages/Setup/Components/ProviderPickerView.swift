import SwiftUI

struct ProviderPickerView: View {
    var body: some View {
        VStack(spacing: AppTheme.Spacing.xxLarge) {
            VStack(spacing: AppTheme.Spacing.large) {
                Image("FreyaLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: logoSize, height: logoSize)
                    .accessibilityHidden(true)

                VStack(spacing: AppTheme.Spacing.xSmall) {
                    Text("Freya Player")
                        .font(.largeTitle.weight(.bold))

                    Text("Connect your server to start watching.")
                        .font(PlatformMetadata.isTV ? .title3 : .body)
                        .foregroundStyle(AppTheme.secondaryText)
                        .multilineTextAlignment(.center)
                }
            }

            if PlatformMetadata.isPhone {
                VStack(spacing: AppTheme.Spacing.medium) {
                    serviceButtons
                }
            } else {
                HStack(spacing: AppTheme.Spacing.xLarge) {
                    serviceButtons
                }
            }

            NavigationLink(value: AppRoute.about) {
                Label("About", systemImage: "info.circle")
            }
            .buttonStyle(.glass)
        }
        .padding(PlatformMetadata.pageGutter)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ArtworkLitBackground(url: nil, fallback: .brand))
    }

    private var logoSize: CGFloat {
        if PlatformMetadata.isTV { return 240 }
        return PlatformMetadata.isPhone ? 150 : 200
    }

    private var serviceButtons: some View {
        Group {
            NavigationLink(value: AppRoute.jellyfinSetup) {
                MediaProviderLabel(providerID: .jellyfin, logoSize: serviceLogoSize)
                    .font(PlatformMetadata.sectionTitleFont)
                    .frame(width: serviceButtonWidth, height: serviceButtonHeight)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.roundedRectangle(radius: AppTheme.Radius.large))

            NavigationLink(value: AppRoute.plexSetup) {
                MediaProviderLabel(providerID: .plex, logoSize: serviceLogoSize)
                    .font(PlatformMetadata.sectionTitleFont)
                    .frame(width: serviceButtonWidth, height: serviceButtonHeight)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.roundedRectangle(radius: AppTheme.Radius.large))
        }
    }

    private var serviceButtonWidth: CGFloat {
        PlatformMetadata.isPhone ? 220 : 340
    }

    private var serviceButtonHeight: CGFloat {
        PlatformMetadata.isPhone ? 72 : 120
    }

    private var serviceLogoSize: CGFloat {
        PlatformMetadata.isPhone ? 28 : 40
    }
}
