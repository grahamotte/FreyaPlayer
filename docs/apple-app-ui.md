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

Playback can start from four places:

1. **Play/Resume** on an item page (`MediaPlayButton`). A long press opens Play Options.
2. **Play All** (In Order or Shuffle) on a series, season, or library (`MediaPlayAllButton`).
3. **Quick action** on any tile: a context menu on iOS and Mac, and a long press of Select on tvOS (`MediaItemQuickActions`).
4. **Play Options dialog**: quality, audio, and subtitle selection, plus a conversion plan (inside `MediaPlayButton`).

## Screens

### Provider Picker (`Pages/Setup/Components/ProviderPickerView.swift`)
Freya logo (300pt), two large provider buttons (Jellyfin first, Plex second), and an About button. The provider buttons stack vertically on iPhone and sit side by side elsewhere.

### Jellyfin Setup (`JellyfinSetupContent.swift`)
A form on a `PanelBackground` card with protocol (segmented), address, port, username, and password, then Connect and Cancel. On compact width the fields stack; otherwise protocol, address, and port share one row in a `Grid`. tvOS uses system text fields, and the other platforms use custom capsule fields.

### Plex Setup (`PlexSetupContent.swift`)
A privacy-notice alert appears first ("Before You Use Plex"). After that, the user sees a panel card with the link-code flow: "Visit plex.tv/link and enter this code". Its state follows `connectionState`.

### Libraries Home (`Pages/Libraries/Components/`)
The server name is the page title, with Search on the trailing side. One horizontal shelf per visible library, each starting with an "Open Library" tile and followed by preview items. Refresh, Manage, and About sit at the bottom. The background is an animated random-color mesh (`LibrariesAmbientBackground`).

- iOS/Mac: SwiftUI in `LibrariesPage.iOSLayout`. Every tile shows a title and subtitle.
- tvOS: `TvOSLibrariesPageContent`, a UIKit compositional collection view. Tiles show artwork only, and a per-shelf footer shows the focused item's title. Shelf column counts are fixed (6 posters, 4 wide). Long-pressing Select opens quick actions.
- Data comes from `LibrariesHomeProjection`, which is shared by both platforms.

### Library Grid (`Pages/Library/Components/`)
The library title and item count, then Filter (All/Unseen), Sort (Title/Added At/Duration with ascending or descending order), Play All, and a Seen/Unseen menu. Below that is a grid of `LibraryItemCard`s. State and persistence live in `LibraryPageState`, which is shared by both platforms.

- iOS: 2 columns on iPhone, 4 posters or 3 wide on iPad, adaptive on Mac.
- tvOS: `TvOSLibraryPageContent`, a UIKit collection view with 4 posters or 3 wide, a hosted SwiftUI Play All and Seen button in a UIKit header, and an index bar whose titles depend on the sort.

### Item Detail (`Components/MediaView.swift`)
One layout serves every item kind:

- On landscape and tvOS, details sit on the left (62%) and artwork on the right (38%).
- On portrait iPhone and iPad, artwork sits on top (38% of the height) and fades as the details scroll.
- The background comes from the artwork's palette (`AmbientMeshBackground` fed by `ArtworkPalette`), plus a faint blurred backdrop and black gradients.
- Content, in order: the title (an inert focusable button), a horizontal row of metadata tiles (Length, Released, Added, More Details), the synopsis (5 lines; Select opens the full details on tvOS), and an action row supplied by the caller.
- "More Details" opens `FullItemDetailsView`, a full-screen cover with the description, an artwork gallery, and every provider field in a monospaced grid.

Series and Season pages add a Play All and Seen action row and an `ItemChildListSection`, a list of seasons or numbered episodes that auto-focuses the next unwatched child.

### Search (`Pages/Search/ServerSearchPage.swift`)
Fuzzy title search over the local cache (`ServerTitleSearch`), shown as rows with artwork, a highlighted title, the date, and the synopsis. tvOS uses the system `.searchable`. iOS and Mac hide the navigation bar and draw a custom Back button and search field.

### Manage / Settings (`Pages/Settings/Components/`)
A stack of `ServerManagementSection` panel cards: Server (name, URL, Deactivate), Cache (versions, size, Clear Cache), Libraries (reorder with up/down arrows, hide with the eye button), and Playback Capabilities (an AVFoundation format support list).

### About (`Pages/About/AboutPage.swift`)
A single panel card that covers free forever, private by default, open source, the bug link, and the version number.

## Shared Components (`Components/`)

| Component | Role | Used by |
| --- | --- | --- |
| `AppTheme` | Color, spacing, and radius tokens; the `focusSurface`, `glassField`, and `MediaSurfaceButtonStyle` helpers; UIKit glass helpers | Everything |
| `PlatformMetadata` (`Libraries/`) | Per-idiom fonts, gutters, spacing, and title sizes; platform modifiers; the `PlatformLibrary(ies)PageContent` switches | Everything |
| `AppBackground`, `PanelBackground` | Base dark gradient; the rounded card behind a form or section | Setup, Settings, About, library grids |
| `AmbientMeshBackground`, `ArtworkPalette` | Animated mesh gradient; color extraction from artwork | Libraries home, Search, Item detail |
| `MediaGlassButtonStyle` | The app's button (sizes regular, compact, square, bare; roles standard, tinted, destructive) | Every SwiftUI button and menu |
| `LibraryItemCard` (`Pages/Library/`) | SwiftUI poster or wide tile with a progress badge, a marquee title, and a subtitle | iOS home shelves, iOS library grid |
| `WatchProgressCircle`, `ArtworkProgressIndicatorView` | Yellow pie or check badge; the UIKit wrapper for it | All tiles, child rows |
| `MarqueeText`, `MarqueeLabel` | Scrolls truncated titles on hover or focus (SwiftUI and UIKit) | Tiles, child rows |
| `MediaView` | Item detail layout and full details | Every item page |
| `MediaPlayButton` | Play/Resume, the long-press Play Options dialog, and a full playback session | Playable item pages |
| `MediaPlayAllButton` | Queue playback (in order or shuffled) | Series, Season, Library |
| `MediaWatchStatusButton`, `MediaCollectionWatchStatusButton` | Seen/Unseen/percent menu tinted from white to yellow by progress | Item pages, Library header |
| `MediaItemQuickActions` | Context menu (SwiftUI) and long-press alert (UIKit); each starts its own playback session | Every tile |
| `PlaybackSessionController`, `MediaPlayerItemFactory`, `StockPlayerView` | AVPlayer lifecycle and timeline reporting; item metadata; AVPlayerViewController host | All playback |

## Platform Split

| Surface | iOS / iPadOS / Mac | tvOS |
| --- | --- | --- |
| Libraries home | SwiftUI `ScrollView` and `LibraryItemCard` | UIKit `LibrariesCollectionViewController` with `LibraryTileCell` |
| Library grid | SwiftUI `LazyVGrid` | UIKit `LibraryPageCollectionViewController` with `LibraryGridCell`, `GlassMenuButton` |
| Tile title | Under every tile | A focused-title footer per shelf on the home screen; under each tile in the grid |
| Quick actions | `.contextMenu` | `UIAlertController` opened by a long press of Select |
| Search field | Custom header, nav bar hidden | System `.searchable` |
| Setup text fields | Custom capsule fields | System fields |
| Play Options | `.sheet`, or a custom full-screen card on iPhone | `.sheet` |

The UIKit screens reproduce the SwiftUI glass look through `AppTheme.applyGlassBackground` and `uiGlassForeground`. Any visual change to a button, tile, or header has to be made twice.

## Known Quirks

These are inconsistencies found while mapping the app. They are the starting backlog for the facelift.

**System fit**
- The app draws its own "glass": `MediaGlassButtonStyle` and `applyGlassBackground` fill buttons with 12% white and invert them to solid white on focus. It targets OS 26.2, so it could use system Liquid Glass (`.buttonStyle(.glass)`, `.glassProminent`, `glassEffect`) instead.
- Title sizes are hard-coded points (`pageTitleSize` 38/52/64, `itemTitleSize` 28/38/58), so they ignore Dynamic Type. Fixed widths (720, 860, 1000, 1200, 360×72 tvOS buttons) are scattered through the views.
- Settings, About, and setup are custom panel-card stacks rather than grouped `Form` and `List` content.
- On iOS, Search hides the system navigation bar and back button and replaces them with a custom Back button and field.
- Dark mode is forced everywhere through `.preferredColorScheme(.dark)`.

**Duplication**
- Playback orchestration is written four times: in `MediaPlayButton`, `MediaPlayAllButton`, and twice in `MediaItemQuickActions` (the UIKit handler and the SwiftUI presenter). Each copy has its own recovery, seek, and timeline code.
- Two private enums (`LibrariesShelfStyle`, `LibraryTileStyle`) re-implement `MediaArtworkStyle`.
- Placeholder icons (`film.stack.fill` / `tv.fill`) and image-loading logic are copied across `LibraryItemCard`, `LibraryTileCell`, `LibraryGridCell`, and `SearchResultArtwork`.
- The iPad and Mac library header lists the same controls twice inside `ViewThatFits`.
- `FeatureStubView` has no callers.

**Inconsistent language**
- Watch state is called "Seen/Unseen" in the UI, "watched" in code, and "Unwatched" in the published screenshots.
- The play label varies: "Play/Resume" on the button, `playButtonTitle` (with a timestamp) in Play Options, and "Play Now/Resume Now" in quick actions.
- The sort is labelled "Added At", and the full details header shows "N fields across M sections".
- The first tile on a home shelf reads "Open Library" in code but the library name in the tvOS screenshot. The screenshots in `apps/screenshots/` predate current code.

**Visual hierarchy**
- The title, metadata tiles, and synopsis on an item page are focusable buttons with empty actions, so tvOS focus lands on things that do nothing (the synopsis is the exception on tvOS).
- `LibrariesHomeProjection` computes an empty-shelf message, but only tvOS shows it.
- Three backgrounds compete: a random-color mesh on home and search, an artwork mesh on items, and a flat gradient everywhere else. A library grid opened from the colorful home drops to the flat gradient.
- The watch tint is the system yellow, with no other accent in the app. The progress-blended button color (white → yellow) is the only use of color in controls.

## Working Rules for the Facelift

- Change shared tokens and components first (`AppTheme`, `PlatformMetadata`, `MediaGlassButtonStyle`). Then update each tvOS UIKit counterpart in the same change.
- When a page needs a variant, add it to an existing shared component instead of styling inline. Keep feature-only views under their page, as AGENTS.md describes.
- Every visual change is checked on all four targets (tvOS, iPhone, iPad, Mac), because no platform wins ties.
- Refresh `apps/screenshots/` after the facelift lands.
