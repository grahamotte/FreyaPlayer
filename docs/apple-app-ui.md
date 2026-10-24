# Apple App UI Map

How the Freya Player interface is put together: screens, navigation, shared components, and where each platform diverges. Read it with [PRODUCT.md](../PRODUCT.md) (who the app is for) and [DESIGN.md](../DESIGN.md) (the visual system). Paths are relative to `apps/apple/App/`.

## App Shell

- `FreyaPlayerApp` opens one `WindowGroup` containing `AppView`, plus Mac menu commands for About and Help.
- `AppView` owns a single `NavigationStack(path: [AppRoute])`. Every screen is pushed onto that stack, and there are no tabs or sidebars.
- `AppView` applies `.appChrome()`, which forces dark mode and white foreground on every screen.
- The root view depends on `AppModel.connectionState`:

| State | Root view |
| --- | --- |
| `.checking`, `.savedConnectionFailed` | `ProgressView("Checking saved connections...")`; the failure state also shows a Retry/Deactivate alert |
| `.connecting(message)` | `ProgressView(message)` |
| `.connected(server)` | `LibrariesPage` |
| `.signedOut`, `.failed` | `ProviderPickerView` |

When a server connects, the path is cleared. A `PollingLoop` refreshes stale libraries while a server stays connected.

## Routes

`AppRoute` in `AppRoute.swift`. `MediaItem.route` maps an item's kind to its route.

| Route | Page | Content view |
| --- | --- | --- |
| `.plexSetup` | `PlexSetupPage` | `PlexSetupContent` |
| `.jellyfinSetup` | `JellyfinSetupPage` | `JellyfinSetupContent` |
| `.about` | `AboutPage` | itself |
| `.plexSettings`, `.jellyfinSettings` | `PlexSettingsPage`, `JellyfinSettingsPage` | `ServerManagementPanel` (the same for both) |
| `.library(ref)` | `MovieLibraryPage`, `TvLibraryPage`, `OtherLibraryPage` (chosen by `defaultItemKind`) | `PlatformLibraryPageContent` (the same for all three) |
| `.search(server)` | `ServerSearchPage` | itself |
| `.movie`, `.episode`, `.other` | `MovieItemPage`, `TvEpisodeItemPage`, `OtherItemPage` | `PlayableMediaItemView` |
| `.series` | `TvSeriesItemPage` | `SeriesItemContent` |
| `.season` | `TvSeasonItemPage` | `SeasonItemContent` |

The per-kind page structs are one-line wrappers. They keep routing explicit, but today none of them differs from its siblings.

## Flow

```
Launch ─▶ Checking ─┬─▶ Provider Picker ─┬─▶ Jellyfin Setup (form) ─┐
                    │                    ├─▶ Plex Setup (notice → link code) ─┤
                    │                    └─▶ About                        │
                    └──────────────── connected ◀────────────────────────┘
                                         │
                                   Libraries (home)
             ┌───────────┬───────────────┼───────────────┬───────────┐
          Search      Library grid    Item detail       Manage      About
             │           │            (from shelf)       (settings)
             └─────▶ Item detail ◀────────┘
                        │
        Movie / Episode / Other ─▶ Play ─▶ AVPlayerViewController (full screen)
        Series ─▶ Seasons list ─▶ Season ─▶ Episodes list ─▶ Episode
```

Playback can start from four places. Every one of them runs through the same `MediaPlaybackSession`:

1. **Play/Resume** on an item page (`MediaPlayButton`). A long press opens Play Options.
2. **Play All** (In Order or Shuffle) on a series, season, or library (`MediaPlayAllButton`).
3. **Quick action** on any tile: a context menu on iOS and Mac, and a long press of Select on tvOS (`MediaItemQuickActions`).
4. **Play Options dialog**: quality, audio, and subtitle selection, plus a conversion plan (inside `MediaPlayButton`).

## Screens

### Provider Picker (`Pages/Setup/Components/ProviderPickerView.swift`)
Freya logo (300pt), two large provider buttons (Jellyfin first, Plex second), and an About button. The provider buttons stack vertically on iPhone and sit side by side elsewhere.

### Jellyfin Setup (`JellyfinSetupContent.swift`)
A grouped `Form`: a Server section (protocol segmented control, address, port), an Account section (username, password), and a Connect row whose footer shows any failure. Return moves focus to the next field. The system back button cancels.

### Plex Setup (`PlexSetupContent.swift`)
A privacy-notice alert appears first ("Before You Use Plex"). After that, a grouped `Form` shows the link-code flow ("Visit plex.tv/link in a browser and enter this code") and a Connect With Plex or Try Again row. Its state follows `connectionState`.

### Libraries Home (`Pages/Libraries/Components/`)
The server name is the page title, with Search on the trailing side. One horizontal shelf per visible library, each starting with an "Open Library" tile and followed by preview items. Refresh, Manage, and About sit at the bottom. The background is `BrowsingBackground`, an animated mesh whose random colors are picked once per launch and shared with Search and the library grids.

- iOS/Mac: SwiftUI in `LibrariesPage.iOSLayout`. Every tile shows a title and subtitle.
- tvOS: `TvOSLibrariesPageContent`, a UIKit compositional collection view. Tiles show artwork only, and a per-shelf footer shows the focused item's title. Shelf column counts are fixed (6 posters, 4 wide). Long-pressing Select opens quick actions.
- Data comes from `LibrariesHomeProjection`, which is shared by both platforms.

### Library Grid (`Pages/Library/Components/`)
The library title and item count, then Filter (All/Unseen), Sort (Title/Date Added/Duration with ascending or descending order), Play All, and a Seen/Unseen menu. Below that is a grid of `LibraryItemCard`s. State and persistence live in `LibraryPageState`, which is shared by both platforms.

- iOS: 2 columns on iPhone, 4 posters or 3 wide on iPad, adaptive on Mac.
- tvOS: `TvOSLibraryPageContent`, a UIKit collection view with 4 posters or 3 wide, a hosted SwiftUI Play All and Seen button in a UIKit header, and an index bar whose titles depend on the sort.

### Item Detail (`Components/MediaView.swift`)
One layout serves every item kind:

- On landscape and tvOS, details sit on the left (62%) and artwork on the right (38%).
- On portrait iPhone and iPad, artwork sits on top (38% of the height) and fades as the details scroll.
- The background comes from the artwork's palette (`AmbientMeshBackground` fed by `ArtworkPalette`), plus a faint blurred backdrop and black gradients.
- Content, in order: the title, a horizontal row of metadata tiles (Length, Released, Added) ending in a More Details button, the synopsis (5 lines; selecting it opens full details), and an action row supplied by the caller. Only More Details, the synopsis, and the actions take focus. On tvOS, focusing More Details or the synopsis scrolls the title back into view.
- "More Details" opens `FullItemDetailsView`, a full-screen cover with the description, an artwork gallery, and every provider field in a monospaced grid.

Series and Season pages add a Play All and Seen action row and an `ItemChildListSection`, a list of seasons or numbered episodes that auto-focuses the next unwatched child.

### Search (`Pages/Search/ServerSearchPage.swift`)
Fuzzy title search over the local cache (`ServerTitleSearch`), shown as rows with artwork, a highlighted title, the date, and the synopsis. Every platform uses the system `.searchable` field: it sits in the navigation bar on iOS and Mac and gets focus on arrival there.

### Manage / Settings (`Pages/Settings/Components/`)
A grouped `Form` with these sections: Server (name, address, provider, Deactivate), Cache (versions, size, Clear Cache), Libraries (reorder with up/down arrows, hide with the eye button), and Playback Capabilities (an AVFoundation format support list, one section per category). On tvOS the text rows can take focus so the list can scroll.

### About (`Pages/About/AboutPage.swift`)
A grouped `Form` covering free forever, private by default, open source, the bug link (a `Link` except on tvOS), and the version number.

## Shared Components (`Components/`)

| Component | Role | Used by |
| --- | --- | --- |
| `AppTheme` | Color, spacing, and radius tokens; the `focusSurface` and `MediaSurfaceButtonStyle` helpers | Everything |
| `PlatformMetadata` (`Libraries/`) | Per-idiom fonts, gutters, spacing, and title sizes; platform modifiers; the `PlatformLibrary(ies)PageContent` switches | Everything |
| `PlatformViewShims` | `pageTitleFont()` and `itemTitleFont()` (Dynamic Type), `readableFormWidth()`, `tvOSFocusSection()`, `tvOSFocusableRow()` | Pages and forms |
| `AppBackground`, `BrowsingBackground` | Flat base gradient; the per-launch ambient mesh for browsing screens | Loading and item fallback; home, search, library grids |
| `AmbientMeshBackground`, `ArtworkPalette` | Animated mesh gradient; color extraction from artwork | `BrowsingBackground`, Item detail |
| `ArtworkImage`, `ArtworkImageLoader` | Cached artwork with a style placeholder (SwiftUI); the same for UIKit cells | Every tile, search row, and item artwork |
| `LibraryItemCard` (`Pages/Library/`) | SwiftUI poster or wide tile with a progress badge, a marquee title, and a subtitle | iOS home shelves, iOS library grid |
| `WatchProgressCircle`, `ArtworkProgressIndicatorView` | Yellow pie or check badge; the UIKit wrapper for it | All tiles, child rows |
| `MarqueeText`, `MarqueeLabel` | Scrolls truncated titles on hover or focus (SwiftUI and UIKit) | Tiles, child rows |
| `MediaView` | Item detail layout and full details | Every item page |
| `MediaPlayButton` | Play or "Resume at…", plus the long-press Play Options dialog | Playable item pages |
| `MediaPlayAllButton` | Queue playback (in order or shuffled) | Series, Season, Library |
| `MediaWatchStatusButton`, `MediaCollectionWatchStatusButton` | Seen/Unseen/percent menu; the eye icon blends from white to yellow by progress | Item pages, Library header |
| `MediaItemQuickActions` | Context menu (SwiftUI) and long-press alert (UIKit tvOS) | Every tile |
| `MediaPlaybackSession` | The one playback path: queue, player presentation, timeline reporting, one recovery retry, seek reloads, preparing the next item, failure alerts | Every playback entry point |
| `PlaybackQueue` (`Libraries/`) | Playable-item queue and recovery-offset rule, unit tested | `MediaPlaybackSession` |
| `PlaybackSessionController`, `MediaPlayerItemFactory`, `StockPlayerViewController` | AVPlayer lifecycle; item metadata; the AVPlayerViewController host | `MediaPlaybackSession` |

Buttons use system Liquid Glass directly: `.buttonStyle(.glass)`, with `.glassProminent` for the one primary action (Play), and `UIButton.Configuration.glass()` in tvOS UIKit.

## Platform Split

| Surface | iOS / iPadOS / Mac | tvOS |
| --- | --- | --- |
| Libraries home | SwiftUI `ScrollView` and `LibraryItemCard` | UIKit `LibrariesCollectionViewController` with `LibraryTileCell`; the action row is glass `UIButton`s in non-focusable cells |
| Library grid | SwiftUI `LazyVGrid` | UIKit `LibraryPageCollectionViewController` with `LibraryGridCell`, `GlassMenuButton` |
| Tile title | Under every tile | A focused-title footer per shelf on the home screen; under each tile in the grid |
| Empty shelf | Message under the shelf | Message in the shelf footer |
| Quick actions | `.contextMenu` | `UIAlertController` opened by a long press of Select |
| Play Options | `.sheet`, or a custom full-screen card on iPhone | `.sheet` |

Tile and button visuals still exist twice, once in SwiftUI and once in tvOS UIKit. Both sides now resolve to the same system glass and the same `ArtworkImageLoader`, `MediaArtworkStyle`, and `AppTheme` tokens.

## Known Quirks

Fixed in FP-40: hand-rolled glass, fixed-size titles, custom settings, setup, and About cards, the custom iOS search header, the four playback copies, the duplicate style enums and image loaders, the duplicated library header, dead `FeatureStubView`, play-label and "Added At" wording, inert focus targets on item pages, iOS empty shelves, and mismatched browsing backgrounds.

Still open:
- Dark mode is forced everywhere through `.preferredColorScheme(.dark)`. Whether to support light appearance is undecided.
- The screenshots in `apps/screenshots/` predate the current UI.
- Several tvOS layout sizes remain literal values (shelf columns, the 184pt server header, grid text heights) because they are tied to the 1920pt canvas.

## Working Rules for the Facelift

- Change shared tokens and components first (`AppTheme`, `PlatformMetadata`, `PlatformViewShims`). Then update each tvOS UIKit counterpart in the same change.
- When a page needs a variant, add it to an existing shared component instead of styling inline. Keep feature-only views under their page, as AGENTS.md describes.
- Every visual change is checked on all four targets (tvOS, iPhone, iPad, Mac), because no platform wins ties.
- Refresh `apps/screenshots/` after the facelift lands.
