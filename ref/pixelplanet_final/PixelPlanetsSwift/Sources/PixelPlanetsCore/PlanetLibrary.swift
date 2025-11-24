import Foundation

public enum PlanetLibraryError: Error {
    case unknownPlanet(String)
}

public typealias PlanetFactory = @Sendable () throws -> PlanetBase

public enum PlanetLibrary {
    @MainActor
    private static let factories: [String: PlanetFactory] = [
        "Terran Wet": { try RiversPlanet() },
        "Terran Dry": { try DryTerranPlanet() },
        "Islands": { try LandMassesPlanet() },
        "No atmosphere": { try NoAtmospherePlanet() },
        "Gas giant 1": { try GasPlanetPlanet() },
        "Gas giant 2": { try GasPlanetLayersPlanet() },
        "Ice World": { try IceWorldPlanet() },
        "Lava World": { try LavaWorldPlanet() },
        "Asteroid": { try AsteroidPlanet() },
        "Black Hole": { try BlackHolePlanet() },
        "Galaxy": { try GalaxyPlanet() },
        "Galaxy Round": { try CircularGalaxyPlanet() },
        "Star": { try StarPlanet() },
        "Twinkle Star": { try TwinkleStarPlanet() },
        "Twinkle Galaxy": { try TwinkleGalaxyPlanet() },
    ]

    @MainActor
    public static var allPlanetNames: [String] {
        factories.keys.sorted()
    }

    @MainActor
    public static func makePlanet(named name: String) throws -> PlanetBase {
        guard let factory = factories[name] else {
            throw PlanetLibraryError.unknownPlanet(name)
        }
        return try factory()
    }
}
