import Foundation
import simd

struct PlanetConfigurator {
    /// Configures a planet with randomized parameters based on a seed.
    /// This replaces the manual slider controls from the original project.
    @MainActor
    static func configure(planet: PlanetBase, seed: Int) {
        var rng = RandomStream(seed: seed)
        
        // 1. Generic Randomization for all controls
        // Iterate over all available controls and set a random value within their defined range.
        // This ensures that every parameter that *could* be tweaked is tweaked.
        for control in planet.uniformControls {
            // We only randomize floats for now as that covers most sliders
            // Some controls might be integers disguised as floats (like octaves),
            // but nextRange handles that continuously. For strict integers we might need care,
            // but usually shaders handle non-integers fine or we can round if needed.
            // However, for things like "octaves", it's better to pick an integer.
            
            if control.uniform == "octaves" || control.uniform == "OCTAVES" || control.uniform == "n_colors" {
                let value = round(rng.nextRange(min: control.min, max: control.max))
                planet.setFloat(control.layer, control.uniform, value)
            } else {
                let value = rng.nextRange(min: control.min, max: control.max)
                planet.setFloat(control.layer, control.uniform, value)
            }
        }
        
        // 2. Specific Overrides and Tuning
        // Some parameters need specific tuning to look good, rather than full random range.
        
        // Global defaults
        planet.setDither(true) // Always enable dither for the retro look
        
        // Planet-specific tuning
        switch planet {
        case is GasPlanetPlanet:
            configureGasPlanet(planet as! GasPlanetPlanet, rng: &rng)
        case is GasPlanetLayersPlanet:
            configureGasPlanetLayers(planet as! GasPlanetLayersPlanet, rng: &rng)
        case is LandMassesPlanet:
            configureLandMasses(planet as! LandMassesPlanet, rng: &rng)
        case is NoAtmospherePlanet:
            configureNoAtmosphere(planet as! NoAtmospherePlanet, rng: &rng)
        case is RiversPlanet:
            configureRivers(planet as! RiversPlanet, rng: &rng)
        case is BlackHolePlanet:
            configureBlackHole(planet as! BlackHolePlanet, rng: &rng)
        default:
            break
        }
    }
    
    @MainActor
    private static func configureGasPlanet(_ planet: GasPlanetPlanet, rng: inout RandomStream) {
        // GasPlanetPlanet uses "Cloud" and "Cloud2" layers (Swift original)
        // Gas planets look better with slower, majestic movement
        let speed = rng.nextRange(min: 0.05, max: 0.2)
        planet.setFloat("Cloud", "time_speed", speed)
        planet.setFloat("Cloud2", "time_speed", speed * 0.7)
        
        // Cloud scale
        let size = rng.nextRange(min: 3.0, max: 9.0)
        planet.setFloat("Cloud", "size", size)
        planet.setFloat("Cloud2", "size", size)
    }
    
    @MainActor
    private static func configureGasPlanetLayers(_ planet: GasPlanetLayersPlanet, rng: inout RandomStream) {
        // GasPlanetLayersPlanet uses "GasLayers" and "Ring" (Swift original)
        let speed = rng.nextRange(min: 0.05, max: 0.15)
        planet.setFloat("GasLayers", "time_speed", speed)
        planet.setFloat("Ring", "time_speed", speed)
        
        // Ring rotation relative to planet
        let ringRot = rng.nextRange(min: -0.5, max: 0.5)
        planet.setFloat("Ring", "rotation", ringRot)
    }
    
    @MainActor
    private static func configureLandMasses(_ planet: LandMassesPlanet, rng: inout RandomStream) {
        // Water level (land_cutoff)
        // Lower value = more land, Higher value = more water
        let waterLevel = rng.nextRange(min: 0.45, max: 0.65)
        planet.setFloat("Land", "land_cutoff", waterLevel)
        
        // Cloud movement
        planet.setFloat("Clouds", "time_speed", rng.nextRange(min: 0.1, max: 0.3))
    }
    
    @MainActor
    private static func configureNoAtmosphere(_ planet: NoAtmospherePlanet, rng: inout RandomStream) {
        // Crater density via size
        let craterScale = rng.nextRange(min: 2.0, max: 6.0)
        planet.setFloat("Craters", "size", craterScale)
    }
    
    @MainActor
    private static func configureRivers(_ planet: RiversPlanet, rng: inout RandomStream) {
        // River complexity
        let scale = rng.nextRange(min: 4.0, max: 10.0)
        planet.setFloat("Land", "size", scale)
    }
    
    @MainActor
    private static func configureBlackHole(_ planet: BlackHolePlanet, rng: inout RandomStream) {
        // Disk swirl speed
        planet.setFloat("Disk", "time_speed", rng.nextRange(min: 0.1, max: 0.4))
        
        // Core radius
        let radius = rng.nextRange(min: 0.2, max: 0.3)
        planet.setFloat("BlackHole", "radius", radius)
    }
}
