import SwiftUI
import StarOracleCore
import StarOracleFeatures

struct StarCollectionSheet: View {
  @EnvironmentObject private var starStore: StarStore
  @Environment(\.dismiss) private var dismiss

  @State private var searchText: String = ""
  @State private var showOnlySpecial = false
  @State private var flipped: Set<String> = []

  private var filteredStars: [Star] {
    starStore.constellation.stars
      .filter { star in
        (!showOnlySpecial || star.isSpecial) &&
        (searchText.isEmpty || star.question.localizedCaseInsensitiveContains(searchText) || star.answer.localizedCaseInsensitiveContains(searchText))
      }
      .sorted(by: { $0.createdAt > $1.createdAt })
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 12) {
        filterHeader
        if filteredStars.isEmpty {
          VStack(spacing: 12) {
            Image(systemName: "sparkles")
              .font(.largeTitle)
              .foregroundStyle(.secondary)
            Text("暂时还没有符合条件的星卡")
              .foregroundStyle(.secondary)
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
          ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 16)], spacing: 16) {
              ForEach(filteredStars) { star in
                StarCardCell(star: star, flipped: flipped.contains(star.id)) {
                  toggleFlip(for: star.id)
                }
              }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
          }
        }
      }
      .navigationTitle("星卡收藏")
      .toolbar {
        ToolbarItem(placement: .automatic) {
          Button("关闭") { dismiss() }
        }
      }
    }
  }

  private var filterHeader: some View {
    VStack(spacing: 8) {
      TextField("搜索问题或回答", text: $searchText)
        .textFieldStyle(.roundedBorder)
      Toggle(isOn: $showOnlySpecial) {
        Label("只显示特殊星卡", systemImage: "star.fill")
      }
      .toggleStyle(.switch)
    }
    .padding(.horizontal, 16)
  }

  private func toggleFlip(for id: String) {
    if flipped.contains(id) {
      flipped.remove(id)
    } else {
      flipped.insert(id)
    }
  }
}

private struct StarCardCell: View {
  let star: Star
  let flipped: Bool
  let onTap: () -> Void

  @State private var isTapped = false

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 18)
        .fill(Color.black.opacity(0.6))
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 8)
      VStack(alignment: .leading, spacing: 10) {
        HStack {
          Text(star.isSpecial ? "★" : "☆")
            .foregroundStyle(star.isSpecial ? Color.yellow : Color.white.opacity(0.5))
          Spacer()
          Text(star.createdAt.formatted(date: .abbreviated, time: .omitted))
            .font(.caption2)
            .foregroundStyle(.white.opacity(0.5))
        }
        Spacer(minLength: 0)
        Text(flipped ? star.answer : star.question)
          .font(.footnote)
          .foregroundStyle(.white)
          .lineLimit(6)
        Spacer(minLength: 0)
        HStack {
          Text(categoryLabel)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.white.opacity(0.15))
            .clipShape(Capsule())
          Spacer()
          Text(flipped ? "查看提问" : "查看回答")
            .font(.caption2)
            .foregroundStyle(.white.opacity(0.6))
        }
      }
      .padding(16)
    }
    .frame(height: 180)
    .rotation3DEffect(
      .degrees(flipped ? 180 : 0),
      axis: (x: 0, y: 1, z: 0)
    )
    .animation(.spring(duration: 0.45, bounce: 0.4), value: flipped)
    .onTapGesture { onTap() }
  }

  private var categoryLabel: String {
    switch star.primaryCategory {
    case "relationships": return "关系"
    case "personal_growth": return "成长"
    case "career_and_purpose": return "事业"
    case "emotional_wellbeing": return "情绪"
    case "creativity_and_passion": return "创造"
    case "daily_life": return "日常"
    default: return "探索"
    }
  }
}
