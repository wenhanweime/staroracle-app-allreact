import Foundation
import simd

private let baseGroundColors: [Float] = [
    0.639216, 0.654902, 0.760784, 1,
    0.298039, 0.407843, 0.521569, 1,
    0.227451, 0.247059, 0.368627, 1,
]

private let baseCraterColors: [Float] = [
    0.298039, 0.407843, 0.521569, 1,
    0.227451, 0.247059, 0.368627, 1,
]

private func makeNoAtmosphereConfig() -> PlanetConfig {
    let groundUniforms: [String: UniformValue] = [
        "pixels": .float(100),
        "rotation": .float(0),
        "light_origin": .vec2(Vec2(0.25, 0.25)),
        "time_speed": .float(0.4),
        "dither_size": .float(2),
        "light_border_1": .float(0.615),
        "light_border_2": .float(0.729),
        "colors": .buffer(baseGroundColors),
        "size": .float(8),
        "OCTAVES": .float(4),
        "seed": .float(1.012),
        "time": .float(0),
        "should_dither": .float(1),
    ]

    let craterUniforms: [String: UniformValue] = [
        "pixels": .float(100),
        "rotation": .float(0),
        "light_origin": .vec2(Vec2(0.25, 0.25)),
        "time_speed": .float(0.001),
        "light_border": .float(0.465),
        "colors": .buffer(baseCraterColors),
        "size": .float(5),
        "seed": .float(4.517),
        "time": .float(0),
    ]

    let controls: [UniformControl] = [
        UniformControl(layer: "Ground", uniform: "time_speed", label: "Ground Time Speed", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Ground", uniform: "dither_size", label: "Ground Dither Size", min: 0, max: 6, step: 0.1),
        UniformControl(layer: "Ground", uniform: "light_border_1", label: "Ground Light Border 1", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Ground", uniform: "light_border_2", label: "Ground Light Border 2", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Ground", uniform: "size", label: "Ground Noise Scale", min: 1, max: 15, step: 0.1),
        UniformControl(layer: "Ground", uniform: "OCTAVES", label: "Ground Octaves", min: 1, max: 8, step: 1),
        UniformControl(layer: "Craters", uniform: "time_speed", label: "Crater Time Speed", min: 0, max: 0.1, step: 0.001),
        UniformControl(layer: "Craters", uniform: "light_border", label: "Crater Light Border", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Craters", uniform: "size", label: "Crater Noise Scale", min: 1, max: 10, step: 0.1),
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
                uniforms: groundUniforms,
                colors: [ColorBinding(layer: "Ground", uniform: "colors", slots: 3)]
            ),
            LayerDefinition(
                name: "Craters",
                shaderPath: "no-atmosphere/craters.frag",
                uniforms: craterUniforms,
                colors: [ColorBinding(layer: "Craters", uniform: "colors", slots: 2)]
            ),
        ],
        uniformControls: controls
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
        setFloat("Ground", "time", t * multiplier(for: "Ground"))
        setFloat("Craters", "time", t * multiplier(for: "Craters"))
    }

    public override func setDither(_ enabled: Bool) {
        setFloat("Ground", "should_dither", enabled ? 1 : 0)
    }

    public override func isDitherEnabled() -> Bool {
        getFloat("Ground", "should_dither") > 0.5
    }

    public override func randomizeColors(rng: inout RandomStream) -> [Color] {
        var palette = generatePalette(
            rng: &rng,
            count: 3 + randInt(&rng, maxExclusive: 2),
            hueDiff: randRange(&rng, min: 0.3, max: 0.6),
            saturation: 0.7
        )
        if palette.count < 3 {
            palette += Array(repeating: Color(r: 0.5, g: 0.5, b: 0.6, a: 1), count: 3 - palette.count)
        }

        var ground: [Color] = []
        for i in 0..<3 {
            let base = palette[i % palette.count]
            let darkened = base.darkened(by: Float(i) / 3)
            ground.append(darkened.lightened(by: (1 - Float(i) / 3) * 0.2))
        }

        let craters: [Color] = [ground[1], ground[2]]
        let combined = ground + craters
        setColors(combined)
        return combined
    }
}

@MainActor
func registerNoAtmospherePlanet(into factories: inout [String: PlanetFactory]) {
    factories["No atmosphere"] = { try NoAtmospherePlanet() }
}
