---
name: Freya Player
description: A native Apple player for your own Jellyfin or Plex server.
colors:
  screening-room-top: "#14171F"
  screening-room-floor: "#0A0D12"
  projection-white: "#FFFFFF"
  dimmed-white: "rgba(255, 255, 255, 0.72)"
  surface: "rgba(255, 255, 255, 0.08)"
  surface-subtle: "rgba(255, 255, 255, 0.05)"
  surface-focused: "rgba(255, 255, 255, 0.16)"
  surface-border: "rgba(255, 255, 255, 0.12)"
  seen-yellow: "#FFD60A"
  warning-orange: "#FF9F0A"
  positive-green: "#30D158"
  destructive-red: "#FF453A"
  scrim: "rgba(0, 0, 0, 0.4)"
  modal-scrim: "rgba(0, 0, 0, 0.5)"
typography:
  page-title:
    fontFamily: "SF Pro (system)"
    fontSize: "38pt iPhone / 52pt iPad & Mac / 64pt tvOS, scaled with Large Title"
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
  body:
    fontFamily: "SF Pro (system)"
    fontSize: "Body"
    fontWeight: 400
  label:
    fontFamily: "SF Pro (system)"
    fontSize: "Footnote (Caption on tvOS)"
    fontWeight: 400
  detail-value:
    fontFamily: "SF Mono (system monospaced)"
    fontSize: "Body"
    fontWeight: 400
rounded:
  inline: "16pt"
  artwork: "18pt (24pt tvOS)"
  card: "20pt"
  large: "28pt"
spacing:
  xxs: "4pt"
  xs: "8pt"
  sm: "12pt"
  md: "16pt"
  lg: "24pt"
  xl: "32pt"
  xxl: "48pt"
components:
  media-tile:
    backgroundColor: "{colors.surface}"
    rounded: "{rounded.artwork}"
  detail-tile:
    backgroundColor: "{colors.surface-subtle}"
    rounded: "{rounded.card}"
    padding: "12pt 16pt"
  list-row:
    backgroundColor: "{colors.surface}"
    rounded: "{rounded.card}"
    padding: "16pt 24pt"
---

# Design System: Freya Player

<!-- Captured from code on 2026-10-24 and updated after FP-40 (system Liquid Glass, Forms, Dynamic Type titles). -->

## Overview

**Creative North Star: "The Private Screening Room"**

Freya is a dark, quiet room that belongs to you. The lights are down, the chrome stays out of the way, and the collection's own artwork supplies the color. Nothing leaves the room: the interface should feel calm, private, and owned, never like a storefront.

The structure is stock Apple. There is one navigation stack, system menus, alerts, context menus, and AVPlayerViewController for playback. Freya's light signature is ambient color drawn from the artwork, glowing behind the content like the spill from a projector. Everything else is near-black space, white type, and translucent surfaces. Density is low: large artwork, generous gutters, and few controls per screen.

Controls use the system's Liquid Glass, settings-shaped screens are grouped Forms, and browsing screens share one ambient background per launch. Item pages swap in the artwork's own palette.

**Key Characteristics:**
- Always dark, with white type at two strengths (full and 72%).
- Artwork is the hero and the only source of saturated color, apart from the yellow "seen" mark.
- Translucent white surfaces at 5%, 8%, 12%, and 16% for layering. There are no colored panels.
- Controls are system Liquid Glass and take the system focus and press treatment. On tvOS a focused tile lifts with the system parallax.
- Continuous (squircle) corners everywhere.

## Colors

The palette is near-black and white. Saturated color comes from content, plus one functional accent.

### Primary
- **Seen Yellow** (system yellow): the only interface accent. It marks watched and in-progress state on the pie or check badge, and it colors the Seen/Unseen button's eye icon in proportion to progress. It is never decoration.

### Neutral
- **Screening Room Top / Floor**: the vertical base gradient behind every screen that has no artwork.
- **Projection White**: primary text and the fill of a focused control.
- **Dimmed White** (72%): secondary text, labels, placeholder icons, and captions.
- **Surface / Subtle / Focused**: translucent white layers for tiles and list rows at rest (8%), quiet detail tiles (5%), and focused surfaces (16%).
- **Surface Border**: hairline dividers in full details.
- **Scrims**: black at 40% behind full-screen details and 50% behind the iPhone Play Options card.

### Functional
- **Warning Orange**: conversions in the Play Options plan, "conditional" capability, dialog errors.
- **Positive Green**: "supported" capability.
- **Destructive Red**: reserved for destructive state. Deactivate uses the system destructive button role.

### Named Rules
**The Projector Rule.** Saturated color on screen comes from the artwork (the ambient mesh, posters, backdrops) or from the seen mark. The interface never adds its own hue for decoration.

**The One Accent Rule.** Seen Yellow means watch state and nothing else. Do not reuse it for selection, links, or emphasis.

## Typography

**Font:** San Francisco (system) for everything. SF Mono appears only for raw provider values in full details, the Plex link code, and the GitHub URL.

**Character:** Apple-native and bold at the top. Titles are heavy and large, and everything below them steps down quickly to system text styles.

### Hierarchy
- **Page Title** (bold, 38/52/64pt by idiom, scaled like Large Title): server name on home, library name on grids.
- **Item Title** (bold, 28/38/58pt, scaled like Title): the title on an item page, up to 3 lines.
- **Section Title** (semibold, Title 2; Title 3 on tvOS): shelf names, settings sections, dialog titles.
- **Control**: system glass button labels at the system's default control font.
- **Tile Title** (Headline; semibold Callout on tvOS): titles under tiles, scrolling as a marquee on focus or hover.
- **Body** (Body, Dimmed White): synopses, explanations.
- **Label** (Footnote; Caption on tvOS): tile subtitles, metadata labels, captions.

### Named Rules
**The Dynamic Type Rule.** Titles go through `pageTitleFont()` and `itemTitleFont()`, which scale with the user's reading size. All other text uses system text styles. New text never uses a hard-coded size.

## Layout

There is one full-bleed column per screen, with side gutters that grow per idiom (16pt iPhone, 32pt iPad and Mac, 48pt tvOS). Vertical rhythm uses the section spacing token (24pt iPhone, 32pt iPad and Mac, 48pt tvOS).

- **Home:** stacked horizontal shelves. Posters are 130pt (iPhone) or 180pt (iPad and Mac) wide, and wide tiles 200pt or 280pt. On tvOS, shelves use fixed columns: 6 posters or 4 wide.
- **Library grid:** 2 columns on iPhone, 4 posters or 3 wide on iPad and tvOS, adaptive 180–220pt posters or 260–300pt wide on Mac.
- **Item detail:** landscape splits into 62% details and 38% artwork. Portrait stacks artwork (38% of the height) above scrolling details.
- **Forms, settings, About:** system grouped `Form`s, capped at 1200pt wide on tvOS through `readableFormWidth()`.

## Elevation & Depth

Depth comes from tonal layering on a dark ground, not from shadows. Surfaces stack as translucent white over the gradient or the ambient mesh. Only item-page artwork casts a shadow (black at 35%, 28pt blur, 18pt down), so the poster reads as an object in the room. On tvOS, focus raises tiles through the system image-focus parallax and raises SwiftUI surfaces by scaling them to 102%.

### Named Rules
**The Lights-Down Rule.** Panels and controls stay flat and translucent. Only content (artwork) earns a shadow.

**The System Glass Rule.** Controls use system Liquid Glass: `.buttonStyle(.glass)`, `.glassProminent` for the one primary action, and `UIButton.Configuration.glass()` in tvOS UIKit. Never hand-roll a white-alpha fill for a control.

## Shapes

Every rounded rectangle uses continuous corners. Radii grow with the size of the object: inline surfaces and search artwork 16pt, tiles 18pt (24pt tvOS), cards and list rows 20pt, large artwork and provider buttons 28pt. Control shapes come from system glass (capsules, or circles for icon-only buttons). The progress badge is a 24pt circle.

## Components

### Buttons
- **Character:** system Liquid Glass. `.glassProminent` marks the one primary action on a screen (Play). Everything else, including menus (Filter, Sort, Play All, Seen, Play Options pickers), uses `.glass`.
- **Icon-only:** `.glass` with `.buttonBorderShape(.circle)` (library reordering in Manage).
- **tvOS UIKit:** `UIButton.Configuration.glass()` for Search, the home action row, and the library header menus.
- **Rows in Forms:** plain system row buttons (Connect, Clear Cache, Deactivate with the destructive role).

### Media Tiles (`LibraryItemCard`, `LibraryTileCell`, `LibraryGridCell`)
- **Shape:** artwork in a rounded rectangle (`artwork` radius) at 2:3 for posters or 16:9 for wide tiles, on a Surface placeholder with a dimmed SF Symbol until the image loads.
- **Badge:** Seen Yellow progress pie or check in the bottom-trailing corner.
- **Text:** a marquee title and dimmed subtitle (runtime, plus the added date when sorted by Date Added) under the artwork. On the tvOS home screen there is no per-tile text; the shelf footer shows the focused title.
- **Open Library tile:** a Surface tile with an arrow and "Open Library" that leads each home shelf.

### Item Detail (`MediaView`)
- **Signature component.** It combines the ambient artwork-palette mesh, a faint blurred backdrop, and black gradients that darken toward the text side.
- **Metadata tiles:** label and value pairs on Surface Subtle cards (`card` radius) in a horizontal row that fades at the trailing edge.
- **Child lists:** full-width Surface rows with a title, a progress badge, and a chevron.

### Forms (`ServerManagementPanel`, `JellyfinSetupContent`, `PlexSetupContent`, `AboutPage`)
- System grouped `Form`s with section headers. Text-only rows call `tvOSFocusableRow()` so tvOS can scroll to them. Search uses the system `.searchable` field on every platform.

### Navigation
- System `NavigationStack` push and pop throughout, with system back buttons on every page. The player is presented full screen, full details use a full-screen cover, and Play Options uses a sheet (a custom centered card on iPhone).

## Do's and Don'ts

### Do:
- **Do** let artwork carry color and keep every control and surface neutral.
- **Do** use system components first: menus, alerts, context menus, `.searchable`, `Form` and `List` for settings, AVPlayerViewController.
- **Do** adopt system Liquid Glass for controls, with `.glassProminent` for the one primary action on a screen.
- **Do** use the spacing and radius tokens above. Add a token rather than an inline number.
- **Do** keep the SwiftUI and tvOS UIKit renderings of a surface visually identical, and change them in the same commit.
- **Do** use the yellow seen mark for watch state only.

### Don't:
- **Don't** hand-roll glassmorphism (white-alpha fills and strokes) for new controls.
- **Don't** add a brand hue, gradient text, or colored panels. The ambient artwork mesh is the only signature.
- **Don't** use hard-coded point sizes for text.
- **Don't** make inert elements focusable on tvOS. Focus should land only on things that act.
- **Don't** hide the system navigation bar or back gesture to draw a custom one.
- **Don't** burn subtitles into video, or present server conversion as the default path.
