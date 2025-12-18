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

  struct KnownStar: Equatable {
    let id: String
    let insightLevel: Int
  }

  struct Session: Identifiable, Codable, Equatable {
    let id: String
    var title: String
    var systemPrompt: String
    var messages: [PersistMessage]
    var createdAt: Date
    var updatedAt: Date
    var hasCustomTitle: Bool
    var lastSseDoneAt: Date?
    // 兼容旧持久化文件：该字段可能缺失（decode 为 nil），按 false 处理。
    var hasSupabaseConversationStarted: Bool?

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
  private var stateLoggingEnabled: Bool { StarOracleDebug.verboseLogsEnabled }
  private var isPublishingEnabled = false
  private var isBootstrapped = false
  private var isPublishScheduled = false
  private var pendingGalaxyStarIndicesStorage: [Int]?
  private var pendingGalaxyStarIndicesExpiresAt: Date?
  private var pendingReviewSessionIdByChatId: [String: String] = [:]
  private var knownStarsByChatId: [String: KnownStar] = [:]

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
  func upsertSupabaseSession(
    id: String,
    title: String?,
    messages: [CoreChatMessage],
    createdAt: Date? = nil,
    updatedAt: Date? = nil
  ) -> Session {
    let now = Date()
    let trimmedTitle = (title ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    let resolvedTitle = trimmedTitle.isEmpty ? "未命名会话" : trimmedTitle
    let persistedMessages = messages.map { message in
      PersistMessage(
        id: message.id,
        text: message.text,
        isUser: message.isUser,
        timestamp: message.timestamp
      )
    }

    mutateState {
      if let index = self.sessionsStorage.firstIndex(where: { $0.id == id }) {
        var session = self.sessionsStorage.remove(at: index)
        session.title = resolvedTitle
        session.messages = persistedMessages
        if let createdAt {
          session.createdAt = createdAt
        }
        session.updatedAt = updatedAt ?? now
        session.hasCustomTitle = !trimmedTitle.isEmpty
        session.hasSupabaseConversationStarted = true
        self.sessionsStorage.insert(session, at: 0)
      } else {
        let session = Session(
          id: id,
          title: resolvedTitle,
          systemPrompt: "",
          messages: persistedMessages,
          createdAt: createdAt ?? now,
          updatedAt: updatedAt ?? now,
          hasCustomTitle: !trimmedTitle.isEmpty,
          lastSseDoneAt: nil,
          hasSupabaseConversationStarted: true
        )
        self.sessionsStorage.insert(session, at: 0)
      }
      self.currentSessionIdStorage = id
    }
    scheduleSave()
    return session(id: id) ?? makeSession(title: resolvedTitle)
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

  // MARK: - Chat segmentation (10-minute rule)

  func shouldStartNewSessionDueToInactivity(limitSeconds: TimeInterval = 10 * 60) -> Bool {
    guard let session = currentSession(), let doneAt = session.lastSseDoneAt else { return false }
    return Date().timeIntervalSince(doneAt) > limitSeconds
  }

  func markSseDone(at date: Date = Date(), sessionId: String? = nil) {
    guard let index = sessions.firstIndex(where: { $0.id == (sessionId ?? currentSessionId) }) else { return }
    mutateState {
      self.sessionsStorage[index].lastSseDoneAt = date
      self.sessionsStorage[index].updatedAt = date
      self.sessionsStorage[index].hasSupabaseConversationStarted = true
    }
    scheduleSave()
  }

  // MARK: - Pending chat-send context (Tap/Review)

  func setPendingGalaxyStarIndices(_ indices: [Int], ttlSeconds: TimeInterval = 120) {
    let cleaned = Array(Set(indices)).sorted()
    guard !cleaned.isEmpty else { return }
    pendingGalaxyStarIndicesStorage = cleaned
    pendingGalaxyStarIndicesExpiresAt = Date().addingTimeInterval(max(1, ttlSeconds))
    NSLog("🌟 ConversationStore | setPendingGalaxyStarIndices count=%d ttl=%.0fs", cleaned.count, ttlSeconds)
  }

  func clearPendingGalaxyStarIndices() {
    pendingGalaxyStarIndicesStorage = nil
    pendingGalaxyStarIndicesExpiresAt = nil
  }

  func galaxyStarIndicesForFirstChatSend(sessionId: String) -> [Int]? {
    guard let exp = pendingGalaxyStarIndicesExpiresAt else { return nil }
    if exp <= Date() {
      clearPendingGalaxyStarIndices()
      return nil
    }
    guard let indices = pendingGalaxyStarIndicesStorage, !indices.isEmpty else { return nil }
    guard let session = session(id: sessionId) else { return nil }
    guard session.hasSupabaseConversationStarted != true else { return nil }
    return indices
  }

  func beginReviewSession(forChatId chatId: String) -> String {
    let sessionId = UUID().uuidString.lowercased()
    pendingReviewSessionIdByChatId[chatId] = sessionId
    NSLog("🧾 ConversationStore | beginReviewSession chat_id=%@ review_session_id=%@", chatId, sessionId)
    return sessionId
  }

  func pendingReviewSessionId(forChatId chatId: String) -> String? {
    pendingReviewSessionIdByChatId[chatId]
  }

  func clearReviewSession(forChatId chatId: String) {
    pendingReviewSessionIdByChatId.removeValue(forKey: chatId)
  }

  func knownStar(forChatId chatId: String) -> KnownStar? {
    knownStarsByChatId[chatId]
  }

  func updateKnownStar(forChatId chatId: String, starId: String, insightLevel: Int) {
    let trimmedStarId = starId.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedStarId.isEmpty else { return }
    knownStarsByChatId[chatId] = KnownStar(id: trimmedStarId, insightLevel: max(0, insightLevel))
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

  func replaceSessionMessages(
    sessionId: String,
    messages: [CoreChatMessage],
    updatedAt: Date? = nil,
    markSupabaseConversationStarted: Bool = false
  ) {
    guard let index = sessions.firstIndex(where: { $0.id == sessionId }) else { return }
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
      self.sessionsStorage[index].updatedAt = updatedAt ?? Date()
      if markSupabaseConversationStarted {
        self.sessionsStorage[index].hasSupabaseConversationStarted = true
      }
    }
    scheduleSave()
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
    if stateLoggingEnabled {
      NSLog("🚨 updateCurrentSessionMessages called | stack: \(Thread.callStackSymbols.joined(separator: "\n"))")
    }
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
      hasCustomTitle: !cleanTitle.isEmpty,
      lastSseDoneAt: nil,
      hasSupabaseConversationStarted: false
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
