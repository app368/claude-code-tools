# ViewShot

Renders a single AppKit or UIKit view to PNG without launching the app.

## The problem

Claude Code cannot see your screen. When it writes layout code, it is working blind:
edit, ask you to build, wait for a screenshot, guess. Every margin costs a round trip
through a human.

## The fix

A tiny program that builds one view, sets its state, and asks the system to draw it
into a PNG. Claude opens the PNG and looks at it directly. Rounds that took minutes
take seconds, and layout bugs are caught before you ever see them.

The image is drawn by the system with the same machinery it uses for a real window,
so it is exact — not an approximation.

## Install

```
/plugin marketplace add app368/claude-code-tools
/plugin install viewshot@claude-code-tools
```

## Use

Nothing to invoke by hand. When the work touches layout, Claude builds the viewshot
from the bundled templates, points it at the view in question, and starts looking at
frames on its own.

## Limits

- **No motion.** Every frame is frozen; state is set explicitly.
- **No animation in flight.** The system draws what is stored in properties, not what
  a viewer sees mid-animation. Timing bugs need logging with timestamps instead.
- **macOS only** in this version. The same approach works for UIKit through
  `UIGraphicsImageRenderer`, but the bundled template is AppKit.

## License

MIT
