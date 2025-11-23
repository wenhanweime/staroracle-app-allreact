import Foundation
import simd

private let dryTerranLandColors: [Float] = [
    1, 0.913725, 0.737255, 1,
    0.980392, 0.705882, 0.329412, 1,
    0.839216, 0.356863, 0.266667, 1,
    0.501961, 0.231373, 0.219608, 1,
]

private func makeDryTerranConfig() -> PlanetConfig {
    let uniforms: [String: UniformValue] = [
        "pixels": .float(100),
        "rotation": .float(0),
        "light_origin": .vec2(Vec2(0.39, 0.39)),
        "time_speed": .float(0.2),
        "dither_size": .float(2),
        "should_dither": .float(1),
        "light_border_1": .float(0.4),
        "light_border_2": .float(0.5),
        "colors": .buffer(dryTerranLandColors),
        "size": .float(8),
        "octaves": .float(3),
        "seed": .float(1.234),
        "time": .float(0),
    ]

    return PlanetConfig(
        id: "dry-terran",
        label: "Terran Dry",
        relativeScale: 1,
        guiZoom: 1,
        layers: [
            LayerDefinition(
                name: "Land",
                shaderPath: "dry-terran/land.frag",
                uniforms: uniforms,
                colors: [ColorBinding(layer: "Land", uniform: "colors", slots: 4)]
            ),
        ],
        uniformControls: [
            UniformControl(layer: "Land", uniform: "time_speed", label: "Spin Speed", min: 0, max: 1, step: 0.01),
            UniformControl(layer: "Land", uniform: "dither_size", label: "Dither Size", min: 0, max: 6, step: 0.1),
            UniformControl(layer: "Land", uniform: "light_border_1", label: "Light Border 1", min: 0, max: 1, step: 0.01),
            UniformControl(layer: "Land", uniform: "light_border_2", label: "Light Border 2", min: 0, max: 1, step: 0.01),
            UniformControl(layer: "Land", uniform: "size", label: "Noise Scale", min: 1, max: 15, step: 0.1),
            UniformControl(layer: "Land", uniform: "octaves", label: "Octaves", min: 1, max: 6, step: 1),
        ]
    )
}

private let dryTerranConfig = makeDryTerranConfig()

public final class DryTerranPlanet: PlanetBase, @unchecked Sendable {
    public init() throws {
        try super.init(config: dryTerranConfig)
    }

    public override func setPixels(_ amount: Int) {
        setFloat("Land", "pixels", Float(amount))
    }

    public override func setLight(_ position: SIMD2<Float>) {
        setVec2("Land", "light_origin", position)
    }

    public override func setSeed(_ seed: Int, rng: inout RandomStream) {
        let converted = Float(seed % 1000) / 100
        setFloat("Land", "seed", converted)
    }

    public override func setRotation(_ radians: Float) {
        setFloat("Land", "rotation", radians)
    }

    public override func updateTime(_ t: Float) {
        setFloat("Land", "time", t * multiplier(for: "Land") * 0.02)
    }

    public override func setCustomTime(_ t: Float) {
        let speed = max(0.0001, getFloat("Land", "time_speed"))
        setFloat("Land", "time", t * Float.pi * 2 * speed)
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
            count: 4,
            hueDiff: randRange(&rng, min: 0.3, max: 0.6),
            saturation: 0.8
        )
        if palette.count < 4 {
            palette += Array(repeating: PixelColor(r: 0.8, g: 0.5, b: 0.3, a: 1), count: 4 - palette.count)
        }

        var colors: [PixelColor] = []
        for i in 0..<4 {
            var shade = palette[i % palette.count].darkened(by: Float(i) / 4)
            shade = shade.lightened(by: (1 - Float(i) / 4) * 0.2)
            colors.append(shade)
        }

        setColors(colors)
        return colors
    }
}

@MainActor
func registerDryTerranPlanet(into factories: inout [String: PlanetFactory]) {
    factories["Terran Dry"] = { try DryTerranPlanet() }
}
