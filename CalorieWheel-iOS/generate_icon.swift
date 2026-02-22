#!/usr/bin/env swift
import Cocoa

// Generate a 1024x1024 app icon matching the Android design:
// Green circle background with a white fork and plate icon

let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)

image.lockFocus()

let ctx = NSGraphicsContext.current!.cgContext

// Background: green circle
let green = NSColor(red: 0x3D / 255.0, green: 0xDC / 255.0, blue: 0x84 / 255.0, alpha: 1.0)
ctx.setFillColor(green.cgColor)
ctx.fillEllipse(in: CGRect(x: 0, y: 0, width: 1024, height: 1024))

// Scale factor (Android uses 108x108 viewport, we use 1024x1024)
let scale: CGFloat = 1024.0 / 108.0

ctx.setFillColor(NSColor.white.cgColor)

// Fork tines (three vertical lines) - from Android pathData
// Left tine: rect from (38,24) to (42,52) with rounded ends
let tineWidth: CGFloat = 4 * scale
let tineCorner: CGFloat = 2 * scale

// Left tine
let leftTine = CGRect(x: 38 * scale, y: (108 - 52) * scale, width: tineWidth, height: 28 * scale)
let leftPath = NSBezierPath(roundedRect: leftTine, xRadius: tineCorner, yRadius: tineCorner)
leftPath.fill()

// Center tine (thinner, rect)
let centerTine = CGRect(x: 54 * scale, y: (108 - 50) * scale, width: 2 * scale, height: 26 * scale)
NSBezierPath(roundedRect: centerTine, xRadius: 1 * scale, yRadius: 1 * scale).fill()

// Right tine
let rightTine = CGRect(x: 66 * scale, y: (108 - 52) * scale, width: tineWidth, height: 28 * scale)
let rightPath = NSBezierPath(roundedRect: rightTine, xRadius: tineCorner, yRadius: tineCorner)
rightPath.fill()

// Plate (ring/donut shape) - circle with hole
// Outer: center (54,80), radius 22
// Inner: center (54,80), radius 18
let plateCenterX = 54 * scale
let plateCenterY = (108 - 80) * scale // flip Y for macOS coordinate system
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

// Save as PNG
if let tiffData = image.tiffRepresentation,
   let bitmapRep = NSBitmapImageRep(data: tiffData),
   let pngData = bitmapRep.representation(using: .png, properties: [:]) {
    let url = URL(fileURLWithPath: "CalorieWheel/Assets.xcassets/AppIcon.appiconset/AppIcon.png")
    try! pngData.write(to: url)
    print("App icon generated successfully!")
} else {
    print("Failed to generate app icon")
    exit(1)
}
