import AVFoundation
import SwiftUI

struct ServerManagementPlaybackCapabilitiesSection: View {
    @State private var capabilities = PlaybackCompatibility.deviceCapabilities

    var body: some View {
        Section {
            Text("Formats AVFoundation reports this \(PlatformMetadata.deviceName) can play. Playback options show whether Freya uses that native path or asks the server to convert the item.")
                .foregroundStyle(AppTheme.secondaryText)
                .tvOSFocusableRow()
        } header: {
            Text("Playback Capabilities")
        }
        .onReceive(NotificationCenter.default.publisher(for: AVPlayer.eligibleForHDRPlaybackDidChangeNotification)) { _ in
            capabilities = PlaybackCompatibility.deviceCapabilities
        }

        ForEach(PlaybackCapabilityCategory.allCases) { category in
            let categoryCapabilities = capabilities.filter { $0.category == category }
            if !categoryCapabilities.isEmpty {
                Section(category.rawValue) {
                    ForEach(categoryCapabilities) { capability in
                        capabilityRow(capability)
                            .tvOSFocusableRow()
                    }
                }
            }
        }
    }

    private func capabilityRow(_ capability: PlaybackCapability) -> some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.small) {
            Image(systemName: systemImage(for: capability.support))
                .foregroundStyle(color(for: capability.support))
                .frame(width: AppTheme.Spacing.large)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxSmall) {
                Text(capability.name)
                    .font(.body.weight(.medium))

                Text(capability.detail)
                    .font(PlatformMetadata.labelFont)
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityValue(capability.support.title)
    }

    private func systemImage(for support: PlaybackCapabilitySupport) -> String {
        switch support {
        case .supported: "checkmark.circle.fill"
        case .conditional: "questionmark.circle.fill"
        case .unavailable: "xmark.circle.fill"
        }
    }

    private func color(for support: PlaybackCapabilitySupport) -> Color {
        switch support {
        case .supported: AppTheme.positive
        case .conditional: AppTheme.warning
        case .unavailable: AppTheme.secondaryText
        }
    }
}
