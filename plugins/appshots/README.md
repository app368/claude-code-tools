# AppShots

Draws App Store screenshots in code instead of capturing the screen.

## The problem

Store screenshots have to be exactly one of four pixel sizes, carry no alpha channel, and
stay legible when the store squeezes them to a fraction of their size. Capturing them by
hand fights all three: a hand-drawn selection is never pixel-exact, a capture inherits
whatever the display and the window were doing, and one changed word means recapturing
the whole set.

And some apps have nothing to capture. A menu bar utility has no interface to show; its
entire result happens inside somebody else's window.

## The fix

Draw the frame whole. A backing plate at the exact required size, a card on it, and
inside the card the thing the app actually does. The size is right by construction, the
composition is a few numbers, and a revision is a rerun rather than a photo session.

Bundled with the decisions that make such a frame readable — stacked rather than
side-by-side, type fitted to the width, the alpha stripped at the end — and with the
traps that cost rounds the first time.

## Install

```
/plugin marketplace add app368/claude-code-tools
/plugin install appshots@claude-code-tools
```

## Use

Nothing to invoke by hand. When the work turns to store screenshots, Claude builds the
tool from the bundled templates, writes the frame composition, and looks at every frame
before you do.

## Limits

- **macOS sizes only** in the bundled template. iOS and iPadOS sizes differ by device
  generation and have to be looked up.
- **Drawn frames, not captures.** If the app's own interface is the selling point, a real
  capture placed on the plate is the better route.
- **Drawing is code.** Type, shapes and layout are quick; illustration is not.

## License

MIT
