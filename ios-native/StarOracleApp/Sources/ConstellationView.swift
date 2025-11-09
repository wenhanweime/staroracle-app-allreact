import SwiftUI
import StarOracleCore

struct ConstellationView: View {
  var stars: [Star]
  var connections: [Connection]
  var highlightId: String?
  var onSelect: (Star) -> Void

  var body: some View {
    GeometryReader { proxy in
      ZStack {
        Canvas { context, size in
          context.blendMode = .plusLighter
          let gradient = Gradient(colors: [Color.white.opacity(0.05), Color.blue.opacity(0.1)])
          let background = Path(CGRect(origin: .zero, size: size))
          context.fill(background, with: .linearGradient(gradient, startPoint: .zero, endPoint: CGPoint(x: size.width, y: size.height)))

          for connection in connections {
            guard
              let from = stars.first(where: { $0.id == connection.fromStarId }),
              let to = stars.first(where: { $0.id == connection.toStarId })
            else { continue }
            let fromPoint = position(for: from, in: size)
            let toPoint = position(for: to, in: size)
            var path = Path()
            path.move(to: fromPoint)
            path.addLine(to: toPoint)
            let alpha = 0.2 + connection.strength * 0.4
            context.stroke(path, with: .color(Color.white.opacity(alpha)), lineWidth: 1)
          }

          for star in stars {
            let point = position(for: star, in: size)
            let radius = CGFloat(max(2.0, star.size))
            let glowRect = CGRect(x: point.x - radius * 2.5, y: point.y - radius * 2.5, width: radius * 5, height: radius * 5)
            let coreRect = CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)
            let isHighlight = highlightId == star.id
            let glowOpacity = isHighlight ? 0.45 : 0.25
            let coreOpacity = isHighlight ? 0.9 : 0.7

            context.fill(Path(ellipseIn: glowRect), with: .radialGradient(
              Gradient(colors: [Color.white.opacity(glowOpacity), .clear]),
              center: point,
              startRadius: 0,
              endRadius: glowRect.width / 2
            ))
            context.fill(Path(ellipseIn: coreRect), with: .color(Color.white.opacity(coreOpacity)))
          }
        }

        ForEach(stars) { star in
          let point = position(for: star, in: proxy.size)
          Button {
            onSelect(star)
          } label: {
            Circle()
              .fill(Color.white.opacity(0.001))
              .frame(width: max(44, CGFloat(star.size) * 6), height: max(44, CGFloat(star.size) * 6))
          }
          .position(point)
          .buttonStyle(.plain)
          .contentShape(Rectangle())
        }
      }
      .clipShape(RoundedRectangle(cornerRadius: 24))
      .overlay(
        RoundedRectangle(cornerRadius: 24)
          .stroke(Color.white.opacity(0.1), lineWidth: 1)
      )
    }
  }

  private func position(for star: Star, in size: CGSize) -> CGPoint {
    CGPoint(
      x: size.width * CGFloat(star.x / 100.0),
      y: size.height * CGFloat(star.y / 100.0)
    )
  }
}
