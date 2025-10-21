import UIKit
import QuartzCore
import Capacitor

// MARK: - 渲染质量定义
enum GalaxyRenderQuality: String {
    case low
    case mid
    case high
    case auto

    static func from(_ raw: String?) -> GalaxyRenderQuality {
        guard let raw = raw?.lowercased() else { return .auto }
        return GalaxyRenderQuality(rawValue: raw) ?? .auto
    }
}

// MARK: - 高亮数据模型
struct GalaxyHighlightPayload {
    let id: String
    let point: CGPoint?
    let color: UIColor
    let intensity: CGFloat
}

// MARK: - 星河背景View
final class GalaxyBackgroundView: UIView {
    private enum Constants {
        static let rotationKey = "com.stararacle.galaxy.rotation"
        static let pulsationKey = "com.stararacle.galaxy.highlight"
    }

    private let starLayer = CAEmitterLayer()
    private let dustLayer = CAEmitterLayer()
    private let highlightContainer = CALayer()
    private var highlights: [String: CAShapeLayer] = [:]
    private var currentQuality: GalaxyRenderQuality = .mid
    private var reducedMotion: Bool = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        isUserInteractionEnabled = false
        layer.masksToBounds = true
        backgroundColor = UIColor(red: 3/255, green: 5/255, blue: 14/255, alpha: 1)

        configureEmitter(layer: starLayer, isDust: false)
        configureEmitter(layer: dustLayer, isDust: true)

        layer.addSublayer(starLayer)
        layer.addSublayer(dustLayer)
        layer.addSublayer(highlightContainer)

        startRotation()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let bounds = self.bounds
        [starLayer, dustLayer].forEach { emitter in
            emitter.frame = bounds
            emitter.emitterPosition = CGPoint(x: bounds.midX, y: bounds.midY)
            emitter.emitterSize = CGSize(width: bounds.width, height: bounds.height)
        }
        highlightContainer.frame = bounds
    }

    private func configureEmitter(layer: CAEmitterLayer, isDust: Bool) {
        layer.emitterShape = .circle
        layer.emitterMode = .surface
        layer.renderMode = .additive
        layer.scale = 1.0

        let cell = CAEmitterCell()
        cell.contents = makeStarImage(isDust: isDust)?.cgImage
        cell.birthRate = isDust ? 22 : 40
        cell.lifetime = isDust ? 60 : 45
        cell.velocity = isDust ? 6 : 12
        cell.velocityRange = isDust ? 4 : 10
        cell.emissionRange = .pi * 2
        cell.scale = isDust ? 0.4 : 0.8
        cell.scaleRange = isDust ? 0.2 : 0.5
        cell.alphaSpeed = -0.002
        cell.color = (isDust ? UIColor(white: 0.9, alpha: 0.55) : UIColor.white).cgColor

        layer.emitterCells = [cell]
    }

    private func makeStarImage(isDust: Bool) -> UIImage? {
        let size = CGSize(width: isDust ? 3 : 4, height: isDust ? 3 : 4)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        context.setFillColor(UIColor.white.cgColor)
        context.setAlpha(isDust ? 0.6 : 1.0)
        context.fillEllipse(in: CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    private func startRotation() {
        guard layer.animation(forKey: Constants.rotationKey) == nil else { return }
        let animation = CABasicAnimation(keyPath: "transform.rotation.z")
        animation.fromValue = 0
        animation.toValue = Double.pi * 2
        animation.duration = 120
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        layer.add(animation, forKey: Constants.rotationKey)
    }

    private func stopRotation() {
        layer.removeAnimation(forKey: Constants.rotationKey)
    }

    func apply(quality: GalaxyRenderQuality, reducedMotion: Bool) {
        currentQuality = quality
        self.reducedMotion = reducedMotion

        let resolvedQuality: GalaxyRenderQuality = quality == .auto ? .mid : quality
        let config = configuration(for: resolvedQuality)

        if reducedMotion {
            stopRotation()
        } else {
            startRotation()
        }

        apply(config: config)
    }

    private func configuration(for quality: GalaxyRenderQuality) -> (starBirth: Float, dustBirth: Float, velocity: CGFloat) {
        switch quality {
        case .low:
            return (starBirth: 25, dustBirth: 12, velocity: 6)
        case .mid:
            return (starBirth: 40, dustBirth: 22, velocity: 10)
        case .high, .auto:
            return (starBirth: 60, dustBirth: 28, velocity: 14)
        }
    }

    private func apply(config: (starBirth: Float, dustBirth: Float, velocity: CGFloat)) {
        starLayer.birthRate = config.starBirth
        dustLayer.birthRate = config.dustBirth

        starLayer.emitterCells?.forEach { cell in
            cell.velocity = config.velocity
        }
        dustLayer.emitterCells?.forEach { cell in
            cell.velocity = config.velocity * 0.5
        }
    }

    func setPaused(_ paused: Bool) {
        let speed: Float = paused ? 0 : 1
        layer.speed = speed
        highlightContainer.speed = speed
    }

    func setHighlights(_ payloads: [GalaxyHighlightPayload]) {
        let incomingIds = Set(payloads.map { $0.id })

        // 移除不存在的高亮
        for (id, layer) in highlights where !incomingIds.contains(id) {
            layer.removeAllAnimations()
            layer.removeFromSuperlayer()
            highlights.removeValue(forKey: id)
        }

        for payload in payloads {
            let layer = highlights[payload.id] ?? makeHighlightLayer()
            if highlights[payload.id] == nil {
                highlights[payload.id] = layer
                highlightContainer.addSublayer(layer)
            }

            let targetPoint: CGPoint
            if let point = payload.point {
                targetPoint = convertNormalized(point)
            } else {
                // 默认随机散布
                let x = CGFloat.random(in: 0.2...0.8)
                let y = CGFloat.random(in: 0.2...0.8)
                targetPoint = convertNormalized(CGPoint(x: x, y: y))
            }

            CATransaction.begin()
            CATransaction.setDisableActions(true)
            layer.position = targetPoint
            layer.bounds = CGRect(x: 0, y: 0, width: 120 * payload.intensity, height: 120 * payload.intensity)
            layer.backgroundColor = payload.color.withAlphaComponent(0.35).cgColor
            CATransaction.commit()

            if layer.animation(forKey: Constants.pulsationKey) == nil && !reducedMotion {
                let animation = CABasicAnimation(keyPath: "transform.scale")
                animation.fromValue = 0.7
                animation.toValue = 1.4
                animation.duration = 1.8
                animation.autoreverses = true
                animation.repeatCount = .infinity
                animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                layer.add(animation, forKey: Constants.pulsationKey)
            }
        }
    }

    func clearHighlights() {
        highlights.values.forEach { layer in
            layer.removeAllAnimations()
            layer.removeFromSuperlayer()
        }
        highlights.removeAll()
    }

    private func makeHighlightLayer() -> CAShapeLayer {
        let layer = CAShapeLayer()
        layer.cornerRadius = 60
        layer.masksToBounds = true
        layer.shadowColor = UIColor.white.cgColor
        layer.shadowRadius = 18
        layer.shadowOpacity = 0.7
        layer.shadowOffset = .zero
        return layer
    }

    private func convertNormalized(_ point: CGPoint) -> CGPoint {
        let x = bounds.width * min(max(point.x, 0), 1)
        let y = bounds.height * min(max(point.y, 0), 1)
        return CGPoint(x: x, y: y)
    }
}

// MARK: - 管理器
final class GalaxyBackgroundManager {
    private weak var bridge: CAPBridgeProtocol?
    private weak var galaxyView: GalaxyBackgroundView?
    private var currentQuality: GalaxyRenderQuality = .auto
    private var reducedMotion: Bool = false
    private var mode: String = "web"
    private var observers: [NSObjectProtocol] = []

    deinit {
        cleanupObservers()
    }

    func attach(to bridge: CAPBridgeProtocol) {
        self.bridge = bridge
        DispatchQueue.main.async { [weak self] in
            self?.ensureViewHierarchy()
        }
        registerObservers()
    }

    private func ensureViewHierarchy() {
        guard let bridge = bridge,
              let container = bridge.viewController?.view,
              galaxyView == nil else { return }

        let view = GalaxyBackgroundView(frame: container.bounds)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = (mode != "native")

        if let webView = bridge.webView {
            container.insertSubview(view, belowSubview: webView)
        } else {
            container.addSubview(view)
        }

        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            view.topAnchor.constraint(equalTo: container.topAnchor),
            view.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        galaxyView = view
        applyCurrentConfiguration()
    }

    private func registerObservers() {
        cleanupObservers()

        let center = NotificationCenter.default
        let willResign = center.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: .main) { [weak self] _ in
            self?.galaxyView?.setPaused(true)
        }
        let didBecomeActive = center.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            self?.galaxyView?.setPaused(false)
        }
        let reduceMotion = center.addObserver(forName: UIAccessibility.reduceMotionStatusDidChangeNotification, object: nil, queue: .main) { [weak self] _ in
            guard let self = self else { return }
            self.reducedMotion = UIAccessibility.isReduceMotionEnabled
            self.galaxyView?.apply(quality: self.currentQuality, reducedMotion: self.reducedMotion)
        }

        observers = [willResign, didBecomeActive, reduceMotion]
    }

    private func cleanupObservers() {
        let center = NotificationCenter.default
        observers.forEach { center.removeObserver($0) }
        observers.removeAll()
    }

    func configure(quality: GalaxyRenderQuality, reducedMotion: Bool?) {
        currentQuality = quality
        if let reducedMotion = reducedMotion {
            self.reducedMotion = reducedMotion
        } else {
            self.reducedMotion = UIAccessibility.isReduceMotionEnabled
        }
        DispatchQueue.main.async { [weak self] in
            self?.ensureViewHierarchy()
            self?.applyCurrentConfiguration()
        }
    }

    func setMode(_ mode: String) {
        self.mode = mode
        DispatchQueue.main.async { [weak self] in
            self?.ensureViewHierarchy()
            self?.galaxyView?.isHidden = (mode != "native")
        }
    }

    func setHighlights(_ highlights: [GalaxyHighlightPayload]) {
        DispatchQueue.main.async { [weak self] in
            self?.galaxyView?.setHighlights(highlights)
        }
    }

    func clearHighlights() {
        DispatchQueue.main.async { [weak self] in
            self?.galaxyView?.clearHighlights()
        }
    }

    private func applyCurrentConfiguration() {
        guard let view = galaxyView else { return }
        let resolvedQuality = resolveQuality(currentQuality)
        view.apply(quality: resolvedQuality, reducedMotion: reducedMotion)
    }

    private func resolveQuality(_ quality: GalaxyRenderQuality) -> GalaxyRenderQuality {
        guard quality == .auto else { return quality }

        let screen = UIScreen.main
        let maxDimension = max(screen.bounds.width, screen.bounds.height)
        let scale = screen.scale

        if UIAccessibility.isReduceMotionEnabled {
            return .low
        }

        if maxDimension >= 800 && scale >= 3 {
            return .high
        }

        if maxDimension >= 650 {
            return .mid
        }

        return .low
    }
}
