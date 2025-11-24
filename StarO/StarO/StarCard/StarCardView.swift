import SwiftUI
import StarOracleCore
import UIKit

struct StarCardView: View {
    let star: Star
    let isFlipped: Bool
    let onFlip: () -> Void
    var isLoading: Bool = false
    
    // Resolved config
    private let config: StarCardConfig
    
    init(star: Star, isFlipped: Bool, onFlip: @escaping () -> Void, isLoading: Bool = false) {
        self.star = star
        self.isFlipped = isFlipped
        self.onFlip = onFlip
        self.isLoading = isLoading
        self.config = StarCardConfig.resolve(for: star)
    }
    
    var body: some View {
        ZStack {
            // Front Face
            StarCardFrontView(star: star, config: config, isLoading: isLoading)
                .opacity(isFlipped ? 0 : 1)
                .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
            
            // Back Face
            StarCardBackView(star: star, config: config)
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
        }
        // .frame(width: 300, height: 420) // Removed hardcoded frame
        .onTapGesture {
            if !isLoading {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    onFlip()
                }
            }
        }
    }
}

// MARK: - Front Face

private struct StarCardFrontView: View {
    let star: Star
    let config: StarCardConfig
    let isLoading: Bool
    
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let minDim = min(size.width, size.height)
            
            ZStack {
                // Background Gradient
                RadialGradient(
                    gradient: Gradient(colors: [config.theme.inner, config.theme.outer]),
                    center: .center,
                    startRadius: 0,
                    endRadius: max(size.width, size.height) * 0.8
                )
                
                if !isLoading {
                    // Content
                    ZStack {
                        // Background Stars
                        ForEach(0..<20) { i in
                            BackgroundStar(seed: config.seed, index: i, containerSize: size)
                        }
                        
                        // Dust Particles
                        ForEach(0..<config.dustCount, id: \.self) { i in
                            DustParticle(seed: config.seed, index: i, color: star.isSpecial ? config.theme.accent : config.theme.star, containerSize: size)
                        }
                        
                        // Main Celestial Body
                        if config.style.isPixelPlanet {
                            // New pixel planet rendering
                            PixelPlanetRenderer(config: config, star: star)
                                .frame(width: minDim * 0.7, height: minDim * 0.7)
                        } else if config.style.isPlanet {
                            PlanetView(config: config, star: star)
                                .frame(width: minDim * 0.7, height: minDim * 0.7)
                        } else {
                            // Star Pattern
                            StarPatternView(config: config, color: star.isSpecial ? config.theme.accent : config.theme.star)
                                .frame(width: minDim * 0.7, height: minDim * 0.7)
                            
                            // Central Star Glow
                            Circle()
                                .fill(star.isSpecial ? config.theme.accent : config.theme.star)
                                .frame(width: minDim * 0.06, height: minDim * 0.06)
                                .blur(radius: minDim * 0.015)
                                .overlay(
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: minDim * 0.02, height: minDim * 0.02)
                                )
                                .shadow(color: (star.isSpecial ? config.theme.accent : config.theme.star).opacity(0.8), radius: minDim * 0.04)
                        }
                    }
                }
                
                // Title / Badge
                VStack {
                    Spacer()
                    HStack {
                        if star.isSpecial {
                            HStack(spacing: 4) {
                                Image(systemName: "sparkles")
                                Text("Rare Celestial")
                            }
                            .font(.system(size: minDim * 0.04, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(config.theme.accent.opacity(0.2))
                            .foregroundColor(config.theme.accent)
                            .cornerRadius(12)
                        } else {
                            HStack(spacing: 4) {
                                Circle().fill(Color.white.opacity(0.8)).frame(width: 6, height: 6)
                                Text("Inner Star")
                            }
                            .font(.system(size: minDim * 0.04))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.1))
                            .foregroundColor(.white.opacity(0.8))
                            .cornerRadius(12)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                            Text(star.createdAt, style: .date)
                        }
                        .font(.system(size: minDim * 0.04))
                        .foregroundColor(.white.opacity(0.6))
                    }
                    .padding()
                }
            }
            .cornerRadius(size.width * 0.08)
            .overlay(
                RoundedRectangle(cornerRadius: size.width * 0.08)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.3), radius: size.width * 0.06, x: 0, y: size.width * 0.03)
        }
    }
}

// MARK: - Back Face

private struct StarCardBackView: View {
    let star: Star
    let config: StarCardConfig
    
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            
            ZStack {
                Color(hex: "#1A1B26") // Dark background
                
                VStack(spacing: size.height * 0.06) {
                    // Question
                    VStack(spacing: 8) {
                        Text("Your Question")
                            .font(.system(size: size.width * 0.04))
                            .foregroundColor(.white.opacity(0.5))
                            .textCase(.uppercase)
                            .tracking(1)
                        
                        Text("\"\(star.question)\"")
                            .font(.system(size: size.width * 0.055, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                            .padding(.horizontal)
                    }
                    
                    // Divider
                    HStack {
                        Rectangle().fill(LinearGradient(colors: [.clear, config.theme.accent.opacity(0.5)], startPoint: .leading, endPoint: .trailing)).frame(height: 1)
                        Image(systemName: "sparkle")
                            .foregroundColor(config.theme.accent)
                        Rectangle().fill(LinearGradient(colors: [config.theme.accent.opacity(0.5), .clear], startPoint: .leading, endPoint: .trailing)).frame(height: 1)
                    }
                    .padding(.horizontal, size.width * 0.15)
                    
                    // Answer
                    VStack(spacing: 12) {
                        Text("星辰的启示")
                            .font(.system(size: size.width * 0.04))
                            .foregroundColor(config.theme.accent)
                            .tracking(2)
                        
                        Text(star.answer.isEmpty ? "..." : star.answer)
                            .font(.system(size: size.width * 0.05))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .lineSpacing(6)
                            .padding(.horizontal)
                    }
                    
                    Spacer()
                    
                    // Stats
                    HStack(spacing: 20) {
                        StatItem(label: "Brightness", value: "\(Int(star.brightness * 100))%")
                        StatItem(label: "Size", value: String(format: "%.1fpx", star.size))
                    }
                    .padding(.bottom, size.height * 0.05)
                    
                    Text("再次点击卡片继续探索星空")
                        .font(.system(size: size.width * 0.03))
                        .foregroundColor(config.theme.accent.opacity(0.7))
                        .padding(.bottom, size.height * 0.04)
                }
                .padding(.top, size.height * 0.1)
            }
            .cornerRadius(size.width * 0.08)
            .overlay(
                RoundedRectangle(cornerRadius: size.width * 0.08)
                    .stroke(config.theme.accent.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.3), radius: size.width * 0.06, x: 0, y: size.width * 0.03)
        }
    }
}

private struct StatItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.4))
            Text(value)
                .font(.caption.bold())
                .foregroundColor(.white.opacity(0.9))
        }
    }
}

// MARK: - Background Elements

private struct BackgroundStar: View {
    let seed: UInt64
    let index: Int
    let containerSize: CGSize
    @State private var isAnimating = false
    
    var body: some View {
        let randomX = Double((seed &+ UInt64(index * 13)) % UInt64(containerSize.width))
        let randomY = Double((seed &+ UInt64(index * 7)) % UInt64(containerSize.height))
        let size = Double((seed &+ UInt64(index)) % 3) / 2.0 + 1.0
        
        Circle()
            .fill(Color.white.opacity(0.6))
            .frame(width: size, height: size)
            .position(x: randomX, y: randomY)
            .opacity(isAnimating ? 0.8 : 0.3)
            .scaleEffect(isAnimating ? 1.2 : 1.0)
            .animation(
                Animation.easeInOut(duration: 2.0 + Double(index % 3))
                    .repeatForever(autoreverses: true)
                    .delay(Double(index) * 0.2),
                value: isAnimating
            )
            .onAppear { isAnimating = true }
    }
}

private struct DustParticle: View {
    let seed: UInt64
    let index: Int
    let color: Color
    let containerSize: CGSize
    @State private var isAnimating = false
    
    var body: some View {
        let angle = Double((seed &+ UInt64(index)) % 360) * .pi / 180
        let dist = 50.0 + Double((seed &+ UInt64(index * 5)) % 50)
        let size = Double((seed &+ UInt64(index * 2)) % 20) / 10.0 + 1.0
        
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .offset(x: cos(angle) * dist, y: sin(angle) * dist)
            .opacity(isAnimating ? 0.7 : 0)
            .offset(x: isAnimating ? 5 : -5, y: isAnimating ? -5 : 5) // Slight drift
            .animation(
                Animation.easeInOut(duration: 3.0 + Double(index % 2))
                    .repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear { isAnimating = true }
    }
}

// MARK: - Pixel Planet Renderer

private struct PixelPlanetRenderer: View {
    let config: StarCardConfig
    let star: Star
    @State private var error: String?
    
    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            
            if let planet = createPlanet(for: config.style, seed: Int(config.seed)) {
                ZStack {
                    PlanetCanvasView(
                        planet: planet,
                        pixels: max(50, Int(size)),
                        playing: true,
                        renderError: $error
                    )
                    .clipShape(Circle())
                    
                    // Overlay error if present (even if planet created, render might fail)
                    if let error = error {
                        Text(error)
                            .font(.caption2)
                            .foregroundColor(.red)
                            .background(Color.black.opacity(0.7))
                            .padding()
                    }
                }
            } else {
                // Fallback
                Circle()
                    .fill(config.theme.inner)
                    .overlay(
                        VStack {
                            Text("?")
                                .font(.system(size: size * 0.3))
                                .foregroundColor(config.theme.star)
                            if let error = error {
                                Text(error)
                                    .font(.caption2)
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                                    .padding()
                            }
                        }
                    )
            }
        }
    }
    
    private func createPlanet(for style: StarCardStyle, seed: Int) -> PlanetBase? {
        do {
            var rng = RandomStream(seed: seed)
            
            let planet: PlanetBase
            switch style {
            case .pixelAsteroid:
                planet = try AsteroidPlanet()
            case .pixelBlackHole:
                planet = try BlackHolePlanet()
            case .pixelGalaxy:
                planet = try GalaxyPlanet()
            case .pixelGalaxyRound:
                planet = try CircularGalaxyPlanet()
            case .pixelTwinkleGalaxy:
                planet = try TwinkleGalaxyPlanet()
            case .pixelGasPlanet:
                planet = try GasPlanetPlanet()
            case .pixelGasPlanetLayers:
                planet = try GasPlanetLayersPlanet()
            case .pixelIceWorld:
                planet = try IceWorldPlanet()
            case .pixelLandMasses:
                planet = try LandMassesPlanet()
            case .pixelLavaWorld:
                planet = try LavaWorldPlanet()
            case .pixelNoAtmosphere:
                planet = try NoAtmospherePlanet()
            case .pixelRivers:
                planet = try RiversPlanet()
            case .pixelDryTerran:
                planet = try DryTerranPlanet()
            case .pixelStar:
                planet = try StarPlanet()
            case .pixelTwinkleStar:
                planet = try TwinkleStarPlanet()
            default:
                return nil
            }
            
            // Complete initialization matching original PixelPlanets
            planet.setSeed(seed, rng: &rng)
            planet.setPixels(128)  // Standard resolution
            planet.setRotation(Float.pi / 8)  // Initial rotation
            planet.setLight(Vec2(0.39, 0.39))  // Light position (matching defaults)
            
            // Randomize colors
            var colorRng = RandomStream(seed: seed &+ 777)  // Different seed for colors
            _ = planet.randomizeColors(rng: &colorRng)
            
            // Apply advanced configuration (migrated from original project sliders)
            PlanetConfigurator.configure(planet: planet, seed: seed)
            
            return planet
        } catch {
            print("Failed to create planet: \(error)")
            DispatchQueue.main.async {
                self.error = "\(error)"
            }
            return nil
        }
    }
}
