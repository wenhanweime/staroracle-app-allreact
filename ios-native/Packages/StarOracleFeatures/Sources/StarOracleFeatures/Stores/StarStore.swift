import Foundation
import StarOracleCore
import StarOracleServices

@MainActor
public final class StarStore: ObservableObject, StarStoreProtocol {
  @Published public private(set) var constellation: Constellation {
    willSet { logStateChange("constellation -> \(newValue.stars.count) stars") }
  }
  @Published public private(set) var inspirationStars: [Star] {
    willSet { logStateChange("inspirationStars -> \(newValue.count)") }
  }
  @Published public private(set) var activeStarId: String? {
    willSet { logStateChange("activeStarId -> \(String(describing: newValue))") }
  }
  @Published public private(set) var highlightedStarId: String? {
    willSet { logStateChange("highlightedStarId -> \(String(describing: newValue))") }
  }
  @Published public private(set) var galaxyHighlights: [String: GalaxyHighlight] {
    willSet { logStateChange("galaxyHighlights -> \(newValue.count)") }
  }
  @Published public private(set) var galaxyHighlightColor: String {
    willSet { logStateChange("galaxyHighlightColor -> \(newValue)") }
  }
  @Published public private(set) var isAsking: Bool {
    willSet { logStateChange("isAsking -> \(newValue)") }
  }
  @Published public private(set) var isLoading: Bool {
    willSet { logStateChange("isLoading -> \(newValue)") }
  }
  @Published public private(set) var pendingStarPosition: StarPosition? {
    willSet { logStateChange("pendingStarPosition updated") }
  }
  @Published public private(set) var currentInspirationCard: InspirationCard? {
    willSet { logStateChange("currentInspirationCard -> \(String(describing: newValue?.id))") }
  }
  @Published public private(set) var hasTemplate: Bool {
    willSet { logStateChange("hasTemplate -> \(newValue)") }
  }
  @Published public private(set) var templateInfo: ConstellationTemplateInfo? {
    willSet { logStateChange("templateInfo updated") }
  }
  @Published public private(set) var lastCreatedStarId: String? {
    willSet { logStateChange("lastCreatedStarId -> \(String(describing: newValue))") }
  }

  private let aiService: AIServiceProtocol
  private let inspirationService: InspirationServiceProtocol
  private let templateService: TemplateServiceProtocol
  private let preferenceService: PreferenceServiceProtocol
  private let soundService: SoundServiceProtocol?
  private let hapticService: HapticServiceProtocol?

  private let stateLoggingEnabled = true

  public init(
    constellation: Constellation = Constellation(),
    inspirationStars: [Star] = [],
    activeStarId: String? = nil,
    highlightedStarId: String? = nil,
    galaxyHighlights: [String: GalaxyHighlight] = [:],
    galaxyHighlightColor: String = "#FFE2B0",
    isAsking: Bool = false,
    isLoading: Bool = false,
    pendingStarPosition: StarPosition? = nil,
    currentInspirationCard: InspirationCard? = nil,
    hasTemplate: Bool = false,
    templateInfo: ConstellationTemplateInfo? = nil,
    lastCreatedStarId: String? = nil,
    aiService: AIServiceProtocol,
    inspirationService: InspirationServiceProtocol,
    templateService: TemplateServiceProtocol,
    preferenceService: PreferenceServiceProtocol,
    soundService: SoundServiceProtocol? = nil,
    hapticService: HapticServiceProtocol? = nil
  ) {
    self.constellation = constellation
    self.inspirationStars = inspirationStars
    self.activeStarId = activeStarId
    self.highlightedStarId = highlightedStarId
    self.galaxyHighlights = galaxyHighlights
    self.galaxyHighlightColor = galaxyHighlightColor
    self.isAsking = isAsking
    self.isLoading = isLoading
    self.pendingStarPosition = pendingStarPosition
    self.currentInspirationCard = currentInspirationCard
    self.hasTemplate = hasTemplate
    self.templateInfo = templateInfo
    self.lastCreatedStarId = lastCreatedStarId
    self.aiService = aiService
    self.inspirationService = inspirationService
    self.templateService = templateService
    self.preferenceService = preferenceService
    self.soundService = soundService
    self.hapticService = hapticService
  }

  private func logStateChange(_ label: String) {
    guard stateLoggingEnabled else { return }
    NSLog("⚠️ StarStore mutate \(label) | stack:\n\(Thread.callStackSymbols.joined(separator: "\n"))")
  }

  public func addStar(question: String, at position: StarPosition?) async throws -> Star {
    let trimmedQuestion = question.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedQuestion.isEmpty else {
      isAsking = false
      pendingStarPosition = nil
      isLoading = false
      throw StoreError.invalidQuestion
    }

    soundService?.play(.uiClick)
    hapticService?.impact(.light)
    isLoading = true
    defer { isLoading = false }
    isAsking = false

    let targetPosition = position ?? pendingStarPosition ?? StarPosition(
      x: Double.random(in: 15...85),
      y: Double.random(in: 15...85)
    )
    pendingStarPosition = nil

    let starId = "star-\(UUID().uuidString)"
    let placeholder = Star(
      id: starId,
      x: targetPosition.x,
      y: targetPosition.y,
      size: Double.random(in: 2.5...4.5),
      brightness: 0.6,
      question: trimmedQuestion,
      answer: "",
      imageURL: nil,
      createdAt: Date(),
      isSpecial: false,
      tags: [],
      primaryCategory: "philosophy_and_existence",
      emotionalTone: [],
      questionType: nil,
      insightLevel: nil,
      initialLuminosity: nil,
      connectionPotential: nil,
      suggestedFollowUp: nil,
      cardSummary: trimmedQuestion,
      similarity: nil,
      isTemplate: false,
      templateType: nil,
      isStreaming: true,
      isTransient: false
    )

    var stars = constellation.stars
    stars.append(placeholder)
    let connections = generateConnections(for: stars, baseConnections: constellation.connections)
    constellation = Constellation(stars: stars, connections: connections)
    activeStarId = starId
    highlightedStarId = starId
    lastCreatedStarId = starId

    let configuration = await preferenceService.loadAIConfiguration() ?? defaultConfiguration()
    var streamedAnswer = ""

    let stream = aiService.streamResponse(
      for: trimmedQuestion,
      configuration: configuration,
      context: AIRequestContext(history: [], metadata: [:])
    )

    do {
      for try await chunk in stream {
        streamedAnswer.append(chunk)
        updateStar(withId: starId) { star in
          star.answer = streamedAnswer
          star.isStreaming = true
        }
        if Task.isCancelled {
          throw StoreError.cancelled
        }
      }
    } catch {
      streamedAnswer = fallbackAnswer(for: trimmedQuestion)
      updateStar(withId: starId) { star in
        star.answer = streamedAnswer
      }
    }

    let analysis: TagAnalysis
    do {
      analysis = try await aiService.analyzeStarContent(
        question: trimmedQuestion,
        answer: streamedAnswer,
        configuration: configuration
      )
    } catch {
      analysis = TagAnalysis(
        tags: [],
        primaryCategory: "philosophy_and_existence",
        emotionalTone: ["探寻中"],
        questionType: "探索型",
        insightLevel: .init(value: 1, description: "星尘"),
        initialLuminosity: 60,
        connectionPotential: 3,
        suggestedFollowUp: "继续探索这个话题可能带来新的洞察。",
        cardSummary: streamedAnswer.isEmpty ? trimmedQuestion : String(streamedAnswer.prefix(60)) + "…"
      )
    }

    updateStar(withId: starId) { star in
      star.answer = streamedAnswer
      star.isStreaming = false
      star.tags = analysis.tags
      star.primaryCategory = analysis.primaryCategory
      star.emotionalTone = analysis.emotionalTone
      star.questionType = analysis.questionType
      star.insightLevel = analysis.insightLevel
      star.initialLuminosity = analysis.initialLuminosity
      star.connectionPotential = analysis.connectionPotential
      star.suggestedFollowUp = analysis.suggestedFollowUp
      star.cardSummary = analysis.cardSummary
      star.isSpecial = analysis.insightLevel.value >= 4
      star.size = star.size + Double(analysis.insightLevel.value) * 0.4
      star.brightness = Double(analysis.initialLuminosity) / 100.0
    }

    regenerateConnections()
    soundService?.play(.starLight)
    hapticService?.impact(.medium)

    guard let finalStar = constellation.stars.first(where: { $0.id == starId }) else {
      throw StoreError.starNotFound
    }
    return finalStar
  }

  public func drawInspirationCard(region: GalaxyRegion?) -> InspirationCard {
    let card = inspirationService.drawCard(for: region)
    currentInspirationCard = card
    inspirationStars.append(
      Star(
        id: "inspiration-\(card.id)-\(UUID().uuidString)",
        x: pendingStarPosition?.x ?? Double.random(in: 15...85),
        y: pendingStarPosition?.y ?? Double.random(in: 15...85),
        size: Double.random(in: 2.5...4.0),
        brightness: 0.6,
        question: card.question,
        answer: card.reflection,
        imageURL: nil,
        createdAt: Date(),
        isSpecial: card.emotionalTone == "positive",
        tags: Array(Set(card.tags + ["inspiration_card"])),
        primaryCategory: card.category,
        emotionalTone: [card.emotionalTone],
        questionType: "灵感火花",
        initialLuminosity: 55,
        connectionPotential: 2,
        suggestedFollowUp: card.reflection,
        cardSummary: card.question,
        isStreaming: false,
        isTransient: true
      )
    )
    if inspirationStars.count > 60 {
      inspirationStars = Array(inspirationStars.suffix(60))
    }
    soundService?.play(.starClick)
    return card
  }

  public func useCurrentInspirationCard() {
    isAsking = true
  }

  public func dismissInspirationCard(id: String?) {
    if let id, currentInspirationCard?.id != id {
      return
    }
    currentInspirationCard = nil
  }

  public func viewStar(id: String?) {
    activeStarId = id
    highlightedStarId = id ?? highlightedStarId
  }

  public func hideStarDetail() {
    activeStarId = nil
  }

  public func setIsAsking(_ isAsking: Bool, position: StarPosition?) {
    self.isAsking = isAsking
    pendingStarPosition = position
  }

  public func setGalaxyHighlights(_ highlights: [String: GalaxyHighlight]) {
    galaxyHighlights = highlights
    if galaxyHighlights.isEmpty {
      highlightedStarId = nil
    }
  }

  public func setGalaxyHighlightColor(_ colorHex: String) {
    galaxyHighlightColor = colorHex.uppercased()
  }

  public func regenerateConnections() {
    let connections = generateConnections(for: constellation.stars)
    constellation = Constellation(stars: constellation.stars, connections: connections)
  }

  public func applyTemplate(_ template: ConstellationTemplate) async throws {
    let templateStars = instantiateTemplateStars(template)
    var userStars = constellation.stars.filter { !$0.isTemplate }
    userStars.append(contentsOf: templateStars)

    let templateConnections = instantiateTemplateConnections(template, templateStars: templateStars)
    let connections = generateConnections(for: userStars, baseConnections: templateConnections)

    constellation = Constellation(stars: userStars, connections: connections)
    hasTemplate = true
    templateInfo = ConstellationTemplateInfo(name: template.chineseName, element: template.element)
    activeStarId = nil
    highlightedStarId = nil
  }

  public func clearConstellation() {
    constellation = Constellation()
    inspirationStars = []
    activeStarId = nil
    highlightedStarId = nil
    galaxyHighlights = [:]
    hasTemplate = false
    templateInfo = nil
    lastCreatedStarId = nil
  }

  public func updateStarTags(for starId: String, tags: [String]) {
    var stars = constellation.stars
    guard let index = stars.firstIndex(where: { $0.id == starId }) else { return }
    stars[index].tags = tags
    constellation = Constellation(stars: stars, connections: generateConnections(for: stars))
  }
}

private extension StarStore {
  func updateStar(withId id: String, update: (inout Star) -> Void) {
    var stars = constellation.stars
    guard let index = stars.firstIndex(where: { $0.id == id }) else { return }
    update(&stars[index])
    constellation = Constellation(stars: stars, connections: constellation.connections)
  }

  func generateConnections(for stars: [Star], baseConnections: [Connection] = []) -> [Connection] {
    var connectionSet = Set<String>()
    var result = [Connection]()

    for connection in baseConnections {
      let key = "\(connection.fromStarId)->\(connection.toStarId)"
      if !connectionSet.contains(key) {
        connectionSet.insert(key)
        result.append(connection)
      }
    }

    let sorted = stars.sorted { $0.createdAt < $1.createdAt }
    for pair in zip(sorted, sorted.dropFirst()) {
      let key = "\(pair.0.id)->\(pair.1.id)"
      guard !connectionSet.contains(key) else { continue }
      connectionSet.insert(key)
      result.append(
        Connection(
          id: "auto-\(pair.0.id)-\(pair.1.id)",
          fromStarId: pair.0.id,
          toStarId: pair.1.id,
          strength: 0.5,
          sharedTags: Array(Set(pair.0.tags).intersection(pair.1.tags))
        )
      )
    }
    return result
  }

  func instantiateTemplateStars(_ template: ConstellationTemplate) -> [Star] {
    template.stars.map { data in
      let x = template.centerX + data.x * template.scale
      let y = template.centerY + data.y * template.scale
      return Star(
        id: "template-\(template.id)-\(data.id)",
        x: x,
        y: y,
        size: data.size,
        brightness: data.brightness,
        question: data.question,
        answer: data.answer,
        imageURL: nil,
        createdAt: Date(),
        isSpecial: data.isMainStar,
        tags: data.tags,
        primaryCategory: data.primaryCategory ?? "philosophy_and_existence",
        emotionalTone: data.emotionalTone ?? [],
        questionType: data.questionType,
        insightLevel: data.insightLevel,
        initialLuminosity: data.initialLuminosity,
        connectionPotential: data.connectionPotential,
        suggestedFollowUp: data.suggestedFollowUp,
        cardSummary: data.cardSummary,
        similarity: nil,
        isTemplate: true,
        templateType: template.name,
        isStreaming: false,
        isTransient: false
      )
    }
  }

  func instantiateTemplateConnections(
    _ template: ConstellationTemplate,
    templateStars: [Star]
  ) -> [Connection] {
    let idMap = Dictionary(uniqueKeysWithValues: templateStars.map { star in
      (star.id.replacingOccurrences(of: "template-\(template.id)-", with: ""), star.id)
    })

    return template.connections.compactMap { connection in
      guard
        let fromId = idMap[connection.fromStarId],
        let toId = idMap[connection.toStarId]
      else { return nil }
      return Connection(
        id: "template-\(template.id)-\(connection.id)",
        fromStarId: fromId,
        toStarId: toId,
        strength: connection.strength,
        sharedTags: connection.sharedTags,
        isTemplate: true,
        constellationName: template.name
      )
    }
  }

  func defaultConfiguration() -> AIConfiguration {
    AIConfiguration(
      provider: "mock",
      apiKey: "",
      endpoint: URL(string: "https://example.com/mock")!,
      model: "mock-gpt"
    )
  }

  func fallbackAnswer(for question: String) -> String {
    let themes: [(keywords: [String], responses: [String])] = [
      (
        ["爱", "恋", "relationship", "love"],
        [
          "当心灵以真实的频率共鸣时，星辰自然排成新的轨道。",
          "如同双星互绕，亲密需要既独立又相互依存的节奏。",
          "在信任之光照耀下，脆弱会化成连接的桥梁。"
        ]
      ),
      (
        ["目标", "意义", "purpose"],
        [
          "意义往往藏在每日的微光里，而不是遥远的终点。",
          "当你向内探索时，外在的道路也会逐渐显形。",
          "目标像星座，需要你亲手把零散的星点连成线。"
        ]
      ),
      (
        ["恐惧", "害怕", "担心", "fear", "anxiety"],
        [
          "恐惧是未被看见的愿望，请给它温柔的关注。",
          "允许自己与不安同坐，它将慢慢讲述真正的诉求。",
          "越是靠近内心的火焰，影子就会越显眼。"
        ]
      )
    ]

    for theme in themes {
      if theme.keywords.contains(where: { question.contains($0) }) {
        return theme.responses.randomElement() ?? "你的感受值得被仔细看见。"
      }
    }
    return "宇宙静静回应：请相信你已经踏在属于自己的轨迹之上。"
  }
}
