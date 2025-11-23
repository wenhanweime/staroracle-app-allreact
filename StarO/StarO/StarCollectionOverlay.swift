import SwiftUI
import StarOracleCore

enum StarCollectionFilter: CaseIterable {
  case all, special, recent

  var label: String {
    switch self {
    case .all: return "All"
    case .special: return "Special"
    case .recent: return "Recent"
    }
  }
}

struct StarCollectionOverlay: View {
  @Binding var isPresented: Bool
  let constellationStars: [Star]
  let inspirationStars: [Star]

  @State private var searchText = ""
  @State private var filter: StarCollectionFilter = .all
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
        overlayHeader
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
        searchText = ""
        filter = .all
        flippedIds = []
      }
    }
  }

  private var overlayHeader: some View {
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
        ForEach(StarCollectionFilter.allCases, id: \.self) { filter in
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
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
      ], spacing: 20) {
        ForEach(displayedStars) { star in
          StarCardView(
            star: star,
            isFlipped: flippedIds.contains(star.id),
            onFlip: { toggleFlip(for: star.id) }
          )
          .aspectRatio(0.7, contentMode: .fit)
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

  private var filteredStars: [Star] {
    filterStars(
      stars: mergedStars(
        constellation: constellationStars,
        inspiration: inspirationStars
      ),
      filter: filter,
      query: searchText
    )
  }

  private var displayedStars: [Star] {
    Array(filteredStars.prefix(visibleCount))
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
}

struct StarCollectionPane: View {
  let constellationStars: [Star]
  let inspirationStars: [Star]
  var onBack: () -> Void

  @State private var searchText = ""
  @State private var filter: StarCollectionFilter = .all
  @State private var flippedIds = Set<String>()
  @State private var visibleCount = 18

  private let batchSize = 18

  var body: some View {
    VStack(spacing: 0) {
      paneHeader
      Divider().overlay(Color.white.opacity(0.08))
      controls
      Divider().overlay(Color.white.opacity(0.05))
      gridContent
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .background(
      LinearGradient(
        colors: [
          Color(red: 9/255, green: 12/255, blue: 20/255),
          Color(red: 12/255, green: 18/255, blue: 32/255)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .ignoresSafeArea()
    )
  }

  private var paneHeader: some View {
    HStack {
      Button {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
          onBack()
        }
      } label: {
        Label("返回首页", systemImage: "chevron.left")
          .font(.footnote.weight(.medium))
          .padding(.horizontal, 14)
          .padding(.vertical, 10)
          .background(Color.white.opacity(0.08), in: Capsule())
      }
      .buttonStyle(.plain)

      Spacer()
      VStack(alignment: .trailing, spacing: 4) {
        Text("Star Collection")
          .font(.title3.weight(.semibold))
          .foregroundStyle(.white)
        Text("\(filteredStars.count) entries")
          .font(.caption)
          .foregroundStyle(.white.opacity(0.7))
      }
    }
    .padding(.horizontal, 32)
    .padding(.top, 56)
    .padding(.bottom, 16)
  }

  private var controls: some View {
    HStack(spacing: 16) {
      HStack {
        Image(systemName: "magnifyingglass")
        TextField("Search your stars...", text: $searchText)
          .textInputAutocapitalization(.never)
      }
      .padding(12)
      .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 18))
      .overlay(
        RoundedRectangle(cornerRadius: 18)
          .stroke(Color.white.opacity(0.08), lineWidth: 1)
      )

      Spacer()

      Picker("Filter", selection: $filter) {
        ForEach(StarCollectionFilter.allCases, id: \.self) { filter in
          Text(filter.label).tag(filter)
        }
      }
      .pickerStyle(.segmented)
      .frame(maxWidth: 260)
    }
    .padding(.horizontal, 32)
    .padding(.bottom, 16)
  }

  private var gridContent: some View {
    ScrollView {
      LazyVGrid(columns: [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
      ], spacing: 20) {
        ForEach(displayedStars) { star in
          StarCardView(
            star: star,
            isFlipped: flippedIds.contains(star.id),
            onFlip: { toggleFlip(for: star.id) }
          )
          .aspectRatio(0.7, contentMode: .fit)
          .onAppear {
            if star.id == displayedStars.last?.id {
              loadMore()
            }
          }
        }
      }
      .padding(.horizontal, 32)
      .padding(.bottom, 32)

      if visibleCount < filteredStars.count {
        ProgressView("加载更多星卡...")
          .tint(.white)
          .padding(.bottom, 40)
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

  private var filteredStars: [Star] {
    filterStars(
      stars: mergedStars(
        constellation: constellationStars,
        inspiration: inspirationStars
      ),
      filter: filter,
      query: searchText
    )
  }

  private var displayedStars: [Star] {
    Array(filteredStars.prefix(visibleCount))
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
}

private func mergedStars(constellation: [Star], inspiration: [Star]) -> [Star] {
  var unique = [String: Star]()
  (inspiration + constellation).forEach { star in
    unique[star.id] = star
  }
  return unique.values.sorted(by: { $0.createdAt > $1.createdAt })
}

private func filterStars(
  stars: [Star],
  filter: StarCollectionFilter,
  query: String
) -> [Star] {
  stars.filter { star in
    let matchesQuery = query.isEmpty ||
    star.question.localizedCaseInsensitiveContains(query) ||
    star.answer.localizedCaseInsensitiveContains(query)

    switch filter {
    case .all:
      return matchesQuery
    case .special:
      return star.isSpecial && matchesQuery
    case .recent:
      guard let days = Calendar.current.dateComponents([.day], from: star.createdAt, to: Date()).day else {
        return false
      }
      return days <= 7 && matchesQuery
    }
  }
}
