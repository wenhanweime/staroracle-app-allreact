import Foundation
import PixelPlanetsCore
import simd

func describe(_ planet: PlanetBase) {
    print("Planet: \(planet.label) [\(planet.id)]")
    print("  Relative scale: \(planet.relativeScale)")
    print("  GUI zoom: \(planet.guiZoom)")
    print("  Layers:")
    for layer in planet.layersSummary() {
        print("    • \(layer.name) visible=\(layer.visible)")
    }
    if !planet.uniformControlsList().isEmpty {
        print("  Uniform controls:")
        for control in planet.uniformControlsList() {
            print("    • \(control.label) (\(control.layer).\(control.uniform)) range [\(control.min), \(control.max)]")
        }
    }
}

do {
    let names = PlanetLibrary.allPlanetNames
    guard let first = names.first else {
        print("No planets registered.")
        exit(0)
    }

    print("Available planet presets:")
    names.forEach { print("  - \($0)") }
    print("")

    let planet = try PlanetLibrary.makePlanet(named: first)
    describe(planet)

    var seedRng = RandomStream(seed: 1_234_567)
    planet.setSeed(1_234_567, rng: &seedRng)
    planet.setPixels(128)
    planet.setRotation(Float.pi / 8)
    planet.setLight(Vec2(Float(0.4), Float(0.42)))

    var colorRng = RandomStream(seed: 777)
    let colors = planet.randomizeColors(rng: &colorRng)
    print("")
    print("Generated \(colors.count) colors for palette preview.")

    planet.updateTime(Float(0.5))
    let landTime = planet.uniformValue(layerName: "Land", uniform: "time")?.asFloat() ?? 0
    print("Land time uniform now: \(landTime)")
} catch PlanetLibraryError.unknownPlanet(let name) {
    print("Unknown planet preset: \(name)")
} catch {
    print("Failed to build planet: \(error)")
}
