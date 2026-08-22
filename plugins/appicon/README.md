# AppIcon

Draws a full macOS app icon set in code.

## The problem

An app icon is required for App Store review, and making one by hand means ten exported
images at ten sizes, a listing file that has to agree with them, and a fresh export every
time a colour changes. Worse, the small sizes need different artwork than the large ones —
detail that reads at 512 turns to mud at 16 — and that only becomes visible after the
whole set has been exported and looked at.

## The fix

One small AppKit program. It draws every size natively, writes the `Contents.json`
listing beside the images, and produces a contact sheet of the icon at the sizes people
actually see, on three grounds — white like the App Store page, grey like a wallpaper,
dark like dark mode. Claude opens that sheet and judges the icon the way a user will,
then changes a number and runs it again.

It also carries the traps that cost rounds the first time: the three-byte canvas that
silently draws nothing, `NSImage` doubling sizes on Retina, glyphs that centre by metrics
instead of by their ink.

## Install

```
/plugin marketplace add app368/claude-code-tools
/plugin install appicon@claude-code-tools
```

## Use

Nothing to invoke by hand. When the work turns to the app icon, Claude builds the tool
from the bundled templates, writes the drawing function, and starts looking at the sheet
on its own.

## Limits

- **macOS only.** The size table and the tile shape are macOS-specific. iOS wants a
  single 1024×1024 image with no alpha instead.
- **No Liquid Glass authoring.** On macOS 26 the system dresses a flat icon by itself.
  Controlling those layers means Icon Composer and a `.icon` file, which this does not
  produce.
- **Drawing is code.** Geometry, type and flat shapes are quick; illustration is not.

## License

MIT
