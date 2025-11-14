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
