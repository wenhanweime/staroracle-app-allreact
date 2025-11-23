import Foundation
import simd

open class PlanetBase: @unchecked Sendable {
    public let id: String
    public let label: String
    public let relativeScale: Float
    public let guiZoom: Float
    public var overrideTime: Bool = false

    public private(set) var layers: [LayerState]
    public let colorBindings: [ColorBinding]
    public let uniformControls: [UniformControl]

    public init(config: PlanetConfig) throws {
        self.id = config.id
        self.label = config.label
        self.relativeScale = config.relativeScale
        self.guiZoom = config.guiZoom
        self.layers = try config.layers.map { try LayerState(definition: $0) }
        self.colorBindings = layers.flatMap(\.colorBindings)
        self.uniformControls = config.uniformControls
    }

    // MARK: - Layer utilities

    @discardableResult
    private func layer(named name: String) -> LayerState {
        guard let layer = layers.first(where: { $0.name == name }) else {
            fatalError("Layer \(name) not found on planet \(id)")
        }
        return layer
    }

    private func indexOfLayer(named name: String) -> Int {
        guard let index = layers.firstIndex(where: { $0.name == name }) else {
            fatalError("Layer \(name) not found on planet \(id)")
        }
        return index
    }

    private func setUniform(_ value: UniformValue, layerName: String, uniform: String) {
        let index = indexOfLayer(named: layerName)
        layers[index].uniforms[uniform] = value
    }

    private func getUniform(layerName: String, uniform: String) -> UniformValue {
        layer(named: layerName).uniforms[uniform] ?? {
            fatalError("Uniform \(uniform) missing on layer \(layerName)")
        }()
    }

    internal func setFloat(_ layerName: String, _ uniform: String, _ value: Float) {
        setUniform(.float(value), layerName: layerName, uniform: uniform)
    }

    internal func setVec2(_ layerName: String, _ uniform: String, _ value: SIMD2<Float>) {
        setUniform(.vec2(value), layerName: layerName, uniform: uniform)
    }

    internal func setBuffer(_ layerName: String, _ uniform: String, _ value: [Float]) {
        setUniform(.buffer(value), layerName: layerName, uniform: uniform)
    }

    internal func getFloat(_ layerName: String, _ uniform: String) -> Float {
        let value = getUniform(layerName: layerName, uniform: uniform)
        switch value {
        case .float(let scalar):
            return scalar
        case .vec2(let vector):
            return vector.x
        case .vec3(let vector):
            return vector.x
        case .vec4(let vector):
            return vector.x
        case .buffer(let buffer):
            return buffer.first ?? 0
        }
    }

    internal func getVec2(_ layerName: String, _ uniform: String) -> SIMD2<Float> {
        let value = getUniform(layerName: layerName, uniform: uniform)
        switch value {
        case .vec2(let vector):
            return vector
        case .buffer(let buffer) where buffer.count >= 2:
            return SIMD2(buffer[0], buffer[1])
        default:
            fatalError("Uniform \(uniform) on layer \(layerName) is not vec2")
        }
    }

    private func colors(for binding: ColorBinding) -> [PixelColor] {
        let uniform = getUniform(layerName: binding.layer, uniform: binding.uniform)
        guard case let .buffer(buffer) = uniform else {
            fatalError("Uniform \(binding.uniform) is not a color buffer")
        }
        var colors: [PixelColor] = []
        for index in stride(from: 0, to: min(buffer.count, binding.slots * 4), by: 4) {
            let color = PixelColor(
                r: buffer[index],
                g: buffer[index + 1],
                b: buffer[index + 2],
                a: buffer[index + 3]
            )
            colors.append(color)
        }
        return colors
    }

    private func setColors(_ colors: [PixelColor], for binding: ColorBinding) {
        var buffer = [Float](repeating: 0, count: binding.slots * 4)
        for (index, color) in colors.prefix(binding.slots).enumerated() {
            let offset = index * 4
            buffer[offset + 0] = color.r
            buffer[offset + 1] = color.g
            buffer[offset + 2] = color.b
            buffer[offset + 3] = color.a
        }
        setBuffer(binding.layer, binding.uniform, buffer)
    }

    internal func multiplier(for layerName: String) -> Float {
        let size = getFloat(layerName, "size")
        let speed = getFloat(layerName, "time_speed")
        guard speed != 0 else { return 0 }
        return (round(size) * 2) / speed
    }

    // MARK: - Public interface

    public func uniformControlsList() -> [UniformControl] {
        uniformControls
    }

    public func uniformValue(layerName: String, uniform: String) -> UniformValue? {
        layer(named: layerName).uniforms[uniform]
    }

    public func setUniformValue(layerName: String, uniform: String, value: UniformValue) {
        let index = indexOfLayer(named: layerName)
        guard let current = layers[index].uniforms[uniform] else {
            fatalError("Uniform \(uniform) missing on layer \(layerName)")
        }

        switch (current, value) {
        case (.float, .float),
             (.vec2, .vec2),
             (.vec3, .vec3),
             (.vec4, .vec4):
            layers[index].uniforms[uniform] = value
        case (.buffer(let buffer), .buffer(let newBuffer)):
            guard buffer.count == newBuffer.count else {
                fatalError("Mismatched buffer length for uniform \(uniform) on layer \(layerName)")
            }
            layers[index].uniforms[uniform] = .buffer(Array(newBuffer))
        default:
            fatalError("Unsupported uniform update for \(uniform) on layer \(layerName)")
        }
    }

    public func layersSummary() -> [LayerSummary] {
        layers.map { LayerSummary(name: $0.name, visible: $0.visible) }
    }

    public func toggleLayer(at index: Int) {
        guard layers.indices.contains(index) else { return }
        layers[index].visible.toggle()
    }

    public func colorsPalette() -> [PixelColor] {
        colorBindings.flatMap { colors(for: $0) }
    }

    public func setColors(_ colors: [PixelColor]) {
        var cursor = 0
        for binding in colorBindings {
            let end = min(cursor + binding.slots, colors.count)
            guard cursor < end else { break }
            setColors(Array(colors[cursor..<end]), for: binding)
            cursor = end
        }
    }

    // MARK: - Abstract API

    open func setPixels(_ amount: Int) {
        fatalError("setPixels not implemented for \(id)")
    }

    open func setLight(_ position: SIMD2<Float>) {
        fatalError("setLight not implemented for \(id)")
    }

    open func setSeed(_ seed: Int, rng: inout RandomStream) {
        fatalError("setSeed not implemented for \(id)")
    }

    open func setRotation(_ radians: Float) {
        fatalError("setRotation not implemented for \(id)")
    }

    open func updateTime(_ t: Float) {
        fatalError("updateTime not implemented for \(id)")
    }

    open func setCustomTime(_ t: Float) {
        fatalError("setCustomTime not implemented for \(id)")
    }

    open func setDither(_ enabled: Bool) {
        fatalError("setDither not implemented for \(id)")
    }

    open func isDitherEnabled() -> Bool {
        fatalError("getDither not implemented for \(id)")
    }

    open func randomizeColors(rng: inout RandomStream) -> [PixelColor] {
        fatalError("randomizeColors not implemented for \(id)")
    }
}
