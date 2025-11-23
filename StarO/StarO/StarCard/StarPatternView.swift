import SwiftUI

struct StarPatternView: View {
    let config: StarCardConfig
    let color: Color
    
    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let center = CGPoint(x: proxy.size.width/2, y: proxy.size.height/2)
            
            ZStack {
                switch config.style {
                case .standard:
                    StandardStarView(color: color, size: size)
                case .cross:
                    CrossStarView(color: color, size: size)
                case .burst:
                    BurstStarView(color: color, seed: config.seed, size: size)
                case .sparkle:
                    SparkleStarView(color: color, seed: config.seed, size: size)
                case .ringed:
                    RingedStarView(color: color, hasRing: config.hasRing, size: size)
                default:
                    EmptyView()
                }
            }
            .position(center)
        }
    }
}

// MARK: - Subviews

private struct StandardStarView: View {
    let color: Color
    let size: CGFloat
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            ForEach(0..<8) { i in
                RayLine(angle: .degrees(Double(i) * 45), length: size * 0.2)
                    .stroke(color, lineWidth: size * 0.01)
                    .opacity(isAnimating ? 0.8 : 0)
                    .animation(
                        Animation.easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.1),
                        value: isAnimating
                    )
            }
        }
        .onAppear { isAnimating = true }
    }
}

private struct CrossStarView: View {
    let color: Color
    let size: CGFloat
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            ForEach(0..<4) { i in
                let isVertical = i % 2 == 0
                Rectangle()
                    .fill(color)
                    .frame(
                        width: isVertical ? size * 0.01 : size * 0.15,
                        height: isVertical ? size * 0.15 : size * 0.01
                    )
                    .scaleEffect(isAnimating ? 1 : 0)
                    .opacity(isAnimating ? 0.8 : 0)
                    .rotationEffect(.degrees(isAnimating ? 180 : 0))
                    .animation(
                        Animation.easeInOut(duration: 2.0)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.2),
                        value: isAnimating
                    )
            }
        }
        .onAppear { isAnimating = true }
    }
}

private struct BurstStarView: View {
    let color: Color
    let seed: UInt64
    let size: CGFloat
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            ForEach(0..<12) { i in
                let randomLen = (Double((seed &+ UInt64(i)) % 30) + 20.0) / 50.0 * (size * 0.25)
                let randomWidth = (Double((seed &+ UInt64(i*2)) % 15) / 10.0 + 0.5) * (size * 0.005)
                
                RayLine(angle: .degrees(Double(i) * 30), length: randomLen)
                    .stroke(color, lineWidth: randomWidth)
                    .opacity(isAnimating ? 0.7 : 0)
                    .animation(
                        Animation.easeInOut(duration: 2.0 + Double((seed &+ UInt64(i)) % 10)/10.0)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.05),
                        value: isAnimating
                    )
            }
        }
        .onAppear { isAnimating = true }
    }
}

private struct SparkleStarView: View {
    let color: Color
    let seed: UInt64
    let size: CGFloat
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            ForEach(0..<8) { i in
                let angle = Double(i) * .pi / 4
                let dist = (15.0 + Double((seed &+ UInt64(i)) % 20)) / 35.0 * (size * 0.2)
                let r = (1.0 + Double((seed &+ UInt64(i*3)) % 20) / 10.0) * (size * 0.01)
                
                Circle()
                    .fill(color)
                    .frame(width: r*2, height: r*2)
                    .offset(x: cos(angle) * dist, y: sin(angle) * dist)
                    .scaleEffect(isAnimating ? 1 : 0)
                    .opacity(isAnimating ? 0.9 : 0)
                    .animation(
                        Animation.easeInOut(duration: 1.0 + Double((seed &+ UInt64(i)) % 10)/10.0)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.1),
                        value: isAnimating
                    )
            }
        }
        .onAppear { isAnimating = true }
    }
}

private struct RingedStarView: View {
    let color: Color
    let hasRing: Bool
    let size: CGFloat
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            if !hasRing {
                Circle()
                    .stroke(color, style: StrokeStyle(lineWidth: size * 0.005, dash: [size * 0.005, size * 0.01]))
                    .frame(width: size * 0.15, height: size * 0.15)
                    .scaleEffect(isAnimating ? 1.2 : 1.0)
                    .opacity(isAnimating ? 0.6 : 0.3)
                    .animation(
                        Animation.easeInOut(duration: 3.0)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
            }
        }
        .onAppear { isAnimating = true }
    }
}

// MARK: - Shapes

private struct RayLine: Shape {
    let angle: Angle
    let length: Double
    
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let end = CGPoint(
            x: center.x + cos(angle.radians) * length,
            y: center.y + sin(angle.radians) * length
        )
        var path = Path()
        path.move(to: center)
        path.addLine(to: end)
        return path
    }
}
