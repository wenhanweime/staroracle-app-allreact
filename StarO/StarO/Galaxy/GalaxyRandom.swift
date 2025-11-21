import Foundation

func seeded(_ seed: UInt64) -> () -> Double {
    var state = seed
    return {
        state &+= 0x6D2B79F5
        var result = state
        result = (result ^ (result >> 15)) &* (1 | state)
        result ^= result &+ ((result ^ (result >> 7)) &* (61 | result))
        return Double((result ^ (result >> 14)) & 0xFFFFFFFF) / Double(UInt32.max)
    }
}

struct SeededRandom {
    private var generator: () -> Double

    init(seed: UInt64) {
        self.generator = seeded(seed)
    }

    mutating func next() -> Double {
        generator()
    }

    mutating func next(in range: ClosedRange<Double>) -> Double {
        let value = generator()
        return range.lowerBound + (range.upperBound - range.lowerBound) * value
    }

    mutating func nextBool(probability: Double) -> Bool {
        generator() < max(0.0, min(1.0, probability))
    }
}

func galaxyDeterministicSeed(from string: String) -> UInt32 {
    var hash: UInt32 = 2166136261
    for scalar in string.unicodeScalars {
        hash ^= UInt32(scalar.value)
        hash &*= 16777619
    }
    return hash
}

func galaxyDeterministicPhase(from string: String) -> Double {
    Double(galaxyDeterministicSeed(from: string)) / Double(UInt32.max)
}

func galaxyNoise2D(_ x: Double, _ y: Double) -> Double {
    let t = sin(x * 12.9898 + y * 78.233) * 43758.5453123
    let value = t - floor(t)
    return value * 2.0 - 1.0
}

func clamp(_ value: Double, min lower: Double = 0.0, max upper: Double = 1.0) -> Double {
    return Swift.max(lower, Swift.min(upper, value))
}
