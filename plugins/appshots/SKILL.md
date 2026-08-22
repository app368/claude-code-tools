---
name: appshots
description: Draws App Store screenshots in code rather than capturing the screen — exact frame size, no transparency, backing plate and card. Use whenever a store page needs screenshots, or when Connect refuses to accept them.
---

# AppShots

## When to use it

The moment a store page needs screenshots. For Mac apps they are **required** — a build
without them will not be submitted, unlike preview videos.

The second trigger: **Connect refused the images**. The reason is almost always one of
two — a size that is not on the list, or transparency.

## The decision that matters: draw, do not capture

A store screenshot does not have to be a picture of a screen. For a menu bar utility it
cannot be one: there is nothing to show — no interface, and all the work happens inside
other people's windows.

So the frame is **drawn whole**: a backing plate at the exact required size, a card on
it, and inside the card whatever the app does. Three gains:

- the frame no longer depends on display resolution or what happened to be in the window;
- the size comes out exact with no fitting;
- an edit is an edit to a number, not a fresh round of captures.

If the app does have something to show on screen, a capture makes more sense — but even
then it is worth placing it on a drawn plate of the required size, so the frame size
stops being a problem.

## What Apple requires

**The frame is exactly one of four sizes**, 16:10: 1280×800, 1440×900, 2560×1600,
2880×1800. Take the largest — downscaling is always available. iOS and iPadOS sizes are
different and depend on device generation; do not quote them from memory, look them up.

**No transparency.** No alpha channel at all.

**Format** — png, jpg or jpeg. **Count** — 1 to 10.

Gallery order comes from how the images are dragged into Connect; Apple does not read
filenames.

## Two traps that cost real rounds

**A three-byte-per-pixel canvas silently refuses to draw.** `NSBitmapImageRep` with
`samplesPerPixel: 3` is created without error, but no `NSGraphicsContext` can be built
over it, drawing goes nowhere, and uninitialised memory lands in the file — a black
rectangle. Draw into a four-byte canvas and strip the alpha at the end by rewriting
pixels.

**Lines sit by font metrics, not by the size of what was drawn.** Rendered height varies
by alphabet — Greek capitals are taller than Latin — so measuring the drawn text makes
lines drift up and down from frame to frame. Take half-height as
`(ascender - descender) / 2`.

## How to compose a frame

**Stack, do not place side by side.** When showing a "before → after", put the parts one
above the other. Each line then gets the full width of the card and the type comes out
two to three times larger. This is arithmetic, not taste: the store shows a screenshot
about six hundred points wide, so the frame is squeezed fivefold. Small text there does
not get read.

**Fit the type to the width instead of fixing it.** Strings differ in length, and one
number for every frame will either clip the long one or shrink the short one to nothing.

**Measure the text box with room for everything around it.** Selection fills, field
borders and icons all extend past the string, and without slack they collide with the
edge.

**Look at the result.** Open the finished PNG via Read and look. Numbers lie: a layout
can be arithmetically correct and still crooked.

## How to work

1. Build the tool from `templates/` in `Tools/ShotStage/`, **outside the sources folder**.
2. Point `outputFolder` at the store materials folder, not next to the tool.
3. Fill in the frame list and write `drawContent` — the contents of the card.
4. Run it and look at every frame.
5. Check size and transparency: `sips -g pixelWidth -g pixelHeight -g hasAlpha`.

## Afterwards

**Keep the finished frames in git**: they are light, around a hundred kilobytes each, and
it is useful to have exactly the files that went to Connect. Keep the tool in the project
and add `bin/` to `.gitignore`.
