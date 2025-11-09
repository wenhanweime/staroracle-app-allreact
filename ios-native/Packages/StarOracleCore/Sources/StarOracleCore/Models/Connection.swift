import Foundation

public struct Connection: Identifiable, Codable, Equatable, Sendable {
  public let id: String
  public var fromStarId: String
  public var toStarId: String
  public var strength: Double
  public var sharedTags: [String]
  public var isTemplate: Bool
  public var constellationName: String?

  public init(
    id: String,
    fromStarId: String,
    toStarId: String,
    strength: Double,
    sharedTags: [String] = [],
    isTemplate: Bool = false,
    constellationName: String? = nil
  ) {
    self.id = id
    self.fromStarId = fromStarId
    self.toStarId = toStarId
    self.strength = strength
    self.sharedTags = sharedTags
    self.isTemplate = isTemplate
    self.constellationName = constellationName
  }
}

public struct Constellation: Codable, Equatable, Sendable {
  public var stars: [Star]
  public var connections: [Connection]

  public init(stars: [Star] = [], connections: [Connection] = []) {
    self.stars = stars
    self.connections = connections
  }
}
