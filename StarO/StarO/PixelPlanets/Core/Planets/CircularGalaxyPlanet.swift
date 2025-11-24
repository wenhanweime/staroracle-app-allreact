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

    public override func randomizeColors(rng: inout RandomStream) -> [PixelColor] {
        var palette = generatePalette(
            rng: &rng,
            count: 6,
            hueDiff: randRange(&rng, min: 0.45, max: 0.75),
            saturation: 1.2
        )
        if palette.count < 6 {
            palette += Array(repeating: PixelColor(r: 0.9, g: 0.8, b: 0.6, a: 1), count: 6 - palette.count)
        }

        var colors: [PixelColor] = []
        for i in 0..<6 {
            var shade = palette[i % palette.count].darkened(by: Float(i) / 7)
            shade = shade.lightened(by: (1 - Float(i) / 6) * 0.55)
            colors.append(shade)
        }
        colors.append(colors.last ?? PixelColor(r: 1, g: 1, b: 1, a: 1))
        setColors(colors)
        return colors
    }
}

@MainActor
func registerCircularGalaxyPlanet(into factories: inout [String: PlanetFactory]) {
    factories["Galaxy Round"] = { try CircularGalaxyPlanet() }
}

// Twinkle Galaxy variant removed by product decision.
