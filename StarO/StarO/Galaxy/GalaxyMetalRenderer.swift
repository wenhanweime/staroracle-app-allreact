import Foundation
import MetalKit

@MainActor
final class GalaxyMetalRenderer: NSObject, MTKViewDelegate {
    struct StarVertex {
        var initialPosition: SIMD2<Float>
        var size: Float
        var type: Float
        var color: SIMD4<Float>
        var progress: Float
        var ringIndex: Float
    }

    struct Uniforms {
        var time: Float
        var viewportSizePixels: SIMD2<Float>
        var scale: Float
    }

    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private var pipelineState: MTLRenderPipelineState?
    private var vertexBuffer: MTLBuffer?
    private var starCount: Int = 0
    private var viewportSizePoints: SIMD2<Float> = SIMD2<Float>(1, 1)
    private var viewportSizePixels: SIMD2<Float> = SIMD2<Float>(1, 1)
    private var viewportScale: Float = 1.0
    private var vertexDescriptor: MTLVertexDescriptor = {
        let descriptor = MTLVertexDescriptor()
        // Attribute 0: initialPosition (float2)
        descriptor.attributes[0].format = .float2
        descriptor.attributes[0].offset = 0
        descriptor.attributes[0].bufferIndex = 0
        
        // Attribute 1: size (float)
        descriptor.attributes[1].format = .float
        descriptor.attributes[1].offset = MemoryLayout<SIMD2<Float>>.stride
        descriptor.attributes[1].bufferIndex = 0
        
        // Attribute 2: type (float)
        descriptor.attributes[2].format = .float
        descriptor.attributes[2].offset = MemoryLayout<SIMD2<Float>>.stride + MemoryLayout<Float>.stride
        descriptor.attributes[2].bufferIndex = 0
        
        // Attribute 3: color (float4)
        descriptor.attributes[3].format = .float4
        descriptor.attributes[3].offset = MemoryLayout<SIMD2<Float>>.stride + MemoryLayout<Float>.stride * 2
        descriptor.attributes[3].bufferIndex = 0
        
        // Attribute 4: progress (float)
        descriptor.attributes[4].format = .float
        descriptor.attributes[4].offset = MemoryLayout<SIMD2<Float>>.stride + MemoryLayout<Float>.stride * 2 + MemoryLayout<SIMD4<Float>>.stride
        descriptor.attributes[4].bufferIndex = 0
        
        // Attribute 5: ringIndex (float)
        descriptor.attributes[5].format = .float
        descriptor.attributes[5].offset = MemoryLayout<SIMD2<Float>>.stride + MemoryLayout<Float>.stride * 3 + MemoryLayout<SIMD4<Float>>.stride
        descriptor.attributes[5].bufferIndex = 0
        
        descriptor.layouts[0].stride = MemoryLayout<StarVertex>.stride
        descriptor.layouts[0].stepRate = 1
        descriptor.layouts[0].stepFunction = .perVertex
        return descriptor
    }()
    private var startTime: CFTimeInterval = CACurrentMediaTime()

    init?(metalKitView: MTKView) {
        guard let device = MTLCreateSystemDefaultDevice() else {
            return nil
        }
        self.device = device
        guard let commandQueue = device.makeCommandQueue() else {
            return nil
        }
        self.commandQueue = commandQueue
        super.init()
        configureView(metalKitView)
        buildResources()
    }

    private func configureView(_ view: MTKView) {
        view.device = device
        view.colorPixelFormat = .bgra8Unorm
        view.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        view.depthStencilPixelFormat = .invalid
        view.sampleCount = 1
        let scale = currentDeviceScale(for: view)
        updateViewport(pointSize: view.bounds.size, scale: scale)
    }

    private func buildResources() {
        buildPipeline()
    }

    private func buildPipeline() {
        guard let library = device.makeDefaultLibrary() else {
            assertionFailure("Unable to load default Metal library")
            return
        }
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.label = "Galaxy Pipeline"
        descriptor.vertexFunction = library.makeFunction(name: "galaxy_vertex")
        descriptor.fragmentFunction = library.makeFunction(name: "galaxy_fragment")
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        descriptor.vertexDescriptor = vertexDescriptor
        descriptor.inputPrimitiveTopology = .point
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
        } catch {
            assertionFailure("Failed to create pipeline state: \(error)")
        }
    }

    func updateStarVertices(_ vertices: [StarVertex]) {
        starCount = vertices.count
        guard !vertices.isEmpty else {
            vertexBuffer = nil
            return
        }
        let length = MemoryLayout<StarVertex>.stride * vertices.count
        vertexBuffer = device.makeBuffer(bytes: vertices, length: length, options: [])
        // 移除每帧调试输出，避免影响渲染流畅度
    }

    // MARK: - MTKViewDelegate
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        let scale = currentDeviceScale(for: view)
        let safeScale = max(scale.isFinite ? scale : 1.0, 1.0)
        if size.width > 0, size.height > 0 {
            let pointSize = CGSize(
                width: size.width / safeScale,
                height: size.height / safeScale
            )
            updateViewport(pointSize: pointSize, scale: safeScale)
        }
    }

    func draw(in view: MTKView) {
        guard
            let pipelineState,
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let renderPassDescriptor = view.currentRenderPassDescriptor,
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        else {
            return
        }

        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setViewport(makeViewport())

        var uniforms = Uniforms(
            time: Float(CACurrentMediaTime() - startTime),
            viewportSizePixels: viewportSizePixels,
            scale: viewportScale
        )
        renderEncoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 1)
        renderEncoder.setFragmentBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 0)
        if starCount > 0, let vertexBuffer {
            renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: starCount)
        } else {
            // no-op
        }
        renderEncoder.endEncoding()

        if let drawable = view.currentDrawable {
            commandBuffer.present(drawable)
        }
        commandBuffer.commit()
    }
    
    func updateViewport(pointSize: CGSize, scale: CGFloat) {
        let widthPoints = Float(max(pointSize.width, 1.0))
        let heightPoints = Float(max(pointSize.height, 1.0))
        viewportSizePoints = SIMD2<Float>(widthPoints, heightPoints)
        viewportScale = max(Float(scale.isFinite ? scale : 1.0), 1.0)
        viewportSizePixels = viewportSizePoints * viewportScale
    }

    func updateViewport(pointSize: CGSize) {
        updateViewport(pointSize: pointSize, scale: CGFloat(viewportScale))
    }

    private func makeViewport() -> MTLViewport {
        MTLViewport(
            originX: 0.0,
            originY: 0.0,
            width: Double(max(viewportSizePixels.x, 1.0)),
            height: Double(max(viewportSizePixels.y, 1.0)),
            znear: 0.0,
            zfar: 1.0
        )
    }
}

@MainActor
private func currentDeviceScale(for view: MTKView) -> CGFloat {
#if canImport(UIKit)
    let scale = view.contentScaleFactor
    if scale.isFinite, scale >= 1.0 {
        return scale
    }
    return max(view.window?.screen.scale ?? UIScreen.main.scale, 1.0)
#elseif canImport(AppKit)
    if let layerScale = view.layer?.contentsScale, layerScale.isFinite, layerScale >= 1.0 {
        return layerScale
    }
    if let windowScale = view.window?.backingScaleFactor, windowScale.isFinite, windowScale >= 1.0 {
        return windowScale
    }
    return max(NSScreen.main?.backingScaleFactor ?? 1.0, 1.0)
#else
    return 1.0
#endif
}
