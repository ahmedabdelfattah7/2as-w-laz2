// Logo generator le "2as w Laze2" — beyersem el icon bel CoreGraphics
// w beytalla3 PNGs bel ma2asat el matlooba lel AppIcon.appiconset.
//
// Usage: swift genicon.swift <output_dir> [--preview]
import AppKit

let args = CommandLine.arguments
guard args.count >= 2 else {
  print("usage: swift genicon.swift <output_dir> [--preview]")
  exit(1)
}
let outDir = args[1]
let previewOnly = args.contains("--preview")

func deg(_ d: CGFloat) -> CGFloat { d * .pi / 180 }

// Kol el rasm fe e7dathiyat 1024x1024; el scale beyetzabbat le kol ma2as.
func draw(into ctx: CGContext, canvas: CGFloat) {
  let s = canvas / 1024.0
  ctx.scaleBy(x: s, y: s)

  // ===== 1) El khalfeya: squircle b gradient "gharoob masri" =====
  let bgRect = CGRect(x: 100, y: 100, width: 824, height: 824)
  let bgPath = CGPath(roundedRect: bgRect, cornerWidth: 185, cornerHeight: 185, transform: nil)

  ctx.saveGState()
  ctx.addPath(bgPath)
  ctx.clip()

  let colors = [
    CGColor(red: 0.976, green: 0.788, blue: 0.310, alpha: 1),  // gold #F9C94F
    CGColor(red: 0.898, green: 0.408, blue: 0.169, alpha: 1),  // burnt orange #E5682B
  ] as CFArray
  let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
  ctx.drawLinearGradient(
    grad,
    start: CGPoint(x: 512, y: 924), end: CGPoint(x: 512, y: 100), options: [])

  // ===== 2) Khat el 2as (ta7t el war2a — abyad 3ala el khalfeya) =====
  func strokeCutLine(_ color: CGColor) {
    ctx.saveGState()
    ctx.setStrokeColor(color)
    ctx.setLineWidth(18)
    ctx.setLineCap(.round)
    ctx.setLineDash(phase: 0, lengths: [44, 46])
    ctx.move(to: CGPoint(x: 165, y: 195))
    ctx.addLine(to: CGPoint(x: 800, y: 830))
    ctx.strokePath()
    ctx.restoreGState()
  }
  // ===== 3) El war2a el maqsoosa (metlaze2a b tape) =====
  ctx.saveGState()
  ctx.translateBy(x: 636, y: 622)
  ctx.rotate(by: deg(-14))

  // dell khafeef ta7t el war2a
  ctx.setShadow(offset: CGSize(width: 0, height: -14), blur: 40,
                color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.30))
  let paper = CGRect(x: -195, y: -240, width: 390, height: 480)
  let paperPath = CGPath(roundedRect: paper, cornerWidth: 36, cornerHeight: 36, transform: nil)
  ctx.addPath(paperPath)
  ctx.setFillColor(CGColor(red: 1, green: 0.992, blue: 0.973, alpha: 1))
  ctx.fillPath()
  ctx.setShadow(offset: .zero, blur: 0, color: nil)

  // el tape (el "laze2"): shreet ma2el 3ala el rokn el foo2ani
  ctx.saveGState()
  ctx.translateBy(x: -148, y: 200)
  ctx.rotate(by: deg(-45))
  ctx.setFillColor(CGColor(red: 1, green: 0.925, blue: 0.60, alpha: 0.88))
  ctx.addPath(CGPath(rect: CGRect(x: -95, y: -34, width: 190, height: 68), transform: nil))
  ctx.fillPath()
  ctx.restoreGState()

  ctx.restoreGState()

  // ===== 4) Nafs el khat gowa el war2a bas — ramadi (coupon style) =====
  ctx.saveGState()
  ctx.translateBy(x: 636, y: 622)
  ctx.rotate(by: deg(-14))
  ctx.addPath(CGPath(roundedRect: CGRect(x: -195, y: -240, width: 390, height: 480),
                     cornerWidth: 36, cornerHeight: 36, transform: nil))
  ctx.restoreGState()
  ctx.saveGState()
  ctx.clip()
  strokeCutLine(CGColor(red: 0.72, green: 0.745, blue: 0.792, alpha: 1))
  ctx.restoreGState()

  // ===== 4) El ma2as (scissors) 3ala el khat =====
  ctx.saveGState()
  ctx.translateBy(x: 372, y: 400)
  ctx.rotate(by: deg(-45))  // el sellah metwaggeh ma3a el khat (45°)

  let charcoal = CGColor(red: 0.161, green: 0.157, blue: 0.176, alpha: 1)
  let bladeLen: CGFloat = 255
  let handleDist: CGFloat = 180
  let open: CGFloat = 17  // zawyet fat7 el ma2as

  for sign: CGFloat in [-1, 1] {
    let a = deg(open) * sign
    let dir = CGPoint(x: -sin(a), y: cos(a))

    // el nasla: khat te5een b tarf medawwar
    ctx.setStrokeColor(charcoal)
    ctx.setLineWidth(58)
    ctx.setLineCap(.round)
    ctx.move(to: .zero)
    ctx.addLine(to: CGPoint(x: dir.x * bladeLen, y: dir.y * bladeLen))
    ctx.strokePath()

    // el 3elba (el 7al2a) fel etegah el 3aksi
    let hc = CGPoint(x: -dir.x * handleDist, y: -dir.y * handleDist)
    ctx.setLineWidth(42)
    ctx.addEllipse(in: CGRect(x: hc.x - 68, y: hc.y - 68, width: 136, height: 136))
    ctx.strokePath()
  }

  // el mesmar fel nos
  ctx.setFillColor(CGColor(red: 0.976, green: 0.788, blue: 0.310, alpha: 1))
  ctx.addEllipse(in: CGRect(x: -30, y: -30, width: 60, height: 60))
  ctx.fillPath()

  ctx.restoreGState()
  ctx.restoreGState()  // clip bta3 el khalfeya
}

func render(size: Int, to path: String) {
  let ctx = CGContext(
    data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
    space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
  draw(into: ctx, canvas: CGFloat(size))
  let img = ctx.makeImage()!
  let rep = NSBitmapImageRep(cgImage: img)
  let png = rep.representation(using: .png, properties: [:])!
  try! png.write(to: URL(fileURLWithPath: path))
  print("wrote \(path)")
}

if previewOnly {
  render(size: 1024, to: "\(outDir)/logo_1024.png")
} else {
  for size in [16, 32, 64, 128, 256, 512, 1024] {
    render(size: size, to: "\(outDir)/app_icon_\(size).png")
  }
}
