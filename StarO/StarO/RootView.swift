import SwiftUI
import Combine
#if os(iOS)
import UIKit
#endif
import StarOracleCore
import StarOracleFeatures
import StarOracleServices
import StarOracleUIComponents

struct RootView: View {
  @EnvironmentObject private var environment: AppEnvironment
  @EnvironmentObject private var starStore: StarStore
  @EnvironmentObject private var chatStore: ChatStore
  @EnvironmentObject private var galaxyStore: GalaxyStore
  @EnvironmentObject private var conversationStore: ConversationStore
  @State private var showingTemplateSheet = false
  @State private var chatInput: String = ""
  @State private var isSendingChat = false
  @State private var selectedStar: Star?
  @State private var showingCollection = false
  @State private var showingDrawer = false
  @State private var showingAIConfig = false
  @State private var showingChatOverlay = false
  @State private var showingInspiration = false
  @State private var chatStatusMessage: String?
  @State private var chatErrorMessage: String?
  private let headerHeight: CGFloat = 120

  var body: some View {
    ZStack(alignment: .top) {
      GalaxyBackgroundView()
        .environmentObject(galaxyStore)
        .ignoresSafeArea()

      NavigationStack {
        ScrollView {
          VStack(spacing: 24) {
            header
            constellationSection
            constellationSummary
            actionButtons
            quickAccessButtons
            inspirationSection
            starListSection
            chatPreview
            floatingChatButton
          }
          .padding(24)
        }
        .padding(.top, headerHeight + 40)
        .background(
          LinearGradient(
            colors: [Color.black, Color.blue.opacity(0.4)],
            startPoint: .top,
            endPoint: .bottom
          )
          .ignoresSafeArea()
        )
        .sheet(isPresented: $showingTemplateSheet) {
          TemplatePickerView()
            .environmentObject(environment)
            .environmentObject(starStore)
        }
        .sheet(item: $selectedStar) { star in
          StarDetailSheet(star: star) { selectedStar = nil }
        }
        .sheet(isPresented: $showingAIConfig) {
          AIConfigSheet()
            .environmentObject(environment)
        }
        .sheet(isPresented: $showingInspiration) {
          InspirationSheet()
            .environmentObject(starStore)
        }
        .navigationBarHidden(true)
      }
      sideUtilityOverlay
        .zIndex(1)

      if showingDrawer {
        ZStack(alignment: .leading) {
          Color.black.opacity(0.45)
            .ignoresSafeArea()
            .onTapGesture { toggleDrawer(false) }
          DrawerMenuView(
            onClose: { toggleDrawer(false) },
          onOpenTemplate: {
            toggleDrawer(false)
            showingTemplateSheet = true
          },
          onOpenCollection: {
            toggleDrawer(false)
            showingCollection = true
          },
          onOpenAIConfig: {
            toggleDrawer(false)
            showingAIConfig = true
          },
          onOpenInspiration: {
            toggleDrawer(false)
            showingInspiration = true
          },
          onSwitchSession: { id in
            environment.switchSession(to: id)
          },
          onCreateSession: { title in
            environment.createSession(title: title)
          },
          onRenameSession: { id, title in
            environment.renameSession(id: id, title: title)
          },
          onDeleteSession: { id in
            environment.deleteSession(id: id)
          }
          )
          .frame(maxWidth: 360)
          .frame(maxHeight: .infinity, alignment: .top)
          .padding(.vertical, 24)
          .transition(.move(edge: .leading).combined(with: .opacity))
        }
        .zIndex(4)
      }

      if showingChatOverlay {
        ChatOverlayPanel(
          messages: chatStore.messages.suffix(10),
          input: $chatInput,
          isSending: isSendingChat,
          statusMessage: chatStatusMessage,
          errorMessage: chatErrorMessage,
          onSend: sendChat,
          onClose: { showingChatOverlay = false }
        )
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .zIndex(2)
      }

      if showingCollection {
        StarCollectionOverlay(
          isPresented: $showingCollection,
          constellationStars: starStore.constellation.stars,
          inspirationStars: starStore.inspirationStars
        )
        .transition(.opacity.combined(with: .scale))
        .zIndex(5)
      }
    }
    .safeAreaInset(edge: .top, spacing: 0) {
      cosmicHeaderBar
        .zIndex(3)
    }
  }

  private var constellationSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("星图预览")
          .font(.headline)
          .foregroundStyle(.white)
        Spacer()
        if let template = starStore.templateInfo {
          Text("模板：\(template.name)")
            .font(.caption)
            .foregroundStyle(.white.opacity(0.7))
        }
      }
      ConstellationView(
        stars: starStore.constellation.stars,
        connections: starStore.constellation.connections,
        highlightId: starStore.highlightedStarId
      ) { star in
        selectedStar = star
        starStore.viewStar(id: star.id)
      }
      .frame(height: 220)
    }
    .frame(maxWidth: .infinity)
  }

  private var header: some View {
    VStack(spacing: 8) {
      Text("宇宙正在苏醒")
        .font(.title2.weight(.semibold))
        .foregroundStyle(.white)
      Text("Swift 原生版本正在构建中，先与星语打个招呼吧。")
        .font(.callout)
        .foregroundStyle(Color.white.opacity(0.7))
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity)
    .glassBackground(RoundedRectangle(cornerRadius: 24))
  }

  private var constellationSummary: some View {
    VStack(spacing: 12) {
      Text("当前星图")
        .font(.headline)
        .foregroundStyle(.white)
      HStack(spacing: 24) {
        summaryTile(title: "星卡", value: "\(starStore.constellation.stars.count)")
        summaryTile(title: "灵感", value: "\(starStore.inspirationStars.count)")
        summaryTile(title: "连线", value: "\(starStore.constellation.connections.count)")
      }
    }
    .frame(maxWidth: .infinity)
    .padding()
    .glassBackground(RoundedRectangle(cornerRadius: 24))
  }

  private func summaryTile(title: String, value: String) -> some View {
    VStack(spacing: 6) {
      Text(title)
        .font(.caption)
        .foregroundStyle(.white.opacity(0.7))
      Text(value)
        .font(.title3.bold())
        .foregroundStyle(.white)
    }
    .frame(maxWidth: .infinity)
  }

  private var actionButtons: some View {
    VStack(spacing: 12) {
      Button {
        Task {
          try? await starStore.addStar(question: "此刻的你最想探索什么？", at: nil)
        }
      } label: {
        Label("生成星卡", systemImage: "sparkles")
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.borderedProminent)

      Button {
        _ = starStore.drawInspirationCard(region: nil)
      } label: {
        Label("抽取灵感卡", systemImage: "moon.stars")
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.bordered)
    }
    .padding()
    .glassBackground(RoundedRectangle(cornerRadius: 24))
  }

  private var quickAccessButtons: some View {
    HStack(spacing: 12) {
      Button {
        showingTemplateSheet = true
      } label: {
        Label("模板库", systemImage: "hexagon")
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.bordered)

      Button {
        showingCollection = true
      } label: {
        Label("星卡收藏", systemImage: "rectangle.grid.2x2")
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.bordered)

      Button {
        showingInspiration = true
      } label: {
        Label("灵感卡", systemImage: "sparkles")
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.bordered)
    }
  }

  private var inspirationSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("灵感提示")
        .font(.headline)
        .foregroundStyle(.white)
      if let card = starStore.currentInspirationCard {
        inspirationCardView(title: card.title, question: card.question, reflection: card.reflection)
      } else if let star = starStore.inspirationStars.last {
        inspirationCardView(title: star.cardSummary ?? "灵感火花", question: star.question, reflection: star.answer)
      } else {
        Text("抽一张灵感卡，看看宇宙为你点亮了什么。")
          .font(.footnote)
          .foregroundStyle(.white.opacity(0.7))
      }
      InspirationHistoryList(stars: starStore.inspirationStars.suffix(5)) { question in
        Task { try? await starStore.addStar(question: question, at: nil) }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var starListSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("星卡记录")
        .font(.headline)
        .foregroundStyle(.white)
      if starStore.constellation.stars.isEmpty {
        Text("还没有星卡，先生成一张吧。")
          .font(.footnote)
          .foregroundStyle(.white.opacity(0.7))
      } else {
        VStack(spacing: 12) {
          ForEach(Array(starStore.constellation.stars.suffix(5)).reversed()) { star in
            VStack(alignment: .leading, spacing: 6) {
              Text(star.question)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
              Text(star.answer.isEmpty ? "等待星语回应…" : star.answer)
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.8))
              HStack(spacing: 8) {
                if let category = star.primaryCategory.split(separator: "_").first {
                  Text(String(category).uppercased())
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.12))
                    .clipShape(Capsule())
                }
                Text(star.emotionalTone.first ?? "探寻中")
                  .font(.caption2)
                  .foregroundStyle(.white.opacity(0.6))
              }
            }
            .padding()
            .glassBackground(RoundedRectangle(cornerRadius: 20))
          }
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private func inspirationCardView(title: String, question: String, reflection: String) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title)
        .font(.caption)
        .foregroundStyle(.white.opacity(0.6))
      Text(question)
        .font(.subheadline.weight(.medium))
        .foregroundStyle(.white)
      Text(reflection)
        .font(.footnote)
        .foregroundStyle(.white.opacity(0.8))
    }
    .padding()
    .glassBackground(RoundedRectangle(cornerRadius: 20))
  }

  private var chatPreview: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("对话预览")
        .font(.headline)
        .foregroundStyle(.white)
      if chatStore.messages.isEmpty {
        Text("对话还未开始。可以在这里向星语提问。")
          .font(.footnote)
          .foregroundStyle(.white.opacity(0.7))
      } else {
        VStack(alignment: .leading, spacing: 12) {
          ForEach(Array(chatStore.messages.suffix(5))) { message in
            VStack(alignment: .leading, spacing: 4) {
              Text(message.isUser ? "你" : "星语")
                .font(.caption)
                .foregroundStyle(message.isUser ? Color.blue.opacity(0.8) : Color.purple.opacity(0.8))
              Text(message.text)
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.9))
              if message.isStreaming {
                ProgressView()
                  .progressViewStyle(.circular)
                  .scaleEffect(0.6)
                  .tint(.white.opacity(0.6))
              }
            }
            .padding(12)
            .glassBackground(RoundedRectangle(cornerRadius: 18))
          }
        }
      }
      chatComposer
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var chatComposer: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 12) {
        TextField("向星语提问…", text: $chatInput)
          .textFieldStyle(.roundedBorder)
          .disabled(isSendingChat)
        Button {
          sendChat()
        } label: {
          if isSendingChat {
            ProgressView()
              .progressViewStyle(.circular)
              .tint(.white)
          } else {
            Image(systemName: "paperplane.fill")
              .foregroundStyle(.white)
          }
        }
        .buttonStyle(.borderless)
        .disabled(chatInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSendingChat)
      }
      Text("发送问题后，星语会以 Mock AI 的方式回应，用于演示流式聊天体验。")
        .font(.caption2)
        .foregroundStyle(.white.opacity(0.6))
    }
  }

  private var floatingChatButton: some View {
    HStack {
      Spacer()
      Button {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
          showingChatOverlay.toggle()
        }
      } label: {
        Image(systemName: showingChatOverlay ? "chevron.down" : "message.fill")
          .padding()
          .background(.ultraThinMaterial)
          .clipShape(Circle())
          .shadow(radius: 10)
      }
    }
  }

  private func sendChat() {
    let trimmed = chatInput.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty, !isSendingChat else { return }

    chatStatusMessage = "星语正在回应..."
    chatErrorMessage = nil
    provideFeedback(success: true)
    chatStore.addUserMessage(trimmed)
    chatInput = ""

    Task {
      await MainActor.run { isSendingChat = true }

      let history = await MainActor.run { chatStore.messages }
      let configuration = await environment.preferenceService.loadAIConfiguration() ?? AIConfiguration(
        provider: "mock",
        apiKey: "",
        endpoint: URL(string: "https://example.com/mock")!,
        model: "mock-gpt"
      )

      let messageId = await MainActor.run { chatStore.beginStreamingAIMessage(initial: "") }
      var buffer = ""
      let stream = environment.aiService.streamResponse(
        for: trimmed,
        configuration: configuration,
        context: AIRequestContext(history: history, metadata: [:])
      ) 

      do {
        for try await chunk in stream {
          buffer.append(chunk)
          await MainActor.run {
            chatStore.updateStreamingMessage(id: messageId, text: buffer)
          }
        }
      } catch {
        await MainActor.run {
          chatStore.updateStreamingMessage(id: messageId, text: "未能获取星语回应，请稍后再试。")
          chatErrorMessage = "发送失败，请检查配置或稍后再试。"
          chatStatusMessage = nil
          provideFeedback(success: false)
        }
      }

      await MainActor.run {
        chatStore.finalizeStreamingMessage(id: messageId)
        isSendingChat = false
        if chatErrorMessage == nil {
          chatStatusMessage = "星语已完成回应"
        }
      }

      try? await chatStore.generateConversationTitle()
    }
  }

  private func toggleDrawer(_ target: Bool? = nil) {
    let nextState = target ?? !showingDrawer
    guard nextState != showingDrawer else { return }
    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
      showingDrawer = nextState
    }
  }

  private var cosmicHeaderBar: some View {
    HStack {
      headerMenuButton
      Spacer()
      headerStarButton
    }
    .frame(height: 48)
    .padding(.horizontal, 16)
    .background(
      Color.black.opacity(0.1)
        .background(.ultraThinMaterial)
        .blur(radius: 10)
    )
    .overlay { headerTitle }
  }

  private var headerMenuButton: some View {
    Button(action: { toggleDrawer() }) {
      Image(systemName: "line.3.horizontal")
        .font(.system(size: 16, weight: .medium))
        .foregroundStyle(.white)
        .frame(width: 32, height: 32)
    }
    .buttonStyle(.plain)
  }

  private var headerTitle: some View {
    HStack(spacing: 6) {
      Text("星谕")
        .font(.system(size: 20, weight: .semibold, design: .serif))
        .foregroundStyle(.white)
      Text("(StarOracle)")
        .font(.caption)
        .foregroundStyle(.white.opacity(0.7))
    }
  }

  private var headerStarButton: some View {
    Button(action: { showingCollection = true }) {
      StarRayIconView(size: 18)
        .frame(width: 32, height: 32)
    }
    .buttonStyle(.plain)
    .accessibilityLabel("打开星星收藏册")
  }


  private func provideFeedback(success: Bool) {
    #if os(iOS)
    if success {
      UIImpactFeedbackGenerator(style: .light).impactOccurred()
    } else {
      UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
    #endif
  }

  private var sideUtilityOverlay: some View {
    GeometryReader { proxy in
      let shouldShowUtilities = proxy.size.width > 900
      ZStack(alignment: .top) {
        if shouldShowUtilities {
          HStack(alignment: .top, spacing: 0) {
            leftUtilityColumn
            Spacer()
            rightUtilityColumn
          }
          .padding(.horizontal, 28)
          .padding(.top, headerHeight + 110)
        }
      }
      .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
    }
  }

  private var leftUtilityColumn: some View {
    VStack(alignment: .leading, spacing: 16) {
      sideActionCard(
        icon: "book.fill",
        title: "星卡收藏",
        subtitle: "\(starStore.constellation.stars.count) 颗星",
        mirrored: false
      ) { showingCollection = true }

      sideActionCard(
        icon: "sparkles",
        title: starStore.hasTemplate ? "当前模板" : "选择星座",
        subtitle: starStore.templateInfo?.name ?? "尚未选择",
        mirrored: false
      ) { showingTemplateSheet = true }
    }
    .frame(width: 230, alignment: .leading)
  }

  private var rightUtilityColumn: some View {
    VStack(alignment: .trailing, spacing: 16) {
      Button {
        showingCollection = true
      } label: {
        VStack(spacing: 8) {
          ZStack {
            Circle()
              .fill(
                AngularGradient(
                  gradient: Gradient(colors: [.purple, .pink, .blue, .purple]),
                  center: .center
                )
              )
              .frame(width: 72, height: 72)
              .shadow(color: .purple.opacity(0.4), radius: 18, x: 0, y: 10)
            Image(systemName: "star.circle.fill")
              .font(.title)
              .foregroundStyle(.white)
          }
          Text("Star Collection")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
          Text("启动灵感宇宙")
            .font(.caption2)
            .foregroundStyle(.white.opacity(0.65))
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 18)
        .background(
          RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(Color.white.opacity(0.04))
            .overlay(
              RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        )
      }
      .buttonStyle(.plain)

      sideActionCard(
        icon: "slider.horizontal.3",
        title: "AI 配置",
        subtitle: "Prompt & Keys",
        mirrored: true
      ) { showingAIConfig = true }
    }
    .frame(width: 230, alignment: .trailing)
  }

  private func sideActionCard(
    icon: String,
    title: String,
    subtitle: String,
    mirrored: Bool,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      let iconView = ZStack {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
          .fill(
            LinearGradient(
              colors: [.white.opacity(0.18), .white.opacity(0.02)],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )
          .frame(width: 48, height: 48)
          .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
              .stroke(Color.white.opacity(0.15), lineWidth: 1)
          )
        Image(systemName: icon)
          .font(.headline)
          .foregroundStyle(.white)
      }

      let textStack = VStack(alignment: mirrored ? .trailing : .leading, spacing: 4) {
        Text(title)
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(.white)
        Text(subtitle)
          .font(.caption2)
          .foregroundStyle(.white.opacity(0.7))
      }

      HStack(spacing: 14) {
        if mirrored {
          textStack
          iconView
        } else {
          iconView
          textStack
        }
      }
      .frame(maxWidth: .infinity, alignment: mirrored ? .trailing : .leading)
      .padding(20)
      .background(
        RoundedRectangle(cornerRadius: 26, style: .continuous)
          .fill(
            LinearGradient(
              colors: [
                Color.white.opacity(0.08),
                Color.white.opacity(0.02)
              ],
              startPoint: mirrored ? .bottomTrailing : .topLeading,
              endPoint: mirrored ? .topLeading : .bottomTrailing
            )
          )
          .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
              .stroke(Color.white.opacity(0.1), lineWidth: 1)
          )
      )
      .shadow(color: .black.opacity(0.35), radius: 16, x: 0, y: 14)
    }
    .buttonStyle(.plain)
  }
}

private struct InspirationHistoryList: View {
  let stars: ArraySlice<Star>
  let onUse: (String) -> Void

  var body: some View {
    if stars.isEmpty { EmptyView() }
    else {
      VStack(alignment: .leading, spacing: 8) {
        Text("灵感记录")
          .font(.caption)
          .foregroundStyle(.white.opacity(0.6))
        ForEach(Array(stars.reversed())) { star in
          HStack(alignment: .top, spacing: 8) {
            Circle()
              .fill(Color.white.opacity(0.15))
              .frame(width: 8, height: 8)
              .padding(.top, 6)
            VStack(alignment: .leading, spacing: 4) {
              Text(star.question)
                .font(.caption)
                .foregroundStyle(.white)
              Button("用此灵感提问") {
                onUse(star.question)
              }
              .font(.caption2)
            }
            Spacer()
          }
        }
      }
    }
  }
}

#if DEBUG && canImport(SwiftUI)
#Preview {
  let environment = AppEnvironment()
  RootView()
    .environmentObject(environment)
    .environmentObject(environment.starStore)
    .environmentObject(environment.chatStore)
}
#endif

private struct ChatOverlayPanel: View {
  let messages: ArraySlice<ChatMessage>
  @Binding var input: String
  let isSending: Bool
  let statusMessage: String?
  let errorMessage: String?
  let onSend: () -> Void
  let onClose: () -> Void
  @State private var lastMessageID: String?
  @FocusState private var isInputFocused: Bool
  @State private var keyboardHeight: CGFloat = 0

  var body: some View {
    VStack(spacing: 12) {
      HStack {
        Text("即时对话")
          .font(.headline)
        Spacer()
        Button(action: onClose) {
          Image(systemName: "xmark")
        }
      }
      ScrollViewReader { proxy in
        ScrollView {
          VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(messages), id: \.id) { message in
              VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                  .padding(10)
                  .background(message.isUser ? Color.blue.opacity(0.6) : Color.white.opacity(0.1))
                  .clipShape(RoundedRectangle(cornerRadius: 12))
                  .foregroundStyle(.white)
                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                  .font(.caption2)
                  .foregroundStyle(.white.opacity(0.5))
              }
              .frame(maxWidth: .infinity, alignment: message.isUser ? .trailing : .leading)
              .id(message.id)
            }
          }
        }
        .onChange(of: messages.map(\.id).last) { oldValue, newValue in
          if let id = newValue {
            withAnimation {
              proxy.scrollTo(id, anchor: .bottom)
            }
          }
        }
      }
      if let statusMessage {
        Label(statusMessage, systemImage: "sparkles")
          .font(.caption)
          .foregroundStyle(.white.opacity(0.7))
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      if let errorMessage {
        Label(errorMessage, systemImage: "exclamationmark.triangle")
          .font(.caption)
          .foregroundStyle(.red)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      chatInputBar
    }
    .padding(20)
    .frame(maxWidth: .infinity)
    .background(.ultraThinMaterial)
    .clipShape(RoundedRectangle(cornerRadius: 28))
    .padding(.horizontal)
    .padding(.bottom, 16 + keyboardHeight)
    .shadow(radius: 20)
    .frame(maxHeight: .infinity, alignment: .bottom)
    .onReceive(keyboardPublisher) { height in
      withAnimation(.easeOut(duration: 0.2)) {
        keyboardHeight = height
      }
    }
  }

  @ViewBuilder
  private var chatInputBar: some View {
    HStack(spacing: 12) {
      TextField("输入内容", text: $input)
        .textFieldStyle(.roundedBorder)
        .focused($isInputFocused)
      Button {
        onSend()
      } label: {
        if isSending {
          ProgressView()
        } else {
          Image(systemName: "paperplane.fill")
        }
      }
      .buttonStyle(.borderedProminent)
      .disabled(isSending || input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
    .onAppear { isInputFocused = true }
  }

  private var keyboardPublisher: AnyPublisher<CGFloat, Never> {
    #if os(iOS)
    KeyboardObserver.shared.$keyboardHeight.eraseToAnyPublisher()
    #else
    Just(0).eraseToAnyPublisher()
    #endif
  }
}
