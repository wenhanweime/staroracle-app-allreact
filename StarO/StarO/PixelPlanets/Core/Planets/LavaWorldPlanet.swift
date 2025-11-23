import Foundation
import simd

private let lavaWorldColors: [Float] = [
    0.596078, 0.447059, 0.384314, 1,
    0.341176, 0.239216, 0.254902, 1,
    0.223529, 0.156863, 0.188235, 1,
    0.137255, 0.105882, 0.141176, 1,
]

private let lavaWorldRiverColors: [Float] = [
    1, 0.537255, 0.2, 1,
    0.901961, 0.270588, 0.223529, 1,
    0.678431, 0.184314, 0.270588, 1,
]

private func makeLavaWorldConfig() -> PlanetConfig {
    let uniforms: [String: UniformValue] = [
        "pixels": .float(100),
        "rotation": .float(0),
        "light_origin": .vec2(Vec2(0.39, 0.39)),
        "time_speed": .float(0.2),
        "dither_size": .float(2),
        "should_dither": .float(1),
        "light_border_1": .float(0.019),
        "light_border_2": .float(0.036),
        "colors": .buffer(lavaWorldColors),
        "color_num": .float(4),
        "size": .float(10),
        "octaves": .float(3),
        "seed": .float(1.234),
        "time": .float(0),
    ]

    let riverUniforms: [String: UniformValue] = [
        "pixels": .float(100),
        "rotation": .float(0),
        "light_origin": .vec2(Vec2(0.39, 0.39)),
        "time_speed": .float(0.2),
        "dither_size": .float(2),
        "should_dither": .float(1),
        "light_border_1": .float(0.019),
        "light_border_2": .float(0.036),
        "colors": .buffer(lavaWorldRiverColors),
        "size": .float(10),
        "octaves": .float(3),
        "seed": .float(1.234),
        "time": .float(0),
        "river_cutoff": .float(0.368),
    ]

    return PlanetConfig(
        id: "lava-world",
        label: "Lava World",
        relativeScale: 1,
        guiZoom: 1,
        layers: [
            LayerDefinition(
                name: "Planet",
                shaderPath: "lava-world/rivers.frag",
                uniforms: uniforms,
                colors: [ColorBinding(layer: "Planet", uniform: "colors", slots: 4)]
            ),
            LayerDefinition(
                name: "Rivers",
                shaderPath: "lava-world/rivers.frag",
                uniforms: riverUniforms,
                colors: [ColorBinding(layer: "Rivers", uniform: "colors", slots: 3)]
            ),
        ],
        uniformControls: [
            UniformControl(layer: "Planet", uniform: "time_speed", label: "Spin Speed", min: 0, max: 1, step: 0.01),
            UniformControl(layer: "Planet", uniform: "dither_size", label: "Dither Size", min: 0, max: 6, step: 0.1),
            UniformControl(layer: "Planet", uniform: "light_border_1", label: "Light Border 1", min: 0, max: 1, step: 0.01),
            UniformControl(layer: "Planet", uniform: "light_border_2", label: "Light Border 2", min: 0, max: 1, step: 0.01),
            UniformControl(layer: "Planet", uniform: "size", label: "Noise Scale", min: 1, max: 15, step: 0.1),
            UniformControl(layer: "Planet", uniform: "octaves", label: "Octaves", min: 1, max: 6, step: 1),
            UniformControl(layer: "Rivers", uniform: "river_cutoff", label: "River Cutoff", min: 0, max: 1, step: 0.01),
        ]
    )
}

private let lavaWorldConfig = makeLavaWorldConfig()

public final class LavaWorldPlanet: PlanetBase, @unchecked Sendable {
    public init() throws {
        try super.init(config: lavaWorldConfig)
    }

    public override func setPixels(_ amount: Int) {
        let value = Float(amount)
        setFloat("Planet", "pixels", value)
        setFloat("Rivers", "pixels", value)
    }

    public override func setLight(_ position: SIMD2<Float>) {
        setVec2("Planet", "light_origin", position)
        setVec2("Rivers", "light_origin", position)
    }

    public override func setSeed(_ seed: Int, rng: inout RandomStream) {
        let converted = Float(seed % 1000) / 100
        setFloat("Planet", "seed", converted)
        setFloat("Rivers", "seed", converted)
    }

    public override func setRotation(_ radians: Float) {
        setFloat("Planet", "rotation", radians)
        setFloat("Rivers", "rotation", radians)
    }

    public override func updateTime(_ t: Float) {
        setFloat("Planet", "time", t * multiplier(for: "Planet") * 0.02)
        setFloat("Rivers", "time", t * multiplier(for: "Rivers") * 0.02)
    }

    public override func setCustomTime(_ t: Float) {
        let speed = max(0.0001, getFloat("Planet", "time_speed"))
        setFloat("Planet", "time", t * Float.pi * 2 * speed)
        setFloat("Rivers", "time", t * Float.pi * 2 * speed)
    }

    public override func setDither(_ enabled: Bool) {
        let value = enabled ? 1 : 0
        setFloat("Planet", "should_dither", Float(value))
        setFloat("Rivers", "should_dither", Float(value))
    }

    public override func isDitherEnabled() -> Bool {
        getFloat("Planet", "should_dither") > 0.5
    }

    public override func randomizeColors(rng: inout RandomStream) -> [PixelColor] {
        var palette = generatePalette(
            rng: &rng,
            count: 4,
            hueDiff: randRange(&rng, min: 0.3, max: 0.6),
            saturation: 0.8
        )
        if palette.count < 4 {
            palette += Array(repeating: PixelColor(r: 0.3, g: 0.2, b: 0.2, a: 1), count: 4 - palette.count)
        }

        var planetColors: [PixelColor] = []
        for i in 0..<4 {
            var shade = palette[i % palette.count].darkened(by: Float(i) / 4)
            planetColors.append(shade)
        }

        let riverColors = [
            PixelColor(r: 1, g: 0.5, b: 0.2, a: 1),
            PixelColor(r: 0.9, g: 0.3, b: 0.2, a: 1),
            PixelColor(r: 0.7, g: 0.2, b: 0.3, a: 1),
        ]

        let allColors = planetColors + riverColors
        setColors(allColors)
        return allColors
    }
}

@MainActor
func registerLavaWorldPlanet(into factories: inout [String: PlanetFactory]) {
    factories["Lava World"] = { try LavaWorldPlanet() }
}
