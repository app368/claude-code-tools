import AppKit

// ViewShot: builds one view from the project and draws it into a PNG.
//
// Replace ViewUnderTest with your view and rewrite the shot(...) calls below.
// The project files this view needs are listed in snapshot.sh, variable NEEDED.

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
// Set the appearance explicitly — otherwise it follows the system theme
// and frames come out different on different days. Dark is .darkAqua
app.appearance = NSAppearance(named: .aqua)

let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "out"

/// Size of the view being drawn. If the view owns a size constant, use that instead.
let paneSize = NSSize(width: 240, height: 168)

/// Draws a single frame.
///
/// The view goes into an invisible window: without one the system never lays the
/// subviews out and there is nothing to draw. `configure` sets the frame's state.
func shot(_ name: String, configure: (ViewUnderTest) -> Void) {
    let view = ViewUnderTest()
    let window = NSWindow(
        contentRect: NSRect(origin: .zero, size: paneSize),
        styleMask: [.borderless], backing: .buffered, defer: false
    )
    let host = NSView(frame: NSRect(origin: .zero, size: paneSize))
    host.addSubview(view)
    view.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        view.leadingAnchor.constraint(equalTo: host.leadingAnchor),
        view.topAnchor.constraint(equalTo: host.topAnchor),
    ])
    window.contentView = host

    // Lay out twice, before and after setting state: first so the elements get
    // their sizes, then so the changes take effect
    host.layoutSubtreeIfNeeded()
    configure(view)
    host.layoutSubtreeIfNeeded()

    guard let rep = host.bitmapImageRepForCachingDisplay(in: host.bounds) else { return }
    rep.size = host.bounds.size
    host.cacheDisplay(in: host.bounds, to: rep)
    guard let data = rep.representation(using: .png, properties: [:]) else { return }
    try? data.write(to: URL(fileURLWithPath: "\(outDir)/\(name).png"))
    print("wrote \(name).png")
}

// MARK: - Frames

shot("1-initial") { _ in }

shot("2-some-state") { view in
    // view.showSomething(true)
}
