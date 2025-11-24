import Foundation
import simd

private let circularGalaxyColors: [Float] = [
    0.992157, 0.937255, 0.843137, 1,
    0.968627, 0.756863, 0.505882, 1,
    0.741176, 0.603922, 0.870588, 1,
    0.45098, 0.435294, 0.752941, 1,
    0.278431, 0.400784, 0.635294, 1,
    0.184314, 0.239216, 0.417647, 1,
    0.12549, 0.152941, 0.270588, 1,
]

private func makeCircularGalaxyConfig() -> PlanetConfig {
    let uniforms: [String: UniformValue] = [
        "pixels": .float(200),
        "rotation": .float(0.512),
        "time_speed": .float(1.1),
        "dither_size": .float(2),
        "should_dither": .float(1),
        "colors": .buffer(circularGalaxyColors),
        "n_colors": .float(6),
        "size": .float(8.5),
        "OCTAVES": .float(1),
        "seed": .float(6.781),
        "time": .float(0),
        "tilt": .float(1),
        "n_layers": .float(6),
        "layer_height": .float(0.22),
        "zoom": .float(1.1),
        "swirl": .float(-11),
    ]

    let controls: [UniformControl] = [
        UniformControl(layer: "Galaxy", uniform: "time_speed", label: "Time Speed", min: 0, max: 4, step: 0.05),
        UniformControl(layer: "Galaxy", uniform: "dither_size", label: "Dither Size", min: 0, max: 6, step: 0.1),
        UniformControl(layer: "Galaxy", uniform: "size", label: "Noise Scale", min: 1, max: 15, step: 0.1),
        UniformControl(layer: "Galaxy", uniform: "OCTAVES", label: "Octaves", min: 1, max: 6, step: 1),
        UniformControl(layer: "Galaxy", uniform: "n_layers", label: "Layer Count", min: 1, max: 8, step: 1),
        UniformControl(layer: "Galaxy", uniform: "layer_height", label: "Layer Height", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Galaxy", uniform: "zoom", label: "Zoom", min: 0.5, max: 2.5, step: 0.05),
        UniformControl(layer: "Galaxy", uniform: "swirl", label: "Swirl", min: -12, max: 12, step: 0.5),
    ]

    return PlanetConfig(
        id: "galaxy-circular",
        label: "Galaxy Round",
        relativeScale: 1,
        guiZoom: 2,
        layers: [
            LayerDefinition(
                name: "Galaxy",
                shaderPath: "galaxy/galaxy.frag",
                uniforms: uniforms,
                colors: [ColorBinding(layer: "Galaxy", uniform: "colors", slots: 7)]
            ),
        ],
        uniformControls: controls
    )
}

private let circularGalaxyConfig = makeCircularGalaxyConfig()

public final class CircularGalaxyPlanet: PlanetBase, @unchecked Sendable {
    public init() throws {
        try super.init(config: circularGalaxyConfig)
    }

    public override func setPixels(_ amount: Int) {
        setFloat("Galaxy", "pixels", Float(amount))
    }

    public override func setLight(_ position: SIMD2<Float>) {
        // Galaxy shader ignores external light.
    }

    public override func setSeed(_ seed: Int, rng: inout RandomStream) {
        let converted = Float(seed % 1000) / 100
        setFloat("Galaxy", "seed", converted)
    }

    public override func setRotation(_ radians: Float) {
        setFloat("Galaxy", "rotation", radians)
    }

    public override func updateTime(_ t: Float) {
        setFloat("Galaxy", "time", t * multiplier(for: "Galaxy") * 0.035)
    }

    public override func setCustomTime(_ t: Float) {
        let speed = max(0.0001, getFloat("Galaxy", "time_speed"))
        setFloat("Galaxy", "time", t * Float.pi * 2 * speed)
    }

    public override func setDither(_ enabled: Bool) {
        setFloat("Galaxy", "should_dither", enabled ? 1 : 0)
    }

    public override func isDitherEnabled() -> Bool {
        getFloat("Galaxy", "should_dither") > 0.5
    }

    public override func randomizeColors(rng: inout RandomStream) -> [Color] {
        var palette = generatePalette(
            rng: &rng,
            count: 6,
            hueDiff: randRange(&rng, min: 0.45, max: 0.75),
            saturation: 1.2
        )
        if palette.count < 6 {
            palette += Array(repeating: Color(r: 0.9, g: 0.8, b: 0.6, a: 1), count: 6 - palette.count)
        }

        var colors: [Color] = []
        for i in 0..<6 {
            var shade = palette[i % palette.count].darkened(by: Float(i) / 7)
            shade = shade.lightened(by: (1 - Float(i) / 6) * 0.55)
            colors.append(shade)
        }
        colors.append(colors.last ?? Color(r: 1, g: 1, b: 1, a: 1))
        setColors(colors)
        return colors
    }
}

@MainActor
func registerCircularGalaxyPlanet(into factories: inout [String: PlanetFactory]) {
    factories["Galaxy Round"] = { try CircularGalaxyPlanet() }
}

// MARK: - Twinkle Galaxy

private let twinkleGalaxyColors: [Float] = [
    0.992157, 0.937255, 0.843137, 1,
    0.87451, 0.878431, 0.909804, 1,
    0.639216, 0.654902, 0.760784, 1,
    0.407843, 0.435294, 0.6, 1,
    0.231373, 0.490196, 0.309804, 1,
    0.109804, 0.243137, 0.368627, 1,
    0.035294, 0.086275, 0.145098, 1,
]

private func makeTwinkleGalaxyConfig() -> PlanetConfig {
    let uniforms: [String: UniformValue] = [
        "pixels": .float(220),
        "time_speed": .float(0.8),
        "colors": .buffer(twinkleGalaxyColors),
        "n_colors": .float(6),
        "time": .float(0),
        "branch_count": .float(4),
        "branch_sharpness": .float(3),
        "morph_speed": .float(0.4),
        "halo_softness": .float(0.2),
        "spark_scale": .float(1.2),
        "rotation_speed": .float(1.2),
        "flicker_strength": .float(0.7),
    ]

    let controls: [UniformControl] = [
        UniformControl(layer: "GalaxyLinear", uniform: "time_speed", label: "闪烁速度", min: 0, max: 2, step: 0.05),
        UniformControl(layer: "GalaxyLinear", uniform: "morph_speed", label: "脉冲速度", min: 0.1, max: 1, step: 0.02),
        UniformControl(layer: "GalaxyLinear", uniform: "branch_count", label: "光芒数量", min: 2, max: 8, step: 1),
        UniformControl(layer: "GalaxyLinear", uniform: "branch_sharpness", label: "光芒锐度", min: 1, max: 6, step: 0.1),
        UniformControl(layer: "GalaxyLinear", uniform: "halo_softness", label: "光晕柔和度", min: 0.05, max: 0.4, step: 0.01),
        UniformControl(layer: "GalaxyLinear", uniform: "spark_scale", label: "光芒长度", min: 0.5, max: 2.5, step: 0.05),
        UniformControl(layer: "GalaxyLinear", uniform: "rotation_speed", label: "光芒旋转", min: 0, max: 2, step: 0.05),
        UniformControl(layer: "GalaxyLinear", uniform: "flicker_strength", label: "闪烁强度", min: 0, max: 1, step: 0.05),
    ]

    let layer = LayerDefinition(
        name: "GalaxyLinear",
        shaderPath: "galaxy/linear_twinkle.frag",
        uniforms: uniforms,
        colors: [ColorBinding(layer: "GalaxyLinear", uniform: "colors", slots: 7)]
    )

    return PlanetConfig(
        id: "twinkle-galaxy",
        label: "Twinkle Galaxy",
        relativeScale: 1,
        guiZoom: 2,
        layers: [layer],
        uniformControls: controls
    )
}

private let twinkleGalaxyConfig = makeTwinkleGalaxyConfig()

public final class TwinkleGalaxyPlanet: PlanetBase, @unchecked Sendable {
    public init() throws {
        try super.init(config: twinkleGalaxyConfig)
    }

    public override func setPixels(_ amount: Int) {
        setFloat("GalaxyLinear", "pixels", Float(amount))
    }

    public override func setSeed(_ seed: Int, rng: inout RandomStream) {
        let converted = Float(seed % 1000) / 100
        setFloat("GalaxyLinear", "seed", converted)
    }

    public override func setRotation(_ radians: Float) {
        setFloat("GalaxyLinear", "rotation", radians)
    }

    public override func updateTime(_ t: Float) {
        setFloat("GalaxyLinear", "time", t)
    }

    public override func setCustomTime(_ t: Float) {
        setFloat("GalaxyLinear", "time", t)
    }

    public override func setDither(_ enabled: Bool) {
        setFloat("GalaxyLinear", "should_dither", enabled ? 1 : 0)
    }

    public override func isDitherEnabled() -> Bool {
        getFloat("GalaxyLinear", "should_dither") > 0.5
    }

    public override func randomizeColors(rng: inout RandomStream) -> [Color] {
        var palette = generatePalette(
            rng: &rng,
            count: 6,
            hueDiff: randRange(&rng, min: 0.35, max: 0.6),
            saturation: 1.1
        )
        if palette.count < 6 {
            palette += Array(repeating: Color(r: 0.85, g: 0.9, b: 1, a: 1), count: 6 - palette.count)
        }

        var colors: [Color] = []
        for i in 0..<6 {
            var shade = palette[i % palette.count]
            let mix = Float(i) / 6
            shade = shade.lightened(by: 0.5 * (1 - mix))
            shade = shade.darkened(by: mix * 0.4)
            colors.append(shade)
        }
        colors.append(Color(r: 1, g: 1, b: 1, a: 1))
        setColors(colors)
        return colors
    }
}

@MainActor
func registerTwinkleGalaxyPlanet(into factories: inout [String: PlanetFactory]) {
    factories["Twinkle Galaxy"] = { try TwinkleGalaxyPlanet() }
}
