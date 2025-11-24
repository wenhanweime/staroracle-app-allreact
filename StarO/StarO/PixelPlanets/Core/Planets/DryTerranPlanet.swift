import Foundation
import simd

private let dryLandColors: [Float] = [
    1, 0.537255, 0.2, 1,
    0.901961, 0.270588, 0.223529, 1,
    0.678431, 0.184314, 0.270588, 1,
    0.321569, 0.2, 0.247059, 1,
    0.239216, 0.160784, 0.211765, 1,
]

private func normalizedSeed(_ seed: Int) -> Float {
    let remainder = ((seed % 1000) + 1000) % 1000
    let value = Float(remainder) / 100
    return max(value, 0.01)
}

private func makeDryTerranConfig() -> PlanetConfig {
    let landUniforms: [String: UniformValue] = [
        "pixels": .float(100),
        "rotation": .float(0),
        "light_origin": .vec2(Vec2(0.4, 0.3)),
        "light_distance1": .float(0.362),
        "light_distance2": .float(0.525),
        "time_speed": .float(0.1),
        "dither_size": .float(2),
        "colors": .buffer(dryLandColors),
        "n_colors": .float(5),
        "size": .float(8),
        "OCTAVES": .float(3),
        "seed": .float(1.175),
        "time": .float(0),
        "should_dither": .float(1),
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
                uniforms: landUniforms,
                colors: [ColorBinding(layer: "Land", uniform: "colors", slots: 5)]
            ),
        ],
        uniformControls: [
            UniformControl(layer: "Land", uniform: "light_distance1", label: "Light Distance 1", min: 0, max: 1, step: 0.01),
            UniformControl(layer: "Land", uniform: "light_distance2", label: "Light Distance 2", min: 0, max: 1, step: 0.01),
            UniformControl(layer: "Land", uniform: "time_speed", label: "Time Speed", min: 0, max: 1, step: 0.01),
            UniformControl(layer: "Land", uniform: "dither_size", label: "Dither Size", min: 0, max: 6, step: 0.1),
            UniformControl(layer: "Land", uniform: "size", label: "Noise Scale", min: 1, max: 20, step: 0.1),
            UniformControl(layer: "Land", uniform: "OCTAVES", label: "Octaves", min: 1, max: 12, step: 1),
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
        setFloat("Land", "seed", normalizedSeed(seed))
    }

    public override func setRotation(_ radians: Float) {
        setFloat("Land", "rotation", radians)
    }

    public override func updateTime(_ t: Float) {
        setFloat("Land", "time", t * multiplier(for: "Land") * 0.02)
    }

    public override func setCustomTime(_ t: Float) {
        setFloat("Land", "time", t * multiplier(for: "Land"))
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
            count: 5 + randInt(&rng, maxExclusive: 3),
            hueDiff: randRange(&rng, min: 0.3, max: 0.65),
            saturation: 1.0
        )
        if palette.count < 5 {
            palette += Array(repeating: PixelColor(r: 0.8, g: 0.6, b: 0.3, a: 1), count: 5 - palette.count)
        }

        let count = 5
        var colors: [PixelColor] = []
        for i in 0..<count {
            let base = palette[i % palette.count]
            let shaded = base.darkened(by: Float(i) / Float(count))
            let lightened = shaded.lightened(by: (1 - Float(i) / Float(count)) * 0.2)
            colors.append(lightened)
        }

        setColors(colors)
        return colors
    }
}

@MainActor
func registerDryTerranPlanet(into factories: inout [String: PlanetFactory]) {
    factories["Terran Dry"] = { try DryTerranPlanet() }
}
