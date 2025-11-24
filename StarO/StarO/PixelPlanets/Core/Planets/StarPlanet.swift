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
        let converted = Float(seed % 1000) / 100
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

// Twinkle star variant removed by product decision.
