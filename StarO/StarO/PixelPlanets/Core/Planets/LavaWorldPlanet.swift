import Foundation
import simd

private let lavaLandColors: [Float] = [
    0.560784, 0.301961, 0.341176, 1,
    0.321569, 0.2, 0.247059, 1,
    0.239216, 0.160784, 0.211765, 1,
]

private let lavaCraterColors: [Float] = [
    0.321569, 0.2, 0.247059, 1,
    0.239216, 0.160784, 0.211765, 1,
]

private let lavaRiverColors: [Float] = [
    1, 0.537255, 0.2, 1,
    0.901961, 0.270588, 0.223529, 1,
    0.678431, 0.184314, 0.270588, 1,
]

private func makeLavaWorldConfig() -> PlanetConfig {
    let landUniforms: [String: UniformValue] = [
        "pixels": .float(100),
        "rotation": .float(0),
        "light_origin": .vec2(Vec2(0.3, 0.3)),
        "time_speed": .float(0.2),
        "dither_size": .float(2),
        "light_border_1": .float(0.4),
        "light_border_2": .float(0.6),
        "colors": .buffer(lavaLandColors),
        "size": .float(10),
        "OCTAVES": .float(3),
        "seed": .float(1.551),
        "time": .float(0),
        "should_dither": .float(1),
    ]

    let craterUniforms: [String: UniformValue] = [
        "pixels": .float(100),
        "rotation": .float(0),
        "light_origin": .vec2(Vec2(0.3, 0.3)),
        "time_speed": .float(0.2),
        "light_border": .float(0.4),
        "colors": .buffer(lavaCraterColors),
        "size": .float(3.5),
        "seed": .float(1.561),
        "time": .float(0),
    ]

    let lavaUniforms: [String: UniformValue] = [
        "pixels": .float(100),
        "rotation": .float(0),
        "light_origin": .vec2(Vec2(0.3, 0.3)),
        "time_speed": .float(0.2),
        "light_border_1": .float(0.019),
        "light_border_2": .float(0.036),
        "river_cutoff": .float(0.579),
        "colors": .buffer(lavaRiverColors),
        "size": .float(10),
        "OCTAVES": .float(4),
        "seed": .float(2.527),
        "time": .float(0),
    ]

    let controls: [UniformControl] = [
        UniformControl(layer: "Land", uniform: "time_speed", label: "Land Time Speed", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Land", uniform: "dither_size", label: "Land Dither Size", min: 0, max: 6, step: 0.1),
        UniformControl(layer: "Land", uniform: "light_border_1", label: "Land Light Border 1", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Land", uniform: "light_border_2", label: "Land Light Border 2", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Land", uniform: "size", label: "Land Noise Scale", min: 1, max: 15, step: 0.1),
        UniformControl(layer: "Land", uniform: "OCTAVES", label: "Land Octaves", min: 1, max: 6, step: 1),
        UniformControl(layer: "Craters", uniform: "time_speed", label: "Crater Time Speed", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Craters", uniform: "light_border", label: "Crater Light Border", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Craters", uniform: "size", label: "Crater Noise Scale", min: 1, max: 10, step: 0.1),
        UniformControl(layer: "LavaRivers", uniform: "time_speed", label: "Lava Time Speed", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "LavaRivers", uniform: "light_border_1", label: "Lava Light Border 1", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "LavaRivers", uniform: "light_border_2", label: "Lava Light Border 2", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "LavaRivers", uniform: "river_cutoff", label: "Lava Cutoff", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "LavaRivers", uniform: "size", label: "Lava Noise Scale", min: 1, max: 15, step: 0.1),
        UniformControl(layer: "LavaRivers", uniform: "OCTAVES", label: "Lava Octaves", min: 1, max: 6, step: 1),
    ]

    return PlanetConfig(
        id: "lava-world",
        label: "Lava World",
        relativeScale: 1,
        guiZoom: 1,
        layers: [
            LayerDefinition(
                name: "Land",
                shaderPath: "no-atmosphere/ground.frag",
                uniforms: landUniforms,
                colors: [ColorBinding(layer: "Land", uniform: "colors", slots: 3)]
            ),
            LayerDefinition(
                name: "Craters",
                shaderPath: "no-atmosphere/craters.frag",
                uniforms: craterUniforms,
                colors: [ColorBinding(layer: "Craters", uniform: "colors", slots: 2)]
            ),
            LayerDefinition(
                name: "LavaRivers",
                shaderPath: "lava-world/rivers.frag",
                uniforms: lavaUniforms,
                colors: [ColorBinding(layer: "LavaRivers", uniform: "colors", slots: 3)]
            ),
        ],
        uniformControls: controls
    )
}

private let lavaWorldConfig = makeLavaWorldConfig()

public final class LavaWorldPlanet: PlanetBase, @unchecked Sendable {
    public init() throws {
        try super.init(config: lavaWorldConfig)
    }

    public override func setPixels(_ amount: Int) {
        let value = Float(amount)
        setFloat("Land", "pixels", value)
        setFloat("Craters", "pixels", value)
        setFloat("LavaRivers", "pixels", value)
    }

    public override func setLight(_ position: SIMD2<Float>) {
        setVec2("Land", "light_origin", position)
        setVec2("Craters", "light_origin", position)
        setVec2("LavaRivers", "light_origin", position)
    }

    public override func setSeed(_ seed: Int, rng: inout RandomStream) {
        let converted = Float(seed % 1000) / 100
        setFloat("Land", "seed", converted)
        setFloat("Craters", "seed", converted)
        setFloat("LavaRivers", "seed", converted)
    }

    public override func setRotation(_ radians: Float) {
        setFloat("Land", "rotation", radians)
        setFloat("Craters", "rotation", radians)
        setFloat("LavaRivers", "rotation", radians)
    }

    public override func updateTime(_ t: Float) {
        setFloat("Land", "time", t * multiplier(for: "Land") * 0.02)
        setFloat("Craters", "time", t * multiplier(for: "Craters") * 0.02)
        setFloat("LavaRivers", "time", t * multiplier(for: "LavaRivers") * 0.02)
    }

    public override func setCustomTime(_ t: Float) {
        setFloat("Land", "time", t * multiplier(for: "Land"))
        setFloat("Craters", "time", t * multiplier(for: "Craters"))
        setFloat("LavaRivers", "time", t * multiplier(for: "LavaRivers"))
    }

    public override func setDither(_ enabled: Bool) {
        setFloat("Land", "should_dither", enabled ? 1 : 0)
    }

    public override func isDitherEnabled() -> Bool {
        getFloat("Land", "should_dither") > 0.5
    }

    public override func randomizeColors(rng: inout RandomStream) -> [PixelColor] {
        var palette = generatePalette(
            rng: &rng,
            count: (rng.next() < 0.5 ? 2 : 3),
            hueDiff: randRange(&rng, min: 0.6, max: 1.0),
            saturation: randRange(&rng, min: 0.7, max: 0.8)
        )
        if palette.isEmpty {
            palette = [PixelColor(r: 0.9, g: 0.3, b: 0.2, a: 1)]
        }

        var land: [PixelColor] = []
        let landBase = palette[0]
        for i in 0..<3 {
            var shade = landBase.darkened(by: Float(i) / 3)
            var hsv = shade.toHSV()
            hsv.h += 0.2 * (Float(i) / 4)
            shade = PixelColor.fromHSV(hsv)
            land.append(shade)
        }

        var lava: [PixelColor] = []
        let lavaBase = palette[min(1, palette.count - 1)]
        for i in 0..<3 {
            var shade = lavaBase.darkened(by: Float(i) / 3)
            var hsv = shade.toHSV()
            hsv.h += 0.2 * (Float(i) / 3)
            shade = PixelColor.fromHSV(hsv)
            shade = shade.lightened(by: (1 - Float(i) / 3) * 0.5)
            lava.append(shade)
        }

        let colors = land + [land[1], land[2]] + lava
        setColors(colors)
        return colors
    }
}

@MainActor
func registerLavaWorldPlanet(into factories: inout [String: PlanetFactory]) {
    factories["Lava World"] = { try LavaWorldPlanet() }
}
