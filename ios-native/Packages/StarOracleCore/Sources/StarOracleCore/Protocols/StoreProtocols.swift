import Foundation

@MainActor
public protocol StarStoreProtocol: AnyObject {
  var constellation: Constellation { get }
  var inspirationStars: [Star] { get }
  var activeStarId: String? { get }
  var highlightedStarId: String? { get }
  var galaxyHighlights: [String: GalaxyHighlight] { get }
  var galaxyHighlightColor: String { get }
  var isAsking: Bool { get }
  var isLoading: Bool { get }
  var pendingStarPosition: StarPosition? { get }
  var currentInspirationCard: InspirationCard? { get }
  var hasTemplate: Bool { get }
  var templateInfo: ConstellationTemplateInfo? { get }
  var lastCreatedStarId: String? { get }

  func addStar(question: String, at position: StarPosition?) async throws -> Star
  func drawInspirationCard(region: GalaxyRegion?) -> InspirationCard
  func useCurrentInspirationCard()
  func dismissInspirationCard(id: String?)
  func viewStar(id: String?)
  func hideStarDetail()
  func setIsAsking(_ isAsking: Bool, position: StarPosition?)
  func setGalaxyHighlights(_ highlights: [String: GalaxyHighlight])
  func setGalaxyHighlightColor(_ colorHex: String)
  func regenerateConnections()
  func applyTemplate(_ template: ConstellationTemplate) async throws
  func clearConstellation()
  func updateStarTags(for starId: String, tags: [String])
}

@MainActor
public protocol ChatStoreProtocol: AnyObject {
  var messages: [ChatMessage] { get }
  var isLoading: Bool { get }
  var conversationTitle: String { get }
  var conversationAwareness: ConversationAwareness { get }

  func addUserMessage(_ text: String)
  func addAIMessage(_ text: String)
  func beginStreamingAIMessage(initial: String?) -> String
  func updateStreamingMessage(id: String, text: String)
  func finalizeStreamingMessage(id: String)
  func setLoading(_ isLoading: Bool)
  func clearMessages()
  func startAwarenessAnalysis(messageId: String)
  func completeAwarenessAnalysis(messageId: String, insight: AwarenessInsight)
  func refreshConversationAwareness()
  func setConversationAnalyzing(_ isAnalyzing: Bool)
  func setConversationTitle(_ title: String)
  func generateConversationTitle() async throws
}

@MainActor
public protocol GalaxyStoreProtocol: AnyObject {
  var width: Double { get }
  var height: Double { get }
  var hotspots: [GalaxyHotspot] { get }
  var ripples: [GalaxyRipple] { get }
  var hoveredId: String? { get }

  func setCanvasSize(width: Double, height: Double)
  func generateHotspots(count: Int)
  func hover(atX x: Double, y: Double)
  func tap(atX x: Double, y: Double)
  func cleanupEffects()
}

public struct GalaxyGridSite: Identifiable, Codable, Equatable, Sendable {
  public let id: String
  public var x: Double
  public var y: Double
  public var seed: Int

  public init(id: String, x: Double, y: Double, seed: Int) {
    self.id = id
    self.x = x
    self.y = y
    self.seed = seed
  }
}

@MainActor
public protocol GalaxyGridStoreProtocol: AnyObject {
  var width: Double { get }
  var height: Double { get }
  var sites: [GalaxyGridSite] { get }
  var activeIds: [String] { get }

  func setCanvasSize(width: Double, height: Double)
  func generateSites(count: Int)
  func setActiveSites(nearX x: Double, y: Double)
  func perturbActiveSites(strength: Double)
  func buildNeighbors(k: Int)
  func computeGraphDistances(seedIds: [String]) -> [Double]
}
