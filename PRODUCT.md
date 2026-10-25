# Product

<!-- impeccable:product-schema 1 -->

## Platform

ios

The app is a native Apple app built with SwiftUI and UIKit. It ships to tvOS, iOS, iPadOS, and Mac Catalyst from one codebase. All four targets carry equal weight: when they conflict, each one gets its own native best answer and none of them wins by default.

## Users

People who run their own Plex or Jellyfin media server and want to watch their own collection on Apple devices. They watch from a couch with a Siri Remote, on a phone or iPad in bed or on the move, and on a Mac at a desk. They are usually technical enough to host a server, but once setup is done they expect the app to work like any other Apple app.

## Product Purpose

Freya Player plays everything Apple supports natively, and plays it exceptionally well. It asks the server to convert a file only when Apple genuinely can't play it. Success looks like this: connect once, browse a familiar library, press Play, and get native AVKit playback with correct resume, watched state, audio, and subtitle choices.

## Positioning

A small, native client that feels like it came with the device. The app is free, has no ads or upsell, and is open source. It is private by default: data stays on the device, and there is no analytics, telemetry, or crash reporter. It favors direct-play through Apple's own player over server transcoding, and it never burns in subtitles.

## Operating Context

- Setup: Jellyfin connects with an address, port, username, and password. Plex uses the plex.tv/link code flow, which comes after an explicit notice that Plex involves third-party services.
- Daily use: start on the libraries home, open a library grid or search, open an item, and play. Use long-press quick actions to play or mark items seen.
- Maintenance: Manage covers reordering and hiding libraries, clearing the cache, reviewing playback capabilities, and deactivating the server.

## Capabilities and Constraints

- Providers: Jellyfin (recommended) and Plex. One connected server at a time.
- Item kinds: movie, series, season, episode, other. Posters are used for movies, series, and seasons. Landscape artwork is used for episodes and other items.
- Watch state is called "Seen/Unseen" in the UI. Changes apply optimistically and roll back on failure.
- Playback uses the stock AVPlayerViewController. There are Play Options (quality, audio, subtitles) and an honest per-item conversion plan.
- Apple platform conventions come first: SwiftUI, AVKit, Foundation networking, and UIKit only where tvOS focus or collection views require it.
- Freya Player is dark-only by decision (confirmed 2026-10-24): the screening-room look applies everywhere, and there is no light appearance.

## Brand Commitments

- Name: Freya Player. Logo asset: the `FreyaLogo` image set in the asset catalog. Logo source art lives in `assets/`. Provider marks: `Jellyfin`, `Plex` image sets.
- Voice: plain, warm, and a little wry. The About page says "no plus premium max whatever". It is direct about privacy and candid about Plex's tradeoffs.
- Feel: stock Apple foundations with a light Freya signature (confirmed 2026-10-24). The signature should be one recognizable touch, used sparingly, never a reskin.
- Controls move to the system Liquid Glass materials (confirmed 2026-10-24).

## Evidence on Hand

- App Store listing: https://apps.apple.com/us/app/freya-player/id6761883699
- Screenshots: `apps/screenshots/` and `assets/screenshots/`. They predate current UI copy.
- Sample artwork is public-domain film posters in the screenshots. There are no testimonials, reviews, user counts, or press, and none should be invented.

## Product Principles

1. Native first. If Apple ships a control, material, or behavior for it, use that.
2. The collection is the interface. Artwork and titles carry the screen, and chrome recedes.
3. Honest playback. Show what will direct-play and what will be converted. Never burn in subtitles.
4. Private by construction. Nothing leaves the device except what the user's server needs.
5. Least code that solves it well. Write one shared component rather than one per platform wherever focus behavior allows.
