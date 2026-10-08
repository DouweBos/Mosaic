// Renders Mosaic's app icon into app/Mosaic/Mosaic/AppIcon.icon (Icon Composer bundle),
// and the same glyph as a template image for the menu bar.
// Usage: swift scripts/render-icon.swift [output .icon path]
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

struct Appearance {
    let name: String
    let background: (top: String, bottom: String)
    let glyph: String
}

let light = Appearance(name: "light", background: ("#2DD4BF", "#0F766E"), glyph: "#FFFFFF")
let dark = Appearance(name: "dark", background: ("#134E4A", "#042F2E"), glyph: "#5EEAD4")
let gradientAngle: CGFloat = 20 // degrees off vertical, top-left → bottom-right

// MARK: - Glyph (designed on the 1024 macOS grid, y down, body at 100...924)


/// An open tray with a wing rising from its side: the shelf that carries things.
/// A window layout: one tall tile on the left, two stacked on the right.
func glyph(weight: CGFloat = 1) -> CGPath {
    let path = CGMutablePath()
    let gap: CGFloat = 40 * weight
    let left: CGFloat = 232, top: CGFloat = 252, right: CGFloat = 792, bottom: CGFloat = 772
    let split = (left + right) / 2, middle = (top + bottom) / 2
    let radius: CGFloat = 52
    let tiles = [
        CGRect(x: left, y: top, width: split - gap / 2 - left, height: bottom - top),
        CGRect(x: split + gap / 2, y: top, width: right - split - gap / 2, height: middle - gap / 2 - top),
        CGRect(x: split + gap / 2, y: middle + gap / 2, width: right - split - gap / 2, height: bottom - middle - gap / 2)
    ]
    for tile in tiles {
        path.addRoundedRect(in: tile, cornerWidth: radius, cornerHeight: radius)
    }
    return path
}

// MARK: - Output

func rgb(_ hex: String) -> [CGFloat] {
    var value: UInt64 = 0
    Scanner(string: hex.replacingOccurrences(of: "#", with: "")).scanHexInt64(&value)
    return [CGFloat((value >> 16) & 0xFF) / 255, CGFloat((value >> 8) & 0xFF) / 255, CGFloat(value & 0xFF) / 255]
}

func color(_ hex: String) -> CGColor {
    let c = rgb(hex)
    return CGColor(srgbRed: c[0], green: c[1], blue: c[2], alpha: 1)
}

/// Icon Composer's canvas is the icon body, so the 824 grid body is scaled up to fill 1024.
func writeGlyph(_ appearance: Appearance, to url: URL) throws {
    let size = 1024
    let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    let scale: CGFloat = 1024 / 824
    ctx.translateBy(x: 512, y: 512)
    ctx.scaleBy(x: scale, y: -scale)
    ctx.translateBy(x: -512, y: -512)
    ctx.addPath(glyph())
    ctx.setFillColor(color(appearance.glyph))
    ctx.fillPath()

    guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
        throw CocoaError(.fileWriteUnknown)
    }
    CGImageDestinationAddImage(dest, ctx.makeImage()!, nil)
    guard CGImageDestinationFinalize(dest) else { throw CocoaError(.fileWriteUnknown) }
}

func srgbString(_ hex: String) -> String {
    "srgb:" + (rgb(hex) + [1]).map { String(format: "%.5f", $0) }.joined(separator: ",")
}

func fill(_ appearance: Appearance) -> [String: Any] {
    let dx = 0.5 * sin(gradientAngle * .pi / 180)
    // Decimal keeps the JSON free of float noise.
    func coord(_ v: CGFloat) -> NSDecimalNumber { NSDecimalNumber(string: String(format: "%.3f", v)) }
    return ["linear-gradient": [srgbString(appearance.background.top), srgbString(appearance.background.bottom)],
            "orientation": ["start": ["x": coord(0.5 - dx), "y": 0], "stop": ["x": coord(0.5 + dx), "y": 1]]]
}

let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let bundle = CommandLine.arguments.count > 1
    ? URL(fileURLWithPath: CommandLine.arguments[1])
    : root.appendingPathComponent("app/Mosaic/Mosaic/AppIcon.icon")
let assets = bundle.appendingPathComponent("Assets")
try FileManager.default.createDirectory(at: assets, withIntermediateDirectories: true)

for appearance in [light, dark] {
    try writeGlyph(appearance, to: assets.appendingPathComponent("glyph-\(appearance.name).png"))
}

let icon: [String: Any] = [
    "fill-specializations": [["value": fill(light)], ["appearance": "dark", "value": fill(dark)]],
    "groups": [[
        "layers": [[
            "name": "glyph",
            "glass": false,
            "image-name-specializations": [["value": "glyph-light.png"], ["appearance": "dark", "value": "glyph-dark.png"]],
        ]],
        "shadow": ["kind": "neutral", "opacity": 0.5],
        "specular": false,
        "translucency": ["enabled": false, "value": 0.5],
    ]],
    "supported-platforms": ["squares": ["macOS"]],
]
let json = try JSONSerialization.data(withJSONObject: icon, options: [.prettyPrinted, .sortedKeys])
try json.write(to: bundle.appendingPathComponent("icon.json"))
print("Wrote \(bundle.path)")

// MARK: - Menu bar

/// Black on transparent, cropped to the glyph and fitted to the 18pt menu bar height.
func writeMenuBarGlyph(height: Int, to url: URL) throws {
    let path = glyph(weight: 1.6)
    let box = path.boundingBoxOfPath
    let scale = CGFloat(height) / box.height
    let width = Int((box.width * scale).rounded(.up))
    let ctx = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.translateBy(x: 0, y: CGFloat(height))
    ctx.scaleBy(x: scale, y: -scale)
    ctx.translateBy(x: -box.minX, y: -box.minY)
    ctx.addPath(path)
    ctx.setFillColor(CGColor(gray: 0, alpha: 1))
    ctx.fillPath()
    guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
        throw CocoaError(.fileWriteUnknown)
    }
    CGImageDestinationAddImage(dest, ctx.makeImage()!, nil)
    guard CGImageDestinationFinalize(dest) else { throw CocoaError(.fileWriteUnknown) }
}

let imageset = root.appendingPathComponent("app/Mosaic/Mosaic/Assets.xcassets/MenuBarIcon.imageset")
try FileManager.default.createDirectory(at: imageset, withIntermediateDirectories: true)
try writeMenuBarGlyph(height: 16, to: imageset.appendingPathComponent("menubar.png"))
try writeMenuBarGlyph(height: 32, to: imageset.appendingPathComponent("menubar@2x.png"))
let imagesetJSON: [String: Any] = [
    "images": [
        ["filename": "menubar.png", "idiom": "universal", "scale": "1x"],
        ["filename": "menubar@2x.png", "idiom": "universal", "scale": "2x"],
    ],
    "info": ["author": "xcode", "version": 1],
    "properties": ["template-rendering-intent": "template"],
]
try JSONSerialization.data(withJSONObject: imagesetJSON, options: [.prettyPrinted, .sortedKeys])
    .write(to: imageset.appendingPathComponent("Contents.json"))
print("Wrote \(imageset.path)")
