import Foundation
import Combine
import SwiftUI
import UIKit
import StarOracleCore
import StarOracleFeatures
import StarOracleServices

@MainActor
final class NativeChatBridge: NSObject, ObservableObject {
  enum PresentationState {
    case hidden
    case collapsed
    case expanded
  }

  @Published private(set) var presentationState: PresentationState = .hidden
  @Published private(set) var isInputDrawerVisible = false
  @Published private(set) var lastErrorMessage: String?

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
    ensureOverlayVisible(collapsed: true)
  }

  func ensureInputDrawerVisible() {
    NSLog("🎯 NativeChatBridge.ensureInputDrawerVisible")
    inputManager.show(animated: true) { [weak self] success in
      guard let self else { return }
      if success { self.isInputDrawerVisible = true }
    }
  }

  func hideInputDrawer() {
    inputManager.hide(animated: true) { [weak self] in
      self?.isInputDrawerVisible = false
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
      DispatchQueue.main.async {
        self.presentationState = expanded ? .expanded : .collapsed
      }
    }
  }

  func hideOverlay() {
    NSLog("🎯 NativeChatBridge.hideOverlay")
    overlayManager.hide(animated: true) { [weak self] in
      DispatchQueue.main.async {
        self?.presentationState = .hidden
      }
    }
  }

  func ensureOverlayVisible(collapsed: Bool = true) {
    NSLog("🎯 NativeChatBridge.ensureOverlayVisible collapsed=\(collapsed) current=\(presentationState)")
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
    lastErrorMessage = nil
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
    let configuration = await preferenceService.loadAIConfiguration() ?? AIConfiguration(
      provider: "mock",
      apiKey: "",
      endpoint: URL(string: "https://example.com/mock")!,
      model: "mock-gpt"
    )
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
        chatStore.updateStreamingMessage(id: messageId, text: buffer)
      }
      chatStore.finalizeStreamingMessage(id: messageId)
      chatStore.setLoading(false)
      overlayManager.setLoading(false)
      try? await chatStore.generateConversationTitle()
      lastErrorMessage = nil
    } catch {
      chatStore.updateStreamingMessage(id: messageId, text: "未能获取星语回应，请稍后再试。")
      chatStore.finalizeStreamingMessage(id: messageId)
      chatStore.setLoading(false)
      overlayManager.setLoading(false)
      lastErrorMessage = "发送失败：\(error.localizedDescription)"
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
            self.presentationState = .expanded
          case "collapsed":
            self.presentationState = .collapsed
          case "hidden":
            self.presentationState = .hidden
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
    Task { @MainActor [weak self] in
      guard let self else { return }
      if self.presentationState == .hidden {
        self.ensureOverlayVisible(collapsed: true)
      }
    }
  }

  nonisolated func inputDrawerDidFocus() {
    NSLog("🎯 NativeChatBridge.inputDrawerDidFocus")
    Task { @MainActor [weak self] in
      self?.ensureOverlayVisible(collapsed: true)
    }
  }

  nonisolated func inputDrawerDidBlur() {}
}
