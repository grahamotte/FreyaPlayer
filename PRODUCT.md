# Product

<!-- impeccable:product-schema 1 -->

## Platform

ios

## Users

People who run their own Plex or Jellyfin server and want to watch their personal library on Apple devices. tvOS, iOS, iPadOS, and Mac Catalyst are equally important; no device is secondary.

## Product Purpose

Freya Player is a native Apple client for personal Plex and Jellyfin servers. Its goal is to play everything Apple supports natively, exceptionally well. It uses server-side conversion only for media Apple genuinely cannot play. Success means that browsing and playback feel as if Apple built the app.

## Positioning

Freya Player keeps native playback first and stock platform behavior everywhere. It uses AVKit playback, standard focus and navigation, and system search. Plex and Jellyfin get identical functionality behind one app-owned model. It never burns in subtitles.

## Operating Context

- The user connects to their own server by choosing Plex or Jellyfin, then entering a server URL and credentials. Freya Player provides no server and no content.
- Main flow: libraries shown as shelves, then library, then item detail, then playback. Search runs locally over cached titles across all visible libraries.
- Watched state updates optimistically and syncs back to the server. Playback progress reports to the server.
- tvOS is driven by the Siri Remote and focus. iOS and iPadOS use touch. Mac Catalyst uses pointer and window.

## Capabilities and Constraints

- Targets: tvOS, iOS and iPadOS, Mac Catalyst. Built with SwiftUI and AVKit. UIKit is used only where tvOS focus or collection-view behavior requires it.
- Providers: Plex and Jellyfin, with the same features for both.
- Never burns in subtitles.
- The website (`frontend/subdomains/www`) is currently a placeholder.

## Brand Commitments

- Name: Freya Player.
- Voice: simple, clear, no-nonsense.
- Free and open source under MIT. No purchases, subscriptions, or in-app payments.
- No tracking, no analytics, no Freya account. The app talks only to the user's own server.
- The brand is the stock Apple feel. Personality stays minimal.
- The yellow accent on progress, watched, and seen controls is part of the identity.
- Logo: `assets/logo-v2.png` (current) and `assets/logo.png` (earlier).

## Evidence on Hand

- App Store listing: https://apps.apple.com/us/app/freya-player/id6761883699
- Store metadata and release configuration: `apps` in `config.json`
- Screenshots: `assets/screenshots/` (iOS, macOS, tvOS, repo) and `apps/screenshots/`
- Provider marks: `assets/plex.svg`, `assets/jellyfin.svg`
- Public-domain sample media: `assets/samples/` (sources in `sources.txt`)
- Privacy policy: `docs/privacy-policy.md`
- There are no testimonials, user counts, press, or benchmarks. Do not fabricate any.

## Product Principles

1. Native first: play what Apple plays directly, and convert only when Apple cannot.
2. Stock over custom: prefer platform behavior, controls, and focus over invented UI.
3. Every device is a first-class device.
4. The user's server, the user's data: no accounts, no tracking, no middleman.
5. Least code that solves the problem well.
