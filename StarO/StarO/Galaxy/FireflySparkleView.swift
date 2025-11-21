import SwiftUI
import QuartzCore

@MainActor
final class FireflySimulation: ObservableObject {
    struct Particle: Identifiable {
        let id = UUID()
        var position: CGPoint
        var velocity: CGPoint
        var lifeSpan: TimeInterval
        var age: TimeInterval = 0
        var baseSize: CGFloat
    }

    @Published private(set) var particles: [Particle] = []

    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0
    private let maxParticles = 260
    private var bounds: CGSize = .zero

    func start(in size: CGSize) {
        bounds = size
        stop()
        lastTimestamp = 0
        let link = CADisplayLink(target: self, selector: #selector(step))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
    }

    func updateBounds(_ size: CGSize) {
        bounds = size
    }

    // deinit removed to avoid concurrency violation. 
    // CADisplayLink retains 'self', so deinit is only called after invalidate() breaks the cycle.
    // Cleanup must be done in stop().

    @objc private func step(link: CADisplayLink) {
        guard bounds.width > 0, bounds.height > 0 else { return }
        if lastTimestamp == 0 {
            lastTimestamp = link.timestamp
            return
        }
        let dt = link.timestamp - lastTimestamp
        lastTimestamp = link.timestamp
        evolve(dt: dt)
    }

    func emit(at point: CGPoint) {
        guard bounds.width > 0, bounds.height > 0 else { return }
        var emitted: [Particle] = []
        let count = Int.random(in: 24...36)
        for _ in 0..<count {
            var position = point
            position.x += CGFloat.random(in: -14...14)
            position.y += CGFloat.random(in: -14...14)
            let speed = CGFloat.random(in: 20...60)
            let angle = CGFloat.random(in: 0...(CGFloat.pi * 2))
            let velocity = CGPoint(
                x: CGFloat(cos(Double(angle))) * speed,
                y: CGFloat(sin(Double(angle))) * speed
            )
            let lifeSpan = TimeInterval.random(in: 0.5...0.9)
            let size = CGFloat.random(in: 2.5...4.0)
            emitted.append(
                Particle(
                    position: position,
                    velocity: velocity,
                    lifeSpan: lifeSpan,
                    baseSize: size
                )
            )
        }
        particles.append(contentsOf: emitted)
        if particles.count > maxParticles {
            particles = Array(particles.suffix(maxParticles))
        }
        print("[FireflySimulation] emitted \(emitted.count) particles (total: \(particles.count)) at (\(point.x), \(point.y))")
    }

    private func evolve(dt: TimeInterval) {
        var nextParticles: [Particle] = []
        nextParticles.reserveCapacity(particles.count)

        for var particle in particles {
            var updated = particle
            updated.age += dt
            if updated.age >= updated.lifeSpan {
                continue
            }
            updated.position.x += updated.velocity.x * dt
            updated.position.y += updated.velocity.y * dt
            wrap(&updated.position)
            nextParticles.append(updated)
        }

        // ❌ 禁用自动生成萤火虫粒子（只在点击时生成）
        /*
        let spawnCount = Int.random(in: 0...4)
        for _ in 0..<spawnCount {
            guard nextParticles.count < maxParticles else { break }
            let position = CGPoint(
                x: CGFloat.random(in: 0...bounds.width),
                y: CGFloat.random(in: 0...bounds.height)
            )
            let speed = CGFloat.random(in: 10...26)
            let angle = CGFloat.random(in: 0...(CGFloat.pi * 2))
            let velocity = CGPoint(
                x: CGFloat(cos(Double(angle))) * speed,
                y: CGFloat(sin(Double(angle))) * speed
            )
            let lifeSpan = TimeInterval.random(in: 1.0...1.6)
            let size = CGFloat.random(in: 3.0...4.0)
            let particle = Particle(
                position: position,
                velocity: velocity,
                lifeSpan: lifeSpan,
                baseSize: size
            )
            nextParticles.append(particle)
        }
        */


        particles = nextParticles
    }

    private func wrap(_ point: inout CGPoint) {
        if point.x < 0 { point.x += bounds.width }
        if point.x > bounds.width { point.x -= bounds.width }
        if point.y < 0 { point.y += bounds.height }
        if point.y > bounds.height { point.y -= bounds.height }
    }

}

struct FireflySparkleView: View {
    var size: CGSize
    @ObservedObject var simulation: FireflySimulation

    var body: some View {
        Canvas { context, _ in
            context.blendMode = .plusLighter
            for particle in simulation.particles {
                let progress = particle.age / max(particle.lifeSpan, 0.001)
                let pulse = sin(progress * .pi)
                let opacity = max(0.0, Double(pulse))
                let radius = particle.baseSize * CGFloat(1 + progress * 10)
                let rect = CGRect(
                    x: particle.position.x - radius / 2,
                    y: particle.position.y - radius / 2,
                    width: radius,
                    height: radius
                )
                let color = Color.yellow.opacity(opacity)
                context.fill(
                    Path(ellipseIn: rect),
                    with: .color(color)
                )
            }
        }
        .frame(width: size.width, height: size.height)
        .allowsHitTesting(false)
        .onAppear {
            simulation.start(in: size)
        }
        .onDisappear {
            simulation.stop()
        }
        .onChange(of: size) { newValue in
            simulation.updateBounds(newValue)
        }
    }
}
