import SwiftUI
import UIKit
import QuartzCore

final class GalaxyTouchUIView: UIView {
    var onTap: ((CGPoint, CFTimeInterval) -> Void)?
    var isTapEnabled: Bool = true
    private static let sparkleImage: CGImage = {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 48, height: 48))
        let image = renderer.image { context in
            let cg = context.cgContext
            cg.setAllowsAntialiasing(true)
            cg.setShouldAntialias(true)

            let center = CGPoint(x: 24, y: 24)
            let longRadius = CGFloat(20)
            let shortRadius = CGFloat(5)
            let path = UIBezierPath()
            for index in 0..<8 {
                let angle = CGFloat(index) * (.pi / 4)
                let radius = (index % 2 == 0) ? longRadius : shortRadius
                let point = CGPoint(
                    x: center.x + radius * CGFloat(cos(Double(angle))),
                    y: center.y + radius * CGFloat(sin(Double(angle)))
                )
                index == 0 ? path.move(to: point) : path.addLine(to: point)
            }
            path.close()
            let colors = [UIColor(white: 1, alpha: 1).cgColor, UIColor(white: 1, alpha: 0).cgColor] as CFArray
            let locations: [CGFloat] = [0, 1]
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: locations) {
                cg.saveGState()
                path.addClip()
                cg.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: longRadius, options: .drawsAfterEndLocation)
                cg.restoreGState()
            }
            cg.setFillColor(UIColor.white.cgColor)
            cg.fillEllipse(in: CGRect(x: center.x - 2, y: center.y - 2, width: 4, height: 4))
        }
        return image.cgImage ?? UIImage(systemName: "star.fill")!.cgImage!
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
        backgroundColor = .clear
        isMultipleTouchEnabled = false
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var startLocation: CGPoint?

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard let touch = touches.first else { return }
        startLocation = touch.location(in: self)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        guard isTapEnabled else { return }
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // Check for drag/swipe
        if let start = startLocation {
            let dx = location.x - start.x
            let dy = location.y - start.y
            let distance = sqrt(dx*dx + dy*dy)
            if distance > 10.0 {
                print("[TouchOverlay] drag detected (distance: \(distance)), ignoring tap")
                startLocation = nil
                return
            }
        }
        
        let timestamp = touch.timestamp
        print("[TouchOverlay] tap at (\(location.x), \(location.y)) ts=\(timestamp)")
        // ❌ 已禁用粒子爆炸
        // burst(at: location)
        onTap?(location, timestamp)
        startLocation = nil
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        startLocation = nil
    }

    private func burst(at point: CGPoint) {
        let emitter = CAEmitterLayer()
        emitter.emitterPosition = point
        emitter.emitterShape = .point
        emitter.renderMode = .additive

        let cell = CAEmitterCell()
        cell.contents = Self.sparkleImage
        cell.birthRate = 0
        cell.lifetime = 0.35
        cell.lifetimeRange = 0.15
        cell.alphaSpeed = -2.0
        cell.scale = 0.6
        cell.scaleRange = 0.2
        cell.scaleSpeed = -1.2
        cell.velocity = 42
        cell.velocityRange = 28
        cell.emissionRange = .pi * 2
        cell.spin = 4
        cell.spinRange = 6

        emitter.emitterCells = [cell]
        layer.addSublayer(emitter)

        emitter.beginTime = CACurrentMediaTime()
        emitter.setValue(24, forKeyPath: "emitterCells.spark.birthRate")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            emitter.setValue(0, forKeyPath: "emitterCells.spark.birthRate")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            emitter.removeFromSuperlayer()
        }
    }
}

struct GalaxyTouchOverlay: UIViewRepresentable {
    final class Coordinator {
        var onTapClosure: (CGPoint, CFTimeInterval) -> Void

        init(onTap: @escaping (CGPoint, CFTimeInterval) -> Void) {
            self.onTapClosure = onTap
        }

        func handleTap(_ point: CGPoint, _ timestamp: CFTimeInterval) {
            onTapClosure(point, timestamp)
        }
    }

    var onTap: (CGPoint, CFTimeInterval) -> Void
    var isTapEnabled: Bool = true

    func makeCoordinator() -> Coordinator {
        Coordinator(onTap: onTap)
    }

    func makeUIView(context: Context) -> GalaxyTouchUIView {
        let view = GalaxyTouchUIView(frame: .zero)
        view.isTapEnabled = isTapEnabled
        context.coordinator.onTapClosure = onTap
        view.onTap = { point, ts in
            context.coordinator.handleTap(point, ts)
        }
        return view
    }

    func updateUIView(_ uiView: GalaxyTouchUIView, context: Context) {
        uiView.isTapEnabled = isTapEnabled
        context.coordinator.onTapClosure = onTap
        uiView.onTap = { point, ts in
            context.coordinator.handleTap(point, ts)
        }
    }
}
