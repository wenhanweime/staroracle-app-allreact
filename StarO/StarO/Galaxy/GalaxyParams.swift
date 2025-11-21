import SwiftUI

import StarOracleCore

struct GalaxyParams: Equatable {
    var coreDensity: Double
    var coreRadius: Double
    var coreSizeMin: Double
    var coreSizeMax: Double
    var armCount: Int
    var armDensity: Double
    var armBaseSizeMin: Double
    var armBaseSizeMax: Double
    var armHighlightSize: Double
    var armHighlightProb: Double
    var spiralA: Double
    var spiralB: Double
    var armWidthInner: Double
    var armWidthOuter: Double
    var armWidthGrowth: Double
    var armWidthScale: Double
    var armTransitionSoftness: Double
    var fadeStartRadius: Double
    var fadeEndRadius: Double
    var outerDensityMaintain: Double
    var interArmDensity: Double
    var interArmSizeMin: Double
    var interArmSizeMax: Double
    var radialDecay: Double
    var backgroundDensity: Double
    var backgroundSizeVariation: Double
    var jitterStrength: Double
    var densityNoiseScale: Double
    var densityNoiseStrength: Double
    var jitterChaos: Double
    var jitterChaosScale: Double
    var armStarSizeMultiplier: Double
    var interArmStarSizeMultiplier: Double
    var backgroundStarSizeMultiplier: Double
    var galaxyScale: Double
    var colorJitterHue: Double
    var colorJitterSat: Double
    var colorJitterLight: Double
    var colorNoiseScale: Double
}

struct GalaxyPalette: Equatable {
    var core: String
    var ridge: String
    var armBright: String
    var armEdge: String
    var hii: String
    var dust: String
    var outer: String
}

struct GalaxyLayerAlpha {
    var core: Double
    var ridge: Double
    var armBright: Double
    var armEdge: Double
    var hii: Double
    var dust: Double
    var outer: Double
}

struct GlowConfig {
    var pickProb: Double
    var pulseWidth: Double
    var radiusFactor: Double
    var minRadius: Double
    var durationMs: Double
    var bandFactor: Double
    var noiseFactor: Double
    var edgeAlphaThresh: Double
    var edgeExponent: Double
    var ease: String
}

extension GalaxyParams {
    static let `default` = GalaxyParams(
        coreDensity: 0.7,
        coreRadius: 12.0,
        coreSizeMin: 1.0,
        coreSizeMax: 3.5,
        armCount: 5,
        armDensity: 0.6,
        armBaseSizeMin: 0.7,
        armBaseSizeMax: 2.0,
        armHighlightSize: 5.0,
        armHighlightProb: 0.01,
        spiralA: 8.0,
        spiralB: 0.29,
        armWidthInner: 29.0,
        armWidthOuter: 65.0,
        armWidthGrowth: 2.5,
        armWidthScale: 1.0,
        armTransitionSoftness: 3.8,
        fadeStartRadius: 0.5,
        fadeEndRadius: 1.3,
        outerDensityMaintain: 0.10,
        interArmDensity: 0.150,
        interArmSizeMin: 0.6,
        interArmSizeMax: 1.2,
        radialDecay: 0.0015,
        backgroundDensity: 0.00024,
        backgroundSizeVariation: 2.0,
        jitterStrength: 10.0,
        densityNoiseScale: 0.018,
        densityNoiseStrength: 0.8,
        jitterChaos: 0.0,
        jitterChaosScale: 0.0,
        armStarSizeMultiplier: 1.0,
        interArmStarSizeMultiplier: 1.0,
        backgroundStarSizeMultiplier: 1.0,
        galaxyScale: 0.88,
        colorJitterHue: 0.0,
        colorJitterSat: 0.0,
        colorJitterLight: 0.0,
        colorNoiseScale: 0.0
    )

    static func platformDefault() -> GalaxyParams {
        var params = GalaxyParams.default
#if os(iOS)
        params.applyiOSTuning()
#endif
        return params
    }

    mutating func applyiOSTuning() {
        armWidthScale = 2.9
        armWidthInner = 29.0
        armWidthOuter = 65.0
        armWidthGrowth = 2.5
        armTransitionSoftness = 7.0
        jitterStrength = max(jitterStrength, 25.0)
        armStarSizeMultiplier *= 1.2
        interArmStarSizeMultiplier *= 1.35
        interArmSizeMin = max(0.4, interArmSizeMin * 1.25)
        interArmSizeMax = max(interArmSizeMin, interArmSizeMax * 1.25)
        backgroundStarSizeMultiplier = max(backgroundStarSizeMultiplier, backgroundStarSizeMultiplier * 1.1)
    }
}

extension GalaxyPalette {
    static let baseline = GalaxyPalette(
        core: "#5A4E41",
        ridge: "#5B5E66",
        armBright: "#28457B",
        armEdge: "#245B88",
        hii: "#3C194E",
        dust: "#0E0A14",
        outer: "#415069"
    )

    static let lit = GalaxyPalette(
        core: "#E3B787",
        ridge: "#C7C9CE",
        armBright: "#92ADE0",
        armEdge: "#95C2E8",
        hii: "#D88AC9",
        dust: "#3F3264",
        outer: "#ACB9CF"
    )
}

extension GalaxyLayerAlpha {
    static let baseline = GalaxyLayerAlpha(
        core: 1.0,
        ridge: 0.98,
        armBright: 0.90,
        armEdge: 0.85,
        hii: 0.88,
        dust: 0.45,
        outer: 0.78
    )
}

extension GlowConfig {
    static let baseline = GlowConfig(
        pickProb: 0.2,
        pulseWidth: 0.25,
        radiusFactor: 0.0175,
        minRadius: 30,
        durationMs: 950,
        bandFactor: 0.12,
        noiseFactor: 0.08,
        edgeAlphaThresh: 8,
        edgeExponent: 1.1,
        ease: "sine"
    )
}
