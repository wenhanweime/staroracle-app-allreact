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
    guard let first = messages.first(where: { $0.isUser && !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else {
      return "新对话"
    }
    let title = makeHeuristicTitle(from: first.text)
    return title.isEmpty ? "新对话" : title
  }

  public func validate(configuration: AIConfiguration) async throws {}
}

private extension MockAIService {
  func makeHeuristicTitle(from raw: String) -> String {
    var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !text.isEmpty else { return "" }

    text = text.replacingOccurrences(of: "\n", with: " ")
    text = text.replacingOccurrences(of: "\r", with: " ")
    if text.hasPrefix("【灵感卡片】") {
      text = String(text.dropFirst("【灵感卡片】".count))
    }

    // 取第一句（避免把整段长文本塞进标题）
    let sentenceSeparators = CharacterSet(charactersIn: "。！？?!；;\n\r")
    if let firstSentence = text
      .components(separatedBy: sentenceSeparators)
      .map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
      .first(where: { !$0.isEmpty }) {
      text = firstSentence
    }

    // 去掉常见开头口头禅/请求词，让标题更像“短语”
    let prefixes = [
      "请问", "帮我", "麻烦", "能不能", "可不可以", "我想问", "我想", "我觉得", "我现在", "你好", "嗨"
    ]
    for p in prefixes where text.hasPrefix(p) {
      text = String(text.dropFirst(p.count)).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // 去掉模板词（避免“关于…的对话/讨论/聊天”）
    let banned = ["关于", "对话", "聊天", "讨论", "咨询", "提问", "交流"]
    for token in banned {
      text = text.replacingOccurrences(of: token, with: "")
    }

    // 去掉引号与常见标点
    let stripped = text.unicodeScalars.filter { scalar in
      let bannedScalars = CharacterSet(charactersIn: "\"“”‘’《》【】[]（）()，,。.！？?!:：;；—-·•")
      return !bannedScalars.contains(scalar)
    }
    text = String(String.UnicodeScalarView(stripped))
      .trimmingCharacters(in: .whitespacesAndNewlines)

    // 收敛长度
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty { return "" }
    return String(trimmed.prefix(12))
  }
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
