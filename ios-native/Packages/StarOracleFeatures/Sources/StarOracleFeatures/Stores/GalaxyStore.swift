import Foundation
import StarOracleCore

@MainActor
public final class GalaxyStore: ObservableObject, GalaxyStoreProtocol {
  @Published public private(set) var width: Double
  @Published public private(set) var height: Double
  @Published public private(set) var hotspots: [GalaxyHotspot]
  @Published public private(set) var ripples: [GalaxyRipple]
  @Published public private(set) var hoveredId: String?

  public init(
    width: Double = 0,
    height: Double = 0,
    hotspots: [GalaxyHotspot] = [],
    ripples: [GalaxyRipple] = [],
    hoveredId: String? = nil
  ) {
    self.width = width
    self.height = height
    self.hotspots = hotspots
    self.ripples = ripples
    self.hoveredId = hoveredId
  }

  public func setCanvasSize(width: Double, height: Double) {
    self.width = width
    self.height = height
  }

  public func generateHotspots(count: Int) {
    guard width > 0, height > 0 else { return }
    let centerX = width / 2
    let centerY = height / 2
    let maxR = min(width, height) * 0.4
    hotspots = (0..<count).map { index in
      let radiusFactor = 0.2 + 0.8 * Double.random(in: 0...1)
      let radius = radiusFactor * maxR
      let theta = Double.random(in: 0...(Double.pi * 2))
      let x = centerX + radius * cos(theta)
      let y = centerY + radius * sin(theta)
      let region = GalaxyStore.region(for: atan2(y - centerY, x - centerX))
      return GalaxyHotspot(
        id: "hs_\(index)_\(UUID().uuidString)",
        xPercent: clamp((x / width) * 100),
        yPercent: clamp((y / height) * 100),
        region: region,
        seed: index
      )
    }
  }

  public func hover(atX x: Double, y: Double) {
    guard width > 0, height > 0 else { return }
    let targetX = clamp((x / width) * 100)
    let targetY = clamp((y / height) * 100)
    hoveredId = hotspots
      .map { hotspot -> (String, Double) in
        let dx = targetX - hotspot.xPercent
        let dy = targetY - hotspot.yPercent
        return (hotspot.id, hypot(dx, dy))
      }
      .filter { $0.1 < 8 }
      .min(by: { $0.1 < $1.1 })?
      .0
  }

  public func tap(atX x: Double, y: Double) {
    guard width > 0, height > 0 else { return }
    let rippleId = "rp_\(UUID().uuidString)"
    let start = Date()
    ripples.append(
      contentsOf: [
        GalaxyRipple(id: rippleId, x: x, y: y, startAt: start, duration: 0.9),
        GalaxyRipple(id: rippleId + "_2", x: x, y: y, startAt: start.addingTimeInterval(0.12), duration: 0.9)
      ]
    )
  }

  public func cleanupEffects() {
    let now = Date()
    ripples.removeAll { now.timeIntervalSince($0.startAt) > $0.duration }
  }

  private func clamp(_ value: Double) -> Double {
    max(0, min(100, value))
  }

  private static func region(for angle: Double) -> GalaxyRegion {
    let degrees = (angle * 180 / .pi + 360).truncatingRemainder(dividingBy: 360)
    switch degrees {
    case ..<120: return .emotion
    case ..<240: return .relation
    default: return .growth
    }
  }
}
