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
  @EnvironmentObject private var chatBridge: NativeChatBridge
  @EnvironmentObject private var authService: AuthService

  @State private var activePane: ActivePane = .home
  @State private var selectedStar: Star?
  @State private var isShowingAccount: Bool = false
  @State private var dragOffset: CGFloat = 0

  var body: some View {
    Group {
      if shouldShowLogin {
        LoginView()
      } else {
        mainContent
      }
    }
  }

  private var shouldShowLogin: Bool {
    SupabaseRuntime.loadProjectConfig() != nil && authService.isAuthenticated != true
  }

  private var mainContent: some View {
    GeometryReader { geometry in
      let width = geometry.size.width
      let menuWidth = min(360, width * 0.8)
      let collectionWidth = min(420, width)

      ZStack(alignment: .leading) {
        GalaxyBackgroundView(isTapEnabled: activePane == .home)
          .environmentObject(galaxyStore)
          .ignoresSafeArea()

        primaryPane
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .offset(x: contentOffset(for: width) + dragOffset)
          .scaleEffect(activePane == .home ? 1 : 0.92, anchor: .center)
          .animation(.spring(response: 0.4, dampingFraction: 0.85), value: activePane)
          .disabled(activePane != .home)

        if activePane == .menu {
          Group {
            DrawerMenuView(
              onClose: { snapTo(.home) },
              onOpenAccount: { openAccount() },
              onOpenServerChat: { chat in environment.openServerChat(chat) },
              onSwitchSession: { id in environment.switchSession(to: id) },
              onRenameSession: { id, title in environment.renameSession(id: id, title: title) },
              onDeleteSession: { id in environment.deleteSession(id: id) }
            )
            .frame(width: menuWidth, alignment: .leading)
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.leading, 24)
            .transition(.move(edge: .leading))

            HStack(spacing: 0) {
              Color.clear
                .frame(width: menuWidth + 24)
                .allowsHitTesting(false)
              Color.black.opacity(0.001)
                .contentShape(Rectangle())
                .onTapGesture { snapTo(.home) }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
          }
          .offset(x: dragOffset)
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
          .offset(x: dragOffset)
        }
      }
      .gesture(
        DragGesture(minimumDistance: 8)
          .onChanged { value in
            guard !galaxyStore.isGeneratingCard else { return }
            handleDragChanged(value.translation.width, width: width)
          }
          .onEnded { value in
            guard !galaxyStore.isGeneratingCard else { return }
            handleDragEnded(value.translation.width, width: width)
          }
      )
      .overlay(
        ChatOverlayHostView(bridge: chatBridge)
          .allowsHitTesting(false)
      )
      .overlay(
        InspirationCardOverlay()
      )

      .onAppear {
        DispatchQueue.main.async {
          environment.bootstrapConversationIfNeeded()
          chatBridge.activateIfNeeded()
          let offset = activePane == .menu ? menuWidth + 24 : 0
          chatBridge.setHorizontalOffset(offset, animated: false)
        }
      }
      .task {
        await environment.syncSupabaseStarsIfNeeded()
      }
      .onChange(of: activePane) { _, newValue in
        DispatchQueue.main.async {
          let offset = newValue == .menu ? menuWidth + 24 : 0
          chatBridge.setHorizontalOffset(offset, animated: true)
        }
      }
      .onReceive(NotificationCenter.default.publisher(for: .chatOverlayOpenStar)) { notification in
        guard let starId = notification.userInfo?["starId"] as? String else { return }
        if SupabaseRuntime.loadConfig() != nil,
           conversationStore.session(id: conversationStore.currentSessionId)?.hasSupabaseConversationStarted == true {
          conversationStore.beginReviewSession(forChatId: conversationStore.currentSessionId)
        }
        snapTo(.collection)
        if let star = findStar(by: starId) {
          selectedStar = star
        }
      }
      .sheet(item: $selectedStar) { star in
        StarDetailSheet(star: star) { selectedStar = nil }
      }
      .sheet(isPresented: $isShowingAccount) {
        AccountView()
      }
    }
  }

  private var primaryPane: some View {
    ZStack(alignment: .top) {
      homePane
      topBar
        .padding(.top, 12)
        .frame(height: 60)
    }
  }

  private var homePane: some View {
    VStack(spacing: 20) {

      
      Spacer()
    }
    .padding(.top, 96)
    .padding(.horizontal, 24)
    .padding(.bottom, 40)
    .frame(maxHeight: .infinity, alignment: .top)
    // 避免中心内容层拦截点击，让银河接收触摸
    .allowsHitTesting(false)
  }





  private var topBar: some View {
    HStack(spacing: 16) {
      headerMenuButton
      Spacer()
      headerTitle
      Spacer()
      headerChatButton
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
    .disabled(galaxyStore.isGeneratingCard)
  }

  private var headerStarButton: some View {
    Button(action: { togglePane(.collection) }) {
      StarRayIconView(size: 18)
        .frame(width: 36, height: 36)
        .foregroundStyle(.white.opacity(activePane == .collection ? 1 : 0.7))
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    .buttonStyle(.plain)
    .disabled(galaxyStore.isGeneratingCard)
  }

  private var headerChatButton: some View {
    let isActive = chatBridge.presentationState != .hidden
    return Button(action: { chatBridge.toggleOverlay(expanded: true) }) {
      Image(systemName: isActive ? "bubble.left.and.bubble.right.fill" : "bubble.left.and.bubble.right")
        .font(.system(size: 16, weight: .medium))
        .foregroundStyle(.white.opacity(isActive ? 1 : 0.7))
        .frame(width: 36, height: 36)
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
      dragOffset = 0
    }
  }

  private func togglePane(_ pane: ActivePane) {
    if activePane == pane {
      snapTo(.home)
    } else {
      snapTo(pane)
    }
  }

  private func findStar(by id: String) -> Star? {
    if let star = starStore.constellation.stars.first(where: { $0.id == id }) { return star }
    if let star = starStore.inspirationStars.first(where: { $0.id == id }) { return star }
    return nil
  }

  private func openAccount() {
    snapTo(.home)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
      isShowingAccount = true
    }
  }

  private func handleDragChanged(_ translation: CGFloat, width: CGFloat) {
    let limit = width * 0.5
    switch activePane {
    case .home:
      dragOffset = max(-limit, min(limit, translation))
    case .menu:
      dragOffset = max(-limit, min(0, translation))
    case .collection:
      dragOffset = max(0, min(limit, translation))
    }
  }

  private func handleDragEnded(_ translation: CGFloat, width: CGFloat) {
    let threshold = width * 0.2
    defer { dragOffset = 0 }

    switch activePane {
    case .home:
      if translation > threshold {
        snapTo(.menu)
      } else if translation < -threshold {
        snapTo(.collection)
      }
    case .menu:
      if translation < -threshold {
        snapTo(.home)
      } else {
        snapTo(.menu)
      }
    case .collection:
      if translation > threshold {
        snapTo(.home)
      } else {
        snapTo(.collection)
      }
    }
  }

  private enum ActivePane {
    case menu
    case home
    case collection
  }
}
