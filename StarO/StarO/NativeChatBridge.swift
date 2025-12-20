import Foundation
import Combine
import SwiftUI
import UIKit
import StarOracleCore
import StarOracleFeatures
import StarOracleServices

extension ObservableObjectPublisher: @unchecked Sendable {}

private func NSLog(_ format: String, _ args: CVarArg...) {
  guard StarOracleDebug.verboseLogsEnabled else { return }
  if args.isEmpty {
    Foundation.NSLog("%@", format)
  } else {
    withVaList(args) { Foundation.NSLogv(format, $0) }
  }
}

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
  private let starStore: StarStore
  private let conversationStore: ConversationStore
  private let aiService: AIServiceProtocol
  private let preferenceService: PreferenceServiceProtocol
  private var cancellables = Set<AnyCancellable>()
  private var streamingTask: Task<Void, Never>?
  private var starsPollingTask: Task<Void, Never>?
  private var userMemoryRefreshTask: Task<Void, Never>?
  private var userMemoryRefreshGeneration: Int = 0
  private var didActivate = false
  private weak var windowScene: UIWindowScene?
  private weak var registeredBackgroundView: UIView?
  private var pendingEnsureWorkItem: DispatchWorkItem?
  private var pendingPresentationStateWorkItem: DispatchWorkItem?
  private var overlayHintIdsByChatId: [String: Set<String>] = [:]
  private var overlayHintsByChatId: [String: [OverlayChatMessage]] = [:]

  private struct CloudSendContext: Sendable {
    let message: String
    let galaxyStarIndices: [Int]?
    let reviewSessionId: String?
  }

  private var cloudSendContextByIdempotencyKey: [String: CloudSendContext] = [:]

  init(
    chatStore: ChatStore,
    starStore: StarStore,
    conversationStore: ConversationStore,
    aiService: AIServiceProtocol,
    preferenceService: PreferenceServiceProtocol
  ) {
    self.chatStore = chatStore
    self.starStore = starStore
    self.conversationStore = conversationStore
    self.aiService = aiService
    self.preferenceService = preferenceService
    super.init()
    inputManager.delegate = self
    observeChatStore()
    observeOverlayNotifications()
    bootstrapSystemPromptIfNeeded()
  }

  deinit {
    streamingTask?.cancel()
    starsPollingTask?.cancel()
    userMemoryRefreshTask?.cancel()
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
    refreshOverlayMessages()
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

  func setSystemModalPresented(_ presented: Bool) {
    overlayManager.setExternalModalPresented(presented)
    inputManager.setExternalModalPresented(presented)
  }

  func sendMessage(_ text: String) {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    NSLog("🎯 NativeChatBridge.sendMessage text=\(trimmed)")
    cancelUserMemoryRefreshTimer()
    if presentationState == .hidden {
      openOverlay(expanded: true)
    }
    rotateSessionIfNeededForFreeChat()
    chatStore.addUserMessage(trimmed)
    inputManager.setText("")
    setLastErrorMessage(nil)
    startStreaming(for: trimmed)
  }

  func retryLastMessage() {
    guard SupabaseRuntime.loadConfig() != nil else { return }
    guard let lastUserMessage = chatStore.messages.last(where: { $0.isUser }) else { return }
    retryCloudMessage(
      chatId: conversationStore.currentSessionId,
      message: lastUserMessage.text,
      idempotencyKey: lastUserMessage.id
    )
  }

  private func rotateSessionIfNeededForFreeChat() {
    guard SupabaseRuntime.loadConfig() != nil else { return }
    let chatId = conversationStore.currentSessionId
    if conversationStore.pendingReviewSessionId(forChatId: chatId) != nil {
      NSLog("🧾 NativeChatBridge | 检测到 review_session_id，跳过10分钟分段 chat_id=%@", chatId)
      return
    }
	    guard conversationStore.shouldStartNewSessionDueToInactivity() else { return }
	    NSLog("🕒 NativeChatBridge | 超过10分钟无活动，自动新建 chat_id 分段")
	    let session = conversationStore.createSession(title: nil)
	    chatStore.setConversationTitle("")
	    chatStore.loadMessages([], title: nil)
	  }

  private func startStreaming(for question: String) {
    streamingTask?.cancel()
    starsPollingTask?.cancel()
    streamingTask = Task { [weak self] in
      guard let self else { return }
      await self.performStreaming(for: question)
    }
  }

  private func retryCloudMessage(chatId: String, message: String, idempotencyKey: String) {
    streamingTask?.cancel()
    starsPollingTask?.cancel()
    cancelUserMemoryRefreshTimer()

    let streamingMessageId: String = {
      if let last = chatStore.messages.last, !last.isUser {
        return last.id
      }
      return chatStore.beginStreamingAIMessage(initial: "")
    }()

    chatStore.updateStreamingMessage(id: streamingMessageId, text: "")
    chatStore.setLoading(true)
    overlayManager.setLoading(true)
    setLastErrorMessage(nil)

    let traceId = SupabaseRuntime.makeTraceId()
    let context = cloudSendContextByIdempotencyKey[idempotencyKey]
    let galaxyStarIndices = context?.galaxyStarIndices ?? conversationStore.galaxyStarIndicesForFirstChatSend(sessionId: chatId)
    let reviewSessionId = context?.reviewSessionId ?? conversationStore.pendingReviewSessionId(forChatId: chatId)

    streamingTask = Task { [weak self] in
      guard let self else { return }
      await self.performCloudStreaming(
        chatId: chatId,
        message: message,
        traceId: traceId,
        idempotencyKey: idempotencyKey,
        galaxyStarIndices: galaxyStarIndices,
        reviewSessionId: reviewSessionId,
        streamingMessageId: streamingMessageId
      )
    }
  }

  private func refreshOverlayMessages(sourceMessages: [StarOracleCore.ChatMessage]? = nil) {
    let now = Date()
    let windowStart = now.addingTimeInterval(-24 * 60 * 60)
    let currentChatId = conversationStore.currentSessionId
    let currentSessionUpdatedAt = conversationStore.session(id: currentChatId)?.updatedAt ?? now

    let shouldAggregate24Hours = currentSessionUpdatedAt >= windowStart

    var base: [OverlayChatMessage] = []
    var includedChatIds: [String] = []

    if shouldAggregate24Hours {
      for session in conversationStore.listSessions() {
        let chatId = session.id
        guard session.updatedAt >= windowStart || chatId == currentChatId else { continue }

        includedChatIds.append(chatId)
        let messages: [StarOracleCore.ChatMessage]
        if chatId == currentChatId {
          messages = sourceMessages ?? chatStore.messages
        } else {
          messages = conversationStore.messages(forSession: chatId)
        }

        for message in messages {
          if chatId != currentChatId, message.timestamp < windowStart { continue }
          base.append(makeOverlayMessage(message))
        }
      }
    } else {
      includedChatIds = [currentChatId]
      base = (sourceMessages ?? chatStore.messages).map(makeOverlayMessage)
    }

    var merged = base
    for chatId in includedChatIds {
      merged.append(contentsOf: overlayHintsByChatId[chatId] ?? [])
    }

    let sorted = merged.sorted { lhs, rhs in
      if lhs.timestamp != rhs.timestamp {
        return lhs.timestamp < rhs.timestamp
      }
      if lhs.isUser != rhs.isUser {
        return lhs.isUser && !rhs.isUser
      }
      return lhs.id < rhs.id
    }
    overlayManager.updateMessages(sorted)
  }

  private func appendStarHint(chatId: String, kind: String, starId: String, text: String) {
    let trimmed = starId.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    let hintId = "hint-star:\(trimmed):\(kind)"

    var ids = overlayHintIdsByChatId[chatId] ?? []
    if ids.contains(hintId) { return }
    ids.insert(hintId)
    overlayHintIdsByChatId[chatId] = ids

    let message = OverlayChatMessage(
      id: hintId,
      text: text,
      isUser: false,
      timestamp: Date().timeIntervalSince1970 * 1000
    )
    var list = overlayHintsByChatId[chatId] ?? []
    list.append(message)
    overlayHintsByChatId[chatId] = list

    if chatId == conversationStore.currentSessionId {
      refreshOverlayMessages()
    }
  }

  private func startStarsPolling(afterDoneChatId chatId: String) {
    starsPollingTask?.cancel()
    let previous = conversationStore.knownStar(forChatId: chatId)

    starsPollingTask = Task.detached { [weak self] in
      guard let self else { return }
      let deadline = Date().addingTimeInterval(20)
      var lastStarId = previous?.id
      var lastInsightLevel = previous?.insightLevel
      var intervalNs: UInt64 = 1_000_000_000

      while Date() < deadline {
        if Task.isCancelled { return }
        if let row = await StarsService.fetchStarByChatId(chatId) {
          let star = StarsService.toCoreStar(row: row)
          let starId = star.id
          let level = star.insightLevel?.value ?? max(1, min(5, row.insightLevel ?? 1))

          await MainActor.run {
            self.starStore.upsertConstellationStar(star)
            self.conversationStore.updateKnownStar(forChatId: chatId, starId: starId, insightLevel: level)

            if lastStarId == nil || lastStarId != starId {
              self.appendStarHint(chatId: chatId, kind: "created", starId: starId, text: "已生成一颗星星，点击查看星卡")
            } else if let lastInsightLevel, level > lastInsightLevel {
              self.appendStarHint(chatId: chatId, kind: "upgraded-\(level)", starId: starId, text: "星卡已升级，点击查看")
            }
          }

          lastStarId = starId
          lastInsightLevel = max(lastInsightLevel ?? 0, level)
        }

        try? await Task.sleep(nanoseconds: intervalNs)
        if intervalNs < 2_000_000_000 {
          intervalNs = min(2_000_000_000, UInt64(Double(intervalNs) * 1.15))
        }
      }
    }
  }

  private func performStreaming(for question: String) async {
    chatStore.setLoading(true)
    overlayManager.setLoading(true)
    if SupabaseRuntime.loadConfig() != nil {
      let effectiveChatId = conversationStore.currentSessionId
      NSLog("🌐 NativeChatBridge.performStreaming | 使用后端 chat-send chat_id=%@", effectiveChatId)
      let requestTraceId = SupabaseRuntime.makeTraceId()
      let requestIdempotencyKey = chatStore.messages.last(where: { $0.isUser })?.id ?? SupabaseRuntime.makeIdempotencyKey()
      let galaxyStarIndices = conversationStore.galaxyStarIndicesForFirstChatSend(sessionId: effectiveChatId)
      let reviewSessionId = conversationStore.pendingReviewSessionId(forChatId: effectiveChatId)
      let streamingMessageId = chatStore.beginStreamingAIMessage(initial: "")
      cloudSendContextByIdempotencyKey[requestIdempotencyKey] = CloudSendContext(
        message: question,
        galaxyStarIndices: galaxyStarIndices,
        reviewSessionId: reviewSessionId
      )

      await performCloudStreaming(
        chatId: effectiveChatId,
        message: question,
        traceId: requestTraceId,
        idempotencyKey: requestIdempotencyKey,
        galaxyStarIndices: galaxyStarIndices,
        reviewSessionId: reviewSessionId,
        streamingMessageId: streamingMessageId
      )
      return
    }

    NSLog("🧩 NativeChatBridge.performStreaming | 使用旧链路 OpenAI（未配置 SUPABASE_URL + TOKEN/SUPABASE_JWT）")
    let history = chatStore.messages
    let systemPrompt = conversationStore.currentSession()?.systemPrompt ?? ""
    if systemPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      NSLog("ℹ️ NativeChatBridge.performStreaming | 当前会话系统提示为空")
    } else {
      NSLog("🎯 NativeChatBridge.performStreaming | systemPrompt 前30字: %@...", String(systemPrompt.prefix(30)))
    }
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
      await generateAndApplyConversationTitleIfNeeded(chatId: conversationStore.currentSessionId)
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

  private func performCloudStreaming(
    chatId: String,
    message: String,
    traceId: String,
    idempotencyKey: String,
    galaxyStarIndices: [Int]?,
    reviewSessionId: String?,
    streamingMessageId: String
  ) async {
    defer { scheduleUserMemoryRefreshAfterIdle() }
    var buffer = ""
    var doneChatId: String?
    var requestStartedAt = Date()
    var didSucceed = true

    let didSendGalaxyStarIndices = galaxyStarIndices != nil
    let didSendReviewSessionId = reviewSessionId != nil

    do {
      if conversationStore.session(id: chatId)?.hasSupabaseConversationStarted != true {
        let title = conversationStore.currentSession()?.hasCustomTitle == true ? conversationStore.currentSession()?.displayTitle : nil
        try await ChatCreateService.ensureChatExists(chatId: chatId, title: title)
      }

      requestStartedAt = Date()
      for try await event in ChatSendService.streamMessage(
        chatId: chatId,
        message: message,
        traceId: traceId,
        idempotencyKey: idempotencyKey,
        galaxyStarIndices: galaxyStarIndices,
        reviewSessionId: reviewSessionId
      ) {
        switch event {
        case let .delta(chunk):
          buffer.append(chunk)
          chatStore.updateStreamingMessage(id: streamingMessageId, text: buffer)
        case let .done(_, doneId, _):
          doneChatId = doneId
          conversationStore.markSseDone(sessionId: doneId)
          if didSendGalaxyStarIndices {
            conversationStore.clearPendingGalaxyStarIndices()
          }
          if didSendReviewSessionId {
            conversationStore.clearReviewSession(forChatId: doneId)
          }
        }
      }

      let effectiveChatId = doneChatId ?? chatId
      let trimmed = buffer.trimmingCharacters(in: .whitespacesAndNewlines)
      if trimmed.isEmpty {
        if let latest = await ChatMessagesService.fetchLatestAssistantMessage(chatId: effectiveChatId) {
          let okTime = latest.timestamp >= requestStartedAt.addingTimeInterval(-2)
          let text = latest.text.trimmingCharacters(in: .whitespacesAndNewlines)
          if okTime, !text.isEmpty {
            buffer = text
            chatStore.updateStreamingMessage(id: streamingMessageId, text: text)
          } else {
            didSucceed = false
          }
        } else {
          didSucceed = false
        }

        if didSucceed != true {
          let fallbackText = "未能获取星语回应，请点击重试。"
          chatStore.updateStreamingMessage(id: streamingMessageId, text: fallbackText)
          setLastErrorMessage("发送失败：未能从云端读取本次回复。")
        }
      }

      chatStore.finalizeStreamingMessage(id: streamingMessageId)
      chatStore.setLoading(false)
      overlayManager.setLoading(false)
      if didSucceed == true {
        conversationStore.markSseDone(sessionId: effectiveChatId)
        if didSendGalaxyStarIndices {
          conversationStore.clearPendingGalaxyStarIndices()
        }
        if didSendReviewSessionId {
          conversationStore.clearReviewSession(forChatId: effectiveChatId)
        }
        await generateAndApplyConversationTitleIfNeeded(chatId: effectiveChatId)
        setLastErrorMessage(nil)
        startStarsPolling(afterDoneChatId: effectiveChatId)
      }

      if let doneChatId, doneChatId != chatId {
        NSLog("⚠️ NativeChatBridge | done.chat_id 与请求 chat_id 不一致 request=%@ done=%@", chatId, doneChatId)
      }
    } catch {
      if await tryRecoverFromCloudIfPossible(
        error: error,
        chatId: chatId,
        requestStartedAt: requestStartedAt,
        streamingMessageId: streamingMessageId,
        didSendGalaxyStarIndices: didSendGalaxyStarIndices,
        didSendReviewSessionId: didSendReviewSessionId
      ) {
        return
      }
      NSLog("❌ NativeChatBridge.performStreaming(chat-send) | error=%@", error.localizedDescription)
      chatStore.updateStreamingMessage(id: streamingMessageId, text: "未能获取星语回应，请稍后再试。")
      chatStore.finalizeStreamingMessage(id: streamingMessageId)
      chatStore.setLoading(false)
      overlayManager.setLoading(false)
      setLastErrorMessage("发送失败：\(error.localizedDescription)")
    }
  }

  // MARK: - User long-term memory refresh (idle trigger)

  private func cancelUserMemoryRefreshTimer() {
    userMemoryRefreshTask?.cancel()
    userMemoryRefreshTask = nil
  }

  private func scheduleUserMemoryRefreshAfterIdle(delaySeconds: TimeInterval = 5 * 60) {
    guard SupabaseRuntime.loadProjectConfig() != nil else { return }
    guard delaySeconds > 0 else { return }

    userMemoryRefreshTask?.cancel()
    userMemoryRefreshGeneration += 1
    let generation = userMemoryRefreshGeneration

    userMemoryRefreshTask = Task { [weak self] in
      guard let self else { return }
      let ns = UInt64(delaySeconds * 1_000_000_000)
      do {
        try await Task.sleep(nanoseconds: ns)
      } catch {
        return
      }
      guard !Task.isCancelled else { return }
      await self.performUserMemoryRefreshIfLatest(generation: generation)
    }
  }

  private func performUserMemoryRefreshIfLatest(generation: Int) async {
    guard generation == userMemoryRefreshGeneration else { return }

    do {
      let traceId = SupabaseRuntime.makeTraceId()
      let result = try await UserMemoryRefreshService.refresh(force: true, traceId: traceId)
      NSLog(
        "🧠 UserMemoryRefresh | ok updated=%@ reason=%@ processed=%@ tokens=%@",
        String(result.updated ?? false),
        result.reason ?? "nil",
        result.processedMessages.map(String.init) ?? "nil",
        result.approxTokens.map(String.init) ?? "nil"
      )
    } catch {
      NSLog("⚠️ UserMemoryRefresh | failed error=%@", error.localizedDescription)
    }

    if generation == userMemoryRefreshGeneration {
      userMemoryRefreshTask = nil
    }
  }

  func checkUserMemoryRefreshAfterRestoreIfNeeded(idleSeconds: TimeInterval = 5 * 60) {
    guard SupabaseRuntime.loadProjectConfig() != nil else { return }
    guard userMemoryRefreshTask == nil else { return }
    guard idleSeconds > 0 else { return }
    guard SupabaseRuntime.loadConfig() != nil else { return }

    let lastDoneAt = conversationStore.listSessions().compactMap(\.lastSseDoneAt).max()
    guard let lastDoneAt else { return }

    let idle = Date().timeIntervalSince(lastDoneAt)
    guard idle >= idleSeconds else { return }

    userMemoryRefreshGeneration += 1
    let generation = userMemoryRefreshGeneration
    userMemoryRefreshTask = Task { [weak self] in
      guard let self else { return }
      await self.performUserMemoryRefreshIfLatest(generation: generation)
    }
  }

  private func tryRecoverFromCloudIfPossible(
    error: Error,
    chatId: String,
    requestStartedAt: Date,
    streamingMessageId: String,
    didSendGalaxyStarIndices: Bool,
    didSendReviewSessionId: Bool
  ) async -> Bool {
    guard SupabaseRuntime.loadProjectConfig() != nil else { return false }

    let shouldRecover: Bool = {
      if let urlError = error as? URLError {
        switch urlError.code {
        case .timedOut,
             .networkConnectionLost,
             .cannotFindHost,
             .cannotConnectToHost,
             .dnsLookupFailed,
             .notConnectedToInternet:
          return true
        default:
          return false
        }
      }
      return false
    }()

    guard shouldRecover else { return false }

    NSLog("🛟 NativeChatBridge | 网络异常，尝试从云端恢复本次回复 chat_id=%@", chatId)
    let deadline = Date().addingTimeInterval(25)

    while Date() < deadline {
      if Task.isCancelled { return false }
      if let latest = await ChatMessagesService.fetchLatestAssistantMessage(chatId: chatId) {
        let okTime = latest.timestamp >= requestStartedAt.addingTimeInterval(-2)
        if okTime {
          let text = latest.text.trimmingCharacters(in: .whitespacesAndNewlines)
          if !text.isEmpty {
            NSLog("🛟 NativeChatBridge | 云端恢复成功 message_id=%@", latest.id)
            chatStore.updateStreamingMessage(id: streamingMessageId, text: text)
            chatStore.finalizeStreamingMessage(id: streamingMessageId)
            chatStore.setLoading(false)
            overlayManager.setLoading(false)
            await generateAndApplyConversationTitleIfNeeded(chatId: chatId)
            setLastErrorMessage(nil)
            conversationStore.markSseDone(sessionId: chatId)
            if didSendGalaxyStarIndices {
              conversationStore.clearPendingGalaxyStarIndices()
            }
            if didSendReviewSessionId {
              conversationStore.clearReviewSession(forChatId: chatId)
            }
            startStarsPolling(afterDoneChatId: chatId)
            return true
          }
        }
      }
      try? await Task.sleep(nanoseconds: 900_000_000)
    }

    NSLog("🛟 NativeChatBridge | 云端恢复失败，超时 chat_id=%@", chatId)
    return false
  }

  private func generateAndApplyConversationTitleIfNeeded(chatId: String) async {
    let trimmedId = chatId.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedId.isEmpty else { return }
    guard conversationStore.currentSessionId == trimmedId else { return }
    guard let session = conversationStore.session(id: trimmedId) else { return }
    guard session.hasCustomTitle != true else { return }

    do {
      try await chatStore.generateConversationTitle()
    } catch {
      NSLog("⚠️ NativeChatBridge | generateConversationTitle failed error=%@", error.localizedDescription)
      return
    }

    let generated = chatStore.conversationTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !generated.isEmpty else { return }
    guard conversationStore.currentSessionId == trimmedId else { return }
    guard let latestSession = conversationStore.session(id: trimmedId) else { return }
    guard latestSession.hasCustomTitle != true else { return }

    // 仅在默认占位标题时覆盖，避免误改用户自定义命名
    let current = latestSession.title.trimmingCharacters(in: .whitespacesAndNewlines)
    let isPlaceholder = current.isEmpty || current == "新会话" || current == "未命名会话"
    guard isPlaceholder else { return }

    conversationStore.renameSession(id: trimmedId, title: generated)
    if SupabaseRuntime.loadConfig() != nil {
      try? await ChatUpdateService.updateChatTitle(chatId: trimmedId, title: generated)
    }
  }

  private func observeChatStore() {
    chatStore.$messages
      .removeDuplicates()
      .receive(on: DispatchQueue.main)
      .sink { [weak self] messages in
        guard let self else { return }
        // 将当前会话的消息落到 ConversationStore，确保左侧历史会话可回放
        self.conversationStore.updateCurrentSessionMessages(messages)
        self.refreshOverlayMessages(sourceMessages: messages)
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

    NotificationCenter.default.publisher(for: .chatOverlayRetryLastMessage)
      .receive(on: DispatchQueue.main)
      .sink { [weak self] _ in
        guard let self else { return }
        DispatchQueue.main.async {
          self.retryLastMessage()
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
    // 若已绑定同一 scene，避免重复 rebind 造成窗口闪烁
    let isSameScene = windowScene === scene
    let isNewScene = windowScene !== scene
    windowScene = scene
    overlayManager.attach(to: scene)
    inputManager.attach(to: scene)
    if isNewScene {
      registeredBackgroundView = nil
    }
    // 已绑定且背景视图有效则无需重复配置
    if isSameScene, let view = registeredBackgroundView, view.window != nil {
      return
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

  private func bootstrapSystemPromptIfNeeded() {
    conversationStore.bootstrapIfNeeded()
    guard let session = conversationStore.currentSession() else {
      NSLog("ℹ️ NativeChatBridge | 无可用会话，无法写入系统提示")
      return
    }
    let prompt = session.systemPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
    guard prompt.isEmpty else { return }
    NSLog("ℹ️ NativeChatBridge | 会话无系统提示，写入默认 prompt")
    conversationStore.setSystemPrompt(SystemPrompt.defaultPrompt, sessionId: session.id)
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
    Task { @MainActor [weak self] in
      guard let self else { return }
      self.ensureOverlayVisible(collapsed: false)
      self.overlayManager.requestScrollToBottom(animated: true, reason: "输入框聚焦")
    }
  }

  nonisolated func inputDrawerDidBlur() {}
}
