---
name: Freya Player
description: A native Apple player for your own Jellyfin or Plex server, lit by the artwork in view.
colors:
  freya-gold: "#E3AF32"
  on-gold: "#000000"
  screening-room-top: "#14171F"
  screening-room-floor: "#0A0D12"
  projection-white: "#FFFFFF"
  dimmed-white: "rgba(255, 255, 255, 0.72)"
  faint-white: "rgba(255, 255, 255, 0.5)"
  hairline: "rgba(255, 255, 255, 0.1)"
  surface: "rgba(255, 255, 255, 0.08)"
  surface-subtle: "rgba(255, 255, 255, 0.05)"
  surface-focused: "rgba(255, 255, 255, 0.16)"
  surface-border: "rgba(255, 255, 255, 0.12)"
  progress-track: "rgba(0, 0, 0, 0.55)"
  scrim: "rgba(0, 0, 0, 0.4)"
  artwork-shadow: "rgba(0, 0, 0, 0.35)"
  house-lights-1: "#29334D"
  house-lights-2: "#1A2138"
  house-lights-3: "#38334D"
  house-lights-4: "#1F2933"
  ember-1: "#8C6114"
  ember-2: "#332414"
  ember-3: "#5C3D0F"
  ember-4: "#1F1A1F"
  warning-orange: "#FF9F0A"
  positive-green: "#30D158"
typography:
  page-title:
    fontFamily: "SF Pro (system)"
    fontSize: "System large navigation title (iOS, iPadOS); inline title (Mac); 64pt scaled with Title 1 (tvOS header)"
    fontWeight: 700
  item-title:
    fontFamily: "SF Pro (system)"
    fontSize: "28pt iPhone / 38pt iPad & Mac / 58pt tvOS, scaled with Title"
    fontWeight: 700
  section-title:
    fontFamily: "SF Pro (system)"
    fontSize: "Title 2 (Title 3 on tvOS)"
    fontWeight: 600
  tile-title:
    fontFamily: "SF Pro (system)"
    fontSize: "Headline (Callout on tvOS)"
    fontWeight: 600
  facts:
    fontFamily: "SF Pro (system)"
    fontSize: "Subheadline (Callout on tvOS)"
    fontWeight: 500
  body:
    fontFamily: "SF Pro (system)"
    fontSize: "Body"
    fontWeight: 400
  label:
    fontFamily: "SF Pro (system)"
    fontSize: "Footnote (Caption 1 on tvOS)"
    fontWeight: 400
  detail-value:
    fontFamily: "SF Mono (system monospaced)"
    fontSize: "Body"
    fontWeight: 400
rounded:
  thumbnail: "8pt (14pt tvOS)"
  inline: "16pt"
  artwork: "18pt (24pt tvOS)"
  card: "20pt"
  large: "28pt"
  full: "9999pt"
spacing:
  xxs: "4pt"
  xs: "8pt"
  sm: "12pt"
  md: "16pt"
  lg: "24pt"
  xl: "32pt"
  xxl: "48pt"
components:
  play-button:
    backgroundColor: "{colors.freya-gold}"
    textColor: "{colors.on-gold}"
    rounded: "{rounded.full}"
    height: "24pt label minimum (40pt tvOS) inside system glass"
  glass-icon-button:
    textColor: "{colors.projection-white}"
    rounded: "{rounded.full}"
    size: "24pt content (40pt tvOS)"
  poster-tile:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.projection-white}"
    rounded: "{rounded.artwork}"
  open-library-tile:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.dimmed-white}"
    rounded: "{rounded.artwork}"
  open-library-tile-hover:
    backgroundColor: "{colors.surface-focused}"
  watched-check:
    backgroundColor: "{colors.freya-gold}"
    textColor: "{colors.on-gold}"
    rounded: "{rounded.full}"
    size: "22pt (34pt tvOS), scaled to artwork width"
  progress-bar:
    backgroundColor: "{colors.freya-gold}"
    rounded: "{rounded.full}"
    height: "5pt (8pt tvOS), scaled to artwork width"
  media-row:
    backgroundColor: "{colors.surface-subtle}"
    rounded: "{rounded.card}"
  media-row-focused:
    backgroundColor: "{colors.surface-focused}"
  detail-tile:
    backgroundColor: "{colors.surface-subtle}"
    rounded: "{rounded.inline}"
    padding: "16pt (24pt tvOS)"
  playback-plan:
    backgroundColor: "{colors.surface}"
    rounded: "{rounded.card}"
    padding: "16pt"
  item-artwork:
    backgroundColor: "{colors.surface}"
    rounded: "{rounded.large}"
---

# Design System: Freya Player

<!-- Regenerated from shipped code after the FP-40 facelift (2026-10-24). Tokens: apps/apple/App/Components/AppTheme.swift, Libraries/PlatformMetadata.swift, Assets.xcassets. -->

## Overview

**Creative North Star: "The Private Screening Room"**

Freya is a dark room that belongs to you, and the room takes its colour from whatever artwork is in view. The ground is near-black. Behind every browsing screen an animated mesh glows in colours lifted from the focused poster (tvOS), the hovered poster (Mac), or the lead artwork on screen (iOS and iPadOS), like spill from a projector. When the artwork changes, the room re-lights in place rather than cutting.

The structure is stock Apple: one navigation stack, system large titles, toolbars, menus, sheets, grouped Forms, `.searchable`, and AVPlayerViewController for playback. Controls are system Liquid Glass. Type is San Francisco in white. Surfaces are translucent white over the mesh, and density is low: large artwork, wide gutters, few controls per screen.

Freya Gold, taken from the logo, is the one interface hue. It marks the viewer's own path through the collection: the Play pill, the progress bar, and the watched check. Everything else stays neutral so the artwork can carry the colour.

**Key Characteristics:**
- Always dark (forced dark appearance), with a launch screen that matches the room's floor.
- The room is lit by an artwork-tinted mesh. It is the signature, and it sits behind content, never on it.
- White type at full strength and at 72%, plus a rare 50% for disclosure chevrons.
- Translucent white surfaces at 5%, 8%, and 16%, with 10% hairlines on artwork edges.
- System Liquid Glass for every control. Freya Gold tints only the prominent Play action.
- Continuous (squircle) corners everywhere.

## Colors

The palette is near-black, white, and one gold. All other colour comes from the artwork.

### Primary
- **Freya Gold** (#E3AF32): the viewer's own path, and nothing else. It tints the prominent glass Play, Resume, and Play All pill (with black label text), fills the watched check and the in-progress bar on artwork, and tints the item page's remaining-time progress view and the watched icon in the Seen menu. It is also the app's AccentColor asset.
- **On Gold** (#000000): label and icon colour on any gold fill.

### Neutral
- **Screening Room Top / Floor** (#14171F to #0A0D12): the vertical base gradient beneath the mesh. The floor colour is also the launch screen background, so launch hands off without a flash.
- **Projection White**: primary text.
- **Dimmed White** (72%): secondary text, synopses, facts lines, subtitles, placeholder symbols.
- **Faint White** (50%): the chevron after a shelf title. Use it for disclosure glyphs, not text.
- **Surface / Subtle / Focused** (8% / 5% / 16%): artwork placeholders and the Play Options plan block at 8%; detail tiles and tvOS list rows at rest at 5%; focused or hovered surfaces at 16%.
- **Hairline** (10%): a 1pt inner stroke around every piece of artwork, so dark posters keep an edge against the dark room.
- **Surface Border** (12%): dividers in full details.
- **Progress Track** (black 55%): the track under the gold progress bar.
- **Scrim** (black 40%): behind the full details cover. **Artwork Shadow** (black 35%): see Elevation.

### Ambient
- **House Lights** (#29334D, #1A2138, #38334D, #1F2933): the cool slate palette the mesh uses before any artwork loads, and on Manage.
- **Ember** (#8C6114, #332414, #5C3D0F, #1F1A1F): a dim amber palette derived from the gold. It lights screens that have no artwork to borrow: the provider picker, Jellyfin and Plex setup, the connecting and checking states, and About. It is ambience, not accent.
- **Artwork palettes**: up to six colours sampled from the artwork, weighted toward the centre and toward saturated pixels, then held to saturation 0.35–0.9 and brightness 0.45–0.9 so every poster lights the room without glaring.

### Functional
- **Warning Orange** (system orange): conversions in the Play Options plan, the "conditional" capability, and setup errors.
- **Positive Green** (system green): the "supported" capability.

### Named Rules
**The Viewer's Path Rule.** Freya Gold appears only where the viewer acts on or tracks their own watching: Play, progress, watched. It never marks selection, links, headers, or decoration.

**The Projector Rule.** Saturated colour comes from the artwork through the mesh, posters, and backdrops. The interface adds no hue of its own beyond Freya Gold and functional status colours.

## Typography

**Font:** San Francisco (system) for everything. SF Mono appears only for raw provider values in full details.

**Character:** Apple-native. Titles are heavy and large, and everything below them steps down quickly to system text styles.

### Hierarchy
- **Page Title** (bold): the system large navigation title on iOS and iPadOS, with the item count as the navigation subtitle on library grids. Mac uses the inline title in a unified toolbar. The tvOS UIKit headers draw it at 64pt scaled with Title 1.
- **Item Title** (bold, 28/38/58pt by idiom, scaled with Title): the title on an item page and in full details, up to 3 lines.
- **Section Title** (semibold Title 2; Title 3 on tvOS): shelf names, child-list headers, dialog titles.
- **Facts** (medium Subheadline; medium Callout on tvOS, Dimmed White): the one-line year · runtime · rating row under an item title.
- **Tile Title** (Headline; semibold Callout on tvOS): titles under tiles, scrolling as a marquee on hover (Mac) or focus (tvOS).
- **Body** (Body, Dimmed White): synopses, 5 lines on iOS and 2 on tvOS before Details.
- **Label** (Footnote; Caption 1 on tvOS): tile subtitles, metadata labels, remaining time.
- **Control**: glass button labels in the system control font.

### Named Rules
**The Dynamic Type Rule.** Item titles go through `itemTitleFont()` (a scaled metric relative to Title), and the tvOS page title through `uiPageTitleFont` (scaled relative to Title 1). Everything else is a system text style. New text never uses a fixed point size.

## Layout

Each screen is one full-bleed column inside a navigation stack. Every value below comes from `PlatformMetadata` unless noted.

- **Gutters:** 16pt iPhone, 20pt iPad and Mac, 48pt tvOS. **Section rhythm:** 24pt iPhone, 32pt iPad and Mac, 48pt tvOS. **Tile spacing:** 12pt iPhone, 16pt iPad and Mac, 48pt tvOS.
- **Home:** a system large title (the server name) with Search and More (Refresh, Manage, About) in the toolbar on iOS and Mac. Below it are stacked horizontal shelves. Each shelf title is a link with a faint chevron, and each shelf leads with an Open Library tile. Shelf tiles are 128pt (iPhone) or 176pt (iPad and Mac) for posters and 240pt or 300pt for wide artwork. tvOS shelves use fixed columns (6 posters or 4 wide) and show only the focused tile's title, captioned under the poster.
- **Library grid:** 3 posters or 2 wide across on iPhone, adaptive from 160pt posters or 260pt wide on iPad and Mac, and 4 posters or 3 wide on tvOS, where every tile is captioned.
- **Item page:** in landscape the artwork takes 38% of the width beside the details (50% for centred wide artwork). In portrait the artwork takes 38% of the height above scrolling details. tvOS insets the page 72pt.
- **Play Options:** a fitted sheet, 640pt wide (720pt on tvOS). On iPhone it sizes to its content with a drag indicator.
- **Forms (Manage, setup, About):** system grouped Forms over the ambient room, capped at 1200pt wide on tvOS through `readableFormWidth()`.

## Elevation & Depth

Depth comes from light and translucency, not shadows. The room has three layers: the base gradient, the artwork mesh (4×4 mesh gradient, 120pt blur, 1.05 saturation, 80% opacity, slow drift with ±10° hue rotation), and two black vignettes (top to bottom 0%, 18%, 50%; leading edge 22%). The item page adds the backdrop image blurred 40pt at 22% opacity and a leading black gradient (55% to 10% to clear) behind the text.

Changing artwork re-lights the room by blending from the current colours to the new palette over 1.4s with a smoothstep curve, after a 300ms debounce for palettes not yet cached. With Reduce Motion on, the mesh stops drifting and palettes change instantly.

### Shadow Vocabulary
- **Item artwork** (black 35%, 32pt blur, 20pt down): the poster on an item page reads as an object in the room.
- **Hover lift** (black 35%, 18pt blur, 10pt down, with 103% scale): a Mac poster tile under the pointer.

### Named Rules
**The Lights-Down Rule.** Panels and controls stay flat and translucent. Only artwork casts a shadow.

**The System Glass Rule.** Controls use system Liquid Glass: `.glass`, `.glassProminent` for the one Play action, and `UIButton.Configuration.glass()` in tvOS UIKit. Never hand-roll a white-alpha fill for a control.

## Shapes

Every rounded rectangle uses continuous corners. Radii grow with the object: detail tiles and focusable text 16pt, tiles 18pt (24pt on tvOS), list rows and the playback plan 20pt, item artwork and provider buttons 28pt. Controls take their shape from system glass: capsule pills for labelled buttons and circles for icon-only buttons (`glassIconButton()`). Progress bars are capsules, and the watched check is a circle.

## Components

### Buttons
- **Play (signature):** a `.glassProminent` pill tinted Freya Gold with a black `play.fill` label ("Play", or "Resume at 1:23:45"; plain "Resume" on iPhone), applied through `playActionStyle()`. It takes focus when the item page opens. A long press opens Play Options. **Play All** is the same pill as a menu (In Order, Shuffle), prominent only on a season or series page where it is the main action.
- **Icon-only:** `glassIconButton()`, a circular `.glass` button with a 24pt (40pt on tvOS) medium-weight symbol, used for Play Options, Seen, and Details beside Play.
- **Secondary:** `.glass` capsules for Cancel, the Play Options menus, and the provider buttons (28pt rounded rectangles).
- **tvOS UIKit:** `UIButton.Configuration.glass()` for Search and the home action row (360×72pt) and for the library Filter and Sort menus.
- **Form rows:** plain system rows. Deactivate uses the destructive role off tvOS; on tvOS it is a plain row so its focused label stays legible.

### Poster Tiles (`PosterArtwork`, `PosterTile`, `PosterCell`)
- **Shape:** artwork at 2:3 (poster) or 16:9 (wide) with the artwork radius, on a Surface placeholder with a dimmed SF Symbol, edged by a 1pt hairline.
- **Watch state:** a gold check circle in the bottom-trailing corner when watched. Otherwise a gold capsule bar on a black 55% track along the bottom edge. Both scale with artwork width (reference 160pt, 300pt on tvOS).
- **Text:** a marquee title and a dimmed subtitle (runtime, plus the added date when sorted by Date Added).
- **States:** on Mac, hover lifts to 103% with the hover shadow and re-lights the room. On tvOS, the system image-focus parallax lifts the poster, and focus re-lights the room.

### Open Library Tile
- The first tile on each home shelf. It matches the shelf's artwork shape on an 8% Surface fill (16% on hover) with a hairline edge, a dimmed `square.grid.2x2` symbol, "Open Library" as the title, and the item count as the subtitle.

### Item Page (`MediaView`)
- **Signature composition:** item artwork (28pt radius, shadowed) beside a details column with the item title, facts, a synopsis that opens full details, and an action row of the gold Play, Play Options, Seen, and Details. When the item is in progress, a gold progress view and remaining time sit under the action row.
- **Full details:** a full-screen cover over a 40% scrim with metadata in 5% Subtle tiles (16pt radius, SF Mono values) and dividers in Surface Border.

### Media Rows (`MediaRow`, `ItemChildListSection`, search results)
- A thumbnail with title, dimmed facts, and an optional synopsis. As buttons they use `MediaSurfaceButtonStyle`: clear at rest on iOS, 5% Subtle at rest on tvOS, 16% Focused with 102% scale on tvOS focus, and 98% when pressed, with a 20pt radius.

### Navigation
- A system `NavigationStack` with system back buttons and large titles. The player is presented full screen, full details uses a full-screen cover, and Play Options uses a sheet. Mac hides the window title in favour of a unified toolbar.

## Do's and Don'ts

### Do:
- **Do** light every browsing surface with `AmbientBackdrop` or `ArtworkLitBackground`, fed by the artwork the viewer is looking at, and use the Ember palette only where there is no artwork to borrow.
- **Do** reserve Freya Gold for Play, progress, and watched state, with black content on gold fills.
- **Do** use system components first: navigation titles, toolbars, menus, sheets, `.searchable`, `Form`, and AVPlayerViewController.
- **Do** use `glassIconButton()`, `glassPillLabel()`, and `playActionStyle()` for controls next to Play.
- **Do** edge artwork with the 10% hairline and use the spacing and radius tokens. Add a token rather than an inline number.
- **Do** honour Reduce Motion: no mesh drift, instant palette changes.
- **Do** keep the SwiftUI and tvOS UIKit renderings of a surface visually identical, and change them together.

### Don't:
- **Don't** use Freya Gold for selection, links, focus, section headers, or decoration.
- **Don't** hand-roll glassmorphism (white-alpha fills and strokes) for controls.
- **Don't** cut between room colours. Blend them, unless Reduce Motion is on.
- **Don't** add shadows to panels or controls. Only artwork casts one.
- **Don't** use fixed point sizes for text.
- **Don't** make inert elements focusable on tvOS.
- **Don't** hide the system navigation bar or back gesture to draw a custom one.
