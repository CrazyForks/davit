#!/usr/bin/env swift
// Renders the app icon (gradient rounded-rect + shipping box symbol) and emits AppIcon.icns.
// Usage: swift scripts/make-icon.swift <output-dir>

import AppKit

let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."
let iconsetPath = "\(outDir)/AppIcon.iconset"
try? FileManager.default.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

func drawIcon(size: CGFloat) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size),
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    let inset = size * 0.05 // macOS icon grid margin
    let rect = NSRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
    let radius = rect.width * 0.225
    let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)

    // Deep blue → violet gradient background
    let gradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.11, green: 0.27, blue: 0.85, alpha: 1),
        NSColor(calibratedRed: 0.42, green: 0.20, blue: 0.88, alpha: 1),
    ])!
    path.addClip()
    gradient.draw(in: rect, angle: -60)

    // Subtle top sheen
    let sheen = NSGradient(colors: [
        NSColor.white.withAlphaComponent(0.18),
        NSColor.white.withAlphaComponent(0.0),
    ])!
    sheen.draw(in: NSRect(x: rect.minX, y: rect.midY, width: rect.width, height: rect.height / 2), angle: -90)

    // Shipping box symbol
    let config = NSImage.SymbolConfiguration(pointSize: size * 0.42, weight: .medium)
    if let symbol = NSImage(systemSymbolName: "shippingbox.fill", accessibilityDescription: nil)?
        .withSymbolConfiguration(config) {
        let tinted = NSImage(size: symbol.size, flipped: false) { r in
            symbol.draw(in: r)
            NSColor.white.set()
            r.fill(using: .sourceAtop)
            return true
        }
        let s = tinted.size
        let scale = (size * 0.52) / max(s.width, s.height)
        let w = s.width * scale, h = s.height * scale
        tinted.draw(
            in: NSRect(x: (size - w) / 2, y: (size - h) / 2, width: w, height: h),
            from: .zero, operation: .sourceOver, fraction: 0.97)
    }

    NSGraphicsContext.restoreGraphicsState()
    return rep
}

let sizes: [(name: String, px: CGFloat)] = [
    ("icon_16x16", 16), ("icon_16x16@2x", 32),
    ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256),
    ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024),
]

for (name, px) in sizes {
    let rep = drawIcon(size: px)
    let data = rep.representation(using: .png, properties: [:])!
    try! data.write(to: URL(fileURLWithPath: "\(iconsetPath)/\(name).png"))
}

let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
task.arguments = ["-c", "icns", iconsetPath, "-o", "\(outDir)/AppIcon.icns"]
try! task.run()
task.waitUntilExit()
print("Wrote \(outDir)/AppIcon.icns")
