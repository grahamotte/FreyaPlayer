---
version: 1
slug: "apps-apple-app"
primary_target: "apps/apple/App"
related_targets: []
---

## Scope

The Freya Player Apple app (tvOS, iOS, iPadOS, Mac Catalyst). Visitor mode: Operate. The user browses their own library, finds a title, and plays it.

## Direction contract

THESIS: a native Apple media client whose room takes its color from the artwork in view. It refuses the random-color mesh and hand-rolled glass the previous version used.

OWN-WORLD: a near-black ground lit by an animated mesh tinted from artwork. The mesh blends in place over 1.4s after a 300ms debounce, and switches instantly with Reduce Motion. Type is white SF at 100% and 72%. Surfaces are translucent white at 5%, 8% and 16%, and controls are system Liquid Glass. One accent, Freya Gold #E3AF32, appears only on the viewer's own path: the Play and Play All pill, watch progress, and the watched check.

STORY: the visitor sees their collection lit by its own artwork, understands that the app plays it natively, and opens a library or a title and presses the gold Play.

FIRST VIEWPORT: Home. On iOS and Mac, the server name is the system large title, with Search and More in the toolbar. Below it are shelves that each start with an Open Library tile, the same size as a poster and captioned with the item count, followed by posters with titles. On tvOS, a glass Search button sits beside the title, and the focused poster shows its title beneath it. The room takes its color from the lead or focused artwork.

FORM: the user pinned this direction through structured questions on 2026-10-24: stock Apple structure with a light Freya signature, system Liquid Glass, North Star "The Private Screening Room", and the signature "lit by focused artwork". The roll was run afterward, and the pinned direction beats it. seed:3ea0756f04759822

FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance.

## Signature interaction

When focus or hover moves between posters, the room blends to the new artwork's palette. Tapping a poster on iOS, iPadOS, or Mac zooms its artwork into the item page.

## Unresolved

Light appearance is not supported; whether to add it is the user's decision.
