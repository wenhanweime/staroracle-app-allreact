import Foundation
import StarOracleCore
import StarOracleFeatures
import StarOracleServices

@MainActor
final class AppEnvironment: ObservableObject {
  let aiService: AIServiceProtocol
  let preferenceService: PreferenceServiceProtocol
  let templateService: TemplateServiceProtocol
  let inspirationService: InspirationServiceProtocol
  let starStore: StarStore
  let chatStore: ChatStore
  let galaxyStore: GalaxyStore
  let galaxyGridStore: GalaxyGridStore
  let conversationStore: ConversationStore
  let chatBridge: NativeChatBridge

  private let conversationSync: ConversationSyncService

  init(conversationStore: ConversationStore = .shared) {
    let aiService = MockAIService()
    let inspirationService = MockInspirationService()
    let templateService = MockTemplateService()
    let preferenceService = LocalPreferenceService()
    let soundService = MockSoundService()
    let hapticService = MockHapticService()

    self.aiService = aiService
    self.preferenceService = preferenceService
    self.templateService = templateService
    self.inspirationService = inspirationService
    starStore = StarStore(
      aiService: aiService,
      inspirationService: inspirationService,
      templateService: templateService,
      preferenceService: preferenceService,
      soundService: soundService,
      hapticService: hapticService
    )

    chatStore = ChatStore(
      aiService: aiService,
      configurationProvider: { await preferenceService.loadAIConfiguration() }
    )

    galaxyStore = GalaxyStore()
    galaxyGridStore = GalaxyGridStore()

    self.conversationStore = conversationStore
    let initialMessages = conversationStore.messages(forSession: nil)
    if !initialMessages.isEmpty {
      chatStore.loadMessages(initialMessages, title: conversationStore.currentSession()?.displayTitle)
    }
    chatBridge = NativeChatBridge(
      chatStore: chatStore,
      conversationStore: conversationStore,
      aiService: aiService,
      preferenceService: preferenceService
    )
    conversationSync = ConversationSyncService(chatStore: chatStore, conversationStore: conversationStore)
  }

  func switchSession(to sessionId: String) {
    guard let session = conversationStore.switchSession(to: sessionId) else { return }
    let messages = conversationStore.messages(forSession: sessionId)
    chatStore.loadMessages(messages, title: session.displayTitle)
  }

  func createSession(title: String?) {
    let session = conversationStore.createSession(title: title)
    chatStore.loadMessages([], title: session.displayTitle)
  }

  func renameSession(id: String, title: String) {
    conversationStore.renameSession(id: id, title: title)
  }

  func deleteSession(id: String) {
    conversationStore.deleteSession(id: id)
    let messages = conversationStore.messages(forSession: nil)
    chatStore.loadMessages(messages, title: conversationStore.currentSession()?.displayTitle)
  }
}
