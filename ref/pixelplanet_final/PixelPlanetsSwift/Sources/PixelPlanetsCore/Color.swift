import Foundation
import simd

/// RGBA color representation with components in the range `[0, 1]`.
public struct Color: Equatable, Codable, Sendable {
    public var r: Float
    public var g: Float
    public var b: Float
    public var a: Float

    public init(r: Float, g: Float, b: Float, a: Float = 1) {
        self.r = Self.clamp01(r)
        self.g = Self.clamp01(g)
        self.b = Self.clamp01(b)
        self.a = Self.clamp01(a)
    }

    public init(_ vector: SIMD4<Float>) {
        self.init(r: vector.x, g: vector.y, b: vector.z, a: vector.w)
    }

    public var simd: SIMD4<Float> {
        SIMD4(r, g, b, a)
    }

    @inline(__always)
    private static func clamp01(_ value: Float) -> Float {
        max(0, min(1, value))
    }

    public func withAlpha(_ alpha: Float) -> Color {
        Color(r: r, g: g, b: b, a: alpha)
    }

    public func asArray() -> [Float] {
        [r, g, b, a]
    }
}

public extension Color {
    static func fromHex(_ hex: String) -> Color {
        let clean = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard let value = UInt32(clean, radix: 16) else {
            return Color(r: 0, g: 0, b: 0, a: 1)
        }
        if clean.count == 8 {
            return Color(
                r: Float((value >> 24) & 0xff) / 255,
                g: Float((value >> 16) & 0xff) / 255,
                b: Float((value >> 8) & 0xff) / 255,
                a: Float(value & 0xff) / 255
            )
        }
        return Color(
            r: Float((value >> 16) & 0xff) / 255,
            g: Float((value >> 8) & 0xff) / 255,
            b: Float(value & 0xff) / 255,
            a: 1
        )
    }
}

public struct HSV: Equatable, Sendable {
    public var h: Float
    public var s: Float
    public var v: Float
    public var a: Float

    public init(h: Float, s: Float, v: Float, a: Float = 1) {
        self.h = h
        self.s = s
        self.v = v
        self.a = a
    }
}

public extension Color {
    func toHSV() -> HSV {
        let maxComponent = max(r, g, b)
        let minComponent = min(r, g, b)
        let delta = maxComponent - minComponent

        var hue: Float = 0
        let saturation: Float = maxComponent == 0 ? 0 : delta / maxComponent
        let value = maxComponent

        if delta != 0 {
            if maxComponent == r {
                hue = (g - b) / delta + (g < b ? 6 : 0)
            } else if maxComponent == g {
                hue = (b - r) / delta + 2
            } else {
                hue = (r - g) / delta + 4
            }
            hue /= 6
        }

        return HSV(h: hue, s: saturation, v: value, a: a)
    }

    static func fromHSV(_ hsv: HSV) -> Color {
        func wrapHue(_ value: Float) -> Float {
            let wrapped = value.remainder(dividingBy: 1)
            return wrapped < 0 ? wrapped + 1 : wrapped
        }

        let h = wrapHue(hsv.h) * 6
        let i = floor(h)
        let f = h - i
        let p = hsv.v * (1 - hsv.s)
        let q = hsv.v * (1 - f * hsv.s)
        let t = hsv.v * (1 - (1 - f) * hsv.s)

        let mod = Int(i) % 6
        let (r, g, b): (Float, Float, Float)
        switch mod {
        case 0: (r, g, b) = (hsv.v, t, p)
        case 1: (r, g, b) = (q, hsv.v, p)
        case 2: (r, g, b) = (p, hsv.v, t)
        case 3: (r, g, b) = (p, q, hsv.v)
        case 4: (r, g, b) = (t, p, hsv.v)
        default: (r, g, b) = (hsv.v, p, q)
        }

        return Color(r: r, g: g, b: b, a: hsv.a)
    }
}

public extension Color {
    func darkened(by amount: Float) -> Color {
        let factor = max(0, min(1, 1 - amount))
        return Color(r: r * factor, g: g * factor, b: b * factor, a: a)
    }

    func lightened(by amount: Float) -> Color {
        let value = max(0, min(1, amount))
        return Color(
            r: r + (1 - r) * value,
            g: g + (1 - g) * value,
            b: b + (1 - b) * value,
            a: a
        )
    }

    func shiftedHue(by delta: Float) -> Color {
        let hsv = toHSV()
        return Color.fromHSV(HSV(h: hsv.h + delta, s: hsv.s, v: hsv.v, a: hsv.a))
    }
}
