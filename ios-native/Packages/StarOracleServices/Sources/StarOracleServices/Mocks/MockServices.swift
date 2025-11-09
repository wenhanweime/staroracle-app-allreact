import Foundation
import StarOracleCore

public final class MockAIService: AIServiceProtocol {
  public init() {}

  public func streamResponse(
    for question: String,
    configuration: AIConfiguration,
    context: AIRequestContext
  ) -> AsyncThrowingStream<String, Error> {
    let response = "星语提示：\(question.isEmpty ? "请告诉我你的想法。" : "关于「\(question)」的灵感正在汇聚。")"
    return AsyncThrowingStream { continuation in
      Task {
        var cursor = response.startIndex
        while cursor < response.endIndex {
          let next = response.index(cursor, offsetBy: 12, limitedBy: response.endIndex) ?? response.endIndex
          let chunk = String(response[cursor..<next])
          try? await Task.sleep(nanoseconds: 60_000_000)
          continuation.yield(chunk)
          cursor = next
        }
        continuation.finish()
      }
    }
  }

  public func analyzeStarContent(
    question: String,
    answer: String,
    configuration: AIConfiguration
  ) async throws -> TagAnalysis {
    TagAnalysis(
      tags: ["mock", "insight"],
      primaryCategory: "personal_growth",
      emotionalTone: ["探寻中"],
      questionType: "探索型",
      insightLevel: .init(value: 3, description: "寻常星"),
      initialLuminosity: 65,
      connectionPotential: 3,
      suggestedFollowUp: "试着把这个想法写下来，并问问自己真正的渴望是什么。",
      cardSummary: answer.isEmpty ? question : answer
    )
  }

  public func analyzeAwareness(
    question: String,
    answer: String,
    configuration: AIConfiguration
  ) async throws -> AwarenessInsight {
    AwarenessInsight(
      hasInsight: true,
      insightLevel: .medium,
      insightType: "自我认知",
      keyInsights: ["觉察到新的视角"],
      emotionalPattern: "正在探索自我需求",
      suggestedReflection: "将这种感受描述给自己，观察出现了哪些画面。",
      followUpQuestions: ["如果给这种感受一个颜色，它会是什么？"]
    )
  }

  public func generateConversationTitle(
    from messages: [ChatMessage],
    configuration: AIConfiguration
  ) async throws -> String {
    if let first = messages.first(where: { $0.isUser }) {
      return "关于\(String(first.text.prefix(4)))的对话"
    }
    return "新对话"
  }

  public func validate(configuration: AIConfiguration) async throws {}
}

public final class MockInspirationService: InspirationServiceProtocol {
  public init() {}

  public func drawCard(for region: GalaxyRegion?) -> InspirationCard {
    if let region {
      let filtered = InspirationData.cards.filter { card in
        switch region {
        case .emotion:
          return card.category == "wellbeing"
        case .relation:
          return card.category == "relationships"
        case .growth:
          return card.category == "personal_growth" || card.category == "life_direction"
        }
      }
      if let card = filtered.randomElement() {
        return card
      }
    }
    return InspirationData.cards.randomElement() ?? InspirationCard(
      id: "fallback",
      title: "灵感火花",
      question: "此刻有什么在呼唤你？",
      reflection: "允许自己停顿，与内心的声音进行一场温柔的对话。",
      tags: ["inspiration", "reflection"],
      emotionalTone: "探寻中",
      category: "philosophy_and_existence"
    )
  }
}

public final class MockTemplateService: TemplateServiceProtocol {
  public init() {}

  public func availableTemplates() async -> [ConstellationTemplate] {
    ConstellationTemplateData.templates
  }

  public func template(withId id: String) async -> ConstellationTemplate? {
    ConstellationTemplateData.templates.first { $0.id == id }
  }
}

public final class MockPreferenceService: PreferenceServiceProtocol {
  public init(configuration: AIConfiguration? = nil) {
    storedConfiguration = configuration
  }

  private var storedConfiguration: AIConfiguration?

  public func loadAIConfiguration() async -> AIConfiguration? {
    storedConfiguration
  }

  public func saveAIConfiguration(_ config: AIConfiguration) async throws {
    storedConfiguration = config
  }
}

public final class MockSoundService: SoundServiceProtocol {
  public init() {}

  public func preload() {}
  public func play(_ sound: SoundEffect) {}
  public func stop(_ sound: SoundEffect) {}
  public func startAmbient() {}
  public func stopAmbient() {}
}

public final class MockHapticService: HapticServiceProtocol {
  public init() {}

  public func impact(_ style: HapticImpactStyle) {}
  public func selectionChanged() {}
}

public final class MockResourceService: ResourceServiceProtocol {
  public init() {}

  public func resolveImageURL(named: String) -> URL? { nil }

  public func loadJSONResource<T>(_ name: String, as type: T.Type) throws -> T where T : Decodable {
    throw NSError(domain: "MockResourceService", code: -1)
  }
}

extension MockAIService: @unchecked Sendable {}
extension MockInspirationService: @unchecked Sendable {}
extension MockTemplateService: @unchecked Sendable {}
extension MockPreferenceService: @unchecked Sendable {}
extension MockSoundService: @unchecked Sendable {}
extension MockHapticService: @unchecked Sendable {}
extension MockResourceService: @unchecked Sendable {}
