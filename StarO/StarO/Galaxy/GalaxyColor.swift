import SwiftUI

func normalizeGalaxyHex(_ hex: String) -> String {
    var value = hex.trimmingCharacters(in: .whitespacesAndNewlines)
    if !value.hasPrefix("#") {
        value = "#\(value)"
    }
    if value.count == 4 {
        let chars = Array(value)
        value = "#\(chars[1])\(chars[1])\(chars[2])\(chars[2])\(chars[3])\(chars[3])"
    }
    if value.count != 7 {
        return "#FFFFFF"
    }
    return value.uppercased()
}

func galaxyRGBComponents(from hex: String) -> (r: Double, g: Double, b: Double) {
    let normalized = normalizeGalaxyHex(hex)
    let chars = Array(normalized.dropFirst())
    guard chars.count == 6 else {
        return (255, 255, 255)
    }
    let rString = String(chars[0...1])
    let gString = String(chars[2...3])
    let bString = String(chars[4...5])
    let r = Double(Int(rString, radix: 16) ?? 255)
    let g = Double(Int(gString, radix: 16) ?? 255)
    let b = Double(Int(bString, radix: 16) ?? 255)
    return (r, g, b)
}

extension Color {
    init(galaxyHex hex: String) {
        let comps = galaxyRGBComponents(from: hex)
        self = Color(red: comps.r / 255.0, green: comps.g / 255.0, blue: comps.b / 255.0)
    }
}

func desaturatedColor(from hex: String, factor: Double) -> Color {
    let clamped = max(0.0, min(1.0, factor))
    let comps = galaxyRGBComponents(from: hex)
    let gray = (comps.r + comps.g + comps.b) / 3.0
    let newR = comps.r + (gray - comps.r) * clamped
    let newG = comps.g + (gray - comps.g) * clamped
    let newB = comps.b + (gray - comps.b) * clamped
    return Color(red: newR / 255.0, green: newG / 255.0, blue: newB / 255.0)
}

func galaxyBlendHex(_ lhs: String, _ rhs: String, ratio: Double) -> Color {
    let mix = clamp(ratio, min: 0.0, max: 1.0)
    let left = galaxyRGBComponents(from: lhs)
    let right = galaxyRGBComponents(from: rhs)
    let r = left.r + (right.r - left.r) * mix
    let g = left.g + (right.g - left.g) * mix
    let b = left.b + (right.b - left.b) * mix
    return Color(red: r / 255.0, green: g / 255.0, blue: b / 255.0)
}

struct GalaxyHSL {
    var h: Double
    var s: Double
    var l: Double
}

func galaxyHexToHSL(_ hex: String) -> GalaxyHSL {
    let comps = galaxyRGBComponents(from: hex)
    let r = comps.r / 255.0
    let g = comps.g / 255.0
    let b = comps.b / 255.0
    let maxVal = max(r, g, b)
    let minVal = min(r, g, b)
    var h: Double = 0
    var s: Double = 0
    let l = (maxVal + minVal) * 0.5
    if maxVal != minVal {
        let d = maxVal - minVal
        s = l > 0.5 ? d / (2.0 - maxVal - minVal) : d / (maxVal + minVal)
        if maxVal == r {
            h = (g - b) / d + (g < b ? 6.0 : 0.0)
        } else if maxVal == g {
            h = (b - r) / d + 2.0
        } else {
            h = (r - g) / d + 4.0
        }
        h /= 6.0
    }
    return GalaxyHSL(h: h * 360.0, s: s, l: l)
}

private func hueToRGB(_ p: Double, _ q: Double, _ t: Double) -> Double {
    var tVar = t
    if tVar < 0 { tVar += 1 }
    if tVar > 1 { tVar -= 1 }
    if tVar < 1/6 { return p + (q - p) * 6 * tVar }
    if tVar < 1/2 { return q }
    if tVar < 2/3 { return p + (q - p) * (2/3 - tVar) * 6 }
    return p
}

func galaxyHSLToColor(_ hsl: GalaxyHSL) -> Color {
    let h = hsl.h / 360.0
    let s = clamp(hsl.s)
    let l = clamp(hsl.l)
    if s == 0 {
        return Color(red: l, green: l, blue: l)
    }
    let q = l < 0.5 ? l * (1 + s) : l + s - l * s
    let p = 2 * l - q
    let r = hueToRGB(p, q, h + 1/3)
    let g = hueToRGB(p, q, h)
    let b = hueToRGB(p, q, h - 1/3)
    return Color(red: r, green: g, blue: b)
}

func galaxyDesaturatedColor(from hex: String, saturationScale: Double, lightnessAdjust: Double) -> Color {
    var hsl = galaxyHexToHSL(hex)
    hsl.s = clamp(hsl.s * saturationScale)
    hsl.l = clamp(hsl.l + lightnessAdjust)
    return galaxyHSLToColor(hsl)
}
