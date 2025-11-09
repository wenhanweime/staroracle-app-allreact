import Foundation
import StarOracleCore

public enum ConstellationTemplateData {
  public static let templates: [ConstellationTemplate] = [
    ConstellationTemplate(
      id: "aries",
      name: "Aries",
      chineseName: "白羊座",
      description: "勇敢的开拓者，充满激情与活力",
      element: .fire,
      stars: [
        TemplateStar(
          id: "aries-1",
          x: 0,
          y: 0,
          size: 4,
          brightness: 1.0,
          question: "我如何发现自己的勇气？",
          answer: "勇气如火星般燃烧，在行动中点燃，在挑战中壮大。",
          tags: ["courage", "leadership", "action", "passion", "initiative"],
          primaryCategory: mapCategory("personal_growth"),
          emotionalTone: mapTone("positive"),
          questionType: questionType("我如何发现自己的勇气？"),
          suggestedFollowUp: followUp(for: mapCategory("personal_growth")),
          isMainStar: true
        ),
        TemplateStar(
          id: "aries-2",
          x: -8,
          y: 5,
          size: 3,
          brightness: 0.8,
          question: "如何成为更好的领导者？",
          answer: "真正的领导者如北极星，不是最亮的，却为他人指引方向。",
          tags: ["leadership", "guidance", "responsibility", "vision"],
          primaryCategory: mapCategory("life_direction"),
          emotionalTone: mapTone("contemplative"),
          questionType: questionType("如何成为更好的领导者？"),
          suggestedFollowUp: followUp(for: mapCategory("life_direction"))
        ),
        TemplateStar(
          id: "aries-3",
          x: 8,
          y: -3,
          size: 2.5,
          brightness: 0.7,
          question: "我的激情在哪里？",
          answer: "激情如恒星核心的聚变，从内心深处释放无穷能量。",
          tags: ["passion", "energy", "motivation", "drive"],
          primaryCategory: mapCategory("personal_growth"),
          emotionalTone: mapTone("seeking"),
          questionType: questionType("我的激情在哪里？"),
          suggestedFollowUp: followUp(for: mapCategory("personal_growth"))
        ),
        TemplateStar(
          id: "aries-4",
          x: 3,
          y: 8,
          size: 2,
          brightness: 0.6,
          question: "如何开始新的征程？",
          answer: "每个新开始都是宇宙的重新创造，勇敢迈出第一步。",
          tags: ["new_beginnings", "adventure", "courage", "change"],
          primaryCategory: mapCategory("life_direction"),
          emotionalTone: mapTone("positive"),
          questionType: questionType("如何开始新的征程？"),
          suggestedFollowUp: followUp(for: mapCategory("life_direction"))
        )
      ],
      connections: [
        TemplateConnection(
          id: "aries-1-2",
          fromStarId: "aries-1",
          toStarId: "aries-2",
          strength: 0.8,
          sharedTags: ["leadership", "courage"]
        ),
        TemplateConnection(
          id: "aries-1-3",
          fromStarId: "aries-1",
          toStarId: "aries-3",
          strength: 0.7,
          sharedTags: ["passion", "energy"]
        ),
        TemplateConnection(
          id: "aries-2-4",
          fromStarId: "aries-2",
          toStarId: "aries-4",
          strength: 0.6,
          sharedTags: ["leadership", "new_beginnings"]
        )
      ],
      centerX: 25,
      centerY: 30,
      scale: 1.0
    ),
    ConstellationTemplate(
      id: "taurus",
      name: "Taurus",
      chineseName: "金牛座",
      description: "稳重的建设者，追求美好与安全",
      element: .earth,
      stars: [
        TemplateStar(
          id: "taurus-1",
          x: 0,
          y: 0,
          size: 4,
          brightness: 1.0,
          question: "如何建立稳定的生活？",
          answer: "稳定如大地般深厚，在耐心与坚持中慢慢积累。",
          tags: ["stability", "security", "patience", "persistence"],
          primaryCategory: mapCategory("wellbeing"),
          emotionalTone: mapTone("contemplative"),
          questionType: questionType("如何建立稳定的生活？"),
          suggestedFollowUp: followUp(for: mapCategory("wellbeing")),
          isMainStar: true
        ),
        TemplateStar(
          id: "taurus-2",
          x: -6,
          y: -4,
          size: 3,
          brightness: 0.8,
          question: "什么是真正的财富？",
          answer: "真正的财富不在金库，而在心灵的富足与关系的深度。",
          tags: ["wealth", "abundance", "values", "material"],
          primaryCategory: mapCategory("material"),
          emotionalTone: mapTone("contemplative"),
          questionType: questionType("什么是真正的财富？"),
          suggestedFollowUp: followUp(for: mapCategory("material"))
        ),
        TemplateStar(
          id: "taurus-3",
          x: 7,
          y: 6,
          size: 2.5,
          brightness: 0.7,
          question: "如何欣赏生活中的美？",
          answer: "美如花朵在感恩的土壤中绽放，用心感受每个瞬间。",
          tags: ["beauty", "appreciation", "senses", "gratitude"],
          primaryCategory: mapCategory("wellbeing"),
          emotionalTone: mapTone("positive"),
          questionType: questionType("如何欣赏生活中的美？"),
          suggestedFollowUp: followUp(for: mapCategory("wellbeing"))
        ),
        TemplateStar(
          id: "taurus-4",
          x: 2,
          y: -8,
          size: 2,
          brightness: 0.6,
          question: "如何保持内心的平静？",
          answer: "平静如深山古井，不因外界波动而失去内在的宁静。",
          tags: ["peace", "calm", "stability", "inner_strength"],
          primaryCategory: mapCategory("wellbeing"),
          emotionalTone: mapTone("contemplative"),
          questionType: questionType("如何保持内心的平静？"),
          suggestedFollowUp: followUp(for: mapCategory("wellbeing"))
        )
      ],
      connections: [
        TemplateConnection(
          id: "taurus-1-2",
          fromStarId: "taurus-1",
          toStarId: "taurus-2",
          strength: 0.7,
          sharedTags: ["stability", "security"]
        ),
        TemplateConnection(
          id: "taurus-1-4",
          fromStarId: "taurus-1",
          toStarId: "taurus-4",
          strength: 0.8,
          sharedTags: ["stability", "peace"]
        ),
        TemplateConnection(
          id: "taurus-3-4",
          fromStarId: "taurus-3",
          toStarId: "taurus-4",
          strength: 0.6,
          sharedTags: ["peace", "appreciation"]
        )
      ],
      centerX: 75,
      centerY: 25,
      scale: 1.0
    )
  ]
}

private func mapTone(_ tone: String) -> [String] {
  switch tone {
  case "positive":
    return ["充满希望的"]
  case "contemplative":
    return ["思考的"]
  case "seeking":
    return ["探寻中"]
  case "neutral":
    return ["中性的"]
  default:
    return ["探寻中"]
  }
}

private func mapCategory(_ category: String) -> String {
  switch category {
  case "relationships":
    return "relationships"
  case "personal_growth":
    return "personal_growth"
  case "life_direction":
    return "career_and_purpose"
  case "wellbeing":
    return "emotional_wellbeing"
  case "material":
    return "daily_life"
  case "creative":
    return "creativity_and_passion"
  case "existential":
    return "philosophy_and_existence"
  default:
    return "philosophy_and_existence"
  }
}

private func questionType(_ question: String) -> String {
  let lower = question.lowercased()
  if lower.contains("为什么") || lower.contains("why") || lower.contains("是否") || lower.contains("是不是") {
    return "探索型"
  } else if lower.contains("如何") || lower.contains("how") || lower.contains("方法") || lower.contains("steps") {
    return "实用型"
  } else if lower.contains("什么") || lower.contains("who") || lower.contains("where") {
    return "事实型"
  }
  return "探索型"
}

private func followUp(for category: String) -> String {
  switch category {
  case "relationships":
    return "这种关系模式在你生活的其他方面是否也有体现？"
  case "personal_growth":
    return "你觉得是什么阻碍了你在这方面的进一步成长？"
  case "career_and_purpose":
    return "如果没有任何限制，你理想中的职业道路是什么样的？"
  case "emotional_wellbeing":
    return "这种情绪是从什么时候开始的，有没有特定的触发点？"
  case "philosophy_and_existence":
    return "这个信念对你日常生活的决策有什么影响？"
  case "creativity_and_passion":
    return "你上一次完全沉浸在创造性活动中是什么时候？那感觉如何？"
  case "daily_life":
    return "这个日常习惯如何影响了你的整体生活质量？"
  default:
    return "关于这个话题，你还有什么更深层次的感受或想法？"
  }
}

