import Foundation
import simd

private let asteroidBaseColors: [Float] = [
    0.639216, 0.654902, 0.760784, 1,
    0.298039, 0.407843, 0.521569, 1,
    0.227451, 0.247059, 0.368627, 1,
]

private func makeAsteroidConfig() -> PlanetConfig {
    let uniforms: [String: UniformValue] = [
        "pixels": .float(100),
        "rotation": .float(0),
        "light_origin": .vec2(Vec2(0, 0)),
        "time_speed": .float(0.4),
        "colors": .buffer(asteroidBaseColors),
        "size": .float(5.294),
        "octaves": .float(2),
        "seed": .float(1.567),
        "should_dither": .float(1),
    ]

    return PlanetConfig(
        id: "asteroid",
        label: "Asteroid",
        relativeScale: 1,
        guiZoom: 1,
        layers: [
            LayerDefinition(
                name: "Asteroid",
                shaderPath: "asteroid/asteroid.frag",
                uniforms: uniforms,
                colors: [ColorBinding(layer: "Asteroid", uniform: "colors", slots: 3)]
            ),
        ],
        uniformControls: [
            UniformControl(layer: "Asteroid", uniform: "time_speed", label: "Spin Speed", min: 0, max: 1, step: 0.01),
            UniformControl(layer: "Asteroid", uniform: "size", label: "Noise Scale", min: 1, max: 12, step: 0.1),
            UniformControl(layer: "Asteroid", uniform: "octaves", label: "Octaves", min: 1, max: 6, step: 1),
        ]
    )
}

private let asteroidConfig = makeAsteroidConfig()

public final class AsteroidPlanet: PlanetBase, @unchecked Sendable {
    public init() throws {
        try super.init(config: asteroidConfig)
    }

    public override func setPixels(_ amount: Int) {
        setFloat("Asteroid", "pixels", Float(amount))
    }

    public override func setLight(_ position: SIMD2<Float>) {
        setVec2("Asteroid", "light_origin", position)
    }

    public override func setSeed(_ seed: Int, rng: inout RandomStream) {
        let converted = Float(seed % 1000) / 100
        setFloat("Asteroid", "seed", converted)
    }

    public override func setRotation(_ radians: Float) {
        setFloat("Asteroid", "rotation", radians)
    }

    public override func updateTime(_ t: Float) { }

    public override func setCustomTime(_ t: Float) {
        setFloat("Asteroid", "rotation", t * Float.pi * 2)
    }

    public override func setDither(_ enabled: Bool) {
        setFloat("Asteroid", "should_dither", enabled ? 1 : 0)
    }

    public override func isDitherEnabled() -> Bool {
        getFloat("Asteroid", "should_dither") > 0.5
    }

    public override func randomizeColors(rng: inout RandomStream) -> [Color] {
        var palette = generatePalette(
            rng: &rng,
            count: 3 + randInt(&rng, maxExclusive: 2),
            hueDiff: randRange(&rng, min: 0.3, max: 0.6),
            saturation: 0.7
        )
        if palette.count < 3 {
            palette += Array(repeating: Color(r: 0.5, g: 0.5, b: 0.6, a: 1), count: 3 - palette.count)
        }

        var colors: [Color] = []
        for i in 0..<3 {
            let shaded = palette[i % palette.count]
                .darkened(by: Float(i) / 3)
                .lightened(by: (1 - Float(i) / 3) * 0.2)
            colors.append(shaded)
        }

        setColors(colors)
        return colors
    }
}

@MainActor
func registerAsteroidPlanet(into factories: inout [String: PlanetFactory]) {
    factories["Asteroid"] = { try AsteroidPlanet() }
}
