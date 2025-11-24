import Foundation
import simd

private let gasLayersLightColors: [Float] = [
    0.933333, 0.764706, 0.603922, 1,
    0.85098, 0.627451, 0.4, 1,
    0.560784, 0.337255, 0.231373, 1,
]

private let gasLayersDarkColors: [Float] = [
    0.4, 0.223529, 0.192157, 1,
    0.270588, 0.156863, 0.235294, 1,
    0.133333, 0.12549, 0.203922, 1,
]

private let ringLightColors: [Float] = [
    0.933333, 0.764706, 0.603922, 1,
    0.701961, 0.478431, 0.313726, 1,
    0.560784, 0.337255, 0.231373, 1,
]

private let ringDarkColors: [Float] = [
    0.333333, 0.188235, 0.211765, 1,
    0.196078, 0.137255, 0.215686, 1,
    0.133333, 0.12549, 0.203922, 1,
]

private func makeGasPlanetLayersConfig() -> PlanetConfig {
    let gasUniforms: [String: UniformValue] = [
        "pixels": .float(100),
        "rotation": .float(0),
        "cloud_cover": .float(0.61),
        "light_origin": .vec2(Vec2(-0.1, 0.3)),
        "time_speed": .float(0.05),
        "stretch": .float(2.204),
        "cloud_curve": .float(1.376),
        "light_border_1": .float(0.52),
        "light_border_2": .float(0.62),
        "bands": .float(0.892),
        "should_dither": .float(1),
        "n_colors": .float(3),
        "colors": .buffer(gasLayersLightColors),
        "dark_colors": .buffer(gasLayersDarkColors),
        "size": .float(10.107),
        "OCTAVES": .float(3),
        "seed": .float(6.314),
        "time": .float(0),
    ]

    let ringUniforms: [String: UniformValue] = [
        "pixels": .float(300),
        "rotation": .float(0.7),
        "light_origin": .vec2(Vec2(-0.1, 0.3)),
        "time_speed": .float(0.2),
        "light_border_1": .float(0.52),
        "light_border_2": .float(0.62),
        "ring_width": .float(0.127),
        "ring_perspective": .float(6),
        "scale_rel_to_planet": .float(6),
        "n_colors": .float(3),
        "colors": .buffer(ringLightColors),
        "dark_colors": .buffer(ringDarkColors),
        "size": .float(15),
        "OCTAVES": .float(4),
        "seed": .float(8.461),
        "time": .float(0),
    ]

    let controls: [UniformControl] = [
        UniformControl(layer: "GasLayers", uniform: "cloud_cover", label: "Layers Cloud Cover", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "GasLayers", uniform: "time_speed", label: "Layers Time Speed", min: 0, max: 0.2, step: 0.005),
        UniformControl(layer: "GasLayers", uniform: "stretch", label: "Layers Stretch", min: 1, max: 3, step: 0.05),
        UniformControl(layer: "GasLayers", uniform: "bands", label: "Bands", min: 0, max: 2, step: 0.01),
        UniformControl(layer: "GasLayers", uniform: "light_border_1", label: "Layers Light Border 1", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "GasLayers", uniform: "light_border_2", label: "Layers Light Border 2", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "GasLayers", uniform: "size", label: "Layers Noise Scale", min: 1, max: 15, step: 0.1),
        UniformControl(layer: "GasLayers", uniform: "OCTAVES", label: "Layers Octaves", min: 1, max: 6, step: 1),
        UniformControl(layer: "Ring", uniform: "time_speed", label: "Ring Time Speed", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Ring", uniform: "ring_width", label: "Ring Width", min: 0.01, max: 0.3, step: 0.005),
        UniformControl(layer: "Ring", uniform: "ring_perspective", label: "Ring Perspective", min: 1, max: 20, step: 0.1),
        UniformControl(layer: "Ring", uniform: "scale_rel_to_planet", label: "Ring Scale", min: 1, max: 10, step: 0.1),
        UniformControl(layer: "Ring", uniform: "light_border_1", label: "Ring Light Border 1", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Ring", uniform: "light_border_2", label: "Ring Light Border 2", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Ring", uniform: "size", label: "Ring Noise Scale", min: 1, max: 20, step: 0.1),
        UniformControl(layer: "Ring", uniform: "OCTAVES", label: "Ring Octaves", min: 1, max: 6, step: 1),
    ]

    return PlanetConfig(
        id: "gas-planet-layers",
        label: "Gas giant 2",
        relativeScale: 3,
        guiZoom: 2.5,
        layers: [
            LayerDefinition(
                name: "GasLayers",
                shaderPath: "gas-planet-layers/layers.frag",
                uniforms: gasUniforms,
                colors: [
                    ColorBinding(layer: "GasLayers", uniform: "colors", slots: 3),
                    ColorBinding(layer: "GasLayers", uniform: "dark_colors", slots: 3),
                ]
            ),
            LayerDefinition(
                name: "Ring",
                shaderPath: "gas-planet-layers/ring.frag",
                uniforms: ringUniforms,
                colors: [
                    ColorBinding(layer: "Ring", uniform: "colors", slots: 3),
                    ColorBinding(layer: "Ring", uniform: "dark_colors", slots: 3),
                ]
            ),
        ],
        uniformControls: controls
    )
}

private let gasPlanetLayersConfig = makeGasPlanetLayersConfig()

public final class GasPlanetLayersPlanet: PlanetBase, @unchecked Sendable {
    public init() throws {
        try super.init(config: gasPlanetLayersConfig)
    }

    public override func setPixels(_ amount: Int) {
        let value = Float(amount)
        setFloat("GasLayers", "pixels", value)
        setFloat("Ring", "pixels", value * relativeScale)
    }

    public override func setLight(_ position: SIMD2<Float>) {
        setVec2("GasLayers", "light_origin", position)
        setVec2("Ring", "light_origin", position)
    }

    public override func setSeed(_ seed: Int, rng: inout RandomStream) {
        let converted = Float(seed % 1000) / 100.0 + 1.0
        setFloat("GasLayers", "seed", converted)
        setFloat("Ring", "seed", converted)
    }

    public override func setRotation(_ radians: Float) {
        setFloat("GasLayers", "rotation", radians)
        setFloat("Ring", "rotation", radians + 0.7)
    }

    public override func updateTime(_ t: Float) {
        setFloat("GasLayers", "time", t * multiplier(for: "GasLayers") * 0.004)
        setFloat("Ring", "time", t * 314.15 * 0.004)
    }

    public override func setCustomTime(_ t: Float) {
        setFloat("GasLayers", "time", t * multiplier(for: "GasLayers"))
        let speed = max(0.0001, getFloat("Ring", "time_speed"))
        setFloat("Ring", "time", t * 314.15 * speed * 0.5)
    }

    public override func setDither(_ enabled: Bool) {
        setFloat("GasLayers", "should_dither", enabled ? 1 : 0)
    }

    public override func isDitherEnabled() -> Bool {
        getFloat("GasLayers", "should_dither") > 0.5
    }

    public override func randomizeColors(rng: inout RandomStream) -> [PixelColor] {
        var palette = generatePalette(
            rng: &rng,
            count: 6 + randInt(&rng, maxExclusive: 4),
            hueDiff: randRange(&rng, min: 0.3, max: 0.55),
            saturation: 1.4
        )
        if palette.count < 6 {
            palette += Array(repeating: PixelColor(r: 0.7, g: 0.5, b: 0.4, a: 1), count: 6 - palette.count)
        }

        var baseCols: [PixelColor] = []
        for i in 0..<6 {
            let base = palette[i % palette.count]
            var shade = base.darkened(by: Float(i) / 7)
            shade = shade.lightened(by: (1 - Float(i) / 6) * 0.3)
            baseCols.append(shade)
        }

        let lights = Array(baseCols[0..<3])
        let darks = Array(baseCols[3..<6])
        let combined = lights + darks + lights + darks
        setColors(combined)
        return combined
    }
}

@MainActor
func registerGasPlanetLayersPlanet(into factories: inout [String: PlanetFactory]) {
    factories["Gas giant 2"] = { try GasPlanetLayersPlanet() }
}
