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
        Task { @MainActor in
          conversationStore.updateCurrentSessionMessages(messages)
        }
      }
      .store(in: &cancellables)
  }
}
