import SwiftUI
import StarOracleCore

struct StarDetailSheet: View {
  let star: Star
  var onDismiss: () -> Void

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          Text(star.question)
            .font(.title3.weight(.semibold))
          VStack(alignment: .leading, spacing: 10) {
            section(title: "星语回应", icon: "sparkles") {
              Text(star.answer.isEmpty ? "星语正在收集回应…" : star.answer)
            }
            if let summary = star.cardSummary, !summary.isEmpty {
              section(title: "摘要", icon: "note.text") {
                Text(summary)
              }
            }
            if !star.tags.isEmpty {
              section(title: "标签", icon: "tag") {
                TagGrid(tags: star.tags)
              }
            }
            section(title: "洞察", icon: "chart.bar") {
              VStack(alignment: .leading, spacing: 6) {
                if let insight = star.insightLevel {
                  Text("洞察等级：\(insight.description) — \(insight.value)")
                }
                if let category = readableCategory(star.primaryCategory) {
                  Text("主题类别：\(category)")
                }
                if let follow = star.suggestedFollowUp, !follow.isEmpty {
                  Text("建议追问：\(follow)")
                }
              }
            }
          }
          .padding(18)
          .background(.ultraThinMaterial)
          .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .padding(20)
      }
      .navigationTitle("星卡详情")
      .toolbar {
        ToolbarItem(placement: .automatic) {
          Button("完成") { onDismiss() }
        }
      }
    }
  }

  private func section<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Label(title, systemImage: icon)
        .font(.subheadline.weight(.medium))
        .foregroundStyle(.primary)
      content()
        .font(.footnote)
        .foregroundColor(.primary.opacity(0.85))
    }
  }

  private func readableCategory(_ category: String) -> String? {
    switch category {
    case "relationships": return "人际关系"
    case "personal_growth": return "自我成长"
    case "career_and_purpose": return "事业与目标"
    case "emotional_wellbeing": return "情绪福祉"
    case "creativity_and_passion": return "创造与热情"
    case "daily_life": return "日常生活"
    case "philosophy_and_existence": return "哲学与存在"
    default: return nil
    }
  }
}

private struct TagGrid: View {
  let tags: [String]

  private var columns: [GridItem] {
    [GridItem(.adaptive(minimum: 80), spacing: 8, alignment: .leading)]
  }

  var body: some View {
    LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
      ForEach(tags, id: \.self) { tag in
        Text(tag)
          .font(.caption2)
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(Color.secondary.opacity(0.15))
          .clipShape(Capsule())
      }
    }
  }
}
