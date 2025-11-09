import SwiftUI
import StarOracleCore

public struct GlassBackground<S: Shape>: View {
  private let shape: S
  private let blurRadius: CGFloat
  private let opacity: Double

  public init(shape: S, blurRadius: CGFloat = 20, opacity: Double = 0.2) {
    self.shape = shape
    self.blurRadius = blurRadius
    self.opacity = opacity
  }

  public var body: some View {
    ZStack {
      shape
        .fill(.ultraThinMaterial)
        .blur(radius: blurRadius)
        .opacity(opacity)
      shape
        .stroke(Color.white.opacity(0.3), lineWidth: 1)
    }
  }
}

public extension View {
  func glassBackground<S: Shape>(
    _ shape: S,
    blurRadius: CGFloat = 20,
    opacity: Double = 0.2
  ) -> some View {
    background(
      GlassBackground(shape: shape, blurRadius: blurRadius, opacity: opacity)
    )
  }
}
