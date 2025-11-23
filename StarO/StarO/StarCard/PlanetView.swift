import SwiftUI
import StarOracleCore

struct PlanetView: View {
    let config: StarCardConfig
    let star: Star
    
    var body: some View {
        Canvas { context, size in
            // Setup RNG
            var rng = SeededRandom(seed: config.seed)
            
            let centerX = size.width / 2
            let centerY = size.height / 2
            let scale = size.width / 200.0 // Base logic on 200x200
            
            // Planet Parameters
            let planetRadiusBase = 15.0 + rng.next(in: 0...5)
            let planetRadius = planetRadiusBase * scale
            
            // Palette Generation
            // Parse HSL from theme (simplified: use theme colors directly)
            // We'll generate a palette based on the theme's accent or star color
            let baseColor = star.isSpecial ? config.theme.accent : config.theme.star
            // We need to derive shadow/highlight colors. 
            // Since Color doesn't easily give HSL in SwiftUI, we'll use opacity overlays for shading.
            
            let lightAngle = rng.next(in: 0...(2 * .pi))
            
            // 1. Glow
            let glowRadius = planetRadius * 3.0
            let glowGradient = Gradient(stops: [
                .init(color: baseColor.opacity(0.7), location: 0),
                .init(color: baseColor.opacity(0.3), location: 0.15), // 0.5 in 0.8-3 range approx
                .init(color: .clear, location: 1.0)
            ])
            context.fill(
                Path(ellipseIn: CGRect(x: centerX - glowRadius, y: centerY - glowRadius, width: glowRadius * 2, height: glowRadius * 2)),
                with: .radialGradient(glowGradient, center: .init(x: centerX, y: centerY), startRadius: planetRadius * 0.8, endRadius: glowRadius)
            )
            
            // 2. Background Stars
            for _ in 0..<30 {
                let x = rng.next(in: 0...size.width)
                let y = rng.next(in: 0...size.height)
                let s = (rng.next() * 1.2 + 0.3) * scale
                context.opacity = rng.next() * 0.7 + 0.1
                context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: s, height: s)), with: .color(.white))
            }
            context.opacity = 1.0
            
            // Ring Config
            let hasPlanetRings = config.style == .planetRings || (config.style.isPlanet && rng.next() > 0.7)
            var ringTilt = 0.0
            var ringRadiusX = 0.0
            var ringRadiusY = 0.0
            
            if hasPlanetRings {
                ringTilt = (rng.next() - 0.5) * 0.8
                ringRadiusX = planetRadius * 1.6
                ringRadiusY = ringRadiusX * 0.3
            }
            
            // 3. Ring Back
            if hasPlanetRings {
                context.withCGContext { cg in
                    cg.saveGState()
                    cg.translateBy(x: centerX, y: centerY)
                    cg.rotate(by: ringTilt)
                    
                    let rect = CGRect(x: -ringRadiusX, y: -ringRadiusY, width: ringRadiusX * 2, height: ringRadiusY * 2)
                    let path = Path(ellipseIn: rect)
                    
                    // Clip to back half (top half in rotated space, roughly)
                    // Actually, standard ellipse drawing draws full. We need to mask or just draw full behind?
                    // React draws full ellipse behind.
                    context.stroke(path, with: .color(baseColor.opacity(0.6)), lineWidth: 1.5 * scale)
                    
                    cg.restoreGState()
                }
            }
            
            // 4. Planet Body
            let planetRect = CGRect(x: centerX - planetRadius, y: centerY - planetRadius, width: planetRadius * 2, height: planetRadius * 2)
            let planetPath = Path(ellipseIn: planetRect)
            
            // Draw base planet with shadow
            var baseContext = context
            baseContext.addFilter(.shadow(color: baseColor.opacity(0.5), radius: 5 * scale))
            baseContext.fill(planetPath, with: .color(baseColor)) // Base
            
            // Clip to planet for details
            // We use a local context for the planet body details so the clip doesn't affect subsequent drawing (like rings/rays)
            var planetBodyContext = context
            planetBodyContext.clip(to: planetPath)
            
            // Shading (Bands)
            let numBands = Int(rng.next(in: 5...10))
            let lightVec = CGPoint(x: cos(lightAngle), y: sin(lightAngle))
            let totalOffset = planetRadius * 0.8
            
            for i in 0..<numBands {
                let t = Double(i) / Double(numBands - 1)
                let offsetFactor = -1.0 + 2.0 * t
                let offsetX = lightVec.x * totalOffset * offsetFactor * -0.5
                let offsetY = lightVec.y * totalOffset * offsetFactor * -0.5
                
                // Darker bands
                let bandPath = Path(ellipseIn: CGRect(
                    x: centerX - planetRadius - offsetX,
                    y: centerY - planetRadius - offsetY,
                    width: planetRadius * 2,
                    height: planetRadius * 2
                ))
                
                // Simulate shadow/highlight by varying opacity of black/white
                // t=0 is shadow side, t=1 is light side
                let shadowOpacity = (1.0 - t) * 0.6
                planetBodyContext.fill(bandPath, with: .color(.black.opacity(shadowOpacity)))
            }
            
            // Style Specific Features
            if config.style == .planetCraters {
                let craterCount = Int(rng.next(in: 5...15))
                for _ in 0..<craterCount {
                    let angle = rng.next(in: 0...(2 * .pi))
                    let dist = rng.next(in: 0...0.8) * planetRadius
                    let cx = centerX + cos(angle) * dist
                    let cy = centerY + sin(angle) * dist
                    let r = (rng.next() * 0.06 + 0.01) * planetRadius
                    
                    // Perspective squash
                    let relativeDist = dist / planetRadius
                    let squash = sqrt(1.0 - relativeDist * relativeDist)
                    let rotation = angle + .pi / 2
                    
                    planetBodyContext.withCGContext { cg in
                        cg.saveGState()
                        cg.translateBy(x: cx, y: cy)
                        cg.rotate(by: rotation)
                        cg.scaleBy(x: 1.0, y: max(0.1, squash))
                        
                        let craterPath = Path(ellipseIn: CGRect(x: -r, y: -r, width: r*2, height: r*2))
                        let isShadow = rng.next() > 0.5
                        cg.setFillColor(isShadow ? UIColor.black.withAlphaComponent(0.4).cgColor : UIColor.white.withAlphaComponent(0.4).cgColor)
                        cg.addPath(craterPath.cgPath)
                        cg.fillPath()
                        
                        cg.restoreGState()
                    }
                }
            } else if config.style == .planetDust {
                let dustCount = Int(rng.next(in: 10...20))
                for _ in 0..<dustCount {
                    let angle = rng.next(in: 0...(2 * .pi))
                    let dist = rng.next(in: 0...planetRadius)
                    let dx = centerX + cos(angle) * dist
                    let dy = centerY + sin(angle) * dist
                    let r = (rng.next() * 1.0 + 0.3) * scale
                    
                    planetBodyContext.fill(Path(ellipseIn: CGRect(x: dx - r, y: dy - r, width: r*2, height: r*2)), with: .color(.white.opacity(0.8)))
                }
            }
            
            // 5. Ring Front
            if hasPlanetRings {
                context.withCGContext { cg in
                    cg.saveGState()
                    cg.translateBy(x: centerX, y: centerY)
                    cg.rotate(by: ringTilt)
                    
                    let rect = CGRect(x: -ringRadiusX, y: -ringRadiusY, width: ringRadiusX * 2, height: ringRadiusY * 2)
                    let path = Path(ellipseIn: rect)
                    
                    // To draw "front" only, we technically need to clip the back part which is behind planet.
                    // But React implementation just draws the whole ring again with higher opacity?
                    // React: "drawRingFront" draws full ellipse again.
                    // Wait, React code:
                    // drawRingBack: draws ellipse.
                    // drawPlanet: draws planet (covers back ring).
                    // drawRingFront: draws ellipse again?
                    // Ah, `ctx.ellipse(..., 0, 0, Math.PI)` -> Draws half ellipse!
                    // Back: `0, Math.PI, Math.PI * 2` (Bottom half?)
                    // Front: `0, 0, Math.PI` (Top half?)
                    
                    // In SwiftUI Path, we can use addArc.
                    // Ellipse is harder to arc.
                    // We can use scale transform on a circle arc.
                    
                    // Let's try to draw just the front arc.
                    // Front is 0 to Pi (if 0 is right, Pi is left, clockwise).
                    // We need to check orientation.
                    
                    let frontPath = Path { p in
                        p.addArc(center: .zero, radius: ringRadiusX, startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
                    }
                    // This creates a circular arc. We need to squash it.
                    
                    cg.scaleBy(x: 1.0, y: 0.3) // Apply the 0.3 aspect ratio
                    
                    context.stroke(frontPath, with: .color(baseColor.opacity(0.8)), lineWidth: 1.5 * scale)
                    
                    cg.restoreGState()
                }
            }
            
            // 6. Rays (Special)
            if star.isSpecial {
                let rayCount = Int(rng.next(in: 4...8))
                let baseAngle = rng.next() * .pi
                
                for i in 0..<rayCount {
                    let angle = baseAngle + (Double(i) * 2 * .pi) / Double(rayCount)
                    let length = planetRadius * (2.0 + rng.next() * 2.0)
                    
                    let endX = centerX + cos(angle) * length
                    let endY = centerY + sin(angle) * length
                    
                    var path = Path()
                    path.move(to: CGPoint(x: centerX, y: centerY))
                    path.addLine(to: CGPoint(x: endX, y: endY))
                    
                    context.stroke(path, with: .linearGradient(Gradient(colors: [baseColor.opacity(0.9), .clear]), startPoint: CGPoint(x: centerX, y: centerY), endPoint: CGPoint(x: endX, y: endY)), lineWidth: (1.0 + rng.next()) * scale)
                }
            }
            
        }
    }
}
