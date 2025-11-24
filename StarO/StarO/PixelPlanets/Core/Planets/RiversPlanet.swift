import Foundation
import simd

private let landColors: [Float] = [
    0.388235, 0.670588, 0.247059, 1,
    0.231373, 0.490196, 0.309804, 1,
    0.184314, 0.341176, 0.325490, 1,
    0.156863, 0.207843, 0.250980, 1,
    0.309804, 0.643137, 0.721569, 1,
    0.250980, 0.286275, 0.450980, 1,
]

private let cloudColors: [Float] = [
    0.960784, 1.0, 0.909804, 1,
    0.874510, 0.878431, 0.909804, 1,
    0.407843, 0.435294, 0.600000, 1,
    0.250980, 0.286275, 0.450980, 1,
]

private func normalizedSeed(_ seed: Int) -> Float {
    let remainder = ((seed % 1000) + 1000) % 1000
    let value = Float(remainder) / 100
    return max(value, 0.01)
}

private func makeRiversConfig() -> PlanetConfig {
    let landUniforms: [String: UniformValue] = [
        "pixels": .float(100),
        "rotation": .float(0.2),
        "light_origin": .vec2(Vec2(0.39, 0.39)),
        "time_speed": .float(0.1),
        "dither_size": .float(3.951),
        "should_dither": .float(1),
        "light_border_1": .float(0.287),
        "light_border_2": .float(0.476),
        "river_cutoff": .float(0.368),
        "colors": .buffer(landColors),
        "size": .float(4.6),
        "OCTAVES": .float(6),
        "seed": .float(8.98),
        "time": .float(0),
    ]

    let cloudUniforms: [String: UniformValue] = [
        "pixels": .float(100),
        "rotation": .float(0),
        "cloud_cover": .float(0.47),
        "light_origin": .vec2(Vec2(0.39, 0.39)),
        "time_speed": .float(0.1),
        "stretch": .float(2),
        "cloud_curve": .float(1.3),
        "light_border_1": .float(0.52),
        "light_border_2": .float(0.62),
        "colors": .buffer(cloudColors),
        "size": .float(7.315),
        "OCTAVES": .float(2),
        "seed": .float(5.939),
        "time": .float(0),
    ]

    let landLayer = LayerDefinition(
        name: "Land",
        shaderPath: "rivers/land.frag",
        uniforms: landUniforms,
        colors: [ColorBinding(layer: "Land", uniform: "colors", slots: 6)]
    )

    let cloudLayer = LayerDefinition(
        name: "Cloud",
        shaderPath: "common/clouds.frag",
        uniforms: cloudUniforms,
        colors: [ColorBinding(layer: "Cloud", uniform: "colors", slots: 4)]
    )

    let controls: [UniformControl] = [
        UniformControl(layer: "Land", uniform: "time_speed", label: "Land Time Speed", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Land", uniform: "dither_size", label: "Land Dither Size", min: 0, max: 6, step: 0.1),
        UniformControl(layer: "Land", uniform: "light_border_1", label: "Land Light Border 1", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Land", uniform: "light_border_2", label: "Land Light Border 2", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Land", uniform: "river_cutoff", label: "River Cutoff", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Land", uniform: "size", label: "Land Noise Scale", min: 1, max: 12, step: 0.1),
        UniformControl(layer: "Land", uniform: "OCTAVES", label: "Land Octaves", min: 1, max: 8, step: 1),
        UniformControl(layer: "Cloud", uniform: "cloud_cover", label: "Cloud Cover", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Cloud", uniform: "time_speed", label: "Cloud Time Speed", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Cloud", uniform: "stretch", label: "Cloud Stretch", min: 0.5, max: 3, step: 0.05),
        UniformControl(layer: "Cloud", uniform: "cloud_curve", label: "Cloud Curve", min: 0.5, max: 2, step: 0.05),
        UniformControl(layer: "Cloud", uniform: "light_border_1", label: "Cloud Light Border 1", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Cloud", uniform: "light_border_2", label: "Cloud Light Border 2", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Cloud", uniform: "size", label: "Cloud Noise Scale", min: 1, max: 12, step: 0.1),
        UniformControl(layer: "Cloud", uniform: "OCTAVES", label: "Cloud Octaves", min: 1, max: 6, step: 1),
    ]

    return PlanetConfig(
        id: "rivers",
        label: "Terran Wet",
        relativeScale: 1,
        guiZoom: 1,
        layers: [landLayer, cloudLayer],
        uniformControls: controls
    )
}

private let riversConfig = makeRiversConfig()

public final class RiversPlanet: PlanetBase, @unchecked Sendable {
    public init() throws {
        try super.init(config: riversConfig)
    }

    public override func setPixels(_ amount: Int) {
        let value = Float(amount)
        setFloat("Land", "pixels", value)
        setFloat("Cloud", "pixels", value)
    }

    public override func setLight(_ position: SIMD2<Float>) {
        setVec2("Land", "light_origin", position)
        setVec2("Cloud", "light_origin", position)
    }

    public override func setSeed(_ seed: Int, rng: inout RandomStream) {
        let converted = normalizedSeed(seed)
        setFloat("Land", "seed", converted)
        setFloat("Cloud", "seed", converted)
        setFloat("Cloud", "cloud_cover", randRange(&rng, min: 0.35, max: 0.6))
    }

    public override func setRotation(_ radians: Float) {
        setFloat("Land", "rotation", radians)
        setFloat("Cloud", "rotation", radians)
    }

    public override func updateTime(_ t: Float) {
        setFloat("Land", "time", t * multiplier(for: "Land") * 0.02)
        setFloat("Cloud", "time", t * multiplier(for: "Cloud") * 0.01)
    }

    public override func setCustomTime(_ t: Float) {
        setFloat("Land", "time", t * multiplier(for: "Land"))
        setFloat("Cloud", "time", t * multiplier(for: "Cloud") * 0.5)
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
            count: 3 + randInt(&rng, maxExclusive: 2),
            hueDiff: randRange(&rng, min: 0.7, max: 1.0),
            saturation: randRange(&rng, min: 0.45, max: 0.55)
        )
        if palette.isEmpty {
            palette = [PixelColor(r: 0.3, g: 0.6, b: 0.8, a: 1)]
        }

        var land: [PixelColor] = []
        let landBase = palette[0]
        for i in 0..<4 {
            let factor = Float(i) / 4
            let shaded = landBase.darkened(by: factor)
            var hsv = shaded.toHSV()
            hsv.h += 0.2 * factor
            land.append(PixelColor.fromHSV(hsv))
        }

        var rivers: [PixelColor] = []
        let riverBase = palette[min(1, palette.count - 1)]
        for i in 0..<2 {
            let factor = Float(i) / 2
            let shaded = riverBase.darkened(by: factor)
            var hsv = shaded.toHSV()
            hsv.h += 0.2 * factor
            rivers.append(PixelColor.fromHSV(hsv))
        }

        var clouds: [PixelColor] = []
        let cloudBase = palette[min(2, palette.count - 1)]
        for i in 0..<4 {
            let factor = Float(i) / 4
            let lightened = cloudBase.lightened(by: (1 - factor) * 0.8)
            var hsv = lightened.toHSV()
            hsv.h += 0.2 * factor
            clouds.append(PixelColor.fromHSV(hsv))
        }

        let colors = land + rivers + clouds
        setColors(colors)
        return colors
    }
}

@MainActor
func registerRiversPlanet(into factories: inout [String: PlanetFactory]) {
    factories["Terran Wet"] = { try RiversPlanet() }
}
