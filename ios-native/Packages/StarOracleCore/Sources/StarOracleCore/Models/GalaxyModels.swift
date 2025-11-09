import Foundation

public enum GalaxyRegion: String, Codable, CaseIterable, Sendable {
  case emotion
  case relation
  case growth
}

public struct GalaxyHotspot: Identifiable, Codable, Equatable, Sendable {
  public let id: String
  public var xPercent: Double
  public var yPercent: Double
  public var region: GalaxyRegion
  public var seed: Int
  public var cooldownUntil: Date?

  public init(
    id: String,
    xPercent: Double,
    yPercent: Double,
    region: GalaxyRegion,
    seed: Int,
    cooldownUntil: Date? = nil
  ) {
    self.id = id
    self.xPercent = xPercent
    self.yPercent = yPercent
    self.region = region
    self.seed = seed
    self.cooldownUntil = cooldownUntil
  }
}

public struct GalaxyRipple: Identifiable, Codable, Equatable, Sendable {
  public let id: String
  public var x: Double
  public var y: Double
  public var startAt: Date
  public var duration: TimeInterval

  public init(id: String, x: Double, y: Double, startAt: Date, duration: TimeInterval) {
    self.id = id
    self.x = x
    self.y = y
    self.startAt = startAt
    self.duration = duration
  }
}
