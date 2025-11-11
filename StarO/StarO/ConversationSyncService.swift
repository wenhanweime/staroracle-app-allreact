import Foundation
import Combine
import StarOracleFeatures

@MainActor
final class ConversationSyncService {
  private var cancellables = Set<AnyCancellable>()

  init(chatStore: ChatStore, conversationStore: ConversationStore) {
    chatStore.$messages
      .receive(on: DispatchQueue.main)
      .sink { messages in
        DispatchQueue.main.async {
          conversationStore.updateCurrentSessionMessages(messages)
        }
      }
      .store(in: &cancellables)
  }
}
