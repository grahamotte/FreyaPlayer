import SwiftUI

struct ProviderPickerView: View {
    var body: some View {
        VStack(spacing: AppTheme.Spacing.xxLarge) {
            Image("FreyaLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 300, height: 300)

            if PlatformMetadata.isPhone {
                VStack(spacing: AppTheme.Spacing.large) {
                    serviceButtons
                }
            } else {
                HStack(spacing: AppTheme.Spacing.xxLarge) {
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
        .background(AppBackground())
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
