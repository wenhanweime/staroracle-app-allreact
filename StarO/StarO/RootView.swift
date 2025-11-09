import SwiftUI
import StarOracleCore
import StarOracleFeatures
import StarOracleServices
import StarOracleUIComponents

struct RootView: View {
  @EnvironmentObject private var environment: AppEnvironment
  @EnvironmentObject private var starStore: StarStore
  @EnvironmentObject private var galaxyStore: GalaxyStore
  @EnvironmentObject private var conversationStore: ConversationStore

  @State private var activePane: ActivePane = .home
  @State private var selectedStar: Star?

  var body: some View {
    GeometryReader { geometry in
      let width = geometry.size.width
      let menuWidth = min(360, width * 0.8)
      let collectionWidth = min(420, width)

      ZStack(alignment: .leading) {
        GalaxyBackgroundView()
          .environmentObject(galaxyStore)
          .ignoresSafeArea()

        homePane
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .offset(x: contentOffset(for: width))
          .scaleEffect(activePane == .home ? 1 : 0.92, anchor: .center)
          .animation(.spring(response: 0.4, dampingFraction: 0.85), value: activePane)
          .disabled(activePane != .home)

        if activePane == .menu {
          DrawerMenuView(
            onClose: { snapTo(.home) },
            onOpenTemplate: {},
            onOpenCollection: { snapTo(.collection) },
            onOpenAIConfig: {},
            onOpenInspiration: {},
            onSwitchSession: { id in environment.switchSession(to: id) },
            onCreateSession: { title in environment.createSession(title: title) },
            onRenameSession: { id, title in environment.renameSession(id: id, title: title) },
            onDeleteSession: { id in environment.deleteSession(id: id) }
          )
          .frame(width: menuWidth, alignment: .leading)
          .frame(maxHeight: .infinity, alignment: .top)
          .padding(.leading, 24)
          .transition(.move(edge: .leading))
        }

        if activePane == .collection {
          StarCollectionPane(
            constellationStars: starStore.constellation.stars,
            inspirationStars: starStore.inspirationStars,
            onBack: { snapTo(.home) }
          )
          .frame(width: collectionWidth, alignment: .trailing)
          .frame(maxHeight: .infinity)
          .transition(.move(edge: .trailing))
          .frame(maxWidth: .infinity, alignment: .trailing)
        }
      }
      .overlay(alignment: .top) {
        topBar
          .padding(.top, 12)
          .frame(height: 60, alignment: .center)
      }
    }
  }

  private var homePane: some View {
    ScrollView {
      VStack(spacing: 20) {
        Text("StarOracle Native")
          .font(.title)
          .foregroundStyle(.white)

        summarySection
        latestStarsSection
      }
      .padding(.top, 96)
      .padding(.horizontal, 24)
      .padding(.bottom, 40)
    }
  }

  private var summarySection: some View {
    VStack(spacing: 12) {
      Text("概览")
        .font(.headline)
        .foregroundStyle(.white)
      HStack(spacing: 16) {
        summaryTile(title: "星卡", value: starStore.constellation.stars.count)
        summaryTile(title: "灵感", value: starStore.inspirationStars.count)
        summaryTile(title: "会话", value: conversationStore.listSessions().count)
      }
    }
    .frame(maxWidth: .infinity)
    .padding()
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
  }

  private func summaryTile(title: String, value: Int) -> some View {
    VStack(spacing: 4) {
      Text("\(value)")
        .font(.title2.bold())
        .foregroundStyle(.white)
      Text(title)
        .font(.caption)
        .foregroundStyle(.white.opacity(0.7))
    }
    .frame(maxWidth: .infinity)
  }

  private var latestStarsSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("最新星卡")
        .font(.headline)
        .foregroundStyle(.white)
      if starStore.constellation.stars.isEmpty {
        Text("暂无星卡")
          .foregroundStyle(.white.opacity(0.6))
      } else {
        ForEach(Array(starStore.constellation.stars.suffix(5)).reversed()) { star in
          VStack(alignment: .leading, spacing: 6) {
            Text(star.question)
              .font(.subheadline.weight(.medium))
              .foregroundStyle(.white)
            if !star.answer.isEmpty {
              Text(star.answer)
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.8))
            }
          }
          .padding()
          .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
          .onTapGesture { selectedStar = star }
        }
      }
    }
    .sheet(item: $selectedStar) { star in
      StarDetailSheet(star: star) { selectedStar = nil }
    }
  }

  private var topBar: some View {
    HStack {
      headerMenuButton
      Spacer()
      headerTitle
      Spacer()
      headerStarButton
    }
    .padding(.horizontal, 24)
  }

  private var headerMenuButton: some View {
    Button(action: { togglePane(.menu) }) {
      Image(systemName: "line.3.horizontal")
        .font(.system(size: 16, weight: .medium))
        .foregroundStyle(.white.opacity(activePane == .menu ? 1 : 0.7))
        .frame(width: 36, height: 36)
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    .buttonStyle(.plain)
  }

  private var headerStarButton: some View {
    Button(action: { togglePane(.collection) }) {
      StarRayIconView(size: 18)
        .frame(width: 36, height: 36)
        .foregroundStyle(.white.opacity(activePane == .collection ? 1 : 0.7))
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    .buttonStyle(.plain)
  }

  private var headerTitle: some View {
    HStack(spacing: 6) {
      Text("星谕")
        .font(.system(size: 18, weight: .semibold, design: .serif))
        .foregroundStyle(.white)
      Text("(StarOracle)")
        .font(.caption)
        .foregroundStyle(.white.opacity(0.7))
    }
  }

  private func contentOffset(for width: CGFloat) -> CGFloat {
    switch activePane {
    case .home:
      return 0
    case .menu:
      return width * 0.5
    case .collection:
      return -width * 0.5
    }
  }

  private func snapTo(_ pane: ActivePane) {
    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
      activePane = pane
    }
  }

  private func togglePane(_ pane: ActivePane) {
    if activePane == pane {
      snapTo(.home)
    } else {
      snapTo(pane)
    }
  }

  private enum ActivePane {
    case menu
    case home
    case collection
  }
}
