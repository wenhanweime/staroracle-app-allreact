import Foundation

public struct InspirationCard: Identifiable, Codable, Equatable, Sendable {
  public let id: String
  public var title: String
  public var question: String
  public var reflection: String
  public var tags: [String]
  public var emotionalTone: String
  public var category: String
  public var spawnedAt: Int?

  public init(
    id: String,
    title: String,
    question: String,
    reflection: String,
    tags: [String] = [],
    emotionalTone: String = "探寻中",
    category: String = "philosophy_and_existence",
    spawnedAt: Int? = nil
  ) {
    self.id = id
    self.title = title
    self.question = question
    self.reflection = reflection
    self.tags = tags
    self.emotionalTone = emotionalTone
    self.category = category
    self.spawnedAt = spawnedAt
  }
}

public struct PersonalizedInspirationCandidate: Identifiable, Codable, Equatable, Sendable {
  public let id: String
  public var kind: String
  public var title: String
  public var content: String
  public var tags: [String]
  public var spawnedAt: Int?

  public init(
    id: String,
    kind: String,
    title: String,
    content: String,
    tags: [String] = [],
    spawnedAt: Int? = nil
  ) {
    self.id = id
    self.kind = kind
    self.title = title
    self.content = content
    self.tags = tags
    self.spawnedAt = spawnedAt
  }
}

public struct GalaxyHighlight: Codable, Equatable, Sendable {
  public var colorHex: String

  public init(colorHex: String) {
    self.colorHex = colorHex
  }
}

public enum StarOracleDebug {
  public static let verboseLogsKey = "staro.debug.verboseLogs"

  public static var verboseLogsEnabled: Bool {
#if DEBUG
    return UserDefaults.standard.bool(forKey: verboseLogsKey)
#else
    return false
#endif
  }

  public static func setVerboseLogsEnabled(_ enabled: Bool) {
#if DEBUG
    UserDefaults.standard.set(enabled, forKey: verboseLogsKey)
#else
    _ = enabled
#endif
  }
}
