import Foundation
import simd

private let blackHoleCoreColors: [Float] = [
    0.152941, 0.152941, 0.211765, 1,
    1, 1, 0.921569, 1,
    0.929412, 0.482353, 0.223529, 1,
]

private let blackHoleDiskColors: [Float] = [
    1, 1, 0.921569, 1,
    1, 0.960784, 0.25098, 1,
    1, 0.721569, 0.290196, 1,
    0.929412, 0.482353, 0.223529, 1,
    0.741176, 0.25098, 0.207843, 1,
]

private func makeBlackHoleConfig() -> PlanetConfig {
    let coreUniforms: [String: UniformValue] = [
        "pixels": .float(100),
        "colors": .buffer(blackHoleCoreColors),
        "radius": .float(0.247),
        "light_width": .float(0.028),
    ]

    let diskUniforms: [String: UniformValue] = [
        "pixels": .float(300),
        "rotation": .float(0.766),
        "light_origin": .vec2(Vec2(0.607, 0.444)),
        "time_speed": .float(0.2),
        "disk_width": .float(0.065),
        "ring_perspective": .float(14),
        "should_dither": .float(1),
        "colors": .buffer(blackHoleDiskColors),
        "n_colors": .float(5),
        "size": .float(6.598),
        "OCTAVES": .float(3),
        "seed": .float(8.175),
        "time": .float(0),
    ]

    return PlanetConfig(
        id: "black-hole",
        label: "Black Hole",
        relativeScale: 2,
        guiZoom: 2,
        layers: [
            LayerDefinition(
                name: "BlackHole",
                shaderPath: "black-hole/core.frag",
                uniforms: coreUniforms,
                colors: [ColorBinding(layer: "BlackHole", uniform: "colors", slots: 3)]
            ),
            LayerDefinition(
                name: "Disk",
                shaderPath: "black-hole/ring.frag",
                uniforms: diskUniforms,
                colors: [ColorBinding(layer: "Disk", uniform: "colors", slots: 5)]
            ),
        ],
        uniformControls: [
            UniformControl(layer: "BlackHole", uniform: "radius", label: "Core Radius", min: 0.1, max: 0.5, step: 0.005),
            UniformControl(layer: "BlackHole", uniform: "light_width", label: "Core Light Width", min: 0, max: 0.2, step: 0.005),
            UniformControl(layer: "Disk", uniform: "time_speed", label: "Disk Time Speed", min: 0, max: 1, step: 0.01),
            UniformControl(layer: "Disk", uniform: "disk_width", label: "Disk Width", min: 0.01, max: 0.2, step: 0.005),
            UniformControl(layer: "Disk", uniform: "ring_perspective", label: "Ring Perspective", min: 1, max: 20, step: 0.2),
            UniformControl(layer: "Disk", uniform: "size", label: "Disk Noise Scale", min: 1, max: 15, step: 0.1),
            UniformControl(layer: "Disk", uniform: "OCTAVES", label: "Disk Octaves", min: 1, max: 6, step: 1),
            UniformControl(layer: "Disk", uniform: "n_colors", label: "Disk Colors", min: 3, max: 7, step: 1),
        ]
    )
}

private let blackHoleConfig = makeBlackHoleConfig()

public final class BlackHolePlanet: PlanetBase, @unchecked Sendable {
    public init() throws {
        try super.init(config: blackHoleConfig)
    }

    public override func setPixels(_ amount: Int) {
        let value = Float(amount)
        setFloat("BlackHole", "pixels", value)
        setFloat("Disk", "pixels", value * 3)
    }

    public override func setLight(_ position: SIMD2<Float>) {
        setVec2("Disk", "light_origin", position)
    }

    public override func setSeed(_ seed: Int, rng: inout RandomStream) {
        let converted = Float(seed % 1000) / 100
        setFloat("Disk", "seed", converted)
    }

    public override func setRotation(_ radians: Float) {
        setFloat("Disk", "rotation", radians + 0.7)
    }

    public override func updateTime(_ t: Float) {
        setFloat("Disk", "time", t * 314.15 * 0.004)
    }

    public override func setCustomTime(_ t: Float) {
        let speed = max(0.0001, getFloat("Disk", "time_speed"))
        setFloat("Disk", "time", t * 314.15 * speed * 0.5)
    }

    public override func setDither(_ enabled: Bool) {
        setFloat("Disk", "should_dither", enabled ? 1 : 0)
    }

    public override func isDitherEnabled() -> Bool {
        getFloat("Disk", "should_dither") > 0.5
    }

    public override func randomizeColors(rng: inout RandomStream) -> [PixelColor] {
        var palette = generatePalette(
            rng: &rng,
            count: 5 + randInt(&rng, maxExclusive: 2),
            hueDiff: randRange(&rng, min: 0.3, max: 0.5),
            saturation: 2.0
        )
        if palette.count < 5 {
            palette += Array(repeating: PixelColor(r: 1, g: 0.8, b: 0.3, a: 1), count: 5 - palette.count)
        }

        var diskColors: [PixelColor] = []
        for i in 0..<5 {
            var shade = palette[i % palette.count].darkened(by: (Float(i) / 5) * 0.7)
            shade = shade.lightened(by: (1 - Float(i) / 5) * 0.9)
            diskColors.append(shade)
        }

        let core = PixelColor(r: 0.152941, g: 0.152941, b: 0.211765, a: 1)
        let colors = [core, diskColors[0], diskColors[3]] + diskColors
        setColors(colors)
        return colors
    }
}

@MainActor
func registerBlackHolePlanet(into factories: inout [String: PlanetFactory]) {
    factories["Black Hole"] = { try BlackHolePlanet() }
}
