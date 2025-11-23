import Foundation
import simd

private let riversLandColors: [Float] = [
    0.388235, 0.670588, 0.247059, 1,
    0.231373, 0.490196, 0.309804, 1,
    0.184314, 0.341176, 0.32549, 1,
    0.156863, 0.207843, 0.25098, 1,
]

private let riversWaterColors: [Float] = [
    0.309804, 0.643137, 0.721569, 1,
    0.298039, 0.407843, 0.521569, 1,
    0.227451, 0.247059, 0.368627, 1,
]

private let riversCloudColors: [Float] = [
    0.941176, 0.964706, 0.941176, 1,
    0.886275, 0.952941, 0.894118, 1,
    0.745098, 0.85098, 0.784314, 1,
]

private func makeRiversConfig() -> PlanetConfig {
    let landUniforms: [String: UniformValue] = [
        "pixels": .float(100),
        "rotation": .float(0),
        "light_origin": .vec2(Vec2(0.39, 0.39)),
        "time_speed": .float(0.2),
        "dither_size": .float(2),
        "should_dither": .float(1),
        "light_border_1": .float(0.32),
        "light_border_2": .float(0.534),
        "colors": .buffer(riversLandColors),
        "size": .float(4),
        "octaves": .float(3),
        "seed": .float(1.234),
        "time": .float(0),
        "river_cutoff": .float(0.368),
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
        "colors": .buffer(riversCloudColors),
        "size": .float(7),
        "octaves": .float(3),
        "seed": .float(9.876),
        "time": .float(0),
        "cloud_cover": .float(0.47),
    ]

    return PlanetConfig(
        id: "rivers",
        label: "Terran Wet",
        relativeScale: 1,
        guiZoom: 1,
        layers: [
            LayerDefinition(
                name: "Land",
                shaderPath: "rivers/land.frag",
                uniforms: landUniforms,
                colors: [
                    ColorBinding(layer: "Land", uniform: "colors", slots: 4),
                    ColorBinding(layer: "Land", uniform: "color2", slots: 3) // Water colors
                ]
            ),
            LayerDefinition(
                name: "Clouds",
                shaderPath: "common/clouds.frag",
                uniforms: cloudsUniforms,
                colors: [ColorBinding(layer: "Clouds", uniform: "colors", slots: 3)]
            ),
        ],
        uniformControls: [
            UniformControl(layer: "Land", uniform: "time_speed", label: "Spin Speed", min: 0, max: 1, step: 0.01),
            UniformControl(layer: "Land", uniform: "dither_size", label: "Dither Size", min: 0, max: 6, step: 0.1),
            UniformControl(layer: "Land", uniform: "light_border_1", label: "Light Border 1", min: 0, max: 1, step: 0.01),
            UniformControl(layer: "Land", uniform: "light_border_2", label: "Light Border 2", min: 0, max: 1, step: 0.01),
            UniformControl(layer: "Land", uniform: "size", label: "Noise Scale", min: 1, max: 15, step: 0.1),
            UniformControl(layer: "Land", uniform: "octaves", label: "Octaves", min: 1, max: 6, step: 1),
            UniformControl(layer: "Land", uniform: "river_cutoff", label: "River Cutoff", min: 0, max: 1, step: 0.01),
            UniformControl(layer: "Clouds", uniform: "cloud_cover", label: "Cloud Cover", min: 0, max: 1, step: 0.01),
        ]
    )
}

private let riversConfig = makeRiversConfig()

public final class RiversPlanet: PlanetBase, @unchecked Sendable {
    public init() throws {
        try super.init(config: riversConfig)
        // Initialize water colors manually since they are a secondary binding on Land layer
        setBuffer("Land", "color2", riversWaterColors)
    }

    public override func setPixels(_ amount: Int) {
        let value = Float(amount)
        setFloat("Land", "pixels", value)
        setFloat("Clouds", "pixels", value)
    }

    public override func setLight(_ position: SIMD2<Float>) {
        setVec2("Land", "light_origin", position)
        setVec2("Clouds", "light_origin", position)
    }

    public override func setSeed(_ seed: Int, rng: inout RandomStream) {
        let converted = Float(seed % 1000) / 100
        setFloat("Land", "seed", converted)
        setFloat("Clouds", "seed", converted + 1.23)
    }

    public override func setRotation(_ radians: Float) {
        setFloat("Land", "rotation", radians)
        setFloat("Clouds", "rotation", radians)
    }

    public override func updateTime(_ t: Float) {
        setFloat("Land", "time", t * multiplier(for: "Land") * 0.02)
        setFloat("Clouds", "time", t * multiplier(for: "Clouds") * 0.02)
    }

    public override func setCustomTime(_ t: Float) {
        let speed = max(0.0001, getFloat("Land", "time_speed"))
        setFloat("Land", "time", t * Float.pi * 2 * speed)
        setFloat("Clouds", "time", t * Float.pi * 2 * speed * 0.8)
    }

    public override func setDither(_ enabled: Bool) {
        let value = enabled ? 1 : 0
        setFloat("Land", "should_dither", Float(value))
        setFloat("Clouds", "should_dither", Float(value))
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
            palette += Array(repeating: PixelColor(r: 0.4, g: 0.6, b: 0.3, a: 1), count: 4 - palette.count)
        }

        var landColors: [PixelColor] = []
        for i in 0..<4 {
            var shade = palette[i % palette.count].darkened(by: Float(i) / 4)
            landColors.append(shade)
        }

        var waterColors: [PixelColor] = []
        for i in 0..<3 {
            let base = palette[(i + 2) % palette.count].shiftedHue(by: 0.5)
            waterColors.append(base.lightened(by: 0.1))
        }

        let cloudColors = [
            PixelColor(r: 0.95, g: 0.95, b: 0.95, a: 1),
            PixelColor(r: 0.9, g: 0.9, b: 0.9, a: 1),
            PixelColor(r: 0.8, g: 0.8, b: 0.8, a: 1),
        ]

        let allColors = landColors + waterColors + cloudColors
        setColors(allColors)
        return allColors
    }
}

@MainActor
func registerRiversPlanet(into factories: inout [String: PlanetFactory]) {
    factories["Terran Wet"] = { try RiversPlanet() }
}
