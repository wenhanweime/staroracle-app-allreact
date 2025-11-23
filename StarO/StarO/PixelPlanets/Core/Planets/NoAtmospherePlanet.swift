import Foundation
import simd

private let noAtmosphereColors: [Float] = [
    0.556863, 0.556863, 0.556863, 1,
    0.411765, 0.411765, 0.411765, 1,
    0.25098, 0.25098, 0.25098, 1,
]

private func makeNoAtmosphereConfig() -> PlanetConfig {
    let uniforms: [String: UniformValue] = [
        "pixels": .float(100),
        "rotation": .float(0),
        "light_origin": .vec2(Vec2(0.39, 0.39)),
        "time_speed": .float(0.2),
        "dither_size": .float(2),
        "should_dither": .float(1),
        "light_border_1": .float(0.287),
        "light_border_2": .float(0.476),
        "colors": .buffer(noAtmosphereColors),
        "size": .float(5),
        "octaves": .float(3),
        "seed": .float(1.234),
        "time": .float(0),
    ]

    let craterUniforms: [String: UniformValue] = [
        "pixels": .float(100),
        "rotation": .float(0),
        "light_origin": .vec2(Vec2(0.39, 0.39)),
        "time_speed": .float(0.2),
        "dither_size": .float(2),
        "should_dither": .float(1),
        "light_border_1": .float(0.287),
        "light_border_2": .float(0.476),
        "colors": .buffer(noAtmosphereColors),
        "size": .float(3.5),
        "octaves": .float(3),
        "seed": .float(1.234),
        "time": .float(0),
    ]

    return PlanetConfig(
        id: "no-atmosphere",
        label: "No atmosphere",
        relativeScale: 1,
        guiZoom: 1,
        layers: [
            LayerDefinition(
                name: "Ground",
                shaderPath: "no-atmosphere/ground.frag",
                uniforms: uniforms,
                colors: [ColorBinding(layer: "Ground", uniform: "colors", slots: 3)]
            ),
            LayerDefinition(
                name: "Craters",
                shaderPath: "no-atmosphere/craters.frag",
                uniforms: craterUniforms,
                colors: [ColorBinding(layer: "Craters", uniform: "colors", slots: 3)]
            ),
        ],
        uniformControls: [
            UniformControl(layer: "Ground", uniform: "time_speed", label: "Spin Speed", min: 0, max: 1, step: 0.01),
            UniformControl(layer: "Ground", uniform: "dither_size", label: "Dither Size", min: 0, max: 6, step: 0.1),
            UniformControl(layer: "Ground", uniform: "light_border_1", label: "Light Border 1", min: 0, max: 1, step: 0.01),
            UniformControl(layer: "Ground", uniform: "light_border_2", label: "Light Border 2", min: 0, max: 1, step: 0.01),
            UniformControl(layer: "Ground", uniform: "size", label: "Noise Scale", min: 1, max: 15, step: 0.1),
            UniformControl(layer: "Ground", uniform: "octaves", label: "Octaves", min: 1, max: 6, step: 1),
        ]
    )
}

private let noAtmosphereConfig = makeNoAtmosphereConfig()

public final class NoAtmospherePlanet: PlanetBase, @unchecked Sendable {
    public init() throws {
        try super.init(config: noAtmosphereConfig)
    }

    public override func setPixels(_ amount: Int) {
        let value = Float(amount)
        setFloat("Ground", "pixels", value)
        setFloat("Craters", "pixels", value)
    }

    public override func setLight(_ position: SIMD2<Float>) {
        setVec2("Ground", "light_origin", position)
        setVec2("Craters", "light_origin", position)
    }

    public override func setSeed(_ seed: Int, rng: inout RandomStream) {
        let converted = Float(seed % 1000) / 100
        setFloat("Ground", "seed", converted)
        setFloat("Craters", "seed", converted)
    }

    public override func setRotation(_ radians: Float) {
        setFloat("Ground", "rotation", radians)
        setFloat("Craters", "rotation", radians)
    }

    public override func updateTime(_ t: Float) {
        setFloat("Ground", "time", t * multiplier(for: "Ground") * 0.02)
        setFloat("Craters", "time", t * multiplier(for: "Craters") * 0.02)
    }

    public override func setCustomTime(_ t: Float) {
        let speed = max(0.0001, getFloat("Ground", "time_speed"))
        setFloat("Ground", "time", t * Float.pi * 2 * speed)
        setFloat("Craters", "time", t * Float.pi * 2 * speed)
    }

    public override func setDither(_ enabled: Bool) {
        let value = enabled ? 1 : 0
        setFloat("Ground", "should_dither", Float(value))
        setFloat("Craters", "should_dither", Float(value))
    }

    public override func isDitherEnabled() -> Bool {
        getFloat("Ground", "should_dither") > 0.5
    }

    public override func randomizeColors(rng: inout RandomStream) -> [PixelColor] {
        var palette = generatePalette(
            rng: &rng,
            count: 3,
            hueDiff: randRange(&rng, min: 0.3, max: 0.6),
            saturation: 0.5
        )
        if palette.count < 3 {
            palette += Array(repeating: PixelColor(r: 0.5, g: 0.5, b: 0.5, a: 1), count: 3 - palette.count)
        }

        var colors: [PixelColor] = []
        for i in 0..<3 {
            var shade = palette[i % palette.count].darkened(by: Float(i) / 3)
            colors.append(shade)
        }

        // Both layers share the same colors
        let allColors = colors + colors
        setColors(allColors)
        return allColors
    }
}

@MainActor
func registerNoAtmospherePlanet(into factories: inout [String: PlanetFactory]) {
    factories["No atmosphere"] = { try NoAtmospherePlanet() }
}
