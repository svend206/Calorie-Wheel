#!/usr/bin/env swift
import Cocoa

let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)
image.lockFocus()
let ctx = NSGraphicsContext.current!.cgContext

// Fill entire image with green background (no transparency)
let bgGreen = NSColor(red: 0x3D/255.0, green: 0xDC/255.0, blue: 0x84/255.0, alpha: 1.0)
ctx.setFillColor(bgGreen.cgColor)
ctx.fill(CGRect(x: 0, y: 0, width: 1024, height: 1024))

let scale: CGFloat = 1024.0 / 108.0
ctx.setFillColor(NSColor.white.cgColor)

// Fork tines
let tineWidth: CGFloat = 4 * scale
let tineCorner: CGFloat = 2 * scale

let leftTine = CGRect(x: 38 * scale, y: (108 - 52) * scale, width: tineWidth, height: 28 * scale)
NSBezierPath(roundedRect: leftTine, xRadius: tineCorner, yRadius: tineCorner).fill()

let centerTine = CGRect(x: 54 * scale, y: (108 - 50) * scale, width: 2 * scale, height: 26 * scale)
NSBezierPath(roundedRect: centerTine, xRadius: 1 * scale, yRadius: 1 * scale).fill()

let rightTine = CGRect(x: 66 * scale, y: (108 - 52) * scale, width: tineWidth, height: 28 * scale)
NSBezierPath(roundedRect: rightTine, xRadius: tineCorner, yRadius: tineCorner).fill()

// Plate (ring)
let plateCenterX = 54 * scale
let plateCenterY = (108 - 80) * scale
let outerRadius = 22 * scale
let innerRadius = 18 * scale

let outerCircle = NSBezierPath(ovalIn: CGRect(
    x: plateCenterX - outerRadius, y: plateCenterY - outerRadius,
    width: outerRadius * 2, height: outerRadius * 2))
let innerCircle = NSBezierPath(ovalIn: CGRect(
    x: plateCenterX - innerRadius, y: plateCenterY - innerRadius,
    width: innerRadius * 2, height: innerRadius * 2))
outerCircle.append(innerCircle)
outerCircle.windingRule = .evenOdd
outerCircle.fill()

image.unlockFocus()

// Save as PNG WITHOUT alpha channel
let noAlphaRep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: 1024,
    pixelsHigh: 1024,
    bitsPerSample: 8,
    samplesPerPixel: 3,
    hasAlpha: false,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
)!

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: noAlphaRep)
image.draw(in: NSRect(x: 0, y: 0, width: 1024, height: 1024))
NSGraphicsContext.restoreGraphicsState()

if let pngData = noAlphaRep.representation(using: .png, properties: [:]) {
    let url = URL(fileURLWithPath: "CalorieWheel/Assets.xcassets/AppIcon.appiconset/AppIcon.png")
    try! pngData.write(to: url)
    print("App icon saved without alpha!")
} else {
    print("Failed")
    exit(1)
}
