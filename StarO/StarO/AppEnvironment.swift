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

  private let conversationSync: ConversationSyncService

  init() {
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

    conversationStore = ConversationStore()
    let initialMessages = conversationStore.messages()
    if !initialMessages.isEmpty {
      chatStore.loadMessages(initialMessages, title: conversationStore.currentSession()?.displayTitle)
    }
    conversationSync = ConversationSyncService(chatStore: chatStore, conversationStore: conversationStore)
  }

  func switchSession(to sessionId: String) {
    guard let session = conversationStore.switchSession(to: sessionId) else { return }
    let messages = conversationStore.messages(for: sessionId)
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
    let messages = conversationStore.messages()
    chatStore.loadMessages(messages, title: conversationStore.currentSession()?.displayTitle)
  }
}
