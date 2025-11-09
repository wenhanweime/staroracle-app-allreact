import Testing
@testable import StarOracleFeatures
import StarOracleCore
import StarOracleServices

@Test @MainActor func chatStoreAddsMessages() async throws {
  let service = MockAIService()
  let store = ChatStore(
    aiService: service,
    configurationProvider: { nil }
  )

  store.addUserMessage("你好")
  let messageId = store.beginStreamingAIMessage(initial: "初始")
  store.updateStreamingMessage(id: messageId, text: "最终回答")
  store.finalizeStreamingMessage(id: messageId)

  #expect(store.messages.count == 2)
  #expect(store.messages.last?.isResponse == true)
}
