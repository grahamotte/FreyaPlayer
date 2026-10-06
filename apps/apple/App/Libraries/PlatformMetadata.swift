import Foundation
import SwiftUI
import UIKit

enum PlatformMetadata {
    static let isTV: Bool = UIDevice.current.userInterfaceIdiom == .tv
    static let isPhone: Bool = UIDevice.current.userInterfaceIdiom == .phone
    static let isiPad: Bool = UIDevice.current.userInterfaceIdiom == .pad
    #if targetEnvironment(macCatalyst)
    static let isMac: Bool = true
    #else
    static let isMac: Bool = false
    #endif

    static let plexPlatformName: String = {
        #if os(tvOS)
        "tvOS"
        #elseif targetEnvironment(macCatalyst)
        "MacOSX"
        #else
        "iOS"
        #endif
    }()

    static let deviceName: String = {
        #if os(tvOS)
        "Apple TV"
        #elseif targetEnvironment(macCatalyst)
        "Mac"
        #else
        PlatformMetadata.isPhone ? "iPhone" : "iPad"
        #endif
    }()

    static var pageGutter: CGFloat {
        if isTV { return AppTheme.Spacing.xxLarge }
        return isPhone ? AppTheme.Spacing.medium : AppTheme.Spacing.xLarge
    }

    static var controlSpacing: CGFloat {
        isTV ? AppTheme.Spacing.large : AppTheme.Spacing.small
    }

    static var panelPadding: CGFloat {
        isPhone ? AppTheme.Spacing.medium : AppTheme.Spacing.large
    }

    static var pageSectionSpacing: CGFloat {
        if isTV { return AppTheme.Spacing.xxLarge }
        return isPhone ? AppTheme.Spacing.large : AppTheme.Spacing.xLarge
    }

    static var shelfSpacing: CGFloat {
        isPhone ? AppTheme.Spacing.small : AppTheme.Spacing.medium
    }

    static var tileSpacing: CGFloat {
        if isTV { return AppTheme.Spacing.xxLarge }
        return isPhone ? AppTheme.Spacing.small : AppTheme.Spacing.medium
    }

    static var tileTitleSpacing: CGFloat {
        isTV ? AppTheme.Spacing.large : AppTheme.Spacing.xSmall
    }

    static var tileSubtitleSpacing: CGFloat {
        AppTheme.Spacing.xxSmall
    }

    static var pageTitleSize: CGFloat {
        if isTV { return 64 }
        return isPhone ? 38 : 52
    }

    static var itemTitleSize: CGFloat {
        if isTV { return 58 }
        return isPhone ? 28 : 38
    }

    static var pageTitleFont: Font {
        .system(size: pageTitleSize, weight: .bold)
    }

    static var itemTitleFont: Font {
        .system(size: itemTitleSize, weight: .bold)
    }

    static var uiPageTitleFont: UIFont {
        .systemFont(ofSize: pageTitleSize, weight: .bold)
    }

    static var sectionTitleFont: Font {
        Font.system(sectionTitleTextStyle, weight: .semibold)
    }

    static var uiSectionTitleFont: UIFont {
        uiFont(sectionTitleUITextStyle, weight: .semibold)
    }

    static var controlFont: Font {
        .body.weight(.semibold)
    }

    static var uiControlFont: UIFont {
        uiFont(.body, weight: .semibold)
    }

    static var tileTitleFont: Font {
        isTV ? .callout.weight(.semibold) : .headline
    }

    static var uiTileTitleFont: UIFont {
        isTV ? uiFont(.callout, weight: .semibold) : .preferredFont(forTextStyle: .headline)
    }

    static var labelFont: Font {
        isTV ? .caption : .footnote
    }

    static var uiLabelFont: UIFont {
        .preferredFont(forTextStyle: isTV ? .caption1 : .footnote)
    }

    private static var sectionTitleTextStyle: Font.TextStyle {
        isTV ? .title3 : .title2
    }

    private static var sectionTitleUITextStyle: UIFont.TextStyle {
        isTV ? .title3 : .title2
    }

    private static func uiFont(_ style: UIFont.TextStyle, weight: UIFont.Weight) -> UIFont {
        .systemFont(ofSize: UIFont.preferredFont(forTextStyle: style).pointSize, weight: weight)
    }

    static var supportsItemTitleHoverMarquee: Bool {
        isTV || isMac
    }

    static var requiresTranscodedPlaybackAudio: Bool {
        PlaybackCompatibility.requiresTranscodedAudio
    }
}

extension PlatformMetadata {
    static func textSelectionModifier<Content: View>(_ content: Content) -> some View {
        #if os(tvOS)
        return content
        #else
        return content.textSelection(.enabled)
        #endif
    }

    static func focusSectionModifier<Content: View>(_ content: Content) -> some View {
        #if os(tvOS)
        return content.focusSection()
        #else
        return content
        #endif
    }

    static func macCommandsModifier<Content: Scene>(_ content: Content) -> some Scene {
        #if targetEnvironment(macCatalyst)
        return content.commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Freya Player") {
                    NotificationCenter.default.post(name: .navigateToAbout, object: nil)
                }
            }
            CommandGroup(replacing: .help) {
                Button("Freya Player Help") {
                    NotificationCenter.default.post(name: .navigateToAbout, object: nil)
                }
            }
        }
        #else
        return content
        #endif
    }

    static func configureFocusedImageView(_ imageView: UIImageView) {
        #if os(tvOS)
        imageView.adjustsImageWhenAncestorFocused = true
        imageView.overlayContentView.clipsToBounds = false
        #endif
    }

    static func overlayContent(for imageView: UIImageView) -> UIView {
        #if os(tvOS)
        return imageView.overlayContentView
        #else
        return imageView
        #endif
    }

    static func hoverModifier<Content: View>(_ content: Content, perform action: @escaping (Bool) -> Void) -> some View {
        #if targetEnvironment(macCatalyst)
        return content.onHover(perform: action)
        #else
        return content
        #endif
    }
}

extension View {
    func platformHover(perform action: @escaping (Bool) -> Void) -> some View {
        PlatformMetadata.hoverModifier(self, perform: action)
    }
}

struct PlatformLibraryPageContent: View {
    @ObservedObject var model: AppModel
    let library: LibraryReference
    @Binding var path: [AppRoute]

    var body: some View {
        #if os(tvOS)
        TvOSLibraryPageContent(model: model, library: library, path: $path)
        #else
        IOSLibraryPageContent(model: model, library: library)
        #endif
    }
}

struct PlatformLibrariesPageContent: View {
    @ObservedObject var model: AppModel
    let server: ConnectedServer
    @Binding var path: [AppRoute]
    let iOSLayout: AnyView

    var body: some View {
        #if os(tvOS)
        TvOSLibrariesPageContent(model: model, server: server, path: $path)
        #else
        iOSLayout
        #endif
    }
}
