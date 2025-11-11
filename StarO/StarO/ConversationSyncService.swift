import Foundation
import Combine
import StarOracleFeatures
import StarOracleCore

@MainActor
final class ConversationSyncService {
  private var cancellables = Set<AnyCancellable>()

  init(chatStore: ChatStore, conversationStore: ConversationStore) {
    chatStore.$messages
      .combineLatest(chatStore.$isLoading)
      .debounce(for: .milliseconds(150), scheduler: RunLoop.main)
      .sink { [weak conversationStore] payload in
        let (messages, isLoading) = payload
        guard !isLoading, let conversationStore else { return }
        let signature = ConversationSyncService.signature(for: messages)
        Task.detached(priority: .utility) {
          await MainActor.run {
            if conversationStore.__updateSignature != signature {
              conversationStore.__updateSignature = signature
              conversationStore.updateCurrentSessionMessages(messages)
            }
          }
        }
      }
      .store(in: &cancellables)
  }

  private static func signature(for messages: [StarOracleCore.ChatMessage]) -> String {
    messages.map { "\($0.id)|\($0.text)|\($0.isUser)" }.joined(separator: "§")
  }
}
