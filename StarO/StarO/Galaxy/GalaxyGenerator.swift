import SwiftUI
import CoreGraphics
import Foundation
import simd
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct GalaxyStar: Identifiable {
    let id: String
    let band: Int
    let position: CGPoint      // Overscan canvas coordinates (CSS points)
    let size: CGFloat
    let baseColor: Color
    let litColor: Color
    let baseHex: String
    let displayHex: String
    let litHex: String
    let bandSize: CGSize
}

struct GalaxyBackgroundStar: Identifiable {
    let id: String
    let position: CGPoint
    let size: CGFloat
}

struct GalaxyFieldData {
    let rings: [[GalaxyStar]]
    let background: [GalaxyBackgroundStar]
    let bandSize: CGSize
}

private struct ArmInfo {
    let distance: Double
    let armIndex: Int
    let radius: Double
    let inArm: Bool
    let armWidth: Double
    let theta: Double
}

private struct ArmDensityProfile {
    let density: Double
    let size: Double
    let profile: Double
}

enum GalaxyGenerator {
    static func generateField(
        size: CGSize,
        params: GalaxyParams,
        palette: GalaxyPalette,
        litPalette: GalaxyPalette,
        structureColoring: Bool,
        scale: Double,
        deviceScale: Double,
        reduceMotion: Bool
    ) -> GalaxyFieldData {
        let width = Double(size.width)
        let height = Double(size.height)
        guard width > 0, height > 0 else {
            return GalaxyFieldData(rings: [], background: [], bandSize: .zero)
        }

        let dpr = deviceScale
        let scaleLocal = max(0.01, scale)
        let minOverscan = max(sqrt(2.0) + 0.1, (1.0 / scaleLocal) + 0.2)
        let overscan = max(1.0, minOverscan)

        let overscanWidth = width * overscan
        let overscanHeight = height * overscan
        let overscanCenter = CGPoint(x: overscanWidth / 2.0, y: overscanHeight / 2.0)

        let overscanWidthDev = overscanWidth * dpr
        let overscanHeightDev = overscanHeight * dpr
        let overscanCenterDev = CGPoint(x: overscanWidthDev / 2.0, y: overscanHeightDev / 2.0)

        let maxRadiusCSS = min(width, height) * 0.4
        let maxRadiusDev = min(width * dpr, height * dpr) * 0.4
        let radialDecay = makeRadialDecay(params: params)
        let rings = max(3, min(16, 10))
        let step = 1.0

        let rng = seeded(0xA17C9E3)
        var stars: [GalaxyStar] = []
        stars.reserveCapacity(1800)

        let paletteMap = buildPaletteMap(base: palette, lit: litPalette)
        let litCore = normalizeGalaxyHex(litPalette.core)

        var background: [GalaxyBackgroundStar] = []
        background.reserveCapacity(800)

        for x in stride(from: 0.0, to: overscanWidth, by: step) {
            for y in stride(from: 0.0, to: overscanHeight, by: step) {
                let dx = x - overscanCenter.x
                let dy = y - overscanCenter.y
                let radius = hypot(dx, dy)
                if radius < 3.0 { continue }

                let baseDecay = radialDecay(radius, maxRadiusCSS)
                let armInfo = getArmInfo(
                    x: x * dpr,
                    y: y * dpr,
                    centerX: overscanCenterDev.x,
                    centerY: overscanCenterDev.y,
                    maxRadius: maxRadiusDev,
                    params: params
                )
                let armProfile = calculateArmDensityProfile(armInfo: armInfo, params: params, random: rng)

                var density: Double
                var sizeValue: Double

                if radius < params.coreRadius {
                    let coreProfile = exp(-pow(radius / params.coreRadius, 1.5))
                    density = params.coreDensity * coreProfile * baseDecay
                    sizeValue = (params.coreSizeMin + rng() * (params.coreSizeMax - params.coreSizeMin)) * params.armStarSizeMultiplier
                } else {
                    let n = galaxyNoise2D(x * params.densityNoiseScale, y * params.densityNoiseScale)
                    var modulation = 1.0 - params.densityNoiseStrength * (0.5 * (1.0 - n))
                    if modulation < 0.0 { modulation = 0.0 }
                    density = armProfile.density * baseDecay * modulation
                    sizeValue = armProfile.size
                }

                density *= 0.8 + rng() * 0.4
                if rng() >= density { continue }

                var ox = x
                var oy = y

                if armProfile.profile > 0.001 {
                    let pitchAngle = atan(1.0 / params.spiralB)
                    let jitterAngle = armInfo.theta + pitchAngle + .pi / 2.0
                    let r1 = max(rng(), Double.leastNonzeroMagnitude)
                    let r2 = rng()
                    let gaussian = sqrt(-2.0 * log(r1)) * cos(2.0 * .pi * r2)
                    let chaos = 1.0 + params.jitterChaos * galaxyNoise2D(x * params.jitterChaosScale, y * params.jitterChaosScale)
                    let randomMix = 0.7 + 0.6 * rng()
                    let jitterAmount = params.jitterStrength * chaos * randomMix * armProfile.profile * gaussian
                    ox += (jitterAmount * cos(jitterAngle)) / dpr
                    oy += (jitterAmount * sin(jitterAngle)) / dpr
                }

                ox += (rng() - 0.5) * step
                oy += (rng() - 0.5) * step

                let dxDev = (ox * dpr) - overscanCenterDev.x
                let dyDev = (oy * dpr) - overscanCenterDev.y
                let radiusDev = hypot(dxDev, dyDev)
                let ringIndex = min(rings - 1, max(0, Int((radiusDev / maxRadiusDev) * Double(rings))))

                var baseHex = "#FFFFFF"
                var sizeFinal = sizeValue

                if structureColoring {
                    if radius < params.coreRadius {
                        baseHex = palette.core
                    } else {
                        let aw = armInfo.armWidth / dpr
                        let distance = armInfo.distance / dpr
                        let dustOffset = 0.35 * aw
                        let dustHalf = 0.10 * aw * 0.5
                        let noiseLocal = galaxyNoise2D(x * 0.05, y * 0.05)
                        let inDust = armInfo.inArm && abs(distance - dustOffset) <= dustHalf
                        let ridgeThreshold = 0.6
                        let mainThreshold = 0.45
                        let edgeThreshold = 0.25

                        if inDust || noiseLocal < -0.2 {
                            baseHex = palette.dust
                        } else if armProfile.profile > ridgeThreshold {
                            baseHex = palette.ridge
                        } else if armProfile.profile > mainThreshold {
                            let nearBoost = armProfile.profile > 0.65 ? 0.12 : (armProfile.profile > 0.55 ? 0.03 : -0.12)
                            let baseShare = min(0.8, max(0.0, 0.25 + nearBoost))
                            let r01 = (galaxyNoise2D(x * 0.017 - 19.3, y * 0.017 + 23.1) + 1.0) * 0.5
                            let knot1 = galaxyNoise2D(x * 0.03 + 11.7, y * 0.03 - 7.9)
                            let knot2 = galaxyNoise2D(x * 0.09 - 3.1, y * 0.09 + 5.3)
                            let isHII = (r01 < baseShare) || (knot1 > 0.65 && knot2 > 0.30)
                            if isHII {
                                baseHex = palette.hii
                                sizeFinal *= 1.35
                            } else {
                                baseHex = palette.armBright
                            }
                        } else if armProfile.profile > edgeThreshold {
                            baseHex = palette.armEdge
                        } else {
                            baseHex = palette.outer
                        }
                    }
                }

                let structuralHex = normalizeGalaxyHex(baseHex)
                var displayHex = structuralHex
                if params.colorNoiseScale > 0.0,
                   (abs(params.colorJitterHue) > 0.0001 ||
                    abs(params.colorJitterSat) > 0.0001 ||
                    abs(params.colorJitterLight) > 0.0001) {
                    displayHex = jitteredHexColor(
                        from: structuralHex,
                        x: ox,
                        y: oy,
                        params: params
                    )
                }

                let mappedLit = paletteMap[structuralHex] ?? litCore
                let starID = "s-\(stars.count)"

                let star = GalaxyStar(
                    id: starID,
                    band: ringIndex,
                    position: CGPoint(x: ox, y: oy),
                    size: CGFloat(sizeFinal),
                    baseColor: Color(galaxyHex: displayHex),
                    litColor: Color(galaxyHex: mappedLit),
                    baseHex: structuralHex,
                    displayHex: displayHex,
                    litHex: mappedLit,
                    bandSize: CGSize(width: overscanWidth, height: overscanHeight)
                )
                stars.append(star)
            }
        }

        let backgroundSeed: UInt64 = 0x0BADC0DE
        let backgroundRng = seeded(backgroundSeed)
        let reducedMotionLocal = reduceMotion
        let backgroundCount = Int((width * height) * params.backgroundDensity * (reducedMotionLocal ? 0.6 : 1.0))

        for idx in 0..<backgroundCount {
            let x = backgroundRng() * width
            let y = backgroundRng() * height
            let r1 = backgroundRng()
            let r2 = backgroundRng()
            var sizeValue = r1 < 0.85 ? 0.8 : (r2 < 0.9 ? 1.2 : params.backgroundSizeVariation)
            sizeValue *= params.backgroundStarSizeMultiplier
            background.append(GalaxyBackgroundStar(
                id: "bg-\(idx)",
                position: CGPoint(x: x, y: y),
                size: CGFloat(sizeValue)
            ))
        }

        let grouped = Dictionary(grouping: stars, by: { $0.band })
        let ringsOrdered = (0..<rings).map { grouped[$0] ?? [] }

        return GalaxyFieldData(
            rings: ringsOrdered,
            background: background,
            bandSize: CGSize(width: overscanWidth, height: overscanHeight)
        )
    }
}

// MARK: - Helper Functions

private func jitteredHexColor(from baseHex: String, x: Double, y: Double, params: GalaxyParams) -> String {
    let hsl = galaxyHexToHSL(baseHex)
    let scale = params.colorNoiseScale
    let nh = galaxyNoise2D(x * scale, y * scale)
    let ns = galaxyNoise2D(x * scale + 31.7, y * scale + 11.3)
    let nl = galaxyNoise2D(x * scale + 77.1, y * scale + 59.9)

    var hue = hsl.h + nh * params.colorJitterHue
    while hue < 0 { hue += 360.0 }
    while hue >= 360.0 { hue -= 360.0 }

    let sat = clamp(hsl.s + ns * params.colorJitterSat, min: 0.0, max: 1.0)
    let light = clamp(hsl.l + nl * params.colorJitterLight, min: 0.0, max: 1.0)

    return hslToHexString(h: hue, s: sat, l: light)
}

private func hslToHexString(h: Double, s: Double, l: Double) -> String {
    let hh = h / 360.0
    let q = l < 0.5 ? l * (1 + s) : l + s - l * s
    let p = 2 * l - q

    let r = hueToRGBComponent(p: p, q: q, t: hh + 1.0 / 3.0)
    let g = hueToRGBComponent(p: p, q: q, t: hh)
    let b = hueToRGBComponent(p: p, q: q, t: hh - 1.0 / 3.0)

    let ri = Int(round(r * 255.0))
    let gi = Int(round(g * 255.0))
    let bi = Int(round(b * 255.0))

    return String(format: "#%02X%02X%02X", ri, gi, bi)
}

private func hueToRGBComponent(p: Double, q: Double, t: Double) -> Double {
    var value = t
    if value < 0 { value += 1 }
    if value > 1 { value -= 1 }
    if value < 1 / 6 { return p + (q - p) * 6 * value }
    if value < 1 / 2 { return q }
    if value < 2 / 3 { return p + (q - p) * (2 / 3 - value) * 6 }
    return p
}

private func makeRadialDecay(params: GalaxyParams) -> (Double, Double) -> Double {
    return { radius, maxRadius in
        let base = exp(-radius * params.radialDecay)
        let fade = getFadeFactor(radius: radius, maxRadius: maxRadius, params: params)
        let maintain = params.outerDensityMaintain
        return max(base * fade, maintain * fade)
    }
}

private func getFadeFactor(radius: Double, maxRadius: Double, params: GalaxyParams) -> Double {
    let fadeStart = maxRadius * params.fadeStartRadius
    let fadeEnd = maxRadius * params.fadeEndRadius
    if radius < fadeStart { return 1.0 }
    if radius > fadeEnd { return 0.0 }
    let progress = (radius - fadeStart) / (fadeEnd - fadeStart)
    return 0.5 * (1.0 + cos(progress * .pi))
}

private func getArmWidth(radius: Double, maxRadius: Double, params: GalaxyParams) -> Double {
    let progress = min(radius / (maxRadius * 0.8), 1.0)
    let scale = params.armWidthScale
    let inner = params.armWidthInner * scale
    let outer = params.armWidthOuter * scale
    return inner + (outer - inner) * pow(progress, params.armWidthGrowth)
}

private func spiralTheta(radius: Double, params: GalaxyParams, armOffset: Double) -> Double {
    let value = log(max(radius, params.spiralA) / params.spiralA) / params.spiralB
    return armOffset - value
}

private func getArmPositions(radius: Double, centerX: Double, centerY: Double, params: GalaxyParams) -> [simd_double3] {
    guard radius >= 0 else { return [] }
    var positions: [simd_double3] = []
    for arm in 0..<params.armCount {
        let armOffset = (Double(arm) * 2.0 * .pi) / Double(params.armCount)
        let theta = spiralTheta(radius: radius, params: params, armOffset: armOffset)
        let x = centerX + radius * cos(theta)
        let y = centerY + radius * sin(theta)
        positions.append(simd_double3(x, y, theta))
    }
    return positions
}

private func getArmInfo(
    x: Double,
    y: Double,
    centerX: Double,
    centerY: Double,
    maxRadius: Double,
    params: GalaxyParams
) -> ArmInfo {
    let dx = x - centerX
    let dy = y - centerY
    let radius = hypot(dx, dy)
    if radius < 3.0 {
        return ArmInfo(distance: 0, armIndex: 0, radius: radius, inArm: true, armWidth: 0, theta: 0)
    }
    let positions = getArmPositions(radius: radius, centerX: centerX, centerY: centerY, params: params)
    var minDistance = Double.infinity
    var nearestIndex = 0
    var nearestTheta = 0.0

    for (index, entry) in positions.enumerated() {
        let px = entry.x
        let py = entry.y
        let theta = entry.z
        let distance = hypot(x - px, y - py)
        if distance < minDistance {
            minDistance = distance
            nearestIndex = index
            nearestTheta = theta
        }
    }
    let armWidth = getArmWidth(radius: radius, maxRadius: maxRadius, params: params)
    let inArm = minDistance < armWidth
    return ArmInfo(distance: minDistance, armIndex: nearestIndex, radius: radius, inArm: inArm, armWidth: armWidth, theta: nearestTheta)
}

private func calculateArmDensityProfile(armInfo: ArmInfo, params: GalaxyParams, random: @escaping () -> Double) -> ArmDensityProfile {
    let profile = exp(-0.5 * pow(armInfo.distance / (armInfo.armWidth / params.armTransitionSoftness), 2.0))
    let totalDensity = params.interArmDensity + params.armDensity * profile
    var sizeValue: Double
    if profile > 0.1 {
        sizeValue = params.armBaseSizeMin + (params.armBaseSizeMax - params.armBaseSizeMin) * profile
        if profile > 0.7 && random() < params.armHighlightProb {
            sizeValue = params.armHighlightSize
        }
        sizeValue *= params.armStarSizeMultiplier
    } else {
        sizeValue = params.interArmSizeMin + (params.interArmSizeMax - params.interArmSizeMin) * random()
        sizeValue *= params.interArmStarSizeMultiplier
    }
    return ArmDensityProfile(density: totalDensity, size: sizeValue, profile: profile)
}

private func buildPaletteMap(base: GalaxyPalette, lit: GalaxyPalette) -> [String: String] {
    let entries: [(String, String)] = [
        (base.core, lit.core),
        (base.ridge, lit.ridge),
        (base.armBright, lit.armBright),
        (base.armEdge, lit.armEdge),
        (base.hii, lit.hii),
        (base.dust, lit.dust),
        (base.outer, lit.outer)
    ]
    var map: [String: String] = [:]
    for (baseHex, litHex) in entries {
        let normalizedBase = normalizeGalaxyHex(baseHex)
        let normalizedLit = normalizeGalaxyHex(litHex)
        map[normalizedBase] = normalizedLit
    }
    return map
}
