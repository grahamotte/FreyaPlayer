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
  surface-emphasized: "rgba(255, 255, 255, 0.16)"
  surface-border: "rgba(255, 255, 255, 0.12)"
  glass-fill: "rgba(255, 255, 255, 0.12)"
  glass-stroke: "rgba(255, 255, 255, 0.28)"
  seen-yellow: "#FFD60A"
  warning-orange: "#FF9F0A"
  positive-green: "#30D158"
  destructive-red: "#FF453A"
  scrim: "rgba(0, 0, 0, 0.4)"
  modal-scrim: "rgba(0, 0, 0, 0.5)"
typography:
  page-title:
    fontFamily: "SF Pro (system)"
    fontSize: "38pt iPhone / 52pt iPad & Mac / 64pt tvOS"
    fontWeight: 700
  item-title:
    fontFamily: "SF Pro (system)"
    fontSize: "28pt iPhone / 38pt iPad & Mac / 58pt tvOS"
    fontWeight: 700
  section-title:
    fontFamily: "SF Pro (system)"
    fontSize: "Title 2 (Title 3 on tvOS)"
    fontWeight: 600
  control:
    fontFamily: "SF Pro (system)"
    fontSize: "Body"
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
  panel: "34pt"
  control: "36pt"
spacing:
  xxs: "4pt"
  xs: "8pt"
  sm: "12pt"
  md: "16pt"
  lg: "24pt"
  xl: "32pt"
  xxl: "48pt"
components:
  button-glass:
    backgroundColor: "{colors.glass-fill}"
    textColor: "{colors.projection-white}"
    typography: "{typography.control}"
    rounded: "{rounded.control}"
    padding: "16pt 28pt"
  button-glass-focused:
    backgroundColor: "{colors.projection-white}"
    textColor: "{colors.screening-room-floor}"
    rounded: "{rounded.control}"
  button-glass-compact:
    backgroundColor: "{colors.glass-fill}"
    textColor: "{colors.projection-white}"
    rounded: "{rounded.control}"
    padding: "16pt 16pt (iPhone) / 16pt 24pt"
  panel:
    backgroundColor: "{colors.surface}"
    rounded: "{rounded.panel}"
    padding: "16pt (iPhone) / 24pt"
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
  text-field:
    backgroundColor: "{colors.glass-fill}"
    textColor: "{colors.projection-white}"
    height: "48pt"
---

# Design System: Freya Player

<!-- Captured from code on 2026-10-24, before the facelift. Tokens describe the incumbent system. Lines marked "Direction" are confirmed decisions the facelift will apply. -->

## Overview

**Creative North Star: "The Private Screening Room"**

Freya is a dark, quiet room that belongs to you. The lights are down, the chrome stays out of the way, and the collection's own artwork supplies the color. Nothing leaves the room: the interface should feel calm, private, and owned, never like a storefront.

The structure is stock Apple. There is one navigation stack, system menus, alerts, context menus, and AVPlayerViewController for playback. Freya's light signature is ambient color drawn from the artwork, glowing behind the content like the spill from a projector. Everything else is near-black space, white type, and translucent surfaces. Density is low: large artwork, generous gutters, and few controls per screen.

The system was assembled by several hands, so it holds three background treatments, two hand-rolled "glass" button paths (SwiftUI and UIKit), and fixed point sizes alongside Dynamic Type. The facelift should reduce it to one coherent version of the room.

**Key Characteristics:**
- Always dark, with white type at two strengths (full and 72%).
- Artwork is the hero and the only source of saturated color, apart from the yellow "seen" mark.
- Translucent white surfaces at 5%, 8%, 12%, and 16% for layering. There are no colored panels.
- On tvOS, focus inverts a control to solid white, and a focused tile lifts with the system parallax.
- Continuous (squircle) corners everywhere.

## Colors

The palette is near-black and white. Saturated color comes from content, plus one functional accent.

### Primary
- **Seen Yellow** (system yellow): the only interface accent. It marks watched and in-progress state on the pie or check badge, and it tints the Seen/Unseen button in proportion to progress. It is never decoration.

### Neutral
- **Screening Room Top / Floor**: the vertical base gradient behind every screen that has no artwork.
- **Projection White**: primary text and the fill of a focused control.
- **Dimmed White** (72%): secondary text, labels, placeholder icons, and captions.
- **Surface / Subtle / Emphasized**: translucent white layers for tiles and panels at rest (8%), quiet detail tiles (5%), and focused surfaces (16%).
- **Surface Border / Glass Fill / Glass Stroke**: hairline outlines and the fill and stroke of the custom glass buttons.
- **Scrims**: black at 40% behind full-screen details and 50% behind the iPhone Play Options card.

### Functional
- **Warning Orange**: conversions in the Play Options plan, "conditional" capability, dialog errors.
- **Positive Green**: "supported" capability.
- **Destructive Red**: the tint for the Deactivate button.

### Named Rules
**The Projector Rule.** Saturated color on screen comes from the artwork (the ambient mesh, posters, backdrops) or from the seen mark. The interface never adds its own hue for decoration.

**The One Accent Rule.** Seen Yellow means watch state and nothing else. Do not reuse it for selection, links, or emphasis.

## Typography

**Font:** San Francisco (system) for everything. SF Mono appears only for raw provider values in full details, the Plex link code, and the GitHub URL.

**Character:** Apple-native and bold at the top. Titles are heavy and large, and everything below them steps down quickly to system text styles.

### Hierarchy
- **Page Title** (bold, 38/52/64pt by idiom): server name on home, library name on grids. A fixed size today.
- **Item Title** (bold, 28/38/58pt): the title on an item page, up to 3 lines. A fixed size today.
- **Section Title** (semibold, Title 2; Title 3 on tvOS): shelf names, settings sections, dialog titles.
- **Control** (semibold Body): all button and menu labels.
- **Tile Title** (Headline; semibold Callout on tvOS): titles under tiles, scrolling as a marquee on focus or hover.
- **Body** (Body, Dimmed White): synopses, explanations.
- **Label** (Footnote; Caption on tvOS): tile subtitles, metadata labels, captions.

### Named Rules
**The Dynamic Type Rule.** Direction: titles move from fixed point sizes to system text styles, such as Large Title and Title, scaled per idiom, so they follow the user's reading size. New text never uses a hard-coded size.

## Layout

There is one full-bleed column per screen, with side gutters that grow per idiom (16pt iPhone, 32pt iPad and Mac, 48pt tvOS). Vertical rhythm uses the section spacing token (24pt iPhone, 32pt iPad and Mac, 48pt tvOS).

- **Home:** stacked horizontal shelves. Posters are 130pt (iPhone) or 180pt (iPad and Mac) wide, and wide tiles 200pt or 280pt. On tvOS, shelves use fixed columns: 6 posters or 4 wide.
- **Library grid:** 2 columns on iPhone, 4 posters or 3 wide on iPad and tvOS, adaptive 180–220pt posters or 260–300pt wide on Mac.
- **Item detail:** landscape splits into 62% details and 38% artwork. Portrait stacks artwork (38% of the height) above scrolling details.
- **Forms, settings, About:** a centered panel capped at 720pt (1000–1200pt on tvOS; settings 860pt).

## Elevation & Depth

Depth comes from tonal layering on a dark ground, not from shadows. Surfaces stack as translucent white over the gradient or the ambient mesh. Only item-page artwork casts a shadow (black at 35%, 28pt blur, 18pt down), so the poster reads as an object in the room. On tvOS, focus raises tiles through the system image-focus parallax and raises SwiftUI surfaces by scaling them to 102%.

### Named Rules
**The Lights-Down Rule.** Panels and controls stay flat and translucent. Only content (artwork) earns a shadow.

**The System Glass Rule.** Direction (confirmed 2026-10-24): controls adopt system Liquid Glass (`.buttonStyle(.glass)` and `.glassProminent`, plus `glassEffect` for custom chrome) and drop the hand-rolled 12% white fill. The SwiftUI and UIKit paths should both resolve to the system material.

## Shapes

Every rounded rectangle uses continuous corners. Radii grow with the size of the object: inline fields and detail rows 16pt, tiles 18pt (24pt tvOS), cards and list rows 20pt, large artwork 28pt, panels 34pt, and controls 36pt, which makes buttons pill-like at their height. Setup text fields on iOS are full capsules. The progress badge is a 24pt circle.

## Components

### Buttons (`MediaGlassButtonStyle`, `GlassMenuButton`, `applyGlassBackground`)
- **Character:** translucent pills that go solid white when focused on tvOS.
- **Sizes:** regular (16×28pt padding), compact (16×16pt on iPhone, 16×24pt otherwise), square (14pt, icon only), bare (no padding, used by the provider picker).
- **Roles:** standard; tinted (fill at 18% of the tint, stroke at 40%, used by the Seen button); destructive (red tint).
- **States:** pressed scales to 98%; disabled drops to 45% opacity; focused fills solid white with black text and no stroke.
- **Menus** (Filter, Sort, Play All, Seen, Play Options pickers) use the same style with `.menuStyle(.button)`.
- **Direction:** replace with system Liquid Glass. Primary actions such as Play, Resume, and Connect take `.glassProminent`; everything else takes `.glass`.

### Media Tiles (`LibraryItemCard`, `LibraryTileCell`, `LibraryGridCell`)
- **Shape:** artwork in a rounded rectangle (`artwork` radius) at 2:3 for posters or 16:9 for wide tiles, on a Surface placeholder with a dimmed SF Symbol until the image loads.
- **Badge:** Seen Yellow progress pie or check in the bottom-trailing corner.
- **Text:** a marquee title and dimmed subtitle (runtime, plus the added date when sorted by Added At) under the artwork. On the tvOS home screen there is no per-tile text; the shelf footer shows the focused title.
- **Open Library tile:** a Surface tile with an arrow and "Open Library" that leads each home shelf.

### Item Detail (`MediaView`)
- **Signature component.** It combines the ambient artwork-palette mesh, a faint blurred backdrop, and black gradients that darken toward the text side.
- **Metadata tiles:** label and value pairs on Surface Subtle cards (`card` radius) in a horizontal row that fades at the trailing edge.
- **Child lists:** full-width Surface rows with a title, a progress badge, and a chevron.

### Panels (`PanelBackground`, `ServerManagementSection`)
- A Surface fill with a hairline Surface Border at the `panel` radius. Panels hold setup forms, settings sections, and About.

### Inputs (`JellyfinSetupContent`, `ServerSearchPage`)
- On iOS, setup fields are 48pt capsules with a Glass Fill and Glass Stroke, and a white stroke when focused. The iOS search field is a `glassField` (Surface fill, 16pt radius, 2pt white stroke when focused). tvOS uses system fields and `.searchable`.

### Navigation
- System `NavigationStack` push and pop throughout. Full-screen covers are used for playback and full details, and sheets for Play Options (a custom centered card on iPhone). The iOS Search page replaces the navigation bar with its own Back button.

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
