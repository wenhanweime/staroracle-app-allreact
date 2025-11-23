import Foundation

/// Deterministic pseudo random number generator that mirrors the PCG
/// implementation used by the original Godot shaders and the React port.
public struct RandomStream: Sendable {
    private static let defaultState: UInt64 = 0x853c49e6748fea9b
    private static let multiplier: UInt64 = 6364136223846793005
    private static let increment: UInt64 = 1442695040888963407
    private static let mask: UInt64 = UInt64.max
    private static let scale: Float = 1.0 / 4294967296.0 // 1 / 2^32

    private var state: UInt64

    public init(seed: UInt64) {
        let sanitized = seed & Self.mask
        self.state = sanitized == 0 ? Self.defaultState : sanitized
    }

    public mutating func nextUInt32() -> UInt32 {
        state = (state &* Self.multiplier &+ Self.increment) & Self.mask
        let shifted = ((state >> 18) ^ state) >> 27
        let rot = UInt32(state >> 59)
        let xorshifted = UInt32(truncatingIfNeeded: shifted)
        let shift = Int(rot & 31)
        let complement = (32 - shift) & 31
        return (xorshifted >> shift) | (xorshifted << complement)
    }

    public mutating func next() -> Float {
        let value = nextUInt32()
        return Float(value) * Self.scale
    }

    public mutating func nextRange(min: Float, max: Float) -> Float {
        next() * (max - min) + min
    }

    public mutating func nextInt(_ upperBound: Int) -> Int {
        precondition(upperBound > 0, "Upper bound must be positive")
        return Int(next() * Float(upperBound))
    }
}

public extension RandomStream {
    init(seed: Int) {
        self.init(seed: UInt64(UInt32(bitPattern: Int32(truncatingIfNeeded: seed))))
    }

    mutating func nextBool() -> Bool {
        next() >= 0.5
    }
}
