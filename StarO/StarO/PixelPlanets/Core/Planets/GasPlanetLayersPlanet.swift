import Foundation
import simd

private let gasPlanet2Colors: [Float] = [
    0.211765, 0.168627, 0.262745, 1,
    0.380392, 0.25098, 0.352941, 1,
    0.533333, 0.352941, 0.439216, 1,
]

private let gasPlanet2DarkColors: [Float] = [
    0.160784, 0.129412, 0.2, 1,
    0.286275, 0.192157, 0.270588, 1,
    0.4, 0.270588, 0.337255, 1,
]

private let gasPlanet2RingColors: [Float] = [
    0.321569, 0.27451, 0.258824, 1,
    0.431373, 0.384314, 0.341176, 1,
    0.572549, 0.52549, 0.45098, 1,
    0.690196, 0.635294, 0.541176, 1,
]

private func makeGasPlanet2Config() -> PlanetConfig {
    let gasUniforms: [String: UniformValue] = [
        "pixels": .float(100),
        "rotation": .float(0),
        "light_origin": .vec2(Vec2(0.39, 0.39)),
        "time_speed": .float(0.2),
        "dither_size": .float(2),
        "should_dither": .float(1),
        "light_border_1": .float(0.4),
        "light_border_2": .float(0.6),
        "colors": .buffer(gasPlanet2Colors),
        "dark_colors": .buffer(gasPlanet2DarkColors),
        "size": .float(9),
        "octaves": .float(3),
        "seed": .float(4.123),
        "time": .float(0),
    ]

    let ringUniforms: [String: UniformValue] = [
        "pixels": .float(300),
        "rotation": .float(-0.4),
        "light_origin": .vec2(Vec2(0.39, 0.39)),
        "time_speed": .float(0.2),
        "dither_size": .float(2),
        "should_dither": .float(1),
        "light_border_1": .float(0.4),
        "light_border_2": .float(0.6),
        "colors": .buffer(gasPlanet2RingColors),
        "size": .float(6),
        "octaves": .float(3),
        "seed": .float(8.456),
        "time": .float(0),
    ]

    return PlanetConfig(
        id: "gas-planet-layers",
        label: "Gas giant 2",
        relativeScale: 1,
        guiZoom: 1,
        layers: [
            LayerDefinition(
                name: "Gas",
                shaderPath: "gas-planet-layers/layers.frag",
                uniforms: gasUniforms,
                colors: [
                    ColorBinding(layer: "Gas", uniform: "colors", slots: 3),
                    ColorBinding(layer: "Gas", uniform: "dark_colors", slots: 3)
                ]
            ),
            LayerDefinition(
                name: "Ring",
                shaderPath: "gas-planet-layers/ring.frag",
                uniforms: ringUniforms,
                colors: [ColorBinding(layer: "Ring", uniform: "colors", slots: 4)]
            ),
        ],
        uniformControls: [
            UniformControl(layer: "Gas", uniform: "time_speed", label: "Spin Speed", min: 0, max: 1, step: 0.01),
            UniformControl(layer: "Gas", uniform: "dither_size", label: "Dither Size", min: 0, max: 6, step: 0.1),
            UniformControl(layer: "Gas", uniform: "light_border_1", label: "Light Border 1", min: 0, max: 1, step: 0.01),
            UniformControl(layer: "Gas", uniform: "light_border_2", label: "Light Border 2", min: 0, max: 1, step: 0.01),
            UniformControl(layer: "Gas", uniform: "size", label: "Noise Scale", min: 1, max: 15, step: 0.1),
            UniformControl(layer: "Gas", uniform: "octaves", label: "Octaves", min: 1, max: 6, step: 1),
            UniformControl(layer: "Ring", uniform: "rotation", label: "Ring Rotation", min: -1, max: 1, step: 0.05),
            UniformControl(layer: "Ring", uniform: "size", label: "Ring Noise Scale", min: 1, max: 15, step: 0.1),
        ]
    )
}

private let gasPlanet2Config = makeGasPlanet2Config()

public final class GasPlanetLayersPlanet: PlanetBase, @unchecked Sendable {
    public init() throws {
        try super.init(config: gasPlanet2Config)
    }

    public override func setPixels(_ amount: Int) {
        let value = Float(amount)
        setFloat("Gas", "pixels", value)
        setFloat("Ring", "pixels", value * 3)
    }

    public override func setLight(_ position: SIMD2<Float>) {
        setVec2("Gas", "light_origin", position)
        setVec2("Ring", "light_origin", position)
    }

    public override func setSeed(_ seed: Int, rng: inout RandomStream) {
        let converted = Float(seed % 1000) / 100
        setFloat("Gas", "seed", converted)
        setFloat("Ring", "seed", converted + 12.34)
    }

    public override func setRotation(_ radians: Float) {
        setFloat("Gas", "rotation", radians)
        setFloat("Ring", "rotation", radians - 0.4)
    }

    public override func updateTime(_ t: Float) {
        setFloat("Gas", "time", t * multiplier(for: "Gas") * 0.02)
        setFloat("Ring", "time", t * multiplier(for: "Ring") * 0.02)
    }

    public override func setCustomTime(_ t: Float) {
        let speed = max(0.0001, getFloat("Gas", "time_speed"))
        setFloat("Gas", "time", t * Float.pi * 2 * speed)
        setFloat("Ring", "time", t * Float.pi * 2 * speed * 0.8)
    }

    public override func setDither(_ enabled: Bool) {
        let value = enabled ? 1 : 0
        setFloat("Gas", "should_dither", Float(value))
        setFloat("Ring", "should_dither", Float(value))
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
            palette += Array(repeating: PixelColor(r: 0.5, g: 0.4, b: 0.6, a: 1), count: 3 - palette.count)
        }

        var lightColors: [PixelColor] = []
        var darkColors: [PixelColor] = []

        for i in 0..<3 {
            let base = palette[i]
            lightColors.append(base.lightened(by: 0.1))
            darkColors.append(base.darkened(by: 0.3))
        }

        var ringColors: [PixelColor] = []
        for i in 0..<4 {
            let base = palette[i % 3]
            ringColors.append(base.lightened(by: Float(i) * 0.1))
        }

        let allColors = lightColors + darkColors + ringColors
        setColors(allColors)
        return allColors
    }
}

@MainActor
func registerGasPlanetLayersPlanet(into factories: inout [String: PlanetFactory]) {
    factories["Gas giant 2"] = { try GasPlanetLayersPlanet() }
}
