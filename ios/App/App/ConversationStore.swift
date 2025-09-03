import Foundation

// 会话存储（单例）——多会话管理、系统提示与持久化
final class ConversationStore {
    static let shared = ConversationStore()

    struct Session: Codable {
        var id: String
        var title: String
        var systemPrompt: String
        var messages: [PersistMessage]
        var createdAt: Double
        var updatedAt: Double
    }

    struct PersistMessage: Codable {
        let id: String
        let text: String
        let isUser: Bool
        let timestamp: Double
    }

    private struct PersistModel: Codable {
        var currentSessionId: String
        var sessions: [Session]
    }

    private let queue = DispatchQueue(label: "chat.conversation.store", qos: .utility)
    private let fileURL: URL = {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("conversation_sessions.json")
    }()

    private var model = PersistModel(currentSessionId: "", sessions: [])

    private init() {
        load()
        if model.sessions.isEmpty {
            _ = createSession(title: "默认会话")
        }
        if model.currentSessionId.isEmpty, let first = model.sessions.first {
            model.currentSessionId = first.id
        }
    }

    // MARK: - Session APIs
    func listSessions() -> [Session] { model.sessions }

    func createSession(title: String) -> String {
        let now = Date().timeIntervalSince1970 * 1000
        let id = UUID().uuidString
        let s = Session(id: id, title: title, systemPrompt: "", messages: [], createdAt: now, updatedAt: now)
        model.sessions.insert(s, at: 0)
        model.currentSessionId = id
        save()
        return id
    }

    func switchSession(_ id: String) {
        guard model.sessions.contains(where: { $0.id == id }) else { return }
        model.currentSessionId = id
        save()
    }

    func clear(sessionId: String? = nil) {
        queue.async {
            let sid = sessionId ?? self.model.currentSessionId
            if let idx = self.model.sessions.firstIndex(where: { $0.id == sid }) {
                self.model.sessions[idx].messages.removeAll()
                self.model.sessions[idx].updatedAt = Date().timeIntervalSince1970 * 1000
                self.save()
            }
        }
    }

    // MARK: - Current session convenience
    private func currentIndex() -> Int? { model.sessions.firstIndex(where: { $0.id == model.currentSessionId }) }

    var systemPrompt: String {
        get { currentIndex().flatMap { model.sessions[$0].systemPrompt } ?? "" }
    }

    var messages: [ChatMessage] {
        get {
            guard let idx = currentIndex() else { return [] }
            return model.sessions[idx].messages.map { ChatMessage(id: $0.id, text: $0.text, isUser: $0.isUser, timestamp: $0.timestamp) }
        }
    }

    func setSystemPrompt(_ prompt: String) {
        queue.async {
            if let idx = self.currentIndex() {
                self.model.sessions[idx].systemPrompt = prompt
                self.model.sessions[idx].updatedAt = Date().timeIntervalSince1970 * 1000
                self.save()
            }
        }
    }

    func setMessages(_ list: [ChatMessage]) {
        queue.async {
            if let idx = self.currentIndex() {
                self.model.sessions[idx].messages = list.map { PersistMessage(id: $0.id, text: $0.text, isUser: $0.isUser, timestamp: $0.timestamp) }
                self.model.sessions[idx].updatedAt = Date().timeIntervalSince1970 * 1000
                self.save()
            }
        }
    }

    func append(_ message: ChatMessage) {
        queue.async {
            if let idx = self.currentIndex() {
                self.model.sessions[idx].messages.append(PersistMessage(id: message.id, text: message.text, isUser: message.isUser, timestamp: message.timestamp))
                self.model.sessions[idx].updatedAt = Date().timeIntervalSince1970 * 1000
                self.save()
            }
        }
    }

    func replaceLastAssistantText(_ text: String) {
        queue.async {
            if let idx = self.currentIndex() {
                var msgs = self.model.sessions[idx].messages
                if let last = msgs.lastIndex(where: { !$0.isUser }) {
                    msgs[last] = PersistMessage(id: msgs[last].id, text: text, isUser: msgs[last].isUser, timestamp: msgs[last].timestamp)
                    self.model.sessions[idx].messages = msgs
                    self.model.sessions[idx].updatedAt = Date().timeIntervalSince1970 * 1000
                    self.save()
                }
            }
        }
    }

    // MARK: - Persistence
    private func save() {
        do {
            let data = try JSONEncoder().encode(model)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            NSLog("⚠️ ConversationStore 保存失败: \(error.localizedDescription)")
        }
    }

    private func load() {
        // 兼容旧版本（单会话）
        let oldURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("conversation.json")
        if FileManager.default.fileExists(atPath: oldURL.path) {
            do {
                let oldData = try Data(contentsOf: oldURL)
                struct OldModel: Codable { let systemPrompt: String; let messages: [PersistMessage] }
                let o = try JSONDecoder().decode(OldModel.self, from: oldData)
                let now = Date().timeIntervalSince1970 * 1000
                let sid = UUID().uuidString
                self.model = PersistModel(currentSessionId: sid, sessions: [Session(id: sid, title: "迁移会话", systemPrompt: o.systemPrompt, messages: o.messages, createdAt: now, updatedAt: now)])
                try? FileManager.default.removeItem(at: oldURL)
                save()
                return
            } catch { /* ignore */ }
        }
        do {
            let data = try Data(contentsOf: fileURL)
            self.model = try JSONDecoder().decode(PersistModel.self, from: data)
        } catch {
            // 首次运行初始化
            self.model = PersistModel(currentSessionId: "", sessions: [])
        }
    }
}
