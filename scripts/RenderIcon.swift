import AppKit
let size = 1024
let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()
let tile = NSBezierPath(roundedRect: NSRect(x: 64,y: 64,width: 896,height: 896), xRadius: 204,yRadius: 204)
NSGradient(starting: NSColor(calibratedRed: 0.10,green: 0.29,blue: 0.35,alpha: 1), ending: NSColor(calibratedRed: 0.03,green: 0.12,blue: 0.19,alpha: 1))!.draw(in: tile, angle: -70)
let center = NSPoint(x: 512,y: 522)
for i in 0..<56 {
 let fraction = Double(i)/55
 let angle = (90 + Double(i)*5.1) * Double.pi / 180
 let radius = 285.0
 let point = NSPoint(x: 512 + cos(angle)*radius, y: 522 + sin(angle)*radius)
 NSColor(calibratedRed: 0.62, green: 0.94, blue: 0.87, alpha: 1 - fraction*0.93).setFill()
 let r = 15.0 - fraction*6
 NSBezierPath(ovalIn: NSRect(x: point.x-r,y: point.y-r,width: r*2,height: r*2)).fill()
}
let hand=NSBezierPath();hand.lineWidth=34;hand.lineCapStyle = .round
hand.move(to: NSPoint(x: 512,y: 710));hand.line(to:center);hand.line(to:NSPoint(x: 650,y: 440))
NSColor.white.setStroke();hand.stroke()
NSColor(calibratedRed: 1,green: 0.71,blue: 0.39,alpha: 1).setFill()
NSBezierPath(ovalIn:NSRect(x:488,y:498,width:48,height:48)).fill()
image.unlockFocus()
let rep=NSBitmapImageRep(data:image.tiffRepresentation!)!
try rep.representation(using:.png,properties:[:])!.write(to: URL(fileURLWithPath:CommandLine.arguments[1]))
