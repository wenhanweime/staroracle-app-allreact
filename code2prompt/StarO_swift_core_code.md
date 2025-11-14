Project Path: StarO/StarO

Source Tree:

```txt
StarO/StarO
├── AIConfigSheet.swift
├── AppEnvironment.swift
├── ChatOverlayHostView.swift
├── ChatOverlayManager.swift
├── ConversationStore.swift
├── NativeChatBridge.swift
├── PreferenceService.swift
├── RootView.swift
├── StarOApp.swift
└── StreamingClient.swift
```

`StarO/StarO/StarOApp.swift`:

```swift
//
//  StarOApp.swift
//  StarO
//
//  Created by pot on 11/8/25.
//

import SwiftUI

@main
struct StarOApp: App {
  @StateObject private var environment = AppEnvironment()

  var body: some Scene {
    WindowGroup {
      RootView()
        .environmentObject(environment)
        .environmentObject(environment.starStore)
        .environmentObject(environment.chatStore)
        .environmentObject(environment.galaxyStore)
        .environmentObject(environment.galaxyGridStore)
        .environmentObject(environment.conversationStore)
        .environmentObject(environment.chatBridge)
    }
  }
}

```

`StarO/StarO/RootView.swift`:

```swift
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

  @State private var activePane: ActivePane = .home
  @State private var selectedStar: Star?
  @State private var dragOffset: CGFloat = 0

  var body: some View {
    GeometryReader { geometry in
      let width = geometry.size.width
      let menuWidth = min(360, width * 0.8)
      let collectionWidth = min(420, width)

      ZStack(alignment: .leading) {
        GalaxyBackgroundView()
          .environmentObject(galaxyStore)
          .ignoresSafeArea()

        primaryPane
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .offset(x: contentOffset(for: width) + dragOffset)
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
      .overlay(
        ChatOverlayHostView(bridge: chatBridge)
          .allowsHitTesting(false)
      )
      .contentShape(Rectangle())
      .gesture(
        DragGesture(minimumDistance: 15)
          .onChanged { value in
            handleDragChanged(value.translation.width, width: width)
          }
          .onEnded { value in
            handleDragEnded(value.translation.width, width: width)
          }
      )
      .onAppear {
        DispatchQueue.main.async {
          environment.bootstrapConversationIfNeeded()
          chatBridge.activateIfNeeded()
          let offset = activePane == .menu ? menuWidth + 24 : 0
          chatBridge.setHorizontalOffset(offset, animated: false)
        }
      }
      .onChange(of: activePane) { _, newValue in
        DispatchQueue.main.async {
          let offset = newValue == .menu ? menuWidth + 24 : 0
          chatBridge.setHorizontalOffset(offset, animated: true)
        }
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

```

`StarO/StarO/ChatOverlayHostView.swift`:

```swift
import SwiftUI
import UIKit

struct ChatOverlayHostView: UIViewRepresentable {
  let bridge: NativeChatBridge

  func makeUIView(context: Context) -> OverlayAnchorView {
    let view = OverlayAnchorView()
    view.bridge = bridge
    return view
  }

  func updateUIView(_ uiView: OverlayAnchorView, context: Context) {
    uiView.bridge = bridge
    uiView.syncBridgeIfNeeded()
  }
}

final class OverlayAnchorView: UIView {
  weak var bridge: NativeChatBridge?

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .clear
    isUserInteractionEnabled = false
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func didMoveToWindow() {
    super.didMoveToWindow()
    syncBridgeIfNeeded()
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    syncBridgeIfNeeded()
  }

  func syncBridgeIfNeeded() {
    guard let bridge, let window = window, let scene = window.windowScene else { return }
    bridge.attach(to: scene)
  }
}

```

`StarO/StarO/AppEnvironment.swift`:

```swift
import Foundation
import StarOracleCore
import StarOracleFeatures
import StarOracleServices

@MainActor
final class AppEnvironment: ObservableObject {
  let aiService: AIServiceProtocol
  let preferenceService: PreferenceServiceProtocol
  let templateService: TemplateServiceProtocol
  let inspirationService: InspirationServiceProtocol
  let starStore: StarStore
  let chatStore: ChatStore
  let galaxyStore: GalaxyStore
  let galaxyGridStore: GalaxyGridStore
  let conversationStore: ConversationStore
  let chatBridge: NativeChatBridge
  private var didBootstrapConversation = false

  init(conversationStore: ConversationStore = .shared) {
    let aiService = LiveAIService()
    let inspirationService = MockInspirationService()
    let templateService = MockTemplateService()
    let preferenceService = LocalPreferenceService()
    let soundService = MockSoundService()
    let hapticService = MockHapticService()

    self.aiService = aiService
    self.preferenceService = preferenceService
    self.templateService = templateService
    self.inspirationService = inspirationService
    starStore = StarStore(
      aiService: aiService,
      inspirationService: inspirationService,
      templateService: templateService,
      preferenceService: preferenceService,
      soundService: soundService,
      hapticService: hapticService
    )

    chatStore = ChatStore(
      aiService: aiService,
      configurationProvider: { await preferenceService.loadAIConfiguration() }
    )

    galaxyStore = GalaxyStore()
    galaxyGridStore = GalaxyGridStore()

    self.conversationStore = conversationStore
    chatBridge = NativeChatBridge(
      chatStore: chatStore,
      conversationStore: conversationStore,
      aiService: aiService,
      preferenceService: preferenceService
    )
  }

  func switchSession(to sessionId: String) {
    guard let session = conversationStore.switchSession(to: sessionId) else { return }
    let messages = conversationStore.messages(forSession: sessionId)
    chatStore.loadMessages(messages, title: session.displayTitle)
  }

  func createSession(title: String?) {
    let session = conversationStore.createSession(title: title)
    chatStore.loadMessages([], title: session.displayTitle)
  }

  func renameSession(id: String, title: String) {
    conversationStore.renameSession(id: id, title: title)
  }

  func deleteSession(id: String) {
    conversationStore.deleteSession(id: id)
    let messages = conversationStore.messages(forSession: nil)
    chatStore.loadMessages(messages, title: conversationStore.currentSession()?.displayTitle)
  }

  func bootstrapConversationIfNeeded() {
    guard !didBootstrapConversation else { return }
    didBootstrapConversation = true
    conversationStore.bootstrapIfNeeded()
    let initialMessages = conversationStore.messages(forSession: nil)
    if !initialMessages.isEmpty {
      chatStore.loadMessages(initialMessages, title: conversationStore.currentSession()?.displayTitle)
    }
  }
}

// MARK: - Live AI Service (OpenAI-compatible)

@MainActor
final class LiveAIService: AIServiceProtocol {
  private let streamingClient = StreamingClient()
  private let fallback = MockAIService()
  private let urlSession: URLSession

  init(urlSession: URLSession = .shared) {
    self.urlSession = urlSession
  }

  func streamResponse(
    for question: String,
    configuration: AIConfiguration,
    context: AIRequestContext
  ) -> AsyncThrowingStream<String, Error> {
    guard Self.isLive(configuration: configuration) else {
      NSLog("ℹ️ LiveAIService.streamResponse | 使用 mock provider=%@", configuration.provider)
      return fallback.streamResponse(for: question, configuration: configuration, context: context)
    }

    NSLog("🎯 LiveAIService.streamResponse | provider=%@ endpoint=%@ model=%@", configuration.provider, configuration.endpoint.absoluteString, configuration.model)
    let messages = makeMessages(for: question, context: context)
    let endpoint = configuration.endpoint.absoluteString
    let apiKey = configuration.apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
    let client = streamingClient

    return AsyncThrowingStream { continuation in
      client.startChatCompletionStream(
        endpoint: endpoint,
        apiKey: apiKey,
        model: configuration.model,
        messages: messages,
        temperature: nil,
        maxTokens: nil,
        onChunk: { chunk in
          continuation.yield(chunk)
        },
        onComplete: { _, error in
          if let error {
            continuation.finish(throwing: error)
          } else {
            continuation.finish()
          }
        }
      )

      continuation.onTermination = { [weak streamingClient] _ in
        streamingClient?.cancel()
      }
    }
  }

  func analyzeStarContent(
    question: String,
    answer: String,
    configuration: AIConfiguration
  ) async throws -> TagAnalysis {
    try await fallback.analyzeStarContent(question: question, answer: answer, configuration: configuration)
  }

  func analyzeAwareness(
    question: String,
    answer: String,
    configuration: AIConfiguration
  ) async throws -> AwarenessInsight {
    try await fallback.analyzeAwareness(question: question, answer: answer, configuration: configuration)
  }

  func generateConversationTitle(
    from messages: [StarOracleCore.ChatMessage],
    configuration: AIConfiguration
  ) async throws -> String {
    try await fallback.generateConversationTitle(from: messages, configuration: configuration)
  }

  func validate(configuration: AIConfiguration) async throws {
    guard Self.isLive(configuration: configuration) else {
      try await fallback.validate(configuration: configuration)
      return
    }

    let request = try makeChatRequest(
      configuration: configuration,
      messages: [
        StreamingClient.Message(role: "user", content: "Hello, can you hear me?")
      ],
      stream: false,
      maxTokens: 12,
      temperature: 0.1
    )

    let (data, response) = try await urlSession.data(for: request)
    guard let http = response as? HTTPURLResponse else {
      throw AIServiceError.invalidResponse
    }
    guard (200..<300).contains(http.statusCode) else {
      let body = String(data: data, encoding: .utf8) ?? ""
      throw AIServiceError.http(status: http.statusCode, body: body)
    }
    guard try LiveAIService.responseContainsChoices(data) else {
      throw AIServiceError.invalidPayload
    }
  }

  private func makeMessages(for question: String, context: AIRequestContext) -> [StreamingClient.Message] {
    var result: [StreamingClient.Message] = []
    if let prompt = context.metadata["systemPrompt"]?.trimmingCharacters(in: .whitespacesAndNewlines),
       !prompt.isEmpty {
      result.append(.init(role: "system", content: prompt))
    }
    for message in context.history {
      let trimmed = message.text.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !trimmed.isEmpty else { continue }
      result.append(.init(role: message.isUser ? "user" : "assistant", content: trimmed))
    }
    if result.filter({ $0.role != "system" }).isEmpty {
      result.append(.init(role: "user", content: question))
    }
    return result
  }

  private func makeChatRequest(
    configuration: AIConfiguration,
    messages: [StreamingClient.Message],
    stream: Bool,
    maxTokens: Int?,
    temperature: Double?
  ) throws -> URLRequest {
    var request = URLRequest(url: configuration.endpoint)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(Self.authHeaderValue(for: configuration.apiKey), forHTTPHeaderField: "Authorization")

    let body = StreamingClient.RequestBody(
      model: configuration.model,
      messages: messages,
      temperature: temperature,
      maxTokens: maxTokens,
      stream: stream
    )
    request.httpBody = try JSONEncoder().encode(body)
    return request
  }

  private static func responseContainsChoices(_ data: Data) throws -> Bool {
    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
       let choices = json["choices"] as? [Any],
       !choices.isEmpty {
      return true
    }
    return false
  }

  private static func isLive(configuration: AIConfiguration) -> Bool {
    guard configuration.provider.lowercased() != "mock" else { return false }
    return !configuration.apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  private static func authHeaderValue(for apiKey: String) -> String {
    let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.lowercased().hasPrefix("bearer ") ? trimmed : "Bearer \(trimmed)"
  }

  private enum AIServiceError: LocalizedError {
    case invalidResponse
    case invalidPayload
    case http(status: Int, body: String)

    var errorDescription: String? {
      switch self {
      case .invalidResponse:
        return "服务器响应不可用。"
      case .invalidPayload:
        return "API 响应格式不正确。"
      case let .http(status, body):
        return "请求失败 (\(status))：\(body)"
      }
    }
  }
}

```

`StarO/StarO/NativeChatBridge.swift`:

```swift
import Foundation
import Combine
import SwiftUI
import UIKit
import StarOracleCore
import StarOracleFeatures
import StarOracleServices

extension ObservableObjectPublisher: @unchecked Sendable {}

@MainActor
final class NativeChatBridge: NSObject, ObservableObject {
  enum PresentationState {
    case hidden
    case collapsed
    case expanded
  }

  nonisolated let objectWillChange = ObservableObjectPublisher()
  private var presentationStateStorage: PresentationState = .hidden
  var presentationState: PresentationState { presentationStateStorage }
  private(set) var isInputDrawerVisible = false
  private var lastErrorMessageStorage: String?
  var lastErrorMessage: String? { lastErrorMessageStorage }

  private let overlayManager = ChatOverlayManager()
  private let inputManager = InputDrawerManager()
  private let chatStore: ChatStore
  private let conversationStore: ConversationStore
  private let aiService: AIServiceProtocol
  private let preferenceService: PreferenceServiceProtocol
  private var cancellables = Set<AnyCancellable>()
  private var streamingTask: Task<Void, Never>?
  private var didActivate = false
  private weak var windowScene: UIWindowScene?
  private weak var registeredBackgroundView: UIView?
  private var pendingEnsureWorkItem: DispatchWorkItem?
  private var pendingPresentationStateWorkItem: DispatchWorkItem?

  init(
    chatStore: ChatStore,
    conversationStore: ConversationStore,
    aiService: AIServiceProtocol,
    preferenceService: PreferenceServiceProtocol
  ) {
    self.chatStore = chatStore
    self.conversationStore = conversationStore
    self.aiService = aiService
    self.preferenceService = preferenceService
    super.init()
    inputManager.delegate = self
    observeChatStore()
    observeOverlayNotifications()
  }

  deinit {
    streamingTask?.cancel()
  }

  func activateIfNeeded() {
    guard !didActivate else {
      ensureInputDrawerVisible()
      configureBackgroundViewIfNeeded()
      return
    }
    didActivate = true
    configureBackgroundViewIfNeeded()
    ensureInputDrawerVisible()
    overlayManager.setConversationTitle(chatStore.conversationTitle)
    overlayManager.updateMessages(chatStore.messages.map(makeOverlayMessage))
  }

  private var pendingInputVisibleWork: DispatchWorkItem?

  func ensureInputDrawerVisible() {
    NSLog("🎯 NativeChatBridge.ensureInputDrawerVisible")
    pendingInputVisibleWork?.cancel()
    let work = DispatchWorkItem { [weak self] in
      guard let self else { return }
      self.inputManager.show(animated: true) { [weak self] success in
        guard let self else { return }
        if success, self.isInputDrawerVisible != true {
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
            self.setInputDrawerVisible(true)
          }
        }
      }
    }
    pendingInputVisibleWork = work
    DispatchQueue.main.async(execute: work)
  }

  func hideInputDrawer() {
    inputManager.hide(animated: true) { [weak self] in
      DispatchQueue.main.async { [weak self] in
        guard let self else { return }
        if self.isInputDrawerVisible == true {
          self.setInputDrawerVisible(false)
        }
      }
    }
  }

  func toggleOverlay(expanded: Bool = true) {
    NSLog("🎯 NativeChatBridge.toggleOverlay expanded=\(expanded) state=\(presentationState)")
    switch presentationState {
    case .hidden:
      openOverlay(expanded: expanded)
    case .collapsed:
      if expanded {
        openOverlay(expanded: true)
      } else {
        hideOverlay()
      }
    case .expanded:
      hideOverlay()
    }
  }

  func openOverlay(expanded: Bool) {
    NSLog("🎯 NativeChatBridge.openOverlay expanded=\(expanded)")
    overlayManager.show(animated: true, expanded: expanded) { [weak self] success in
      guard let self, success else { return }
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) { [weak self] in
        self?.updatePresentationState(expanded ? .expanded : .collapsed)
      }
    }
  }

  func hideOverlay() {
    NSLog("🎯 NativeChatBridge.hideOverlay")
    overlayManager.hide(animated: true) { [weak self] in
      DispatchQueue.main.async { [weak self] in
        self?.updatePresentationState(.hidden)
      }
    }
  }

  func ensureOverlayVisible(collapsed: Bool = true) {
    NSLog("🎯 NativeChatBridge.ensureOverlayVisible collapsed=\(collapsed) current=\(presentationState)")
    pendingEnsureWorkItem?.cancel()
    let work = DispatchWorkItem { [weak self] in
      self?.performEnsureOverlayVisible(collapsed: collapsed)
    }
    pendingEnsureWorkItem = work
    DispatchQueue.main.async(execute: work)
  }

  private func performEnsureOverlayVisible(collapsed: Bool) {
    switch presentationState {
    case .hidden:
      openOverlay(expanded: !collapsed)
    case .collapsed:
      if !collapsed {
        openOverlay(expanded: true)
      }
    case .expanded:
      if collapsed {
        openOverlay(expanded: false)
      }
    }
  }

  func setHorizontalOffset(_ offset: CGFloat, animated: Bool = true) {
    inputManager.setHorizontalOffset(offset, animated: animated)
    overlayManager.setHorizontalOffset(offset, animated: animated)
  }

  func sendMessage(_ text: String) {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    NSLog("🎯 NativeChatBridge.sendMessage text=\(trimmed)")
    if presentationState == .hidden {
      openOverlay(expanded: true)
    }
    chatStore.addUserMessage(trimmed)
    inputManager.setText("")
    setLastErrorMessage(nil)
    startStreaming(for: trimmed)
  }

  private func startStreaming(for question: String) {
    streamingTask?.cancel()
    streamingTask = Task { [weak self] in
      guard let self else { return }
      await self.performStreaming(for: question)
    }
  }

  private func performStreaming(for question: String) async {
    chatStore.setLoading(true)
    overlayManager.setLoading(true)
    let history = chatStore.messages
    let systemPrompt = conversationStore.currentSession()?.systemPrompt ?? ""
    guard let configuration = await preferenceService.loadAIConfiguration() else {
      NSLog("⚠️ NativeChatBridge.performStreaming | 未找到 AI 配置")
      chatStore.setLoading(false)
      overlayManager.setLoading(false)
      setLastErrorMessage("尚未配置 AI 接口，请先在设置中填写。")
      return
    }
    NSLog("🎯 NativeChatBridge.performStreaming | provider=%@ model=%@ endpoint=%@", configuration.provider, configuration.model, configuration.endpoint.absoluteString)
    let messageId = chatStore.beginStreamingAIMessage(initial: "")
    var buffer = ""
    let stream = aiService.streamResponse(
      for: question,
      configuration: configuration,
      context: AIRequestContext(
        history: history,
        metadata: systemPrompt.isEmpty ? [:] : ["systemPrompt": systemPrompt]
      )
    )

    do {
      for try await chunk in stream {
        buffer.append(chunk)
        NSLog("✉️ NativeChatBridge.chunk | len=%d", chunk.count)
        chatStore.updateStreamingMessage(id: messageId, text: buffer)
      }
      NSLog("✅ NativeChatBridge.performStreaming | 完成")
      chatStore.finalizeStreamingMessage(id: messageId)
      chatStore.setLoading(false)
      overlayManager.setLoading(false)
      try? await chatStore.generateConversationTitle()
      setLastErrorMessage(nil)
    } catch {
      NSLog("❌ NativeChatBridge.performStreaming | error=%@", error.localizedDescription)
      chatStore.updateStreamingMessage(id: messageId, text: "未能获取星语回应，请稍后再试。")
      chatStore.finalizeStreamingMessage(id: messageId)
      chatStore.setLoading(false)
      overlayManager.setLoading(false)
      setLastErrorMessage("发送失败：\(error.localizedDescription)")
    }
  }

  private func observeChatStore() {
    chatStore.$messages
      .removeDuplicates()
      .receive(on: DispatchQueue.main)
      .sink { [weak self] messages in
        guard let self else { return }
        let overlayMessages = messages.map(self.makeOverlayMessage)
        self.overlayManager.updateMessages(overlayMessages)
      }
      .store(in: &cancellables)

    chatStore.$isLoading
      .receive(on: DispatchQueue.main)
      .sink { [weak self] loading in
        self?.overlayManager.setLoading(loading)
      }
      .store(in: &cancellables)

    chatStore.$conversationTitle
      .receive(on: DispatchQueue.main)
      .sink { [weak self] title in
        self?.overlayManager.setConversationTitle(title)
      }
      .store(in: &cancellables)
  }

  private func observeOverlayNotifications() {
    NotificationCenter.default.publisher(for: .chatOverlayStateChanged)
      .receive(on: DispatchQueue.main)
      .sink { [weak self] notification in
        guard let self else { return }
        guard let stateValue = notification.userInfo?["state"] as? String else { return }
        DispatchQueue.main.async {
          switch stateValue {
          case "expanded":
            self.updatePresentationState(.expanded)
          case "collapsed":
            self.updatePresentationState(.collapsed)
          case "hidden":
            self.updatePresentationState(.hidden)
          default:
            break
          }
        }
      }
      .store(in: &cancellables)
  }

  private func makeOverlayMessage(_ message: StarOracleCore.ChatMessage) -> OverlayChatMessage {
    OverlayChatMessage(
      id: message.id,
      text: message.text,
      isUser: message.isUser,
      timestamp: message.timestamp.timeIntervalSince1970 * 1000
    )
  }

  private func updatePresentationState(_ newState: PresentationState) {
    guard presentationState != newState else { return }
    pendingPresentationStateWorkItem?.cancel()
    let workItem = DispatchWorkItem { [weak self] in
      guard let self else { return }
      NSLog("🎯 presentationState commit -> \(newState)")
      self.pendingPresentationStateWorkItem = nil
      self.setPresentationStateValue(newState)
    }
    NSLog("🎯 schedule presentationState -> \(newState) | stack:\n\(Thread.callStackSymbols.joined(separator: "\n"))")
    pendingPresentationStateWorkItem = workItem
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.03, execute: workItem)
  }
  
  private func setPresentationStateValue(_ newState: PresentationState) {
    guard presentationStateStorage != newState else { return }
    publishBridgeChange("presentationState -> \(newState)")
    presentationStateStorage = newState
  }

  private func setLastErrorMessage(_ newValue: String?) {
    guard lastErrorMessageStorage != newValue else { return }
    publishBridgeChange("lastErrorMessage changed")
    lastErrorMessageStorage = newValue
  }
  
  private func setInputDrawerVisible(_ visible: Bool) {
    guard isInputDrawerVisible != visible else { return }
    publishBridgeChange("isInputDrawerVisible -> \(visible)")
    isInputDrawerVisible = visible
  }

  private func publishBridgeChange(_ label: String) {
    NSLog("⚠️ NativeChatBridge 即将 publish (\(label)) | stack:\n\(Thread.callStackSymbols.joined(separator: "\n"))")
    objectWillChange.send()
  }

  func attach(to scene: UIWindowScene) {
    let isNewScene = windowScene !== scene
    windowScene = scene
    overlayManager.attach(to: scene)
    inputManager.attach(to: scene)
    if isNewScene {
      registeredBackgroundView = nil
    }
    configureBackgroundViewIfNeeded()
  }

  private func registerBackgroundView(_ view: UIView) {
    overlayManager.setBackgroundView(view)
    registeredBackgroundView = view
  }

  private func configureBackgroundViewIfNeeded() {
    if let view = registeredBackgroundView, view.window != nil {
      return
    }
    let candidateScene = windowScene ?? UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .first { $0.activationState == .foregroundActive || $0.activationState == .foregroundInactive }
    guard let scene = candidateScene,
          let window = scene.windows.first(where: { $0.isKeyWindow }) ?? scene.windows.first,
          let rootView = window.rootViewController?.view else {
      return
    }
    registerBackgroundView(rootView)
  }
}

extension NativeChatBridge: InputDrawerDelegate {
  nonisolated func inputDrawerDidSubmit(_ text: String) {
    NSLog("🎯 NativeChatBridge.inputDrawerDidSubmit text=\(text)")
    Task { @MainActor [weak self] in
      self?.sendMessage(text)
    }
  }

  nonisolated func inputDrawerDidChange(_ text: String) {
    NSLog("🎯 NativeChatBridge.inputDrawerDidChange text=\(text)")
  }

  nonisolated func inputDrawerDidFocus() {
    NSLog("🎯 NativeChatBridge.inputDrawerDidFocus")
  }

  nonisolated func inputDrawerDidBlur() {}
}

```

`StarO/StarO/ConversationStore.swift`:

```swift
import Foundation
import Combine
import StarOracleCore

typealias CoreChatMessage = StarOracleCore.ChatMessage

extension Notification.Name {
  static let conversationStoreChanged = Notification.Name("conversationStoreChanged")
}

@MainActor
final class ConversationStore: ObservableObject {
  static let shared = ConversationStore()
  var __updateSignature: String = ""

  struct Session: Identifiable, Codable, Equatable {
    let id: String
    var title: String
    var systemPrompt: String
    var messages: [PersistMessage]
    var createdAt: Date
    var updatedAt: Date
    var hasCustomTitle: Bool

    var displayTitle: String {
      let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
      return trimmed.isEmpty ? "未命名会话" : trimmed
    }

    var formattedUpdatedAt: String {
      let formatter = DateFormatter()
      formatter.dateStyle = .short
      formatter.timeStyle = .short
      return formatter.string(from: updatedAt)
    }
  }

  struct PersistMessage: Codable, Equatable {
    let id: String
    let text: String
    let isUser: Bool
    let timestamp: Date
  }

  private struct PersistModel: Codable {
    var currentSessionId: String
    var sessions: [Session]
  }

  private var sessionsStorage: [Session] = [] {
    didSet {
      logStateChange("sessions -> \(sessionsStorage.count)")
    }
  }
  private var currentSessionIdStorage: String = "" {
    didSet {
      logStateChange("currentSessionId -> \(currentSessionIdStorage)")
    }
  }

  var sessions: [Session] { sessionsStorage }
  var currentSessionId: String { currentSessionIdStorage }

  private let fileURL: URL
  private var saveTask: Task<Void, Never>?
  private var pendingMessageUpdate: DispatchWorkItem?
  private let stateLoggingEnabled = true
  private var isPublishingEnabled = false
  private var isBootstrapped = false
  private var isPublishScheduled = false

  init(fileURL: URL = ConversationStore.defaultURL()) {
    self.fileURL = fileURL
  }

  // MARK: - Session management

  func listSessions() -> [Session] {
    sessions
  }

  func session(id: String) -> Session? {
    sessions.first(where: { $0.id == id })
  }

  func currentSession() -> Session? {
    session(id: currentSessionId)
  }

  @discardableResult
  func createSession(title: String?) -> Session {
    let session = makeSession(title: title)
    mutateState {
      self.sessionsStorage.insert(session, at: 0)
      self.currentSessionIdStorage = session.id
    }
    scheduleSave()
    return session
  }

  @discardableResult
  func switchSession(to id: String) -> Session? {
    guard sessions.contains(where: { $0.id == id }) else { return nil }
    mutateState {
      self.currentSessionIdStorage = id
    }
    scheduleSave()
    return session(id: id)
  }

  func renameSession(id: String, title: String) {
    guard let index = sessions.firstIndex(where: { $0.id == id }) else { return }
    mutateState {
      self.sessionsStorage[index].title = title
      self.sessionsStorage[index].hasCustomTitle = !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      self.sessionsStorage[index].updatedAt = Date()
    }
    scheduleSave()
  }

  func deleteSession(id: String) {
    guard let index = sessions.firstIndex(where: { $0.id == id }) else { return }
    mutateState {
      let deletingCurrent = self.sessionsStorage[index].id == self.currentSessionIdStorage
      self.sessionsStorage.remove(at: index)
      if deletingCurrent {
        if let first = self.sessionsStorage.first {
          self.currentSessionIdStorage = first.id
        } else {
          let newSession = makeSession(title: "默认会话")
          self.sessionsStorage.insert(newSession, at: 0)
          self.currentSessionIdStorage = newSession.id
        }
      }
    }
    scheduleSave()
  }

  // MARK: - Messages

  func messages(forSession id: String? = nil) -> [CoreChatMessage] {
    let sessionId = id ?? currentSessionId
    guard let session = sessions.first(where: { $0.id == sessionId }) else { return [] }
    return session.messages.map { persist in
      CoreChatMessage(
        id: persist.id,
        text: persist.text,
        isUser: persist.isUser,
        timestamp: persist.timestamp,
        isResponse: !persist.isUser
      )
    }
  }

  func updateCurrentSessionMessages(_ messages: [CoreChatMessage]) {
    pendingMessageUpdate?.cancel()
    let snapshot = messages
    let work = DispatchWorkItem { [weak self] in
      guard let self else { return }
      Task { @MainActor [weak self] in
        self?.performUpdateCurrentSessionMessages(snapshot)
      }
    }
    pendingMessageUpdate = work
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.02, execute: work)
  }

  @MainActor
  private func performUpdateCurrentSessionMessages(_ messages: [CoreChatMessage]) {
    NSLog("🚨 updateCurrentSessionMessages called | stack: \(Thread.callStackSymbols.joined(separator: "\n"))")
    guard let index = sessions.firstIndex(where: { $0.id == currentSessionId }) else { return }
    let converted = messages.map { message in
      PersistMessage(
        id: message.id,
        text: message.text,
        isUser: message.isUser,
        timestamp: message.timestamp
      )
    }
    mutateState {
      self.sessionsStorage[index].messages = converted
      self.sessionsStorage[index].updatedAt = Date()
    }
    scheduleSave()
  }

  var messages: [OverlayChatMessage] {
    messages(forSession: currentSessionId).map { $0.toOverlayMessage() }
  }

  func setMessages(_ list: [OverlayChatMessage]) {
    let converted = list.map { $0.toCoreMessage() }
    updateCurrentSessionMessages(converted)
  }

  func append(_ message: OverlayChatMessage) {
    guard let index = sessions.firstIndex(where: { $0.id == currentSessionId }) else { return }
    var updated = sessions[index].messages
    updated.append(message.toPersistMessage())
    mutateState {
      self.sessionsStorage[index].messages = updated
      self.sessionsStorage[index].updatedAt = Date()
    }
    scheduleSave()
  }

  func replaceLastAssistantText(_ text: String) {
    guard let index = sessions.firstIndex(where: { $0.id == currentSessionId }) else { return }
    var updated = sessions[index].messages
    guard let lastIndex = updated.lastIndex(where: { !$0.isUser }) else { return }
    let target = updated[lastIndex]
    updated[lastIndex] = PersistMessage(id: target.id, text: text, isUser: target.isUser, timestamp: Date())
    mutateState {
      self.sessionsStorage[index].messages = updated
      self.sessionsStorage[index].updatedAt = Date()
    }
    scheduleSave()
  }

  func setSystemPrompt(_ prompt: String, sessionId: String? = nil) {
    guard let index = sessions.firstIndex(where: { $0.id == (sessionId ?? currentSessionId) }) else { return }
    mutateState {
      self.sessionsStorage[index].systemPrompt = prompt
      self.sessionsStorage[index].updatedAt = Date()
    }
    scheduleSave()
  }

  // MARK: - Persistence

  func bootstrapIfNeeded() {
    guard !isBootstrapped else { return }
    performInitialLoad()
    isPublishingEnabled = true
    isBootstrapped = true
  }

  private func performInitialLoad() {
    let model = loadPersistedModel()
    var initialSessions = model?.sessions ?? []
    var initialCurrentId = model?.currentSessionId ?? ""
    var needsSave = false

    if initialSessions.isEmpty {
      let defaultSession = makeSession(title: "默认会话")
      initialSessions = [defaultSession]
      initialCurrentId = defaultSession.id
      needsSave = true
    }

    if initialCurrentId.isEmpty {
      initialCurrentId = initialSessions.first?.id ?? ""
      needsSave = true
    }

    let sessionsSnapshot = initialSessions
    let currentSnapshot = initialCurrentId
    mutateState(sendChange: false) { [sessionsSnapshot, currentSnapshot] in
      self.sessionsStorage = sessionsSnapshot
      self.currentSessionIdStorage = currentSnapshot
    }
    if needsSave {
      scheduleSave()
    }
  }

  private func loadPersistedModel() -> PersistModel? {
    guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
    do {
      let data = try Data(contentsOf: fileURL)
      return try JSONDecoder().decode(PersistModel.self, from: data)
    } catch {
      print("⚠️ ConversationStore load failed: \(error.localizedDescription)")
      return nil
    }
  }

  private func scheduleSave() {
    saveTask?.cancel()
    let snapshot = PersistModel(currentSessionId: currentSessionId, sessions: sessions)
    saveTask = Task.detached(priority: .utility) { [fileURL] in
      try? await Task.sleep(nanoseconds: 200_000_000)
      do {
        let data = try JSONEncoder().encode(snapshot)
        try data.write(to: fileURL, options: .atomic)
        await MainActor.run {
          NotificationCenter.default.post(name: .conversationStoreChanged, object: nil)
        }
      } catch {
        print("⚠️ ConversationStore save failed: \(error.localizedDescription)")
      }
    }
  }

  private func logStateChange(_ label: String) {
    guard stateLoggingEnabled else { return }
    NSLog("🚨 ConversationStore.\(label) | stack:\n\(Thread.callStackSymbols.joined(separator: "\n"))")
  }

  private func mutateState(sendChange: Bool = true, _ updates: () -> Void) {
    updates()
    if sendChange && isPublishingEnabled {
      logPendingPublishStack()
      schedulePublish()
    }
  }

  private func schedulePublish() {
    guard !isPublishScheduled else { return }
    isPublishScheduled = true
    DispatchQueue.main.async { [weak self] in
      guard let self else { return }
      self.isPublishScheduled = false
      self.objectWillChange.send()
    }
  }

  private func logPendingPublishStack() {
    guard stateLoggingEnabled else { return }
    NSLog("⚠️ ConversationStore 即将 publish objectWillChange | stack:\n\(Thread.callStackSymbols.joined(separator: "\n"))")
  }

  private func makeSession(title: String?) -> Session {
    let now = Date()
    let cleanTitle = title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    return Session(
      id: UUID().uuidString,
      title: cleanTitle.isEmpty ? "新会话" : cleanTitle,
      systemPrompt: "",
      messages: [],
      createdAt: now,
      updatedAt: now,
      hasCustomTitle: !cleanTitle.isEmpty
    )
  }

  private static func defaultURL() -> URL {
    let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
    return dir.appendingPathComponent("conversation_sessions.json")
  }
}

private extension OverlayChatMessage {
  func toCoreMessage() -> CoreChatMessage {
    CoreChatMessage(
      id: id,
      text: text,
      isUser: isUser,
      timestamp: Date(timeIntervalSince1970: timestamp / 1000),
      isResponse: !isUser
    )
  }

  func toPersistMessage() -> ConversationStore.PersistMessage {
    ConversationStore.PersistMessage(
      id: id,
      text: text,
      isUser: isUser,
      timestamp: Date(timeIntervalSince1970: timestamp / 1000)
    )
  }
}

private extension CoreChatMessage {
  func toOverlayMessage() -> OverlayChatMessage {
    OverlayChatMessage(
      id: id,
      text: text,
      isUser: isUser,
      timestamp: timestamp.timeIntervalSince1970 * 1000
    )
  }
}

```

`StarO/StarO/PreferenceService.swift`:

```swift
import Foundation
import StarOracleServices

@MainActor
final class LocalPreferenceService: PreferenceServiceProtocol {
  private let defaults: UserDefaults
  private let key = "aiConfiguration"
  private var cachedDefault: AIConfiguration?

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
  }

  func loadAIConfiguration() async -> AIConfiguration? {
    if let data = defaults.data(forKey: key),
       let stored = try? JSONDecoder().decode(AIConfiguration.self, from: data) {
      NSLog("ℹ️ [PreferenceService] 使用用户保存的 AI 配置（provider=%@, endpoint=%@）", stored.provider, stored.endpoint.absoluteString)
      return stored
    }
    if let cachedDefault {
      NSLog("ℹ️ [PreferenceService] 使用缓存的默认 AI 配置（provider=%@）", cachedDefault.provider)
      return cachedDefault
    }
    let defaultConfig = AIConfigurationDefaults.load()
    if let defaultConfig {
      NSLog("ℹ️ [PreferenceService] 使用默认 AI 配置（provider=%@, endpoint=%@）", defaultConfig.provider, defaultConfig.endpoint.absoluteString)
    } else {
      NSLog("⚠️ [PreferenceService] 未找到任何 AI 配置")
    }
    cachedDefault = defaultConfig
    return defaultConfig
  }

  func saveAIConfiguration(_ config: AIConfiguration) async throws {
    let data = try JSONEncoder().encode(config)
    defaults.set(data, forKey: key)
    NSLog("✅ [PreferenceService] AI 配置已保存（provider=%@）", config.provider)
    cachedDefault = config
  }
}

```

`StarO/StarO/AIConfigSheet.swift`:

```swift
import SwiftUI
import StarOracleServices

@MainActor
struct AIConfigSheet: View {
  @EnvironmentObject private var environment: AppEnvironment
  @State private var config: AIConfiguration = AIConfiguration(
    provider: "openai",
    apiKey: "",
    endpoint: URL(string: "https://api.openai.com/v1/chat/completions")!,
    model: "gpt-4o-mini"
  )
  @State private var validationMessage: String?
  @State private var isValidating = false
  @State private var isSaving = false

  var body: some View {
    NavigationStack {
      Form {
        Section("提供商") {
          TextField("Provider", text: $config.provider)
#if os(iOS)
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
#endif
        }
        Section("API 配置") {
          SecureField("API Key", text: $config.apiKey)
          TextField("Endpoint", text: Binding(
            get: { config.endpoint.absoluteString },
            set: { config.endpoint = URL(string: $0) ?? config.endpoint }
          ))
#if os(iOS)
          .keyboardType(.URL)
#endif
          TextField("模型", text: $config.model)
#if os(iOS)
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
#endif
        }
        Section("验证") {
          VStack(alignment: .leading, spacing: 12) {
            Button {
              Task { await validateConfig() }
            } label: {
              if isValidating {
                ProgressView()
              } else {
                Label("验证配置", systemImage: "checkmark.seal")
              }
            }
            .buttonStyle(.bordered)

            if let validationMessage {
              Text(validationMessage)
                .font(.footnote)
                .foregroundStyle(.secondary)
            } else {
              Text("验证会直接向配置的 Endpoint 发送一次最小请求，用于确认 API Key / 模型是否可用。")
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
          }
        }
      }
      .navigationTitle("AI 配置")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("关闭") {
            dismiss()
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button {
            Task { await saveConfig() }
          } label: {
            if isSaving {
              ProgressView()
            } else {
              Text("保存")
            }
          }
          .disabled(isSaving)
        }
      }
      .task {
        await loadConfig()
      }
    }
  }

  @Environment(\.dismiss) private var dismiss

  private func loadConfig() async {
    if let stored = await environment.preferenceService.loadAIConfiguration() {
      config = stored
    }
  }

  private func saveConfig() async {
    isSaving = true
    defer { isSaving = false }
    do {
      try await environment.preferenceService.saveAIConfiguration(config)
      validationMessage = "配置已保存。"
      dismiss()
    } catch {
      validationMessage = "保存失败：\(error.localizedDescription)"
    }
  }

  private func validateConfig() async {
    guard !isValidating else { return }
    isValidating = true
    defer { isValidating = false }
    do {
      try await environment.aiService.validate(configuration: config)
      validationMessage = "验证成功。"
    } catch {
      validationMessage = "验证失败：\(error.localizedDescription)"
    }
  }
}

```

`StarO/StarO/StreamingClient.swift`:

```swift
import Foundation

/// Lightweight SSE client for OpenAI-compatible /v1/chat/completions streaming.
/// Uses URLSession.bytes(for:) to iterate server-sent event lines.
final class StreamingClient: @unchecked Sendable {
  private var currentTask: Task<Void, Never>?

  private final class ChunkHandler: @unchecked Sendable {
    private let block: @Sendable (String) -> Void
    init(_ block: @escaping @Sendable (String) -> Void) { self.block = block }
    func call(_ chunk: String) { block(chunk) }
  }

  private final class CompletionHandler: @unchecked Sendable {
    private let block: @Sendable (_ fullText: String?, _ error: Error?) -> Void
    init(_ block: @escaping @Sendable (_ fullText: String?, _ error: Error?) -> Void) { self.block = block }
    func call(_ text: String?, _ error: Error?) { block(text, error) }
  }

  private struct StreamingJob: @unchecked Sendable {
    var request: URLRequest
    let chunkHandler: ChunkHandler
    let completionHandler: CompletionHandler

    func run() async {
      var full = ""
      do {
        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        guard let http = response as? HTTPURLResponse else {
          completionHandler.call(nil, StreamingError.invalidResponse)
          return
        }
        guard (200..<300).contains(http.statusCode) else {
          let text = try? String(
            data: Data(try await bytes.reduce(into: [UInt8](), { $0.append($1) })),
            encoding: .utf8
          )
          completionHandler.call(nil, StreamingError.http(status: http.statusCode, body: text ?? ""))
          return
        }
        for try await line in bytes.lines {
          try Task.checkCancellation()
          let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
          guard trimmed.hasPrefix("data: ") else { continue }
          let payload = String(trimmed.dropFirst(6))
          if payload == "[DONE]" { break }
          guard let data = payload.data(using: .utf8) else { continue }
          if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
             let choices = json["choices"] as? [[String: Any]],
             let delta = choices.first?["delta"] as? [String: Any],
             let content = delta["content"] as? String,
             !content.isEmpty {
            full += content
            chunkHandler.call(content)
          }
        }
        completionHandler.call(full, nil)
      } catch is CancellationError {
        completionHandler.call(full.isEmpty ? nil : full, StreamingError.cancelled)
      } catch {
        completionHandler.call(full.isEmpty ? nil : full, error)
      }
    }
  }

  private enum StreamingError: LocalizedError {
    case invalidResponse
    case http(status: Int, body: String)
    case cancelled

    var errorDescription: String? {
      switch self {
      case .invalidResponse:
        return "SSE 响应无效"
      case let .http(status, body):
        return "SSE 请求失败 (\(status))：\(body)"
      case .cancelled:
        return "请求已取消"
      }
    }
  }

  struct Message: Codable {
    let role: String
    let content: String
  }

  struct RequestBody: Codable {
    let model: String
    let messages: [Message]
    let temperature: Double?
    let maxTokens: Int?
    let stream: Bool

    enum CodingKeys: String, CodingKey {
      case model
      case messages
      case temperature
      case maxTokens = "max_tokens"
      case stream
    }
  }

  func startChatCompletionStream(
    endpoint: String,
    apiKey: String,
    model: String,
    messages: [Message],
    temperature: Double?,
    maxTokens: Int?,
    onChunk: @escaping @Sendable (String) -> Void,
    onComplete: @escaping @Sendable (_ fullText: String?, _ error: Error?) -> Void
  ) {
    cancel()
    NSLog("🚀 StreamingClient.start | endpoint=%@ model=%@ messages=%d", endpoint, model, messages.count)

    let chunkHandler = ChunkHandler(onChunk)
    let completionHandler = CompletionHandler(onComplete)

    var request = URLRequest(url: URL(string: endpoint)!)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(StreamingClient.authHeaderValue(for: apiKey), forHTTPHeaderField: "Authorization")

    let body = RequestBody(
      model: model,
      messages: messages,
      temperature: temperature,
      maxTokens: maxTokens,
      stream: true
    )
    do {
      request.httpBody = try JSONEncoder().encode(body)
    } catch {
      NSLog("❌ StreamingClient.encode | %@", error.localizedDescription)
      completionHandler.call(nil, error)
      return
    }

    let job = StreamingJob(request: request, chunkHandler: chunkHandler, completionHandler: completionHandler)
    currentTask = Task {
      await job.run()
    }
  }

  func cancel() {
    currentTask?.cancel()
    currentTask = nil
  }

  private static func authHeaderValue(for apiKey: String) -> String {
    let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.lowercased().hasPrefix("bearer ") ? trimmed : "Bearer \(trimmed)"
  }
}

```

