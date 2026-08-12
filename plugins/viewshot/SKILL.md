---
name: viewshot
description: Renders a single AppKit or UIKit view to PNG without launching the app. Use whenever the work touches layout — padding, alignment, sizes, element positions, dark mode. Without it the layout is invisible and every fix costs a round trip through a human screenshot.
---

# ViewShot

## When to use it

Any time the task is about **how something looks**: building a screen, fixing a
margin, aligning an element, checking dark mode, positioning a cursor in an animation.

The signal that you need it right now: you are about to ask the user to build the app
and send a screenshot. Build the viewshot instead.

**Build it immediately, not after the tenth round trip.** It takes about fifteen
minutes and saves hours — with it you catch three layout bugs per pass, before the
user ever sees them.

## What it is

A tiny program that creates the view, sets its state, and asks the system to draw it
into a PNG. It shows nothing on screen and never launches the real app.

The system draws it with the same machinery it uses for a real window, so the image is
exact: fonts, spacing, colors, corner radii as they will be.

## How to build it

1. Create `Tools/ViewShot/` **outside the sources directory**. This matters: Xcode 16
   pulls everything under the sources directory into the target, and a second
   `main.swift` in there breaks the build.
2. Copy `templates/main.swift` and `templates/snapshot.sh` from this skill into it.
3. In `snapshot.sh`, list the project files your view needs in `NEEDED`, and point
   `SOURCES` at the sources directory. Unknown-symbol error means a file is missing
   from the list.
4. In `main.swift`, replace `ViewUnderTest` with your view and rewrite the `shot(...)`
   calls — one per frame, each setting its own state.
5. `chmod +x snapshot.sh`, run it, then **open the PNGs and look at them yourself**.

This works when the needed files are **closed over their dependencies** — they don't
drag in half the app. View code usually is.

## What it can't do

**No motion.** Every frame is frozen; you set the state by hand.

**No animation in flight.** The system draws the state stored in properties, not what
a viewer sees mid-animation. Timing and ordering bugs are caught by temporary logging
with timestamps, not here.

**Set the appearance explicitly.** Otherwise it follows the system theme and frames
come out different on different days.

## Afterwards

Leave `Tools/ViewShot/` in the project with a short README — it will be needed again.
Add `out/` and the compiled binary to `.gitignore`.
