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

Every browsing screen sits in an ambient room lit by artwork (`AmbientBackdrop`, see Signature below). Setup, settings, and About use the gold-tinted brand palette or the neutral one.

### Provider Picker (`Pages/Setup/Components/ProviderPickerView.swift`)
The Freya logo, the title "Freya Player", a one-line prompt, two glass provider buttons (Jellyfin first, Plex second), and an About button, all on the gold brand glow. The provider buttons stack on iPhone and sit side by side elsewhere.

### Jellyfin Setup (`JellyfinSetupContent.swift`)
On iOS and Mac, a grouped `Form`: a Server section (protocol, address, port), an Account section (username, password), and a Connect row whose footer shows any failure. On tvOS, the FP-3 layout: protocol, address, and port on one row; username and password as standalone system fields; and a gold Connect button. Return moves focus to the next field on both. The system back button cancels.

### Plex Setup (`PlexSetupContent.swift`)
A privacy-notice alert appears first ("Before You Use Plex"). After that, a grouped `Form` shows the link-code flow ("Visit plex.tv/link in a browser and enter this code") and a Connect With Plex or Try Again row. Its state follows `connectionState`.

### Libraries Home (`Pages/Libraries/Components/`)
The server name is the page title. One horizontal shelf per visible library, filled from `LibrariesHomeProjection` (shared by both platforms). The room is lit by the lead artwork, or by whatever is focused or hovered.

- iOS/Mac: `LibrariesPage.iOSLayout` in SwiftUI. The server name is the system large title (inline on Mac), with Search and More (Refresh, Manage, About) toolbar buttons and a spinner while refreshing. Each shelf starts with an `OpenLibraryTile` captioned with the library's item count, and its chevron title also opens the library. `PosterTile`s show a title and subtitle. Pull to refresh works on iPhone and iPad. Empty shelves show skeleton tiles while loading and the empty message afterward.
- tvOS: `TvOSLibrariesPageContent`, a UIKit compositional collection view built from `PosterCell`s. The focused poster shows its title beneath it. Each shelf starts with an Open Library tile, which takes initial focus and lights the room with that shelf's lead artwork. A glass Search button sits in the header, and glass Refresh, Manage, and About buttons sit at the bottom. Shelf column counts are fixed (6 posters, 4 wide). Long-pressing Select opens quick actions.

### Library Grid (`Pages/Library/Components/`)
The library title and count (the system title and subtitle on iOS/Mac), separate Filter (All/Unseen) and Sort (Title/Date Added/Duration, then ascending or descending) menus (toolbar buttons on iOS/Mac, glass pills on tvOS), then Play All and a Seen menu. Below that is a grid of posters. State and persistence live in `LibraryPageState`, which both platforms share.

- iOS/Mac: a SwiftUI `LazyVGrid` of `PosterTile`s, with 3 posters or 2 wide on iPhone and adaptive columns elsewhere. Skeleton tiles show while loading, and `ContentUnavailableView` shows when the grid is empty.
- tvOS: `TvOSLibraryPageContent`, a UIKit collection view of `PosterCell`s (4 posters or 3 wide) with captions always showing, glass `GlassMenuButton`s, a hosted SwiftUI Play All and Seen button, and an index bar whose titles depend on the sort.

### Item Detail (`Components/MediaView.swift`)
One layout serves every item kind. `MediaView(model:data:actions:below:)` takes the action buttons and an optional section below them, such as a seasons or episodes list.

- On landscape and tvOS, details sit on the left (62%) and artwork on the right (38%). On portrait iPhone and iPad, artwork sits on top and fades as the details scroll.
- The background is `ArtworkLitBackground` for the item's artwork, plus a faint blurred backdrop.
- Content, in order: the title, a facts line (year · rating · runtime), the synopsis (selecting it opens full details), and the action row. The row holds the caller's actions plus a circular Details button. In-progress items also show a gold time-left bar.
- Movie, episode, and other actions: a gold Play pill ("Resume at 32:18", shortened to "Resume" on iPhone), plus circular glass Play Options and Seen buttons. Long-pressing Play also opens Play Options.
- Series and season actions: a gold Play All pill and a Seen menu. Below them, `ItemChildListSection` shows `MediaRow`s for seasons or numbered episodes and auto-focuses the next unwatched one.
- On tvOS the header (title through actions) stays pinned, and only the list below scrolls, fading under the header; the rows label themselves, so there is no "Seasons"/"Episodes" heading there. A page with nothing below (movies, episodes) centres its details beside the artwork, and wide artwork takes half the width.
- Off tvOS the season and episode rows have no card background; spacing separates them.
- Details opens `FullItemDetailsView`, a full-screen cover with the description, an artwork gallery, and every provider field.

### Search (`Pages/Search/ServerSearchPage.swift`)
Fuzzy title search over the local cache (`ServerTitleSearch`), shown as `MediaRow`s with the matched part of each title in bold. Every result uses a full-bleed 16:9 thumbnail (`MediaArtworkSet.widescreenURL`) so titles share one edge. The room is lit by the top result. Every platform uses the system `.searchable` field. It sits in the navigation bar on iOS and Mac and gets focus on arrival there.

### Manage / Settings (`Pages/Settings/Components/`)
A grouped `Form` (the standard tvOS list on tvOS). Sections: Server (name, address, provider, Deactivate Server… with a confirmation alert), Cache (versions, size, Clear Cache), Libraries (on iOS/Mac a leading drag handle and a Show toggle per library, reordered by dragging the row; on tvOS a Shown/Hidden button and glass up/down arrows), and Playback Capabilities (one section per category). On tvOS the text rows can take focus so the list can scroll, and `tvOSFocusableRow()` lightens the focused row so focus is always visible.

### About (`Pages/About/AboutPage.swift`)
A grouped `Form` covering free forever, private by default, open source, the bug link (a `Link` except on tvOS), and the version number.

## Signature: Lit by the Artwork

`AmbientLight` holds the current `AmbientPalette` and blends the mesh colours in place to a new one (1.4s smoothstep, or instantly with Reduce Motion) whenever a page calls `light(url)`; an interrupted blend continues from where it is, so the room never flashes. Palettes are pulled from artwork by `ArtworkPalette` and cached per URL. Calls are debounced 300ms, so quick focus sweeps settle once. `AmbientBackdrop(light:)` draws the mesh under legibility scrims. `ArtworkLitBackground(url:fallback:)` wraps both for screens with one fixed palette.

| Screen | What lights the room |
| --- | --- |
| Home, library grid (tvOS) | The focused poster |
| Home, library grid (iOS) | The lead poster; the hovered poster on Mac |
| Search | The top result |
| Item pages | The item's artwork |
| Onboarding, setup, About | `AmbientPalette.brand` (gold) |
| Manage | `AmbientPalette.neutral` |

## Shared Components (`Components/`)

| Component | Role | Used by |
| --- | --- | --- |
| `AppTheme` | Color (including the `accent` Freya Gold), spacing, and radius tokens; the `focusSurface` and `MediaSurfaceButtonStyle` helpers | Everything |
| `PlatformMetadata` (`Libraries/`) | Per-idiom fonts, gutters, spacing, title sizes, and `controlContentSide`; platform modifiers; the `PlatformLibrary(ies)PageContent` switches | Everything |
| `PlatformViewShims` | `pageTitleFont()` and `itemTitleFont()` (Dynamic Type), `glassIconButton()`, `glassPillLabel()`, `playActionStyle()`, `formBackdrop()`, `readableFormWidth()`, `tvOSFocusSection()`, `tvOSFocusableRow()` | Pages and controls |
| `AmbientBackdrop`, `AmbientLight`, `AmbientPalette`, `ArtworkLitBackground` | The artwork-lit room (see Signature) | Every page |
| `AmbientMeshBackground`, `ArtworkPalette` | The animated mesh; color extraction from artwork | `AmbientBackdrop` |
| `AppBackground` | The flat base under the mesh | `AmbientBackdrop` |
| `ArtworkImage`, `ArtworkImageLoader` | Cached artwork with a placeholder for its style (SwiftUI); the same for UIKit cells | `PosterArtwork`, `PosterCell`, item artwork |
| `PosterArtwork`, `PosterTile` | Artwork with a hairline edge and progress badge; that plus a marquee title and subtitle | iOS home shelves and library grid, `MediaRow` |
| `PosterCell` | The tvOS UIKit poster: system focus parallax, a caption that appears on focus or always shows, a placeholder icon and title (Open Library) | tvOS home and library grid |
| `MediaRow` | Thumbnail, title, facts, and synopsis; an optional uniform 16:9 thumbnail | Seasons, episodes, search results |
| `OpenLibraryTile` | Poster-sized grid tile captioned "Open Library" and the item count | iOS/Mac home shelves |
| `WatchProgressBadge`, `ArtworkProgressIndicatorView` | A gold progress bar, or a gold check when watched; the UIKit host | Every artwork |
| `MarqueeText`, `MarqueeLabel` | Scrolls truncated titles on hover or focus (SwiftUI and UIKit) | Tiles, `PosterCell` |
| `MediaView` | Item detail layout and full details | Every item page |
| `MediaPlayButton` | The gold Play pill plus the Play Options button and dialog | Playable item pages |
| `MediaPlayAllButton` | Queue playback (in order or shuffled); gold when it is the primary action | Series, Season, Library |
| `MediaWatchStatusButton`, `MediaCollectionWatchStatusButton` | Circular Seen menu: gold check when watched, eye otherwise | Item pages, Library header |
| `MediaItemQuickActions` | Context menu (SwiftUI) and long-press alert (UIKit tvOS) | Every tile |
| `MediaPlaybackSession` | The one playback path: queue, player presentation, timeline reporting, one recovery retry, seek reloads, preparing the next item, failure alerts | Every playback entry point |
| `PlaybackQueue` (`Libraries/`) | Playable-item queue and recovery-offset rule, unit tested | `MediaPlaybackSession` |
| `PlaybackSessionController`, `MediaPlayerItemFactory`, `StockPlayerViewController` | AVPlayer lifecycle; item metadata; the AVPlayerViewController host | `MediaPlaybackSession` |

Controls use system Liquid Glass. Primary actions (Play, Play All on series and seasons, tvOS Connect) use `playActionStyle()`: `.glassProminent` in Freya Gold with a dark label. Everything else uses `.glass`, with `glassIconButton()` for circles and `glassPillLabel()` so pills match circle height. tvOS UIKit uses `UIButton.Configuration.glass()`.

## Platform Split

| Surface | iOS / iPadOS / Mac | tvOS |
| --- | --- | --- |
| Libraries home | SwiftUI `ScrollView` and `PosterTile` | UIKit `LibrariesCollectionViewController` with `PosterCell`; the action row is glass `UIButton`s in non-focusable cells |
| Library grid | SwiftUI `LazyVGrid` and `PosterTile` | UIKit `LibraryPageCollectionViewController` with `PosterCell`, `GlassMenuButton` |
| Tile title | Under every tile | Under the focused poster on home; under each tile in the grid |
| Empty shelf | Skeleton while loading, then the message under the shelf | Message in the shelf footer |
| Open a library | A leading Open Library tile, or the chevron shelf title | A leading Open Library tile |
| Item header | Scrolls with its list | Pinned; only the list scrolls |
| Sign-in form | Grouped `Form` | Standalone system fields (FP-3 layout) |
| Quick actions | `.contextMenu` | `UIAlertController` opened by a long press of Select |
| Play Options | `.sheet`, or a custom full-screen card on iPhone | `.sheet` |

Tiles exist twice: `PosterTile` in SwiftUI and `PosterCell` in tvOS UIKit. Both use the same `ArtworkImageLoader`, `WatchProgressBadge`, `MediaArtworkStyle`, `PlatformMetadata` type, and `AppTheme` tokens, so a visual change belongs in those shared pieces first.

## Known Quirks

Fixed in FP-40: hand-rolled glass, fixed-size titles, custom settings, setup, and About cards, the custom iOS search header, the four playback copies, the duplicate style enums and image loaders, the duplicated library header, dead `FeatureStubView`, play-label and "Added At" wording, inert focus targets on item pages, iOS empty shelves, and mismatched browsing backgrounds.

Still open:
- Dark mode is applied everywhere through `.preferredColorScheme(.dark)`; dark-only is a confirmed product decision.
- The screenshots in `apps/screenshots/` predate the current UI.
- Several tvOS layout sizes remain literal values (shelf columns, the 184pt server header, grid text heights) because they are tied to the 1920pt canvas.

## Working Rules for the Facelift

- Change shared tokens and components first (`AppTheme`, `PlatformMetadata`, `PlatformViewShims`). Then update each tvOS UIKit counterpart in the same change.
- When a page needs a variant, add it to an existing shared component instead of styling inline. Keep feature-only views under their page, as AGENTS.md describes.
- Every visual change is checked on all four targets (tvOS, iPhone, iPad, Mac), because no platform wins ties.
- Refresh `apps/screenshots/` after the facelift lands.
