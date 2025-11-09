import Foundation
import StarOracleCore

@MainActor
public final class GalaxyGridStore: ObservableObject, GalaxyGridStoreProtocol {
  @Published public private(set) var width: Double
  @Published public private(set) var height: Double
  @Published public private(set) var sites: [GalaxyGridSite]
  @Published public private(set) var activeIds: [String]

  private var neighbors: [[Int]]

  public init(
    width: Double = 0,
    height: Double = 0,
    sites: [GalaxyGridSite] = [],
    activeIds: [String] = [],
    neighbors: [[Int]] = []
  ) {
    self.width = width
    self.height = height
    self.sites = sites
    self.activeIds = activeIds
    self.neighbors = neighbors
  }

  public func setCanvasSize(width: Double, height: Double) {
    self.width = width
    self.height = height
  }

  public func generateSites(count: Int) {
    guard width > 0, height > 0 else { return }
    var rng = SeededRandomGenerator(seed: 0xABCDEF)
    sites = (0..<count).map { index in
      GalaxyGridSite(
        id: "site_\(index)",
        x: Double.random(in: 0...width, using: &rng),
        y: Double.random(in: 0...height, using: &rng),
        seed: index
      )
    }
    buildNeighbors(k: 6)
  }

  public func setActiveSites(nearX x: Double, y: Double) {
    guard !sites.isEmpty else { return }
    let shortEdge = min(width, height)
    let pickRadius = max(36, shortEdge * 0.05)
    let pickRadiusSquared = pickRadius * pickRadius
    var candidates: [(id: String, distance: Double)] = []
    for site in sites {
      let dx = x - site.x
      let dy = y - site.y
      let distanceSquared = dx * dx + dy * dy
      if distanceSquared <= pickRadiusSquared {
        candidates.append((site.id, distanceSquared))
      }
    }
    if candidates.count < 3 {
      let sorted = sites.map { site -> (String, Double) in
        let dx = x - site.x
        let dy = y - site.y
        return (site.id, dx * dx + dy * dy)
      }
      .sorted { $0.1 < $1.1 }
      let extra = sorted.prefix(max(3, 8 - candidates.count))
      for item in extra where !candidates.contains(where: { $0.0 == item.0 }) {
        candidates.append(item)
      }
    }
    candidates.sort { $0.distance < $1.distance }
    activeIds = candidates.prefix(8).map { $0.id }
  }

  public func perturbActiveSites(strength: Double) {
    guard !activeIds.isEmpty else { return }
    var newSites = sites
    for id in activeIds {
      guard let index = newSites.firstIndex(where: { $0.id == id }) else { continue }
      var site = newSites[index]
      site.x += Double.random(in: -strength...strength)
      site.y += Double.random(in: -strength...strength)
      newSites[index] = site
    }
    sites = newSites
  }

  public func buildNeighbors(k: Int) {
    let count = sites.count
    guard count > 1 else {
      neighbors = []
      return
    }
    neighbors = (0..<count).map { i in
      let site = sites[i]
      let sorted = sites.enumerated()
        .filter { $0.offset != i }
        .map { (offset, other) -> (Int, Double) in
          let dx = site.x - other.x
          let dy = site.y - other.y
          return (offset, dx * dx + dy * dy)
        }
        .sorted { $0.1 < $1.1 }
      return sorted.prefix(k).map { $0.0 }
    }
  }

  public func computeGraphDistances(seedIds: [String]) -> [Double] {
    let count = sites.count
    guard count > 0 else { return [] }
    var distances = Array(repeating: Double.infinity, count: count)
    var queue: [Int] = []
    for id in seedIds {
      if let index = sites.firstIndex(where: { $0.id == id }) {
        distances[index] = 0
        queue.append(index)
      }
    }
    var cursor = 0
    while cursor < queue.count {
      let current = queue[cursor]
      cursor += 1
      let baseDistance = distances[current]
      for neighbor in neighbors[safe: current] ?? [] {
        if distances[neighbor] > baseDistance + 1 {
          distances[neighbor] = baseDistance + 1
          queue.append(neighbor)
        }
      }
    }
    return distances
  }
}

private struct SeededRandomGenerator: RandomNumberGenerator {
  private var state: UInt64

  init(seed: UInt64) {
    state = seed
  }

  mutating func next() -> UInt64 {
    state &+= 0x9E3779B97F4A7C15
    var z = state
    z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
    z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
    return z ^ (z >> 31)
  }
}

private extension Array {
  subscript(safe index: Int) -> Element? {
    indices.contains(index) ? self[index] : nil
  }
}
