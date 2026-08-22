---
name: appicon
description: Draws a macOS app icon set in code — ten sizes, the Contents.json listing, simplified artwork at small sizes. Use whenever an app needs its icon made or reworked, and when an icon fails to appear in Finder or is rejected by the build.
---

# AppIcon

## When to use it

The moment a macOS app needs its icon. It is required for App Store review and cannot be
left for later: a build without one will not be accepted.

The second trigger: **the icon does not show up** — a blank page in Finder, a build
warning about missing sizes, a refusal from App Store Connect.

## What it is

An AppKit program that draws all ten images of the set and writes the listing beside
them. No graphics editor involved: changing a colour or a size is changing a number and
running again — seconds, not a round trip.

Build it from `templates/` in `Tools/IconStage/`, **outside the sources folder**. Xcode
sweeps everything inside that folder into the build, and a second `main.swift` in there
breaks the app.

## What to know before drawing

**The set is ten images.** Five sizes, each at 1x and 2x: 16, 32, 128, 256, 512 points —
16 to 1024 pixels. Do not ship fewer: the system will fill the gaps by downscaling, and
it shows.

**Small sizes are drawn separately, not shrunk.** At 16 and 32 detail turns to mud. The
right move is to remove things: make a thin outline solid, drop a small shape entirely,
keep the silhouette. Apple does the same in its own apps, and size-specific artwork is
not grounds for rejection — provided it still reads as the same icon, not two different
ones.

**A macOS icon needs transparency.** Outside the rounded tile there is nothing. The
"no alpha channel" rule applies to store screenshots, not to the icon.

**You draw the tile yourself.** macOS does not round the corners for you: the shape is
part of the artwork. Leave a margin around it for the system's shadow and highlights,
roughly a tenth of the side.

**On macOS 26 the system dresses the icon** — glass bevel, gradient, glow, shadow. That
applies to large sizes on the new system only; on earlier ones the icon stays flat.
Nothing extra to draw for it. To control the glass, that is Icon Composer and a layered
`.icon` file — separate work; a plain image set is still accepted.

## Three traps that cost real rounds

**A three-byte-per-pixel canvas silently refuses to draw.** `NSBitmapImageRep` with
`samplesPerPixel: 3` is created without error, but no `NSGraphicsContext` can be built
over it, drawing goes nowhere, and uninitialised memory lands in the file — a black
rectangle. Always draw into a four-byte canvas; strip alpha afterwards if you need it
gone.

**`NSImage` doubles the size on a Retina display.** Ask for 1024, get 2048 — and Apple
wants exact. Draw into an `NSBitmapImageRep` of the intended pixel count, scaling fixed
coordinates into it.

**A glyph centres by its ink, not by font metrics.** Many glyphs carry empty space below,
and centring by ascender and descender pushes the artwork up. Measure with
`CTLineGetImageBounds`.

## How to work

1. Build the tool from `templates/`, fix the `iconSet` path to the `AppIcon.appiconset`.
2. Write `art(for:)` — the artwork and its simplifications for small sizes.
3. Run it and look at `out/sheet.png` **with your own eyes** via Read: the icon at the
   sizes people see, on three grounds — white like the App Store page, grey like a
   wallpaper, dark like dark mode.
4. Judge by the small image on white, not the large one. A light tile disappears against
   a white page; a hairline grey frame, about a pixel wide, fixes it.
5. Build the app with `xcodebuild` and confirm an `AppIcon.icns` came out. Xcode
   complains when the listing and the files disagree.
6. Pull the `.icns` out of the built app and look at it. That is the only honest check
   that what you drew is what shipped.

## The menu bar icon is a different thing

If the app has a menu bar item, the icon set does **not** apply to it: that image is set
separately in code. It must be a template image — a single-colour silhouette the system
tints for the current appearance. A colour icon there breaks: dark parts become holes in
dark mode. The simplest route is a system symbol via `NSImage(systemSymbolName:)`, chosen
to echo the app icon.

## Afterwards

Keep the tool in the project — icons get revised. Add `bin/` and `out/` to `.gitignore`,
but **keep the icon images in git**: they are small and they are part of the build.
