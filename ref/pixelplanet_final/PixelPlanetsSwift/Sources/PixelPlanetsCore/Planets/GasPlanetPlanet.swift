import Foundation
import simd

private let gasLayerOneColors: [Float] = [
    0.231373, 0.12549, 0.152941, 1,
    0.231373, 0.12549, 0.152941, 1,
    0, 0, 0, 1,
    0.129412, 0.0941176, 0.105882, 1,
]

private let gasLayerTwoColors: [Float] = [
    0.941176, 0.709804, 0.254902, 1,
    0.811765, 0.458824, 0.168627, 1,
    0.670588, 0.317647, 0.188235, 1,
    0.490196, 0.219608, 0.2, 1,
]

private func makeGasPlanetConfig() -> PlanetConfig {
    let cloud1Uniforms: [String: UniformValue] = [
        "pixels": .float(100),
        "rotation": .float(0),
        "cloud_cover": .float(0),
        "light_origin": .vec2(Vec2(0.25, 0.25)),
        "time_speed": .float(0.7),
        "stretch": .float(1),
        "cloud_curve": .float(1.3),
        "light_border_1": .float(0.692),
        "light_border_2": .float(0.666),
        "colors": .buffer(gasLayerOneColors),
        "size": .float(9),
        "OCTAVES": .float(5),
        "seed": .float(5.939),
        "time": .float(0),
    ]

    let cloud2Uniforms: [String: UniformValue] = [
        "pixels": .float(100),
        "rotation": .float(0),
        "cloud_cover": .float(0.538),
        "light_origin": .vec2(Vec2(0.25, 0.25)),
        "time_speed": .float(0.47),
        "stretch": .float(1),
        "cloud_curve": .float(1.3),
        "light_border_1": .float(0.439),
        "light_border_2": .float(0.746),
        "colors": .buffer(gasLayerTwoColors),
        "size": .float(9),
        "OCTAVES": .float(5),
        "seed": .float(5.939),
        "time": .float(0),
    ]

    let controls: [UniformControl] = [
        UniformControl(layer: "Cloud", uniform: "cloud_cover", label: "Layer 1 Cloud Cover", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Cloud", uniform: "time_speed", label: "Layer 1 Time Speed", min: -1, max: 1, step: 0.01),
        UniformControl(layer: "Cloud", uniform: "stretch", label: "Layer 1 Stretch", min: 0.5, max: 3, step: 0.05),
        UniformControl(layer: "Cloud", uniform: "cloud_curve", label: "Layer 1 Curve", min: 0.5, max: 2, step: 0.05),
        UniformControl(layer: "Cloud", uniform: "light_border_1", label: "Layer 1 Light Border 1", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Cloud", uniform: "light_border_2", label: "Layer 1 Light Border 2", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Cloud", uniform: "size", label: "Layer 1 Noise Scale", min: 1, max: 15, step: 0.1),
        UniformControl(layer: "Cloud", uniform: "OCTAVES", label: "Layer 1 Octaves", min: 1, max: 8, step: 1),
        UniformControl(layer: "Cloud2", uniform: "cloud_cover", label: "Layer 2 Cloud Cover", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Cloud2", uniform: "time_speed", label: "Layer 2 Time Speed", min: -1, max: 1, step: 0.01),
        UniformControl(layer: "Cloud2", uniform: "stretch", label: "Layer 2 Stretch", min: 0.5, max: 3, step: 0.05),
        UniformControl(layer: "Cloud2", uniform: "cloud_curve", label: "Layer 2 Curve", min: 0.5, max: 2, step: 0.05),
        UniformControl(layer: "Cloud2", uniform: "light_border_1", label: "Layer 2 Light Border 1", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Cloud2", uniform: "light_border_2", label: "Layer 2 Light Border 2", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Cloud2", uniform: "size", label: "Layer 2 Noise Scale", min: 1, max: 15, step: 0.1),
        UniformControl(layer: "Cloud2", uniform: "OCTAVES", label: "Layer 2 Octaves", min: 1, max: 8, step: 1),
    ]

    return PlanetConfig(
        id: "gas-planet",
        label: "Gas giant 1",
        relativeScale: 1,
        guiZoom: 1,
        layers: [
            LayerDefinition(
                name: "Cloud",
                shaderPath: "common/clouds.frag",
                uniforms: cloud1Uniforms,
                colors: [ColorBinding(layer: "Cloud", uniform: "colors", slots: 4)]
            ),
            LayerDefinition(
                name: "Cloud2",
                shaderPath: "common/clouds.frag",
                uniforms: cloud2Uniforms,
                colors: [ColorBinding(layer: "Cloud2", uniform: "colors", slots: 4)]
            ),
        ],
        uniformControls: controls
    )
}

private let gasPlanetConfig = makeGasPlanetConfig()

public final class GasPlanetPlanet: PlanetBase, @unchecked Sendable {
    public init() throws {
        try super.init(config: gasPlanetConfig)
    }

    public override func setPixels(_ amount: Int) {
        let value = Float(amount)
        setFloat("Cloud", "pixels", value)
        setFloat("Cloud2", "pixels", value)
    }

    public override func setLight(_ position: SIMD2<Float>) {
        setVec2("Cloud", "light_origin", position)
        setVec2("Cloud2", "light_origin", position)
    }

    public override func setSeed(_ seed: Int, rng: inout RandomStream) {
        let converted = Float(seed % 1000) / 100
        setFloat("Cloud", "seed", converted)
        setFloat("Cloud2", "seed", converted)
        setFloat("Cloud2", "cloud_cover", randRange(&rng, min: 0.28, max: 0.5))
    }

    public override func setRotation(_ radians: Float) {
        setFloat("Cloud", "rotation", radians)
        setFloat("Cloud2", "rotation", radians)
    }

    public override func updateTime(_ t: Float) {
        setFloat("Cloud", "time", t * multiplier(for: "Cloud") * 0.005)
        setFloat("Cloud2", "time", t * multiplier(for: "Cloud2") * 0.005)
    }

    public override func setCustomTime(_ t: Float) {
        setFloat("Cloud", "time", t * multiplier(for: "Cloud"))
        setFloat("Cloud2", "time", t * multiplier(for: "Cloud2"))
    }

    public override func setDither(_ enabled: Bool) {
        // Shader layers do not expose dither toggles.
    }

    public override func isDitherEnabled() -> Bool {
        false
    }

    public override func randomizeColors(rng: inout RandomStream) -> [Color] {
        var palette = generatePalette(
            rng: &rng,
            count: 8 + randInt(&rng, maxExclusive: 4),
            hueDiff: randRange(&rng, min: 0.3, max: 0.8),
            saturation: 1.0
        )
        if palette.count < 8 {
            palette += Array(repeating: Color(r: 0.8, g: 0.5, b: 0.3, a: 1), count: 8 - palette.count)
        }

        var firstLayer: [Color] = []
        for i in 0..<4 {
            let base = palette[i % palette.count]
            var shade = base.darkened(by: Float(i) / 6)
            shade = shade.darkened(by: 0.7)
            firstLayer.append(shade)
        }

        var secondLayer: [Color] = []
        for i in 0..<4 {
            let index = (i + 4) % palette.count
            let base = palette[index]
            var shade = base.darkened(by: Float(i) / 4)
            shade = shade.lightened(by: (1 - Float(i) / 4) * 0.5)
            secondLayer.append(shade)
        }

        let combined = firstLayer + secondLayer
        setColors(combined)
        return combined
    }
}

@MainActor
func registerGasPlanetPlanet(into factories: inout [String: PlanetFactory]) {
    factories["Gas giant 1"] = { try GasPlanetPlanet() }
}
