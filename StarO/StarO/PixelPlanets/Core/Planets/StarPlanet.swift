import Foundation
import simd
private let blobColors: [Float] = [1, 1, 0.894118, 1]

private let starGradientColors: [Float] = [
    0.960784, 1, 0.909804, 1,
    0.466667, 0.839216, 0.756863, 1,
    0.109804, 0.572549, 0.654902, 1,
    0.0117647, 0.243137, 0.368627, 1,
]

private let flareGradientColors: [Float] = [
    0.466667, 0.839216, 0.756863, 1,
    1, 1, 0.894118, 1,
]

private func makeStarConfig() -> PlanetConfig {
    let blobs = LayerDefinition(
        name: "Blobs",
        shaderPath: "star/blobs.frag",
        uniforms: [
            "pixels": .float(200),
            "colors": .buffer(blobColors),
            "time_speed": .float(0.05),
            "time": .float(0),
            "rotation": .float(0),
            "seed": .float(3.078),
            "circle_amount": .float(2),
            "circle_size": .float(1),
            "size": .float(4.93),
            "OCTAVES": .float(4),
        ],
        colors: [ColorBinding(layer: "Blobs", uniform: "colors", slots: 1)]
    )

    let starCore = LayerDefinition(
        name: "Star",
        shaderPath: "star/star.frag",
        uniforms: [
            "pixels": .float(100),
            "time_speed": .float(0.05),
            "time": .float(0),
            "rotation": .float(0),
            "colors": .buffer(starGradientColors),
            "n_colors": .float(4),
            "should_dither": .float(1),
            "seed": .float(4.837),
            "size": .float(4.463),
            "OCTAVES": .float(4),
            "TILES": .float(1),
        ],
        colors: [ColorBinding(layer: "Star", uniform: "colors", slots: 4)]
    )

    let flares = LayerDefinition(
        name: "StarFlares",
        shaderPath: "star/flares.frag",
        uniforms: [
            "pixels": .float(200),
            "colors": .buffer(flareGradientColors),
            "time_speed": .float(0.05),
            "time": .float(0),
            "rotation": .float(0),
            "should_dither": .float(1),
            "storm_width": .float(0.3),
            "storm_dither_width": .float(0),
            "scale": .float(1),
            "seed": .float(3.078),
            "circle_amount": .float(2),
            "circle_scale": .float(1),
            "size": .float(1.6),
            "OCTAVES": .float(4),
        ],
        colors: [ColorBinding(layer: "StarFlares", uniform: "colors", slots: 2)]
    )

    let controls: [UniformControl] = [
        UniformControl(layer: "Blobs", uniform: "time_speed", label: "Blobs Time Speed", min: 0, max: 0.3, step: 0.005),
        UniformControl(layer: "Blobs", uniform: "circle_amount", label: "Blobs Circle Amount", min: 1, max: 6, step: 1),
        UniformControl(layer: "Blobs", uniform: "circle_size", label: "Blobs Circle Size", min: 0.5, max: 2, step: 0.05),
        UniformControl(layer: "Blobs", uniform: "size", label: "Blobs Noise Scale", min: 1, max: 10, step: 0.1),
        UniformControl(layer: "Blobs", uniform: "OCTAVES", label: "Blobs Octaves", min: 1, max: 6, step: 1),
        UniformControl(layer: "Star", uniform: "time_speed", label: "Star Time Speed", min: 0, max: 0.2, step: 0.005),
        UniformControl(layer: "Star", uniform: "n_colors", label: "Star Colors", min: 2, max: 6, step: 1),
        UniformControl(layer: "Star", uniform: "size", label: "Star Noise Scale", min: 1, max: 10, step: 0.1),
        UniformControl(layer: "Star", uniform: "OCTAVES", label: "Star Octaves", min: 1, max: 6, step: 1),
        UniformControl(layer: "Star", uniform: "TILES", label: "Star Tiles", min: 1, max: 4, step: 1),
        UniformControl(layer: "StarFlares", uniform: "time_speed", label: "Flares Time Speed", min: 0, max: 0.3, step: 0.005),
        UniformControl(layer: "StarFlares", uniform: "storm_width", label: "Storm Width", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "StarFlares", uniform: "storm_dither_width", label: "Storm Dither Width", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "StarFlares", uniform: "scale", label: "Flares Scale", min: 0.5, max: 3, step: 0.05),
        UniformControl(layer: "StarFlares", uniform: "circle_amount", label: "Flares Circle Amount", min: 1, max: 6, step: 1),
        UniformControl(layer: "StarFlares", uniform: "circle_scale", label: "Flares Circle Scale", min: 0.5, max: 3, step: 0.05),
        UniformControl(layer: "StarFlares", uniform: "size", label: "Flares Noise Scale", min: 0.5, max: 6, step: 0.1),
        UniformControl(layer: "StarFlares", uniform: "OCTAVES", label: "Flares Octaves", min: 1, max: 6, step: 1),
    ]

    return PlanetConfig(
        id: "star",
        label: "Star",
        relativeScale: 2,
        guiZoom: 2,
        layers: [blobs, starCore, flares],
        uniformControls: controls
    )
}

private let starConfig = makeStarConfig()

public final class StarPlanet: PlanetBase, @unchecked Sendable {
    public init() throws {
        try super.init(config: starConfig)
    }

    public override func setPixels(_ amount: Int) {
        let scaled = Float(amount) * relativeScale
        setFloat("Blobs", "pixels", scaled)
        setFloat("Star", "pixels", Float(amount))
        setFloat("StarFlares", "pixels", scaled)
    }

    public override func setLight(_ position: SIMD2<Float>) {
        // Star shader does not expose light control in original implementation.
    }

    public override func setSeed(_ seed: Int, rng: inout RandomStream) {
        let converted = Float(seed % 1000) / 100.0 + 1.0
        setFloat("Blobs", "seed", converted)
        setFloat("Star", "seed", converted)
        setFloat("StarFlares", "seed", converted)
    }

    public override func setRotation(_ radians: Float) {
        setFloat("Blobs", "rotation", radians)
        setFloat("Star", "rotation", radians)
        setFloat("StarFlares", "rotation", radians)
    }

    public override func updateTime(_ t: Float) {
        setFloat("Blobs", "time", t * multiplier(for: "Blobs") * 0.01)
        setFloat("Star", "time", t * multiplier(for: "Star") * 0.005)
        setFloat("StarFlares", "time", t * multiplier(for: "StarFlares") * 0.015)
    }

    public override func setCustomTime(_ t: Float) {
        setFloat("Blobs", "time", t * multiplier(for: "Blobs"))
        let speed = max(0.0001, getFloat("Star", "time_speed"))
        setFloat("Star", "time", t * (1.0 / speed))
        setFloat("StarFlares", "time", t * multiplier(for: "StarFlares"))
    }

    public override func setDither(_ enabled: Bool) {
        let value = enabled ? 1 : 0
        setFloat("Star", "should_dither", Float(value))
        setFloat("StarFlares", "should_dither", Float(value))
    }

    public override func isDitherEnabled() -> Bool {
        getFloat("Star", "should_dither") > 0.5
    }

    public override func randomizeColors(rng: inout RandomStream) -> [PixelColor] {
        var palette = generatePalette(
            rng: &rng,
            count: 4,
            hueDiff: randRange(&rng, min: 0.2, max: 0.4),
            saturation: 2.0
        )
        if palette.count < 4 {
            palette += Array(repeating: PixelColor(r: 1, g: 0.8, b: 0.4, a: 1), count: 4 - palette.count)
        }

        var shades: [PixelColor] = []
        for i in 0..<4 {
            var shade = palette[i].darkened(by: Float(i) / 4 * 0.9)
            shade = shade.lightened(by: (1 - Float(i) / 4) * 0.8)
            shades.append(shade)
        }
        shades[0] = shades[0].lightened(by: 0.8)

        let final = [shades[0]] + shades + [shades[1], shades[0]]
        setColors(final)
        return final
    }
}
@MainActor
func registerStarPlanet(into factories: inout [String: PlanetFactory]) {
    factories["Star"] = { try StarPlanet() }
}

// MARK: - Twinkle star variant

private let twinkleCoreColors: [Float] = [
    1, 0.956862, 0.835294, 1,
    0.945098, 0.788235, 0.654902, 1,
    0.482352, 0.721568, 0.929411, 1,
    0.207843, 0.321568, 0.584313, 1,
]

private let twinkleSparkColors: [Float] = [
    1, 0.988235, 0.917647, 1,
    0.560784, 0.792156, 1, 1,
]

private func makeTwinkleStarConfig() -> PlanetConfig {
    let coreLayer = LayerDefinition(
        name: "TwinkleCore",
        shaderPath: "star/star.frag",
        uniforms: [
            "pixels": .float(140),
            "time_speed": .float(0.04),
            "time": .float(0),
            "rotation": .float(0),
            "colors": .buffer(twinkleCoreColors),
            "n_colors": .float(4),
            "should_dither": .float(1),
            "seed": .float(5.934),
            "size": .float(4.1),
            "OCTAVES": .float(4),
            "TILES": .float(1),
        ],
        colors: [ColorBinding(layer: "TwinkleCore", uniform: "colors", slots: 4)]
    )

let twinkleLayer = LayerDefinition(
        name: "TwinkleGlow",
        shaderPath: "star/twinkle.frag",
        uniforms: [
            "time_speed": .float(2.0),
            "time": .float(0),
            "spark_scale": .float(1.2),
            "spark_sharpness": .float(3.0),
            "flicker_strength": .float(0.7),
            "star_radius": .float(0.48),
            "branch_count": .float(4),
            "rotation_speed": .float(0.8),
            "halo_softness": .float(0.15),
            "colors": .buffer(twinkleSparkColors),
        ],
        colors: [ColorBinding(layer: "TwinkleGlow", uniform: "colors", slots: 2)]
    )

    let controls: [UniformControl] = [
        UniformControl(layer: "TwinkleCore", uniform: "time_speed", label: "核心速度", min: 0, max: 0.2, step: 0.005),
        UniformControl(layer: "TwinkleCore", uniform: "size", label: "噪声尺度", min: 1, max: 10, step: 0.1),
        UniformControl(layer: "TwinkleGlow", uniform: "time_speed", label: "闪烁速度", min: 0.2, max: 4, step: 0.05),
        UniformControl(layer: "TwinkleGlow", uniform: "flicker_strength", label: "闪烁强度", min: 0, max: 1, step: 0.05),
        UniformControl(layer: "TwinkleGlow", uniform: "spark_scale", label: "光芒长度", min: 0.6, max: 2.5, step: 0.05),
        UniformControl(layer: "TwinkleGlow", uniform: "spark_sharpness", label: "光芒锐度", min: 1, max: 6, step: 0.1),
        UniformControl(layer: "TwinkleGlow", uniform: "star_radius", label: "核心半径", min: 0.3, max: 0.6, step: 0.01),
        UniformControl(layer: "TwinkleGlow", uniform: "branch_count", label: "光芒数量", min: 2, max: 6, step: 1),
        UniformControl(layer: "TwinkleGlow", uniform: "rotation_speed", label: "旋转速度", min: 0, max: 2, step: 0.05),
        UniformControl(layer: "TwinkleGlow", uniform: "halo_softness", label: "光晕柔和度", min: 0.05, max: 0.3, step: 0.01),
    ]

    return PlanetConfig(
        id: "twinkle-star",
        label: "Twinkle Star",
        relativeScale: 2,
        guiZoom: 2,
        layers: [coreLayer, twinkleLayer],
        uniformControls: controls
    )
}

private let twinkleConfig = makeTwinkleStarConfig()

public final class TwinkleStarPlanet: PlanetBase, @unchecked Sendable {
    public init() throws {
        try super.init(config: twinkleConfig)
    }

    public override func setPixels(_ amount: Int) {
        let value = Float(amount)
        setFloat("TwinkleCore", "pixels", value)
        setFloat("TwinkleGlow", "pixels", value * 1.4)
    }

    public override func setSeed(_ seed: Int, rng: inout RandomStream) {
        let converted = Float(seed % 1000) / 100.0 + 1.0
        setFloat("TwinkleCore", "seed", converted)
        setFloat("TwinkleGlow", "seed", converted)
    }

    public override func setRotation(_ radians: Float) {
        setFloat("TwinkleCore", "rotation", radians)
    }

    public override func updateTime(_ t: Float) {
        setFloat("TwinkleCore", "time", t * multiplier(for: "TwinkleCore") * 0.01)
        setFloat("TwinkleGlow", "time", t)
    }

    public override func setCustomTime(_ t: Float) {
        setFloat("TwinkleCore", "time", t * multiplier(for: "TwinkleCore"))
        setFloat("TwinkleGlow", "time", t)
    }

    public override func setDither(_ enabled: Bool) {
        let value = enabled ? 1 : 0
        setFloat("TwinkleCore", "should_dither", Float(value))
    }

    public override func isDitherEnabled() -> Bool {
        getFloat("TwinkleCore", "should_dither") > 0.5
    }

    public override func randomizeColors(rng: inout RandomStream) -> [PixelColor] {
        var corePalette = generatePalette(
            rng: &rng,
            count: 4,
            hueDiff: randRange(&rng, min: 0.15, max: 0.3),
            saturation: 1.5
        )
        if corePalette.count < 4 {
            corePalette += Array(repeating: PixelColor(r: 1, g: 0.9, b: 0.6, a: 1), count: 4 - corePalette.count)
        }

        var gradient: [PixelColor] = []
        for i in 0..<4 {
            let mix = Float(i) / 4
            var col = corePalette[i].lightened(by: 0.4 * (1 - mix))
            col = col.darkened(by: mix * 0.3)
            gradient.append(col)
        }

        let sparkA = gradient.first ?? PixelColor(r: 1, g: 0.95, b: 0.8, a: 1)
        let sparkB = gradient[2].lightened(by: 0.3)

        var buffers: [PixelColor] = []
        buffers.append(contentsOf: gradient)
        buffers.append(contentsOf: [sparkA, sparkB])

        setColors(buffers)
        return buffers
    }
}

@MainActor
func registerTwinkleStarPlanet(into factories: inout [String: PlanetFactory]) {
    factories["Twinkle Star"] = { try TwinkleStarPlanet() }
}
