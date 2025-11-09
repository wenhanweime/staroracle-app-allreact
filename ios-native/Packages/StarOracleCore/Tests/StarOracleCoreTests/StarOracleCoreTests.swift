import Testing
@testable import StarOracleCore

@Test func starModelDefaults() throws {
  let star = Star(
    id: "test-star",
    x: 42,
    y: 58,
    size: 3.2,
    brightness: 0.6,
    question: "测试问题？",
    answer: "测试回答。",
    imageURL: nil,
    createdAt: .distantPast
  )

  #expect(star.primaryCategory == "philosophy_and_existence")
  #expect(star.insightLevel == nil)
  #expect(!star.isSpecial)
  #expect(!star.isStreaming)
}
