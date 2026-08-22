import AppKit
import CoreText

// AppIcon: draws the macOS icon set and the listing that goes with it.
//
// All artwork is expressed in fixed 1024×1024 coordinates; every image is then
// rendered at its own pixel count. Two things change per project: the colours
// and the art function.
//
// Run:  ./icon

// MARK: - Where it goes

/// Finished images go straight into the app — an icon is part of the build,
/// not a working file. Path from the tool folder to the icon set
let iconSet = "../../YOUR_PROJECT/YOUR_PROJECT/Assets.xcassets/AppIcon.appiconset"

// MARK: - Shared

/// Fixed drawing coordinates. Everything is measured in these, whatever the pixel size
let side: CGFloat = 1024

/// The macOS icon shape: a rounded square with a margin around it.
/// The margin leaves the system room for shadow and highlights
let shapeInset: CGFloat = 100
let shapeRadius: CGFloat = 185

// Colours — change these
let tileColor = NSColor(calibratedRed: 0.909, green: 0.894, blue: 0.871, alpha: 1)
let inkColor = NSColor(calibratedWhite: 0.12, alpha: 1)
let frameColor = NSColor(calibratedWhite: 0.72, alpha: 1)

/// Makes a canvas.
///
/// Always four bytes per pixel: the macOS drawing machinery can only write into
/// a four-byte one and silently refuses a three-byte one — leaving a black file
func makeCanvas(_ size: NSSize) -> NSBitmapImageRep? {
    NSBitmapImageRep(bitmapDataPlanes: nil,
                     pixelsWide: Int(size.width), pixelsHigh: Int(size.height),
                     bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                     isPlanar: false, colorSpaceName: .deviceRGB,
                     bytesPerRow: 0, bitsPerPixel: 0)
}

/// Draws the icon directly at the intended pixel count.
///
/// The canvas is created at the real size and scaled to fit the fixed coordinates,
/// so every image comes out crisp instead of downscaled from a large one.
/// Do not route this through NSImage: on Retina it silently doubles the size
func render(_ body: () -> Void, pixels: CGFloat) -> NSBitmapImageRep? {
    guard let canvas = makeCanvas(NSSize(width: pixels, height: pixels)),
          let context = NSGraphicsContext(bitmapImageRep: canvas) else { return nil }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    context.cgContext.scaleBy(x: pixels / side, y: pixels / side)
    body()
    NSGraphicsContext.restoreGraphicsState()
    return canvas
}

/// Draws a glyph centred on a point — centred by its ink.
///
/// Font metrics will not do: many glyphs carry empty space below, and centring
/// by ascender and descender pushes the glyph upward
func drawGlyph(_ text: String, centeredAt point: NSPoint, font: NSFont, color: NSColor) {
    let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
    let line = CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: attributes))
    let ink = CTLineGetImageBounds(line, nil)
    guard let context = NSGraphicsContext.current?.cgContext else { return }
    context.saveGState()
    context.textPosition = CGPoint(x: point.x - ink.midX, y: point.y - ink.midY)
    CTLineDraw(line, context)
    context.restoreGState()
}

/// The icon tile
@discardableResult
func drawTile(_ fill: NSColor = tileColor) -> NSRect {
    let box = NSRect(x: shapeInset, y: shapeInset,
                     width: side - shapeInset * 2, height: side - shapeInset * 2)
    fill.setFill()
    NSBezierPath(roundedRect: box, xRadius: shapeRadius, yRadius: shapeRadius).fill()
    return box
}

/// A hairline frame along the tile edge.
///
/// Small sizes need it: against the white App Store page a light tile blends
/// into the background and the artwork floats with no boundary
func drawTileFrame(_ box: NSRect, color: NSColor, width: CGFloat) {
    let path = NSBezierPath(roundedRect: box.insetBy(dx: width / 2, dy: width / 2),
                            xRadius: shapeRadius, yRadius: shapeRadius)
    path.lineWidth = width
    color.setStroke()
    path.stroke()
}

// MARK: - Artwork

/// THIS IS WHERE EVERYTHING CHANGES. Picks the artwork for a size.
///
/// Detailed when large, simplified when small. Apple does the same: at 16 and 32
/// detail turns to mud, so features are removed rather than shrunk.
/// Keep the frame about one pixel wide at every size
func art(for pixels: CGFloat) -> () -> Void {
    switch pixels {
    case ...32:
        return {
            let box = drawTile()
            drawTileFrame(box, color: frameColor, width: side / pixels * 1.2)
            // The simplest possible artwork: one large shape
            drawGlyph("A", centeredAt: NSPoint(x: box.midX, y: box.midY),
                      font: .systemFont(ofSize: 520, weight: .bold), color: inkColor)
        }
    default:
        return {
            let box = drawTile()
            drawGlyph("A", centeredAt: NSPoint(x: box.midX, y: box.midY),
                      font: .systemFont(ofSize: 520, weight: .bold), color: inkColor)
        }
    }
}

// MARK: - The set

/// The macOS set: five sizes, each at 1x and 2x.
/// Do not ship fewer than ten images — the system fills the gaps by
/// downscaling, and it shows
struct Item {
    let size: Int
    let scale: Int
    var pixels: CGFloat { CGFloat(size * scale) }
    var file: String { "icon_\(size)x\(size)\(scale == 2 ? "@2x" : "").png" }
}

let wanted: [Item] = [
    Item(size: 16, scale: 1), Item(size: 16, scale: 2),
    Item(size: 32, scale: 1), Item(size: 32, scale: 2),
    Item(size: 128, scale: 1), Item(size: 128, scale: 2),
    Item(size: 256, scale: 1), Item(size: 256, scale: 2),
    Item(size: 512, scale: 1), Item(size: 512, scale: 2),
]

try? FileManager.default.createDirectory(atPath: iconSet, withIntermediateDirectories: true)

var made: [(CGFloat, NSBitmapImageRep)] = []
for item in wanted {
    guard let rep = render(art(for: item.pixels), pixels: item.pixels) else { continue }
    if let png = rep.representation(using: .png, properties: [:]) {
        try? png.write(to: URL(fileURLWithPath: "\(iconSet)/\(item.file)"))
        print("wrote \(item.file) — \(Int(item.pixels)) pixels")
    }
    made.append((item.pixels, rep))
}

// The listing: how Xcode learns which image belongs to which size
let listing = wanted.map { item in
    """
        {
          "filename" : "\(item.file)",
          "idiom" : "mac",
          "scale" : "\(item.scale)x",
          "size" : "\(item.size)x\(item.size)"
        }
    """
}.joined(separator: ",\n")

let contents = """
{
  "images" : [
\(listing)
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}

"""
try? contents.write(toFile: "\(iconSet)/Contents.json", atomically: true, encoding: .utf8)
print("wrote Contents.json")

// MARK: - Contact sheet

/// Shows the icon at the sizes people will see and on the grounds it will land on.
/// Judge by the small image on white, not by the large one in an editor
let sheetSizes: [CGFloat] = [256, 128, 64, 32, 16]
let grounds: [NSColor] = [NSColor(calibratedWhite: 1.0, alpha: 1),
                          NSColor(calibratedWhite: 0.70, alpha: 1),
                          NSColor(calibratedWhite: 0.16, alpha: 1)]
let gap: CGFloat = 50
let rowHeight: CGFloat = 256 + gap
let sheetWidth = sheetSizes.reduce(gap) { $0 + $1 + gap }
let sheetHeight = rowHeight * CGFloat(grounds.count) + gap

if let sheet = makeCanvas(NSSize(width: sheetWidth, height: sheetHeight)),
   let context = NSGraphicsContext(bitmapImageRep: sheet) {
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context

    for (row, ground) in grounds.enumerated() {
        let top = sheetHeight - gap - CGFloat(row) * rowHeight
        ground.setFill()
        NSBezierPath(rect: NSRect(x: 0, y: top - 256 - gap / 2,
                                  width: sheetWidth, height: 256 + gap)).fill()
        var x = gap
        for size in sheetSizes {
            // Use the image drawn at that size, not a downscaled one, or the
            // whole point of separate small artwork is invisible
            if let rep = made.first(where: { $0.0 == size })?.1
                ?? render(art(for: size), pixels: size) {
                let image = NSImage(size: NSSize(width: size, height: size))
                image.addRepresentation(rep)
                let y = top - 256 / 2 - size / 2
                image.draw(in: NSRect(x: x, y: y, width: size, height: size))
            }
            x += size + gap
        }
    }
    NSGraphicsContext.restoreGraphicsState()
    try? FileManager.default.createDirectory(atPath: "out", withIntermediateDirectories: true)
    if let png = sheet.representation(using: .png, properties: [:]) {
        try? png.write(to: URL(fileURLWithPath: "out/sheet.png"))
        print("wrote out/sheet.png — look at it")
    }
}
