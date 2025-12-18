import SwiftUI
import StarOracleCore
import StarOracleFeatures

struct StarDetailSheet: View {
  let star: Star
  var onDismiss: () -> Void

  @EnvironmentObject private var starStore: StarStore

  @State private var didLoadEnergy = false
  @State private var isLoadingEnergy = false
  @State private var energyDay: String?
  @State private var energyRemaining: Int?

  @State private var isUpgrading = false
  @State private var alertMessage: String?
  @State private var isCardFlipped: Bool = false

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          StarCardView(
            star: displayStar,
            isFlipped: isCardFlipped,
            onFlip: { isCardFlipped.toggle() }
          )
          .aspectRatio(0.7, contentMode: .fit)
          .frame(maxWidth: 360)
          .frame(maxWidth: .infinity, alignment: .center)

          if canShowEvolveControls {
            HStack(spacing: 12) {
              energyBadge
              Spacer()
              upgradeButton
            }
          }

          Text(displayStar.question)
            .font(.title3.weight(.semibold))
          VStack(alignment: .leading, spacing: 10) {
            section(title: "星语回应", icon: "sparkles") {
              Text(displayStar.answer.isEmpty ? "星语正在收集回应…" : displayStar.answer)
            }
            if let summary = displayStar.cardSummary, !summary.isEmpty {
              section(title: "摘要", icon: "note.text") {
                Text(summary)
              }
            }
            if !displayStar.tags.isEmpty {
              section(title: "标签", icon: "tag") {
                TagGrid(tags: displayStar.tags)
              }
            }
            section(title: "洞察", icon: "chart.bar") {
              VStack(alignment: .leading, spacing: 6) {
                if let insight = displayStar.insightLevel {
                  Text("洞察等级：\(insight.description) — \(insight.value)")
                }
                if let category = readableCategory(displayStar.primaryCategory) {
                  Text("主题类别：\(category)")
                }
                if let follow = displayStar.suggestedFollowUp, !follow.isEmpty {
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
      .task { await loadEnergyIfNeeded() }
      .alert("提示", isPresented: alertPresented) {
        Button("好的", role: .cancel) { alertMessage = nil }
      } message: {
        Text(alertMessage ?? "")
      }
    }
  }

  private var displayStar: Star {
    if let matched = starStore.constellation.stars.first(where: { $0.id == star.id }) {
      return matched
    }
    if let matched = starStore.inspirationStars.first(where: { $0.id == star.id }) {
      return matched
    }
    return star
  }

  private var canShowEvolveControls: Bool {
    guard SupabaseRuntime.loadConfig() != nil else { return false }
    guard UUID(uuidString: displayStar.id) != nil else { return false }
    guard !displayStar.isTransient, !displayStar.isTemplate else { return false }
    return true
  }

  private var currentInsightLevel: Int {
    max(1, min(5, displayStar.insightLevel?.value ?? 1))
  }

  private var isAtMaxLevel: Bool {
    currentInsightLevel >= 5
  }

  private var resolvedEnergyRemaining: Int? {
    guard let energyRemaining else { return nil }
    return max(0, energyRemaining)
  }

  private var upgradeDisabled: Bool {
    if isUpgrading { return true }
    if isAtMaxLevel { return true }
    if let remaining = resolvedEnergyRemaining, remaining <= 0 { return true }
    return false
  }

  private var alertPresented: Binding<Bool> {
    Binding(
      get: { alertMessage != nil },
      set: { newValue in
        if !newValue { alertMessage = nil }
      }
    )
  }

  private var energyBadge: some View {
    HStack(spacing: 6) {
      Image(systemName: "bolt.fill")
      if isLoadingEnergy {
        ProgressView()
          .controlSize(.mini)
      } else if let remaining = resolvedEnergyRemaining {
        Text("\(remaining)")
      } else {
        Text("--")
      }
    }
    .font(.footnote.weight(.semibold))
    .foregroundStyle(.primary)
    .padding(.horizontal, 12)
    .padding(.vertical, 8)
    .background(.ultraThinMaterial, in: Capsule())
    .accessibilityLabel("能量余额")
    .accessibilityValue("\(resolvedEnergyRemaining ?? 0)")
  }

  private var upgradeButton: some View {
    Button {
      Task { await upgradeStarIfPossible() }
    } label: {
      HStack(spacing: 8) {
        if isUpgrading {
          ProgressView()
            .controlSize(.small)
        } else {
          Image(systemName: "arrow.up.circle.fill")
        }
        Text(isAtMaxLevel ? "已满级" : "升级")
      }
      .font(.footnote.weight(.semibold))
    }
    .buttonStyle(.borderedProminent)
    .disabled(upgradeDisabled)
    .accessibilityHint("消耗 1 点能量提升星卡等级")
  }

  private func loadEnergyIfNeeded() async {
    guard canShowEvolveControls else { return }
    guard !didLoadEnergy else { return }
    didLoadEnergy = true
    isLoadingEnergy = true
    defer { isLoadingEnergy = false }

    do {
      let energy = try await EnergyService.getEnergy()
      energyDay = energy.day
      energyRemaining = energy.remaining
    } catch {
      NSLog("⚠️ StarDetailSheet.get-energy | error=%@", error.localizedDescription)
    }
  }

  private func upgradeStarIfPossible() async {
    guard canShowEvolveControls else { return }
    guard !isUpgrading else { return }
    if isAtMaxLevel {
      alertMessage = "已是最高等级，无需升级。"
      return
    }

    isUpgrading = true
    defer { isUpgrading = false }

    do {
      let response = try await StarEvolveService.upgradeByButton(starId: displayStar.id)
      if let energy = response.energy {
        energyDay = energy.day
        energyRemaining = energy.remaining
      }

      if let changed = response.changed, !changed {
        alertMessage = "星卡等级未变化。"
      }

      if let row = await StarsService.fetchStarById(displayStar.id) {
        let updated = StarsService.toCoreStar(row: row)
        await MainActor.run {
          starStore.upsertConstellationStar(updated)
        }
      }
    } catch let error as StarEvolveService.EvolveError {
      if case let .http(_, code, message, energy) = error {
        if let energy {
          energyDay = energy.day
          energyRemaining = energy.remaining
        }
        if code == "EV07" {
          let day = (energyDay?.isEmpty == false ? energyDay : nil)
          alertMessage = day == nil ? "能量不足，明天登录可领取 +5。" : "能量不足（\(day!)）。明天登录可领取 +5。"
          return
        }
        alertMessage = "\(code)：\(message)"
        return
      }
      alertMessage = error.localizedDescription
    } catch {
      alertMessage = error.localizedDescription
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
