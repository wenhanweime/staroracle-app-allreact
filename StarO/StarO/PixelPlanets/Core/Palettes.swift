import Foundation

public func randRange(_ rng: inout RandomStream, min: Float, max: Float) -> Float {
    rng.nextRange(min: min, max: max)
}

public func randInt(_ rng: inout RandomStream, maxExclusive: Int) -> Int {
    rng.nextInt(maxExclusive)
}

public func generatePalette(
    rng: inout RandomStream,
    count: Int,
    hueDiff: Float = 0.9,
    saturation: Float = 0.5
) -> [PixelColor] {
    let a: [Float] = [0.5, 0.5, 0.5]
    let b = a.map { $0 * saturation }
    let c = [
        randRange(&rng, min: 0.5, max: 1.5),
        randRange(&rng, min: 0.5, max: 1.5),
        randRange(&rng, min: 0.5, max: 1.5),
    ].map { $0 * hueDiff }
    let d = [
        randRange(&rng, min: 0, max: 1) * randRange(&rng, min: 1, max: 3),
        randRange(&rng, min: 0, max: 1) * randRange(&rng, min: 1, max: 3),
        randRange(&rng, min: 0, max: 1) * randRange(&rng, min: 1, max: 3),
    ]

    let denominator = max(1, count - 1)
    return (0..<count).map { index in
        let t = Float(index) / Float(denominator)
        let x = cos(Double.pi * 2 * Double(c[0] * t + d[0]))
        let y = cos(Double.pi * 2 * Double(c[1] * t + d[1]))
        let z = cos(Double.pi * 2 * Double(c[2] * t + d[2]))
        return PixelColor(
            r: a[0] + b[0] * Float(x),
            g: a[1] + b[1] * Float(y),
            b: a[2] + b[2] * Float(z),
            a: 1
        )
    }
}
