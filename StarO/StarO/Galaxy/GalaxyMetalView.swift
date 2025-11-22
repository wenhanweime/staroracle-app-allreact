import MetalKit
import SwiftUI
import simd
import UIKit
import QuartzCore
import StarOracleCore

struct GalaxyMetalContainer: View {
    @ObservedObject var viewModel: GalaxyViewModel
    var size: CGSize
    var onRegionSelected: ((GalaxyRegion) -> Void)?
    var onTap: ((CGPoint, CGSize, GalaxyRegion, TimeInterval) -> Void)?
    @State private var referenceDate: Date = Date()

    var body: some View {
        GeometryReader { _ in
            ZStack {
                GalaxyMetalView(viewModel: viewModel, canvasSize: size)
                    .frame(width: size.width, height: size.height)
                    .allowsHitTesting(false)
                
                GalaxyTouchOverlay { point, ts in
                    print(String(format: "[GalaxyMetalContainer] tap at (%.1f, %.1f) ts=%.3f", point.x, point.y, ts))
                    viewModel.onRegionSelected = onRegionSelected
                    viewModel.onTap = onTap
                    viewModel.handleTap(at: point, in: size, tapTimestamp: ts)
                }
                .frame(width: size.width, height: size.height)
            }
        }
        .task(id: size) {
            guard size.width > 0, size.height > 0 else { return }
            await MainActor.run {
                _ = viewModel.prepareIfNeeded(for: size)
                viewModel.onRegionSelected = onRegionSelected
                viewModel.onTap = onTap
                // Initial update only
                viewModel.update(elapsed: 0)
            }
        }
    }
    // ❌ drawPulses方法已完全移除
}

struct GalaxyMetalView: UIViewRepresentable {
    @ObservedObject var viewModel: GalaxyViewModel
    var canvasSize: CGSize
    
    @MainActor
    final class Coordinator: NSObject {
        weak var viewModel: GalaxyViewModel?
        var renderer: GalaxyMetalRenderer?
        var displayLink: CADisplayLink?
        var canvasSize: CGSize = .zero
        var startTime: CFTimeInterval = 0
        var currentElapsed: Double = 0
        var deviceScale: CGFloat = deviceScaleValue()
        
        // deinit removed to avoid concurrency violation.
        // CADisplayLink retains 'self', so deinit is only called after invalidate() breaks the cycle.
        
        @objc func tick(displayLink: CADisplayLink) { // Changed parameter name
            guard let viewModel, let renderer else { return } // Kept viewModel guard
            guard canvasSize.width > 0, canvasSize.height > 0 else { return } // Kept canvas size guard
            
            let currentTime = displayLink.timestamp
            if startTime == 0 { startTime = currentTime } // Changed startTime initialization
            currentElapsed = currentTime - startTime // Changed currentElapsed calculation
            
            // Update ViewModel time (for rotation cache and cleanup)
            // This might trigger SwiftUI updates if @Published properties change (e.g. pulses removed)
            viewModel.updateElapsedTimeOnly(elapsed: currentElapsed)
            
            // ❌ STOP per-frame vertex upload.
            // Vertices are now only rebuilt when viewModel structure changes (via updateUIView -> forceUpdate).
            // renderer.updateStarVertices(...) 
            
            // Note: Rendering is driven by MTKViewDelegate.draw(in:), which runs on the GPU cadence.
        }
        
        func ensureDisplayLink() {
            guard displayLink == nil else { return }
            let link = CADisplayLink(target: self, selector: #selector(tick(displayLink:))) // Updated selector
            link.add(to: .main, forMode: .common)
            displayLink = link
            startTime = CACurrentMediaTime()
            viewModel?.timeOrigin = startTime
        }
        
        func forceUpdate() {
            guard let viewModel, let renderer else { return }
            guard canvasSize.width > 0, canvasSize.height > 0 else { return }
            renderer.updateViewport(pointSize: canvasSize, scale: deviceScale)
            let vertices = GalaxyMetalView.buildVertices(
                viewModel: viewModel,
                size: canvasSize,
                elapsed: currentElapsed,
                deviceScale: deviceScale
            )
            if !vertices.isEmpty {
                renderer.updateStarVertices(vertices)
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    @MainActor
    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView(frame: .zero)
        mtkView.isUserInteractionEnabled = false
        mtkView.enableSetNeedsDisplay = false
        mtkView.isPaused = false
        mtkView.preferredFramesPerSecond = 60
        let scale = safeDeviceScale(for: mtkView)
        context.coordinator.deviceScale = scale
        updateDrawableSize(for: mtkView, canvasSize: canvasSize, scale: scale)
        
        if let renderer = GalaxyMetalRenderer(metalKitView: mtkView) {
            context.coordinator.renderer = renderer
            mtkView.delegate = renderer
            renderer.updateViewport(pointSize: canvasSize, scale: scale)
        } else {
            assertionFailure("Unable to create GalaxyMetalRenderer")
        }
        context.coordinator.viewModel = viewModel
        context.coordinator.canvasSize = canvasSize
        context.coordinator.ensureDisplayLink()
        context.coordinator.forceUpdate()
        #if DEBUG
        print("[Metal] makeUIView canvasSize:\(canvasSize) bounds:\(mtkView.bounds.size)")
        #endif
        return mtkView
    }

    @MainActor
    func updateUIView(_ uiView: MTKView, context: Context) {
        // Later we can propagate viewModel changes to renderer.
        if context.coordinator.renderer == nil {
            context.coordinator.renderer = GalaxyMetalRenderer(metalKitView: uiView)
            uiView.delegate = context.coordinator.renderer
        }
        context.coordinator.viewModel = viewModel
        context.coordinator.canvasSize = canvasSize
        let scale = safeDeviceScale(for: uiView)
        context.coordinator.deviceScale = scale
        updateDrawableSize(for: uiView, canvasSize: canvasSize, scale: scale)
        context.coordinator.renderer?.updateViewport(pointSize: canvasSize, scale: scale)
        #if DEBUG
        print("[Metal] updateUIView canvasSize:\(canvasSize) bounds:\(uiView.bounds.size) drawable:\(uiView.drawableSize)")
        #endif
        context.coordinator.forceUpdate()
    }
    
    static func dismantleUIView(_ uiView: MTKView, coordinator: Coordinator) {
        coordinator.displayLink?.invalidate()
    }
    
    private static func buildVertices(viewModel: GalaxyViewModel, size: CGSize, elapsed: Double, deviceScale: CGFloat) -> [GalaxyMetalRenderer.StarVertex] {
        guard size.width > 0, size.height > 0 else { return [] }
        var vertices: [GalaxyMetalRenderer.StarVertex] = []
        vertices.reserveCapacity(viewModel.backgroundStars.count + viewModel.rings.reduce(0) { $0 + $1.count } + viewModel.pulses.count)

        // 注意：deviceScale 现在传递给 Shader 的 Uniforms 使用，这里不再用于预乘位置
        // 但 size 仍然需要用于计算初始偏移（居中）
        
        let offsetX = (viewModel.bandSize.width - size.width) * 0.5
        let offsetY = (viewModel.bandSize.height - size.height) * 0.5

        let backgroundColor = hexToColor("#D0D4DB", alpha: 0.55)
        for star in viewModel.backgroundStars {
            // 背景星不旋转，ringIndex = -1
            // 位置相对于中心点的偏移
            // 原始逻辑：star.position 是在 bandSize 坐标系下的绝对位置
            // 我们需要将其转换为相对于屏幕中心的偏移，以便 Shader 应用缩放
            
            let bandCenter = CGPoint(x: viewModel.bandSize.width / 2.0, y: viewModel.bandSize.height / 2.0)
            let dx = Float(star.position.x - bandCenter.x)
            let dy = Float(star.position.y - bandCenter.y)
            
            let s = Float(viewModel.params.galaxyScale)
            let position = SIMD2<Float>(dx, dy) * s
            let sizeValue = max(0.6, Float(star.size))
            // Type 0: Background
            vertices.append(.init(initialPosition: position, size: sizeValue, type: 0.0, color: backgroundColor, highlightStartTime: 0, ringIndex: -1.0, highlightDuration: 0))
        }

        // let now = CACurrentMediaTime() // 不需要了，时间由 GPU 统一管理
        let highlightDuration: Float = 0.60

        var normalVertices: [GalaxyMetalRenderer.StarVertex] = []
        var highlightedBaseVertices: [GalaxyMetalRenderer.StarVertex] = []
        var litVertices: [GalaxyMetalRenderer.StarVertex] = []
        // 预分配数组空间
        litVertices.reserveCapacity(50)

        for (ringIndex, ring) in viewModel.rings.enumerated() {
            for star in ring {
                // 核心修改：不再调用 screenPosition 计算旋转后的位置
                // 而是直接计算相对于 bandCenter 的初始偏移
                let bandCenter = CGPoint(x: star.bandSize.width / 2.0, y: star.bandSize.height / 2.0)
                let dx = Float(star.position.x - bandCenter.x)
                let dy = Float(star.position.y - bandCenter.y)
                let s = Float(viewModel.params.galaxyScale)
                let initialPos = SIMD2<Float>(dx, dy) * s
                
                let baseSize = max(0.8, Float(star.size))
                // 基础颜色：如果高亮，则使用 litHex（常亮高亮色），否则使用 displayHex（暗色）
                let isHighlighted = viewModel.isHighlighted(star)
                // 高亮基础层颜色：对齐提交 cf1de85...，采用 litHex 与 #5AE7FF 的混合色
                let layerAlpha = Float(max(0.0, min(1.0, viewModel.alpha(for: star))))
                let baseAlpha = isHighlighted ? max(layerAlpha, 0.95) : layerAlpha
                let baseColor: SIMD4<Float>
                if isHighlighted {
                    // 基础高亮色保持提交风格：litHex 与 #5AE7FF 的混合色，不参与纯白/绿色随机
                    baseColor = GalaxyMetalView.blendHex(star.litHex, with: "#5AE7FF", ratio: 0.45, alpha: baseAlpha)
                } else {
                    baseColor = hexToColor(star.displayHex, alpha: baseAlpha)
                }
                
                let rIndex = Float(ringIndex)
                // 基础层：区分普通与高亮，确保高亮的基础层始终绘制在最上层（避免被后续普通星覆盖）
                // Type 0: Normal/Base
                let baseVertex = GalaxyMetalRenderer.StarVertex(initialPosition: initialPos, size: baseSize, type: 0.0, color: baseColor, highlightStartTime: 0, ringIndex: rIndex, highlightDuration: 0)
                if isHighlighted {
                    highlightedBaseVertices.append(baseVertex)
                } else {
                    normalVertices.append(baseVertex)
                }
                
                // 2. Lit Layer (高亮时光晕层) - 存入单独数组，稍后追加
                if let highlight = viewModel.highlights[star.id] {
                    // 仅在动画时窗内追加 Lit 顶点，避免颜色残留
                    let now = CACurrentMediaTime()
                    let hElapsed = now - highlight.activatedAt
                    if hElapsed >= 0 && hElapsed < Double(highlightDuration) {
                    // Type 1: Lit Star (GPU Animation)
                    // 直接使用目标高亮色（去除“偏白”混合），避免初始帧出现纯白后再“染色”的体验问题
                    let litAlpha: Float = 1.0 // Shader 将按强度调制 alpha
                    let litColor = GalaxyMetalView.blendHex(star.litHex, with: "#5AE7FF", ratio: 0.45, alpha: litAlpha)
                        let relativeStart = Float(highlight.activatedAt - now + elapsed)
                        litVertices.append(.init(initialPosition: initialPos, size: baseSize, type: 1.0, color: litColor, highlightStartTime: relativeStart, ringIndex: rIndex, highlightDuration: highlightDuration))
                    }
                }
            }
        }
        // 装配最终顶点顺序：背景 -> 普通基础层 -> 高亮基础层 -> 高亮叠加层
        vertices.append(contentsOf: normalVertices)
        vertices.append(contentsOf: highlightedBaseVertices)
        vertices.append(contentsOf: litVertices)
        
        // 已移除脉冲渲染（Type 2），只保留星点高亮层

        // 移除每帧调试输出，避免影响渲染流畅度

        return vertices
    }

    private static func hexToColor(_ hex: String, alpha: Float) -> SIMD4<Float> {
        var value = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if !value.hasPrefix("#") {
            value = "#\(value)"
        }
        if value.count == 4 {
            let chars = Array(value)
            value = "#\(chars[1])\(chars[1])\(chars[2])\(chars[2])\(chars[3])\(chars[3])"
        }
        guard value.count == 7 else {
            return SIMD4<Float>(repeating: alpha)
        }
        let hexString = String(value.dropFirst())
        var intValue: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&intValue)
        let r = Float((intValue & 0xFF0000) >> 16) / 255.0
        let g = Float((intValue & 0x00FF00) >> 8) / 255.0
        let b = Float(intValue & 0x0000FF) / 255.0
        return SIMD4<Float>(r, g, b, alpha)
    }
    
    private static func blendHex(_ base: String, with tint: String, ratio: Float, alpha: Float) -> SIMD4<Float> {
        // ratio: 0..1, mix base->tint
        let a = hexToColor(base, alpha: 1.0)
        let b = hexToColor(tint, alpha: 1.0)
        let t = max(0.0, min(1.0, ratio))
        let r = a.x + (b.x - a.x) * t
        let g = a.y + (b.y - a.y) * t
        let bch = a.z + (b.z - a.z) * t
        return SIMD4<Float>(r, g, bch, alpha)
    }

    private static func mixColor(_ a: SIMD4<Float>, _ b: SIMD4<Float>, t: Float) -> SIMD4<Float> {
        let tt = max(0.0, min(1.0, t))
        let r = a.x + (b.x - a.x) * tt
        let g = a.y + (b.y - a.y) * tt
        let bl = a.z + (b.z - a.z) * tt
        let al = a.w + (b.w - a.w) * tt
        return SIMD4<Float>(r, g, bl, al)
    }
    
    private static func colorToSIMD(_ color: Color, alpha: Float) -> SIMD4<Float> {
#if canImport(UIKit)
        let uiColor = UIColor(color)
        var r: CGFloat = 1, g: CGFloat = 1, b: CGFloat = 1, a: CGFloat = CGFloat(alpha)
        if uiColor.getRed(&r, green: &g, blue: &b, alpha: &a) {
            return SIMD4<Float>(Float(r), Float(g), Float(b), Float(alpha))
        }
#endif
        return SIMD4<Float>(repeating: alpha)
    }
}

@MainActor
private func updateDrawableSize(for view: MTKView, canvasSize: CGSize, scale: CGFloat) {
    let safeScale = max(scale.isFinite ? scale : deviceScaleValue(), 1.0)
    let drawableSize = CGSize(
        width: max(canvasSize.width, 0) * safeScale,
        height: max(canvasSize.height, 0) * safeScale
    )
    if view.drawableSize != drawableSize {
        view.drawableSize = drawableSize
    }
}

@MainActor
private func deviceScaleValue() -> CGFloat {
#if canImport(UIKit)
    return UIScreen.main.scale
#elseif canImport(AppKit)
    return NSScreen.main?.backingScaleFactor ?? 1.0
#else
    return 1.0
#endif
}

@MainActor
private func safeDeviceScale(for view: MTKView) -> CGFloat {
#if canImport(UIKit)
    let scale = view.contentScaleFactor
    if scale.isFinite, scale >= 1.0 {
        return scale
    }
    return max(UIScreen.main.scale, 1.0)
#elseif canImport(AppKit)
    if let layerScale = view.layer?.contentsScale, layerScale.isFinite, layerScale >= 1.0 {
        return layerScale
    }
    if let screenScale = NSScreen.main?.backingScaleFactor, screenScale.isFinite, screenScale >= 1.0 {
        return screenScale
    }
    return 1.0
#else
    return 1.0
#endif
}
