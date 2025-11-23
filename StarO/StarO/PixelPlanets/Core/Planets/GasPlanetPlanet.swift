import Foundation
import simd

private let gasPlanet1Colors: [Float] = [
    0.929412, 0.921569, 0.792157, 1,
    0.831373, 0.792157, 0.670588, 1,
    0.690196, 0.635294, 0.541176, 1,
]

private let gasPlanet1DarkColors: [Float] = [
    0.572549, 0.52549, 0.45098, 1,
    0.431373, 0.384314, 0.341176, 1,
    0.321569, 0.27451, 0.258824, 1,
]

private func makeGasPlanet1Config() -> PlanetConfig {
    let uniforms: [String: UniformValue] = [
        "pixels": .float(100),
        "rotation": .float(0),
        "light_origin": .vec2(Vec2(0.39, 0.39)),
        "time_speed": .float(0.2),
        "dither_size": .float(2),
        "should_dither": .float(1),
        "light_border_1": .float(0.4),
        "light_border_2": .float(0.6),
        "colors": .buffer(gasPlanet1Colors),
        "dark_colors": .buffer(gasPlanet1DarkColors),
        "size": .float(9),
        "octaves": .float(3),
        "seed": .float(4.123),
        "time": .float(0),
    ]

    return PlanetConfig(
        id: "gas-planet",
        label: "Gas giant 1",
        relativeScale: 1,
        guiZoom: 1,
        layers: [
            LayerDefinition(
                name: "Gas",
                shaderPath: "gas-planet-layers/layers.frag",
                uniforms: uniforms,
                colors: [
                    ColorBinding(layer: "Gas", uniform: "colors", slots: 3),
                    ColorBinding(layer: "Gas", uniform: "dark_colors", slots: 3)
                ]
            ),
        ],
        uniformControls: [
            UniformControl(layer: "Gas", uniform: "time_speed", label: "Spin Speed", min: 0, max: 1, step: 0.01),
            UniformControl(layer: "Gas", uniform: "dither_size", label: "Dither Size", min: 0, max: 6, step: 0.1),
            UniformControl(layer: "Gas", uniform: "light_border_1", label: "Light Border 1", min: 0, max: 1, step: 0.01),
            UniformControl(layer: "Gas", uniform: "light_border_2", label: "Light Border 2", min: 0, max: 1, step: 0.01),
            UniformControl(layer: "Gas", uniform: "size", label: "Noise Scale", min: 1, max: 15, step: 0.1),
            UniformControl(layer: "Gas", uniform: "octaves", label: "Octaves", min: 1, max: 6, step: 1),
        ]
    )
}

private let gasPlanet1Config = makeGasPlanet1Config()

public final class GasPlanetPlanet: PlanetBase, @unchecked Sendable {
    public init() throws {
        try super.init(config: gasPlanet1Config)
    }

    public override func setPixels(_ amount: Int) {
        setFloat("Gas", "pixels", Float(amount))
    }

    public override func setLight(_ position: SIMD2<Float>) {
        setVec2("Gas", "light_origin", position)
    }

    public override func setSeed(_ seed: Int, rng: inout RandomStream) {
        let converted = Float(seed % 1000) / 100
        setFloat("Gas", "seed", converted)
    }

    public override func setRotation(_ radians: Float) {
        setFloat("Gas", "rotation", radians)
    }

    public override func updateTime(_ t: Float) {
        setFloat("Gas", "time", t * multiplier(for: "Gas") * 0.02)
    }

    public override func setCustomTime(_ t: Float) {
        let speed = max(0.0001, getFloat("Gas", "time_speed"))
        setFloat("Gas", "time", t * Float.pi * 2 * speed)
    }

    public override func setDither(_ enabled: Bool) {
        setFloat("Gas", "should_dither", enabled ? 1 : 0)
    }

    public override func isDitherEnabled() -> Bool {
        getFloat("Gas", "should_dither") > 0.5
    }

    public override func randomizeColors(rng: inout RandomStream) -> [PixelColor] {
        var palette = generatePalette(
            rng: &rng,
            count: 3,
            hueDiff: randRange(&rng, min: 0.2, max: 0.5),
            saturation: 0.6
        )
        if palette.count < 3 {
            palette += Array(repeating: PixelColor(r: 0.8, g: 0.8, b: 0.7, a: 1), count: 3 - palette.count)
        }

        var lightColors: [PixelColor] = []
        var darkColors: [PixelColor] = []

        for i in 0..<3 {
            let base = palette[i]
            lightColors.append(base.lightened(by: 0.1))
            darkColors.append(base.darkened(by: 0.3))
        }

        let allColors = lightColors + darkColors
        setColors(allColors)
        return allColors
    }
}

@MainActor
func registerGasPlanetPlanet(into factories: inout [String: PlanetFactory]) {
    factories["Gas giant 1"] = { try GasPlanetPlanet() }
}
