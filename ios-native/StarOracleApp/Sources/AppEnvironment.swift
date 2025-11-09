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
  }
}
