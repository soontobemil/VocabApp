import AppKit

let outputDirectory = URL(fileURLWithPath: "VocabApp/Assets.xcassets/AppIcon.appiconset")
let sizes = [16, 32, 64, 128, 256, 512, 1024]

func scaled(_ value: CGFloat, _ size: CGFloat) -> CGFloat {
    value * size / 1024
}

func drawIcon(size: Int) -> NSImage {
    let dimension = CGFloat(size)
    let image = NSImage(size: NSSize(width: dimension, height: dimension))

    image.lockFocus()
    defer { image.unlockFocus() }

    let bounds = NSRect(x: 0, y: 0, width: dimension, height: dimension)
    let cornerRadius = scaled(228, dimension)
    let backgroundPath = NSBezierPath(roundedRect: bounds, xRadius: cornerRadius, yRadius: cornerRadius)
    let backgroundGradient = NSGradient(colors: [
        NSColor(red: 0.06, green: 0.14, blue: 0.13, alpha: 1),
        NSColor(red: 0.07, green: 0.29, blue: 0.26, alpha: 1),
        NSColor(red: 0.84, green: 0.47, blue: 0.19, alpha: 1)
    ])!
    backgroundGradient.draw(in: backgroundPath, angle: -45)

    NSColor.black.withAlphaComponent(0.24).setFill()
    let shadow = NSBezierPath()
    shadow.move(to: NSPoint(x: scaled(186, dimension), y: scaled(314, dimension)))
    shadow.curve(to: NSPoint(x: scaled(462, dimension), y: scaled(325, dimension)), controlPoint1: NSPoint(x: scaled(278, dimension), y: scaled(340, dimension)), controlPoint2: NSPoint(x: scaled(370, dimension), y: scaled(342, dimension)))
    shadow.curve(to: NSPoint(x: scaled(560, dimension), y: scaled(325, dimension)), controlPoint1: NSPoint(x: scaled(494, dimension), y: scaled(315, dimension)), controlPoint2: NSPoint(x: scaled(528, dimension), y: scaled(315, dimension)))
    shadow.curve(to: NSPoint(x: scaled(838, dimension), y: scaled(314, dimension)), controlPoint1: NSPoint(x: scaled(652, dimension), y: scaled(342, dimension)), controlPoint2: NSPoint(x: scaled(746, dimension), y: scaled(340, dimension)))
    shadow.line(to: NSPoint(x: scaled(838, dimension), y: scaled(720, dimension)))
    shadow.curve(to: NSPoint(x: scaled(560, dimension), y: scaled(701, dimension)), controlPoint1: NSPoint(x: scaled(746, dimension), y: scaled(694, dimension)), controlPoint2: NSPoint(x: scaled(652, dimension), y: scaled(692, dimension)))
    shadow.curve(to: NSPoint(x: scaled(462, dimension), y: scaled(701, dimension)), controlPoint1: NSPoint(x: scaled(528, dimension), y: scaled(711, dimension)), controlPoint2: NSPoint(x: scaled(494, dimension), y: scaled(711, dimension)))
    shadow.curve(to: NSPoint(x: scaled(186, dimension), y: scaled(720, dimension)), controlPoint1: NSPoint(x: scaled(370, dimension), y: scaled(692, dimension)), controlPoint2: NSPoint(x: scaled(278, dimension), y: scaled(694, dimension)))
    shadow.close()
    shadow.fill()

    let pageGradient = NSGradient(colors: [
        NSColor(red: 1.0, green: 0.96, blue: 0.86, alpha: 1),
        NSColor(red: 0.95, green: 0.82, blue: 0.58, alpha: 1)
    ])!
    let leftPage = NSBezierPath()
    leftPage.move(to: NSPoint(x: scaled(212, dimension), y: scaled(276, dimension)))
    leftPage.curve(to: NSPoint(x: scaled(484, dimension), y: scaled(288, dimension)), controlPoint1: NSPoint(x: scaled(302, dimension), y: scaled(246, dimension)), controlPoint2: NSPoint(x: scaled(393, dimension), y: scaled(250, dimension)))
    leftPage.line(to: NSPoint(x: scaled(484, dimension), y: scaled(758, dimension)))
    leftPage.curve(to: NSPoint(x: scaled(212, dimension), y: scaled(746, dimension)), controlPoint1: NSPoint(x: scaled(393, dimension), y: scaled(720, dimension)), controlPoint2: NSPoint(x: scaled(302, dimension), y: scaled(716, dimension)))
    leftPage.close()
    pageGradient.draw(in: leftPage, angle: -90)

    let rightPage = NSBezierPath()
    rightPage.move(to: NSPoint(x: scaled(540, dimension), y: scaled(288, dimension)))
    rightPage.curve(to: NSPoint(x: scaled(812, dimension), y: scaled(276, dimension)), controlPoint1: NSPoint(x: scaled(631, dimension), y: scaled(250, dimension)), controlPoint2: NSPoint(x: scaled(722, dimension), y: scaled(246, dimension)))
    rightPage.line(to: NSPoint(x: scaled(812, dimension), y: scaled(746, dimension)))
    rightPage.curve(to: NSPoint(x: scaled(540, dimension), y: scaled(758, dimension)), controlPoint1: NSPoint(x: scaled(722, dimension), y: scaled(716, dimension)), controlPoint2: NSPoint(x: scaled(631, dimension), y: scaled(720, dimension)))
    rightPage.close()
    pageGradient.draw(in: rightPage, angle: -90)

    NSColor(red: 0.10, green: 0.22, blue: 0.20, alpha: 0.55).setStroke()
    let spine = NSBezierPath()
    spine.lineWidth = max(1, scaled(18, dimension))
    spine.lineCapStyle = .round
    spine.move(to: NSPoint(x: scaled(512, dimension), y: scaled(296, dimension)))
    spine.line(to: NSPoint(x: scaled(512, dimension), y: scaled(754, dimension)))
    spine.stroke()

    NSColor(red: 0.11, green: 0.25, blue: 0.23, alpha: 0.88).setStroke()
    for (x, y, width) in [(276, 656, 140), (276, 600, 164), (276, 544, 124), (608, 656, 140), (608, 600, 164), (608, 544, 108)] {
        let line = NSBezierPath()
        line.lineWidth = max(1, scaled(26, dimension))
        line.lineCapStyle = .round
        line.move(to: NSPoint(x: scaled(CGFloat(x), dimension), y: scaled(CGFloat(y), dimension)))
        line.line(to: NSPoint(x: scaled(CGFloat(x + width), dimension), y: scaled(CGFloat(y), dimension)))
        line.stroke()
    }

    NSColor(red: 0.90, green: 0.49, blue: 0.22, alpha: 1).setFill()
    let bookmark = NSBezierPath()
    bookmark.move(to: NSPoint(x: scaled(642, dimension), y: scaled(237, dimension)))
    bookmark.line(to: NSPoint(x: scaled(725, dimension), y: scaled(220, dimension)))
    bookmark.line(to: NSPoint(x: scaled(725, dimension), y: scaled(376, dimension)))
    bookmark.line(to: NSPoint(x: scaled(683, dimension), y: scaled(345, dimension)))
    bookmark.line(to: NSPoint(x: scaled(642, dimension), y: scaled(376, dimension)))
    bookmark.close()
    bookmark.fill()

    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = .center
    let textColor = NSColor(red: 0.07, green: 0.21, blue: 0.18, alpha: 1)
    let latinFont = NSFont.systemFont(ofSize: scaled(178, dimension), weight: .heavy)
    let koreanFont = NSFont(name: "AppleSDGothicNeo-ExtraBold", size: scaled(162, dimension)) ?? NSFont.systemFont(ofSize: scaled(162, dimension), weight: .heavy)

    ("V" as NSString).draw(in: NSRect(x: scaled(282, dimension), y: scaled(394, dimension), width: scaled(144, dimension), height: scaled(210, dimension)), withAttributes: [
        .font: latinFont,
        .foregroundColor: textColor,
        .paragraphStyle: paragraphStyle
    ])
    ("\u{AC00}" as NSString).draw(in: NSRect(x: scaled(574, dimension), y: scaled(398, dimension), width: scaled(178, dimension), height: scaled(210, dimension)), withAttributes: [
        .font: koreanFont,
        .foregroundColor: textColor,
        .paragraphStyle: paragraphStyle
    ])

    return image
}

func writePNG(_ image: NSImage, size: Int) throws {
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:])
    else {
        throw NSError(domain: "IconGeneration", code: 1)
    }
    try png.write(to: outputDirectory.appendingPathComponent("app-icon-\(size).png"))
}

for size in sizes {
    try writePNG(drawIcon(size: size), size: size)
}
