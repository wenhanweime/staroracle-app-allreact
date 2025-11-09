import SwiftUI
import StarOracleCore

struct StarCollectionOverlay: View {
  @Binding var isPresented: Bool
  let constellationStars: [Star]
  let inspirationStars: [Star]

  @State private var searchText = ""
  @State private var filter: Filter = .all
  @State private var flippedIds = Set<String>()
  @State private var visibleCount = 18

  private let batchSize = 12

  var body: some View {
    ZStack {
      Color.black.opacity(0.85)
        .ignoresSafeArea()
        .onTapGesture {
          withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            isPresented = false
          }
        }

      VStack(spacing: 0) {
        header
        Divider().overlay(Color.white.opacity(0.08))
        controls
        Divider().overlay(Color.white.opacity(0.05))
        gridContent
      }
      .frame(maxWidth: 1100, maxHeight: 720)
      .background(
        RoundedRectangle(cornerRadius: 32, style: .continuous)
          .fill(Color(red: 13/255, green: 18/255, blue: 30/255).opacity(0.96))
          .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
              .stroke(Color.white.opacity(0.08), lineWidth: 1)
          )
      )
      .padding(.horizontal, 24)
      .transition(.scale.combined(with: .opacity))
    }
    .onChange(of: isPresented) { _, newValue in
      if newValue {
        visibleCount = 18
      }
    }
  }

  private var header: some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text("集星")
          .font(.system(size: 24, weight: .semibold, design: .serif))
          .foregroundStyle(.white)
        Text("Star Collection — 精选星卡与灵感记录")
          .font(.footnote)
          .foregroundStyle(.white.opacity(0.6))
      }
      Spacer()
      Text("\(filteredStars.count) stars")
        .font(.caption)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.08), in: Capsule())
      Button {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
          isPresented = false
        }
      } label: {
        Image(systemName: "xmark")
          .font(.headline)
          .padding(12)
          .background(Color.white.opacity(0.1), in: Circle())
      }
      .buttonStyle(.plain)
    }
    .padding(.horizontal, 32)
    .padding(.vertical, 20)
  }

  private var controls: some View {
    HStack(spacing: 16) {
      HStack {
        Image(systemName: "magnifyingglass")
        TextField("Search your stars...", text: $searchText)
          .textInputAutocapitalization(.never)
      }
      .padding(12)
      .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 20))
      .overlay(
        RoundedRectangle(cornerRadius: 20)
          .stroke(Color.white.opacity(0.08), lineWidth: 1)
      )

      Spacer()

      Picker("Filter", selection: $filter) {
        ForEach(Filter.allCases, id: \.self) { filter in
          Text(filter.label).tag(filter)
        }
      }
      .pickerStyle(.segmented)
      .frame(maxWidth: 260)
    }
    .padding(.horizontal, 32)
    .padding(.vertical, 16)
  }

  private var gridContent: some View {
    ScrollView {
      LazyVGrid(columns: [
        GridItem(.adaptive(minimum: 260), spacing: 20)
      ], spacing: 20) {
        ForEach(displayedStars) { star in
          StarCollectionCard(
            star: star,
            flipped: flippedIds.contains(star.id)
          ) {
            toggleFlip(for: star.id)
          }
          .onAppear {
            if star.id == displayedStars.last?.id {
              loadMore()
            }
          }
        }
      }
      .padding(.horizontal, 32)
      .padding(.vertical, 24)

      if visibleCount < filteredStars.count {
        ProgressView("加载更多星卡...")
          .tint(.white)
          .padding(.bottom, 28)
      } else if filteredStars.isEmpty {
        VStack(spacing: 12) {
          Image(systemName: "sparkles")
            .font(.largeTitle)
          Text("没有匹配的星卡")
            .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, minHeight: 240)
      }
    }
  }

  private var mergedStars: [Star] {
    var unique = [String: Star]()
    (inspirationStars + constellationStars).forEach { star in
      unique[star.id] = star
    }
    return unique.values.sorted(by: { $0.createdAt > $1.createdAt })
  }

  private var filteredStars: [Star] {
    mergedStars.filter { star in
      switch filter {
      case .all:
        return matchesSearch(star)
      case .special:
        return star.isSpecial && matchesSearch(star)
      case .recent:
        guard let days = Calendar.current.dateComponents([.day], from: star.createdAt, to: Date()).day else {
          return false
        }
        return days <= 7 && matchesSearch(star)
      }
    }
  }

  private var displayedStars: [Star] {
    Array(filteredStars.prefix(visibleCount))
  }

  private func matchesSearch(_ star: Star) -> Bool {
    guard !searchText.isEmpty else { return true }
    return star.question.localizedCaseInsensitiveContains(searchText) ||
    star.answer.localizedCaseInsensitiveContains(searchText)
  }

  private func toggleFlip(for id: String) {
    if flippedIds.contains(id) {
      flippedIds.remove(id)
    } else {
      flippedIds.insert(id)
    }
  }

  private func loadMore() {
    guard visibleCount < filteredStars.count else { return }
    let next = min(filteredStars.count, visibleCount + batchSize)
    withAnimation(.easeOut(duration: 0.35)) {
      visibleCount = next
    }
  }

  enum Filter: CaseIterable {
    case all, special, recent

    var label: String {
      switch self {
      case .all: return "All"
      case .special: return "Special"
      case .recent: return "Recent"
      }
    }
  }
}

private struct StarCollectionCard: View {
  let star: Star
  let flipped: Bool
  let onTap: () -> Void

  private var gradient: LinearGradient {
    if star.isSpecial {
      return LinearGradient(
        colors: [Color.purple.opacity(0.8), Color.black.opacity(0.6)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    }
    return LinearGradient(
      colors: [Color.blue.opacity(0.4), Color.black.opacity(0.7)],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 26, style: .continuous)
        .fill(gradient)
        .overlay(
          RoundedRectangle(cornerRadius: 26, style: .continuous)
            .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.35), radius: 20, x: 0, y: 15)

      VStack(alignment: .leading, spacing: 12) {
        HStack {
          if star.isSpecial {
            Label("Special", systemImage: "star.fill")
              .font(.caption2)
              .padding(.horizontal, 10)
              .padding(.vertical, 4)
              .background(Color.yellow.opacity(0.2), in: Capsule())
          }
          Spacer()
          Text(star.createdAt.formatted(date: .abbreviated, time: .shortened))
            .font(.caption2)
            .foregroundStyle(.white.opacity(0.7))
        }

        Text(flipped ? star.answer : star.question)
          .font(.system(.body, design: .serif))
          .foregroundStyle(.white)
          .multilineTextAlignment(.leading)
          .lineLimit(5)
          .frame(maxWidth: .infinity, alignment: .leading)

        Spacer()

        HStack {
          Label(categoryLabel, systemImage: "circle.grid.cross")
            .font(.caption2)
            .foregroundStyle(.white.opacity(0.8))
          Spacer()
          Button {
            onTap()
          } label: {
            Text(flipped ? "查看提问" : "查看回答")
              .font(.caption)
              .padding(.horizontal, 12)
              .padding(.vertical, 6)
              .background(Color.white.opacity(0.12), in: Capsule())
          }
          .buttonStyle(.plain)
        }
      }
      .padding(24)
    }
    .frame(height: 220)
    .rotation3DEffect(
      .degrees(flipped ? 180 : 0),
      axis: (x: 0, y: 1, z: 0)
    )
    .animation(.spring(response: 0.6, dampingFraction: 0.75), value: flipped)
    .onTapGesture {
      onTap()
    }
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
