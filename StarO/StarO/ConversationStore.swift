import Foundation
import Combine
import StarOracleCore

extension Notification.Name {
  static let conversationStoreChanged = Notification.Name("conversationStoreChanged")
}

@MainActor
final class ConversationStore: ObservableObject {
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

  @Published private(set) var sessions: [Session] = []
  @Published private(set) var currentSessionId: String = ""

  private let fileURL: URL
  private var saveTask: Task<Void, Never>?

  init(fileURL: URL = ConversationStore.defaultURL()) {
    self.fileURL = fileURL
    load()
    if sessions.isEmpty {
      _ = createSession(title: "默认会话")
    }
    if currentSessionId.isEmpty {
      currentSessionId = sessions.first?.id ?? ""
    }
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
    let now = Date()
    let cleanTitle = title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let session = Session(
      id: UUID().uuidString,
      title: cleanTitle.isEmpty ? "新会话" : cleanTitle,
      systemPrompt: "",
      messages: [],
      createdAt: now,
      updatedAt: now,
      hasCustomTitle: !cleanTitle.isEmpty
    )
    sessions.insert(session, at: 0)
    currentSessionId = session.id
    scheduleSave()
    return session
  }

  @discardableResult
  func switchSession(to id: String) -> Session? {
    guard sessions.contains(where: { $0.id == id }) else { return nil }
    currentSessionId = id
    scheduleSave()
    return session(id: id)
  }

  func renameSession(id: String, title: String) {
    guard let index = sessions.firstIndex(where: { $0.id == id }) else { return }
    sessions[index].title = title
    sessions[index].hasCustomTitle = !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    sessions[index].updatedAt = Date()
    scheduleSave()
  }

  func deleteSession(id: String) {
    guard let index = sessions.firstIndex(where: { $0.id == id }) else { return }
    let deletingCurrent = sessions[index].id == currentSessionId
    sessions.remove(at: index)
    if deletingCurrent {
      if let first = sessions.first {
        currentSessionId = first.id
      } else {
        let newSession = createSession(title: "默认会话")
        currentSessionId = newSession.id
      }
    }
    scheduleSave()
  }

  // MARK: - Messages

  func messages(for id: String? = nil) -> [ChatMessage] {
    let sessionId = id ?? currentSessionId
    guard let session = sessions.first(where: { $0.id == sessionId }) else { return [] }
    return session.messages.map { persist in
      ChatMessage(
        id: persist.id,
        text: persist.text,
        isUser: persist.isUser,
        timestamp: persist.timestamp,
        isResponse: !persist.isUser
      )
    }
  }

  func updateCurrentSessionMessages(_ messages: [ChatMessage]) {
    guard let index = sessions.firstIndex(where: { $0.id == currentSessionId }) else { return }
    sessions[index].messages = messages.map { message in
      PersistMessage(
        id: message.id,
        text: message.text,
        isUser: message.isUser,
        timestamp: message.timestamp
      )
    }
    sessions[index].updatedAt = Date()
    scheduleSave()
  }

  func setSystemPrompt(_ prompt: String, sessionId: String? = nil) {
    guard let index = sessions.firstIndex(where: { $0.id == (sessionId ?? currentSessionId) }) else { return }
    sessions[index].systemPrompt = prompt
    sessions[index].updatedAt = Date()
    scheduleSave()
  }

  // MARK: - Persistence

  private func load() {
    guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
    do {
      let data = try Data(contentsOf: fileURL)
      let model = try JSONDecoder().decode(PersistModel.self, from: data)
      sessions = model.sessions
      currentSessionId = model.currentSessionId
    } catch {
      print("⚠️ ConversationStore load failed: \(error.localizedDescription)")
      sessions = []
      currentSessionId = ""
    }
  }

  private func scheduleSave() {
    saveTask?.cancel()
    let snapshot = PersistModel(currentSessionId: currentSessionId, sessions: sessions)
    saveTask = Task { [fileURL] in
      try? await Task.sleep(nanoseconds: 200_000_000) // debounce 0.2s
      do {
        let data = try JSONEncoder().encode(snapshot)
        try data.write(to: fileURL, options: .atomic)
        NotificationCenter.default.post(name: .conversationStoreChanged, object: nil)
      } catch {
        print("⚠️ ConversationStore save failed: \(error.localizedDescription)")
      }
    }
  }

  private static func defaultURL() -> URL {
    let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
    return dir.appendingPathComponent("conversation_sessions.json")
  }
}
