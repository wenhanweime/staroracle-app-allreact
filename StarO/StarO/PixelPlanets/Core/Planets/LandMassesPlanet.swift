import Foundation
import simd

private let landMassesWaterColors: [Float] = [
    0.309804, 0.643137, 0.721569, 1,
    0.298039, 0.407843, 0.521569, 1,
    0.227451, 0.247059, 0.368627, 1,
]

private let landMassesLandColors: [Float] = [
    0.415686, 0.529412, 0.34902, 1,
    0.266667, 0.419608, 0.258824, 1,
    0.184314, 0.282353, 0.2, 1,
    0.913725, 0.835294, 0.65098, 1,
]

private let landMassesCloudColors: [Float] = [
    0.941176, 0.964706, 0.941176, 1,
    0.886275, 0.952941, 0.894118, 1,
    0.745098, 0.85098, 0.784314, 1,
]

private func makeLandMassesConfig() -> PlanetConfig {
    let waterUniforms: [String: UniformValue] = [
        "pixels": .float(100),
        "rotation": .float(0),
        "light_origin": .vec2(Vec2(0.39, 0.39)),
        "time_speed": .float(0.2),
        "dither_size": .float(2),
        "should_dither": .float(1),
        "light_border_1": .float(0.052),
        "light_border_2": .float(0.082),
        "colors": .buffer(landMassesWaterColors),
        "size": .float(10),
        "octaves": .float(3),
        "seed": .float(1.234),
        "time": .float(0),
    ]

    let landUniforms: [String: UniformValue] = [
        "pixels": .float(100),
        "rotation": .float(0),
        "light_origin": .vec2(Vec2(0.39, 0.39)),
        "time_speed": .float(0.2),
        "dither_size": .float(2),
        "should_dither": .float(1),
        "light_border_1": .float(0.32),
        "light_border_2": .float(0.534),
        "colors": .buffer(landMassesLandColors),
        "size": .float(4),
        "octaves": .float(3),
        "seed": .float(1.234),
        "time": .float(0),
    ]

    let cloudsUniforms: [String: UniformValue] = [
        "pixels": .float(100),
        "rotation": .float(0),
        "light_origin": .vec2(Vec2(0.39, 0.39)),
        "time_speed": .float(0.15),
        "dither_size": .float(2),
        "should_dither": .float(1),
        "light_border_1": .float(0.566),
        "light_border_2": .float(0.785),
        "colors": .buffer(landMassesCloudColors),
        "size": .float(7),
        "octaves": .float(3),
        "seed": .float(9.876),
        "time": .float(0),
        "cloud_cover": .float(0.47),
    ]

    return PlanetConfig(
        id: "land-masses",
        label: "Islands",
        relativeScale: 1,
        guiZoom: 1,
        layers: [
            LayerDefinition(
                name: "Water",
                shaderPath: "landmasses/water.frag",
                uniforms: waterUniforms,
                colors: [ColorBinding(layer: "Water", uniform: "colors", slots: 3)]
            ),
            LayerDefinition(
                name: "Land",
                shaderPath: "landmasses/land.frag",
                uniforms: landUniforms,
                colors: [ColorBinding(layer: "Land", uniform: "colors", slots: 4)]
            ),
            LayerDefinition(
                name: "Clouds",
                shaderPath: "common/clouds.frag",
                uniforms: cloudsUniforms,
                colors: [ColorBinding(layer: "Clouds", uniform: "colors", slots: 3)]
            ),
        ],
        uniformControls: [
            UniformControl(layer: "Water", uniform: "time_speed", label: "Spin Speed", min: 0, max: 1, step: 0.01),
            UniformControl(layer: "Water", uniform: "dither_size", label: "Dither Size", min: 0, max: 6, step: 0.1),
            UniformControl(layer: "Water", uniform: "light_border_1", label: "Light Border 1", min: 0, max: 1, step: 0.01),
            UniformControl(layer: "Water", uniform: "light_border_2", label: "Light Border 2", min: 0, max: 1, step: 0.01),
            UniformControl(layer: "Water", uniform: "size", label: "Noise Scale", min: 1, max: 15, step: 0.1),
            UniformControl(layer: "Water", uniform: "octaves", label: "Octaves", min: 1, max: 6, step: 1),
            UniformControl(layer: "Clouds", uniform: "cloud_cover", label: "Cloud Cover", min: 0, max: 1, step: 0.01),
        ]
    )
}

private let landMassesConfig = makeLandMassesConfig()

public final class LandMassesPlanet: PlanetBase, @unchecked Sendable {
    public init() throws {
        try super.init(config: landMassesConfig)
    }

    public override func setPixels(_ amount: Int) {
        let value = Float(amount)
        setFloat("Water", "pixels", value)
        setFloat("Land", "pixels", value)
        setFloat("Clouds", "pixels", value)
    }

    public override func setLight(_ position: SIMD2<Float>) {
        setVec2("Water", "light_origin", position)
        setVec2("Land", "light_origin", position)
        setVec2("Clouds", "light_origin", position)
    }

    public override func setSeed(_ seed: Int, rng: inout RandomStream) {
        let converted = Float(seed % 1000) / 100
        setFloat("Water", "seed", converted)
        setFloat("Land", "seed", converted)
        setFloat("Clouds", "seed", converted + 1.23)
    }

    public override func setRotation(_ radians: Float) {
        setFloat("Water", "rotation", radians)
        setFloat("Land", "rotation", radians)
        setFloat("Clouds", "rotation", radians)
    }

    public override func updateTime(_ t: Float) {
        setFloat("Water", "time", t * multiplier(for: "Water") * 0.02)
        setFloat("Land", "time", t * multiplier(for: "Land") * 0.02)
        setFloat("Clouds", "time", t * multiplier(for: "Clouds") * 0.02)
    }

    public override func setCustomTime(_ t: Float) {
        let speed = max(0.0001, getFloat("Water", "time_speed"))
        setFloat("Water", "time", t * Float.pi * 2 * speed)
        setFloat("Land", "time", t * Float.pi * 2 * speed)
        setFloat("Clouds", "time", t * Float.pi * 2 * speed * 0.8)
    }

    public override func setDither(_ enabled: Bool) {
        let value = enabled ? 1 : 0
        setFloat("Water", "should_dither", Float(value))
        setFloat("Land", "should_dither", Float(value))
        setFloat("Clouds", "should_dither", Float(value))
    }

    public override func isDitherEnabled() -> Bool {
        getFloat("Water", "should_dither") > 0.5
    }

    public override func randomizeColors(rng: inout RandomStream) -> [PixelColor] {
        var palette = generatePalette(
            rng: &rng,
            count: 3,
            hueDiff: randRange(&rng, min: 0.3, max: 0.6),
            saturation: 0.8
        )
        if palette.count < 3 {
            palette += Array(repeating: PixelColor(r: 0.3, g: 0.6, b: 0.8, a: 1), count: 3 - palette.count)
        }

        var waterColors: [PixelColor] = []
        for i in 0..<3 {
            var shade = palette[i % palette.count].lightened(by: Float(i) * 0.1)
            waterColors.append(shade)
        }

        var landColors: [PixelColor] = []
        for i in 0..<4 {
            let base = palette[(i + 1) % palette.count].shiftedHue(by: 0.1)
            landColors.append(base.darkened(by: 0.2))
        }

        let cloudColors = [
            PixelColor(r: 0.95, g: 0.95, b: 0.95, a: 1),
            PixelColor(r: 0.9, g: 0.9, b: 0.9, a: 1),
            PixelColor(r: 0.8, g: 0.8, b: 0.8, a: 1),
        ]

        let allColors = waterColors + landColors + cloudColors
        setColors(allColors)
        return allColors
    }
}

@MainActor
func registerLandMassesPlanet(into factories: inout [String: PlanetFactory]) {
    factories["Islands"] = { try LandMassesPlanet() }
}
