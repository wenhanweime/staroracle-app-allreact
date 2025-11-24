import Foundation
import simd

private let iceLandColors: [Float] = [
    0.980392, 1, 1, 1,
    0.780392, 0.831373, 0.882353, 1,
    0.572549, 0.560784, 0.721569, 1,
]

private let iceLakeColors: [Float] = [
    0.309804, 0.643137, 0.721569, 1,
    0.298039, 0.407843, 0.521569, 1,
    0.227451, 0.247059, 0.368627, 1,
]

private let iceCloudColors: [Float] = [
    0.882353, 0.94902, 1, 1,
    0.752941, 0.890196, 1, 1,
    0.368627, 0.439216, 0.647059, 1,
    0.25098, 0.286275, 0.45098, 1,
]

private func makeIceWorldConfig() -> PlanetConfig {
    let landUniforms: [String: UniformValue] = [
        "pixels": .float(100),
        "rotation": .float(0),
        "light_origin": .vec2(Vec2(0.3, 0.3)),
        "time_speed": .float(0.25),
        "dither_size": .float(2),
        "light_border_1": .float(0.48),
        "light_border_2": .float(0.632),
        "colors": .buffer(iceLandColors),
        "size": .float(8),
        "OCTAVES": .float(2),
        "seed": .float(1.036),
        "time": .float(0),
        "should_dither": .float(1),
    ]

    let lakeUniforms: [String: UniformValue] = [
        "pixels": .float(100),
        "rotation": .float(0),
        "light_origin": .vec2(Vec2(0.3, 0.3)),
        "time_speed": .float(0.2),
        "light_border_1": .float(0.024),
        "light_border_2": .float(0.047),
        "lake_cutoff": .float(0.55),
        "colors": .buffer(iceLakeColors),
        "size": .float(10),
        "OCTAVES": .float(3),
        "seed": .float(1.14),
        "time": .float(0),
    ]

    let cloudUniforms: [String: UniformValue] = [
        "pixels": .float(100),
        "rotation": .float(0),
        "cloud_cover": .float(0.546),
        "light_origin": .vec2(Vec2(0.3, 0.3)),
        "time_speed": .float(0.1),
        "stretch": .float(2.5),
        "cloud_curve": .float(1.3),
        "light_border_1": .float(0.566),
        "light_border_2": .float(0.781),
        "colors": .buffer(iceCloudColors),
        "size": .float(4),
        "OCTAVES": .float(4),
        "seed": .float(1.14),
        "time": .float(0),
    ]

    let controls: [UniformControl] = [
        UniformControl(layer: "Land", uniform: "time_speed", label: "Land Time Speed", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Land", uniform: "dither_size", label: "Land Dither Size", min: 0, max: 6, step: 0.1),
        UniformControl(layer: "Land", uniform: "light_border_1", label: "Land Light Border 1", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Land", uniform: "light_border_2", label: "Land Light Border 2", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Land", uniform: "size", label: "Land Noise Scale", min: 1, max: 12, step: 0.1),
        UniformControl(layer: "Land", uniform: "OCTAVES", label: "Land Octaves", min: 1, max: 6, step: 1),
        UniformControl(layer: "Lakes", uniform: "time_speed", label: "Lakes Time Speed", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Lakes", uniform: "light_border_1", label: "Lakes Light Border 1", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Lakes", uniform: "light_border_2", label: "Lakes Light Border 2", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Lakes", uniform: "lake_cutoff", label: "Lake Cutoff", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Lakes", uniform: "size", label: "Lakes Noise Scale", min: 1, max: 12, step: 0.1),
        UniformControl(layer: "Lakes", uniform: "OCTAVES", label: "Lakes Octaves", min: 1, max: 6, step: 1),
        UniformControl(layer: "Clouds", uniform: "cloud_cover", label: "Cloud Cover", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Clouds", uniform: "time_speed", label: "Cloud Time Speed", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Clouds", uniform: "stretch", label: "Cloud Stretch", min: 1, max: 3, step: 0.05),
        UniformControl(layer: "Clouds", uniform: "cloud_curve", label: "Cloud Curve", min: 0.5, max: 2, step: 0.05),
        UniformControl(layer: "Clouds", uniform: "light_border_1", label: "Cloud Light Border 1", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Clouds", uniform: "light_border_2", label: "Cloud Light Border 2", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Clouds", uniform: "size", label: "Cloud Noise Scale", min: 1, max: 10, step: 0.1),
        UniformControl(layer: "Clouds", uniform: "OCTAVES", label: "Cloud Octaves", min: 1, max: 6, step: 1),
    ]

    return PlanetConfig(
        id: "ice-world",
        label: "Ice World",
        relativeScale: 1,
        guiZoom: 1,
        layers: [
            LayerDefinition(
                name: "Land",
                shaderPath: "landmasses/water.frag",
                uniforms: landUniforms,
                colors: [ColorBinding(layer: "Land", uniform: "colors", slots: 3)]
            ),
            LayerDefinition(
                name: "Lakes",
                shaderPath: "ice-world/lakes.frag",
                uniforms: lakeUniforms,
                colors: [ColorBinding(layer: "Lakes", uniform: "colors", slots: 3)]
            ),
            LayerDefinition(
                name: "Clouds",
                shaderPath: "common/clouds.frag",
                uniforms: cloudUniforms,
                colors: [ColorBinding(layer: "Clouds", uniform: "colors", slots: 4)]
            ),
        ],
        uniformControls: controls
    )
}

private let iceWorldConfig = makeIceWorldConfig()

public final class IceWorldPlanet: PlanetBase, @unchecked Sendable {
    public init() throws {
        try super.init(config: iceWorldConfig)
    }

    public override func setPixels(_ amount: Int) {
        let value = Float(amount)
        setFloat("Land", "pixels", value)
        setFloat("Lakes", "pixels", value)
        setFloat("Clouds", "pixels", value)
    }

    public override func setLight(_ position: SIMD2<Float>) {
        setVec2("Land", "light_origin", position)
        setVec2("Lakes", "light_origin", position)
        setVec2("Clouds", "light_origin", position)
    }

    public override func setSeed(_ seed: Int, rng: inout RandomStream) {
        let converted = Float(seed % 1000) / 100
        setFloat("Land", "seed", converted)
        setFloat("Lakes", "seed", converted)
        setFloat("Clouds", "seed", converted)
        setFloat("Clouds", "cloud_cover", randRange(&rng, min: 0.35, max: 0.6))
    }

    public override func setRotation(_ radians: Float) {
        setFloat("Land", "rotation", radians)
        setFloat("Lakes", "rotation", radians)
        setFloat("Clouds", "rotation", radians)
    }

    public override func updateTime(_ t: Float) {
        setFloat("Land", "time", t * multiplier(for: "Land") * 0.02)
        setFloat("Lakes", "time", t * multiplier(for: "Lakes") * 0.02)
        setFloat("Clouds", "time", t * multiplier(for: "Clouds") * 0.01)
    }

    public override func setCustomTime(_ t: Float) {
        setFloat("Land", "time", t * multiplier(for: "Land"))
        setFloat("Lakes", "time", t * multiplier(for: "Lakes"))
        setFloat("Clouds", "time", t * multiplier(for: "Clouds"))
    }

    public override func setDither(_ enabled: Bool) {
        setFloat("Land", "should_dither", enabled ? 1 : 0)
    }

    public override func isDitherEnabled() -> Bool {
        getFloat("Land", "should_dither") > 0.5
    }

    public override func randomizeColors(rng: inout RandomStream) -> [Color] {
        var palette = generatePalette(
            rng: &rng,
            count: 3 + randInt(&rng, maxExclusive: 2),
            hueDiff: randRange(&rng, min: 0.7, max: 1.0),
            saturation: randRange(&rng, min: 0.45, max: 0.55)
        )
        if palette.isEmpty {
            palette = [Color(r: 0.7, g: 0.8, b: 0.9, a: 1)]
        }

        var land: [Color] = []
        let landBase = palette[0]
        for i in 0..<3 {
            let shaded = landBase.darkened(by: Float(i) / 3)
            var hsv = shaded.toHSV()
            hsv.h += 0.2 * (Float(i) / 4)
            land.append(Color.fromHSV(hsv))
        }

        var lakes: [Color] = []
        let lakeBase = palette[min(1, palette.count - 1)]
        for i in 0..<3 {
            let shaded = lakeBase.darkened(by: Float(i) / 3)
            var hsv = shaded.toHSV()
            hsv.h += 0.2 * (Float(i) / 3)
            lakes.append(Color.fromHSV(hsv))
        }

        var clouds: [Color] = []
        let cloudBase = palette[min(2, palette.count - 1)]
        for i in 0..<4 {
            let lightened = cloudBase.lightened(by: (1 - Float(i) / 4) * 0.8)
            var hsv = lightened.toHSV()
            hsv.h += 0.2 * (Float(i) / 4)
            clouds.append(Color.fromHSV(hsv))
        }

        let colors = land + lakes + clouds
        setColors(colors)
        return colors
    }
}

@MainActor
func registerIceWorldPlanet(into factories: inout [String: PlanetFactory]) {
    factories["Ice World"] = { try IceWorldPlanet() }
}
