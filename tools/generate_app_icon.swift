import AppKit

struct Node {
    let center: CGPoint
    let radius: CGFloat
    let start: NSColor
    let end: NSColor
}

func color(_ hex: String, alpha: CGFloat = 1) -> NSColor {
    let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&int)
    let r, g, b: UInt64
    switch hex.count {
    case 3:
        (r, g, b) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
    default:
        (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
    }
    return NSColor(
        calibratedRed: CGFloat(r) / 255,
        green: CGFloat(g) / 255,
        blue: CGFloat(b) / 255,
        alpha: alpha
    )
}

func drawGlow(in ctx: CGContext, center: CGPoint, radius: CGFloat, color: NSColor) {
    let colors = [color.withAlphaComponent(0.22).cgColor, color.withAlphaComponent(0).cgColor] as CFArray
    let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
    ctx.drawRadialGradient(
        gradient,
        startCenter: center,
        startRadius: 0,
        endCenter: center,
        endRadius: radius,
        options: [.drawsAfterEndLocation]
    )
}

func fillCircle(in ctx: CGContext, node: Node, shadow: NSColor) {
    let rect = CGRect(
        x: node.center.x - node.radius,
        y: node.center.y - node.radius,
        width: node.radius * 2,
        height: node.radius * 2
    )

    ctx.saveGState()
    ctx.setShadow(offset: .zero, blur: node.radius * 0.12, color: shadow.withAlphaComponent(0.35).cgColor)
    ctx.addEllipse(in: rect)
    ctx.clip()

    let gradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [node.start.cgColor, node.end.cgColor] as CFArray,
        locations: [0, 1]
    )!
    ctx.drawLinearGradient(
        gradient,
        start: CGPoint(x: rect.minX, y: rect.maxY),
        end: CGPoint(x: rect.maxX, y: rect.minY),
        options: []
    )
    ctx.restoreGState()

    ctx.saveGState()
    ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.18).cgColor)
    ctx.setLineWidth(max(2, node.radius * 0.03))
    ctx.strokeEllipse(in: rect.insetBy(dx: 2, dy: 2))
    ctx.restoreGState()

    let dotRect = CGRect(
        x: node.center.x - node.radius * 0.18,
        y: node.center.y - node.radius * 0.18,
        width: node.radius * 0.36,
        height: node.radius * 0.36
    )
    ctx.setFillColor(NSColor.white.withAlphaComponent(0.92).cgColor)
    ctx.fillEllipse(in: dotRect)

    let highlightRect = CGRect(
        x: rect.minX + node.radius * 0.10,
        y: rect.midY + node.radius * 0.12,
        width: node.radius * 0.85,
        height: node.radius * 0.42
    )
    ctx.setFillColor(NSColor.white.withAlphaComponent(0.10).cgColor)
    ctx.fillEllipse(in: highlightRect)
}

let outputPath = CommandLine.arguments.dropFirst().first ?? "/tmp/mindmesh-app-icon.png"
let size = CGSize(width: 1024, height: 1024)
let image = NSImage(size: size)

image.lockFocus()
let ctx = NSGraphicsContext.current!.cgContext
ctx.setAllowsAntialiasing(true)
ctx.setShouldAntialias(true)

ctx.setFillColor(color("0d1120").cgColor)
ctx.fill(CGRect(origin: .zero, size: size))

drawGlow(in: ctx, center: CGPoint(x: 230, y: 780), radius: 430, color: color("8B5CF6"))
drawGlow(in: ctx, center: CGPoint(x: 760, y: 250), radius: 420, color: color("2DD4BF"))
drawGlow(in: ctx, center: CGPoint(x: 520, y: 540), radius: 260, color: color("A78BFA"))

let centerNode = Node(
    center: CGPoint(x: 512, y: 540),
    radius: 118,
    start: color("8B5CF6"),
    end: color("5EEAD4")
)

let outerNodes: [Node] = [
    Node(center: CGPoint(x: 160, y: 815), radius: 82, start: color("7C3AED"), end: color("8B5CF6")),
    Node(center: CGPoint(x: 512, y: 900), radius: 54, start: color("6D28D9"), end: color("7C3AED")),
    Node(center: CGPoint(x: 855, y: 825), radius: 88, start: color("5EEAD4"), end: color("34D399")),
    Node(center: CGPoint(x: 95, y: 240), radius: 70, start: color("8B5CF6"), end: color("7C3AED")),
    Node(center: CGPoint(x: 512, y: 150), radius: 54, start: color("6D28D9"), end: color("7C3AED")),
    Node(center: CGPoint(x: 955, y: 255), radius: 74, start: color("60E1D2"), end: color("2DD4BF")),
]

let secondaryLinks: [(CGPoint, CGPoint, NSColor)] = [
    (outerNodes[3].center, outerNodes[4].center, color("8B5CF6", alpha: 0.28)),
    (outerNodes[4].center, outerNodes[5].center, color("8B5CF6", alpha: 0.24)),
    (outerNodes[0].center, outerNodes[1].center, color("2DD4BF", alpha: 0.28)),
    (outerNodes[1].center, outerNodes[2].center, color("5EEAD4", alpha: 0.28)),
]

ctx.setLineCap(.round)

for (start, end, stroke) in secondaryLinks {
    ctx.saveGState()
    ctx.setStrokeColor(stroke.cgColor)
    ctx.setLineWidth(4)
    ctx.setLineDash(phase: 0, lengths: [8, 14])
    ctx.move(to: start)
    ctx.addLine(to: end)
    ctx.strokePath()
    ctx.restoreGState()
}

for node in outerNodes {
    ctx.saveGState()
    ctx.setStrokeColor(color(node.center.x > 650 ? "5EEAD4" : "60A5FA", alpha: 0.34).cgColor)
    ctx.setLineWidth(5)
    ctx.setLineDash(phase: 0, lengths: [12, 12])
    ctx.move(to: centerNode.center)
    ctx.addLine(to: node.center)
    ctx.strokePath()
    ctx.restoreGState()
}

for ring in [148, 172] {
    let rect = CGRect(x: centerNode.center.x - CGFloat(ring), y: centerNode.center.y - CGFloat(ring), width: CGFloat(ring * 2), height: CGFloat(ring * 2))
    ctx.setStrokeColor(color("A78BFA", alpha: ring == 148 ? 0.16 : 0.10).cgColor)
    ctx.setLineWidth(4)
    ctx.strokeEllipse(in: rect)
}

fillCircle(in: ctx, node: centerNode, shadow: color("A78BFA"))
for node in outerNodes {
    let shadow = node.end.usingColorSpace(.deviceRGB) ?? node.end
    fillCircle(in: ctx, node: node, shadow: shadow)
}

image.unlockFocus()

guard
    let tiffData = image.tiffRepresentation,
    let bitmap = NSBitmapImageRep(data: tiffData),
    let pngData = bitmap.representation(using: .png, properties: [:])
else {
    fputs("Failed to encode PNG\n", stderr)
    exit(1)
}

try pngData.write(to: URL(fileURLWithPath: outputPath))
