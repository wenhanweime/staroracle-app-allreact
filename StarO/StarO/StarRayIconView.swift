import SwiftUI

struct StarRayIconView: View {
  var size: CGFloat = 20
  var color: Color = Color(red: 168/255, green: 85/255, blue: 247/255) // #a855f7

  var body: some View {
    Canvas { context, canvasSize in
      let scale = min(canvasSize.width, canvasSize.height) / 24.0
      context.scaleBy(x: scale, y: scale)
      let tx = (canvasSize.width / scale - 24.0) / 2.0
      let ty = (canvasSize.height / scale - 24.0) / 2.0
      context.translateBy(x: tx, y: ty)

      let center = CGPoint(x: 12, y: 12)
      let halfLen: CGFloat = 8
      let lineWidth: CGFloat = 2

      for index in 0..<8 {
        let angle = Double(index) * (.pi / 4)
        let dx = CGFloat(cos(angle)) * halfLen
        let dy = CGFloat(sin(angle)) * halfLen
        var path = Path()
        path.move(to: CGPoint(x: center.x - dx, y: center.y - dy))
        path.addLine(to: CGPoint(x: center.x + dx, y: center.y + dy))
        context.stroke(
          path,
          with: .color(color),
          style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
        )
      }
    }
    .frame(width: size, height: size)
  }
}
