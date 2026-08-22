import AppKit
import CoreText

// AppShots: draws App Store screenshots in code.
//
// The frame is built whole: a backing plate at the exact size, a white card on it,
// and inside the card whatever is being shown. Nothing is captured from the screen,
// so the frame is independent of display resolution and is redone in seconds.
//
// Run:  ./shots        every frame
//       ./shots 3      only the third

// MARK: - What is shown

/// THIS IS WHERE EVERYTHING CHANGES. One store frame
struct Frame {
    let top: String
    let bottom: String
}

let frames: [Frame] = [
    Frame(top: "before", bottom: "after"),
]

/// Finished frames go to the store materials folder, not next to the tool:
/// screenshots are a deliverable, not a working file
let outputFolder = "../../AppStore/screenshots"

// MARK: - Metrics

enum Metrics {
    /// Apple's rule for Mac screenshots: 16:10, and exactly one of four sizes —
    /// 1280×800, 1440×900, 2560×1600, 2880×1800. Take the largest: downscaling is
    /// always available, upscaling invents nothing.
    /// iOS and iPadOS sizes differ — look them up
    static let frame = NSSize(width: 2880, height: 1800)
    /// Margin from the frame edge to the card
    static let inset: CGFloat = 150
    static let cardRadius: CGFloat = 40
    /// Margin from the card edge to the line
    static let sideInset: CGFloat = 120
    /// The ceiling: without it short lines sprawl across the whole card
    static let lineMaxFont: CGFloat = 200
}

// Colours — change these
let ground = NSColor(calibratedRed: 0.909, green: 0.894, blue: 0.871, alpha: 1)
let ink = NSColor(calibratedWhite: 0.12, alpha: 1)
let faded = NSColor(calibratedWhite: 0.52, alpha: 1)

// MARK: - Canvas

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

/// Strips the alpha — Apple does not accept screenshots with transparency.
/// The frame is opaque throughout, so the channel is simply dropped
func dropAlpha(_ source: NSBitmapImageRep) -> NSBitmapImageRep? {
    guard let opaque = NSBitmapImageRep(bitmapDataPlanes: nil,
                                        pixelsWide: source.pixelsWide, pixelsHigh: source.pixelsHigh,
                                        bitsPerSample: 8, samplesPerPixel: 3, hasAlpha: false,
                                        isPlanar: false, colorSpaceName: .deviceRGB,
                                        bytesPerRow: source.pixelsWide * 3, bitsPerPixel: 24),
          let from = source.bitmapData, let to = opaque.bitmapData else { return nil }
    for y in 0..<source.pixelsHigh {
        for x in 0..<source.pixelsWide {
            let a = y * source.bytesPerRow + x * 4
            let b = y * opaque.bytesPerRow + x * 3
            to[b] = from[a]; to[b + 1] = from[a + 1]; to[b + 2] = from[a + 2]
        }
    }
    return opaque
}

// MARK: - Text

/// Finds the font size at which the line fits the given width
func fittingFont(_ text: String, width: CGFloat, max: CGFloat) -> NSFont {
    var size = max
    while size > 20 {
        let font = NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
        if (text as NSString).size(withAttributes: [.font: font]).width <= width { break }
        size -= 2
    }
    return .monospacedSystemFont(ofSize: size, weight: .regular)
}

/// Half the line height — taken from the font, not from what was drawn.
///
/// Rendered height varies by alphabet, and measuring the drawing makes lines
/// drift up and down from frame to frame
func lineHalf(_ font: NSFont) -> CGFloat {
    (font.ascender - font.descender) / 2
}

/// Draws a line with its middle sitting exactly on centerY
func drawLine(_ text: String, centerY: CGFloat, color: NSColor, font: NSFont,
              centerX: CGFloat? = nil) {
    let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
    let width = (text as NSString).size(withAttributes: attributes).width
    (text as NSString).draw(at: NSPoint(x: (centerX ?? Metrics.frame.width / 2) - width / 2,
                                        y: centerY - lineHalf(font)),
                            withAttributes: attributes)
}

// MARK: - Frame

/// THIS IS WHERE EVERYTHING CHANGES. Builds the contents of the card.
///
/// Stacked top to bottom rather than side by side: each line gets the full width
/// of the card, and the type comes out two to three times larger.
/// The store shows a screenshot about six hundred points wide — the frame is
/// squeezed fivefold, so legibility beats composition
func drawContent(_ frame: Frame, card: NSRect) {
    let width = card.width - Metrics.sideInset * 2
    let font = fittingFont(frame.top.count > frame.bottom.count ? frame.top : frame.bottom,
                           width: width, max: Metrics.lineMaxFont)
    let half = lineHalf(font)
    let gap: CGFloat = 220

    drawLine(frame.top, centerY: card.midY + gap / 2 + half, color: faded, font: font)
    drawLine(frame.bottom, centerY: card.midY - gap / 2 - half, color: ink, font: font)
}

/// Builds the whole frame and writes it
func draw(_ frame: Frame, to file: String) {
    guard let canvas = makeCanvas(Metrics.frame),
          let context = NSGraphicsContext(bitmapImageRep: canvas) else { return }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context

    ground.setFill()
    NSBezierPath(rect: NSRect(origin: .zero, size: Metrics.frame)).fill()
    let card = NSRect(x: Metrics.inset, y: Metrics.inset,
                      width: Metrics.frame.width - Metrics.inset * 2,
                      height: Metrics.frame.height - Metrics.inset * 2)
    NSColor.white.setFill()
    NSBezierPath(roundedRect: card, xRadius: Metrics.cardRadius, yRadius: Metrics.cardRadius).fill()

    drawContent(frame, card: card)

    NSGraphicsContext.restoreGraphicsState()

    guard let opaque = dropAlpha(canvas),
          let png = opaque.representation(using: .png, properties: [:]) else { return }
    try? png.write(to: URL(fileURLWithPath: file))
    print("wrote \(file)")
}

// MARK: - Run

try? FileManager.default.createDirectory(atPath: outputFolder, withIntermediateDirectories: true)

let picked = Int(CommandLine.arguments.dropFirst().first ?? "")
for (index, frame) in frames.enumerated() {
    let number = index + 1
    if let picked, picked != number { continue }
    draw(frame, to: String(format: "\(outputFolder)/shot-%02d.png", number))
}
