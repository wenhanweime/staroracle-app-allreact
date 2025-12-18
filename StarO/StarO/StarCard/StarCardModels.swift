import SwiftUI
import StarOracleCore

// MARK: - Star Styles

enum StarCardStyle: String, CaseIterable {
    case standard = "standard"
    case cross = "cross"
    case burst = "burst"
    case sparkle = "sparkle"
    case ringed = "ringed"
    
    // Legacy planet styles (Canvas-based)
    case planetSmooth = "planet_smooth"
    case planetCraters = "planet_craters"
    case planetSeas = "planet_seas"
    case planetDust = "planet_dust"
    case planetRings = "planet_rings"
    
    // New pixel planet styles (GL-based)
    case pixelAsteroid = "pixel_asteroid"
    case pixelBlackHole = "pixel_black_hole"
    case pixelGalaxy = "pixel_galaxy"
    case pixelGalaxyRound = "pixel_galaxy_round"
    case pixelGasPlanet = "pixel_gas_planet"
    case pixelGasPlanetLayers = "pixel_gas_planet_layers"
    case pixelIceWorld = "pixel_ice_world"
    case pixelLandMasses = "pixel_land_masses"
    case pixelLavaWorld = "pixel_lava_world"
    case pixelNoAtmosphere = "pixel_no_atmosphere"
    case pixelRivers = "pixel_rivers"
    case pixelDryTerran = "pixel_dry_terran"
    case pixelStar = "pixel_star"
    
    var isPlanet: Bool {
        self.rawValue.starts(with: "planet_")
    }
    
    var isPixelPlanet: Bool {
        self.rawValue.starts(with: "pixel_")
    }

    static let starStyles: [StarCardStyle] = allCases.filter { !$0.isPlanet && !$0.isPixelPlanet }
    static let planetStyles: [StarCardStyle] = allCases.filter(\.isPlanet)
    static let pixelStyles: [StarCardStyle] = allCases.filter(\.isPixelPlanet)
}


// MARK: - Cosmic Themes

struct StarCardTheme {
    let name: String
    let inner: Color
    let outer: Color
    let star: Color
    let accent: Color
    
    static let all: [StarCardTheme] = [
        StarCardTheme(
            name: "Deep Space Blue",
            inner: Color(hue: 250/360, saturation: 0.4, brightness: 0.2),
            outer: Color(hue: 230/360, saturation: 0.5, brightness: 0.05),
            star: Color(hue: 220/360, saturation: 1.0, brightness: 0.85),
            accent: Color(hue: 240/360, saturation: 0.7, brightness: 0.7)
        ),
        StarCardTheme(
            name: "Nebula Purple",
            inner: Color(hue: 280/360, saturation: 0.5, brightness: 0.18),
            outer: Color(hue: 260/360, saturation: 0.6, brightness: 0.04),
            star: Color(hue: 290/360, saturation: 1.0, brightness: 0.85),
            accent: Color(hue: 280/360, saturation: 0.7, brightness: 0.7)
        ),
        StarCardTheme(
            name: "Ancient Red",
            inner: Color(hue: 340/360, saturation: 0.45, brightness: 0.15),
            outer: Color(hue: 320/360, saturation: 0.5, brightness: 0.05),
            star: Color(hue: 350/360, saturation: 1.0, brightness: 0.85),
            accent: Color(hue: 340/360, saturation: 0.7, brightness: 0.7)
        ),
        StarCardTheme(
            name: "Ice Crystal Blue",
            inner: Color(hue: 200/360, saturation: 0.5, brightness: 0.15),
            outer: Color(hue: 220/360, saturation: 0.6, brightness: 0.06),
            star: Color(hue: 190/360, saturation: 1.0, brightness: 0.85),
            accent: Color(hue: 200/360, saturation: 0.7, brightness: 0.7)
        )
    ]
}

// MARK: - Configuration

struct StarCardConfig {
    let style: StarCardStyle
    let theme: StarCardTheme
    let hasRing: Bool
    let dustCount: Int
    let seed: UInt64
    
    static func resolve(for star: Star) -> StarCardConfig {
        // Deterministic seed from Star ID or creation date
        let seedString = star.id
        let seed = UInt64(galaxyDeterministicSeed(from: seedString))
        var rng = SeededRandom(seed: seed)

        func pickIndex(_ count: Int, unit: Double) -> Int {
            guard count > 0 else { return 0 }
            let value = min(0.999999999999, max(0.0, unit))
            return Int(floor(value * Double(count)))
        }
        
        // Select Style
        // 视觉类型并列：star / planet_ / pixel_ 三类均启用；三类各占 1/3，类内均匀抽样。
        // 注意：保持只消耗 1 次 rng.next()，避免影响后续 hasRing/dustCount 的确定性结果。
        let value = min(0.999999999999, max(0.0, rng.next()))
        let bucket = value * 3.0
        let group = Int(floor(bucket))
        let within = bucket - Double(group)

        let style: StarCardStyle
        switch group {
        case 0:
            style = StarCardStyle.starStyles[pickIndex(StarCardStyle.starStyles.count, unit: within)]
        case 1:
            style = StarCardStyle.planetStyles[pickIndex(StarCardStyle.planetStyles.count, unit: within)]
        default:
            style = StarCardStyle.pixelStyles[pickIndex(StarCardStyle.pixelStyles.count, unit: within)]
        }
        
        // Select Theme
        // 回归：固定使用紫色主题（Nebula Purple），避免因云端 UUID 变化导致主题漂移。
        let theme = StarCardTheme.all.first(where: { $0.name == "Nebula Purple" }) ?? StarCardTheme.all.first!
        
        // Attributes
        let hasRing = star.isSpecial ? (rng.next() > 0.6) : false
        let dustMin = 5.0
        let dustMax = star.isSpecial ? 20.0 : 10.0
        let dustCount = Int(rng.next(in: dustMin...dustMax))
        
        return StarCardConfig(
            style: style,
            theme: theme,
            hasRing: hasRing,
            dustCount: dustCount,
            seed: seed
        )
    }
}
