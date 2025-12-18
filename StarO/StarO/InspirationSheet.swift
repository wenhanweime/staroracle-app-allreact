import SwiftUI
import StarOracleCore
import StarOracleFeatures

struct InspirationSheet: View {
  @EnvironmentObject private var starStore: StarStore
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      List {
        Section {
          Button {
            Task {
              let remoteCard: InspirationCard?
              if SupabaseRuntime.loadConfig() != nil {
                remoteCard = await StarService.pluckInspiration()
              } else {
                remoteCard = nil
              }

              await MainActor.run {
                if let remoteCard {
                  starStore.presentInspirationCard(remoteCard)
                } else {
                  _ = starStore.drawInspirationCard(region: nil)
                }
              }
            }
          } label: {
            Label("抽取灵感卡", systemImage: "moon.stars")
          }
        }

        Section("筛选") {
          Picker("类别", selection: $selectedCategory) {
            Text("全部").tag("all")
            Text("情绪").tag("emotion")
            Text("关系").tag("relation")
            Text("成长").tag("growth")
          }
          .pickerStyle(.segmented)
        }

        Section("灵感记录") {
          if filteredStars.isEmpty {
            Text("暂无灵感卡记录")
              .foregroundStyle(.secondary)
          } else {
            ForEach(filteredStars) { star in
              VStack(alignment: .leading, spacing: 6) {
                Text(star.question)
                  .font(.subheadline)
                Text(star.answer)
                  .font(.caption)
                  .foregroundStyle(.secondary)
                HStack {
                  Button("用此灵感提问") {
                    Task { try? await starStore.addStar(question: star.question, at: nil) }
                  }
                  Button("详情") {
                    activeStar = star
                  }
                }
                .font(.caption)
              }
              .padding(.vertical, 4)
            }
          }
        }
      }
      .navigationTitle("灵感卡")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("关闭") { dismiss() }
        }
      }
      .sheet(item: $activeStar) { star in
        StarDetailSheet(star: star) { activeStar = nil }
      }
    }
  }

  @State private var selectedCategory: String = "all"
  @State private var activeStar: Star?

  private var filteredStars: [Star] {
    let all = Array(starStore.inspirationStars.reversed())
    switch selectedCategory {
    case "emotion":
      return all.filter { $0.primaryCategory == "emotional_wellbeing" }
    case "relation":
      return all.filter { $0.primaryCategory == "relationships" }
    case "growth":
      return all.filter { $0.primaryCategory == "personal_growth" || $0.primaryCategory == "career_and_purpose" }
    default:
      return all
    }
  }
}
