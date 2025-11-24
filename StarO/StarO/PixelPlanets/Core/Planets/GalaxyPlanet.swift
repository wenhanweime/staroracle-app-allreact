import Foundation
import simd

private let galaxyBaseColors: [Float] = [
    1, 1, 0.921569, 1,
    1, 0.913725, 0.552941, 1,
    0.709804, 0.878431, 0.4, 1,
    0.396078, 0.647059, 0.4, 1,
    0.223529, 0.364706, 0.392157, 1,
    0.196078, 0.223529, 0.301961, 1,
    0.196078, 0.160784, 0.278431, 1,
]

private func makeGalaxyConfig() -> PlanetConfig {
    let uniforms: [String: UniformValue] = [
        "pixels": .float(200),
        "rotation": .float(0.674),
        "time_speed": .float(1),
        "dither_size": .float(2),
        "should_dither": .float(1),
        "colors": .buffer(galaxyBaseColors),
        "n_colors": .float(6),
        "size": .float(7),
        "OCTAVES": .float(1),
        "seed": .float(5.881),
        "time": .float(0),
        "tilt": .float(3),
        "n_layers": .float(4),
        "layer_height": .float(0.4),
        "zoom": .float(1.375),
        "swirl": .float(-9),
    ]

    let controls: [UniformControl] = [
        UniformControl(layer: "Galaxy", uniform: "time_speed", label: "Time Speed", min: 0, max: 4, step: 0.05),
        UniformControl(layer: "Galaxy", uniform: "dither_size", label: "Dither Size", min: 0, max: 6, step: 0.1),
        UniformControl(layer: "Galaxy", uniform: "size", label: "Noise Scale", min: 1, max: 15, step: 0.1),
        UniformControl(layer: "Galaxy", uniform: "OCTAVES", label: "Octaves", min: 1, max: 6, step: 1),
        UniformControl(layer: "Galaxy", uniform: "tilt", label: "Tilt", min: 1, max: 6, step: 0.1),
        UniformControl(layer: "Galaxy", uniform: "n_layers", label: "Layer Count", min: 1, max: 8, step: 1),
        UniformControl(layer: "Galaxy", uniform: "layer_height", label: "Layer Height", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Galaxy", uniform: "zoom", label: "Zoom", min: 0.5, max: 3, step: 0.05),
        UniformControl(layer: "Galaxy", uniform: "swirl", label: "Swirl", min: -12, max: 12, step: 0.5),
    ]

    return PlanetConfig(
        id: "galaxy",
        label: "Galaxy",
        relativeScale: 1,
        guiZoom: 2.5,
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

private let galaxyConfig = makeGalaxyConfig()

public final class GalaxyPlanet: PlanetBase, @unchecked Sendable {
    public init() throws {
        try super.init(config: galaxyConfig)
    }

    public override func setPixels(_ amount: Int) {
        setFloat("Galaxy", "pixels", Float(amount))
    }

    public override func setLight(_ position: SIMD2<Float>) {
        // Galaxy shader does not use external light.
    }

    public override func setSeed(_ seed: Int, rng: inout RandomStream) {
        let converted = Float(seed % 1000) / 100.0 + 1.0
        setFloat("Galaxy", "seed", converted)
    }

    public override func setRotation(_ radians: Float) {
        setFloat("Galaxy", "rotation", radians)
    }

    public override func updateTime(_ t: Float) {
        setFloat("Galaxy", "time", t * multiplier(for: "Galaxy") * 0.04)
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
            hueDiff: randRange(&rng, min: 0.5, max: 0.8),
            saturation: 1.4
        )
        if palette.count < 6 {
            palette += Array(repeating: PixelColor(r: 0.8, g: 0.8, b: 0.5, a: 1), count: 6 - palette.count)
        }

        var colors: [PixelColor] = []
        for i in 0..<6 {
            var shade = palette[i % palette.count].darkened(by: Float(i) / 7)
            shade = shade.lightened(by: (1 - Float(i) / 6) * 0.6)
            colors.append(shade)
        }
        colors.append(colors.last ?? PixelColor(r: 1, g: 1, b: 1, a: 1))
        setColors(colors)
        return colors
    }
}

@MainActor
func registerGalaxyPlanet(into factories: inout [String: PlanetFactory]) {
    factories["Galaxy"] = { try GalaxyPlanet() }
}
