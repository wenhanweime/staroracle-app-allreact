import SwiftUI
import StarOracleCore

struct PersonalizedInspirationCandidatesPanel: View {
  let items: [PersonalizedInspirationCandidate]

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(spacing: 8) {
        Text("为你定制")
          .font(.system(size: 12, weight: .semibold))
          .foregroundStyle(Color(hex: "#8A5FBD"))
        Text("3 条候选")
          .font(.system(size: 11, weight: .regular))
          .foregroundStyle(.white.opacity(0.55))
        Spacer()
      }

      ForEach(items.prefix(3)) { item in
        VStack(alignment: .leading, spacing: 6) {
          HStack(spacing: 8) {
            Text(kindLabel(item.kind))
              .font(.system(size: 10, weight: .semibold))
              .foregroundStyle(.white.opacity(0.75))
              .padding(.horizontal, 8)
              .padding(.vertical, 3)
              .background(Color.white.opacity(0.08), in: Capsule())
            Text(item.title)
              .font(.system(size: 12, weight: .semibold))
              .foregroundStyle(.white.opacity(0.92))
              .lineLimit(1)
            Spacer(minLength: 0)
          }

          Text(item.content)
            .font(.system(size: 12, weight: .regular))
            .foregroundStyle(.white.opacity(0.72))
            .lineLimit(3)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
        .overlay(
          RoundedRectangle(cornerRadius: 14)
            .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
      }
    }
    .padding(12)
    .background(Color.black.opacity(0.35), in: RoundedRectangle(cornerRadius: 18))
    .overlay(
      RoundedRectangle(cornerRadius: 18)
        .stroke(Color.white.opacity(0.08), lineWidth: 1)
    )
  }

  private func kindLabel(_ raw: String) -> String {
    switch raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
    case "concept":
      return "概念"
    case "action":
      return "行动"
    case "quote":
      return "哲思"
    case "question":
      return "提问"
    case "experiment":
      return "小实验"
    case "script":
      return "脚本"
    default:
      return "提示"
    }
  }
}

