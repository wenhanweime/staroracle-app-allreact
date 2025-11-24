import Foundation
import simd

private let waterColorsLandMasses: [Float] = [
    0.572549, 0.909804, 0.752941, 1,
    0.309804, 0.643137, 0.721569, 1,
    0.172549, 0.207843, 0.301961, 1,
]

private let landColorsLandMasses: [Float] = [
    0.784314, 0.831373, 0.364706, 1,
    0.388235, 0.670588, 0.247059, 1,
    0.184314, 0.341176, 0.32549, 1,
    0.156863, 0.207843, 0.25098, 1,
]

private let cloudColorsLandMasses: [Float] = [
    0.87451, 0.878431, 0.909804, 1,
    0.639216, 0.654902, 0.760784, 1,
    0.407843, 0.435294, 0.6, 1,
    0.25098, 0.286275, 0.45098, 1,
]

private func makeLandMassesConfig() -> PlanetConfig {
    let waterUniforms: [String: UniformValue] = [
        "pixels": .float(100),
        "rotation": .float(0),
        "light_origin": .vec2(Vec2(0.39, 0.39)),
        "time_speed": .float(0.1),
        "dither_size": .float(2),
        "light_border_1": .float(0.4),
        "light_border_2": .float(0.6),
        "colors": .buffer(waterColorsLandMasses),
        "size": .float(5.228),
        "OCTAVES": .float(3),
        "seed": .float(10.0),
        "time": .float(0),
        "should_dither": .float(1),
    ]

    let landUniforms: [String: UniformValue] = [
        "pixels": .float(100),
        "rotation": .float(0.2),
        "light_origin": .vec2(Vec2(0.39, 0.39)),
        "time_speed": .float(0.2),
        "dither_size": .float(2),
        "light_border_1": .float(0.32),
        "light_border_2": .float(0.534),
        "land_cutoff": .float(0.633),
        "colors": .buffer(landColorsLandMasses),
        "size": .float(4.292),
        "OCTAVES": .float(6),
        "seed": .float(7.947),
        "time": .float(0),
    ]

    let cloudUniforms: [String: UniformValue] = [
        "pixels": .float(100),
        "rotation": .float(0),
        "cloud_cover": .float(0.415),
        "light_origin": .vec2(Vec2(0.39, 0.39)),
        "time_speed": .float(0.47),
        "stretch": .float(2),
        "cloud_curve": .float(1.3),
        "light_border_1": .float(0.52),
        "light_border_2": .float(0.62),
        "colors": .buffer(cloudColorsLandMasses),
        "size": .float(7.745),
        "OCTAVES": .float(2),
        "seed": .float(5.939),
        "time": .float(0),
    ]

    let controls: [UniformControl] = [
        UniformControl(layer: "Water", uniform: "time_speed", label: "Water Time Speed", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Water", uniform: "light_border_1", label: "Water Light Border 1", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Water", uniform: "light_border_2", label: "Water Light Border 2", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Water", uniform: "size", label: "Water Noise Scale", min: 1, max: 12, step: 0.1),
        UniformControl(layer: "Water", uniform: "OCTAVES", label: "Water Octaves", min: 1, max: 8, step: 1),
        UniformControl(layer: "Land", uniform: "time_speed", label: "Land Time Speed", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Land", uniform: "light_border_1", label: "Land Light Border 1", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Land", uniform: "light_border_2", label: "Land Light Border 2", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Land", uniform: "land_cutoff", label: "Land Cutoff", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Land", uniform: "size", label: "Land Noise Scale", min: 1, max: 12, step: 0.1),
        UniformControl(layer: "Land", uniform: "OCTAVES", label: "Land Octaves", min: 1, max: 8, step: 1),
        UniformControl(layer: "Cloud", uniform: "cloud_cover", label: "Cloud Cover", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Cloud", uniform: "time_speed", label: "Cloud Time Speed", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Cloud", uniform: "stretch", label: "Cloud Stretch", min: 1, max: 3, step: 0.05),
        UniformControl(layer: "Cloud", uniform: "cloud_curve", label: "Cloud Curve", min: 0.5, max: 2, step: 0.05),
        UniformControl(layer: "Cloud", uniform: "light_border_1", label: "Cloud Light Border 1", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Cloud", uniform: "light_border_2", label: "Cloud Light Border 2", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Cloud", uniform: "size", label: "Cloud Noise Scale", min: 1, max: 12, step: 0.1),
        UniformControl(layer: "Cloud", uniform: "OCTAVES", label: "Cloud Octaves", min: 1, max: 6, step: 1),
    ]

    return PlanetConfig(
        id: "landmasses",
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
                name: "Cloud",
                shaderPath: "common/clouds.frag",
                uniforms: cloudUniforms,
                colors: [ColorBinding(layer: "Cloud", uniform: "colors", slots: 4)]
            ),
        ],
        uniformControls: controls
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
        setFloat("Cloud", "pixels", value)
    }

    public override func setLight(_ position: SIMD2<Float>) {
        setVec2("Water", "light_origin", position)
        setVec2("Land", "light_origin", position)
        setVec2("Cloud", "light_origin", position)
    }

    public override func setSeed(_ seed: Int, rng: inout RandomStream) {
        let converted = Float(seed % 1000) / 100
        setFloat("Water", "seed", converted)
        setFloat("Land", "seed", converted)
        setFloat("Cloud", "seed", converted)
        setFloat("Cloud", "cloud_cover", randRange(&rng, min: 0.35, max: 0.6))
    }

    public override func setRotation(_ radians: Float) {
        setFloat("Water", "rotation", radians)
        setFloat("Land", "rotation", radians)
        setFloat("Cloud", "rotation", radians)
    }

    public override func updateTime(_ t: Float) {
        setFloat("Water", "time", t * multiplier(for: "Water") * 0.02)
        setFloat("Land", "time", t * multiplier(for: "Land") * 0.02)
        setFloat("Cloud", "time", t * multiplier(for: "Cloud") * 0.01)
    }

    public override func setCustomTime(_ t: Float) {
        setFloat("Water", "time", t * multiplier(for: "Water"))
        setFloat("Land", "time", t * multiplier(for: "Land"))
        setFloat("Cloud", "time", t * multiplier(for: "Cloud"))
    }

    public override func setDither(_ enabled: Bool) {
        setFloat("Water", "should_dither", enabled ? 1 : 0)
    }

    public override func isDitherEnabled() -> Bool {
        getFloat("Water", "should_dither") > 0.5
    }

    public override func randomizeColors(rng: inout RandomStream) -> [Color] {
        var palette = generatePalette(
            rng: &rng,
            count: 3 + randInt(&rng, maxExclusive: 2),
            hueDiff: randRange(&rng, min: 0.7, max: 1.0),
            saturation: randRange(&rng, min: 0.45, max: 0.55)
        )
        if palette.isEmpty {
            palette = [Color(r: 0.4, g: 0.7, b: 0.6, a: 1)]
        }

        var water: [Color] = []
        let waterBase = palette[1 % palette.count]
        for i in 0..<3 {
            let shaded = waterBase.darkened(by: Float(i) / 5)
            var hsv = shaded.toHSV()
            hsv.h += 0.1 * (Float(i) / 2)
            water.append(Color.fromHSV(hsv))
        }

        var land: [Color] = []
        let landBase = palette[0]
        for i in 0..<4 {
            let shaded = landBase.darkened(by: Float(i) / 4)
            var hsv = shaded.toHSV()
            hsv.h += 0.2 * (Float(i) / 4)
            land.append(Color.fromHSV(hsv))
        }

        var clouds: [Color] = []
        let cloudBase = palette[min(2, palette.count - 1)]
        for i in 0..<4 {
            let lightened = cloudBase.lightened(by: (1 - Float(i) / 4) * 0.8)
            var hsv = lightened.toHSV()
            hsv.h += 0.2 * (Float(i) / 4)
            clouds.append(Color.fromHSV(hsv))
        }

        let combined = water + land + clouds
        setColors(combined)
        return combined
    }
}

@MainActor
func registerLandMassesPlanet(into factories: inout [String: PlanetFactory]) {
    factories["Islands"] = { try LandMassesPlanet() }
}
