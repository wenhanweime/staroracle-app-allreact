import Foundation

// 简易对话存储（单例）——集中管理对话历史、系统提示与持久化
final class ConversationStore {
    static let shared = ConversationStore()

    private(set) var messages: [ChatMessage] = []
    private(set) var systemPrompt: String = ""

    private let queue = DispatchQueue(label: "chat.conversation.store", qos: .utility)
    private let fileURL: URL = {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("conversation.json")
    }()

    private init() {
        load()
    }

    func setSystemPrompt(_ prompt: String) {
        queue.async {
            self.systemPrompt = prompt
            self.save()
        }
    }

    func setMessages(_ list: [ChatMessage]) {
        queue.async {
            self.messages = list
            self.save()
        }
    }

    func append(_ message: ChatMessage) {
        queue.async {
            self.messages.append(message)
            self.save()
        }
    }

    func replaceLastAssistantText(_ text: String) {
        queue.async {
            if let idx = self.messages.lastIndex(where: { !$0.isUser }) {
                let last = self.messages[idx]
                let new = ChatMessage(id: last.id, text: text, isUser: last.isUser, timestamp: last.timestamp)
                self.messages[idx] = new
                self.save()
            }
        }
    }

    func clear() {
        queue.async {
            self.messages.removeAll()
            self.save()
        }
    }

    private struct PersistModel: Codable {
        let systemPrompt: String
        let messages: [PersistMessage]
    }

    private struct PersistMessage: Codable {
        let id: String
        let text: String
        let isUser: Bool
        let timestamp: Double
    }

    private func save() {
        do {
            let persist = PersistModel(
                systemPrompt: systemPrompt,
                messages: messages.map { PersistMessage(id: $0.id, text: $0.text, isUser: $0.isUser, timestamp: $0.timestamp) }
            )
            let data = try JSONEncoder().encode(persist)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            NSLog("⚠️ ConversationStore 保存失败: \(error.localizedDescription)")
        }
    }

    private func load() {
        do {
            let data = try Data(contentsOf: fileURL)
            let persist = try JSONDecoder().decode(PersistModel.self, from: data)
            self.systemPrompt = persist.systemPrompt
            self.messages = persist.messages.map { ChatMessage(id: $0.id, text: $0.text, isUser: $0.isUser, timestamp: $0.timestamp) }
        } catch {
            // 首次运行或解析失败时忽略
        }
    }
}

