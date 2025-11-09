import SwiftUI
import StarOracleCore
import StarOracleFeatures

#if os(iOS)
import UIKit
#endif

struct GalaxyBackgroundView: View {
  @EnvironmentObject private var galaxyStore: GalaxyStore
  @EnvironmentObject private var starStore: StarStore
  @State private var lastTapRegion: GalaxyRegion?
  @State private var lastTapDate: Date = .distantPast

  var body: some View {
    GeometryReader { proxy in
      TimelineView(.animation) { context in
        Canvas { canvas, size in
          galaxyStore.setCanvasSize(width: size.width, height: size.height)
          drawBackground(in: canvas, size: size, date: context.date)
        }
        .contentShape(Rectangle())
        .gesture(
          DragGesture(minimumDistance: 0)
            .onChanged { value in
              galaxyStore.hover(atX: value.location.x, y: value.location.y)
            }
            .onEnded { value in
              galaxyStore.tap(atX: value.location.x, y: value.location.y)
              if let region = region(at: value.location, size: proxy.size) {
                _ = starStore.drawInspirationCard(region: region)
                lastTapRegion = region
                lastTapDate = Date()
              }
            }
        )
        .overlay(alignment: .topLeading) {
          if let region = lastTapRegion, Date().timeIntervalSince(lastTapDate) < 2 {
            Label("灵感来自 \(regionLabel(region)) 区域", systemImage: "sparkles")
              .font(.caption)
              .padding(8)
              .background(Color.black.opacity(0.4), in: Capsule())
              .padding()
          }
        }
        .onAppear {
          #if os(iOS)
          let size = proxy.size == .zero ? UIScreen.main.bounds.size : proxy.size
          galaxyStore.setCanvasSize(width: size.width, height: size.height)
          #endif
          galaxyStore.generateHotspots(count: 30)
        }
      }
    }
  }

  private func drawBackground(in context: GraphicsContext, size: CGSize, date: Date) {
    let colors = Gradient(colors: [Color.black, Color.blue.opacity(0.3)])
    context.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(colors, startPoint: .zero, endPoint: CGPoint(x: size.width, y: size.height)))

    let stars = galaxyStore.hotspots
    for hotspot in stars {
      let point = CGPoint(x: size.width * hotspot.xPercent / 100.0, y: size.height * hotspot.yPercent / 100.0)
      let isHover = hotspot.id == galaxyStore.hoveredId
      let radius: CGFloat = isHover ? 5 : 3
      context.fill(
        Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)),
        with: .color(color(for: hotspot.region).opacity(isHover ? 0.9 : 0.6))
      )
    }

    for ripple in galaxyStore.ripples {
      let progress = min(1, max(0, date.timeIntervalSince(ripple.startAt) / ripple.duration))
      let radius = CGFloat(progress) * 120
      let alpha = 0.5 * (1 - progress)
      let center = CGPoint(x: ripple.x, y: ripple.y)
      context.stroke(
        Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)),
        with: .color(Color.white.opacity(alpha)),
        lineWidth: 1
      )
    }
  }

  private func color(for region: GalaxyRegion) -> Color {
    switch region {
    case .emotion: return .pink
    case .relation: return .cyan
    case .growth: return .purple
    }
  }

  private func region(at point: CGPoint, size: CGSize) -> GalaxyRegion? {
    let hotspots = galaxyStore.hotspots
    guard !hotspots.isEmpty else { return nil }
    var nearest: (GalaxyHotspot, Double)?
    for hotspot in hotspots {
      let hx = size.width * hotspot.xPercent / 100
      let hy = size.height * hotspot.yPercent / 100
      let distance = hypot(point.x - hx, point.y - hy)
      if distance < 80,
         (nearest == nil || distance < nearest!.1) {
        nearest = (hotspot, distance)
      }
    }
    return nearest?.0.region
  }

  private func regionLabel(_ region: GalaxyRegion) -> String {
    switch region {
    case .emotion: return "情绪"
    case .relation: return "关系"
    case .growth: return "成长"
    }
  }
}
