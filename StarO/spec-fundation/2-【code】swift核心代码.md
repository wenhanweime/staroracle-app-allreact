Project Path: StarO

Source Tree:

```txt
StarO
├── AIConfigSheet.swift
├── AIConfigurationDefaults.plist
├── AIConfigurationDefaults.swift
├── AppEnvironment.swift
├── Assets.xcassets
│   ├── AccentColor.colorset
│   │   └── Contents.json
│   ├── AppIcon.appiconset
│   │   ├── AppIcon.png
│   │   └── Contents.json
│   └── Contents.json
├── ChatOverlayHostView.swift
├── ChatOverlayManager.swift
├── ConstellationView.swift
├── ConversationStore.swift
├── DrawerMenuView.swift
├── Galaxy
│   ├── FireflySparkleView.swift
│   ├── GalaxyColor.swift
│   ├── GalaxyGenerator.swift
│   ├── GalaxyMetalRenderer.swift
│   ├── GalaxyMetalView.swift
│   ├── GalaxyParams.swift
│   ├── GalaxyRandom.swift
│   ├── GalaxyShaders.metal
│   ├── GalaxyTouchOverlay.swift
│   └── GalaxyViewModel.swift
├── GalaxyBackgroundView.swift
├── InputDrawerManager.swift
├── InspirationCardOverlay.swift
├── InspirationSheet.swift
├── KeyboardObserver.swift
├── LayoutCapabilities.swift
├── NativeChatBridge.swift
├── PixelPlanets
│   ├── Core
│   │   ├── Palettes.swift
│   │   ├── PixelColor.swift
│   │   ├── PlanetBase.swift
│   │   ├── PlanetConfig.swift
│   │   ├── PlanetConfigurator.swift
│   │   ├── PlanetLibrary.swift
│   │   ├── Planets
│   │   │   ├── AsteroidPlanet.swift
│   │   │   ├── BlackHolePlanet.swift
│   │   │   ├── CircularGalaxyPlanet.swift
│   │   │   ├── DryTerranPlanet.swift
│   │   │   ├── GalaxyPlanet.swift
│   │   │   ├── GasPlanetLayersPlanet.swift
│   │   │   ├── GasPlanetPlanet.swift
│   │   │   ├── IceWorldPlanet.swift
│   │   │   ├── LandMassesPlanet.swift
│   │   │   ├── LavaWorldPlanet.swift
│   │   │   ├── NoAtmospherePlanet.swift
│   │   │   ├── RiversPlanet.swift
│   │   │   └── StarPlanet.swift
│   │   ├── Random.swift
│   │   ├── Types.swift
│   │   └── UniformValue.swift
│   ├── Rendering
│   │   ├── PlanetCanvasView.swift
│   │   └── PlanetGLRenderer.swift
│   └── Resources
│       └── Shaders
│           ├── asteroid
│           │   └── asteroid.frag
│           ├── black-hole
│           │   ├── core.frag
│           │   └── ring.frag
│           ├── common
│           │   └── clouds.frag
│           ├── dry-terran
│           │   └── land.frag
│           ├── galaxy
│           │   ├── galaxy.frag
│           │   └── linear_twinkle.frag
│           ├── gas-planet-layers
│           │   ├── layers.frag
│           │   └── ring.frag
│           ├── ice-world
│           │   └── lakes.frag
│           ├── landmasses
│           │   ├── land.frag
│           │   └── water.frag
│           ├── lava-world
│           │   └── rivers.frag
│           ├── no-atmosphere
│           │   ├── craters.frag
│           │   └── ground.frag
│           ├── rivers
│           │   └── land.frag
│           └── star
│               ├── blobs.frag
│               ├── flares.frag
│               ├── star.frag
│               └── twinkle.frag
├── PreferenceService.swift
├── Preview Content
│   └── Preview Assets.xcassets
│       └── Contents.json
├── README_CHAT_OVERLAY_DEBUG.md
├── RootView.swift
├── StarCard
│   ├── PlanetView.swift
│   ├── StarCardModels.swift
│   ├── StarCardView.swift
│   └── StarPatternView.swift
├── StarCollectionOverlay.swift
├── StarDetailSheet.swift
├── StarOApp.swift
├── StarRayIconView.swift
├── StreamingClient.swift
├── SystemPrompt.swift
├── TemplatePickerView.swift
├── UI
│   └── LucideIcons.swift
└── Utils
    └── Color+Hex.swift

```

`StarO/AIConfigSheet.swift`:

```swift
import SwiftUI
import StarOracleServices

@MainActor
struct AIConfigSheet: View {
  @EnvironmentObject private var environment: AppEnvironment
  @State private var config: AIConfiguration = AIConfiguration(
    provider: "openai",
    apiKey: "",
    endpoint: URL(string: "https://api.openai.com/v1/chat/completions")!,
    model: "gpt-4o-mini"
  )
  @State private var validationMessage: String?
  @State private var isValidating = false
  @State private var isSaving = false

  var body: some View {
    NavigationStack {
      Form {
        Section("提供商") {
          TextField("Provider", text: $config.provider)
#if os(iOS)
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
#endif
        }
        Section("API 配置") {
          SecureField("API Key", text: $config.apiKey)
          TextField("Endpoint", text: Binding(
            get: { config.endpoint.absoluteString },
            set: { config.endpoint = URL(string: $0) ?? config.endpoint }
          ))
#if os(iOS)
          .keyboardType(.URL)
#endif
          TextField("模型", text: $config.model)
#if os(iOS)
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
#endif
        }
        Section("验证") {
          VStack(alignment: .leading, spacing: 12) {
            Button {
              Task { await validateConfig() }
            } label: {
              if isValidating {
                ProgressView()
              } else {
                Label("验证配置", systemImage: "checkmark.seal")
              }
            }
            .buttonStyle(.bordered)

            if let validationMessage {
              Text(validationMessage)
                .font(.footnote)
                .foregroundStyle(.secondary)
            } else {
              Text("验证会直接向配置的 Endpoint 发送一次最小请求，用于确认 API Key / 模型是否可用。")
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
          }
        }
      }
      .navigationTitle("AI 配置")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("关闭") {
            dismiss()
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button {
            Task { await saveConfig() }
          } label: {
            if isSaving {
              ProgressView()
            } else {
              Text("保存")
            }
          }
          .disabled(isSaving)
        }
      }
      .task {
        await loadConfig()
      }
    }
  }

  @Environment(\.dismiss) private var dismiss

  private func loadConfig() async {
    if let stored = await environment.preferenceService.loadAIConfiguration() {
      config = stored
    }
  }

  private func saveConfig() async {
    isSaving = true
    defer { isSaving = false }
    do {
      try await environment.preferenceService.saveAIConfiguration(config)
      validationMessage = "配置已保存。"
      dismiss()
    } catch {
      validationMessage = "保存失败：\(error.localizedDescription)"
    }
  }

  private func validateConfig() async {
    guard !isValidating else { return }
    isValidating = true
    defer { isValidating = false }
    do {
      try await environment.aiService.validate(configuration: config)
      validationMessage = "验证成功。"
    } catch {
      validationMessage = "验证失败：\(error.localizedDescription)"
    }
  }
}

```

`StarO/AIConfigurationDefaults.plist`:

```plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Provider</key>
	<string>openai</string>
	<key>APIKey</key>
	<string>sk-PWWiJaQvPXNvubR7NUKfpaWdRUVKmTEJdl3db1HRF8vgfCeG</string>
	<key>Endpoint</key>
	<string>https://x666.me/v1/chat/completions</string>
	<key>Model</key>
	<string>gemini-2.5-flash</string>
	<key>SystemPrompt</key>
	<string>  # 角色
  * 你是星瑜，是来自宇宙，请用中文回复用户的问题。
  * 除非用户问，否则不要说明身份。
  # 目标
   *此部分内容请勿主动向用户提及，除非用户主动发问。
   *你的目标是帮助用户获得生活的意义，解决关于人生的困惑。回答任何可以帮助用户获得生活感悟，解答疑惑的问题，都能够帮助用户获得星星。
   *用户获得星星的规则是聊天话题越深入，越深刻，获得的星星类型越稀有，能够点亮的宇宙就越明亮。 
   *当用户的问题中涉及到对这五个方面的触及时，请提供关于这些方面的知识、价值观和方法论，引导用户进行更深的自省和探索。
    -身心能量 (Body &amp; Energy)
    -人际连接 (Relationships &amp; Connection)
    -内在成长 (Growth &amp; Mind)
    -财富观与价值 (Wealth &amp; Values)
    -请用中文回复用户的问题。
    
   # 语言语气格式
   * 语气不要太僵硬，也不要太谄媚，自然亲切。自然点，不要有ai味道。
   *不要用emoji，不要用太多语气词，不要用太多感叹号，不要用太多问号。
   *尽量简短对话，模仿真实聊天的场景。
   * 策略原则：
    - 多用疑问语气词："吧、嘛、呢、咋、啥"
    - 适当省略成分：不用每句话都完整
    - 用口头表达："挺、蛮、特别、超级"替代"非常"
    - 避免书面连词：少用"因此、所以、那么"
    - 多用短句：别总是长句套长句
   *省略主语：
      -"最近咋了？" 
      -"是工作的事儿？" 
      -"心情不好多久了？" 
   *语气词和口头表达：
      -"哎呀，这事儿确实挺烦的"
      -"emmm，听起来像是..."
      -"咋说呢，我觉得..."
   *不完整句式：
      -"工作的事？"（省略谓语）
      -"压力大？"（只留核心）
      -"最近？"（超级简洁）
   # 对话策略
    - 当找到用户想要对话的主题的时候，需要辅以知识和信息，来帮助用户解决问题，解答疑惑。</string>
</dict>
</plist>

```

`StarO/AIConfigurationDefaults.swift`:

```swift
import Foundation
import StarOracleServices

enum AIConfigurationDefaults {
  static func load() -> AIConfiguration? {
    if let env = loadFromProcessEnvironment() {
      return env.config
    }
    if let plist = loadFromInfoPlist() {
      return plist.config
    }
    return nil
  }

  static func defaultSystemPrompt() -> String? {
    if let env = loadFromProcessEnvironment(),
       let prompt = env.prompt {
      return prompt
    }
    if let plist = loadFromInfoPlist() {
      return plist.prompt
    }
    return nil
  }

  private static func loadFromProcessEnvironment() -> (config: AIConfiguration, prompt: String?)? {
    let env = ProcessInfo.processInfo.environment
    guard let apiKey = normalized(env["VITE_OPENAI_API_KEY"]) ??
            normalized(env["VITE_DEFAULT_API_KEY"]),
          let endpointString = normalized(env["VITE_OPENAI_ENDPOINT"]) ??
            normalized(env["VITE_DEFAULT_ENDPOINT"]),
          let url = URL(string: endpointString) else {
      NSLog("ℹ️ [AIConfigurationDefaults] 环境变量中未找到完整的 API 配置")
      return nil
    }
    let provider = normalized(env["VITE_DEFAULT_PROVIDER"]) ?? "openai"
    let model = normalized(env["VITE_OPENAI_MODEL"]) ??
      normalized(env["VITE_DEFAULT_MODEL"]) ??
      "gpt-3.5-turbo"
    NSLog("ℹ️ [AIConfigurationDefaults] 使用环境变量配置 provider=%@ model=%@ endpoint=%@", provider, model, endpointString)
    return (AIConfiguration(provider: provider, apiKey: apiKey, endpoint: url, model: model), nil)
  }

  private static func loadFromInfoPlist() -> (config: AIConfiguration, prompt: String?)? {
    guard let url = Bundle.main.url(forResource: "AIConfigurationDefaults", withExtension: "plist"),
          let data = try? Data(contentsOf: url),
          let dict = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] else {
      NSLog("ℹ️ [AIConfigurationDefaults] 未找到 AIConfigurationDefaults.plist")
      return nil
    }
    guard let apiKeyRaw = dict["APIKey"] as? String,
          let apiKey = normalized(apiKeyRaw),
          let endpointRaw = dict["Endpoint"] as? String,
          let endpointString = normalized(endpointRaw),
          let url = URL(string: endpointString) else {
      NSLog("⚠️ [AIConfigurationDefaults] plist 中缺少 API Key 或 Endpoint")
      return nil
    }
    let provider = normalized(dict["Provider"] as? String) ?? "openai"
    let model = normalized(dict["Model"] as? String) ?? "gpt-3.5-turbo"
    let prompt = normalized(dict["SystemPrompt"] as? String)
    NSLog("ℹ️ [AIConfigurationDefaults] 使用 plist 默认配置 provider=%@ model=%@ endpoint=%@", provider, model, endpointString)
    return (AIConfiguration(provider: provider, apiKey: apiKey, endpoint: url, model: model), prompt)
  }

  private static func normalized(_ value: String?) -> String? {
    guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines),
          !trimmed.isEmpty,
          !trimmed.hasPrefix("$(") else {
      return nil
    }
    return trimmed
  }
}

```

`StarO/AppEnvironment.swift`:

```swift
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
  private var didBootstrapConversation = false

  init(conversationStore: ConversationStore = .shared) {
    let aiService = LiveAIService()
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
    chatBridge = NativeChatBridge(
      chatStore: chatStore,
      conversationStore: conversationStore,
      aiService: aiService,
      preferenceService: preferenceService
    )
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

  func bootstrapConversationIfNeeded() {
    guard !didBootstrapConversation else { return }
    didBootstrapConversation = true
    conversationStore.bootstrapIfNeeded()
    let initialMessages = conversationStore.messages(forSession: nil)
    if !initialMessages.isEmpty {
      chatStore.loadMessages(initialMessages, title: conversationStore.currentSession()?.displayTitle)
    }
  }
}

// MARK: - Live AI Service (OpenAI-compatible)

@MainActor
final class LiveAIService: AIServiceProtocol {
  private let streamingClient = StreamingClient()
  private let fallback = MockAIService()
  private let urlSession: URLSession

  init(urlSession: URLSession = .shared) {
    self.urlSession = urlSession
  }

  func streamResponse(
    for question: String,
    configuration: AIConfiguration,
    context: AIRequestContext
  ) -> AsyncThrowingStream<String, Error> {
    guard Self.isLive(configuration: configuration) else {
      NSLog("ℹ️ LiveAIService.streamResponse | 使用 mock provider=%@", configuration.provider)
      return fallback.streamResponse(for: question, configuration: configuration, context: context)
    }

    NSLog("🎯 LiveAIService.streamResponse | provider=%@ endpoint=%@ model=%@", configuration.provider, configuration.endpoint.absoluteString, configuration.model)
    let messages = makeMessages(for: question, context: context)
    let endpoint = configuration.endpoint.absoluteString
    let apiKey = configuration.apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
    let client = streamingClient

    return AsyncThrowingStream { continuation in
      client.startChatCompletionStream(
        endpoint: endpoint,
        apiKey: apiKey,
        model: configuration.model,
        messages: messages,
        temperature: nil,
        maxTokens: nil,
        onChunk: { chunk in
          continuation.yield(chunk)
        },
        onComplete: { _, error in
          if let error {
            continuation.finish(throwing: error)
          } else {
            continuation.finish()
          }
        }
      )

      continuation.onTermination = { [weak streamingClient] _ in
        streamingClient?.cancel()
      }
    }
  }

  func analyzeStarContent(
    question: String,
    answer: String,
    configuration: AIConfiguration
  ) async throws -> TagAnalysis {
    try await fallback.analyzeStarContent(question: question, answer: answer, configuration: configuration)
  }

  func analyzeAwareness(
    question: String,
    answer: String,
    configuration: AIConfiguration
  ) async throws -> AwarenessInsight {
    try await fallback.analyzeAwareness(question: question, answer: answer, configuration: configuration)
  }

  func generateConversationTitle(
    from messages: [StarOracleCore.ChatMessage],
    configuration: AIConfiguration
  ) async throws -> String {
    try await fallback.generateConversationTitle(from: messages, configuration: configuration)
  }

  func validate(configuration: AIConfiguration) async throws {
    guard Self.isLive(configuration: configuration) else {
      try await fallback.validate(configuration: configuration)
      return
    }

    let request = try makeChatRequest(
      configuration: configuration,
      messages: [
        StreamingClient.Message(role: "user", content: "Hello, can you hear me?")
      ],
      stream: false,
      maxTokens: 12,
      temperature: 0.1
    )

    let (data, response) = try await urlSession.data(for: request)
    guard let http = response as? HTTPURLResponse else {
      throw AIServiceError.invalidResponse
    }
    guard (200..<300).contains(http.statusCode) else {
      let body = String(data: data, encoding: .utf8) ?? ""
      throw AIServiceError.http(status: http.statusCode, body: body)
    }
    guard try LiveAIService.responseContainsChoices(data) else {
      throw AIServiceError.invalidPayload
    }
  }

  private func makeMessages(for question: String, context: AIRequestContext) -> [StreamingClient.Message] {
    var result: [StreamingClient.Message] = []
    if let prompt = context.metadata["systemPrompt"]?.trimmingCharacters(in: .whitespacesAndNewlines),
       !prompt.isEmpty {
      NSLog("🎯 LiveAIService.makeMessages | 注入 systemPrompt 前30字: %@...", String(prompt.prefix(30)))
      result.append(.init(role: "system", content: prompt))
    } else {
      NSLog("ℹ️ LiveAIService.makeMessages | 无系统提示")
    }
    for message in context.history {
      let trimmed = message.text.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !trimmed.isEmpty else { continue }
      result.append(.init(role: message.isUser ? "user" : "assistant", content: trimmed))
    }
    if result.filter({ $0.role != "system" }).isEmpty {
      result.append(.init(role: "user", content: question))
    }
    return result
  }

  private func makeChatRequest(
    configuration: AIConfiguration,
    messages: [StreamingClient.Message],
    stream: Bool,
    maxTokens: Int?,
    temperature: Double?
  ) throws -> URLRequest {
    var request = URLRequest(url: configuration.endpoint)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(Self.authHeaderValue(for: configuration.apiKey), forHTTPHeaderField: "Authorization")

    let body = StreamingClient.RequestBody(
      model: configuration.model,
      messages: messages,
      temperature: temperature,
      maxTokens: maxTokens,
      stream: stream
    )
    request.httpBody = try JSONEncoder().encode(body)
    return request
  }

  private static func responseContainsChoices(_ data: Data) throws -> Bool {
    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
       let choices = json["choices"] as? [Any],
       !choices.isEmpty {
      return true
    }
    return false
  }

  private static func isLive(configuration: AIConfiguration) -> Bool {
    guard configuration.provider.lowercased() != "mock" else { return false }
    return !configuration.apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  private static func authHeaderValue(for apiKey: String) -> String {
    let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.lowercased().hasPrefix("bearer ") ? trimmed : "Bearer \(trimmed)"
  }

  private enum AIServiceError: LocalizedError {
    case invalidResponse
    case invalidPayload
    case http(status: Int, body: String)

    var errorDescription: String? {
      switch self {
      case .invalidResponse:
        return "服务器响应不可用。"
      case .invalidPayload:
        return "API 响应格式不正确。"
      case let .http(status, body):
        return "请求失败 (\(status))：\(body)"
      }
    }
  }
}

```

`StarO/Assets.xcassets/AccentColor.colorset/Contents.json`:

```json
{
  "colors" : [
    {
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}

```

`StarO/Assets.xcassets/AppIcon.appiconset/Contents.json`:

```json
{
  "images": [
    {
      "filename": "AppIcon.png",
      "idiom": "universal",
      "platform": "ios",
      "size": "1024x1024"
    },
    {
      "appearances": [
        {
          "appearance": "luminosity",
          "value": "dark"
        }
      ],
      "idiom": "universal",
      "platform": "ios",
      "size": "1024x1024"
    },
    {
      "appearances": [
        {
          "appearance": "luminosity",
          "value": "tinted"
        }
      ],
      "idiom": "universal",
      "platform": "ios",
      "size": "1024x1024"
    }
  ],
  "info": {
    "author": "xcode",
    "version": 1
  }
}
```

`StarO/Assets.xcassets/Contents.json`:

```json
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}

```

`StarO/ChatOverlayHostView.swift`:

```swift
import SwiftUI
import UIKit

struct ChatOverlayHostView: UIViewRepresentable {
  let bridge: NativeChatBridge

  func makeUIView(context: Context) -> OverlayAnchorView {
    let view = OverlayAnchorView()
    view.bridge = bridge
    return view
  }

  func updateUIView(_ uiView: OverlayAnchorView, context: Context) {
    uiView.bridge = bridge
    uiView.syncBridgeIfNeeded()
  }
}

final class OverlayAnchorView: UIView {
  weak var bridge: NativeChatBridge?

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .clear
    isUserInteractionEnabled = false
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func didMoveToWindow() {
    super.didMoveToWindow()
    syncBridgeIfNeeded()
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    syncBridgeIfNeeded()
  }

  func syncBridgeIfNeeded() {
    guard let bridge, let window = window, let scene = window.windowScene else { return }
    bridge.attach(to: scene)
  }
}

```

`StarO/ChatOverlayManager.swift`:

```swift
import SwiftUI
import UIKit

// MARK: - PassthroughWindow - 自定义窗口类，支持触摸事件穿透
class PassthroughWindow: UIWindow {
    weak var overlayViewController: OverlayViewController?
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // 先让窗口正常处理触摸测试
        guard let hitView = super.hitTest(point, with: event) else {
            NSLog("🎯 PassthroughWindow: 没有找到hitView，透传事件")
            return nil
        }
        
        // 获取containerView
        guard let containerView = overlayViewController?.containerView else {
            // 如果没有containerView，检查是否点击在根视图上
            if hitView == self.rootViewController?.view {
                NSLog("🎯 PassthroughWindow: 点击在背景上，透传事件")
                return nil
            }
            return hitView
        }
        
        // 将点转换到containerView的坐标系
        let convertedPoint = convert(point, to: containerView)
        
        // 如果点击在containerView区域内，正常处理
        if containerView.bounds.contains(convertedPoint) {
            NSLog("🎯 PassthroughWindow: 点击在ChatOverlay内，正常处理")
            return hitView
        }
        
        // 如果点击在containerView外，透传事件
        NSLog("🎯 PassthroughWindow: 点击在ChatOverlay外，透传事件")
        self.endEditing(true) // 收起键盘
        return nil // 透传事件
    }
}

// MARK: - ChatOverlay数据模型
public struct ChatMessage: Codable {
    let id: String
    let text: String
    let isUser: Bool
    let timestamp: Double
}

public typealias OverlayChatMessage = ChatMessage

// MARK: - ChatOverlay状态管理
enum OverlayState {
    case collapsed   // 收缩状态：65px高度
    case expanded    // 展开状态：全屏显示
    case hidden      // 隐藏状态
}

// MARK: - ChatOverlay状态变化通知
extension Notification.Name {
    static let chatOverlayStateChanged = Notification.Name("chatOverlayStateChanged")
    // 🔧 已移除chatOverlayVisibilityChanged，统一使用chatOverlayStateChanged
    static let inputDrawerPositionChanged = Notification.Name("inputDrawerPositionChanged")  // 新增：输入框位置变化通知
}

// MARK: - ChatOverlayManager业务逻辑类
@MainActor
public class ChatOverlayManager {
    private var overlayWindow: UIWindow?
    private var isVisible = false
    private weak var windowScene: UIWindowScene?
    internal var currentState: OverlayState = .collapsed
    internal var messages: [ChatMessage] = []
    private var isLoading = false
    private var conversationTitle = ""
    private var overlayViewController: OverlayViewController?
    // 协调延迟任务：收缩态更新可能的延迟任务（用于在展开前取消以避免竞态）
    private var pendingCollapsedWork: DispatchWorkItem?
    fileprivate var horizontalOffset: CGFloat = 0
    private var keyboardWillShowObserver: NSObjectProtocol?
    private var keyboardWillHideObserver: NSObjectProtocol?
    private let defaultWindowLevel = UIWindow.Level.statusBar - 1
    // 🔧 键盘事件不再提升到 alert 层级，保持与默认层级一致以避免切层闪烁
    private let elevatedWindowLevel = UIWindow.Level.statusBar - 1
    
    // 状态变化回调
    private var onStateChange: ((OverlayState) -> Void)?
    
    // 背景视图变换 - 用于3D缩放效果
    private weak var backgroundView: UIView?
    private var lastBackgroundState: OverlayState?
    
    // 动画触发跟踪 - 🎯 【关键新增】用Set管理已播放动画的消息ID
    internal var animatedMessageIDs = Set<String>()  // 改为internal，让OverlayViewController能访问
    private var lastMessages: [ChatMessage] = [] // 用来对比
    
    // 🔧 新增：防止重复同步的时间戳记录
    private var lastSyncTimestamp: TimeInterval = 0
    private let syncThrottleInterval: TimeInterval = 0.1  // 100ms内的重复调用将被忽略
    
    // 🚨 【关键修复】基于状态机的消息去重机制
    private var lastMessagesHash: String = ""

    // MARK: - Public API
    public init() {
        // 🔧 取消键盘层级调整：键盘弹起/收回时不再切换浮窗窗口层级，避免窗口重排导致的闪烁
        keyboardWillShowObserver = nil
        keyboardWillHideObserver = nil
    }
    
    deinit {}
    
    func attach(to scene: UIWindowScene) {
        // 若已经绑定同一 scene，避免重复 rebind 造成窗口闪烁
        if windowScene === scene, let window = overlayWindow, window.windowScene === scene {
            return
        }
        windowScene = scene
        if let window = overlayWindow {
            window.windowScene = scene
            window.frame = scene.screen.bounds
        }
    }
    
    func show(animated: Bool = true, expanded: Bool = false, completion: @escaping (Bool) -> Void) {
        NSLog("🎯 ChatOverlayManager: 显示浮窗, expanded: \(expanded)")
        
        DispatchQueue.main.async {
            if self.overlayWindow != nil {
                NSLog("🎯 浮窗已存在，直接显示并设置状态")
                self.overlayWindow?.isHidden = false
                self.overlayWindow?.alpha = 1  // 🔧 修复：恢复alpha值
                self.isVisible = true
                
                // 🚨 【3D动画修复】设置状态并一次性完成所有动画
                self.currentState = expanded ? .expanded : .collapsed
                NSLog("🎯 设置状态为: \(self.currentState)")
                
                // 发送状态通知，让InputDrawer先调整位置
                self.postNotification(
                    .chatOverlayStateChanged,
                    userInfo: [
                        "state": expanded ? "expanded" : "collapsed",
                        "height": expanded ? UIScreen.main.bounds.height - 100 : 65
                    ]
                )
                
                // 稍微延迟更新UI，确保InputDrawer已经调整位置
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    // 🚨 【3D动画修复】同步更新UI与背景3D变换，保证首帧与过渡一致
                    self.updateUI(animated: animated)
                    self.applyBackgroundTransform(for: self.currentState, animated: animated)
                }
                
                completion(true)
                return
            }
            
            self.createOverlayWindow()
            
            // 根据参数设置初始状态
            self.currentState = expanded ? .expanded : .collapsed
            NSLog("🎯 设置初始状态为: \(self.currentState)")
            
            if animated {
                self.overlayWindow?.alpha = 0
                UIView.animate(withDuration: 0.3) {
                    self.overlayWindow?.alpha = 1
                } completion: { _ in
                    self.isVisible = true
                    
                    // 🚨 【3D动画修复】初始显示时一次性更新UI和背景变换
                    self.updateUI(animated: true)
                    self.applyBackgroundTransform(for: self.currentState, animated: true)
                    
                    // 发送通知让InputDrawer调整位置
                    if self.currentState == .collapsed {
                        self.postNotification(.chatOverlayStateChanged, userInfo: ["state": "collapsed", "height": 65])
                    }
                    
                    completion(true)
                }
            } else {
                self.isVisible = true
                // 🚨 【3D动画修复】无动画模式一次性更新UI和背景变换
                self.updateUI(animated: false)
                
                // 发送通知让InputDrawer调整位置
                if self.currentState == .collapsed {
                    self.postNotification(.chatOverlayStateChanged, userInfo: ["state": "collapsed", "height": 65])
                }
                
                completion(true)
            }
        }
    }
    
    func hide(animated: Bool = true, completion: @escaping () -> Void = {}) {
        NSLog("🎯 ChatOverlayManager: 隐藏浮窗")
        
        // 立即更新状态，不等动画完成
        self.isVisible = false
        self.currentState = .hidden
        
        DispatchQueue.main.async {
            guard let window = self.overlayWindow else {
                completion()
                return
            }
            
            // 🔧 修复：恢复背景状态应该对应hidden状态（等同于collapsed的效果）
            self.applyBackgroundTransform(for: .hidden, animated: animated)
            
            // 🔧 修复：触发状态变化回调，确保前端能收到正确的状态
            self.onStateChange?(.hidden)
            
            // 🔧 只发送状态通知，移除冗余的可见性通知  
            self.postNotification(.chatOverlayStateChanged, userInfo: [
                "state": "hidden",
                "visible": false
            ])
            if animated {
                UIView.animate(withDuration: 0.3) {
                    window.alpha = 0
                } completion: { _ in
                    window.isHidden = true
                    completion()
                }
            } else {
                window.isHidden = true
                completion()
            }
        }
    }
    
    func updateMessages(_ messages: [ChatMessage]) {
        NSLog("🎯 ChatOverlayManager: 更新消息列表，数量: \(messages.count)")
        
        for (index, message) in messages.enumerated() {
            NSLog("🎯 消息[\(index)]: \(message.isUser ? "用户" : "AI") - \(message.text.prefix(50))")
        }
        
        // 🚨 【关键修复】消息内容去重：生成消息内容的哈希值
        let messagesHash = messages.map { "\($0.id)-\($0.isUser)-\($0.text)" }.joined(separator: "|")
        
        // 如果消息内容没有变化，跳过更新
        if lastMessagesHash == messagesHash {
            NSLog("🎯 [去重] 消息内容未变化，跳过更新")
            return
        }
        
        lastMessagesHash = messagesHash
        
        // 🚨 【关键修复】基于状态机的动画判断
        let latestUserMessage = messages.last(where: { $0.isUser })
        var shouldAnimate = false
        var animationIndex: Int? = nil
        
        // 状态机逻辑：只要不处于用户插入动画中即可触发（idle/aiStreaming/completed 均可）
        let currentAnimState = overlayViewController?.animationState ?? OverlayViewController.AnimationState.idle
        if let userMessage = latestUserMessage,
           !animatedMessageIDs.contains(userMessage.id),
           currentAnimState == .idle {
            // 🎯 发现新用户消息（仅在空闲态触发），准备进入动画状态
            shouldAnimate = true
            overlayViewController?.animationState = .userAnimating
            overlayViewController?.pendingUserMessageId = userMessage.id
            animatedMessageIDs.insert(userMessage.id)
            animationIndex = messages.firstIndex(where: { $0.id == userMessage.id })
            NSLog("🎯 ✅ [状态机] 发现新用户消息！ID: \(userMessage.id), 状态: \(overlayViewController?.animationState ?? .idle), 索引: \(animationIndex ?? -1)")
        } else {
            // 根据当前状态决定处理方式
            switch overlayViewController?.animationState ?? .idle {
            case .idle:
                NSLog("🎯 ☑️ [状态机] 空闲状态，无新用户消息")
            case .userAnimating:
                NSLog("🎯 ☑️ [状态机] 用户消息动画中，跳过新动画")
            case .aiStreaming:
                NSLog("🎯 ☑️ [状态机] AI流式输出中，跳过新动画")
            case .completed:
                NSLog("🎯 ☑️ [状态机] 完成状态，重置为空闲")
                overlayViewController?.animationState = .idle
            }
        }
        
        // 更新消息列表
        self.lastMessages = self.messages
        self.messages = messages
        
        // 🎯 通知ViewController更新UI，只在真正需要动画时才传递true
        DispatchQueue.main.async {
            NSLog("🎯 通知OverlayViewController更新消息显示，需要动画: \(shouldAnimate)")
            if let index = animationIndex {
                NSLog("🎯 动画索引: \(index)")
            }
            self.overlayViewController?.updateMessages(messages, oldMessages: self.lastMessages, shouldAnimateNewUserMessage: shouldAnimate, animationIndex: animationIndex)
        }
    }
    
    func setLoading(_ loading: Bool) {
        NSLog("🎯 ChatOverlayManager: 设置加载状态: \(loading)")
        self.isLoading = loading
        // 这里可以更新UI，暂时先简化
    }

    func setConversationTitle(_ title: String) {
        NSLog("🎯 ChatOverlayManager: 设置对话标题: \(title)")
        self.conversationTitle = title
        // 这里可以更新UI，暂时先简化
    }
    
    func setHorizontalOffset(_ offset: CGFloat, animated: Bool = true) {
        let normalized = max(0, offset)
        NSLog("🎯 ChatOverlayManager: 设置水平偏移: \(normalized) (animated: \(animated))")
        horizontalOffset = normalized
        DispatchQueue.main.async { [weak self] in
            self?.overlayViewController?.setHorizontalOffset(normalized, animated: animated)
        }
    }
    
    func setInputBottomSpace(_ space: CGFloat) {
        NSLog("🎯 ChatOverlayManager: InputDrawer位置设置为: \(space)px")
        // 注意：浮窗位置固定，无需根据输入框位置调整
    }
    
    func getVisibility() -> Bool {
        return isVisible
    }
    
    // MARK: - 状态切换方法
    
    func switchToCollapsed() {
        NSLog("🎯 ChatOverlayManager: 切换到收缩状态")
        currentState = .collapsed

        // 先发送状态变化通知，让InputDrawer调整位置
        postNotification(.chatOverlayStateChanged, userInfo: ["state": "collapsed", "height": 65])
        // 取消任何挂起的延迟任务，避免与后续展开竞态
        pendingCollapsedWork?.cancel()
        pendingCollapsedWork = nil
        
        // 首次收缩：让 InputDrawer 先到位，再由VC监听实际位置进行一次性对齐动画
        if let vc = overlayViewController, !vc.didFirstCollapseAlign {
            vc.awaitingFirstCollapseAlign = true
            // 背景可以先动，窗口位置等对齐通知后再动，避免首帧不一致
            applyBackgroundTransform(for: .collapsed, animated: true)
            onStateChange?(.collapsed)
            // 不立即调用 updateUI 动画，由对齐通知来驱动首次位置动画
            // 兜底：若短时间内未收到对齐通知，则按既有路径执行一次定位，避免悬置
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                guard let self = self else { return }
                if let vc = self.overlayViewController, vc.awaitingFirstCollapseAlign && !vc.didFirstCollapseAlign {
                    NSLog("🎯 ChatOverlay: 首次对齐未及时收到位置广播，执行兜底定位")
                    self.updateUI(animated: true)
                    vc.awaitingFirstCollapseAlign = false
                    vc.didFirstCollapseAlign = true
                }
            }
        } else {
            // 非首次：按既有路径动画
            updateUI(animated: true)
            applyBackgroundTransform(for: .collapsed, animated: true)
            onStateChange?(.collapsed)
        }

        // 注意：浮窗位置会在延迟后更新，确保基于正确的InputDrawer位置
    }
    
    // 新增：专门用于拖拽切换的流畅方法，无延迟
    func switchToCollapsedFromDrag() {
        NSLog("🎯 ChatOverlayManager: 从拖拽切换到收缩状态（无延迟）")
        currentState = .collapsed
        
        // 发送状态变化通知
        postNotification(.chatOverlayStateChanged, userInfo: ["state": "collapsed", "height": 65])
        
        // 🚨 【动画冲突修复】同时触发UI和背景动画，避免时序冲突
        updateUI(animated: true)
        applyBackgroundTransform(for: .collapsed, animated: true)
        onStateChange?(.collapsed)
        
        NSLog("🎯 拖拽切换完成，UI和背景同步更新")
    }
    
    func switchToExpanded() {
        NSLog("🎯 ChatOverlayManager: 切换到展开状态")
        // 展开前取消任何挂起的收缩态延迟任务，避免覆盖展开动画
        pendingCollapsedWork?.cancel()
        pendingCollapsedWork = nil
        currentState = .expanded
        // 🚨 【动画冲突修复】同时触发UI和背景动画，避免时序冲突
        updateUI(animated: true)
        applyBackgroundTransform(for: .expanded, animated: true)
        onStateChange?(.expanded)
        
        // 发送状态变化通知
        postNotification(.chatOverlayStateChanged, userInfo: ["state": "expanded", "height": UIScreen.main.bounds.height - 100])
    }
    
    func toggleState() {
        NSLog("🎯 ChatOverlayManager: 切换状态")
        // 切换前先取消可能存在的收缩延迟任务
        pendingCollapsedWork?.cancel()
        pendingCollapsedWork = nil
        currentState = (currentState == .collapsed) ? .expanded : .collapsed
        // 🚨 【动画冲突修复】同时触发UI和背景动画，避免时序冲突
        updateUI(animated: true)
        applyBackgroundTransform(for: currentState, animated: true)
        onStateChange?(currentState)
    }
    
    func setOnStateChange(_ callback: @escaping (OverlayState) -> Void) {
        self.onStateChange = callback
    }

    fileprivate func postNotification(_ name: Notification.Name, userInfo: [AnyHashable: Any]? = nil) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: name, object: nil, userInfo: userInfo)
        }
    }

    // 会话/上下文管理（原生模式下由 ChatStore 负责，这里仅作占位）
    func loadHistory() -> Int {
        NSLog("🎯 ChatOverlayManager: loadHistory noop，返回当前消息数量 \(messages.count)")
        return self.messages.count
    }
    func clearAll() {
        self.lastMessages = self.messages
        self.messages = []
        DispatchQueue.main.async {
            self.overlayViewController?.updateMessages(self.messages, oldMessages: self.lastMessages, shouldAnimateNewUserMessage: false, animationIndex: nil)
        }
    }
    
    // MARK: - 背景3D效果方法
    
    func setBackgroundView(_ view: UIView) {
        NSLog("🎯 ChatOverlayManager: 设置背景视图用于3D变换")
        self.backgroundView = view
    }
    
    private func applyBackgroundTransform(for state: OverlayState, animated: Bool = true) {
        guard let backgroundView = backgroundView else { 
            NSLog("⚠️ 背景视图未设置，跳过3D变换")
            return 
        }

        if state == lastBackgroundState {
            NSLog("ℹ️ 背景状态未变化(\(state))，跳过变换")
            return
        }

        NSLog("🎯 应用背景3D变换，状态: \(state)")
        // 若插入动画进行中，避免与发送动画叠加，改为无动画
        let shouldAnimate = (overlayViewController?.isAnimatingInsert == true) ? false : animated

        // 🎯 基线校准：展开动画起点强制为 scale=1（避免任何>1的起跳错觉）
        if state == .expanded {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            backgroundView.layer.removeAllAnimations()
            backgroundView.layer.transform = CATransform3DIdentity
            CATransaction.commit()
            NSLog("🧭 基线校准：已无动画重置为 scale=1.0, alpha=1.0")
        }
        if shouldAnimate {
            // 🎯 改为无弹簧的单调 ease-out 动画，避免任何反向/反弹
            UIView.animate(withDuration: 0.26,
                           delay: 0,
                           options: [.allowUserInteraction, .curveEaseOut],
                           animations: {
                switch state {
                case .expanded:
                    // 展开状态：缩放0.92，向上移动15px，绕X轴旋转4度，降低亮度
                    var transform = CATransform3DIdentity
                    transform.m34 = -1.0 / 1000.0  // 设置透视效果
                    transform = CATransform3DScale(transform, 0.92, 0.92, 1.0)
                    transform = CATransform3DTranslate(transform, 0, -15, 0)
                    transform = CATransform3DRotate(transform, 4.0 * .pi / 180.0, 1, 0, 0)  // 绕X轴旋转4度
                    
                    backgroundView.layer.transform = transform
                    
                case .collapsed, .hidden:
                    // 收缩状态或隐藏状态：还原到原始状态
                    backgroundView.layer.transform = CATransform3DIdentity
                }
            }, completion: nil)
        } else {
            // 无动画模式：立即设置状态
            switch state {
            case .expanded:
                var transform = CATransform3DIdentity
                transform.m34 = -1.0 / 1000.0
                transform = CATransform3DScale(transform, 0.92, 0.92, 1.0)
                transform = CATransform3DTranslate(transform, 0, -15, 0)
                transform = CATransform3DRotate(transform, 4.0 * .pi / 180.0, 1, 0, 0)
                
                backgroundView.layer.transform = transform
                
            case .collapsed, .hidden:
                backgroundView.layer.transform = CATransform3DIdentity
            }
        }
        lastBackgroundState = state
    }
    
    private func logOverlayDebugState(reason: String) {
        let windowAlpha = overlayWindow?.alpha ?? -1
        let windowHidden = overlayWindow?.isHidden ?? true
        let containerAlpha = overlayViewController?.containerView.alpha ?? -1
        let containerFrame = overlayViewController?.containerView.frame ?? .zero
        let frameString = NSCoder.string(for: containerFrame)
        let maskAlpha = overlayViewController?.backgroundMaskAlpha ?? -1
        let expandedHidden = overlayViewController?.isExpandedHidden ?? true
#if os(iOS)
        let windowLevels = UIApplication.shared.windows.map { window -> String in
            let level = window.windowLevel.rawValue
            let key = window.isKeyWindow ? "key" : "-"
            let hidden = window.isHidden ? "hidden" : "visible"
            let className = String(describing: type(of: window))
            return String(format: "%@ (level=%.2f, %@, %@)", className, level, key, hidden)
        }.joined(separator: " | ")
        NSLog("🛰 OverlayDebug[%@] windowAlpha=%.3f hidden=%@ containerAlpha=%.3f frame=%@ maskAlpha=%.3f expandedHidden=%@ | windows: %@",
              reason,
              windowAlpha,
              windowHidden.description as NSString,
              containerAlpha,
              frameString,
              maskAlpha,
              expandedHidden.description as NSString,
              windowLevels)
        #else
        NSLog("🛰 OverlayDebug[%@] windowAlpha=%.3f hidden=%@ containerAlpha=%.3f frame=%@ maskAlpha=%.3f expandedHidden=%@",
              reason,
              windowAlpha,
              windowHidden.description as NSString,
              containerAlpha,
              NSStringFromCGRect(containerFrame),
              maskAlpha,
              expandedHidden.description as NSString)
        #endif
    }
    
    private func adjustOverlayWindowLevel(isElevated: Bool, reason: String) {
        logOverlayDebugState(reason: reason)
        guard let window = overlayWindow else { return }
        let targetLevel = isElevated ? elevatedWindowLevel : defaultWindowLevel
        // 层级已保持一致，不再弹跳到 alert 级别，避免窗口被移出/再插入导致闪烁
        if abs(window.windowLevel.rawValue - targetLevel.rawValue) < 0.1 { return }
        window.windowLevel = targetLevel
        NSLog("🛰 OverlayDebug[%@] 维持windowLevel -> %.2f", reason, targetLevel.rawValue)
    }
    
    // MARK: - Private Methods
    
    private func createOverlayWindow() {
        NSLog("🎯 ChatOverlayManager: 创建双状态浮窗视图")
        let scene = windowScene ?? UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        if windowScene == nil && scene == nil {
            NSLog("⚠️ ChatOverlayManager: 未找到可用的UIWindowScene，使用UIScreen.main作为兜底")
        }
        let bounds = scene?.screen.bounds ?? UIScreen.main.bounds
        
        // 创建浮窗窗口 - 使用自定义的PassthroughWindow支持触摸穿透
        let window = PassthroughWindow(frame: bounds)
        if let scene {
            window.windowScene = scene
        }
        // 设置层级：确保在星座之上但低于InputDrawer (statusBar-0.5)
        window.windowLevel = UIWindow.Level.statusBar - 1  // 比InputDrawer低0.5级
        window.backgroundColor = UIColor.clear
        
        // 关键：让窗口不阻挡其他交互，只处理容器内的触摸
        window.isHidden = false
        
        // 创建自定义视图控制器
        overlayViewController = OverlayViewController(manager: self)
        window.rootViewController = overlayViewController
        overlayViewController?.loadViewIfNeeded()
        overlayViewController?.setHorizontalOffset(horizontalOffset, animated: false)

        // 设置窗口对视图控制器的引用
        window.overlayViewController = overlayViewController
        
        // 保存窗口引用
        overlayWindow = window
        
        // 不使用makeKeyAndVisible()，避免抢夺焦点，确保InputDrawer始终在最前
        window.isHidden = false
        
        // 注意：不在这里设置初始状态，由show方法控制
        NSLog("🎯 ChatOverlayManager: 双状态浮窗创建完成")
        NSLog("🎯 ChatOverlayManager: 窗口层级: \(window.windowLevel.rawValue)")
        NSLog("🎯 StatusBar层级: \(UIWindow.Level.statusBar.rawValue)")
        NSLog("🎯 Alert层级: \(UIWindow.Level.alert.rawValue)")
        NSLog("🎯 Normal层级: \(UIWindow.Level.normal.rawValue)")
    }
    
    private func updateUI(animated: Bool) {
        guard let overlayViewController = overlayViewController else { return }
        
        // 若插入动画进行中，避免任何包裹动画的状态切换，直接无动画更新
        if (overlayViewController.isAnimatingInsert) {
            NSLog("🧊 冻结窗口：插入动画期间，updateUI无动画执行")
            overlayViewController.updateForState(self.currentState)
            overlayViewController.view.layoutIfNeeded()
            return
        }
        
        if animated {
            // 🎯 使用轻微弹性过渡，营造柔和“推上/落下”手感
            UIView.animate(withDuration: 0.28,
                           delay: 0,
                           usingSpringWithDamping: 0.9,
                           initialSpringVelocity: 0.3,
                           options: [.allowUserInteraction, .curveEaseInOut, .beginFromCurrentState],
                           animations: {
                overlayViewController.updateForState(self.currentState)
                overlayViewController.view.layoutIfNeeded()
            }, completion: nil)
        } else {
            overlayViewController.updateForState(self.currentState)
        }
    }
    
    @objc private func closeButtonTapped() {
        NSLog("🎯 ChatOverlayManager: 关闭按钮被点击")
        hide()
    }
}

// MARK: - OverlayViewController - 处理双状态UI显示
@MainActor
class OverlayViewController: UIViewController, InputOverlayAvoidingLayout {
    
    // 🚨 【关键修复】动画状态枚举
    enum AnimationState {
        case idle           // 空闲状态
        case userAnimating  // 用户消息动画中
        case aiStreaming    // AI流式输出中
        case completed      // 完成状态
    }
    private weak var manager: ChatOverlayManager?
    internal var containerView: UIView!  // 改为internal让PassthroughWindow可以访问
    private var collapsedView: UIView!
    private var expandedView: UIView!
    private var backgroundMaskView: UIView!
    private var messagesList: UITableView!
    private var dragIndicator: UIView!
    private var expandedViewConstraints: [NSLayoutConstraint] = []
    private var isExpandedLayoutActive = true
    // 去除渐变，改为与输入框一致的风格（纯色+浅色描边）
    var backgroundMaskAlpha: CGFloat {
        backgroundMaskView?.alpha ?? 0
    }
    var isExpandedHidden: Bool {
        expandedView?.isHidden ?? true
    }
    
    // 渲染层可见消息（与数据层解耦）：用于发送动画期间隐藏AI占位
    fileprivate var visibleMessages: [ChatMessage] = []
    // 流式缓冲/回放控制：在发送动画期间缓存AI文本，动画完成后按节奏回放
    private var aiBufferTimer: Timer?
    private var aiTargetFullText: String = ""
    private var aiDisplayedText: String = ""
    private var aiMessageId: String = ""
    // 动画去重与节流（双保险）
    private var hasScheduledInsertAnimation: Bool = false
    private var lastAnimatedUserMessageId: String? = nil
    private var lastAnimationTimestamp: CFTimeInterval = 0

    // 首次收缩对齐控制
    internal var awaitingFirstCollapseAlign: Bool = false
    internal var didFirstCollapseAlign: Bool = false

    // 自动滚动策略：仅在接近底部时才自动滚动
    private let autoScrollThreshold: CGFloat = 100 // px
    private func shouldAutoScrollToBottom() -> Bool {
        guard let table = messagesList else { return true }
        let contentHeight = table.contentSize.height
        if contentHeight <= 0 { return true }
        let visibleHeight = table.bounds.height
        let offsetY = table.contentOffset.y
        let distanceFromBottom = contentHeight - (offsetY + visibleHeight)
        let isUserInteracting = table.isDragging || table.isTracking || table.isDecelerating || isDragging
        let nearBottom = distanceFromBottom < autoScrollThreshold
        NSLog("🧭 AutoScroll 判定: contentH=\(contentHeight), visibleH=\(visibleHeight), offsetY=\(offsetY), dist=\(distanceFromBottom), nearBottom=\(nearBottom), interacting=\(isUserInteracting)")
        return nearBottom && !isUserInteracting
    }

    // MARK: - 冻结窗口内的安全UI操作封装
    private func isFrozen() -> Bool { return isAnimatingInsert }

    private func safeReloadData(reason: String) {
        if isFrozen() {
            NSLog("🧊 [冻结] reloadData 被抑制，原因: \(reason)")
            return
        }
        NSLog("🔄 reloadData 执行，原因: \(reason)")
        messagesList.reloadData()
    }

    private func safeReloadRows(_ rows: [IndexPath], reason: String, animation: UITableView.RowAnimation = .none) {
        if isFrozen() {
            NSLog("🧊 [冻结] reloadRows 被抑制，原因: \(reason), rows=\(rows)")
            return
        }
        NSLog("🔄 reloadRows 执行，原因: \(reason), rows=\(rows)")
        messagesList.reloadRows(at: rows, with: animation)
    }

    private func safeScrollToRow(_ indexPath: IndexPath, at position: UITableView.ScrollPosition, animated: Bool, reason: String) {
        if isFrozen() {
            NSLog("🧊 [冻结] scrollToRow 被抑制，原因: \(reason), indexPath=\(indexPath.row)")
            return
        }
        NSLog("🧭 scrollToRow 执行，原因: \(reason), indexPath=\(indexPath.row), animated=\(animated)")
        messagesList.scrollToRow(at: indexPath, at: position, animated: animated)
    }
    
    // 拖拽相关状态 - 移到OverlayViewController中
    private var isDragging = false
    private var dragStartY: CGFloat = 0
    private var originalTopConstraint: CGFloat = 0  // 记录拖拽开始时的原始位置
    
    // 滚动收起相关状态
    private var hasTriggeredScrollCollapse = false  // 防止重复触发滚动收起
    
    // 🔧 新增：动画相关状态
    private var pendingAnimationIndex: Int?  // 需要播放动画的消息索引
    
    // 🚨 【动画锁定机制】核心属性
    internal var isAnimatingInsert = false  // 动画期间锁定标记（对Manager可见）
    private var pendingAIUpdates: [ChatMessage] = []  // 动画期间暂存的AI更新
    
    // 🚨 【关键修复】流式输出与动画协调机制
    internal var isUserMessageAnimating = false  // 用户消息动画进行中（对Manager可见）
    private var aiStreamingBuffer: [String] = []  // AI流式内容缓冲
    private var lastAIStreamingTime: TimeInterval = 0  // 上次AI流式更新时间
    
    // 🚨 【关键修复】状态机属性
    var animationState: AnimationState = .idle
    var pendingUserMessageId: String? = nil
    
    // 🚨 【新增】专门用于抑制AI滚动动画的状态
    private var isAnimatingUserMessage = false  // 用户消息飞入动画期间的标记
    // 🔧 新增：插入动画前后短窗抑制AI滚动（基于CACurrentMediaTime）
    private var suppressAIAnimatedScrollUntil: CFTimeInterval = 0
    private func shouldSuppressAIAnimatedScroll() -> Bool {
        return isAnimatingUserMessage || CACurrentMediaTime() < suppressAIAnimatedScrollUntil
    }

    // 过滤函数：发送动画期间隐藏尾部的AI占位（空文本）
    private func filteredVisibleMessagesForAnimation(all: [ChatMessage]) -> [ChatMessage] {
        // 不再隐藏尾部AI空占位，保证首次发送也能看到加载动画
        return all
    }
    
    // 约束
    private var containerTopConstraint: NSLayoutConstraint!
    private var containerHeightConstraint: NSLayoutConstraint!
    private var containerLeadingConstraint: NSLayoutConstraint!
    private var containerTrailingConstraint: NSLayoutConstraint!
    private var horizontalOffset: CGFloat = 0
    private var layoutCoordinator: InputDrawerLayoutCoordinator?
    
    init(manager: ChatOverlayManager) {
        self.manager = manager
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        // 去通知化：不再监听全局输入框位置通知
        // 初始化可见消息为当前数据层
        visibleMessages = manager?.messages ?? []
        // 组装协调者：输入框位置 -> 布局能力
        layoutCoordinator = InputDrawerLayoutCoordinator(layout: self, observable: InputDrawerState.shared)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // 在视图出现后设置触摸事件透传
        setupPassthroughView()

        // 🚨 强规则：首次出现时（尤其在键盘已弹起且InputDrawer已在屏幕上）
        // 立即依据最新的输入框位置，调整展开态消息区域的底部内边距，避免被遮挡
        if manager?.currentState == .expanded {
            layoutCoordinator?.syncInitialLayout()
        }
    }
    
    // 去通知化：移除基于 NotificationCenter 的输入框位置监听
    
    // 🔧 新增：在 Expanded 状态下调整内容区域内边距，为键盘腾出空间
    private func adjustExpandedContentInset(for inputDrawerBottomSpace: CGFloat) {
        guard let messagesList = messagesList else { return }
        
        let screenHeight = UIScreen.main.bounds.height
        let safeAreaBottom = view.safeAreaInsets.bottom
        
        // 计算输入框顶部的 Y 坐标
        let inputDrawerTopY = screenHeight - inputDrawerBottomSpace
        
        // 计算浮窗容器底部的 Y 坐标
        let containerBottomY = containerView.frame.maxY
        
        // 如果输入框在浮窗底部之上（重叠），需要调整内边距
        if inputDrawerTopY < containerBottomY {
            // 计算重叠高度，并额外加上间隙确保视觉清晰
            let overlap = containerBottomY - inputDrawerTopY + 16  // 加上 16px 间隙
            
            var currentInsets = messagesList.contentInset
            let oldBottom = currentInsets.bottom
            currentInsets.bottom = overlap
            
            NSLog("🎯 Expanded 键盘调整：inputDrawerBottom=\(inputDrawerBottomSpace)px, overlap=\(overlap)px, 内边距 \(oldBottom)px → \(overlap)px")
            
            UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut, .beginFromCurrentState]) {
                messagesList.contentInset = currentInsets
                messagesList.scrollIndicatorInsets = currentInsets
                
                // 如果接近底部，自动滚动保持可见
                if self.shouldAutoScrollToBottom() {
                    let lastRow = self.visibleMessages.count - 1
                    if lastRow >= 0 {
                        let indexPath = IndexPath(row: lastRow, section: 0)
                        self.safeScrollToRow(indexPath, at: .bottom, animated: true, reason: "键盘弹起自动滚动")
                    }
                }
            }
        } else {
            // 输入框在浮窗底部之下或齐平，恢复默认内边距（120px 为输入框预留空间）
            var currentInsets = messagesList.contentInset
            let defaultBottomInset: CGFloat = 120
            
            if abs(currentInsets.bottom - defaultBottomInset) > 1 {
                let oldBottom = currentInsets.bottom
                currentInsets.bottom = defaultBottomInset
                
                NSLog("🎯 Expanded 键盘恢复：inputDrawerBottom=\(inputDrawerBottomSpace)px, 内边距 \(oldBottom)px → \(defaultBottomInset)px")
                
                UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut, .beginFromCurrentState]) {
                    messagesList.contentInset = currentInsets
                    messagesList.scrollIndicatorInsets = currentInsets
                }
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        NSLog("🎯 ChatOverlay: 移除所有通知观察者")
    }
    
    private func setupPassthroughView() {
        // 使用更简单的方式：PassthroughView作为背景层，不移动现有的视图
        let passthroughView = ChatPassthroughView()
        passthroughView.manager = manager
        passthroughView.containerView = containerView
        passthroughView.backgroundColor = UIColor.clear
        
        // 将PassthroughView插入到view的最底层，不影响现有布局
        view.insertSubview(passthroughView, at: 0)
        passthroughView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            passthroughView.topAnchor.constraint(equalTo: view.topAnchor),
            passthroughView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            passthroughView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            passthroughView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        NSLog("🎯 ChatOverlay: PassthroughView设置完成，保持原有布局")
    }

    // MARK: - InputOverlayAvoidingLayout
    func updateLayoutForInputDrawer(bottomSpaceFromScreen: CGFloat) {
        guard let manager = manager else { return }
        switch manager.currentState {
        case .expanded:
            // 展开态：调整消息区域 bottom inset，保证气泡不被输入框遮挡
            adjustExpandedContentInset(for: bottomSpaceFromScreen)
        case .collapsed:
            // 首次收缩态对齐：让浮窗顶部与输入框间保持稳定间距
            if awaitingFirstCollapseAlign && !didFirstCollapseAlign {
                let screenHeight = UIScreen.main.bounds.height
                let safeAreaTop = view.safeAreaInsets.top
                let gap: CGFloat = 10
                let floatingTop = screenHeight - bottomSpaceFromScreen + gap
                let relativeTop = floatingTop - safeAreaTop
                containerTopConstraint.constant = relativeTop
                UIView.animate(withDuration: 0.26,
                               delay: 0,
                               options: [.allowUserInteraction, .curveEaseInOut, .beginFromCurrentState]) {
                    self.view.layoutIfNeeded()
                } completion: { _ in
                    self.didFirstCollapseAlign = true
                    self.awaitingFirstCollapseAlign = false
                    NSLog("🎯 ChatOverlay: 收缩态首次对齐完成 bottom=\(bottomSpaceFromScreen), top=\(relativeTop)")
                }
            }
        case .hidden:
            break
        }
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.clear
        
        // 创建背景遮罩（仅在展开时显示）
        backgroundMaskView = UIView()
        // 稍微变浅的遮罩，避免整体过暗
        backgroundMaskView.backgroundColor = UIColor.black.withAlphaComponent(0.25)
        backgroundMaskView.alpha = 0
        backgroundMaskView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backgroundMaskView)
        
        // 创建主容器
        containerView = UIView()
        // 与输入框一致风格：深色纯色 + 浅色描边
        containerView.backgroundColor = UIColor(red: 17/255.0, green: 24/255.0, blue: 39/255.0, alpha: 0.96) // bg-gray-900 近似
        containerView.layer.cornerRadius = 12
        // 设置只有顶部两个角为圆角，营造从屏幕底部延伸上来的效果
        containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        containerView.layer.masksToBounds = true
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor(red: 31/255.0, green: 41/255.0, blue: 55/255.0, alpha: 1.0).cgColor // border-gray-800 近似
        containerView.layer.masksToBounds = true
        containerView.translatesAutoresizingMaskIntoConstraints = false
        // 🚨 【残影修复】初始化时隐藏容器，避免创建时显示空白形状
        containerView.alpha = 0
        view.addSubview(containerView)
        
        // 设置约束
        NSLayoutConstraint.activate([
            // 背景遮罩填满整个屏幕
            backgroundMaskView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundMaskView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundMaskView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundMaskView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        // 创建可变约束 - 包括宽度约束
        containerTopConstraint = containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 80)
        containerHeightConstraint = containerView.heightAnchor.constraint(equalToConstant: 65)
        horizontalOffset = manager?.horizontalOffset ?? 0
        containerLeadingConstraint = containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16 + horizontalOffset)
        containerTrailingConstraint = containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        
        containerTopConstraint.isActive = true
        containerHeightConstraint.isActive = true
        containerLeadingConstraint.isActive = true
        containerTrailingConstraint.isActive = true
        
        setupCollapsedView()
        setupExpandedView()
        
        // 只添加拖拽手势到整个容器，移除点击手势避免误触
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        containerView.addGestureRecognizer(panGesture)
    }

    // 移除误放置在类外的布局方法（已移动到OverlayViewController内部）
    
    private func setupCollapsedView() {
        collapsedView = UIView()
        collapsedView.translatesAutoresizingMaskIntoConstraints = false
        // 🚨 【残影修复】初始化时就隐藏collapsedView，避免创建时短暂显示
        collapsedView.alpha = 0
        containerView.addSubview(collapsedView)
        
        // 创建收缩状态的控制栏
        let controlBar = UIView()
        controlBar.translatesAutoresizingMaskIntoConstraints = false
        collapsedView.addSubview(controlBar)
        
        // 完成按钮
        let completeButton = UIButton(type: .system)
        completeButton.setTitle("完成", for: .normal)
        completeButton.setTitleColor(.systemBlue, for: .normal)
        completeButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        completeButton.addTarget(self, action: #selector(completeButtonTapped), for: .touchUpInside)
        completeButton.translatesAutoresizingMaskIntoConstraints = false
        controlBar.addSubview(completeButton)
        
        // 当前对话标题
        let titleLabel = UILabel()
        titleLabel.text = "当前对话"
        titleLabel.textColor = .systemGray
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        controlBar.addSubview(titleLabel)
        
        // 关闭按钮
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("×", for: .normal)
        closeButton.setTitleColor(.systemGray, for: .normal)
        closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        controlBar.addSubview(closeButton)
        
        // 为收缩状态添加点击放大手势
        let collapsedTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleCollapsedTap))
        collapsedView.addGestureRecognizer(collapsedTapGesture)
        
        NSLayoutConstraint.activate([
            // 收缩视图填满容器
            collapsedView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            collapsedView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            collapsedView.topAnchor.constraint(equalTo: containerView.topAnchor),
            collapsedView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            // 控制栏约束
            controlBar.leadingAnchor.constraint(equalTo: collapsedView.leadingAnchor, constant: 16),
            controlBar.trailingAnchor.constraint(equalTo: collapsedView.trailingAnchor, constant: -16),
            controlBar.centerYAnchor.constraint(equalTo: collapsedView.centerYAnchor),
            controlBar.heightAnchor.constraint(equalToConstant: 40),
            
            // 按钮约束
            completeButton.leadingAnchor.constraint(equalTo: controlBar.leadingAnchor),
            completeButton.centerYAnchor.constraint(equalTo: controlBar.centerYAnchor),
            
            titleLabel.centerXAnchor.constraint(equalTo: controlBar.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: controlBar.centerYAnchor),
            
            closeButton.trailingAnchor.constraint(equalTo: controlBar.trailingAnchor),
            closeButton.centerYAnchor.constraint(equalTo: controlBar.centerYAnchor),
        ])
    }
    
    private func setupExpandedView() {
        expandedView = UIView()
        expandedView.translatesAutoresizingMaskIntoConstraints = false
        expandedView.alpha = 0
        containerView.addSubview(expandedView)
        
        // 拖拽指示器
        dragIndicator = UIView()
        dragIndicator.backgroundColor = .systemGray3
        dragIndicator.layer.cornerRadius = 2
        dragIndicator.translatesAutoresizingMaskIntoConstraints = false
        expandedView.addSubview(dragIndicator)
        
        // 头部标题区域
        let headerView = UIView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        expandedView.addSubview(headerView)
        
        let titleLabel = UILabel()
        titleLabel.text = "ChatOverlay 对话"
        titleLabel.textColor = .label
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(titleLabel)
        
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("×", for: .normal)
        closeButton.setTitleColor(.systemGray, for: .normal)
        closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(closeButton)
        
        // 为头部区域添加点击收起手势（只在头部有效）
        let headerTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleHeaderTap))
        headerView.addGestureRecognizer(headerTapGesture)
        
        // 为拖拽指示器也添加点击手势
        let dragIndicatorTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleHeaderTap))
        dragIndicator.addGestureRecognizer(dragIndicatorTapGesture)
        
        // 消息列表
        messagesList = UITableView()
        messagesList.backgroundColor = .clear
        messagesList.separatorStyle = .none
        messagesList.translatesAutoresizingMaskIntoConstraints = false
        messagesList.dataSource = self
        messagesList.delegate = self
        messagesList.register(MessageTableViewCell.self, forCellReuseIdentifier: "MessageCell")
        messagesList.estimatedRowHeight = 60
        messagesList.rowHeight = UITableView.automaticDimension
        expandedView.addSubview(messagesList)
        
        // 底部留空区域
        let bottomSpaceView = UIView()
        bottomSpaceView.translatesAutoresizingMaskIntoConstraints = false
        expandedView.addSubview(bottomSpaceView)
        
        expandedViewConstraints = [
            // 展开视图填满容器
            expandedView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            expandedView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            expandedView.topAnchor.constraint(equalTo: containerView.topAnchor),
            expandedView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            // 拖拽指示器
            dragIndicator.topAnchor.constraint(equalTo: expandedView.topAnchor, constant: 16),
            dragIndicator.centerXAnchor.constraint(equalTo: expandedView.centerXAnchor),
            dragIndicator.widthAnchor.constraint(equalToConstant: 48),
            dragIndicator.heightAnchor.constraint(equalToConstant: 4),
            
            // 头部区域
            headerView.topAnchor.constraint(equalTo: dragIndicator.bottomAnchor, constant: 16),
            headerView.leadingAnchor.constraint(equalTo: expandedView.leadingAnchor, constant: 16),
            headerView.trailingAnchor.constraint(equalTo: expandedView.trailingAnchor, constant: -16),
            headerView.heightAnchor.constraint(equalToConstant: 44),
            
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            
            closeButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            closeButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            
            // 消息列表
            messagesList.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 16),
            messagesList.leadingAnchor.constraint(equalTo: expandedView.leadingAnchor),
            messagesList.trailingAnchor.constraint(equalTo: expandedView.trailingAnchor),
            messagesList.bottomAnchor.constraint(equalTo: bottomSpaceView.topAnchor),
            
            // 底部留空
            bottomSpaceView.leadingAnchor.constraint(equalTo: expandedView.leadingAnchor),
            bottomSpaceView.trailingAnchor.constraint(equalTo: expandedView.trailingAnchor),
            bottomSpaceView.bottomAnchor.constraint(equalTo: expandedView.bottomAnchor),
            bottomSpaceView.heightAnchor.constraint(equalToConstant: 120)  // 增加到120px，为输入框预留足够空间
        ]
        NSLayoutConstraint.activate(expandedViewConstraints)
        isExpandedLayoutActive = true
        setExpandedLayout(active: false)
    }
    
    func updateForState(_ state: OverlayState) {
        let screenHeight = UIScreen.main.bounds.height
        let safeAreaTop = view.safeAreaLayoutGuide.layoutFrame.minY
        let safeAreaBottom = screenHeight - view.safeAreaLayoutGuide.layoutFrame.maxY
        
        NSLog("🎯 更新UI状态: \(state), 屏幕高度: \(screenHeight), 安全区顶部: \(safeAreaTop), 安全区底部: \(safeAreaBottom)")
        
        switch state {
        case .collapsed:
            setExpandedLayout(active: false)
            detachExpandedView()
            containerView.alpha = 1  // 确保收缩状态下容器完全可见，避免短暂透明
            // 收缩状态：浮窗顶部与收缩状态下输入框底部-10px对齐
            let floatingHeight: CGFloat = 65
            let gap: CGFloat = 10  // 浮窗顶部与输入框底部的间隙
            
            // InputDrawer在collapsed状态下的bottomSpace是40px（降低整体高度50px）
            let inputBottomSpaceCollapsed: CGFloat = 40
            
            // 计算输入框在collapsed状态下的底部位置
            // 输入框底部 = 屏幕高度 - 安全区底部 - bottomSpace
            let inputDrawerBottomCollapsed = screenHeight - safeAreaBottom - inputBottomSpaceCollapsed
            
            // 浮窗顶部 = 输入框底部 + 间隙
            // 浮窗在输入框下方10px
            let floatingTop = inputDrawerBottomCollapsed + gap
            
            // 转换为相对于安全区顶部的坐标
            let relativeTopFromSafeArea = floatingTop - safeAreaTop
            
            containerTopConstraint.constant = relativeTopFromSafeArea
            containerHeightConstraint.constant = floatingHeight
            
            // 收起状态：与输入框一样宽度（屏幕宽度减去左右各16px边距）
            containerLeadingConstraint.constant = 16 + horizontalOffset
            containerTrailingConstraint.constant = -16 + horizontalOffset
            
            collapsedView.alpha = 1
            expandedView.alpha = 0
            backgroundMaskView.alpha = 0
            // 收缩状态圆角：恢复原始12px圆角
            containerView.layer.cornerRadius = 12
            containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            
            // 重置滚动收起标记，允许下次触发
            hasTriggeredScrollCollapse = false
            
            NSLog("🎯 收缩状态 - 输入框底部: \(inputDrawerBottomCollapsed)px, 浮窗顶部: \(floatingTop)px, 相对安全区顶部: \(relativeTopFromSafeArea)px, 间距: \(gap)px")
            
        case .expanded:
            attachExpandedViewIfNeeded()
            setExpandedLayout(active: true)
            // 展开状态：覆盖整个屏幕高度，营造从屏幕外延伸的效果
            let expandedTopMargin = max(safeAreaTop, 80)  // 顶部留空
            let expandedBottomExtension: CGFloat = 20  // 底部向外延伸20px，营造延伸效果
            
            containerTopConstraint.constant = expandedTopMargin - safeAreaTop  // 转换为相对安全区坐标
            // 高度计算：从顶部到屏幕底部再延伸20px
            containerHeightConstraint.constant = screenHeight - expandedTopMargin + expandedBottomExtension
            
            // 展开状态：覆盖整个屏幕宽度（无边距）
            containerLeadingConstraint.constant = horizontalOffset
            containerTrailingConstraint.constant = horizontalOffset
            
            NSLog("🔥 [残影修复] 设置UI元素可见性 - containerView: 显示, collapsedView: 隐藏, expandedView: 显示")
            containerView.alpha = 1  // 🚨 【残影修复】展开状态时显示容器
            collapsedView.alpha = 0
            expandedView.alpha = 1
            backgroundMaskView.alpha = 1
            // 展开状态圆角：只有顶部圆角，底部延伸到屏幕外
            containerView.layer.cornerRadius = 12
            containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            
            // 重置滚动收起标记，允许触发
            hasTriggeredScrollCollapse = false
            
            NSLog("🎯 展开状态 - 顶部位置: \(expandedTopMargin)px, 高度: \(screenHeight - expandedTopMargin + expandedBottomExtension)px, 底部延伸: \(expandedBottomExtension)px")

            // 🚨 强规则：刷新布局后，同步一次，避免竞态
            self.view.layoutIfNeeded() // 确保 frame 更新
            layoutCoordinator?.syncInitialLayout()
            
        case .hidden:
            setExpandedLayout(active: false)
            detachExpandedView()
            // 隐藏状态：不显示
            containerView.alpha = 0
            hasTriggeredScrollCollapse = false
            NSLog("🎯 隐藏状态")
        }
        
        NSLog("🎯 最终约束 - Top: \(containerTopConstraint.constant), Height: \(containerHeightConstraint.constant)")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // 🚨 强规则：每次布局更新后，重新检查并应用输入框避让规则
        // 这确保了在旋转、大小改变或任何布局失效后，气泡始终不被遮挡
        if manager?.currentState == .expanded {
            layoutCoordinator?.syncInitialLayout()
        }
    }
    
    private func setExpandedLayout(active: Bool) {
        guard active != isExpandedLayoutActive else { return }
        if active {
            NSLayoutConstraint.activate(expandedViewConstraints)
            expandedView.isHidden = false
            expandedView.alpha = 1
        } else {
            NSLayoutConstraint.deactivate(expandedViewConstraints)
            expandedView.isHidden = true
            expandedView.alpha = 0
        }
        isExpandedLayoutActive = active
    }

    private func attachExpandedViewIfNeeded() {
        guard expandedView.superview == nil else { return }
        containerView.addSubview(expandedView)
    }

    private func detachExpandedView() {
        guard expandedView.superview != nil else { return }
        expandedView.removeFromSuperview()
        expandedView.isHidden = true
    }

    func setHorizontalOffset(_ offset: CGFloat, animated: Bool) {
        let normalized = max(0, offset)
        NSLog("🎯 ChatOverlay VC: 更新水平偏移 -> \(normalized) (animated: \(animated))")
        if abs(horizontalOffset - normalized) < 0.5 {
            horizontalOffset = normalized
            return
        }
        horizontalOffset = normalized
        let state = manager?.currentState ?? .collapsed
        let updates = {
            self.updateForState(state)
            self.view.layoutIfNeeded()
        }
        if animated {
            UIView.animate(
                withDuration: 0.25,
                delay: 0,
                usingSpringWithDamping: 0.85,
                initialSpringVelocity: 0.3,
                options: [.allowUserInteraction, .beginFromCurrentState]
            ) {
                updates()
            }
        } else {
            updates()
        }
    }
    
    @objc private func handleHeaderTap() {
        NSLog("🎯 头部区域被点击，切换状态")
        guard let manager = manager else { return }
        manager.toggleState()
    }
    
    @objc private func handleCollapsedTap() {
        NSLog("🎯 收缩状态被点击，放大浮窗")
        guard let manager = manager else { return }
        manager.switchToExpanded()
    }
    
    @objc private func handleTap() {
        // 这个方法现在不会被调用，因为已经移除了通用点击手势
        // 保留方法以防后续需要
        NSLog("🎯 通用点击处理（已禁用）")
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)
        
        switch gesture.state {
        case .began:
            NSLog("🎯 开始拖拽手势")
            dragStartY = gesture.location(in: view).y
            originalTopConstraint = containerTopConstraint.constant  // 记录拖拽开始的位置
            isDragging = true
            
            // 检查是否在拖拽区域
            let touchPoint = gesture.location(in: containerView)
            let isDragHandle = expandedView.alpha > 0 && touchPoint.y <= 80 // 头部80px为拖拽区域
            NSLog("🎯 触摸点: \(touchPoint), 是否在拖拽区域: \(isDragHandle), 初始Top: \(originalTopConstraint)")
            
        case .changed:
            guard isDragging else { return }
            
            let deltaY = translation.y
            NSLog("🎯 拖拽变化: \(deltaY)px")
            
            // 处理展开状态下的拖拽
            if manager?.currentState == .expanded {
                // 只允许向下拖拽收起
                if deltaY > 0 {
                    // 检查消息列表是否滚动到顶部
                    if let messagesList = expandedView.subviews.first(where: { $0 is UITableView }) as? UITableView {
                        let isAtTop = messagesList.contentOffset.y <= 1
                        
                        if isAtTop || deltaY <= 20 { // 微小拖拽优先级最高
                            NSLog("🎯 允许拖拽收起: deltaY=\(deltaY), isAtTop=\(isAtTop)")
                            // 更流畅的实时预览 - 基于原始位置计算
                            let dampedDelta = deltaY * 0.2 // 减少跟手程度
                            let newTop = originalTopConstraint + dampedDelta
                            
                            // 直接设置约束，无动画，实现流畅跟手
                            containerTopConstraint.constant = newTop
                            view.layoutIfNeeded()
                        }
                    }
                }
            }
            
        case .ended, .cancelled:
            guard isDragging else { return }
            isDragging = false
            
            let deltaY = translation.y
            let velocityY = velocity.y
            
            NSLog("🎯 拖拽结束: deltaY=\(deltaY), velocityY=\(velocityY)")
            
            // 判断是否应该切换状态
            let shouldSwitchToCollapsed = deltaY > 50 || (deltaY > 20 && velocityY > 500)
            
            if manager?.currentState == .expanded && shouldSwitchToCollapsed {
                NSLog("🎯 拖拽距离/速度足够，切换到收缩状态")
                // 使用专门的拖拽切换方法，避免延迟造成的卡顿
                manager?.switchToCollapsedFromDrag()
            } else {
                NSLog("🎯 拖拽不足，回弹到原状态")
                // 回弹动画 - 使用与主动画相同的spring参数
                UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: [.allowUserInteraction, .curveEaseInOut], animations: {
                    if let currentState = self.manager?.currentState {
                        self.updateForState(currentState)
                    }
                    self.view.layoutIfNeeded()
                })
            }
            
        default:
            break
        }
    }
    
    @objc private func completeButtonTapped() {
        manager?.hide()
    }
    
    @objc private func closeButtonTapped() {
        manager?.hide()
    }
    
    // MARK: - 更新消息列表
    
    func updateMessages(_ messages: [ChatMessage], oldMessages: [ChatMessage], shouldAnimateNewUserMessage: Bool, animationIndex: Int? = nil) {
        NSLog("🎯 OverlayViewController: updateMessages被调用，消息数量: \(messages.count)")
        NSLog("🎯 状态快照: animationState=\(animationState), isAnimatingInsert=\(isAnimatingInsert), isUserMessageAnimating=\(isUserMessageAnimating), visibleMessages=\(visibleMessages.count)")
        guard let manager = manager else { 
            NSLog("⚠️ OverlayViewController: manager为nil")
            return 
        }
        
        // 🚨 【动画锁定机制】第一层检查：如果正在播放插入动画，缓存AI文本，动画完成后回放
        if isAnimatingInsert {
            NSLog("🚨 【动画锁定】正在播放用户插入动画：缓存AI文本，动画完成后回放")
            // 同步数据层
            manager.messages = messages
            if let last = messages.last, !last.isUser {
                aiTargetFullText = last.text
                aiMessageId = last.id
                NSLog("🚨 【动画锁定】缓存AI目标文本长度: \(aiTargetFullText.count)")
            }
            return
        }
        
        // 🚨 【关键修复】流式输出与动画协调：如果用户消息动画进行中，缓冲AI流式更新
        if isUserMessageAnimating {
            NSLog("🚨 【流式协调】用户消息动画进行中，缓冲AI流式更新")
            if let last = messages.last, !last.isUser {
                // 将AI流式更新加入缓冲
                aiStreamingBuffer.append(last.text)
                lastAIStreamingTime = CACurrentMediaTime()
                NSLog("🚨 【流式协调】AI流式内容已缓冲，当前缓冲长度: \(aiStreamingBuffer.count)")
            }
            return
        }
        
        NSLog("🎯 OverlayViewController: manager存在，准备更新UI")
        NSLog("🎯 是否需要播放用户消息动画: \(shouldAnimateNewUserMessage)")
        if let index = animationIndex {
            NSLog("🎯 动画索引: \(index)")
        }
        
        // 记录旧消息数量，用于判断更新场景（使用传入的oldMessages而非当前manager.messages）
        let oldMessagesCount = oldMessages.count
        
        // 先更新manager的消息列表，并同步到渲染层（非动画期）
        manager.messages = messages
        self.visibleMessages = messages
        
        DispatchQueue.main.async {
            if shouldAnimateNewUserMessage, let targetIndex = animationIndex {
                // 🎯 场景1：有新用户消息，需要整体重载并播放动画
                NSLog("🎯 【场景1】新用户消息需要动画，执行完整重载和动画")
                // 双保险：若已有调度或处于动画中，直接跳过本次动画调度
                if self.hasScheduledInsertAnimation || self.isAnimatingInsert {
                    NSLog("🚧 已有插入动画在调度/进行，跳过重复调度")
                    return
                }
                // 若同一消息在短时间内已播放过动画，跳过（防止抖动重复）
                if let lastId = self.lastAnimatedUserMessageId,
                   messages.indices.contains(targetIndex),
                   messages[targetIndex].id == lastId,
                   CACurrentMediaTime() - self.lastAnimationTimestamp < 1.0 {
                    NSLog("🚧 同一消息短窗重复触发，跳过动画调度")
                    return
                }

                // 🚨 【动画锁定】加锁
                self.isAnimatingInsert = true
                self.hasScheduledInsertAnimation = true
                self.pendingAnimationIndex = targetIndex
                // 🔧 预先设定短窗抑制，保证插入动画前的准备阶段不被AI滚动打断
                self.suppressAIAnimatedScrollUntil = CACurrentMediaTime() + 0.4
                // 发送动画期间隐藏尾部AI占位
                self.visibleMessages = self.filteredVisibleMessagesForAnimation(all: messages)
                self.messagesList.reloadData()
                // 布局稳定屏障：确保列表和父视图在开始动画前完成布局
                self.messagesList.layoutIfNeeded()
                self.view.layoutIfNeeded()

                self.scrollToBottomAndPlayAnimation(messages: self.visibleMessages) {
                    // 🚨 【动画锁定】动画完成回调 - 解锁并处理
                    NSLog("🚨 【动画锁定】动画完成，解锁并呈现当前文本")
                    self.isAnimatingInsert = false
                    self.hasScheduledInsertAnimation = false
                    // 动画完成：直接呈现当前文本（不启用原生回放，由JS逐字推进）
                    self.visibleMessages = self.manager?.messages ?? []
                    self.safeReloadData(reason: "动画完成呈现当前文本")
                    if let count = self.manager?.messages.count, count > 0 {
                        let indexPath = IndexPath(row: count - 1, section: 0)
                        self.safeScrollToRow(indexPath, at: .bottom, animated: false, reason: "动画完成滚到底")
                    }
                    // 清空期间缓存（由JS继续逐字）
                    self.pendingAIUpdates.removeAll()
                }
                
            } else if messages.count == oldMessagesCount && messages.count > 0 {
                // 🎯 场景2：AI流式更新（消息总数不变，只是内容变了）
                NSLog("🎯 【场景2】AI流式更新，使用精细化cell更新")
                let lastMessageIndex = messages.count - 1
                let indexPath = IndexPath(row: lastMessageIndex, section: 0)
                
                if let lastCell = self.messagesList.cellForRow(at: indexPath) as? MessageTableViewCell {
                    // 直接更新cell的内容，不触发reloadData
                    NSLog("🎯 ✅ 直接更新最后一个AI消息cell")
                    if self.aiBufferTimer != nil {
                        // 正在回放：仅更新目标全文，不直接改UI，交由计时器推进
                        self.aiTargetFullText = messages[lastMessageIndex].text
                        NSLog("🎯 回放中：更新AI目标全文长度为 \(self.aiTargetFullText.count)")
                    } else {
                        lastCell.configure(with: messages[lastMessageIndex])
                        // 使动态高度立即生效，且不做高度动画
                        lastCell.setNeedsLayout()
                        lastCell.layoutIfNeeded()
                        UIView.performWithoutAnimation {
                            self.messagesList.beginUpdates()
                            self.messagesList.endUpdates()
                        }
                    }
                    
                    // 🚨 【关键修复】检查短窗/动画状态，决定是否滚动
                    let shouldAnimateScroll = !self.shouldSuppressAIAnimatedScroll()
                    NSLog("🚨 【动画抑制】AI更新滚动检查: isAnimatingUserMessage = \(self.isAnimatingUserMessage), suppressUntil = \(self.suppressAIAnimatedScrollUntil), now = \(CACurrentMediaTime()), shouldAnimateScroll = \(shouldAnimateScroll)")
                    
                    // 确保滚动到底部显示完整内容（接近底部才滚动；并根据动画状态决定是否使用动画）
                    if self.shouldAutoScrollToBottom() {
                        self.safeScrollToRow(indexPath, at: .bottom, animated: shouldAnimateScroll, reason: "AI流式可见cell")
                    } else {
                        NSLog("🧭 AutoScroll 取消：不在底部或用户正在交互")
                    }
                    
                    if shouldAnimateScroll {
                        NSLog("🎯 ✅ AI滚动动画正常执行")
                    } else {
                        NSLog("🚨 【动画抑制】AI滚动动画被抑制，使用静默滚动")
                    }
                } else {
                    // 如果cell不可见，reloadData是无法避免的后备方案
                    NSLog("🎯 ⚠️ AI消息cell不可见，使用后备reloadData方案")
                    if self.aiBufferTimer != nil {
                        // 回放时避免一次性呈现，改为只更新目标全文
                        self.aiTargetFullText = messages[lastMessageIndex].text
                        NSLog("🎯 回放中（不可见）：更新AI目标全文长度为 \(self.aiTargetFullText.count)")
                    } else {
                        self.visibleMessages = messages
                        self.messagesList.reloadData()
                    }
                    
                    // 同样应用自动滚动与动画抑制逻辑到后备方案
                    let shouldAnimateScroll = !self.shouldSuppressAIAnimatedScroll()
                    if self.shouldAutoScrollToBottom() {
                        self.safeScrollToRow(indexPath, at: .bottom, animated: shouldAnimateScroll, reason: "AI流式后备")
                    } else {
                        NSLog("🧭 AutoScroll 取消（后备）：不在底部或用户正在交互")
                    }
                }
                
            } else {
                // 🎯 场景3：其他情况（例如，从历史记录加载），直接重载
                NSLog("🎯 【场景3】其他更新场景，执行常规重载")
                self.visibleMessages = messages
                self.safeReloadData(reason: "场景3常规重载")
                if messages.count > 0 {
                    let indexPath = IndexPath(row: messages.count - 1, section: 0)
                    if self.shouldAutoScrollToBottom() {
                        self.safeScrollToRow(indexPath, at: .bottom, animated: false, reason: "场景3滚动到底")
                    }
                }
            }
        }
    }
    
    // 🔧 修改：滚动并播放动画的辅助方法 - 添加完成回调支持
    private func scrollToBottomAndPlayAnimation(messages: [ChatMessage], completion: @escaping () -> Void) {
        guard messages.count > 0 else { 
            completion()  // 如果没有消息，直接调用完成回调
            return 
        }
        
        NSLog("🎯 滚动到最新消息并准备动画")
        // 使用可见消息列表，隐藏AI占位时不把它计入滚动目标
        let targetRow = max(0, self.visibleMessages.count - 1)
        let indexPath = IndexPath(row: targetRow, section: 0)
        self.messagesList.scrollToRow(at: indexPath, at: .bottom, animated: false)
        
        NSLog("🎯 准备播放用户消息动画")
        // 立即设置动画初始状态，防止出现直接显示
        DispatchQueue.main.async {
            NSLog("🎯 立即设置动画初始状态")
            self.setAnimationInitialState(messages: messages)
            // 布局稳定屏障：再次确保布局稳定后立刻开始动画
            self.messagesList.layoutIfNeeded()
            self.view.layoutIfNeeded()
            NSLog("🎯 开始播放动画")
            self.playUserMessageAnimation(messages: messages, completion: completion)
        }
    }

    // MARK: - 动画完成后回放AI缓冲
    private func beginAIReplayAfterAnimation() {
        // 停止可能存在的计时器
        aiBufferTimer?.invalidate(); aiBufferTimer = nil
        guard var all = manager?.messages, !all.isEmpty else { return }
        // 如果最后一条是AI，将其显示文本重置为当前已显示值（通常是空或已有部分）
        if let last = all.last, !last.isUser {
            aiTargetFullText = last.text
            aiDisplayedText = "" // 从空开始回放
            aiMessageId = last.id
            // 更新可见消息为完整列表，但将最后AI文本置空，准备回放
            if !visibleMessages.isEmpty {
                visibleMessages = all
                var lastVisible = visibleMessages.removeLast()
                lastVisible = ChatMessage(id: lastVisible.id, text: "", isUser: lastVisible.isUser, timestamp: lastVisible.timestamp)
                visibleMessages.append(lastVisible)
                safeReloadData(reason: "回放开始前呈现空AI行")
                let indexPath = IndexPath(row: visibleMessages.count - 1, section: 0)
                safeScrollToRow(indexPath, at: .bottom, animated: false, reason: "回放开始滚到底")
                // 首次出现淡入：让AI行从0到1的轻淡入
                if let cell = messagesList.cellForRow(at: indexPath) as? MessageTableViewCell {
                    cell.alpha = 0.0
                    cell.transform = CGAffineTransform(translationX: 0, y: 8)
                    UIView.animate(withDuration: 0.12) {
                        cell.alpha = 1.0
                        cell.transform = .identity
                    }
                }
            }
            // 启动回放计时器（每30ms追加一小段）
            aiBufferTimer = Timer.scheduledTimer(timeInterval: 0.03, target: self, selector: #selector(handleAIBufferTick(_:)), userInfo: nil, repeats: true)
            RunLoop.main.add(aiBufferTimer!, forMode: .common)
        } else {
            // 无AI消息，直接呈现完整列表
            visibleMessages = all
            messagesList.reloadData()
        }
    }

    @objc private func handleAIBufferTick(_ timer: Timer) {
        let target = aiTargetFullText
        if aiDisplayedText.count >= target.count {
            timer.invalidate()
            aiBufferTimer = nil
            return
        }
        let nextEnd = min(target.count, aiDisplayedText.count + 6)
        let startIdx = target.index(target.startIndex, offsetBy: aiDisplayedText.count)
        let endIdx = target.index(target.startIndex, offsetBy: nextEnd)
        let chunk = String(target[startIdx..<endIdx])
        aiDisplayedText += chunk
        if !visibleMessages.isEmpty, let last = visibleMessages.last, !last.isUser {
            var updated = visibleMessages.removeLast()
            updated = ChatMessage(id: updated.id, text: aiDisplayedText, isUser: updated.isUser, timestamp: updated.timestamp)
            visibleMessages.append(updated)
            let indexPath = IndexPath(row: visibleMessages.count - 1, section: 0)
            if let cell = messagesList.cellForRow(at: indexPath) as? MessageTableViewCell {
                cell.configure(with: updated)
                cell.setNeedsLayout()
                cell.layoutIfNeeded()
            } else {
                safeReloadRows([indexPath], reason: "回放增量刷新最后一行", animation: .none)
            }
            messagesList.beginUpdates()
            messagesList.endUpdates()
            safeScrollToRow(indexPath, at: .bottom, animated: false, reason: "回放推进滚到底")
        }
    }

    // 🚨 【关键修复】处理缓冲的AI流式更新
    private func processBufferedAIUpdates() {
        guard !aiStreamingBuffer.isEmpty else {
            NSLog("🚨 【流式协调】无缓冲的AI更新需要处理")
            return
        }
        
        NSLog("🚨 【流式协调】开始处理\(aiStreamingBuffer.count)个缓冲的AI更新")
        
        // 获取最新的AI内容
        let latestAIContent = aiStreamingBuffer.last ?? ""
        aiStreamingBuffer.removeAll()
        
        // 更新消息列表中的AI内容
        if !visibleMessages.isEmpty, let lastIndex = visibleMessages.lastIndex(where: { !$0.isUser }) {
            var updatedMessages = visibleMessages
            updatedMessages[lastIndex] = ChatMessage(
                id: updatedMessages[lastIndex].id,
                text: latestAIContent,
                isUser: updatedMessages[lastIndex].isUser,
                timestamp: updatedMessages[lastIndex].timestamp
            )
            visibleMessages = updatedMessages
            
            // 更新UI
            let indexPath = IndexPath(row: lastIndex, section: 0)
            if let cell = messagesList.cellForRow(at: indexPath) as? MessageTableViewCell {
                cell.configure(with: updatedMessages[lastIndex])
                cell.setNeedsLayout()
                cell.layoutIfNeeded()
                messagesList.beginUpdates()
                messagesList.endUpdates()
                messagesList.scrollToRow(at: indexPath, at: .bottom, animated: true)
            } else {
                messagesList.reloadData()
            }
            
            NSLog("🚨 【流式协调】AI流式更新处理完成，内容长度: \(latestAIContent.count)")
            
            // 🚨 【关键修复】状态机转换：AI流式完成 -> 完成状态
            self.animationState = .completed
            NSLog("🚨 【状态机】AI流式更新完成，状态转换: aiStreaming -> completed")
        }
    }
    
    // 🔧 新增：设置动画初始状态
    private func setAnimationInitialState(messages: [ChatMessage]) {
        guard let lastUserMessageIndex = messages.lastIndex(where: { $0.isUser }) else { return }
        
        NSLog("🎯 设置动画初始状态，索引: \(lastUserMessageIndex)")
        NSLog("🎯 当前pendingAnimationIndex: \(pendingAnimationIndex ?? -1)")
        
        let indexPath = IndexPath(row: lastUserMessageIndex, section: 0)
        
        if let cell = self.messagesList.cellForRow(at: indexPath) {
            NSLog("🎯 找到用户消息cell，设置初始动画状态")
            
            // 🔧 关键修复：设置动画起始位置
            let inputToMessageDistance: CGFloat = 180
            let initialTransform = CGAffineTransform(translationX: 0, y: inputToMessageDistance)
            cell.transform = initialTransform
            cell.alpha = 0.0
            
            NSLog("🎯 ✅ 成功设置动画初始状态：Y偏移 \(inputToMessageDistance)px, alpha=0")
        } else {
            NSLog("⚠️ 未找到用户消息cell，无法设置初始状态")
        }
    }
    
    // 🔧 新增：播放用户消息动画
    // 🔧 修改：播放用户消息动画 - 添加完成回调支持
    private func playUserMessageAnimation(messages: [ChatMessage], completion: @escaping () -> Void) {
        guard let lastUserMessageIndex = messages.lastIndex(where: { $0.isUser }) else { 
            completion()  // 如果没有用户消息，直接调用完成回调
            return 
        }
        
        NSLog("🎯 播放用户消息动画，索引: \(lastUserMessageIndex)")
        NSLog("🎯 当前pendingAnimationIndex: \(pendingAnimationIndex ?? -1)")
        
        // 🔧 安全检查：确保这是我们要动画的消息
        guard pendingAnimationIndex == lastUserMessageIndex else {
            NSLog("⚠️ 索引不匹配，跳过动画。期望: \(pendingAnimationIndex ?? -1), 实际: \(lastUserMessageIndex)")
            completion()  // 即使跳过动画，也要调用完成回调
            return
        }
        
        let indexPath = IndexPath(row: lastUserMessageIndex, section: 0)
        
        if let cell = self.messagesList.cellForRow(at: indexPath) {
            NSLog("🎯 找到用户消息cell，开始播放从输入框到消息位置的动画")
            
            // 🚨 【关键修复】在动画真正开始时才标记消息为"已动画"，防止重复触发
            let userMessage = messages[lastUserMessageIndex]
            NSLog("🚨 【重复修复】动画开始，将消息ID加入animatedMessageIDs: \(userMessage.id)")
            
            // 🔧 立即清除动画标记，防止重复执行
            self.pendingAnimationIndex = nil
            NSLog("🎯 清除pendingAnimationIndex，防止重复动画")
            
                            // 🚨 【关键修复】设置用户消息动画状态，抑制AI滚动动画
                self.isAnimatingUserMessage = true
                self.isUserMessageAnimating = true  // 新增：标记用户消息动画进行中
                NSLog("🚨 【动画抑制】开始用户消息动画，设置isAnimatingUserMessage = true")
            
            // 🔧 修正：使用更自然的动画参数，纯垂直移动
            UIView.animate(
                withDuration: 0.5, // 🔧 加快到0.5秒，更流畅
                delay: 0,
                usingSpringWithDamping: 0.85, // 🔧 稍微提高阻尼，减少弹跳
                initialSpringVelocity: 0.6, // 🔧 提高初始速度
                options: [.curveEaseOut, .allowUserInteraction],
                animations: {
            // 已在Manager判定阶段记录animatedMessageIDs，这里不再重复插入
                    
                    // 🔧 关键：只有位移变换，移动到最终位置
                    cell.transform = .identity  // 恢复原始变换（0,0位移）
                    cell.alpha = 1.0           // 渐变显示
                    
                    // 🚨 【统一动画指挥权】在ChatOverlay动画中同步控制InputDrawer位移
                    NSLog("🚨 【统一动画】同步控制InputDrawer位移到collapsed位置")
                    self.manager?.postNotification(Notification.Name("chatOverlayStateChanged"), userInfo: [
                        "state": "collapsed",
                        "visible": true,
                        "source": "unified_animation"
                    ])
                },
                completion: { finished in
                    NSLog("🎯 🚨 用户消息动画完成, finished: \(finished)")
                    
                    // 🚨 【关键修复】状态机转换：用户动画完成 -> AI流式状态
                    self.isAnimatingUserMessage = false
                    self.isUserMessageAnimating = false
                    self.animationState = .aiStreaming  // 转换到AI流式状态
                    NSLog("🚨 【状态机】用户消息动画完成，状态转换: userAnimating -> aiStreaming")
                    // 📣 通知JS：发送插入动画已完成（用于解锁逐字流式泵）
                    self.manager?.postNotification(Notification.Name("chatOverlaySendAnimationCompleted"), userInfo: nil)
                    
                    // 🔧 动画完成后，继续短暂抑制AI滚动动画，避免紧随的首包造成叠加观感
                    self.suppressAIAnimatedScrollUntil = CACurrentMediaTime() + 0.15
                    // 记录已播放动画的消息ID与时间戳
                    if let userIdx = messages.lastIndex(where: { $0.isUser }) {
                        self.lastAnimatedUserMessageId = messages[userIdx].id
                        self.lastAnimationTimestamp = CACurrentMediaTime()
                    }
                    
                    // 🚨 【关键修复】动画完成后开启回放计时器（逐字流逝）
                    self.beginAIReplayAfterAnimation()
                    
                    // 🚨 【关键】调用完成回调，通知动画锁定机制解锁
                    completion()
                }
            )
        } else {
            NSLog("⚠️ 未找到用户消息cell，动画失败")
            self.pendingAnimationIndex = nil
            self.isAnimatingUserMessage = false
            completion()  // 即使动画失败，也要调用完成回调
        }
    }
}

extension ChatOverlayManager: @unchecked Sendable {}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension OverlayViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = visibleMessages.count
        NSLog("🎯 TableView numberOfRows: \(count)")
        return count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        NSLog("🎯 TableView cellForRowAt: \(indexPath.row)")
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath) as! MessageTableViewCell

        if indexPath.row < visibleMessages.count {
            let message = visibleMessages[indexPath.row]
            NSLog("🎯 配置cell: \(message.isUser ? "用户" : "AI") - \(message.text)")
            cell.configure(with: message)

            // 🔧 简化：所有cell都设置为正常状态，动画状态在reloadData后单独设置
            cell.transform = .identity
            cell.alpha = 1.0

        } else {
            NSLog("⚠️ 无法获取消息数据，索引: \(indexPath.row)")
        }

        return cell
    }

    // willDisplay 未做特殊处理
    
    // MARK: - 滚动监听：简化的下滑收起功能
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // 只在展开状态下处理滚动收起逻辑
        guard manager?.currentState == .expanded else { return }
        
        // 如果已经触发过滚动收起，不再重复处理
        guard !hasTriggeredScrollCollapse else { return }
        
        let currentOffset = scrollView.contentOffset.y
        NSLog("🎯 TableView滚动监听: contentOffset.y = \(currentOffset)")
        
        // 简化逻辑：只要向下拉超过110px就收起浮窗
        let minimumDownwardPull: CGFloat = -110.0
        
        if currentOffset <= minimumDownwardPull {
            NSLog("🎯 向下拉超过110px (\(currentOffset)px)，触发收起浮窗")
            
            // 设置标记，防止重复触发
            hasTriggeredScrollCollapse = true
            
            // 立即收起浮窗
            manager?.switchToCollapsedFromDrag()
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        let currentOffset = scrollView.contentOffset.y
        NSLog("🎯 开始拖拽TableView，起始offset: \(currentOffset)")
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        let finalOffset = scrollView.contentOffset.y
        NSLog("🎯 结束拖拽TableView，最终offset: \(finalOffset)，是否继续减速: \(decelerate)")
    }
}

// MARK: - MessageTableViewCell - 消息显示Cell

class MessageTableViewCell: UITableViewCell {
    
    private let messageContainerView = UIView()
    private let messageLabel = UILabel()
    private let timeLabel = UILabel()
    private let activity = StarRayActivityView()
    
    private var leadingConstraint: NSLayoutConstraint?
    private var trailingConstraint: NSLayoutConstraint?
    private var timeLabelConstraint: NSLayoutConstraint?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        // 重置约束
        leadingConstraint?.isActive = false
        trailingConstraint?.isActive = false
        timeLabelConstraint?.isActive = false
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        // 消息容器
        messageContainerView.layer.cornerRadius = 16
        messageContainerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(messageContainerView)
        
        // 消息文本
        messageLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageContainerView.addSubview(messageLabel)
        
        // 时间标签
        timeLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        timeLabel.textColor = .systemGray
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(timeLabel)
        
        // 自定义加载指示器（八芒星旋转）
        activity.translatesAutoresizingMaskIntoConstraints = false
        messageContainerView.addSubview(activity)
        
        // 设置固定的约束
        NSLayoutConstraint.activate([
            messageContainerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            messageContainerView.bottomAnchor.constraint(equalTo: timeLabel.topAnchor, constant: -4),
            
            messageLabel.topAnchor.constraint(equalTo: messageContainerView.topAnchor, constant: 12),
            messageLabel.leadingAnchor.constraint(equalTo: messageContainerView.leadingAnchor, constant: 16),
            messageLabel.trailingAnchor.constraint(equalTo: messageContainerView.trailingAnchor, constant: -16),
            messageLabel.bottomAnchor.constraint(equalTo: messageContainerView.bottomAnchor, constant: -12),
            
            activity.centerYAnchor.constraint(equalTo: messageContainerView.centerYAnchor),
            activity.leadingAnchor.constraint(equalTo: messageLabel.leadingAnchor),
            activity.widthAnchor.constraint(equalToConstant: 20),
            activity.heightAnchor.constraint(equalToConstant: 20),
            
            timeLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    
    func configure(with message: ChatMessage) {
        // 回退：使用普通文本渲染，避免富文本带来的替换/渲染问题
        messageLabel.attributedText = nil
        messageLabel.text = message.text
        // AI空文本 -> 显示loading指示器
        let isLoadingAI = (!message.isUser && message.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        if isLoadingAI {
            // 仅显示Star加载，不显示橄榄球样式的气泡/时间
            activity.isHidden = false
            activity.tintColor = UIColor.systemPurple
            activity.start()
            timeLabel.isHidden = true
            messageContainerView.backgroundColor = .clear
        } else {
            activity.stop()
            activity.isHidden = true
            timeLabel.isHidden = false
        }
        
        // 重置之前的约束
        leadingConstraint?.isActive = false
        trailingConstraint?.isActive = false
        timeLabelConstraint?.isActive = false
        
        // 根据是否是用户消息设置不同的样式
        if message.isUser {
            // 用户消息 - 右侧蓝色气泡
            messageContainerView.backgroundColor = UIColor.systemBlue
            messageLabel.textColor = .white
            
            // 设置约束 - 右对齐
            leadingConstraint = messageContainerView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 80)
            trailingConstraint = messageContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
            timeLabelConstraint = timeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        
        } else {
            // AI消息 - 左侧灰色气泡
            // 加载中已设置为透明；有内容时显示灰色气泡
            if !isLoadingAI {
                messageContainerView.backgroundColor = UIColor.systemGray5
            }
            messageLabel.textColor = .label
            
            // 设置约束 - 左对齐
            leadingConstraint = messageContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
            trailingConstraint = messageContainerView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -80)
            timeLabelConstraint = timeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
        }
        
        // 激活新约束
        leadingConstraint?.isActive = true
        trailingConstraint?.isActive = true
        timeLabelConstraint?.isActive = true
        
        // 格式化时间显示
        let date = Date(timeIntervalSince1970: message.timestamp / 1000)
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        timeLabel.text = formatter.string(from: date)
    }
}


// MARK: - ChatPassthroughView - 处理ChatOverlay触摸事件透传的自定义View
// 自定义旋转八芒星加载视图
class StarRayActivityView: UIView {
    private let rayCount = 8
    private let rayLength: CGFloat = 10
    private let rayWidth: CGFloat = 2
    private var rays: [CAShapeLayer] = []
    private var isAnimating = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        isOpaque = false
        setup()
    }

    private func setup() {
        // 创建8条射线
        for _ in 0..<rayCount {
            let layer = CAShapeLayer()
            layer.lineCap = .round
            layer.lineWidth = rayWidth
            layer.strokeColor = (tintColor ?? UIColor.systemPurple).cgColor
            layer.fillColor = UIColor.clear.cgColor
            self.layer.addSublayer(layer)
            rays.append(layer)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius: CGFloat = max(8, min(bounds.width, bounds.height) * 0.35)
        for (index, ray) in rays.enumerated() {
            let angle = CGFloat(index) * (2 * .pi / CGFloat(rayCount))
            let start = CGPoint(x: center.x + cos(angle) * (radius - rayLength),
                                y: center.y + sin(angle) * (radius - rayLength))
            let end = CGPoint(x: center.x + cos(angle) * (radius),
                              y: center.y + sin(angle) * (radius))
            let path = UIBezierPath()
            path.move(to: start)
            path.addLine(to: end)
            ray.path = path.cgPath
            ray.strokeColor = (tintColor ?? UIColor.systemPurple).cgColor
        }
    }

    func start() {
        guard !isAnimating else { return }
        isAnimating = true
        let anim = CABasicAnimation(keyPath: "transform.rotation.z")
        anim.fromValue = 0
        anim.toValue = 2 * Double.pi
        anim.duration = 1.0
        anim.repeatCount = .infinity
        anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        layer.add(anim, forKey: "star-rotate")
        isHidden = false
    }

    func stop() {
        guard isAnimating else { return }
        isAnimating = false
        layer.removeAnimation(forKey: "star-rotate")
    }
}

class ChatPassthroughView: UIView {
    weak var manager: ChatOverlayManager?
    weak var containerView: UIView?
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        NSLog("🎯 ChatPassthroughView hitTest: \(point), state: \(manager?.currentState ?? .collapsed)")
        
        guard let containerView = containerView else {
            NSLog("🎯 无containerView，透传触摸事件")
            return nil // 透传所有触摸
        }
        
        // 将点转换到containerView的坐标系
        let convertedPoint = convert(point, to: containerView)
        let containerBounds = containerView.bounds
        
        // 如果触摸点在containerView的边界内
        if containerBounds.contains(convertedPoint) {
            NSLog("🎯 触摸在ChatOverlay容器内，处理事件")
            return super.hitTest(point, with: event)
        } else {
            NSLog("🎯 触摸在ChatOverlay容器外，透传给下层")
            // 触摸点在containerView外部，透传给下层
            return nil
        }
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard let containerView = containerView else {
            return false
        }
        
        let convertedPoint = convert(point, to: containerView)
        let isInside = containerView.bounds.contains(convertedPoint)
        NSLog("🎯 ChatPassthroughView point inside: \(point) -> \(isInside)")
        return isInside
    }
}
    // removed misplaced viewDidLayoutSubviews (now correctly inside OverlayViewController)

```

`StarO/ConstellationView.swift`:

```swift
import SwiftUI
import StarOracleCore

struct ConstellationView: View {
  var stars: [Star]
  var connections: [Connection]
  var highlightId: String?
  var onSelect: (Star) -> Void

  var body: some View {
    GeometryReader { proxy in
      ZStack {
        Canvas { context, size in
          context.blendMode = .plusLighter
          let gradient = Gradient(colors: [Color.white.opacity(0.05), Color.blue.opacity(0.1)])
          let background = Path(CGRect(origin: .zero, size: size))
          context.fill(background, with: .linearGradient(gradient, startPoint: .zero, endPoint: CGPoint(x: size.width, y: size.height)))

          for connection in connections {
            guard
              let from = stars.first(where: { $0.id == connection.fromStarId }),
              let to = stars.first(where: { $0.id == connection.toStarId })
            else { continue }
            let fromPoint = position(for: from, in: size)
            let toPoint = position(for: to, in: size)
            var path = Path()
            path.move(to: fromPoint)
            path.addLine(to: toPoint)
            let alpha = 0.2 + connection.strength * 0.4
            context.stroke(path, with: .color(Color.white.opacity(alpha)), lineWidth: 1)
          }

          for star in stars {
            let point = position(for: star, in: size)
            let radius = CGFloat(max(2.0, star.size))
            let glowRect = CGRect(x: point.x - radius * 2.5, y: point.y - radius * 2.5, width: radius * 5, height: radius * 5)
            let coreRect = CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)
            let isHighlight = highlightId == star.id
            let glowOpacity = isHighlight ? 0.45 : 0.25
            let coreOpacity = isHighlight ? 0.9 : 0.7

            context.fill(Path(ellipseIn: glowRect), with: .radialGradient(
              Gradient(colors: [Color.white.opacity(glowOpacity), .clear]),
              center: point,
              startRadius: 0,
              endRadius: glowRect.width / 2
            ))
            context.fill(Path(ellipseIn: coreRect), with: .color(Color.white.opacity(coreOpacity)))
          }
        }

        ForEach(stars) { star in
          let point = position(for: star, in: proxy.size)
          Button {
            onSelect(star)
          } label: {
            Circle()
              .fill(Color.white.opacity(0.001))
              .frame(width: max(44, CGFloat(star.size) * 6), height: max(44, CGFloat(star.size) * 6))
          }
          .position(point)
          .buttonStyle(.plain)
          .contentShape(Rectangle())
        }
      }
      .clipShape(RoundedRectangle(cornerRadius: 24))
      .overlay(
        RoundedRectangle(cornerRadius: 24)
          .stroke(Color.white.opacity(0.1), lineWidth: 1)
      )
    }
  }

  private func position(for star: Star, in size: CGSize) -> CGPoint {
    CGPoint(
      x: size.width * CGFloat(star.x / 100.0),
      y: size.height * CGFloat(star.y / 100.0)
    )
  }
}

```

`StarO/ConversationStore.swift`:

```swift
import Foundation
import Combine
import StarOracleCore

typealias CoreChatMessage = StarOracleCore.ChatMessage

extension Notification.Name {
  static let conversationStoreChanged = Notification.Name("conversationStoreChanged")
}

@MainActor
final class ConversationStore: ObservableObject {
  static let shared = ConversationStore()
  var __updateSignature: String = ""

  struct Session: Identifiable, Codable, Equatable {
    let id: String
    var title: String
    var systemPrompt: String
    var messages: [PersistMessage]
    var createdAt: Date
    var updatedAt: Date
    var hasCustomTitle: Bool

    var displayTitle: String {
      let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
      return trimmed.isEmpty ? "未命名会话" : trimmed
    }

    var formattedUpdatedAt: String {
      let formatter = DateFormatter()
      formatter.dateStyle = .short
      formatter.timeStyle = .short
      return formatter.string(from: updatedAt)
    }
  }

  struct PersistMessage: Codable, Equatable {
    let id: String
    let text: String
    let isUser: Bool
    let timestamp: Date
  }

  private struct PersistModel: Codable {
    var currentSessionId: String
    var sessions: [Session]
  }

  private var sessionsStorage: [Session] = [] {
    didSet {
      logStateChange("sessions -> \(sessionsStorage.count)")
    }
  }
  private var currentSessionIdStorage: String = "" {
    didSet {
      logStateChange("currentSessionId -> \(currentSessionIdStorage)")
    }
  }

  var sessions: [Session] { sessionsStorage }
  var currentSessionId: String { currentSessionIdStorage }

  private let fileURL: URL
  private var saveTask: Task<Void, Never>?
  private var pendingMessageUpdate: DispatchWorkItem?
  private let stateLoggingEnabled = true
  private var isPublishingEnabled = false
  private var isBootstrapped = false
  private var isPublishScheduled = false

  init(fileURL: URL = ConversationStore.defaultURL()) {
    self.fileURL = fileURL
  }

  // MARK: - Session management

  func listSessions() -> [Session] {
    sessions
  }

  func session(id: String) -> Session? {
    sessions.first(where: { $0.id == id })
  }

  func currentSession() -> Session? {
    session(id: currentSessionId)
  }

  @discardableResult
  func createSession(title: String?) -> Session {
    let session = makeSession(title: title)
    mutateState {
      self.sessionsStorage.insert(session, at: 0)
      self.currentSessionIdStorage = session.id
    }
    scheduleSave()
    return session
  }

  @discardableResult
  func switchSession(to id: String) -> Session? {
    guard sessions.contains(where: { $0.id == id }) else { return nil }
    mutateState {
      self.currentSessionIdStorage = id
    }
    scheduleSave()
    return session(id: id)
  }

  func renameSession(id: String, title: String) {
    guard let index = sessions.firstIndex(where: { $0.id == id }) else { return }
    mutateState {
      self.sessionsStorage[index].title = title
      self.sessionsStorage[index].hasCustomTitle = !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      self.sessionsStorage[index].updatedAt = Date()
    }
    scheduleSave()
  }

  func deleteSession(id: String) {
    guard let index = sessions.firstIndex(where: { $0.id == id }) else { return }
    mutateState {
      let deletingCurrent = self.sessionsStorage[index].id == self.currentSessionIdStorage
      self.sessionsStorage.remove(at: index)
      if deletingCurrent {
        if let first = self.sessionsStorage.first {
          self.currentSessionIdStorage = first.id
        } else {
          let newSession = makeSession(title: "默认会话")
          self.sessionsStorage.insert(newSession, at: 0)
          self.currentSessionIdStorage = newSession.id
        }
      }
    }
    scheduleSave()
  }

  // MARK: - Messages

  func messages(forSession id: String? = nil) -> [CoreChatMessage] {
    let sessionId = id ?? currentSessionId
    guard let session = sessions.first(where: { $0.id == sessionId }) else { return [] }
    return session.messages.map { persist in
      CoreChatMessage(
        id: persist.id,
        text: persist.text,
        isUser: persist.isUser,
        timestamp: persist.timestamp,
        isResponse: !persist.isUser
      )
    }
  }

  func updateCurrentSessionMessages(_ messages: [CoreChatMessage]) {
    pendingMessageUpdate?.cancel()
    let snapshot = messages
    let work = DispatchWorkItem { [weak self] in
      guard let self else { return }
      Task { @MainActor [weak self] in
        self?.performUpdateCurrentSessionMessages(snapshot)
      }
    }
    pendingMessageUpdate = work
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.02, execute: work)
  }

  @MainActor
  private func performUpdateCurrentSessionMessages(_ messages: [CoreChatMessage]) {
    NSLog("🚨 updateCurrentSessionMessages called | stack: \(Thread.callStackSymbols.joined(separator: "\n"))")
    guard let index = sessions.firstIndex(where: { $0.id == currentSessionId }) else { return }
    let converted = messages.map { message in
      PersistMessage(
        id: message.id,
        text: message.text,
        isUser: message.isUser,
        timestamp: message.timestamp
      )
    }
    mutateState {
      self.sessionsStorage[index].messages = converted
      self.sessionsStorage[index].updatedAt = Date()
    }
    scheduleSave()
  }

  var messages: [OverlayChatMessage] {
    messages(forSession: currentSessionId).map { $0.toOverlayMessage() }
  }

  func setMessages(_ list: [OverlayChatMessage]) {
    let converted = list.map { $0.toCoreMessage() }
    updateCurrentSessionMessages(converted)
  }

  func append(_ message: OverlayChatMessage) {
    guard let index = sessions.firstIndex(where: { $0.id == currentSessionId }) else { return }
    var updated = sessions[index].messages
    updated.append(message.toPersistMessage())
    mutateState {
      self.sessionsStorage[index].messages = updated
      self.sessionsStorage[index].updatedAt = Date()
    }
    scheduleSave()
  }

  func replaceLastAssistantText(_ text: String) {
    guard let index = sessions.firstIndex(where: { $0.id == currentSessionId }) else { return }
    var updated = sessions[index].messages
    guard let lastIndex = updated.lastIndex(where: { !$0.isUser }) else { return }
    let target = updated[lastIndex]
    updated[lastIndex] = PersistMessage(id: target.id, text: text, isUser: target.isUser, timestamp: Date())
    mutateState {
      self.sessionsStorage[index].messages = updated
      self.sessionsStorage[index].updatedAt = Date()
    }
    scheduleSave()
  }

  func setSystemPrompt(_ prompt: String, sessionId: String? = nil) {
    guard let index = sessions.firstIndex(where: { $0.id == (sessionId ?? currentSessionId) }) else { return }
    mutateState {
      self.sessionsStorage[index].systemPrompt = prompt
      self.sessionsStorage[index].updatedAt = Date()
    }
    scheduleSave()
  }

  // MARK: - Persistence

  func bootstrapIfNeeded() {
    guard !isBootstrapped else { return }
    performInitialLoad()
    isPublishingEnabled = true
    isBootstrapped = true
  }

  private func performInitialLoad() {
    let model = loadPersistedModel()
    var initialSessions = model?.sessions ?? []
    var initialCurrentId = model?.currentSessionId ?? ""
    var needsSave = false

    if initialSessions.isEmpty {
      let defaultSession = makeSession(title: "默认会话")
      initialSessions = [defaultSession]
      initialCurrentId = defaultSession.id
      needsSave = true
    }

    if initialCurrentId.isEmpty {
      initialCurrentId = initialSessions.first?.id ?? ""
      needsSave = true
    }

    let sessionsSnapshot = initialSessions
    let currentSnapshot = initialCurrentId
    mutateState(sendChange: false) { [sessionsSnapshot, currentSnapshot] in
      self.sessionsStorage = sessionsSnapshot
      self.currentSessionIdStorage = currentSnapshot
    }
    if needsSave {
      scheduleSave()
    }
  }

  private func loadPersistedModel() -> PersistModel? {
    guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
    do {
      let data = try Data(contentsOf: fileURL)
      return try JSONDecoder().decode(PersistModel.self, from: data)
    } catch {
      print("⚠️ ConversationStore load failed: \(error.localizedDescription)")
      return nil
    }
  }

  private func scheduleSave() {
    saveTask?.cancel()
    let snapshot = PersistModel(currentSessionId: currentSessionId, sessions: sessions)
    saveTask = Task.detached(priority: .utility) { [fileURL] in
      try? await Task.sleep(nanoseconds: 200_000_000)
      do {
        let data = try JSONEncoder().encode(snapshot)
        try data.write(to: fileURL, options: .atomic)
        await MainActor.run {
          NotificationCenter.default.post(name: .conversationStoreChanged, object: nil)
        }
      } catch {
        print("⚠️ ConversationStore save failed: \(error.localizedDescription)")
      }
    }
  }

  private func logStateChange(_ label: String) {
    guard stateLoggingEnabled else { return }
    NSLog("🚨 ConversationStore.\(label) | stack:\n\(Thread.callStackSymbols.joined(separator: "\n"))")
  }

  private func mutateState(sendChange: Bool = true, _ updates: () -> Void) {
    updates()
    if sendChange && isPublishingEnabled {
      logPendingPublishStack()
      schedulePublish()
    }
  }

  private func schedulePublish() {
    guard !isPublishScheduled else { return }
    isPublishScheduled = true
    DispatchQueue.main.async { [weak self] in
      guard let self else { return }
      self.isPublishScheduled = false
      self.objectWillChange.send()
    }
  }

  private func logPendingPublishStack() {
    guard stateLoggingEnabled else { return }
    NSLog("⚠️ ConversationStore 即将 publish objectWillChange | stack:\n\(Thread.callStackSymbols.joined(separator: "\n"))")
  }

  private func makeSession(title: String?) -> Session {
    let now = Date()
    let cleanTitle = title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    return Session(
      id: UUID().uuidString,
      title: cleanTitle.isEmpty ? "新会话" : cleanTitle,
      systemPrompt: "",
      messages: [],
      createdAt: now,
      updatedAt: now,
      hasCustomTitle: !cleanTitle.isEmpty
    )
  }

  private static func defaultURL() -> URL {
    let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
    return dir.appendingPathComponent("conversation_sessions.json")
  }
}

private extension OverlayChatMessage {
  func toCoreMessage() -> CoreChatMessage {
    CoreChatMessage(
      id: id,
      text: text,
      isUser: isUser,
      timestamp: Date(timeIntervalSince1970: timestamp / 1000),
      isResponse: !isUser
    )
  }

  func toPersistMessage() -> ConversationStore.PersistMessage {
    ConversationStore.PersistMessage(
      id: id,
      text: text,
      isUser: isUser,
      timestamp: Date(timeIntervalSince1970: timestamp / 1000)
    )
  }
}

private extension CoreChatMessage {
  func toOverlayMessage() -> OverlayChatMessage {
    OverlayChatMessage(
      id: id,
      text: text,
      isUser: isUser,
      timestamp: timestamp.timeIntervalSince1970 * 1000
    )
  }
}

```

`StarO/DrawerMenuView.swift`:

```swift
import SwiftUI
import StarOracleCore
import StarOracleFeatures

struct DrawerMenuView: View {
  @EnvironmentObject private var starStore: StarStore
  @EnvironmentObject private var chatStore: ChatStore
  @EnvironmentObject private var conversationStore: ConversationStore

  var onClose: () -> Void
  var onOpenTemplate: () -> Void
  var onOpenCollection: () -> Void
  var onOpenAIConfig: () -> Void
  var onOpenInspiration: () -> Void
  var onSwitchSession: (String) -> Void
  var onCreateSession: (String?) -> Void
  var onRenameSession: (String, String) -> Void
  var onDeleteSession: (String) -> Void

  @State private var query: String = ""
  @State private var sessionToRename: ConversationStore.Session?
  @State private var renameText: String = ""
  @State private var sessionToDelete: ConversationStore.Session?

  private var filteredSessions: [ConversationStore.Session] {
    let sessions = conversationStore.listSessions()
    guard !query.isEmpty else { return sessions }
    return sessions.filter { session in
      session.displayTitle.localizedCaseInsensitiveContains(query) ||
      session.systemPrompt.localizedCaseInsensitiveContains(query)
    }
  }

  var body: some View {
    VStack(spacing: 0) {
      header
      Divider().overlay(Color.white.opacity(0.1))
      ScrollView(showsIndicators: false) {
        VStack(alignment: .leading, spacing: 24) {
          searchBar
          sessionList
          Divider().overlay(Color.white.opacity(0.05))
          menuSection
          Divider().overlay(Color.white.opacity(0.05))
          statsSection
        }
        .padding(24)
      }
      closeButton
    }
    .frame(width: 340)
    .frame(maxHeight: .infinity, alignment: .top)
    .background(
      LinearGradient(
        colors: [
          Color(red: 13/255, green: 18/255, blue: 30/255).opacity(0.96),
          Color(red: 6/255, green: 8/255, blue: 15/255).opacity(0.98)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .overlay(Color.white.opacity(0.05), alignment: .top)
    )
    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    .shadow(color: .black.opacity(0.4), radius: 30, x: 0, y: 20)
    .overlay(
      RoundedRectangle(cornerRadius: 28, style: .continuous)
        .stroke(Color.white.opacity(0.06), lineWidth: 1)
    )
    .sheet(item: $sessionToRename, onDismiss: { renameText = "" }) { session in
      RenameSessionSheet(
        title: session.displayTitle,
        initialValue: renameText.isEmpty ? session.displayTitle : renameText
      ) { newTitle in
        onRenameSession(session.id, newTitle)
      }
    }
    .alert("删除会话？", isPresented: Binding(
      get: { sessionToDelete != nil },
      set: { if !$0 { sessionToDelete = nil } }
    )) {
      Button("取消", role: .cancel) { sessionToDelete = nil }
      if let target = sessionToDelete {
        Button("删除", role: .destructive) {
          onDeleteSession(target.id)
          sessionToDelete = nil
        }
      }
    } message: {
      if let target = sessionToDelete {
        Text("历史记录将被移除：\(target.displayTitle)")
      }
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("星谕")
        .font(.system(size: 22, weight: .semibold, design: .serif))
        .foregroundStyle(.white)
      Text("StarOracle Atlas")
        .font(.footnote)
        .foregroundStyle(.white.opacity(0.6))
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, 24)
    .padding(.top, 48)
    .padding(.bottom, 20)
  }

  private var searchBar: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Image(systemName: "magnifyingglass")
        TextField("搜索对话…", text: $query)
          .textInputAutocapitalization(.none)
      }
      .padding(14)
      .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
      .overlay(
        RoundedRectangle(cornerRadius: 16)
          .stroke(Color.white.opacity(0.12), lineWidth: 1)
      )

      Button {
        onCreateSession(nil)
      } label: {
        Label("新建会话", systemImage: "sparkles")
          .font(.footnote.weight(.medium))
          .frame(maxWidth: .infinity)
          .padding(.vertical, 12)
          .background(
            LinearGradient(
              colors: [Color.purple.opacity(0.8), Color.blue.opacity(0.6)],
              startPoint: .leading,
              endPoint: .trailing
            ),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
          )
      }
      .buttonStyle(.plain)
    }
  }

  private var sessionList: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("历史会话")
        .font(.caption)
        .foregroundStyle(.white.opacity(0.6))
      if filteredSessions.isEmpty {
        Text("暂无记录")
          .font(.footnote)
          .foregroundStyle(.white.opacity(0.4))
          .frame(maxWidth: .infinity, alignment: .leading)
      } else {
        ForEach(filteredSessions) { session in
          sessionRow(session)
        }
      }
    }
  }

  private func sessionRow(_ session: ConversationStore.Session) -> some View {
    let isActive = session.id == conversationStore.currentSessionId
    return Button {
      onSwitchSession(session.id)
      onClose()
    } label: {
      HStack(alignment: .top, spacing: 12) {
        VStack(alignment: .leading, spacing: 4) {
          Text(session.displayTitle)
            .font(.headline)
            .foregroundStyle(.white)
          Text(session.formattedUpdatedAt)
            .font(.caption2)
            .foregroundStyle(.white.opacity(0.6))
        }
        Spacer()
        Menu {
          Button("重命名") {
            renameText = session.displayTitle
            sessionToRename = session
          }
          Button("删除", role: .destructive) {
            sessionToDelete = session
          }
        } label: {
          Image(systemName: "ellipsis")
            .font(.caption)
            .padding(6)
            .background(Color.white.opacity(0.08), in: Circle())
        }
        .menuIndicator(.hidden)
      }
      .padding()
      .background(
        RoundedRectangle(cornerRadius: 18, style: .continuous)
          .fill(isActive ? Color.white.opacity(0.16) : Color.white.opacity(0.04))
          .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
              .stroke(isActive ? Color.white.opacity(0.3) : Color.white.opacity(0.08), lineWidth: 1)
          )
      )
    }
    .buttonStyle(.plain)
  }

  private var menuSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("操作")
        .font(.caption)
        .foregroundStyle(.white.opacity(0.6))
      VStack(spacing: 10) {
        DrawerMenuButton(title: "所有项目", icon: "square.grid.2x2", badge: "\(starStore.constellation.stars.count)") { }
        DrawerMenuButton(title: "选择星座", icon: "sparkles") {
          onOpenTemplate()
          onClose()
        }
        DrawerMenuButton(title: "灵感卡", icon: "wand.and.stars") {
          onOpenInspiration()
          onClose()
        }
        DrawerMenuButton(title: "星卡收藏", icon: "bookmark") {
          onOpenCollection()
          onClose()
        }
        DrawerMenuButton(title: "AI 配置", icon: "slider.horizontal.3") {
          onOpenAIConfig()
          onClose()
        }
      }
    }
  }

  private var statsSection: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("宇宙计数")
        .font(.caption)
        .foregroundStyle(.white.opacity(0.6))
      statRow(title: "星卡", value: "\(starStore.constellation.stars.count)")
      statRow(title: "灵感", value: "\(starStore.inspirationStars.count)")
      statRow(title: "对话", value: "\(chatStore.messages.count)")
    }
  }

  private func statRow(title: String, value: String) -> some View {
    HStack {
      Text(title)
        .font(.footnote)
        .foregroundStyle(.white.opacity(0.7))
      Spacer()
      Text(value)
        .font(.footnote.weight(.medium))
        .foregroundStyle(.white)
    }
    .padding(.vertical, 4)
  }

  private var closeButton: some View {
    Button {
      onClose()
    } label: {
      Label("关闭", systemImage: "xmark")
        .font(.footnote.weight(.medium))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.08))
    }
    .buttonStyle(.plain)
  }
}

private struct DrawerMenuButton: View {
  let title: String
  let icon: String
  var badge: String?
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack {
        Label(title, systemImage: icon)
          .foregroundStyle(.white)
        Spacer()
        if let badge {
          Text(badge)
            .font(.caption2)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.white.opacity(0.12), in: Capsule())
        }
        Image(systemName: "chevron.right")
          .font(.caption2)
          .foregroundStyle(.white.opacity(0.6))
      }
      .padding(.vertical, 10)
      .padding(.horizontal, 12)
      .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))
    }
    .buttonStyle(.plain)
  }
}

private struct RenameSessionSheet: View {
  let title: String
  @State var value: String
  let onConfirm: (String) -> Void
  @Environment(\.dismiss) private var dismiss

  init(title: String, initialValue: String, onConfirm: @escaping (String) -> Void) {
    self.title = title
    self._value = State(initialValue: initialValue)
    self.onConfirm = onConfirm
  }

  var body: some View {
    NavigationStack {
      Form {
        Section("新的会话名称") {
          TextField(title, text: $value)
            .textInputAutocapitalization(.never)
        }
      }
      .navigationTitle("重命名会话")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("取消") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("保存") {
            onConfirm(value.trimmingCharacters(in: .whitespacesAndNewlines))
            dismiss()
          }
          .disabled(value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
      }
    }
    .presentationDetents([.medium])
  }
}

```

`StarO/Galaxy/FireflySparkleView.swift`:

```swift
import SwiftUI
import QuartzCore

@MainActor
final class FireflySimulation: ObservableObject {
    struct Particle: Identifiable {
        let id = UUID()
        var position: CGPoint
        var velocity: CGPoint
        var lifeSpan: TimeInterval
        var age: TimeInterval = 0
        var baseSize: CGFloat
    }

    @Published private(set) var particles: [Particle] = []

    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0
    private let maxParticles = 260
    private var bounds: CGSize = .zero

    func start(in size: CGSize) {
        bounds = size
        stop()
        lastTimestamp = 0
        let link = CADisplayLink(target: self, selector: #selector(step))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
    }

    func updateBounds(_ size: CGSize) {
        bounds = size
    }

    // deinit removed to avoid concurrency violation. 
    // CADisplayLink retains 'self', so deinit is only called after invalidate() breaks the cycle.
    // Cleanup must be done in stop().

    @objc private func step(link: CADisplayLink) {
        guard bounds.width > 0, bounds.height > 0 else { return }
        if lastTimestamp == 0 {
            lastTimestamp = link.timestamp
            return
        }
        let dt = link.timestamp - lastTimestamp
        lastTimestamp = link.timestamp
        evolve(dt: dt)
    }

    func emit(at point: CGPoint) {
        guard bounds.width > 0, bounds.height > 0 else { return }
        var emitted: [Particle] = []
        let count = Int.random(in: 24...36)
        for _ in 0..<count {
            var position = point
            position.x += CGFloat.random(in: -14...14)
            position.y += CGFloat.random(in: -14...14)
            let speed = CGFloat.random(in: 20...60)
            let angle = CGFloat.random(in: 0...(CGFloat.pi * 2))
            let velocity = CGPoint(
                x: CGFloat(cos(Double(angle))) * speed,
                y: CGFloat(sin(Double(angle))) * speed
            )
            let lifeSpan = TimeInterval.random(in: 0.5...0.9)
            let size = CGFloat.random(in: 2.5...4.0)
            emitted.append(
                Particle(
                    position: position,
                    velocity: velocity,
                    lifeSpan: lifeSpan,
                    baseSize: size
                )
            )
        }
        particles.append(contentsOf: emitted)
        if particles.count > maxParticles {
            particles = Array(particles.suffix(maxParticles))
        }
        print("[FireflySimulation] emitted \(emitted.count) particles (total: \(particles.count)) at (\(point.x), \(point.y))")
    }

    private func evolve(dt: TimeInterval) {
        var nextParticles: [Particle] = []
        nextParticles.reserveCapacity(particles.count)

        for var particle in particles {
            var updated = particle
            updated.age += dt
            if updated.age >= updated.lifeSpan {
                continue
            }
            updated.position.x += updated.velocity.x * dt
            updated.position.y += updated.velocity.y * dt
            wrap(&updated.position)
            nextParticles.append(updated)
        }

        // ❌ 禁用自动生成萤火虫粒子（只在点击时生成）
        /*
        let spawnCount = Int.random(in: 0...4)
        for _ in 0..<spawnCount {
            guard nextParticles.count < maxParticles else { break }
            let position = CGPoint(
                x: CGFloat.random(in: 0...bounds.width),
                y: CGFloat.random(in: 0...bounds.height)
            )
            let speed = CGFloat.random(in: 10...26)
            let angle = CGFloat.random(in: 0...(CGFloat.pi * 2))
            let velocity = CGPoint(
                x: CGFloat(cos(Double(angle))) * speed,
                y: CGFloat(sin(Double(angle))) * speed
            )
            let lifeSpan = TimeInterval.random(in: 1.0...1.6)
            let size = CGFloat.random(in: 3.0...4.0)
            let particle = Particle(
                position: position,
                velocity: velocity,
                lifeSpan: lifeSpan,
                baseSize: size
            )
            nextParticles.append(particle)
        }
        */


        particles = nextParticles
    }

    private func wrap(_ point: inout CGPoint) {
        if point.x < 0 { point.x += bounds.width }
        if point.x > bounds.width { point.x -= bounds.width }
        if point.y < 0 { point.y += bounds.height }
        if point.y > bounds.height { point.y -= bounds.height }
    }

}

struct FireflySparkleView: View {
    var size: CGSize
    @ObservedObject var simulation: FireflySimulation

    var body: some View {
        Canvas { context, _ in
            context.blendMode = .plusLighter
            for particle in simulation.particles {
                let progress = particle.age / max(particle.lifeSpan, 0.001)
                let pulse = sin(progress * .pi)
                let opacity = max(0.0, Double(pulse))
                let radius = particle.baseSize * CGFloat(1 + progress * 10)
                let rect = CGRect(
                    x: particle.position.x - radius / 2,
                    y: particle.position.y - radius / 2,
                    width: radius,
                    height: radius
                )
                let color = Color.yellow.opacity(opacity)
                context.fill(
                    Path(ellipseIn: rect),
                    with: .color(color)
                )
            }
        }
        .frame(width: size.width, height: size.height)
        .allowsHitTesting(false)
        .onAppear {
            simulation.start(in: size)
        }
        .onDisappear {
            simulation.stop()
        }
        .onChange(of: size) { newValue in
            simulation.updateBounds(newValue)
        }
    }
}

```

`StarO/Galaxy/GalaxyColor.swift`:

```swift
import SwiftUI

func normalizeGalaxyHex(_ hex: String) -> String {
    var value = hex.trimmingCharacters(in: .whitespacesAndNewlines)
    if !value.hasPrefix("#") {
        value = "#\(value)"
    }
    if value.count == 4 {
        let chars = Array(value)
        value = "#\(chars[1])\(chars[1])\(chars[2])\(chars[2])\(chars[3])\(chars[3])"
    }
    if value.count != 7 {
        return "#FFFFFF"
    }
    return value.uppercased()
}

func galaxyRGBComponents(from hex: String) -> (r: Double, g: Double, b: Double) {
    let normalized = normalizeGalaxyHex(hex)
    let chars = Array(normalized.dropFirst())
    guard chars.count == 6 else {
        return (255, 255, 255)
    }
    let rString = String(chars[0...1])
    let gString = String(chars[2...3])
    let bString = String(chars[4...5])
    let r = Double(Int(rString, radix: 16) ?? 255)
    let g = Double(Int(gString, radix: 16) ?? 255)
    let b = Double(Int(bString, radix: 16) ?? 255)
    return (r, g, b)
}

extension Color {
    init(galaxyHex hex: String) {
        let comps = galaxyRGBComponents(from: hex)
        self = Color(red: comps.r / 255.0, green: comps.g / 255.0, blue: comps.b / 255.0)
    }
}

func desaturatedColor(from hex: String, factor: Double) -> Color {
    let clamped = max(0.0, min(1.0, factor))
    let comps = galaxyRGBComponents(from: hex)
    let gray = (comps.r + comps.g + comps.b) / 3.0
    let newR = comps.r + (gray - comps.r) * clamped
    let newG = comps.g + (gray - comps.g) * clamped
    let newB = comps.b + (gray - comps.b) * clamped
    return Color(red: newR / 255.0, green: newG / 255.0, blue: newB / 255.0)
}

func galaxyBlendHex(_ lhs: String, _ rhs: String, ratio: Double) -> Color {
    let mix = clamp(ratio, min: 0.0, max: 1.0)
    let left = galaxyRGBComponents(from: lhs)
    let right = galaxyRGBComponents(from: rhs)
    let r = left.r + (right.r - left.r) * mix
    let g = left.g + (right.g - left.g) * mix
    let b = left.b + (right.b - left.b) * mix
    return Color(red: r / 255.0, green: g / 255.0, blue: b / 255.0)
}

struct GalaxyHSL {
    var h: Double
    var s: Double
    var l: Double
}

func galaxyHexToHSL(_ hex: String) -> GalaxyHSL {
    let comps = galaxyRGBComponents(from: hex)
    let r = comps.r / 255.0
    let g = comps.g / 255.0
    let b = comps.b / 255.0
    let maxVal = max(r, g, b)
    let minVal = min(r, g, b)
    var h: Double = 0
    var s: Double = 0
    let l = (maxVal + minVal) * 0.5
    if maxVal != minVal {
        let d = maxVal - minVal
        s = l > 0.5 ? d / (2.0 - maxVal - minVal) : d / (maxVal + minVal)
        if maxVal == r {
            h = (g - b) / d + (g < b ? 6.0 : 0.0)
        } else if maxVal == g {
            h = (b - r) / d + 2.0
        } else {
            h = (r - g) / d + 4.0
        }
        h /= 6.0
    }
    return GalaxyHSL(h: h * 360.0, s: s, l: l)
}

private func hueToRGB(_ p: Double, _ q: Double, _ t: Double) -> Double {
    var tVar = t
    if tVar < 0 { tVar += 1 }
    if tVar > 1 { tVar -= 1 }
    if tVar < 1/6 { return p + (q - p) * 6 * tVar }
    if tVar < 1/2 { return q }
    if tVar < 2/3 { return p + (q - p) * (2/3 - tVar) * 6 }
    return p
}

func galaxyHSLToColor(_ hsl: GalaxyHSL) -> Color {
    let h = hsl.h / 360.0
    let s = clamp(hsl.s)
    let l = clamp(hsl.l)
    if s == 0 {
        return Color(red: l, green: l, blue: l)
    }
    let q = l < 0.5 ? l * (1 + s) : l + s - l * s
    let p = 2 * l - q
    let r = hueToRGB(p, q, h + 1/3)
    let g = hueToRGB(p, q, h)
    let b = hueToRGB(p, q, h - 1/3)
    return Color(red: r, green: g, blue: b)
}

func galaxyDesaturatedColor(from hex: String, saturationScale: Double, lightnessAdjust: Double) -> Color {
    var hsl = galaxyHexToHSL(hex)
    hsl.s = clamp(hsl.s * saturationScale)
    hsl.l = clamp(hsl.l + lightnessAdjust)
    return galaxyHSLToColor(hsl)
}

```

`StarO/Galaxy/GalaxyGenerator.swift`:

```swift
import SwiftUI
import CoreGraphics
import Foundation
import simd
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct GalaxyStar: Identifiable {
    let id: String
    let band: Int
    let position: CGPoint      // Overscan canvas coordinates (CSS points)
    let size: CGFloat
    let baseColor: Color
    let litColor: Color
    let baseHex: String
    let displayHex: String
    let litHex: String
    let bandSize: CGSize
}

struct GalaxyBackgroundStar: Identifiable {
    let id: String
    let position: CGPoint
    let size: CGFloat
}

struct GalaxyFieldData {
    let rings: [[GalaxyStar]]
    let background: [GalaxyBackgroundStar]
    let bandSize: CGSize
}

private struct ArmInfo {
    let distance: Double
    let armIndex: Int
    let radius: Double
    let inArm: Bool
    let armWidth: Double
    let theta: Double
}

private struct ArmDensityProfile {
    let density: Double
    let size: Double
    let profile: Double
}

enum GalaxyGenerator {
    static func generateField(
        size: CGSize,
        params: GalaxyParams,
        palette: GalaxyPalette,
        litPalette: GalaxyPalette,
        structureColoring: Bool,
        scale: Double,
        deviceScale: Double,
        reduceMotion: Bool
    ) -> GalaxyFieldData {
        let width = Double(size.width)
        let height = Double(size.height)
        guard width > 0, height > 0 else {
            return GalaxyFieldData(rings: [], background: [], bandSize: .zero)
        }

        let dpr = deviceScale
        let scaleLocal = max(0.01, scale)
        let minOverscan = max(sqrt(2.0) + 0.1, (1.0 / scaleLocal) + 0.2)
        let overscan = max(1.0, minOverscan)

        let overscanWidth = width * overscan
        let overscanHeight = height * overscan
        let overscanCenter = CGPoint(x: overscanWidth / 2.0, y: overscanHeight / 2.0)

        let overscanWidthDev = overscanWidth * dpr
        let overscanHeightDev = overscanHeight * dpr
        let overscanCenterDev = CGPoint(x: overscanWidthDev / 2.0, y: overscanHeightDev / 2.0)

        let maxRadiusCSS = min(width, height) * 0.4
        let maxRadiusDev = min(width * dpr, height * dpr) * 0.4
        let radialDecay = makeRadialDecay(params: params)
        let rings = max(3, min(16, 10))
        let step = 1.0

        let rng = seeded(0xA17C9E3)
        var stars: [GalaxyStar] = []
        stars.reserveCapacity(1800)

        let paletteMap = buildPaletteMap(base: palette, lit: litPalette)
        let litCore = normalizeGalaxyHex(litPalette.core)

        var background: [GalaxyBackgroundStar] = []
        background.reserveCapacity(800)

        for x in stride(from: 0.0, to: overscanWidth, by: step) {
            for y in stride(from: 0.0, to: overscanHeight, by: step) {
                let dx = x - overscanCenter.x
                let dy = y - overscanCenter.y
                let radius = hypot(dx, dy)
                if radius < 3.0 { continue }

                let baseDecay = radialDecay(radius, maxRadiusCSS)
                let armInfo = getArmInfo(
                    x: x * dpr,
                    y: y * dpr,
                    centerX: overscanCenterDev.x,
                    centerY: overscanCenterDev.y,
                    maxRadius: maxRadiusDev,
                    params: params
                )
                let armProfile = calculateArmDensityProfile(armInfo: armInfo, params: params, random: rng)

                var density: Double
                var sizeValue: Double

                if radius < params.coreRadius {
                    let coreProfile = exp(-pow(radius / params.coreRadius, 1.5))
                    density = params.coreDensity * coreProfile * baseDecay
                    sizeValue = (params.coreSizeMin + rng() * (params.coreSizeMax - params.coreSizeMin)) * params.armStarSizeMultiplier
                } else {
                    let n = galaxyNoise2D(x * params.densityNoiseScale, y * params.densityNoiseScale)
                    var modulation = 1.0 - params.densityNoiseStrength * (0.5 * (1.0 - n))
                    if modulation < 0.0 { modulation = 0.0 }
                    density = armProfile.density * baseDecay * modulation
                    sizeValue = armProfile.size
                }

                density *= 0.8 + rng() * 0.4
                if rng() >= density { continue }

                var ox = x
                var oy = y

                if armProfile.profile > 0.001 {
                    let pitchAngle = atan(1.0 / params.spiralB)
                    let jitterAngle = armInfo.theta + pitchAngle + .pi / 2.0
                    let r1 = max(rng(), Double.leastNonzeroMagnitude)
                    let r2 = rng()
                    let gaussian = sqrt(-2.0 * log(r1)) * cos(2.0 * .pi * r2)
                    let chaos = 1.0 + params.jitterChaos * galaxyNoise2D(x * params.jitterChaosScale, y * params.jitterChaosScale)
                    let randomMix = 0.7 + 0.6 * rng()
                    let jitterAmount = params.jitterStrength * chaos * randomMix * armProfile.profile * gaussian
                    ox += (jitterAmount * cos(jitterAngle)) / dpr
                    oy += (jitterAmount * sin(jitterAngle)) / dpr
                }

                ox += (rng() - 0.5) * step
                oy += (rng() - 0.5) * step

                let dxDev = (ox * dpr) - overscanCenterDev.x
                let dyDev = (oy * dpr) - overscanCenterDev.y
                let radiusDev = hypot(dxDev, dyDev)
                let ringIndex = min(rings - 1, max(0, Int((radiusDev / maxRadiusDev) * Double(rings))))

                var baseHex = "#FFFFFF"
                var sizeFinal = sizeValue

                if structureColoring {
                    if radius < params.coreRadius {
                        baseHex = palette.core
                    } else {
                        let aw = armInfo.armWidth / dpr
                        let distance = armInfo.distance / dpr
                        let dustOffset = 0.35 * aw
                        let dustHalf = 0.10 * aw * 0.5
                        let noiseLocal = galaxyNoise2D(x * 0.05, y * 0.05)
                        let inDust = armInfo.inArm && abs(distance - dustOffset) <= dustHalf
                        let ridgeThreshold = 0.6
                        let mainThreshold = 0.45
                        let edgeThreshold = 0.25

                        if inDust || noiseLocal < -0.2 {
                            baseHex = palette.dust
                        } else if armProfile.profile > ridgeThreshold {
                            baseHex = palette.ridge
                        } else if armProfile.profile > mainThreshold {
                            let nearBoost = armProfile.profile > 0.65 ? 0.12 : (armProfile.profile > 0.55 ? 0.03 : -0.12)
                            let baseShare = min(0.8, max(0.0, 0.25 + nearBoost))
                            let r01 = (galaxyNoise2D(x * 0.017 - 19.3, y * 0.017 + 23.1) + 1.0) * 0.5
                            let knot1 = galaxyNoise2D(x * 0.03 + 11.7, y * 0.03 - 7.9)
                            let knot2 = galaxyNoise2D(x * 0.09 - 3.1, y * 0.09 + 5.3)
                            let isHII = (r01 < baseShare) || (knot1 > 0.65 && knot2 > 0.30)
                            if isHII {
                                baseHex = palette.hii
                                sizeFinal *= 1.35
                            } else {
                                baseHex = palette.armBright
                            }
                        } else if armProfile.profile > edgeThreshold {
                            baseHex = palette.armEdge
                        } else {
                            baseHex = palette.outer
                        }
                    }
                }

                let structuralHex = normalizeGalaxyHex(baseHex)
                var displayHex = structuralHex
                if params.colorNoiseScale > 0.0,
                   (abs(params.colorJitterHue) > 0.0001 ||
                    abs(params.colorJitterSat) > 0.0001 ||
                    abs(params.colorJitterLight) > 0.0001) {
                    displayHex = jitteredHexColor(
                        from: structuralHex,
                        x: ox,
                        y: oy,
                        params: params
                    )
                }

                let mappedLit = paletteMap[structuralHex] ?? litCore
                let starID = "s-\(stars.count)"

                let star = GalaxyStar(
                    id: starID,
                    band: ringIndex,
                    position: CGPoint(x: ox, y: oy),
                    size: CGFloat(sizeFinal),
                    baseColor: Color(galaxyHex: displayHex),
                    litColor: Color(galaxyHex: mappedLit),
                    baseHex: structuralHex,
                    displayHex: displayHex,
                    litHex: mappedLit,
                    bandSize: CGSize(width: overscanWidth, height: overscanHeight)
                )
                stars.append(star)
            }
        }

        let backgroundSeed: UInt64 = 0x0BADC0DE
        let backgroundRng = seeded(backgroundSeed)
        let reducedMotionLocal = reduceMotion
        let backgroundCount = Int((width * height) * params.backgroundDensity * (reducedMotionLocal ? 0.6 : 1.0))

        for idx in 0..<backgroundCount {
            let x = backgroundRng() * width
            let y = backgroundRng() * height
            let r1 = backgroundRng()
            let r2 = backgroundRng()
            var sizeValue = r1 < 0.85 ? 0.8 : (r2 < 0.9 ? 1.2 : params.backgroundSizeVariation)
            sizeValue *= params.backgroundStarSizeMultiplier
            background.append(GalaxyBackgroundStar(
                id: "bg-\(idx)",
                position: CGPoint(x: x, y: y),
                size: CGFloat(sizeValue)
            ))
        }

        let grouped = Dictionary(grouping: stars, by: { $0.band })
        let ringsOrdered = (0..<rings).map { grouped[$0] ?? [] }

        return GalaxyFieldData(
            rings: ringsOrdered,
            background: background,
            bandSize: CGSize(width: overscanWidth, height: overscanHeight)
        )
    }
}

// MARK: - Helper Functions

private func jitteredHexColor(from baseHex: String, x: Double, y: Double, params: GalaxyParams) -> String {
    let hsl = galaxyHexToHSL(baseHex)
    let scale = params.colorNoiseScale
    let nh = galaxyNoise2D(x * scale, y * scale)
    let ns = galaxyNoise2D(x * scale + 31.7, y * scale + 11.3)
    let nl = galaxyNoise2D(x * scale + 77.1, y * scale + 59.9)

    var hue = hsl.h + nh * params.colorJitterHue
    while hue < 0 { hue += 360.0 }
    while hue >= 360.0 { hue -= 360.0 }

    let sat = clamp(hsl.s + ns * params.colorJitterSat, min: 0.0, max: 1.0)
    let light = clamp(hsl.l + nl * params.colorJitterLight, min: 0.0, max: 1.0)

    return hslToHexString(h: hue, s: sat, l: light)
}

private func hslToHexString(h: Double, s: Double, l: Double) -> String {
    let hh = h / 360.0
    let q = l < 0.5 ? l * (1 + s) : l + s - l * s
    let p = 2 * l - q

    let r = hueToRGBComponent(p: p, q: q, t: hh + 1.0 / 3.0)
    let g = hueToRGBComponent(p: p, q: q, t: hh)
    let b = hueToRGBComponent(p: p, q: q, t: hh - 1.0 / 3.0)

    let ri = Int(round(r * 255.0))
    let gi = Int(round(g * 255.0))
    let bi = Int(round(b * 255.0))

    return String(format: "#%02X%02X%02X", ri, gi, bi)
}

private func hueToRGBComponent(p: Double, q: Double, t: Double) -> Double {
    var value = t
    if value < 0 { value += 1 }
    if value > 1 { value -= 1 }
    if value < 1 / 6 { return p + (q - p) * 6 * value }
    if value < 1 / 2 { return q }
    if value < 2 / 3 { return p + (q - p) * (2 / 3 - value) * 6 }
    return p
}

private func makeRadialDecay(params: GalaxyParams) -> (Double, Double) -> Double {
    return { radius, maxRadius in
        let base = exp(-radius * params.radialDecay)
        let fade = getFadeFactor(radius: radius, maxRadius: maxRadius, params: params)
        let maintain = params.outerDensityMaintain
        return max(base * fade, maintain * fade)
    }
}

private func getFadeFactor(radius: Double, maxRadius: Double, params: GalaxyParams) -> Double {
    let fadeStart = maxRadius * params.fadeStartRadius
    let fadeEnd = maxRadius * params.fadeEndRadius
    if radius < fadeStart { return 1.0 }
    if radius > fadeEnd { return 0.0 }
    let progress = (radius - fadeStart) / (fadeEnd - fadeStart)
    return 0.5 * (1.0 + cos(progress * .pi))
}

private func getArmWidth(radius: Double, maxRadius: Double, params: GalaxyParams) -> Double {
    let progress = min(radius / (maxRadius * 0.8), 1.0)
    let scale = params.armWidthScale
    let inner = params.armWidthInner * scale
    let outer = params.armWidthOuter * scale
    return inner + (outer - inner) * pow(progress, params.armWidthGrowth)
}

private func spiralTheta(radius: Double, params: GalaxyParams, armOffset: Double) -> Double {
    let value = log(max(radius, params.spiralA) / params.spiralA) / params.spiralB
    return armOffset - value
}

private func getArmPositions(radius: Double, centerX: Double, centerY: Double, params: GalaxyParams) -> [simd_double3] {
    guard radius >= 0 else { return [] }
    var positions: [simd_double3] = []
    for arm in 0..<params.armCount {
        let armOffset = (Double(arm) * 2.0 * .pi) / Double(params.armCount)
        let theta = spiralTheta(radius: radius, params: params, armOffset: armOffset)
        let x = centerX + radius * cos(theta)
        let y = centerY + radius * sin(theta)
        positions.append(simd_double3(x, y, theta))
    }
    return positions
}

private func getArmInfo(
    x: Double,
    y: Double,
    centerX: Double,
    centerY: Double,
    maxRadius: Double,
    params: GalaxyParams
) -> ArmInfo {
    let dx = x - centerX
    let dy = y - centerY
    let radius = hypot(dx, dy)
    if radius < 3.0 {
        return ArmInfo(distance: 0, armIndex: 0, radius: radius, inArm: true, armWidth: 0, theta: 0)
    }
    let positions = getArmPositions(radius: radius, centerX: centerX, centerY: centerY, params: params)
    var minDistance = Double.infinity
    var nearestIndex = 0
    var nearestTheta = 0.0

    for (index, entry) in positions.enumerated() {
        let px = entry.x
        let py = entry.y
        let theta = entry.z
        let distance = hypot(x - px, y - py)
        if distance < minDistance {
            minDistance = distance
            nearestIndex = index
            nearestTheta = theta
        }
    }
    let armWidth = getArmWidth(radius: radius, maxRadius: maxRadius, params: params)
    let inArm = minDistance < armWidth
    return ArmInfo(distance: minDistance, armIndex: nearestIndex, radius: radius, inArm: inArm, armWidth: armWidth, theta: nearestTheta)
}

private func calculateArmDensityProfile(armInfo: ArmInfo, params: GalaxyParams, random: @escaping () -> Double) -> ArmDensityProfile {
    let profile = exp(-0.5 * pow(armInfo.distance / (armInfo.armWidth / params.armTransitionSoftness), 2.0))
    let totalDensity = params.interArmDensity + params.armDensity * profile
    var sizeValue: Double
    if profile > 0.1 {
        sizeValue = params.armBaseSizeMin + (params.armBaseSizeMax - params.armBaseSizeMin) * profile
        if profile > 0.7 && random() < params.armHighlightProb {
            sizeValue = params.armHighlightSize
        }
        sizeValue *= params.armStarSizeMultiplier
    } else {
        sizeValue = params.interArmSizeMin + (params.interArmSizeMax - params.interArmSizeMin) * random()
        sizeValue *= params.interArmStarSizeMultiplier
    }
    return ArmDensityProfile(density: totalDensity, size: sizeValue, profile: profile)
}

private func buildPaletteMap(base: GalaxyPalette, lit: GalaxyPalette) -> [String: String] {
    let entries: [(String, String)] = [
        (base.core, lit.core),
        (base.ridge, lit.ridge),
        (base.armBright, lit.armBright),
        (base.armEdge, lit.armEdge),
        (base.hii, lit.hii),
        (base.dust, lit.dust),
        (base.outer, lit.outer)
    ]
    var map: [String: String] = [:]
    for (baseHex, litHex) in entries {
        let normalizedBase = normalizeGalaxyHex(baseHex)
        let normalizedLit = normalizeGalaxyHex(litHex)
        map[normalizedBase] = normalizedLit
    }
    return map
}

```

`StarO/Galaxy/GalaxyMetalRenderer.swift`:

```swift
import Foundation
import MetalKit

@MainActor
final class GalaxyMetalRenderer: NSObject, MTKViewDelegate {
    struct StarVertex {
        var initialPosition: SIMD2<Float>
        var size: Float
        var type: Float
        var color: SIMD4<Float>
        var highlightStartTime: Float // Replaces progress
        var ringIndex: Float
        var highlightDuration: Float
    }

    struct Uniforms {
        var time: Float
        var viewportSizePixels: SIMD2<Float>
        var scale: Float
    }

    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private var pipelineState: MTLRenderPipelineState?
    private var vertexBuffer: MTLBuffer?
    private var starCount: Int = 0
    private var viewportSizePoints: SIMD2<Float> = SIMD2<Float>(1, 1)
    private var viewportSizePixels: SIMD2<Float> = SIMD2<Float>(1, 1)
    private var viewportScale: Float = 1.0
    private var vertexDescriptor: MTLVertexDescriptor = {
        let descriptor = MTLVertexDescriptor()
        // Attribute 0: initialPosition (float2)
        descriptor.attributes[0].format = .float2
        descriptor.attributes[0].offset = 0
        descriptor.attributes[0].bufferIndex = 0
        
        // Attribute 1: size (float)
        descriptor.attributes[1].format = .float
        descriptor.attributes[1].offset = MemoryLayout<SIMD2<Float>>.stride
        descriptor.attributes[1].bufferIndex = 0
        
        // Attribute 2: type (float)
        descriptor.attributes[2].format = .float
        descriptor.attributes[2].offset = MemoryLayout<SIMD2<Float>>.stride + MemoryLayout<Float>.stride
        descriptor.attributes[2].bufferIndex = 0
        
        // Attribute 3: color (float4)
        descriptor.attributes[3].format = .float4
        descriptor.attributes[3].offset = MemoryLayout<SIMD2<Float>>.stride + MemoryLayout<Float>.stride * 2
        descriptor.attributes[3].bufferIndex = 0
        
        // Attribute 4: highlightStartTime (float)
        descriptor.attributes[4].format = .float
        descriptor.attributes[4].offset = MemoryLayout<SIMD2<Float>>.stride + MemoryLayout<Float>.stride * 2 + MemoryLayout<SIMD4<Float>>.stride
        descriptor.attributes[4].bufferIndex = 0
        
        // Attribute 5: ringIndex (float)
        descriptor.attributes[5].format = .float
        descriptor.attributes[5].offset = MemoryLayout<SIMD2<Float>>.stride + MemoryLayout<Float>.stride * 3 + MemoryLayout<SIMD4<Float>>.stride
        descriptor.attributes[5].bufferIndex = 0
        
        // Attribute 6: highlightDuration (float)
        descriptor.attributes[6].format = .float
        descriptor.attributes[6].offset = MemoryLayout<SIMD2<Float>>.stride + MemoryLayout<Float>.stride * 4 + MemoryLayout<SIMD4<Float>>.stride
        descriptor.attributes[6].bufferIndex = 0
        
        descriptor.layouts[0].stride = MemoryLayout<StarVertex>.stride
        descriptor.layouts[0].stepRate = 1
        descriptor.layouts[0].stepFunction = .perVertex
        return descriptor
    }()
    private var startTime: CFTimeInterval = CACurrentMediaTime()

    init?(metalKitView: MTKView) {
        guard let device = MTLCreateSystemDefaultDevice() else {
            return nil
        }
        self.device = device
        guard let commandQueue = device.makeCommandQueue() else {
            return nil
        }
        self.commandQueue = commandQueue
        super.init()
        configureView(metalKitView)
        buildResources()
    }

    private func configureView(_ view: MTKView) {
        view.device = device
        view.colorPixelFormat = .bgra8Unorm
        view.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        view.depthStencilPixelFormat = .invalid
        view.sampleCount = 1
        let scale = currentDeviceScale(for: view)
        updateViewport(pointSize: view.bounds.size, scale: scale)
    }

    private func buildResources() {
        buildPipeline()
    }

    private func buildPipeline() {
        guard let library = device.makeDefaultLibrary() else {
            assertionFailure("Unable to load default Metal library")
            return
        }
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.label = "Galaxy Pipeline"
        descriptor.vertexFunction = library.makeFunction(name: "galaxy_vertex")
        descriptor.fragmentFunction = library.makeFunction(name: "galaxy_fragment")
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        descriptor.vertexDescriptor = vertexDescriptor
        descriptor.inputPrimitiveTopology = .point
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
        } catch {
            assertionFailure("Failed to create pipeline state: \(error)")
        }
    }

    func updateStarVertices(_ vertices: [StarVertex]) {
        starCount = vertices.count
        guard !vertices.isEmpty else {
            vertexBuffer = nil
            return
        }
        let length = MemoryLayout<StarVertex>.stride * vertices.count
        vertexBuffer = device.makeBuffer(bytes: vertices, length: length, options: [])
        // 移除每帧调试输出，避免影响渲染流畅度
    }

    // MARK: - MTKViewDelegate
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        let scale = currentDeviceScale(for: view)
        let safeScale = max(scale.isFinite ? scale : 1.0, 1.0)
        if size.width > 0, size.height > 0 {
            let pointSize = CGSize(
                width: size.width / safeScale,
                height: size.height / safeScale
            )
            updateViewport(pointSize: pointSize, scale: safeScale)
        }
    }

    func draw(in view: MTKView) {
        guard
            let pipelineState,
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let renderPassDescriptor = view.currentRenderPassDescriptor,
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        else {
            return
        }

        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setViewport(makeViewport())

        var uniforms = Uniforms(
            time: Float(CACurrentMediaTime() - startTime),
            viewportSizePixels: viewportSizePixels,
            scale: viewportScale
        )
        renderEncoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 1)
        renderEncoder.setFragmentBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 0)
        if starCount > 0, let vertexBuffer {
            renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: starCount)
        } else {
            // no-op
        }
        renderEncoder.endEncoding()

        if let drawable = view.currentDrawable {
            commandBuffer.present(drawable)
        }
        commandBuffer.commit()
    }
    
    func updateViewport(pointSize: CGSize, scale: CGFloat) {
        let widthPoints = Float(max(pointSize.width, 1.0))
        let heightPoints = Float(max(pointSize.height, 1.0))
        viewportSizePoints = SIMD2<Float>(widthPoints, heightPoints)
        viewportScale = max(Float(scale.isFinite ? scale : 1.0), 1.0)
        viewportSizePixels = viewportSizePoints * viewportScale
    }

    func updateViewport(pointSize: CGSize) {
        updateViewport(pointSize: pointSize, scale: CGFloat(viewportScale))
    }

    private func makeViewport() -> MTLViewport {
        MTLViewport(
            originX: 0.0,
            originY: 0.0,
            width: Double(max(viewportSizePixels.x, 1.0)),
            height: Double(max(viewportSizePixels.y, 1.0)),
            znear: 0.0,
            zfar: 1.0
        )
    }
}

@MainActor
private func currentDeviceScale(for view: MTKView) -> CGFloat {
#if canImport(UIKit)
    let scale = view.contentScaleFactor
    if scale.isFinite, scale >= 1.0 {
        return scale
    }
    return max(view.window?.screen.scale ?? UIScreen.main.scale, 1.0)
#elseif canImport(AppKit)
    if let layerScale = view.layer?.contentsScale, layerScale.isFinite, layerScale >= 1.0 {
        return layerScale
    }
    if let windowScale = view.window?.backingScaleFactor, windowScale.isFinite, windowScale >= 1.0 {
        return windowScale
    }
    return max(NSScreen.main?.backingScaleFactor ?? 1.0, 1.0)
#else
    return 1.0
#endif
}

```

`StarO/Galaxy/GalaxyMetalView.swift`:

```swift
import MetalKit
import SwiftUI
import simd
import UIKit
import QuartzCore
import StarOracleCore

struct GalaxyMetalContainer: View {
    @ObservedObject var viewModel: GalaxyViewModel
    var size: CGSize
    var onRegionSelected: ((GalaxyRegion) -> Void)?
    var onTap: ((CGPoint, CGSize, GalaxyRegion, TimeInterval) -> Void)?
    var isTapEnabled: Bool = true
    @State private var referenceDate: Date = Date()

    var body: some View {
        GeometryReader { _ in
            ZStack {
                GalaxyMetalView(viewModel: viewModel, canvasSize: size)
                    .frame(width: size.width, height: size.height)
                    .allowsHitTesting(false)
                
                GalaxyTouchOverlay(onTap: { point, ts in
                    print(String(format: "[GalaxyMetalContainer] tap at (%.1f, %.1f) ts=%.3f", point.x, point.y, ts))
                    viewModel.onRegionSelected = onRegionSelected
                    viewModel.onTap = onTap
                    viewModel.handleTap(at: point, in: size, tapTimestamp: ts)
                }, isTapEnabled: isTapEnabled)
                .frame(width: size.width, height: size.height)
            }
        }
        .task(id: size) {
            guard size.width > 0, size.height > 0 else { return }
            await MainActor.run {
                _ = viewModel.prepareIfNeeded(for: size)
                viewModel.onRegionSelected = onRegionSelected
                viewModel.onTap = onTap
                // Initial update only
                viewModel.update(elapsed: 0)
            }
        }
    }
    // ❌ drawPulses方法已完全移除
}

struct GalaxyMetalView: UIViewRepresentable {
    @ObservedObject var viewModel: GalaxyViewModel
    var canvasSize: CGSize
    
    @MainActor
    final class Coordinator: NSObject {
        weak var viewModel: GalaxyViewModel?
        var renderer: GalaxyMetalRenderer?
        var displayLink: CADisplayLink?
        var canvasSize: CGSize = .zero
        var startTime: CFTimeInterval = 0
        var currentElapsed: Double = 0
        var deviceScale: CGFloat = deviceScaleValue()
        
        // deinit removed to avoid concurrency violation.
        // CADisplayLink retains 'self', so deinit is only called after invalidate() breaks the cycle.
        
        @objc func tick(displayLink: CADisplayLink) { // Changed parameter name
            guard let viewModel, let renderer else { return } // Kept viewModel guard
            guard canvasSize.width > 0, canvasSize.height > 0 else { return } // Kept canvas size guard
            
            let currentTime = displayLink.timestamp
            if startTime == 0 { startTime = currentTime } // Changed startTime initialization
            currentElapsed = currentTime - startTime // Changed currentElapsed calculation
            
            // Update ViewModel time (for rotation cache and cleanup)
            // This might trigger SwiftUI updates if @Published properties change (e.g. pulses removed)
            viewModel.updateElapsedTimeOnly(elapsed: currentElapsed)
            
            // ❌ STOP per-frame vertex upload.
            // Vertices are now only rebuilt when viewModel structure changes (via updateUIView -> forceUpdate).
            // renderer.updateStarVertices(...) 
            
            // Note: Rendering is driven by MTKViewDelegate.draw(in:), which runs on the GPU cadence.
        }
        
        func ensureDisplayLink() {
            guard displayLink == nil else { return }
            let link = CADisplayLink(target: self, selector: #selector(tick(displayLink:))) // Updated selector
            link.add(to: .main, forMode: .common)
            displayLink = link
            startTime = CACurrentMediaTime()
            viewModel?.timeOrigin = startTime
        }
        
        func forceUpdate() {
            guard let viewModel, let renderer else { return }
            guard canvasSize.width > 0, canvasSize.height > 0 else { return }
            renderer.updateViewport(pointSize: canvasSize, scale: deviceScale)
            let vertices = GalaxyMetalView.buildVertices(
                viewModel: viewModel,
                size: canvasSize,
                elapsed: currentElapsed,
                deviceScale: deviceScale
            )
            if !vertices.isEmpty {
                renderer.updateStarVertices(vertices)
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    @MainActor
    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView(frame: .zero)
        mtkView.isUserInteractionEnabled = false
        mtkView.enableSetNeedsDisplay = false
        mtkView.isPaused = false
        mtkView.preferredFramesPerSecond = 60
        let scale = safeDeviceScale(for: mtkView)
        context.coordinator.deviceScale = scale
        updateDrawableSize(for: mtkView, canvasSize: canvasSize, scale: scale)
        
        if let renderer = GalaxyMetalRenderer(metalKitView: mtkView) {
            context.coordinator.renderer = renderer
            mtkView.delegate = renderer
            renderer.updateViewport(pointSize: canvasSize, scale: scale)
        } else {
            assertionFailure("Unable to create GalaxyMetalRenderer")
        }
        context.coordinator.viewModel = viewModel
        context.coordinator.canvasSize = canvasSize
        context.coordinator.ensureDisplayLink()
        context.coordinator.forceUpdate()
        #if DEBUG
        print("[Metal] makeUIView canvasSize:\(canvasSize) bounds:\(mtkView.bounds.size)")
        #endif
        return mtkView
    }

    @MainActor
    func updateUIView(_ uiView: MTKView, context: Context) {
        // Later we can propagate viewModel changes to renderer.
        if context.coordinator.renderer == nil {
            context.coordinator.renderer = GalaxyMetalRenderer(metalKitView: uiView)
            uiView.delegate = context.coordinator.renderer
        }
        context.coordinator.viewModel = viewModel
        context.coordinator.canvasSize = canvasSize
        let scale = safeDeviceScale(for: uiView)
        context.coordinator.deviceScale = scale
        updateDrawableSize(for: uiView, canvasSize: canvasSize, scale: scale)
        context.coordinator.renderer?.updateViewport(pointSize: canvasSize, scale: scale)
        #if DEBUG
        print("[Metal] updateUIView canvasSize:\(canvasSize) bounds:\(uiView.bounds.size) drawable:\(uiView.drawableSize)")
        #endif
        context.coordinator.forceUpdate()
    }
    
    static func dismantleUIView(_ uiView: MTKView, coordinator: Coordinator) {
        coordinator.displayLink?.invalidate()
    }
    
    private static func buildVertices(viewModel: GalaxyViewModel, size: CGSize, elapsed: Double, deviceScale: CGFloat) -> [GalaxyMetalRenderer.StarVertex] {
        guard size.width > 0, size.height > 0 else { return [] }
        var vertices: [GalaxyMetalRenderer.StarVertex] = []
        vertices.reserveCapacity(viewModel.backgroundStars.count + viewModel.rings.reduce(0) { $0 + $1.count } + viewModel.pulses.count)

        // 注意：deviceScale 现在传递给 Shader 的 Uniforms 使用，这里不再用于预乘位置
        // 但 size 仍然需要用于计算初始偏移（居中）
        
        let offsetX = (viewModel.bandSize.width - size.width) * 0.5
        let offsetY = (viewModel.bandSize.height - size.height) * 0.5

        let backgroundColor = hexToColor("#D0D4DB", alpha: 0.55)
        for star in viewModel.backgroundStars {
            // 背景星不旋转，ringIndex = -1
            // 位置相对于中心点的偏移
            // 原始逻辑：star.position 是在 bandSize 坐标系下的绝对位置
            // 我们需要将其转换为相对于屏幕中心的偏移，以便 Shader 应用缩放
            
            let bandCenter = CGPoint(x: viewModel.bandSize.width / 2.0, y: viewModel.bandSize.height / 2.0)
            let dx = Float(star.position.x - bandCenter.x)
            let dy = Float(star.position.y - bandCenter.y)
            
            let s = Float(viewModel.params.galaxyScale)
            let position = SIMD2<Float>(dx, dy) * s
            let sizeValue = max(0.6, Float(star.size))
            // Type 0: Background
            vertices.append(.init(initialPosition: position, size: sizeValue, type: 0.0, color: backgroundColor, highlightStartTime: 0, ringIndex: -1.0, highlightDuration: 0))
        }

        // let now = CACurrentMediaTime() // 不需要了，时间由 GPU 统一管理
        let highlightDuration: Float = 0.60

        var normalVertices: [GalaxyMetalRenderer.StarVertex] = []
        var highlightedBaseVertices: [GalaxyMetalRenderer.StarVertex] = []
        var litVertices: [GalaxyMetalRenderer.StarVertex] = []
        // 预分配数组空间
        litVertices.reserveCapacity(50)

        for (ringIndex, ring) in viewModel.rings.enumerated() {
            for star in ring {
                // 核心修改：不再调用 screenPosition 计算旋转后的位置
                // 而是直接计算相对于 bandCenter 的初始偏移
                let bandCenter = CGPoint(x: star.bandSize.width / 2.0, y: star.bandSize.height / 2.0)
                let dx = Float(star.position.x - bandCenter.x)
                let dy = Float(star.position.y - bandCenter.y)
                let s = Float(viewModel.params.galaxyScale)
                let initialPos = SIMD2<Float>(dx, dy) * s
                
                let baseSize = max(0.8, Float(star.size))
                // 基础颜色：如果高亮，则使用 litHex（常亮高亮色），否则使用 displayHex（暗色）
                let isHighlighted = viewModel.isHighlighted(star)
                // 高亮基础层颜色：对齐提交 cf1de85...，采用 litHex 与 #5AE7FF 的混合色
                let layerAlpha = Float(max(0.0, min(1.0, viewModel.alpha(for: star))))
                let baseAlpha = isHighlighted ? max(layerAlpha, 0.95) : layerAlpha
                let baseColor: SIMD4<Float>
                if isHighlighted {
                    // 基础高亮色保持提交风格：litHex 与 #5AE7FF 的混合色，不参与纯白/绿色随机
                    baseColor = GalaxyMetalView.blendHex(star.litHex, with: "#5AE7FF", ratio: 0.45, alpha: baseAlpha)
                } else {
                    baseColor = hexToColor(star.displayHex, alpha: baseAlpha)
                }
                
                let rIndex = Float(ringIndex)
                // 基础层：区分普通与高亮，确保高亮的基础层始终绘制在最上层（避免被后续普通星覆盖）
                // Type 0: Normal/Base
                let baseVertex = GalaxyMetalRenderer.StarVertex(initialPosition: initialPos, size: baseSize, type: 0.0, color: baseColor, highlightStartTime: 0, ringIndex: rIndex, highlightDuration: 0)
                if isHighlighted {
                    highlightedBaseVertices.append(baseVertex)
                } else {
                    normalVertices.append(baseVertex)
                }
                
                // 2. Lit Layer (高亮时光晕层) - 存入单独数组，稍后追加
                if let highlight = viewModel.highlights[star.id] {
                    // 仅在动画时窗内追加 Lit 顶点，避免颜色残留
                    let now = CACurrentMediaTime()
                    let hElapsed = now - highlight.activatedAt
                    if hElapsed >= 0 && hElapsed < Double(highlightDuration) {
                    // Type 1: Lit Star (GPU Animation)
                    // 直接使用目标高亮色（去除“偏白”混合），避免初始帧出现纯白后再“染色”的体验问题
                    let litAlpha: Float = 1.0 // Shader 将按强度调制 alpha
                    let litColor = GalaxyMetalView.blendHex(star.litHex, with: "#5AE7FF", ratio: 0.45, alpha: litAlpha)
                        let relativeStart = Float(highlight.activatedAt - now + elapsed)
                        litVertices.append(.init(initialPosition: initialPos, size: baseSize, type: 1.0, color: litColor, highlightStartTime: relativeStart, ringIndex: rIndex, highlightDuration: highlightDuration))
                    }
                }
            }
        }
        // 装配最终顶点顺序：背景 -> 普通基础层 -> 高亮基础层 -> 高亮叠加层
        vertices.append(contentsOf: normalVertices)
        vertices.append(contentsOf: highlightedBaseVertices)
        vertices.append(contentsOf: litVertices)
        
        // 已移除脉冲渲染（Type 2），只保留星点高亮层

        // 移除每帧调试输出，避免影响渲染流畅度

        return vertices
    }

    private static func hexToColor(_ hex: String, alpha: Float) -> SIMD4<Float> {
        var value = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if !value.hasPrefix("#") {
            value = "#\(value)"
        }
        if value.count == 4 {
            let chars = Array(value)
            value = "#\(chars[1])\(chars[1])\(chars[2])\(chars[2])\(chars[3])\(chars[3])"
        }
        guard value.count == 7 else {
            return SIMD4<Float>(repeating: alpha)
        }
        let hexString = String(value.dropFirst())
        var intValue: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&intValue)
        let r = Float((intValue & 0xFF0000) >> 16) / 255.0
        let g = Float((intValue & 0x00FF00) >> 8) / 255.0
        let b = Float(intValue & 0x0000FF) / 255.0
        return SIMD4<Float>(r, g, b, alpha)
    }
    
    private static func blendHex(_ base: String, with tint: String, ratio: Float, alpha: Float) -> SIMD4<Float> {
        // ratio: 0..1, mix base->tint
        let a = hexToColor(base, alpha: 1.0)
        let b = hexToColor(tint, alpha: 1.0)
        let t = max(0.0, min(1.0, ratio))
        let r = a.x + (b.x - a.x) * t
        let g = a.y + (b.y - a.y) * t
        let bch = a.z + (b.z - a.z) * t
        return SIMD4<Float>(r, g, bch, alpha)
    }

    private static func mixColor(_ a: SIMD4<Float>, _ b: SIMD4<Float>, t: Float) -> SIMD4<Float> {
        let tt = max(0.0, min(1.0, t))
        let r = a.x + (b.x - a.x) * tt
        let g = a.y + (b.y - a.y) * tt
        let bl = a.z + (b.z - a.z) * tt
        let al = a.w + (b.w - a.w) * tt
        return SIMD4<Float>(r, g, bl, al)
    }
    
    private static func colorToSIMD(_ color: Color, alpha: Float) -> SIMD4<Float> {
#if canImport(UIKit)
        let uiColor = UIColor(color)
        var r: CGFloat = 1, g: CGFloat = 1, b: CGFloat = 1, a: CGFloat = CGFloat(alpha)
        if uiColor.getRed(&r, green: &g, blue: &b, alpha: &a) {
            return SIMD4<Float>(Float(r), Float(g), Float(b), Float(alpha))
        }
#endif
        return SIMD4<Float>(repeating: alpha)
    }
}

@MainActor
private func updateDrawableSize(for view: MTKView, canvasSize: CGSize, scale: CGFloat) {
    let safeScale = max(scale.isFinite ? scale : deviceScaleValue(), 1.0)
    let drawableSize = CGSize(
        width: max(canvasSize.width, 0) * safeScale,
        height: max(canvasSize.height, 0) * safeScale
    )
    if view.drawableSize != drawableSize {
        view.drawableSize = drawableSize
    }
}

@MainActor
private func deviceScaleValue() -> CGFloat {
#if canImport(UIKit)
    return UIScreen.main.scale
#elseif canImport(AppKit)
    return NSScreen.main?.backingScaleFactor ?? 1.0
#else
    return 1.0
#endif
}

@MainActor
private func safeDeviceScale(for view: MTKView) -> CGFloat {
#if canImport(UIKit)
    let scale = view.contentScaleFactor
    if scale.isFinite, scale >= 1.0 {
        return scale
    }
    return max(UIScreen.main.scale, 1.0)
#elseif canImport(AppKit)
    if let layerScale = view.layer?.contentsScale, layerScale.isFinite, layerScale >= 1.0 {
        return layerScale
    }
    if let screenScale = NSScreen.main?.backingScaleFactor, screenScale.isFinite, screenScale >= 1.0 {
        return screenScale
    }
    return 1.0
#else
    return 1.0
#endif
}

```

`StarO/Galaxy/GalaxyParams.swift`:

```swift
import SwiftUI

import StarOracleCore

struct GalaxyParams: Equatable {
    var coreDensity: Double
    var coreRadius: Double
    var coreSizeMin: Double
    var coreSizeMax: Double
    var armCount: Int
    var armDensity: Double
    var armBaseSizeMin: Double
    var armBaseSizeMax: Double
    var armHighlightSize: Double
    var armHighlightProb: Double
    var spiralA: Double
    var spiralB: Double
    var armWidthInner: Double
    var armWidthOuter: Double
    var armWidthGrowth: Double
    var armWidthScale: Double
    var armTransitionSoftness: Double
    var fadeStartRadius: Double
    var fadeEndRadius: Double
    var outerDensityMaintain: Double
    var interArmDensity: Double
    var interArmSizeMin: Double
    var interArmSizeMax: Double
    var radialDecay: Double
    var backgroundDensity: Double
    var backgroundSizeVariation: Double
    var jitterStrength: Double
    var densityNoiseScale: Double
    var densityNoiseStrength: Double
    var jitterChaos: Double
    var jitterChaosScale: Double
    var armStarSizeMultiplier: Double
    var interArmStarSizeMultiplier: Double
    var backgroundStarSizeMultiplier: Double
    var galaxyScale: Double
    var colorJitterHue: Double
    var colorJitterSat: Double
    var colorJitterLight: Double
    var colorNoiseScale: Double
}

struct GalaxyPalette: Equatable {
    var core: String
    var ridge: String
    var armBright: String
    var armEdge: String
    var hii: String
    var dust: String
    var outer: String
}

struct GalaxyLayerAlpha {
    var core: Double
    var ridge: Double
    var armBright: Double
    var armEdge: Double
    var hii: Double
    var dust: Double
    var outer: Double
}

struct GlowConfig {
    var pickProb: Double
    var pulseWidth: Double
    var radiusFactor: Double
    var minRadius: Double
    var durationMs: Double
    var bandFactor: Double
    var noiseFactor: Double
    var edgeAlphaThresh: Double
    var edgeExponent: Double
    var ease: String
}

extension GalaxyParams {
    static let `default` = GalaxyParams(
        coreDensity: 0.7,
        coreRadius: 12.0,
        coreSizeMin: 1.0,
        coreSizeMax: 3.5,
        armCount: 5,
        armDensity: 0.6,
        armBaseSizeMin: 0.7,
        armBaseSizeMax: 2.0,
        armHighlightSize: 5.0,
        armHighlightProb: 0.01,
        spiralA: 8.0,
        spiralB: 0.29,
        armWidthInner: 29.0,
        armWidthOuter: 65.0,
        armWidthGrowth: 2.5,
        armWidthScale: 1.0,
        armTransitionSoftness: 3.8,
        fadeStartRadius: 0.5,
        fadeEndRadius: 1.3,
        outerDensityMaintain: 0.10,
        interArmDensity: 0.150,
        interArmSizeMin: 0.6,
        interArmSizeMax: 1.2,
        radialDecay: 0.0015,
        backgroundDensity: 0.00024,
        backgroundSizeVariation: 2.0,
        jitterStrength: 10.0,
        densityNoiseScale: 0.018,
        densityNoiseStrength: 0.8,
        jitterChaos: 0.0,
        jitterChaosScale: 0.0,
        armStarSizeMultiplier: 1.0,
        interArmStarSizeMultiplier: 1.0,
        backgroundStarSizeMultiplier: 1.0,
        galaxyScale: 0.88,
        colorJitterHue: 0.0,
        colorJitterSat: 0.0,
        colorJitterLight: 0.0,
        colorNoiseScale: 0.0
    )

    static func platformDefault() -> GalaxyParams {
        var params = GalaxyParams.default
#if os(iOS)
        params.applyiOSTuning()
#endif
        return params
    }

    mutating func applyiOSTuning() {
        armWidthScale = 2.9
        armWidthInner = 29.0
        armWidthOuter = 65.0
        armWidthGrowth = 2.5
        armTransitionSoftness = 7.0
        jitterStrength = max(jitterStrength, 25.0)
        armStarSizeMultiplier *= 1.2
        interArmStarSizeMultiplier *= 1.35
        interArmSizeMin = max(0.4, interArmSizeMin * 1.25)
        interArmSizeMax = max(interArmSizeMin, interArmSizeMax * 1.25)
        backgroundStarSizeMultiplier = max(backgroundStarSizeMultiplier, backgroundStarSizeMultiplier * 1.1)
    }
}

extension GalaxyPalette {
    static let baseline = GalaxyPalette(
        core: "#5A4E41",
        ridge: "#5B5E66",
        armBright: "#28457B",
        armEdge: "#245B88",
        hii: "#3C194E",
        dust: "#0E0A14",
        outer: "#415069"
    )

    static let lit = GalaxyPalette(
        core: "#E3B787",
        ridge: "#C7C9CE",
        armBright: "#92ADE0",
        armEdge: "#95C2E8",
        hii: "#D88AC9",
        dust: "#3F3264",
        outer: "#ACB9CF"
    )
}

extension GalaxyLayerAlpha {
    static let baseline = GalaxyLayerAlpha(
        core: 1.0,
        ridge: 0.98,
        armBright: 0.90,
        armEdge: 0.85,
        hii: 0.88,
        dust: 0.45,
        outer: 0.78
    )
}

extension GlowConfig {
    static let baseline = GlowConfig(
        pickProb: 0.2,
        pulseWidth: 0.25,
        radiusFactor: 0.0175,
        minRadius: 30,
        durationMs: 950,
        bandFactor: 0.12,
        noiseFactor: 0.08,
        edgeAlphaThresh: 8,
        edgeExponent: 1.1,
        ease: "sine"
    )
}

```

`StarO/Galaxy/GalaxyRandom.swift`:

```swift
import Foundation

func seeded(_ seed: UInt64) -> () -> Double {
    var state = seed
    return {
        state &+= 0x6D2B79F5
        var result = state
        result = (result ^ (result >> 15)) &* (1 | state)
        result ^= result &+ ((result ^ (result >> 7)) &* (61 | result))
        return Double((result ^ (result >> 14)) & 0xFFFFFFFF) / Double(UInt32.max)
    }
}

struct SeededRandom {
    private var generator: () -> Double

    init(seed: UInt64) {
        self.generator = seeded(seed)
    }

    mutating func next() -> Double {
        generator()
    }

    mutating func next(in range: ClosedRange<Double>) -> Double {
        let value = generator()
        return range.lowerBound + (range.upperBound - range.lowerBound) * value
    }

    mutating func nextBool(probability: Double) -> Bool {
        generator() < max(0.0, min(1.0, probability))
    }
}

func galaxyDeterministicSeed(from string: String) -> UInt32 {
    var hash: UInt32 = 2166136261
    for scalar in string.unicodeScalars {
        hash ^= UInt32(scalar.value)
        hash &*= 16777619
    }
    return hash
}

func galaxyDeterministicPhase(from string: String) -> Double {
    Double(galaxyDeterministicSeed(from: string)) / Double(UInt32.max)
}

func galaxyNoise2D(_ x: Double, _ y: Double) -> Double {
    let t = sin(x * 12.9898 + y * 78.233) * 43758.5453123
    let value = t - floor(t)
    return value * 2.0 - 1.0
}

func clamp(_ value: Double, min lower: Double = 0.0, max upper: Double = 1.0) -> Double {
    return Swift.max(lower, Swift.min(upper, value))
}

```

`StarO/Galaxy/GalaxyShaders.metal`:

```metal
#include <metal_stdlib>
using namespace metal;

struct Uniforms {
    float time;
    float2 viewportSizePixels;
    float scale;
};

struct VertexOut {
    float4 position [[position]];
    float4 color;
    float pointSize [[point_size]];
    float type;
    float progress;
};

struct StarVertexIn {
    float2 initialPosition [[attribute(0)]];
    float size [[attribute(1)]];
    float type [[attribute(2)]];
    float4 color [[attribute(3)]];
    float highlightStartTime [[attribute(4)]]; // Replaces 'progress'
    float ringIndex [[attribute(5)]];
    float highlightDuration [[attribute(6)]];
};

vertex VertexOut galaxy_vertex(StarVertexIn in [[stage_in]],
                               constant Uniforms& uniforms [[buffer(1)]]) {
    VertexOut out;
    
    float2 center = uniforms.viewportSizePixels * 0.5;
    float2 pos = in.initialPosition;
    float2 finalPos = pos;
    
    // Rotation Logic
    if (in.type < 1.5) { // Type 0 (Normal) and 1 (Lit) rotate
        if (in.ringIndex >= 0.0) {
            float angle = 0.0087266 * uniforms.time; 
            float s = sin(angle);
            float c = cos(angle);
            float rx = pos.x * c - pos.y * s;
            float ry = pos.x * s + pos.y * c;
            finalPos = center + float2(rx, ry) * uniforms.scale;
        } else {
            finalPos = center + pos * uniforms.scale;
        }
    } else { // Type 2 (Pulse) does not rotate
        finalPos = center + pos * uniforms.scale;
    }

    float2 viewport = max(uniforms.viewportSizePixels, float2(1.0));
    float2 ndc = float2(
        (finalPos.x / viewport.x) * 2.0 - 1.0,
        1.0 - (finalPos.y / viewport.y) * 2.0
    );
    
    out.position = float4(ndc, 0.0, 1.0);
    
    // Animation Logic
    float baseSize = max(in.size * uniforms.scale, 1.0);
    float4 baseColor = in.color;
    
    if (in.type > 0.5 && in.type < 1.5) { // Type 1: Lit Star
        float elapsed = uniforms.time - in.highlightStartTime;
        float p = clamp(elapsed / in.highlightDuration, 0.0, 1.0);
        float intensity = sin(p * 3.14159); // PI
        
        float animScale = 1.0 + intensity * 0.8;
        out.pointSize = baseSize * animScale;
        
        // Alpha animation: 0.06 + 0.90 * intensity
        // We assume baseColor passed in has alpha=1 or whatever, we override it?
        // Swift passed: litColor with alpha calculated.
        // Now we pass litColor with alpha=1 (or base), and modulate here.
        float alpha = 0.06 + 0.90 * intensity;
        out.color = float4(baseColor.rgb, alpha);
        out.progress = p;
    } else if (in.type > 1.5) { // Type 2: Pulse
        float elapsed = uniforms.time - in.highlightStartTime;
        float p = clamp(elapsed / in.highlightDuration, 0.0, 1.0);
        
        float animScale = 1.15 + p * 1.7;
        out.pointSize = baseSize * animScale;
        
        float alpha = max(0.0, 1.0 - p) * 0.9;
        out.color = float4(baseColor.rgb, alpha);
        out.progress = p;
    } else {
        out.pointSize = baseSize;
        out.color = baseColor;
        out.progress = 0.0;
    }
    
    out.type = in.type;
    return out;
}

fragment float4 galaxy_fragment(VertexOut in [[stage_in]],
                                float2 pointCoord [[point_coord]],
                                constant Uniforms& uniforms [[buffer(0)]]) {
    float2 centered = pointCoord - float2(0.5);
    float dist = length(centered);
    if (dist >= 0.5) {
        discard_fragment();
    }

    if (in.type < 0.5) {
        float alpha = smoothstep(0.5, 0.0, dist);
        return float4(in.color.rgb, in.color.a * alpha);
    }

    if (in.type < 1.5) {
        float falloff = smoothstep(0.5, 0.0, dist);
        float core = smoothstep(0.18, 0.0, dist);
        float alpha = saturate(falloff * in.color.a + core * 0.6);
        return float4(in.color.rgb, alpha);
    }

    float progress = clamp(in.progress, 0.0, 1.0);
    float normalizedDist = saturate(dist / 0.5);
    float halo = smoothstep(0.5, 0.0, normalizedDist);
    float core = smoothstep(0.18, 0.0, normalizedDist);
    float pulse = smoothstep(0.35 + progress * 0.2, 0.15, normalizedDist) * (1.0 - progress);
    float alpha = saturate(halo * 0.55 + core * 0.85 + pulse * 0.4) * (1.0 - progress * 0.2);
    float whiteBlend = core * 0.6;
    float3 blended = mix(in.color.rgb, float3(1.0), whiteBlend);
    return float4(blended, alpha);
}

```

`StarO/Galaxy/GalaxyTouchOverlay.swift`:

```swift
import SwiftUI
import UIKit
import QuartzCore

final class GalaxyTouchUIView: UIView {
    var onTap: ((CGPoint, CFTimeInterval) -> Void)?
    var isTapEnabled: Bool = true
    private static let sparkleImage: CGImage = {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 48, height: 48))
        let image = renderer.image { context in
            let cg = context.cgContext
            cg.setAllowsAntialiasing(true)
            cg.setShouldAntialias(true)

            let center = CGPoint(x: 24, y: 24)
            let longRadius = CGFloat(20)
            let shortRadius = CGFloat(5)
            let path = UIBezierPath()
            for index in 0..<8 {
                let angle = CGFloat(index) * (.pi / 4)
                let radius = (index % 2 == 0) ? longRadius : shortRadius
                let point = CGPoint(
                    x: center.x + radius * CGFloat(cos(Double(angle))),
                    y: center.y + radius * CGFloat(sin(Double(angle)))
                )
                index == 0 ? path.move(to: point) : path.addLine(to: point)
            }
            path.close()
            let colors = [UIColor(white: 1, alpha: 1).cgColor, UIColor(white: 1, alpha: 0).cgColor] as CFArray
            let locations: [CGFloat] = [0, 1]
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: locations) {
                cg.saveGState()
                path.addClip()
                cg.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: longRadius, options: .drawsAfterEndLocation)
                cg.restoreGState()
            }
            cg.setFillColor(UIColor.white.cgColor)
            cg.fillEllipse(in: CGRect(x: center.x - 2, y: center.y - 2, width: 4, height: 4))
        }
        return image.cgImage ?? UIImage(systemName: "star.fill")!.cgImage!
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
        backgroundColor = .clear
        isMultipleTouchEnabled = false
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var startLocation: CGPoint?

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard let touch = touches.first else { return }
        startLocation = touch.location(in: self)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        guard isTapEnabled else { return }
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // Check for drag/swipe
        if let start = startLocation {
            let dx = location.x - start.x
            let dy = location.y - start.y
            let distance = sqrt(dx*dx + dy*dy)
            if distance > 10.0 {
                print("[TouchOverlay] drag detected (distance: \(distance)), ignoring tap")
                startLocation = nil
                return
            }
        }
        
        let timestamp = touch.timestamp
        print("[TouchOverlay] tap at (\(location.x), \(location.y)) ts=\(timestamp)")
        // ❌ 已禁用粒子爆炸
        // burst(at: location)
        onTap?(location, timestamp)
        startLocation = nil
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        startLocation = nil
    }

    private func burst(at point: CGPoint) {
        let emitter = CAEmitterLayer()
        emitter.emitterPosition = point
        emitter.emitterShape = .point
        emitter.renderMode = .additive

        let cell = CAEmitterCell()
        cell.contents = Self.sparkleImage
        cell.birthRate = 0
        cell.lifetime = 0.35
        cell.lifetimeRange = 0.15
        cell.alphaSpeed = -2.0
        cell.scale = 0.6
        cell.scaleRange = 0.2
        cell.scaleSpeed = -1.2
        cell.velocity = 42
        cell.velocityRange = 28
        cell.emissionRange = .pi * 2
        cell.spin = 4
        cell.spinRange = 6

        emitter.emitterCells = [cell]
        layer.addSublayer(emitter)

        emitter.beginTime = CACurrentMediaTime()
        emitter.setValue(24, forKeyPath: "emitterCells.spark.birthRate")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            emitter.setValue(0, forKeyPath: "emitterCells.spark.birthRate")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            emitter.removeFromSuperlayer()
        }
    }
}

struct GalaxyTouchOverlay: UIViewRepresentable {
    final class Coordinator {
        var onTapClosure: (CGPoint, CFTimeInterval) -> Void

        init(onTap: @escaping (CGPoint, CFTimeInterval) -> Void) {
            self.onTapClosure = onTap
        }

        func handleTap(_ point: CGPoint, _ timestamp: CFTimeInterval) {
            onTapClosure(point, timestamp)
        }
    }

    var onTap: (CGPoint, CFTimeInterval) -> Void
    var isTapEnabled: Bool = true

    func makeCoordinator() -> Coordinator {
        Coordinator(onTap: onTap)
    }

    func makeUIView(context: Context) -> GalaxyTouchUIView {
        let view = GalaxyTouchUIView(frame: .zero)
        view.isTapEnabled = isTapEnabled
        context.coordinator.onTapClosure = onTap
        view.onTap = { point, ts in
            context.coordinator.handleTap(point, ts)
        }
        return view
    }

    func updateUIView(_ uiView: GalaxyTouchUIView, context: Context) {
        uiView.isTapEnabled = isTapEnabled
        context.coordinator.onTapClosure = onTap
        uiView.onTap = { point, ts in
            context.coordinator.handleTap(point, ts)
        }
    }
}

```

`StarO/Galaxy/GalaxyViewModel.swift`:

```swift
import SwiftUI
import QuartzCore
import StarOracleCore

struct GalaxyHighlight {
    let color: Color
    let activatedAt: CFTimeInterval
    let whiteBias: Double // 0.0 = 偏高亮色, 1.0 = 偏纯白
    var isPermanent: Bool = false
}

struct GalaxyPulse: Identifiable {
    let id = UUID()
    let position: CGPoint
    let color: Color
    let startTime: TimeInterval
    let duration: TimeInterval
    let size: CGFloat
}

struct GalaxyHighlightEntry: Identifiable {
    let id: String
    let ring: Int
    let position: CGPoint
    let size: CGFloat
    let colorHex: String
    let litHex: String

    var identifier: String { id }
}

@MainActor
final class GalaxyViewModel: ObservableObject {
    @Published private(set) var rings: [[GalaxyStar]] = []
    @Published private(set) var backgroundStars: [GalaxyBackgroundStar] = []
    @Published private(set) var pulses: [GalaxyPulse] = []
    @Published private(set) var highlights: [String: GalaxyHighlight] = [:]

    let params: GalaxyParams
    let palette: GalaxyPalette
    let litPalette: GalaxyPalette
    let glowConfig: GlowConfig
    let layerAlpha: GalaxyLayerAlpha

    private(set) var bandSize: CGSize = .zero
    private var lastSize: CGSize = .zero
    private var elapsedTime: TimeInterval = 0
    private let baseDegPerMs = 0.0005
    private let alphaMap: [String: Double]
    private var selectionRandom = SeededRandom(seed: 0xC0FFEE1234567890)
    private var pulseRandom = SeededRandom(seed: 0xDABA0FF1CE123456)
    private var starLookup: [String: GalaxyStar] = [:]
    private var ringRotationCache: [RotationCache] = []
    private var screenPositionLookup: [String: CGPoint] = [:]
    private let highlightTintHex: String
    var timeOrigin: CFTimeInterval = 0 // 与渲染对齐的时间原点

    var onRegionSelected: ((GalaxyRegion) -> Void)?
    var onTap: ((CGPoint, CGSize, GalaxyRegion, TimeInterval) -> Void)?
    var onHighlightsPersisted: (([GalaxyHighlightEntry]) -> Void)?

    init(
        params: GalaxyParams = .platformDefault(),
        palette: GalaxyPalette = .baseline,
        litPalette: GalaxyPalette = .lit,
        glowConfig: GlowConfig = .baseline,
        layerAlpha: GalaxyLayerAlpha = .baseline
    ) {
        self.params = params
        self.palette = palette
        self.litPalette = litPalette
        self.glowConfig = glowConfig
        self.layerAlpha = layerAlpha
        // 对齐提交 cf1de85... 中使用的高亮色调
        let boostedHighlightHex = "#5AE7FF"
        self.highlightTintHex = boostedHighlightHex
        self.alphaMap = [
            normalizeGalaxyHex(palette.core): layerAlpha.core,
            normalizeGalaxyHex(palette.ridge): layerAlpha.ridge,
            normalizeGalaxyHex(palette.armBright): layerAlpha.armBright,
            normalizeGalaxyHex(palette.armEdge): layerAlpha.armEdge,
            normalizeGalaxyHex(palette.hii): layerAlpha.hii,
            normalizeGalaxyHex(palette.dust): layerAlpha.dust,
            normalizeGalaxyHex(palette.outer): layerAlpha.outer
        ]
    }

    private struct RotationCache {
        let sin: Double
        let cos: Double
    }

    var ringCount: Int {
        rings.count
    }

    private var highlightLifetime: CFTimeInterval {
        max(0.01, glowConfig.durationMs / 1000.0 * 1.25)
    }

    @discardableResult
    func prepareIfNeeded(for size: CGSize) -> Bool {
        guard size.width > 0, size.height > 0 else { return false }
        if abs(size.width - lastSize.width) < 1 && abs(size.height - lastSize.height) < 1 {
            return false
        }
        regenerate(for: size)
        lastSize = size
        return true
    }

    func regenerate(for size: CGSize) {
        #if os(iOS)
        let dpr = Double(UIScreen.main.scale)
        let reduceMotion = UIAccessibility.isReduceMotionEnabled
        #else
        let dpr = 2.0
        let reduceMotion = false
        #endif

        let field = GalaxyGenerator.generateField(
            size: size,
            params: params,
            palette: palette,
            litPalette: litPalette,
            structureColoring: true,
            scale: params.galaxyScale,
            deviceScale: dpr,
            reduceMotion: reduceMotion
        )
        rings = field.rings
        backgroundStars = field.background
        bandSize = field.bandSize
        highlights.removeAll()
        pulses.removeAll()
        elapsedTime = 0
        rebuildStarLookup()
        ringRotationCache = []
        screenPositionLookup = [:]
    }

    func updateElapsedTimeOnly(elapsed: TimeInterval) {
        elapsedTime = max(0, elapsed)
        
        // 仅当有脉冲过期时才修改数组，避免每帧触发 @Published 更新
        if !pulses.isEmpty {
            let countBefore = pulses.count
            let filtered = pulses.filter { elapsedTime - $0.startTime <= $0.duration }
            if filtered.count != countBefore {
                pulses = filtered
            }
        }
        
        purgeExpiredHighlights()
        
        // 仍然更新旋转缓存，以便 handleTap 时能计算正确位置（开销很小，仅10个环）
        updateRotationCache(for: elapsedTime)
        
        // ❌ 不再更新 screenPositionLookup，节省大量 CPU
        // updateScreenPositionCache()
    }

    func update(elapsed: TimeInterval) {
        updateElapsedTimeOnly(elapsed: elapsed)
    }

    func alpha(for star: GalaxyStar) -> Double {
        alphaMap[star.baseHex] ?? 1.0
    }

    func handleTap(at location: CGPoint, in size: CGSize, tapTimestamp: CFTimeInterval? = nil) {
        guard ringCount > 0 else { return }
        #if DEBUG
        print("[GalaxyViewModel] handleTap at (\(location.x), \(location.y)) size (\(size.width), \(size.height))")
        #endif
        
        // 只保留region选择功能
        let region = region(for: location, in: size)
        onRegionSelected?(region)
        // Pass timestamp to callback
        onTap?(location, size, region, tapTimestamp ?? elapsedTime)
        
        // Restore immediate highlight trigger
        triggerHighlight(at: location, in: size, tapTimestamp: tapTimestamp)
    }
    
    func triggerHighlight(at location: CGPoint, in size: CGSize, tapTimestamp: CFTimeInterval? = nil, isPermanent: Bool = false) {
        guard ringCount > 0 else { return }
        
        // Use deterministic RNG if timestamp is provided to ensure consistent selection
        // between transient flash and permanent highlight
        var rng: SeededRandom
        if let ts = tapTimestamp {
            let seed = UInt64(abs(Int64(ts * 1_000_000)))
            rng = SeededRandom(seed: seed)
        } else {
            rng = selectionRandom
        }
        
        // 计算搜索半径（恢复原版下限 30）
        let radiusBase = min(size.width, size.height) * glowConfig.radiusFactor
        let radius = max(CGFloat(30.0), CGFloat(radiusBase))

        // 计算点击时的 elapsed（对齐渲染时间原点），命中按此时刻的位置进行
        let elapsedAtTap: TimeInterval = {
            if let ts = tapTimestamp, timeOrigin > 0 {
                return max(0, ts - timeOrigin)
            }
            return elapsedTime
        }()
        
        // 收集候选星星
        let candidates = collectCandidates(at: location, in: size, radius: radius, elapsed: elapsedAtTap)
        
        guard !candidates.isEmpty else {
            #if DEBUG
            print("[GalaxyViewModel] no selectable stars around tap")
            #endif
            return
        }
        
        #if DEBUG
        print("[GalaxyViewModel] candidates: \(candidates.count)")
        #endif
        
        // 挑选高亮星星（加权随机）
        let selected = pickHighlights(from: candidates, targetCount: min(30, candidates.count), rng: &rng)
        
        #if DEBUG
        print("[GalaxyViewModel] selected: \(selected.count) stars for highlight")
        #endif
        
        // 禁用脉冲动画（删除大球形闪烁，仅保留星点高亮）
        // appendPulses(for: selected)
        
        // 应用高亮状态（用于星星变大变亮）
        let entries = applyHighlights(from: selected, isPermanent: isPermanent, rng: &rng)
        #if DEBUG
        print("[GalaxyViewModel] highlights added: \(entries.count), total: \(highlights.count)")
        #endif
        
        // Update global RNG only if we didn't use a deterministic one
        if tapTimestamp == nil {
            selectionRandom = rng
        }
        
        // 通知持久化（如果有回调）
        if !entries.isEmpty {
            onHighlightsPersisted?(entries)
        }
    }

    private func collectCandidates(at location: CGPoint, in size: CGSize, radius: CGFloat, elapsed: TimeInterval) -> [HighlightCandidate] {
        var results: [HighlightCandidate] = []
        let radiusSquared = radius * radius
        for (index, ring) in rings.enumerated() {
            for star in ring {
                // 这里按需计算位置，虽然比查表慢，但因为只在点击时触发，完全可接受
                let pos = screenPosition(for: star, ringIndex: index, in: size, elapsed: elapsed)
                let dx = pos.x - location.x
                let dy = pos.y - location.y
                let distanceSquared = dx * dx + dy * dy
                if distanceSquared <= radiusSquared {
                    results.append(HighlightCandidate(star: star, position: pos, distance: distanceSquared))
                }
            }
        }
        if results.isEmpty {
            var nearest: HighlightCandidate?
            var minDst = Double.greatestFiniteMagnitude
            for (index, ring) in rings.enumerated() {
                for star in ring {
                    let pos = screenPosition(for: star, ringIndex: index, in: size, elapsed: elapsed)
                    let dx = pos.x - location.x
                    let dy = pos.y - location.y
                    let distanceSquared = dx * dx + dy * dy
                    if distanceSquared < minDst {
                        minDst = distanceSquared
                        nearest = HighlightCandidate(star: star, position: pos, distance: distanceSquared)
                    }
                }
            }
            if let nearest, minDst < 2500 { // 50*50，如果最近的星星在50像素内，也允许选中
                return [nearest]
            }
        }
        return results
    }

    private func pickHighlights(from candidates: [HighlightCandidate], targetCount: Int, rng: inout SeededRandom) -> [HighlightCandidate] {
        let cappedTarget = min(max(targetCount, 0), candidates.count)
        guard cappedTarget > 0 else { return [] }

        // 1) 中心密集核心：按距离排序，优先选取一部分最近的点
        // 注意：这里的“核心”是指点击位置的中心，而不是银河的核心（band=0）
        let sortedByDistance = candidates.sorted { $0.distance < $1.distance }
        let coreCount = min(max(3, Int(ceil(Double(cappedTarget) * 0.4))), cappedTarget)
        let denseStars = Array(sortedByDistance.prefix(coreCount))
        
        if denseStars.count >= cappedTarget { return denseStars }
        
        let denseIDs = Set(denseStars.map { $0.star.id })
        let remainingCandidates = candidates.filter { !denseIDs.contains($0.star.id) }
        let remainingTarget = cappedTarget - denseStars.count
        
        // 2) 距离加权抽样（无放回）：越靠近中心，被选中概率越高
        // 距离权重：w = ((R - d)/R)^gamma
        let maxDistance = remainingCandidates.map { $0.distance }.max() ?? 1.0
        let R = sqrt(max(1e-9, maxDistance))
        let gamma: Double = 2.2

        struct WeightedKey { let candidate: HighlightCandidate; let key: Double }
        var keys: [WeightedKey] = []
        keys.reserveCapacity(remainingCandidates.count)
        
        for c in remainingCandidates {
            let d = sqrt(max(0.0, c.distance))
            let ratio = max(0.0, min(1.0, 1.0 - d / R))
            let w = pow(ratio, gamma)
            let u = max(1e-9, min(0.999999, rng.next()))
            let key = -log(u) / max(w, 1e-9) // 小 key 表示更高的选择机会
            keys.append(WeightedKey(candidate: c, key: key))
        }
        
        keys.sort { $0.key < $1.key }
        let weightedSelected = keys.prefix(remainingTarget).map { $0.candidate }

        return denseStars + weightedSelected
    }

    private func appendPulses(for candidates: [HighlightCandidate]) {
        let baseDuration = glowConfig.durationMs / 1000.0
        let now = elapsedTime
        var rng = pulseRandom
        var pulsesToAdd: [GalaxyPulse] = []
        pulsesToAdd.reserveCapacity(candidates.count)
        for candidate in candidates {
            let duration = baseDuration * rng.next(in: 0.65...1.05)
            let scale = rng.next(in: 1.15...1.6)
            let size = max(4.0, candidate.star.size * scale)
            let color = highlightColor(for: candidate.star)
            let pulse = GalaxyPulse(
                position: candidate.position,
                color: color,
                startTime: now,
                duration: duration,
                size: CGFloat(size)
            )
            pulsesToAdd.append(pulse)
        }
        pulseRandom = rng
        pulses.append(contentsOf: pulsesToAdd)
        #if DEBUG
        if !pulsesToAdd.isEmpty {
            print("[GalaxyViewModel] pulses added: \(pulsesToAdd.count)")
        }
        #endif
        if pulses.count > 120 {
            pulses = Array(pulses.suffix(120))
        }
    }

    private func applyHighlights(from candidates: [HighlightCandidate], isPermanent: Bool, rng: inout SeededRandom) -> [GalaxyHighlightEntry] {
        guard !candidates.isEmpty else { return [] }
        var outputs: [GalaxyHighlightEntry] = []
        outputs.reserveCapacity(candidates.count)
        var seen: Set<String> = []

        for candidate in candidates {
            let color = highlightColor(for: candidate.star)
            // 为每个高亮分配一个随机的白偏移（决定偏白还是偏高亮色）
            let bias = rng.next()
            
            // Update or create highlight
            // If it already exists and is permanent, keep it permanent
            let existing = highlights[candidate.star.id]
            let shouldBePermanent = isPermanent || (existing?.isPermanent ?? false)
            
            highlights[candidate.star.id] = GalaxyHighlight(
                color: color,
                activatedAt: CACurrentMediaTime(), // Reset animation time
                whiteBias: bias,
                isPermanent: shouldBePermanent
            )
            
            if !seen.contains(candidate.star.id) {
                seen.insert(candidate.star.id)
                let entry = GalaxyHighlightEntry(
                    id: candidate.star.id,
                    ring: candidate.star.band,
                    position: candidate.position,
                    size: candidate.star.size,
                    colorHex: candidate.star.baseHex,
                    litHex: candidate.star.litHex
                )
                outputs.append(entry)
            }
        }
        return outputs
    }

    func highlightFlashProgress(for star: GalaxyStar) -> Double {
        guard let highlight = highlights[star.id] else { return 1.0 }
        let duration = max(0.01, glowConfig.durationMs / 1000.0 * 0.6)
        let progress = (elapsedTime - highlight.activatedAt) / duration
        return min(max(progress, 0.0), 1.0)
    }
    
    func isHighlighted(_ star: GalaxyStar) -> Bool {
        return highlights[star.id] != nil
    }

    func highlightEntries() -> [(GalaxyStar, GalaxyHighlight)] {
        highlights.compactMap { key, highlight in
            guard let star = starLookup[key] else { return nil }
            return (star, highlight)
        }
    }

    private func rebuildStarLookup() {
        var map: [String: GalaxyStar] = [:]
        for ring in rings {
            for star in ring {
                map[star.id] = star
            }
        }
        starLookup = map
    }

    private func purgeExpiredHighlights() {
        // Remove highlights that have exceeded their duration, UNLESS they are permanent
        let duration = max(0.01, glowConfig.durationMs / 1000.0)
        let now = CACurrentMediaTime()
        
        highlights = highlights.filter { _, highlight in
            highlight.isPermanent || (now - highlight.activatedAt <= duration)
        }
    }

    private func highlightColor(for star: GalaxyStar) -> Color {
        galaxyBlendHex(star.litHex, highlightTintHex, ratio: 0.45)
    }


    private func updateRotationCache(for elapsed: TimeInterval) {
        guard ringCount > 0 else {
            ringRotationCache = []
            return
        }
        let angle = baseDegPerMs * elapsed * 1000.0 * (.pi / 180.0)
        let cacheEntry = RotationCache(sin: sin(angle), cos: cos(angle))
        ringRotationCache = Array(repeating: cacheEntry, count: ringCount)
    }

    private func updateScreenPositionCache() {
        // ❌ 移除全量缓存更新，因为渲染已经移至 GPU
        screenPositionLookup = [:]
    }

    private func region(for location: CGPoint, in size: CGSize) -> GalaxyRegion {
        let center = CGPoint(x: size.width / 2.0, y: size.height / 2.0)
        let angle = atan2(location.y - center.y, location.x - center.x)
        let degrees = (angle * 180.0 / .pi + 360.0).truncatingRemainder(dividingBy: 360.0)
        if degrees < 120.0 { return .emotion }
        if degrees < 240.0 { return .relation }
        return .growth
    }

    func screenPosition(for star: GalaxyStar, ringIndex: Int, in size: CGSize, elapsed: TimeInterval) -> CGPoint {
        // 实时计算位置，仅用于点击检测（低频）
        let center = CGPoint(x: size.width / 2.0, y: size.height / 2.0)
        let scale = CGFloat(params.galaxyScale)
        let bandCenter = CGPoint(x: star.bandSize.width / 2.0, y: star.bandSize.height / 2.0)
        let dx = Double(star.position.x - bandCenter.x)
        let dy = Double(star.position.y - bandCenter.y)
        
        // 确保使用与 GPU 一致的旋转逻辑
        // GPU: angle = 0.0087266 * uniforms.time
        // CPU: baseDegPerMs * elapsed * 1000.0 * (.pi / 180.0)
        // baseDegPerMs = 0.0005
        // 0.0005 * 1000 * 0.017453 = 0.0087265
        // 一致
        
        let angle = baseDegPerMs * elapsed * 1000.0 * (.pi / 180.0)
        let rx = dx * cos(angle) - dy * sin(angle)
        let ry = dx * sin(angle) + dy * cos(angle)
        let sx = center.x + CGFloat(rx) * scale
        let sy = center.y + CGFloat(ry) * scale
        return CGPoint(x: sx, y: sy)
    }
}

private struct HighlightCandidate {
    let star: GalaxyStar
    let position: CGPoint
    let distance: CGFloat
}

```

`StarO/GalaxyBackgroundView.swift`:

```swift
import SwiftUI
import StarOracleCore
import StarOracleFeatures

#if os(iOS)
import UIKit
#endif

struct GalaxyBackgroundView: View {
  @EnvironmentObject private var galaxyStore: GalaxyStore
  @EnvironmentObject private var starStore: StarStore
  @StateObject private var viewModel = GalaxyViewModel()
  
  @State private var lastTapRegion: GalaxyRegion?
  @State private var lastTapDate: Date = .distantPast
  @State private var debounceTask: Task<Void, Never>?
  var isTapEnabled: Bool = true

  var body: some View {
    GeometryReader { proxy in
      GalaxyMetalContainer(
        viewModel: viewModel,
        size: proxy.size,
        onRegionSelected: nil,
        onTap: { point, size, region, timestamp in
          // Cancel previous task to prevent card generation from previous rapid taps
          debounceTask?.cancel()
          
          // Lock UI during generation
          galaxyStore.setIsGeneratingCard(true)
          
          debounceTask = Task {
            // Wait for 600ms to allow rapid tapping (exploration)
            // Only the last tap will trigger the card generation AND the highlight
            try? await Task.sleep(nanoseconds: 600_000_000)
            
            if !Task.isCancelled {
              await MainActor.run {
                // Trigger PERMANENT highlight for the valid tap
                viewModel.triggerHighlight(at: point, in: size, tapTimestamp: timestamp, isPermanent: true)
                
                let xPct = Double(point.x / size.width) * 100.0
                let yPct = Double(point.y / size.height) * 100.0
                starStore.setIsAsking(false, position: StarPosition(x: xPct, y: yPct))
                
                _ = starStore.drawInspirationCard(region: region)
                lastTapRegion = region
                lastTapDate = Date()
                
                // Unlock UI
                galaxyStore.setIsGeneratingCard(false)
              }
            }
          }
        },
        isTapEnabled: isTapEnabled
      )
      .ignoresSafeArea()
      .overlay(alignment: .topLeading) {
        if let region = lastTapRegion, Date().timeIntervalSince(lastTapDate) < 2 {
          Label("灵感来自 \(regionLabel(region)) 区域", systemImage: "sparkles")
            .font(.caption)
            .padding(8)
            .background(Color.black.opacity(0.4), in: Capsule())
            .padding()
        }
      }
    }
  }

  private func regionLabel(_ region: GalaxyRegion) -> String {
    switch region {
    case .emotion: return "情绪"
    case .relation: return "关系"
    case .growth: return "成长"
    }
  }
}

```

`StarO/InputDrawerManager.swift`:

```swift
import SwiftUI
import UIKit

// MARK: - InputPassthroughWindow - 自定义窗口类，支持触摸事件穿透
class InputPassthroughWindow: UIWindow {
    weak var inputDrawerViewController: InputViewController?  // 改名避免与系统属性冲突
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let hitView = super.hitTest(point, with: event) else {
            return nil
        }

        if hitView == self.rootViewController?.view {
            inputDrawerViewController?.textField.resignFirstResponder()
            return nil
        }

        if let passthroughView = hitView as? PassthroughView {
            if let containerView = passthroughView.containerView {
                let convertedPoint = passthroughView.convert(point, to: containerView)
                if !containerView.bounds.contains(convertedPoint) {
                    inputDrawerViewController?.textField.resignFirstResponder()
                    return nil
                }
            }
            return hitView
        }

        return hitView
    }
}

// MARK: - InputDrawer事件协议
public protocol InputDrawerDelegate: AnyObject {
    func inputDrawerDidSubmit(_ text: String)
    func inputDrawerDidChange(_ text: String)
    func inputDrawerDidFocus()
    func inputDrawerDidBlur()
}

// MARK: - InputDrawerManager业务逻辑类
@MainActor
public class InputDrawerManager {
    private var inputWindow: UIWindow?
    private weak var windowScene: UIWindowScene?
    private var isVisible = false
    private var currentText = ""
    internal var placeholder = "输入文字..." // 改为internal让InputViewController访问
    internal var bottomSpace: CGFloat = 20 // 默认20px，匹配React版本
    internal var horizontalOffset: CGFloat = 0
    private var inputViewController: InputViewController?
    
    // 事件代理
    public weak var delegate: InputDrawerDelegate?
    
    // MARK: - Public API
    
    func attach(to scene: UIWindowScene) {
        windowScene = scene
        if let window = inputWindow {
            window.windowScene = scene
            window.frame = scene.screen.bounds
        }
    }
    
    func show(animated: Bool = true, completion: @escaping (Bool) -> Void) {
        NSLog("🎯 InputDrawerManager: 显示输入框")
        
        DispatchQueue.main.async {
            if self.inputWindow != nil {
                NSLog("🎯 输入框已存在，直接显示")
                self.inputWindow?.isHidden = false
                self.inputWindow?.isUserInteractionEnabled = true
                self.isVisible = true
                completion(true)
                return
            }
            
            self.createInputWindow()
            
            if animated {
                self.inputWindow?.alpha = 0
                UIView.animate(withDuration: 0.3) {
                    self.inputWindow?.alpha = 1
                } completion: { _ in
                    self.isVisible = true
                    completion(true)
                }
            } else {
                self.isVisible = true
                completion(true)
            }
        }
    }
    
    func hide(animated: Bool = true, completion: @escaping () -> Void = {}) {
        NSLog("🎯 InputDrawerManager: 隐藏输入框")
        
        DispatchQueue.main.async {
            guard let window = self.inputWindow else {
                completion()
                return
            }
            
            if animated {
                UIView.animate(withDuration: 0.3) {
                    window.alpha = 0
                } completion: { _ in
                    window.isHidden = true
                    self.isVisible = false
                    completion()
                }
            } else {
                window.isHidden = true
                self.isVisible = false
                completion()
            }
        }
    }
    
    func setText(_ text: String) {
        NSLog("🎯 InputDrawerManager: 设置文本: \(text)")
        currentText = text
        inputViewController?.updateText(text)
    }
    
    func getText() -> String {
        NSLog("🎯 InputDrawerManager: 获取文本")
        return currentText
    }
    
    func focus() {
        NSLog("🎯 InputDrawerManager: 聚焦输入框")
        inputViewController?.focusInput()
    }
    
    func blur() {
        NSLog("🎯 InputDrawerManager: 失焦输入框")
        inputViewController?.blurInput()
    }
    
    func setBottomSpace(_ space: CGFloat) {
        NSLog("🎯 InputDrawerManager: 设置底部空间: \(space)")
        bottomSpace = space
        inputViewController?.updateBottomSpace(space)
    }
    
    func setPlaceholder(_ placeholder: String) {
        NSLog("🎯 InputDrawerManager: 设置占位符: \(placeholder)")
        self.placeholder = placeholder
        inputViewController?.updatePlaceholder(placeholder)
    }

    func setHorizontalOffset(_ offset: CGFloat, animated: Bool = true) {
        let normalized = max(0, offset)
        NSLog("🎯 InputDrawer: 更新水平偏移 -> \(normalized) (animated: \(animated))")
        NSLog("🎯 InputDrawerManager: 设置水平偏移: \(normalized)")
        horizontalOffset = normalized
        DispatchQueue.main.async { [weak self] in
            self?.inputViewController?.updateHorizontalOffset(normalized, animated: animated)
        }
    }
    
    func getVisibility() -> Bool {
        return isVisible
    }
    
    // MARK: - Private Methods
    
    private func createInputWindow() {
        NSLog("🎯 InputDrawerManager: 创建输入框窗口")
        let scene = windowScene ?? UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        if windowScene == nil && scene == nil {
            NSLog("⚠️ InputDrawerManager: 未找到可用的UIWindowScene，使用UIScreen.main作为兜底")
        }
        let bounds = scene?.screen.bounds ?? UIScreen.main.bounds
        
        // 创建输入框窗口 - 使用自定义的InputPassthroughWindow支持触摸穿透
        let window = InputPassthroughWindow(frame: bounds)
        if let scene {
            window.windowScene = scene
        }
        window.windowLevel = UIWindow.Level.statusBar - 0.5  // 略低于statusBar，但高于普通窗口
        window.backgroundColor = UIColor.clear
        
        // 关键：让窗口不阻挡其他交互，只处理输入框区域的触摸
        window.isHidden = false
        
        // 创建输入框视图控制器
        inputViewController = InputViewController(manager: self)
        window.rootViewController = inputViewController
        inputViewController?.loadViewIfNeeded()
        inputViewController?.updateText(currentText)
        inputViewController?.updatePlaceholder(placeholder)
        inputViewController?.updateBottomSpace(bottomSpace)
        inputViewController?.updateHorizontalOffset(horizontalOffset, animated: false)
        
        // 设置窗口对视图控制器的引用，用于收起键盘
        window.inputDrawerViewController = inputViewController  // 使用新的属性名
        
        // 保存窗口引用
        inputWindow = window
        
        // 不使用makeKeyAndVisible()，避免抢夺焦点，让触摸事件更容易透传
        window.isHidden = false
        
        NSLog("🎯 InputDrawerManager: 输入框窗口创建完成")
        NSLog("🎯 InputDrawer窗口层级: \(window.windowLevel.rawValue)")
        NSLog("🎯 StatusBar层级: \(UIWindow.Level.statusBar.rawValue)")
        NSLog("🎯 Alert层级: \(UIWindow.Level.alert.rawValue)")
        NSLog("🎯 Normal层级: \(UIWindow.Level.normal.rawValue)")
    }
    
    // MARK: - 输入框事件处理
    
    internal func handleTextChange(_ text: String) {
        currentText = text
        delegate?.inputDrawerDidChange(text)
    }
    
    internal func handleTextSubmit(_ text: String) {
        currentText = text
        delegate?.inputDrawerDidSubmit(text)
        NSLog("🎯 InputDrawerManager: 文本提交: \(text)")
    }
    
    internal func handleFocus() {
        delegate?.inputDrawerDidFocus()
        NSLog("🎯 InputDrawerManager: 输入框获得焦点")
    }
    
    internal func handleBlur() {
        delegate?.inputDrawerDidBlur()
        NSLog("🎯 InputDrawerManager: 输入框失去焦点")
    }
}

// MARK: - InputViewController - 处理输入框UI显示
class InputViewController: UIViewController {
    private weak var manager: InputDrawerManager?
    private var containerView: UIView!
    internal var textField: UITextField!  // 改为internal让InputPassthroughWindow可以访问
    private var sendButton: UIButton!
    private var micButton: UIButton!
    private var awarenessView: FloatingAwarenessPlanetView!
    
    // 约束
    private var containerLeadingConstraint: NSLayoutConstraint!
    private var containerTrailingConstraint: NSLayoutConstraint!
    private var containerBottomConstraint: NSLayoutConstraint!
    private var horizontalOffset: CGFloat = 0
    
    // 添加属性来保存键盘出现前的位置
    private var bottomSpaceBeforeKeyboard: CGFloat = 20
    // 新增：键盘可见状态与（已扣安全区的）当前键盘高度
    private var isKeyboardVisible: Bool = false
    private var currentKeyboardActualHeight: CGFloat = 0
    // 仅首轮：在 ChatOverlay 第一次收缩时，键盘可见情况下也要为浮窗预留空间
    private var didAdjustForFirstCollapse: Bool = false
    
    init(manager: InputDrawerManager) {
        self.manager = manager
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupKeyboardObservers()
        setupChatOverlayObservers()  // 新增：监听ChatOverlay状态
        
        // 关键：让view只处理输入框区域的触摸，其他区域透传
        view.backgroundColor = UIColor.clear
        
        // 重要：设置view不拦截触摸事件，让PassthroughView完全控制
        view.isUserInteractionEnabled = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // 在视图出现后设置触摸事件透传
        setupPassthroughView()
        
        // 发送初始位置通知，让ChatOverlay知道输入框的初始位置
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.notifyInputDrawerActualPosition()
        }
    }
    
    private func setupPassthroughView() {
        // 使用更简单的方式：PassthroughView作为背景层，不移动现有的containerView
        let passthroughView = PassthroughView()
        passthroughView.containerView = containerView
        passthroughView.backgroundColor = UIColor.clear
        
        // 将PassthroughView插入到view的最底层，不影响现有布局
        view.insertSubview(passthroughView, at: 0)
        passthroughView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            passthroughView.topAnchor.constraint(equalTo: view.topAnchor),
            passthroughView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            passthroughView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            passthroughView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        NSLog("🎯 InputDrawer: PassthroughView设置完成，保持原有布局")
    }
    
    private func setupUI() {
        // 确保背景透明，不阻挡其他UI
        view.backgroundColor = UIColor.clear
        
        // 创建主容器 - 匹配原版：圆角全包围，灰黑背景，边框
        containerView = UIView()
        containerView.backgroundColor = UIColor(red: 17/255.0, green: 24/255.0, blue: 39/255.0, alpha: 1.0) // bg-gray-900
        containerView.layer.cornerRadius = 24 // rounded-full for h-12
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor(red: 31/255.0, green: 41/255.0, blue: 55/255.0, alpha: 1.0).cgColor // border-gray-800
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        containerView.layer.shadowOpacity = 0.25
        containerView.layer.shadowRadius = 8
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        // 创建左侧觉察动画 - 精确匹配Web版FloatingAwarenessPlanet尺寸
        // Web版: <FloatingAwarenessPlanet className="w-8 h-8 ml-3 ... " /> (w-8 h-8 = 32x32px)
        awarenessView = FloatingAwarenessPlanetView()
        awarenessView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(awarenessView)
        
        // 创建输入框 - 匹配原版：透明背景，白色文字，灰色placeholder
        textField = UITextField()
        textField.placeholder = "询问任何问题" // 匹配原版placeholder
        textField.font = UIFont.systemFont(ofSize: 16)
        textField.borderStyle = .none
        textField.backgroundColor = UIColor.clear
        textField.textColor = UIColor.white
        textField.attributedPlaceholder = NSAttributedString(
            string: "询问任何问题",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor(white: 1.0, alpha: 0.4)]
        )
        textField.returnKeyType = .send
        textField.delegate = self
        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        textField.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(textField)
        
        // 创建发送按钮 - 使用SF Symbols paperplane图标
        sendButton = UIButton(type: .system)
        sendButton.backgroundColor = UIColor.clear
        sendButton.layer.cornerRadius = 16
        sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        sendButton.isEnabled = false
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        
        // 使用SF Symbols paperplane图标
        let paperplaneImage = UIImage(systemName: "paperplane.fill")
        sendButton.setImage(paperplaneImage, for: .normal)
        sendButton.tintColor = UIColor(white: 1.0, alpha: 0.3) // 默认灰色
        containerView.addSubview(sendButton)
        
        // 创建麦克风按钮 - 使用SF Symbols mic图标
        micButton = UIButton(type: .system)
        micButton.backgroundColor = UIColor.clear
        micButton.layer.cornerRadius = 16
        micButton.addTarget(self, action: #selector(micButtonTapped), for: .touchUpInside)
        micButton.translatesAutoresizingMaskIntoConstraints = false
        
        // 使用SF Symbols mic图标
        let micImage = UIImage(systemName: "mic.fill")
        micButton.setImage(micImage, for: .normal)
        micButton.tintColor = UIColor(white: 1.0, alpha: 0.6) // 匹配Web版颜色
        containerView.addSubview(micButton)
        
        // 设置约束 - 完全匹配原版：左侧觉察动画 + 输入框 + 右侧按钮组
        containerBottomConstraint = containerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -(manager?.bottomSpace ?? 20))
        horizontalOffset = manager?.horizontalOffset ?? 0
        containerLeadingConstraint = containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16 + horizontalOffset)
        containerTrailingConstraint = containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        
        NSLayoutConstraint.activate([
            // 容器约束 - 匹配原版h-12 = 48px高度
            containerLeadingConstraint,
            containerTrailingConstraint,
            containerView.heightAnchor.constraint(equalToConstant: 48), // h-12
            containerBottomConstraint,
            
            // 左侧觉察动画约束 - 精确匹配Web版w-8 h-8 ml-3 (32x32px, 12px左边距)
            awarenessView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12), // ml-3 = 12px
            awarenessView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            awarenessView.widthAnchor.constraint(equalToConstant: 32), // w-8 = 32px
            awarenessView.heightAnchor.constraint(equalToConstant: 32), // h-8 = 32px
            
            // 输入框约束 - 精确匹配Web版pl-2 pr-4的内边距
            textField.leadingAnchor.constraint(equalTo: awarenessView.trailingAnchor, constant: 8), // pl-2 = 8px
            textField.trailingAnchor.constraint(equalTo: micButton.leadingAnchor, constant: -16), // pr-4 = 16px
            textField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            
            // 麦克风按钮约束 - 匹配原版：space-x-2，圆形按钮 (p-2 = 8px padding)
            micButton.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8), // space-x-2
            micButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            micButton.widthAnchor.constraint(equalToConstant: 32), // 16px icon + 8px padding each side
            micButton.heightAnchor.constraint(equalToConstant: 32),
            
            // 发送按钮约束 - 匹配原版：mr-3，圆形按钮 (p-2 = 8px padding)
            sendButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12), // mr-3
            sendButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 36), // 20px icon + 8px padding each side
            sendButton.heightAnchor.constraint(equalToConstant: 36)
        ])
    }
    
    private func setupChatOverlayObservers() {
        // 🔧 只保留状态变化监听器，移除冗余的可见性监听器
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(chatOverlayStateChanged(_:)),
            name: Notification.Name("chatOverlayStateChanged"),
            object: nil
        )
        
        NSLog("🎯 InputDrawer: 开始监听ChatOverlay状态变化（已移除冗余的可见性监听器）")
    }
    
    @objc private func chatOverlayStateChanged(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let state = userInfo["state"] as? String else { return }
        
        // 🔧 新增：检查visible状态（如果有）
        let visible = userInfo["visible"] as? Bool ?? true
        
        NSLog("🎯 InputDrawer: 收到ChatOverlay统一状态通知 - state: \(state), visible: \(visible)")
        
        // 根据ChatOverlay状态调整输入框位置
        switch state {
        case "collapsed":
            if visible {
                // ChatOverlay收缩状态且可见：为浮窗预留空间
                let overlayReserve: CGFloat = 40
                if isKeyboardVisible && !didAdjustForFirstCollapse {
                    // 仅第一次：键盘可见时也在键盘之上额外预留 overlayReserve 空间
                    let target = -(currentKeyboardActualHeight + 16 + overlayReserve)
                    if abs(containerBottomConstraint.constant - target) > 0.5 {
                        containerBottomConstraint.constant = target
                        UIView.animate(withDuration: 0.26, delay: 0, options: [.allowUserInteraction, .curveEaseInOut, .beginFromCurrentState]) {
                            self.view.layoutIfNeeded()
                        } completion: { _ in
                            self.didAdjustForFirstCollapse = true
                            NSLog("🎯 InputDrawer: 首次收缩(键盘可见) 预留浮窗空间完成 bottom=\(target)")
                            self.notifyInputDrawerActualPosition()
                        }
                    }
                } else {
                    // 后续或键盘不可见：按原逻辑更新到 40
                    let newBottomSpace: CGFloat = overlayReserve
                    updateBottomSpace(newBottomSpace)
                    NSLog("🎯 InputDrawer: 移动到collapsed位置，bottomSpace: \(newBottomSpace)")
                }
            }
            
        case "expanded":
            if visible {
                // ChatOverlay展开状态：输入框回到原始位置
                let originalBottomSpace: CGFloat = 20
                updateBottomSpace(originalBottomSpace)
                NSLog("🎯 InputDrawer: 回到expanded位置，bottomSpace: \(originalBottomSpace)")
            }
            
        case "hidden":
            // ChatOverlay隐藏：输入框回到原始位置（无论 visible 值）
            let originalBottomSpace: CGFloat = 20
            updateBottomSpace(originalBottomSpace)
            NSLog("🎯 InputDrawer: 回到hidden位置，bottomSpace: \(originalBottomSpace)")
            
        default:
            // 未知状态，检查visible状态
            if !visible {
                let originalBottomSpace: CGFloat = 20
                updateBottomSpace(originalBottomSpace)
                NSLog("🎯 InputDrawer: 未知状态但不可见，回到原始位置")
            }
        }
    }
    
    // 🔧 已移除chatOverlayVisibilityChanged方法，避免重复动画
    // 现在只使用chatOverlayStateChanged来统一管理所有状态变化
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        NSLog("🎯 InputDrawer: 移除所有通知观察者")
    }
    
    // MARK: - Public Methods
    
    func updateText(_ text: String) {
        textField.text = text
        updateSendButtonState()
    }
    
    func updatePlaceholder(_ placeholder: String) {
        textField.placeholder = placeholder
    }
    
    func updateBottomSpace(_ space: CGFloat) {
        // 更新管理器中的bottomSpace值（键盘隐藏时会按此值恢复）
        let oldSpace = manager?.bottomSpace ?? 20
        manager?.bottomSpace = space

        // 若键盘可见：保持由键盘驱动的位置，避免覆盖（首个收缩场景关键修复）
        if isKeyboardVisible {
            NSLog("🎯 InputDrawer: 键盘可见，保持键盘位置，跳过覆盖 bottomSpace -> -\(currentKeyboardActualHeight) - 16")
            containerBottomConstraint.constant = -currentKeyboardActualHeight - 16
            self.view.layoutIfNeeded()
            // 首轮联动所需：广播当前实际位置，供浮窗对齐（不改变既有布局，仅发送事件）
            self.notifyInputDrawerActualPosition()
            return
        }

        // 键盘未显示：仅当变动显著时才更新
        if abs(oldSpace - space) < 1 {
            NSLog("🎯 InputDrawer: 位置未发生显著变化，跳过更新")
            return
        }

        // 使用与浮窗一致的轻量动画，营造柔和的推上推下效果
        containerBottomConstraint.constant = -space
        UIView.animate(
            withDuration: 0.26,
            delay: 0,
            options: [.allowUserInteraction, .curveEaseInOut, .beginFromCurrentState]
        ) {
            self.view.layoutIfNeeded()
        } completion: { _ in
            NSLog("🎯 InputDrawer: 位置更新完成（动画），bottomSpace: \(space)")
            // 通知ChatOverlay输入框的新位置
            self.notifyInputDrawerActualPosition()
        }
    }

    func updateHorizontalOffset(_ offset: CGFloat, animated: Bool) {
        let normalized = max(0, offset)
        if abs(horizontalOffset - normalized) < 0.5 {
            horizontalOffset = normalized
            return
        }
        horizontalOffset = normalized
        containerLeadingConstraint.constant = 16 + normalized
        containerTrailingConstraint.constant = -16 + normalized

        let updates = {
            self.view.layoutIfNeeded()
            self.notifyInputDrawerActualPosition()
        }

        if animated {
            UIView.animate(
                withDuration: 0.25,
                delay: 0,
                usingSpringWithDamping: 0.85,
                initialSpringVelocity: 0.3,
                options: [.allowUserInteraction, .beginFromCurrentState]
            ) {
                updates()
            }
        } else {
            updates()
        }
    }
    
    func focusInput() {
        textField.becomeFirstResponder()
    }
    
    func blurInput() {
        textField.resignFirstResponder()
    }
    
    // MARK: - Private Methods
    
    private func updateSendButtonState() {
        let hasText = !(textField.text?.isEmpty ?? true)
        sendButton.isEnabled = hasText
        
        // 更新发送按钮颜色 - 精确匹配Web版逻辑
        // Web版: 当有文字时变为cosmic-accent紫色，无文字时为白色半透明
        let cosmicAccentColor = UIColor(red: 168/255.0, green: 85/255.0, blue: 247/255.0, alpha: 1.0) // #a855f7
        let defaultColor = UIColor(white: 1.0, alpha: 0.3) // 匹配Web版默认白色半透明
        sendButton.tintColor = hasText ? cosmicAccentColor : defaultColor
    }
    
    @objc private func textFieldDidChange() {
        updateSendButtonState()
        manager?.handleTextChange(textField.text ?? "")
    }
    
    @objc private func sendButtonTapped() {
        guard let text = textField.text, !text.isEmpty else { return }
        
        manager?.handleTextSubmit(text)
        textField.text = ""
        updateSendButtonState()
    }
    
    @objc private func micButtonTapped() {
        NSLog("🎯 麦克风按钮被点击")
        // TODO: 集成语音识别功能
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        
        // 保存键盘出现前的位置
        bottomSpaceBeforeKeyboard = manager?.bottomSpace ?? 20
        NSLog("🎯 键盘即将显示，保存当前bottomSpace: \(bottomSpaceBeforeKeyboard)")
        
        let keyboardHeight = keyboardFrame.height
        // 获取安全区底部高度
        let safeAreaBottom = view.safeAreaInsets.bottom
        
        // 计算输入框应该在键盘上方的位置
        // 键盘高度包含了安全区，所以要减去安全区高度避免重复计算
        let actualKeyboardHeight = keyboardHeight - safeAreaBottom
        currentKeyboardActualHeight = actualKeyboardHeight
        isKeyboardVisible = true
        containerBottomConstraint.constant = -actualKeyboardHeight - 16
        
        NSLog("🎯 键盘高度: \(keyboardHeight), 安全区: \(safeAreaBottom), 实际键盘高度: \(actualKeyboardHeight)")
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        } completion: { _ in
            // 动画完成后，通知ChatOverlay输入框的新位置
            self.notifyInputDrawerActualPosition()
        }
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        // 恢复到键盘出现前的位置
        isKeyboardVisible = false
        containerBottomConstraint.constant = -bottomSpaceBeforeKeyboard
        NSLog("🎯 键盘即将隐藏，恢复到位置: \(bottomSpaceBeforeKeyboard)")
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        } completion: { _ in
            // 动画完成后，通知ChatOverlay输入框的新位置
            self.notifyInputDrawerActualPosition()
        }
    }
    
    // MARK: - 通知ChatOverlay输入框的实际屏幕位置
    private func notifyInputDrawerActualPosition() {
        // 计算输入框底部在屏幕中的实际Y坐标
        let containerFrame = containerView.frame
        let containerBottom = containerFrame.maxY
        let screenHeight = UIScreen.main.bounds.height
        
        // 计算输入框底部距离屏幕底部的实际距离
        let actualBottomSpaceFromScreen = screenHeight - containerBottom
        
        NSLog("🎯 InputDrawer实际位置 - 容器底部Y: \(containerBottom), 屏幕高度: \(screenHeight), 实际底部距离: \(actualBottomSpaceFromScreen)")
        
        // 记录最新的实际位置，供 ChatOverlay 初次出现时立即读取
        InputDrawerState.shared.latestActualBottomSpace = actualBottomSpaceFromScreen

        // 去通知化：不再通过全局通知广播，改由协议回调（InputDrawerPositionObservable）
        NSLog("🎯 InputDrawer: 已更新实际位置 actualBottomSpace=\(actualBottomSpaceFromScreen)")
    }
}

// MARK: - 输入框共享状态（供 ChatOverlay 初次出现时立即对齐）
@MainActor
final class InputDrawerState: InputDrawerPositionObservable {
    static let shared = InputDrawerState()
    private init() {}

    // 位置变化回调（供协调者使用）
    var onBottomSpaceChanged: ((CGFloat) -> Void)?

    // 兼容旧字段（保持与已有调用的一致性）
    var latestActualBottomSpace: CGFloat = 70 {
        didSet {
            // 同步到新协议字段并回调
            latestBottomSpace = latestActualBottomSpace
        }
    }

    // 协议所需字段：屏幕底部到输入框底部的实际距离（px）
    var latestBottomSpace: CGFloat = 70 {
        didSet { onBottomSpaceChanged?(latestBottomSpace) }
    }
}

// MARK: - PassthroughView - 处理触摸事件透传的自定义View
class PassthroughView: UIView {
    weak var containerView: UIView?
    
    // 重写这个方法来决定是否拦截触摸事件
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        NSLog("🎯 InputDrawer PassthroughView hitTest: \(point)")
        
        // 首先让父类正常处理触摸测试
        let hitView = super.hitTest(point, with: event)
        
        // 如果触摸点不在containerView区域内，返回nil让事件透传
        guard let containerView = containerView else {
            NSLog("🎯 无containerView，返回hitView: \(String(describing: hitView))")
            return hitView
        }
        
        // 将点转换到containerView的坐标系
        let convertedPoint = convert(point, to: containerView)
        let containerBounds = containerView.bounds
        
        NSLog("🎯 转换后坐标: \(convertedPoint), 容器边界: \(containerBounds)")
        
        // 如果触摸点在containerView的边界内，正常返回hitView
        if containerBounds.contains(convertedPoint) {
            NSLog("🎯 触摸在输入框容器内，返回hitView: \(String(describing: hitView))")
            return hitView
        } else {
            NSLog("🎯 触摸在输入框容器外，返回nil透传事件")
            // 触摸点在containerView外部，返回nil透传给下层
            return nil
        }
    }
}

// MARK: - UITextFieldDelegate
extension InputViewController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        manager?.handleFocus()
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        manager?.handleBlur()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let text = textField.text, !text.isEmpty else { return false }
        
        sendButtonTapped()
        return true
    }
}

// MARK: - FloatingAwarenessPlanetView - 完全匹配原版动画效果
class FloatingAwarenessPlanetView: UIView {
    private var centerDot: CAShapeLayer!
    private var rayLayers: [CAShapeLayer] = []
    private var isAnimating = false
    private var level: String = "medium" // none, low, medium, high
    private var isAnalyzing = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = UIColor.clear
        
        // 创建中心圆点（跟Web版一样）
        centerDot = CAShapeLayer()
        let centerPath = UIBezierPath(ovalIn: CGRect(x: 14.5, y: 14.5, width: 3, height: 3)) // r=1.5, centered at 16,16
        centerDot.path = centerPath.cgPath
        centerDot.fillColor = getStarColor().cgColor
        layer.addSublayer(centerDot)
        
        // 创建12条射线
        for i in 0..<12 {
            let rayLayer = CAShapeLayer()
            let angle = Double(i) * Double.pi * 2.0 / 12.0
            
            // 随机长度和粗细（匹配原版算法）
            let seedRandom = { (seed: Double) -> Double in
                let x = sin(seed) * 10000
                return x - floor(x)
            }
            let length = 5 + seedRandom(Double(i)) * 8 // 缩小长度适应32px容器
            let strokeWidth = seedRandom(Double(i + 12)) * 1.2 + 0.3
            
            let startX = 16.0
            let startY = 16.0
            let endX = startX + cos(angle) * length
            let endY = startY + sin(angle) * length
            
            let rayPath = UIBezierPath()
            rayPath.move(to: CGPoint(x: startX, y: startY))
            rayPath.addLine(to: CGPoint(x: endX, y: endY))
            
            rayLayer.path = rayPath.cgPath
            rayLayer.strokeColor = getStarColor().cgColor
            rayLayer.lineWidth = CGFloat(strokeWidth)
            rayLayer.lineCap = .round
            rayLayer.strokeStart = 0
            rayLayer.strokeEnd = 0.2 // 初始状态
            rayLayer.opacity = 0.2
            
            layer.addSublayer(rayLayer)
            rayLayers.append(rayLayer)
        }
        
        startAnimation()
    }
    
    private func getStarColor() -> UIColor {
        if isAnalyzing {
            return UIColor(red: 138/255.0, green: 95/255.0, blue: 189/255.0, alpha: 1.0) // #8A5FBD
        }
        
        let progress: Double = 
            level == "none" ? 0 :
            level == "low" ? 0.33 :
            level == "medium" ? 0.66 :
            level == "high" ? 1 : 0.66 // 默认medium
        
        // 从灰色到紫色的渐变
        let gray = (r: 136.0, g: 136.0, b: 136.0)
        let purple = (r: 138.0, g: 95.0, b: 189.0)
        
        let r = gray.r + (purple.r - gray.r) * progress
        let g = gray.g + (purple.g - gray.g) * progress
        let b = gray.b + (purple.b - gray.b) * progress
        
        return UIColor(red: r/255.0, green: g/255.0, blue: b/255.0, alpha: 1.0)
    }
    
    private func startAnimation() {
        guard !isAnimating else { return }
        isAnimating = true
        
        // 中心圆点动画（匹配Web版）
        let centerScaleAnimation = CAKeyframeAnimation(keyPath: "transform.scale")
        centerScaleAnimation.values = [1.0, 1.2, 1.0]
        centerScaleAnimation.keyTimes = [0.0, 0.5, 1.0]
        centerScaleAnimation.duration = 2.0
        centerScaleAnimation.repeatCount = .infinity
        
        let centerOpacityAnimation = CAKeyframeAnimation(keyPath: "opacity")
        centerOpacityAnimation.values = [0.8, 1.0, 0.8]
        centerOpacityAnimation.keyTimes = [0.0, 0.5, 1.0]
        centerOpacityAnimation.duration = 2.0
        centerOpacityAnimation.repeatCount = .infinity
        
        centerDot.add(centerScaleAnimation, forKey: "scale")
        centerDot.add(centerOpacityAnimation, forKey: "opacity")
        
        // 射线动画
        for (i, rayLayer) in rayLayers.enumerated() {
            let strokeAnimation = CAKeyframeAnimation(keyPath: "strokeEnd")
            strokeAnimation.values = [0.0, 1.0, 0.0]
            strokeAnimation.keyTimes = [0.0, 0.5, 1.0]
            strokeAnimation.duration = 2.0 + Double(i) * 0.1 // 轻微的延迟差异
            strokeAnimation.repeatCount = .infinity
            strokeAnimation.beginTime = CACurrentMediaTime() + Double(i) * 0.05
            
            let opacityAnimation = CAKeyframeAnimation(keyPath: "opacity")
            opacityAnimation.values = [0.0, 0.7, 0.0]
            opacityAnimation.keyTimes = [0.0, 0.5, 1.0]
            opacityAnimation.duration = 2.0 + Double(i) * 0.1
            opacityAnimation.repeatCount = .infinity
            opacityAnimation.beginTime = CACurrentMediaTime() + Double(i) * 0.05
            
            rayLayer.add(strokeAnimation, forKey: "strokeEnd")
            rayLayer.add(opacityAnimation, forKey: "opacity")
        }
    }
}

```

`StarO/InspirationCardOverlay.swift`:

```swift
import SwiftUI
import StarOracleCore
import StarOracleFeatures

struct InspirationCardOverlay: View {
    @EnvironmentObject var starStore: StarStore
    @State private var isFlipped = false
    @State private var isAppearing = false
    @State private var dragOffset: CGSize = .zero
    @State private var isClosing = false
    
    // Card dimensions matching React (~280x400)
    private let cardWidth: CGFloat = 300
    private let cardHeight: CGFloat = 440
    
    var body: some View {
        if let card = starStore.currentInspirationCard {
            ZStack {
                // Dimmed background
                Color.black.opacity(isClosing ? 0 : 0.6)
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismiss(id: card.id)
                    }
                    .animation(.easeOut(duration: 0.3), value: isClosing)
                
                // Card Container
                ZStack {
                    // Front Face
                    CardFrontFace(card: card, onFlip: {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            isFlipped = true
                        }
                    })
                        .opacity(isFlipped ? 0 : 1)
                        .rotation3DEffect(
                            .degrees(isFlipped ? 180 : 0),
                            axis: (x: 0.0, y: 1.0, z: 0.0),
                            perspective: 0.8
                        )
                        .accessibilityHidden(isFlipped)
                    
                    // Back Face
                    CardBackFace(card: card, onFlipBack: {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            isFlipped = false
                        }
                    }, onSubmit: { question in
                        submit(card: card, question: question)
                    })
                    .opacity(isFlipped ? 1 : 0)
                    .rotation3DEffect(
                        .degrees(isFlipped ? 0 : -180),
                        axis: (x: 0.0, y: 1.0, z: 0.0),
                        perspective: 0.8
                    )
                    .accessibilityHidden(!isFlipped)
                }
                .frame(width: cardWidth, height: cardHeight)
                .offset(dragOffset)
                .rotationEffect(.degrees(Double(dragOffset.width / 15)))
                .scaleEffect(isClosing ? 0.8 : (isAppearing ? 1 : 0.9))
                .opacity(isClosing ? 0 : (isAppearing ? 1 : 0))
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            dragOffset = value.translation
                        }
                        .onEnded { value in
                            let threshold: CGFloat = 100
                            if abs(value.translation.width) > threshold || abs(value.velocity.width) > 500 {
                                dismiss(id: card.id, velocity: value.velocity)
                            } else {
                                withAnimation(.spring()) {
                                    dragOffset = .zero
                                }
                            }
                        }
                )
            }
            .zIndex(100)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
                    isAppearing = true
                }
            }
        }
    }
    
    private func dismiss(id: String, velocity: CGSize = .zero) {
        withAnimation(.easeIn(duration: 0.25)) {
            isClosing = true
            if velocity != .zero {
                dragOffset.width += velocity.width * 0.2
                dragOffset.height += velocity.height * 0.2
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            starStore.dismissInspirationCard(id: id)
            // Reset state for next time
            isFlipped = false
            isAppearing = false
            isClosing = false
            dragOffset = .zero
        }
    }
    
    private func submit(card: InspirationCard, question: String) {
        let finalQuestion = question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? card.question : question
        
        // Animate out
        withAnimation(.easeIn(duration: 0.2)) {
            isClosing = true
            dragOffset.height = -200.0
            dragOffset.width = 0.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            Task {
                try? await starStore.addStar(question: finalQuestion, at: nil)
                starStore.dismissInspirationCard(id: card.id)
                // Reset
                isFlipped = false
                isAppearing = false
                isClosing = false
                dragOffset = .zero
            }
        }
    }
}

// MARK: - Front Face
struct CardFrontFace: View {
    let card: InspirationCard
    var onFlip: () -> Void
    @State private var animateStars = false
    
    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(
                colors: [
                    Color(hex: "#4a1c6a"),
                    Color(hex: "#2a0f46")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Star Pattern
            GeometryReader { proxy in
                let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
                
                // Background Stars
                ForEach(0..<12) { i in
                    Circle()
                        .fill(Color.white.opacity(0.6))
                        .frame(width: CGFloat.random(in: 2...4))
                        .position(
                            x: center.x + CGFloat.random(in: -80...80),
                            y: center.y + CGFloat.random(in: -100...100)
                        )
                        .opacity(animateStars ? 0.8 : 0.3)
                        .animation(
                            .easeInOut(duration: Double.random(in: 1.5...3.0))
                            .repeatForever(autoreverses: true)
                            .delay(Double.random(in: 0...2)),
                            value: animateStars
                        )
                }
                
                // Main Star
                Circle()
                    .fill(Color.white)
                    .frame(width: 16, height: 16)
                    .position(center)
                    .shadow(color: .white, radius: 10)
                    .scaleEffect(animateStars ? 1.1 : 0.9)
                    .animation(.easeInOut(duration: 2).repeatForever(), value: animateStars)
                
                // Rays
                ForEach(0..<8) { i in
                    Rectangle()
                        .fill(LinearGradient(colors: [.white, .clear], startPoint: .leading, endPoint: .trailing))
                        .frame(width: 40, height: 2)
                        .offset(x: 20)
                        .rotationEffect(.degrees(Double(i) * 45))
                        .position(center)
                        .opacity(animateStars ? 0.8 : 0.2)
                        .animation(
                            .easeInOut(duration: 1.5).repeatForever().delay(Double(i) * 0.1),
                            value: animateStars
                        )
                }
            }
            
            // Prompt Text
            VStack {
                Spacer()
                Text("翻开卡片，宇宙会回答你")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.bottom, 40)
            }
        }
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.25), lineWidth: 1)
        )
        .shadow(color: Color(hex: "#4a1c6a").opacity(0.5), radius: 20, x: 0, y: 10)
        .onAppear {
            animateStars = true
        }
        .contentShape(Rectangle()) // Ensure entire area is tappable
        .onTapGesture {
            onFlip()
        }
    }
}

// MARK: - Back Face
struct CardBackFace: View {
    let card: InspirationCard
    let onFlipBack: () -> Void
    let onSubmit: (String) -> Void
    
    @State private var inputText = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ZStack {
            // Background
            Color(hex: "#1A1A2E")
            
            VStack {
                // Header
                HStack {
                    Text("来自宇宙的答案")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color(hex: "#8A5FBD"))
                    
                    Spacer()
                    
                    Button(action: onFlipBack) {
                        Text("返回正面")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.8))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    }
                }
                .padding(.top, 24)
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Answer
                Text(card.reflection) // Using reflection as the main answer for now, or card.answer if available
                    .font(.system(size: 24, weight: .bold, design: .serif))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .shadow(color: .white.opacity(0.3), radius: 8)
                
                Spacer()
                
                // Reflection/Footer
                Text(card.question) // Using question as the reflection/footer
                    .font(.system(size: 12, design: .serif))
                    .italic()
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                
                // Input Area
                HStack(spacing: 12) {
                    TextField("说说你的困惑吧", text: $inputText)
                        .font(.system(size: 14))
                        .foregroundStyle(.white)
                        .tint(Color(hex: "#5AE7FF"))
                        .focused($isFocused)
                        .submitLabel(.send)
                        .onSubmit {
                            onSubmit(inputText)
                        }
                    
                    Button(action: { onSubmit(inputText) }) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14))
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(inputText.isEmpty ? Color.white.opacity(0.1) : Color(hex: "#8A5FBD"))
                            )
                    }
                    .disabled(inputText.isEmpty)
                }
                .padding(12)
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        // Removed internal rotation to fix mirrored text
        // .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
        .contentShape(Rectangle())
        .onTapGesture {
            onFlipBack()
        }
    }
}

// Helper for Hex Color
// Helper for Hex Color
// Removed duplicate extension, now using shared Color+Hex.swift

```

`StarO/InspirationSheet.swift`:

```swift
import SwiftUI
import StarOracleCore
import StarOracleFeatures

struct InspirationSheet: View {
  @EnvironmentObject private var starStore: StarStore
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      List {
        Section {
          Button {
            _ = starStore.drawInspirationCard(region: nil)
          } label: {
            Label("抽取灵感卡", systemImage: "moon.stars")
          }
        }

        Section("筛选") {
          Picker("类别", selection: $selectedCategory) {
            Text("全部").tag("all")
            Text("情绪").tag("emotion")
            Text("关系").tag("relation")
            Text("成长").tag("growth")
          }
          .pickerStyle(.segmented)
        }

        Section("灵感记录") {
          if filteredStars.isEmpty {
            Text("暂无灵感卡记录")
              .foregroundStyle(.secondary)
          } else {
            ForEach(filteredStars) { star in
              VStack(alignment: .leading, spacing: 6) {
                Text(star.question)
                  .font(.subheadline)
                Text(star.answer)
                  .font(.caption)
                  .foregroundStyle(.secondary)
                HStack {
                  Button("用此灵感提问") {
                    Task { try? await starStore.addStar(question: star.question, at: nil) }
                  }
                  Button("详情") {
                    activeStar = star
                  }
                }
                .font(.caption)
              }
              .padding(.vertical, 4)
            }
          }
        }
      }
      .navigationTitle("灵感卡")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("关闭") { dismiss() }
        }
      }
      .sheet(item: $activeStar) { star in
        StarDetailSheet(star: star) { activeStar = nil }
      }
    }
  }

  @State private var selectedCategory: String = "all"
  @State private var activeStar: Star?

  private var filteredStars: [Star] {
    let all = Array(starStore.inspirationStars.reversed())
    switch selectedCategory {
    case "emotion":
      return all.filter { $0.primaryCategory == "emotional_wellbeing" }
    case "relation":
      return all.filter { $0.primaryCategory == "relationships" }
    case "growth":
      return all.filter { $0.primaryCategory == "personal_growth" || $0.primaryCategory == "career_and_purpose" }
    default:
      return all
    }
  }
}

```

`StarO/KeyboardObserver.swift`:

```swift
import Combine
import SwiftUI

#if os(iOS)
import UIKit

@MainActor
final class KeyboardObserver: ObservableObject {
  static let shared = KeyboardObserver()
  @Published var keyboardHeight: CGFloat = 0 {
    willSet { logStateChange("keyboardHeight -> \(newValue)") }
  }
  private var cancellables = Set<AnyCancellable>()

  private init() {
    NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)
      .merge(with: NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification))
      .sink { [weak self] notification in
        guard let self else { return }
        if notification.name == UIResponder.keyboardWillHideNotification {
          keyboardHeight = 0
          return
        }
        if let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
          keyboardHeight = frame.height
        }
      }
      .store(in: &cancellables)
  }
}

private extension KeyboardObserver {
  func logStateChange(_ label: String) {
    NSLog("⚠️ KeyboardObserver mutate \(label) | stack:\n\(Thread.callStackSymbols.joined(separator: "\n"))")
  }
}
#endif

```

`StarO/LayoutCapabilities.swift`:

```swift
import UIKit

// MARK: - 能力协议：根据输入框位置调整聊天视口布局，避免气泡被遮挡
@MainActor
protocol InputOverlayAvoidingLayout: AnyObject {
    /// 输入：屏幕底部到输入框底部的实际距离（px）
    func updateLayoutForInputDrawer(bottomSpaceFromScreen: CGFloat)
}

// MARK: - 位置可观测源协议：提供最新的输入框位置，并在变化时回调
@MainActor
protocol InputDrawerPositionObservable: AnyObject {
    var latestBottomSpace: CGFloat { get }
    var onBottomSpaceChanged: ((CGFloat) -> Void)? { get set }
}

// MARK: - 协调者：把输入框位置变化派发给布局能力
@MainActor
final class InputDrawerLayoutCoordinator {
    private weak var layout: InputOverlayAvoidingLayout?
    private weak var observable: InputDrawerPositionObservable?

    init(layout: InputOverlayAvoidingLayout, observable: InputDrawerPositionObservable) {
        self.layout = layout
        self.observable = observable
        // 监听位置变化并派发（本类与 observable 均在 MainActor 上）
        observable.onBottomSpaceChanged = { [weak self] bottom in
            guard let self, let layout = self.layout else { return }
            layout.updateLayoutForInputDrawer(bottomSpaceFromScreen: bottom)
        }
    }

    /// 首次出现/状态切换后，强制同步一次，保证“永不遮挡”强规则
    @MainActor
    func syncInitialLayout() {
        guard let layout = layout, let observable = observable else { return }
        layout.updateLayoutForInputDrawer(bottomSpaceFromScreen: observable.latestBottomSpace)
    }
}

```

`StarO/NativeChatBridge.swift`:

```swift
import Foundation
import Combine
import SwiftUI
import UIKit
import StarOracleCore
import StarOracleFeatures
import StarOracleServices

extension ObservableObjectPublisher: @unchecked Sendable {}

@MainActor
final class NativeChatBridge: NSObject, ObservableObject {
  enum PresentationState {
    case hidden
    case collapsed
    case expanded
  }

  nonisolated let objectWillChange = ObservableObjectPublisher()
  private var presentationStateStorage: PresentationState = .hidden
  var presentationState: PresentationState { presentationStateStorage }
  private(set) var isInputDrawerVisible = false
  private var lastErrorMessageStorage: String?
  var lastErrorMessage: String? { lastErrorMessageStorage }

  private let overlayManager = ChatOverlayManager()
  private let inputManager = InputDrawerManager()
  private let chatStore: ChatStore
  private let conversationStore: ConversationStore
  private let aiService: AIServiceProtocol
  private let preferenceService: PreferenceServiceProtocol
  private var cancellables = Set<AnyCancellable>()
  private var streamingTask: Task<Void, Never>?
  private var didActivate = false
  private weak var windowScene: UIWindowScene?
  private weak var registeredBackgroundView: UIView?
  private var pendingEnsureWorkItem: DispatchWorkItem?
  private var pendingPresentationStateWorkItem: DispatchWorkItem?

  init(
    chatStore: ChatStore,
    conversationStore: ConversationStore,
    aiService: AIServiceProtocol,
    preferenceService: PreferenceServiceProtocol
  ) {
    self.chatStore = chatStore
    self.conversationStore = conversationStore
    self.aiService = aiService
    self.preferenceService = preferenceService
    super.init()
    inputManager.delegate = self
    observeChatStore()
    observeOverlayNotifications()
    bootstrapSystemPromptIfNeeded()
  }

  deinit {
    streamingTask?.cancel()
  }

  func activateIfNeeded() {
    guard !didActivate else {
      ensureInputDrawerVisible()
      configureBackgroundViewIfNeeded()
      return
    }
    didActivate = true
    configureBackgroundViewIfNeeded()
    ensureInputDrawerVisible()
    overlayManager.setConversationTitle(chatStore.conversationTitle)
    overlayManager.updateMessages(chatStore.messages.map(makeOverlayMessage))
  }

  private var pendingInputVisibleWork: DispatchWorkItem?

  func ensureInputDrawerVisible() {
    NSLog("🎯 NativeChatBridge.ensureInputDrawerVisible")
    pendingInputVisibleWork?.cancel()
    let work = DispatchWorkItem { [weak self] in
      guard let self else { return }
      self.inputManager.show(animated: true) { [weak self] success in
        guard let self else { return }
        if success, self.isInputDrawerVisible != true {
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
            self.setInputDrawerVisible(true)
          }
        }
      }
    }
    pendingInputVisibleWork = work
    DispatchQueue.main.async(execute: work)
  }

  func hideInputDrawer() {
    inputManager.hide(animated: true) { [weak self] in
      DispatchQueue.main.async { [weak self] in
        guard let self else { return }
        if self.isInputDrawerVisible == true {
          self.setInputDrawerVisible(false)
        }
      }
    }
  }

  func toggleOverlay(expanded: Bool = true) {
    NSLog("🎯 NativeChatBridge.toggleOverlay expanded=\(expanded) state=\(presentationState)")
    switch presentationState {
    case .hidden:
      openOverlay(expanded: expanded)
    case .collapsed:
      if expanded {
        openOverlay(expanded: true)
      } else {
        hideOverlay()
      }
    case .expanded:
      hideOverlay()
    }
  }

  func openOverlay(expanded: Bool) {
    NSLog("🎯 NativeChatBridge.openOverlay expanded=\(expanded)")
    overlayManager.show(animated: true, expanded: expanded) { [weak self] success in
      guard let self, success else { return }
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) { [weak self] in
        self?.updatePresentationState(expanded ? .expanded : .collapsed)
      }
    }
  }

  func hideOverlay() {
    NSLog("🎯 NativeChatBridge.hideOverlay")
    overlayManager.hide(animated: true) { [weak self] in
      DispatchQueue.main.async { [weak self] in
        self?.updatePresentationState(.hidden)
      }
    }
  }

  func ensureOverlayVisible(collapsed: Bool = true) {
    NSLog("🎯 NativeChatBridge.ensureOverlayVisible collapsed=\(collapsed) current=\(presentationState)")
    pendingEnsureWorkItem?.cancel()
    let work = DispatchWorkItem { [weak self] in
      self?.performEnsureOverlayVisible(collapsed: collapsed)
    }
    pendingEnsureWorkItem = work
    DispatchQueue.main.async(execute: work)
  }

  private func performEnsureOverlayVisible(collapsed: Bool) {
    switch presentationState {
    case .hidden:
      openOverlay(expanded: !collapsed)
    case .collapsed:
      if !collapsed {
        openOverlay(expanded: true)
      }
    case .expanded:
      if collapsed {
        openOverlay(expanded: false)
      }
    }
  }

  func setHorizontalOffset(_ offset: CGFloat, animated: Bool = true) {
    inputManager.setHorizontalOffset(offset, animated: animated)
    overlayManager.setHorizontalOffset(offset, animated: animated)
  }

  func sendMessage(_ text: String) {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    NSLog("🎯 NativeChatBridge.sendMessage text=\(trimmed)")
    if presentationState == .hidden {
      openOverlay(expanded: true)
    }
    chatStore.addUserMessage(trimmed)
    inputManager.setText("")
    setLastErrorMessage(nil)
    startStreaming(for: trimmed)
  }

  private func startStreaming(for question: String) {
    streamingTask?.cancel()
    streamingTask = Task { [weak self] in
      guard let self else { return }
      await self.performStreaming(for: question)
    }
  }

  private func performStreaming(for question: String) async {
    chatStore.setLoading(true)
    overlayManager.setLoading(true)
    let history = chatStore.messages
    let systemPrompt = conversationStore.currentSession()?.systemPrompt ?? ""
    if systemPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      NSLog("ℹ️ NativeChatBridge.performStreaming | 当前会话系统提示为空")
    } else {
      NSLog("🎯 NativeChatBridge.performStreaming | systemPrompt 前30字: %@...", String(systemPrompt.prefix(30)))
    }
    guard let configuration = await preferenceService.loadAIConfiguration() else {
      NSLog("⚠️ NativeChatBridge.performStreaming | 未找到 AI 配置")
      chatStore.setLoading(false)
      overlayManager.setLoading(false)
      setLastErrorMessage("尚未配置 AI 接口，请先在设置中填写。")
      return
    }
    NSLog("🎯 NativeChatBridge.performStreaming | provider=%@ model=%@ endpoint=%@", configuration.provider, configuration.model, configuration.endpoint.absoluteString)
    let messageId = chatStore.beginStreamingAIMessage(initial: "")
    var buffer = ""
    let stream = aiService.streamResponse(
      for: question,
      configuration: configuration,
      context: AIRequestContext(
        history: history,
        metadata: systemPrompt.isEmpty ? [:] : ["systemPrompt": systemPrompt]
      )
    )

    do {
      for try await chunk in stream {
        buffer.append(chunk)
        NSLog("✉️ NativeChatBridge.chunk | len=%d", chunk.count)
        chatStore.updateStreamingMessage(id: messageId, text: buffer)
      }
      NSLog("✅ NativeChatBridge.performStreaming | 完成")
      chatStore.finalizeStreamingMessage(id: messageId)
      chatStore.setLoading(false)
      overlayManager.setLoading(false)
      try? await chatStore.generateConversationTitle()
      setLastErrorMessage(nil)
    } catch {
      NSLog("❌ NativeChatBridge.performStreaming | error=%@", error.localizedDescription)
      chatStore.updateStreamingMessage(id: messageId, text: "未能获取星语回应，请稍后再试。")
      chatStore.finalizeStreamingMessage(id: messageId)
      chatStore.setLoading(false)
      overlayManager.setLoading(false)
      setLastErrorMessage("发送失败：\(error.localizedDescription)")
    }
  }

  private func observeChatStore() {
    chatStore.$messages
      .removeDuplicates()
      .receive(on: DispatchQueue.main)
      .sink { [weak self] messages in
        guard let self else { return }
        let overlayMessages = messages.map(self.makeOverlayMessage)
        self.overlayManager.updateMessages(overlayMessages)
      }
      .store(in: &cancellables)

    chatStore.$isLoading
      .receive(on: DispatchQueue.main)
      .sink { [weak self] loading in
        self?.overlayManager.setLoading(loading)
      }
      .store(in: &cancellables)

    chatStore.$conversationTitle
      .receive(on: DispatchQueue.main)
      .sink { [weak self] title in
        self?.overlayManager.setConversationTitle(title)
      }
      .store(in: &cancellables)
  }

  private func observeOverlayNotifications() {
    NotificationCenter.default.publisher(for: .chatOverlayStateChanged)
      .receive(on: DispatchQueue.main)
      .sink { [weak self] notification in
        guard let self else { return }
        guard let stateValue = notification.userInfo?["state"] as? String else { return }
        DispatchQueue.main.async {
          switch stateValue {
          case "expanded":
            self.updatePresentationState(.expanded)
          case "collapsed":
            self.updatePresentationState(.collapsed)
          case "hidden":
            self.updatePresentationState(.hidden)
          default:
            break
          }
        }
      }
      .store(in: &cancellables)
  }

  private func makeOverlayMessage(_ message: StarOracleCore.ChatMessage) -> OverlayChatMessage {
    OverlayChatMessage(
      id: message.id,
      text: message.text,
      isUser: message.isUser,
      timestamp: message.timestamp.timeIntervalSince1970 * 1000
    )
  }

  private func updatePresentationState(_ newState: PresentationState) {
    guard presentationState != newState else { return }
    pendingPresentationStateWorkItem?.cancel()
    let workItem = DispatchWorkItem { [weak self] in
      guard let self else { return }
      NSLog("🎯 presentationState commit -> \(newState)")
      self.pendingPresentationStateWorkItem = nil
      self.setPresentationStateValue(newState)
    }
    NSLog("🎯 schedule presentationState -> \(newState) | stack:\n\(Thread.callStackSymbols.joined(separator: "\n"))")
    pendingPresentationStateWorkItem = workItem
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.03, execute: workItem)
  }
  
  private func setPresentationStateValue(_ newState: PresentationState) {
    guard presentationStateStorage != newState else { return }
    publishBridgeChange("presentationState -> \(newState)")
    presentationStateStorage = newState
  }

  private func setLastErrorMessage(_ newValue: String?) {
    guard lastErrorMessageStorage != newValue else { return }
    publishBridgeChange("lastErrorMessage changed")
    lastErrorMessageStorage = newValue
  }
  
  private func setInputDrawerVisible(_ visible: Bool) {
    guard isInputDrawerVisible != visible else { return }
    publishBridgeChange("isInputDrawerVisible -> \(visible)")
    isInputDrawerVisible = visible
  }

  private func publishBridgeChange(_ label: String) {
    NSLog("⚠️ NativeChatBridge 即将 publish (\(label)) | stack:\n\(Thread.callStackSymbols.joined(separator: "\n"))")
    objectWillChange.send()
  }

  func attach(to scene: UIWindowScene) {
    // 若已绑定同一 scene，避免重复 rebind 造成窗口闪烁
    let isSameScene = windowScene === scene
    let isNewScene = windowScene !== scene
    windowScene = scene
    overlayManager.attach(to: scene)
    inputManager.attach(to: scene)
    if isNewScene {
      registeredBackgroundView = nil
    }
    // 已绑定且背景视图有效则无需重复配置
    if isSameScene, let view = registeredBackgroundView, view.window != nil {
      return
    }
    configureBackgroundViewIfNeeded()
  }

  private func registerBackgroundView(_ view: UIView) {
    overlayManager.setBackgroundView(view)
    registeredBackgroundView = view
  }

  private func configureBackgroundViewIfNeeded() {
    if let view = registeredBackgroundView, view.window != nil {
      return
    }
    let candidateScene = windowScene ?? UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .first { $0.activationState == .foregroundActive || $0.activationState == .foregroundInactive }
    guard let scene = candidateScene,
          let window = scene.windows.first(where: { $0.isKeyWindow }) ?? scene.windows.first,
          let rootView = window.rootViewController?.view else {
      return
    }
    registerBackgroundView(rootView)
  }

  private func bootstrapSystemPromptIfNeeded() {
    conversationStore.bootstrapIfNeeded()
    guard let session = conversationStore.currentSession() else {
      NSLog("ℹ️ NativeChatBridge | 无可用会话，无法写入系统提示")
      return
    }
    let prompt = session.systemPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
    guard prompt.isEmpty else { return }
    NSLog("ℹ️ NativeChatBridge | 会话无系统提示，写入默认 prompt")
    conversationStore.setSystemPrompt(SystemPrompt.defaultPrompt, sessionId: session.id)
  }
}

extension NativeChatBridge: InputDrawerDelegate {
  nonisolated func inputDrawerDidSubmit(_ text: String) {
    NSLog("🎯 NativeChatBridge.inputDrawerDidSubmit text=\(text)")
    Task { @MainActor [weak self] in
      self?.sendMessage(text)
    }
  }

  nonisolated func inputDrawerDidChange(_ text: String) {
    NSLog("🎯 NativeChatBridge.inputDrawerDidChange text=\(text)")
  }

  nonisolated func inputDrawerDidFocus() {
    NSLog("🎯 NativeChatBridge.inputDrawerDidFocus")
  }

  nonisolated func inputDrawerDidBlur() {}
}

```

`StarO/PixelPlanets/Core/Palettes.swift`:

```swift
import Foundation

public func randRange(_ rng: inout RandomStream, min: Float, max: Float) -> Float {
    rng.nextRange(min: min, max: max)
}

public func randInt(_ rng: inout RandomStream, maxExclusive: Int) -> Int {
    rng.nextInt(maxExclusive)
}

public func generatePalette(
    rng: inout RandomStream,
    count: Int,
    hueDiff: Float = 0.9,
    saturation: Float = 0.5
) -> [PixelColor] {
    let a: [Float] = [0.5, 0.5, 0.5]
    let b = a.map { $0 * saturation }
    let c = [
        randRange(&rng, min: 0.5, max: 1.5),
        randRange(&rng, min: 0.5, max: 1.5),
        randRange(&rng, min: 0.5, max: 1.5),
    ].map { $0 * hueDiff }
    let d = [
        randRange(&rng, min: 0, max: 1) * randRange(&rng, min: 1, max: 3),
        randRange(&rng, min: 0, max: 1) * randRange(&rng, min: 1, max: 3),
        randRange(&rng, min: 0, max: 1) * randRange(&rng, min: 1, max: 3),
    ]

    let denominator = max(1, count - 1)
    return (0..<count).map { index in
        let t = Float(index) / Float(denominator)
        let x = cos(Double.pi * 2 * Double(c[0] * t + d[0]))
        let y = cos(Double.pi * 2 * Double(c[1] * t + d[1]))
        let z = cos(Double.pi * 2 * Double(c[2] * t + d[2]))
        return PixelColor(
            r: a[0] + b[0] * Float(x),
            g: a[1] + b[1] * Float(y),
            b: a[2] + b[2] * Float(z),
            a: 1
        )
    }
}

```

`StarO/PixelPlanets/Core/PixelColor.swift`:

```swift
import Foundation
import simd

/// RGBA color representation with components in the range `[0, 1]`.
public struct PixelColor: Equatable, Codable, Sendable {
    public var r: Float
    public var g: Float
    public var b: Float
    public var a: Float

    public init(r: Float, g: Float, b: Float, a: Float = 1) {
        self.r = Self.clamp01(r)
        self.g = Self.clamp01(g)
        self.b = Self.clamp01(b)
        self.a = Self.clamp01(a)
    }

    public init(_ vector: SIMD4<Float>) {
        self.init(r: vector.x, g: vector.y, b: vector.z, a: vector.w)
    }

    public var simd: SIMD4<Float> {
        SIMD4(r, g, b, a)
    }

    @inline(__always)
    private static func clamp01(_ value: Float) -> Float {
        max(0, min(1, value))
    }

    public func withAlpha(_ alpha: Float) -> PixelColor {
        PixelColor(r: r, g: g, b: b, a: alpha)
    }

    public func asArray() -> [Float] {
        [r, g, b, a]
    }
}

public extension PixelColor {
    static func fromHex(_ hex: String) -> PixelColor {
        let clean = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard let value = UInt32(clean, radix: 16) else {
            return PixelColor(r: 0, g: 0, b: 0, a: 1)
        }
        if clean.count == 8 {
            return PixelColor(
                r: Float((value >> 24) & 0xff) / 255,
                g: Float((value >> 16) & 0xff) / 255,
                b: Float((value >> 8) & 0xff) / 255,
                a: Float(value & 0xff) / 255
            )
        }
        return PixelColor(
            r: Float((value >> 16) & 0xff) / 255,
            g: Float((value >> 8) & 0xff) / 255,
            b: Float(value & 0xff) / 255,
            a: 1
        )
    }
}

public struct HSV: Equatable, Sendable {
    public var h: Float
    public var s: Float
    public var v: Float
    public var a: Float

    public init(h: Float, s: Float, v: Float, a: Float = 1) {
        self.h = h
        self.s = s
        self.v = v
        self.a = a
    }
}

public extension PixelColor {
    func toHSV() -> HSV {
        let maxComponent = max(r, g, b)
        let minComponent = min(r, g, b)
        let delta = maxComponent - minComponent

        var hue: Float = 0
        let saturation: Float = maxComponent == 0 ? 0 : delta / maxComponent
        let value = maxComponent

        if delta != 0 {
            if maxComponent == r {
                hue = (g - b) / delta + (g < b ? 6 : 0)
            } else if maxComponent == g {
                hue = (b - r) / delta + 2
            } else {
                hue = (r - g) / delta + 4
            }
            hue /= 6
        }

        return HSV(h: hue, s: saturation, v: value, a: a)
    }

    static func fromHSV(_ hsv: HSV) -> PixelColor {
        func wrapHue(_ value: Float) -> Float {
            let wrapped = value.remainder(dividingBy: 1)
            return wrapped < 0 ? wrapped + 1 : wrapped
        }

        let h = wrapHue(hsv.h) * 6
        let i = floor(h)
        let f = h - i
        let p = hsv.v * (1 - hsv.s)
        let q = hsv.v * (1 - f * hsv.s)
        let t = hsv.v * (1 - (1 - f) * hsv.s)

        let mod = Int(i) % 6
        let (r, g, b): (Float, Float, Float)
        switch mod {
        case 0: (r, g, b) = (hsv.v, t, p)
        case 1: (r, g, b) = (q, hsv.v, p)
        case 2: (r, g, b) = (p, hsv.v, t)
        case 3: (r, g, b) = (p, q, hsv.v)
        case 4: (r, g, b) = (t, p, hsv.v)
        default: (r, g, b) = (hsv.v, p, q)
        }

        return PixelColor(r: r, g: g, b: b, a: hsv.a)
    }
}

public extension PixelColor {
    func darkened(by amount: Float) -> PixelColor {
        let factor = max(0, min(1, 1 - amount))
        return PixelColor(r: r * factor, g: g * factor, b: b * factor, a: a)
    }

    func lightened(by amount: Float) -> PixelColor {
        let value = max(0, min(1, amount))
        return PixelColor(
            r: r + (1 - r) * value,
            g: g + (1 - g) * value,
            b: b + (1 - b) * value,
            a: a
        )
    }

    func shiftedHue(by delta: Float) -> PixelColor {
        let hsv = toHSV()
        return PixelColor.fromHSV(HSV(h: hsv.h + delta, s: hsv.s, v: hsv.v, a: hsv.a))
    }
}

```

`StarO/PixelPlanets/Core/PlanetBase.swift`:

```swift
import Foundation
import simd

open class PlanetBase: @unchecked Sendable {
    public let id: String
    public let label: String
    public let relativeScale: Float
    public let guiZoom: Float
    public var overrideTime: Bool = false

    public private(set) var layers: [LayerState]
    public let colorBindings: [ColorBinding]
    public let uniformControls: [UniformControl]

    public init(config: PlanetConfig) throws {
        self.id = config.id
        self.label = config.label
        self.relativeScale = config.relativeScale
        self.guiZoom = config.guiZoom
        self.layers = try config.layers.map { try LayerState(definition: $0) }
        self.colorBindings = layers.flatMap(\.colorBindings)
        self.uniformControls = config.uniformControls
    }

    // MARK: - Layer utilities

    @discardableResult
    private func layer(named name: String) -> LayerState {
        guard let layer = layers.first(where: { $0.name == name }) else {
            fatalError("Layer \(name) not found on planet \(id)")
        }
        return layer
    }

    private func indexOfLayer(named name: String) -> Int {
        guard let index = layers.firstIndex(where: { $0.name == name }) else {
            fatalError("Layer \(name) not found on planet \(id)")
        }
        return index
    }

    private func setUniform(_ value: UniformValue, layerName: String, uniform: String) {
        let index = indexOfLayer(named: layerName)
        layers[index].uniforms[uniform] = value
    }

    private func getUniform(layerName: String, uniform: String) -> UniformValue {
        layer(named: layerName).uniforms[uniform] ?? {
            fatalError("Uniform \(uniform) missing on layer \(layerName)")
        }()
    }

    internal func setFloat(_ layerName: String, _ uniform: String, _ value: Float) {
        setUniform(.float(value), layerName: layerName, uniform: uniform)
    }

    internal func setVec2(_ layerName: String, _ uniform: String, _ value: SIMD2<Float>) {
        setUniform(.vec2(value), layerName: layerName, uniform: uniform)
    }

    internal func setBuffer(_ layerName: String, _ uniform: String, _ value: [Float]) {
        setUniform(.buffer(value), layerName: layerName, uniform: uniform)
    }

    internal func getFloat(_ layerName: String, _ uniform: String) -> Float {
        let value = getUniform(layerName: layerName, uniform: uniform)
        switch value {
        case .float(let scalar):
            return scalar
        case .vec2(let vector):
            return vector.x
        case .vec3(let vector):
            return vector.x
        case .vec4(let vector):
            return vector.x
        case .buffer(let buffer):
            return buffer.first ?? 0
        }
    }

    internal func getVec2(_ layerName: String, _ uniform: String) -> SIMD2<Float> {
        let value = getUniform(layerName: layerName, uniform: uniform)
        switch value {
        case .vec2(let vector):
            return vector
        case .buffer(let buffer) where buffer.count >= 2:
            return SIMD2(buffer[0], buffer[1])
        default:
            fatalError("Uniform \(uniform) on layer \(layerName) is not vec2")
        }
    }

    private func colors(for binding: ColorBinding) -> [PixelColor] {
        let uniform = getUniform(layerName: binding.layer, uniform: binding.uniform)
        guard case let .buffer(buffer) = uniform else {
            fatalError("Uniform \(binding.uniform) is not a color buffer")
        }
        var colors: [PixelColor] = []
        for index in stride(from: 0, to: min(buffer.count, binding.slots * 4), by: 4) {
            let color = PixelColor(
                r: buffer[index],
                g: buffer[index + 1],
                b: buffer[index + 2],
                a: buffer[index + 3]
            )
            colors.append(color)
        }
        return colors
    }

    private func setColors(_ colors: [PixelColor], for binding: ColorBinding) {
        var buffer = [Float](repeating: 0, count: binding.slots * 4)
        for (index, color) in colors.prefix(binding.slots).enumerated() {
            let offset = index * 4
            buffer[offset + 0] = color.r
            buffer[offset + 1] = color.g
            buffer[offset + 2] = color.b
            buffer[offset + 3] = color.a
        }
        setBuffer(binding.layer, binding.uniform, buffer)
    }

    internal func multiplier(for layerName: String) -> Float {
        let size = getFloat(layerName, "size")
        let speed = getFloat(layerName, "time_speed")
        guard speed != 0 else { return 0 }
        return (round(size) * 2) / speed
    }

    // MARK: - Public interface

    public func uniformControlsList() -> [UniformControl] {
        uniformControls
    }

    public func uniformValue(layerName: String, uniform: String) -> UniformValue? {
        layer(named: layerName).uniforms[uniform]
    }

    public func setUniformValue(layerName: String, uniform: String, value: UniformValue) {
        let index = indexOfLayer(named: layerName)
        guard let current = layers[index].uniforms[uniform] else {
            fatalError("Uniform \(uniform) missing on layer \(layerName)")
        }

        switch (current, value) {
        case (.float, .float),
             (.vec2, .vec2),
             (.vec3, .vec3),
             (.vec4, .vec4):
            layers[index].uniforms[uniform] = value
        case (.buffer(let buffer), .buffer(let newBuffer)):
            guard buffer.count == newBuffer.count else {
                fatalError("Mismatched buffer length for uniform \(uniform) on layer \(layerName)")
            }
            layers[index].uniforms[uniform] = .buffer(Array(newBuffer))
        default:
            fatalError("Unsupported uniform update for \(uniform) on layer \(layerName)")
        }
    }

    public func layersSummary() -> [LayerSummary] {
        layers.map { LayerSummary(name: $0.name, visible: $0.visible) }
    }

    public func toggleLayer(at index: Int) {
        guard layers.indices.contains(index) else { return }
        layers[index].visible.toggle()
    }

    public func colorsPalette() -> [PixelColor] {
        colorBindings.flatMap { colors(for: $0) }
    }

    public func setColors(_ colors: [PixelColor]) {
        var cursor = 0
        for binding in colorBindings {
            let end = min(cursor + binding.slots, colors.count)
            guard cursor < end else { break }
            setColors(Array(colors[cursor..<end]), for: binding)
            cursor = end
        }
    }

    // MARK: - Abstract API

    open func setPixels(_ amount: Int) {
        fatalError("setPixels not implemented for \(id)")
    }

    open func setLight(_ position: SIMD2<Float>) {
        fatalError("setLight not implemented for \(id)")
    }

    open func setSeed(_ seed: Int, rng: inout RandomStream) {
        fatalError("setSeed not implemented for \(id)")
    }

    open func setRotation(_ radians: Float) {
        fatalError("setRotation not implemented for \(id)")
    }

    open func updateTime(_ t: Float) {
        fatalError("updateTime not implemented for \(id)")
    }

    open func setCustomTime(_ t: Float) {
        fatalError("setCustomTime not implemented for \(id)")
    }

    open func setDither(_ enabled: Bool) {
        fatalError("setDither not implemented for \(id)")
    }

    open func isDitherEnabled() -> Bool {
        fatalError("getDither not implemented for \(id)")
    }

    open func randomizeColors(rng: inout RandomStream) -> [PixelColor] {
        fatalError("randomizeColors not implemented for \(id)")
    }
}

```

`StarO/PixelPlanets/Core/PlanetConfig.swift`:

```swift
import Foundation

public struct ColorBinding: Equatable, Sendable {
    public let layer: String
    public let uniform: String
    public let slots: Int

    public init(layer: String, uniform: String, slots: Int) {
        self.layer = layer
        self.uniform = uniform
        self.slots = slots
    }
}

public struct UniformControl: Equatable, Sendable {
    public let layer: String
    public let uniform: String
    public let label: String
    public let min: Float
    public let max: Float
    public let step: Float?

    public init(layer: String, uniform: String, label: String, min: Float, max: Float, step: Float? = nil) {
        self.layer = layer
        self.uniform = uniform
        self.label = label
        self.min = min
        self.max = max
        self.step = step
    }
}

public struct LayerDefinition: Sendable {
    public let name: String
    public let shaderPath: String
    public let uniforms: [String: UniformValue]
    public var visible: Bool
    public var colors: [ColorBinding]

    public init(
        name: String,
        shaderPath: String,
        uniforms: [String: UniformValue],
        visible: Bool = true,
        colors: [ColorBinding] = []
    ) {
        self.name = name
        self.shaderPath = shaderPath
        self.uniforms = uniforms
        self.visible = visible
        self.colors = colors
    }
}

public struct PlanetConfig: Sendable {
    public let id: String
    public let label: String
    public let relativeScale: Float
    public let guiZoom: Float
    public let layers: [LayerDefinition]
    public let uniformControls: [UniformControl]

    public init(
        id: String,
        label: String,
        relativeScale: Float,
        guiZoom: Float,
        layers: [LayerDefinition],
        uniformControls: [UniformControl] = []
    ) {
        self.id = id
        self.label = label
        self.relativeScale = relativeScale
        self.guiZoom = guiZoom
        self.layers = layers
        self.uniformControls = uniformControls
    }
}

public struct LayerSummary: Equatable, Sendable {
    public let name: String
    public var visible: Bool
}

public enum ShaderLibraryError: Error {
    case resourceNotFound(String)
    case unreadableResource(String)
}

public enum ShaderLibrary {
    public static func fragment(_ relativePath: String) throws -> String {
        let path = relativePath.hasSuffix(".frag") ? relativePath : "\(relativePath).frag"
        let url = try locate(path, in: "Shaders")
        do {
            return try String(contentsOf: url)
        } catch {
            throw ShaderLibraryError.unreadableResource(path)
        }
    }

    private static func locate(_ path: String, in subdirectory: String) throws -> URL {
        let components = path.split(separator: "/")
        guard let filename = components.last else {
            throw ShaderLibraryError.resourceNotFound(path)
        }
        let nameParts = filename.split(separator: ".")
        guard let base = nameParts.first else {
            throw ShaderLibraryError.resourceNotFound(path)
        }
        let ext = nameParts.count > 1 ? String(nameParts.last!) : nil
        let directory: String?
        if components.count > 1 {
            let subpath = components.dropLast().joined(separator: "/")
            directory = "\(subdirectory)/\(subpath)"
        } else {
            directory = subdirectory
        }
        // Try multiple possible locations for shaders
        // directory contains the full relative path including subfolders (e.g. "Shaders/gas-planet-layers")
        let searchPaths = [
            directory,
            "PixelPlanets/Resources/\(directory ?? "")",
            "StarO/PixelPlanets/Resources/\(directory ?? "")"
        ]
        
        for searchPath in searchPaths {
            // print("Searching for shader \(base).\(ext) in \(searchPath)")
            if let url = Bundle.main.url(forResource: String(base), withExtension: ext, subdirectory: searchPath) {
                // print("Found shader at \(url)")
                return url
            }
        }
        
        print("[ShaderLibrary] Failed to locate shader: \(path). Searched in: \(searchPaths)")
        
        // Fallback: try searching recursively in the bundle (slower but safer)
        // Note: This is a last resort.
        if let url = Bundle.main.url(forResource: String(base), withExtension: ext) {
            return url
        }
        
        throw ShaderLibraryError.resourceNotFound(path)
    }
}

/// Reference-type layer state used at runtime.
public final class LayerState: @unchecked Sendable {
    public let name: String
    public let shaderPath: String
    public let shaderSource: String
    public var uniforms: [String: UniformValue]
    public var visible: Bool
    public let colorBindings: [ColorBinding]

    public init(definition: LayerDefinition) throws {
        self.name = definition.name
        self.shaderPath = definition.shaderPath
        self.shaderSource = try ShaderLibrary.fragment(definition.shaderPath)
        self.uniforms = definition.uniforms.mapValues { $0.clone() }
        self.visible = definition.visible
        self.colorBindings = definition.colors
    }
}

```

`StarO/PixelPlanets/Core/PlanetConfigurator.swift`:

```swift
import Foundation
import simd

struct PlanetConfigurator {
    /// Configures a planet with randomized parameters based on a seed.
    /// This replaces the manual slider controls from the original project.
    @MainActor
    static func configure(planet: PlanetBase, seed: Int) {
        var rng = RandomStream(seed: seed)
        
        // 1. Generic Randomization for all controls
        // Iterate over all available controls and set a random value within their defined range.
        // This ensures that every parameter that *could* be tweaked is tweaked.
        for control in planet.uniformControls {
            // We only randomize floats for now as that covers most sliders
            // Some controls might be integers disguised as floats (like octaves),
            // but nextRange handles that continuously. For strict integers we might need care,
            // but usually shaders handle non-integers fine or we can round if needed.
            // However, for things like "octaves", it's better to pick an integer.
            
            if control.uniform == "octaves" || control.uniform == "OCTAVES" || control.uniform == "n_colors" {
                let value = round(rng.nextRange(min: control.min, max: control.max))
                planet.setFloat(control.layer, control.uniform, value)
            } else {
                let value = rng.nextRange(min: control.min, max: control.max)
                planet.setFloat(control.layer, control.uniform, value)
            }
        }
        
        // 2. Specific Overrides and Tuning
        // Some parameters need specific tuning to look good, rather than full random range.
        
        // Global defaults
        planet.setDither(true) // Always enable dither for the retro look
        
        // Planet-specific tuning
        switch planet {
        case is GasPlanetPlanet:
            configureGasPlanet(planet as! GasPlanetPlanet, rng: &rng)
        case is GasPlanetLayersPlanet:
            configureGasPlanetLayers(planet as! GasPlanetLayersPlanet, rng: &rng)
        case is LandMassesPlanet:
            configureLandMasses(planet as! LandMassesPlanet, rng: &rng)
        case is NoAtmospherePlanet:
            configureNoAtmosphere(planet as! NoAtmospherePlanet, rng: &rng)
        case is RiversPlanet:
            configureRivers(planet as! RiversPlanet, rng: &rng)
        case is BlackHolePlanet:
            configureBlackHole(planet as! BlackHolePlanet, rng: &rng)
        default:
            break
        }
    }
    
    @MainActor
    private static func configureGasPlanet(_ planet: GasPlanetPlanet, rng: inout RandomStream) {
        // GasPlanetPlanet uses "Cloud" and "Cloud2" layers (Swift original)
        // Gas planets look better with slower, majestic movement
        let speed = rng.nextRange(min: 0.05, max: 0.2)
        planet.setFloat("Cloud", "time_speed", speed)
        planet.setFloat("Cloud2", "time_speed", speed * 0.7)
        
        // Cloud scale
        let size = rng.nextRange(min: 3.0, max: 9.0)
        planet.setFloat("Cloud", "size", size)
        planet.setFloat("Cloud2", "size", size)
    }
    
    @MainActor
    private static func configureGasPlanetLayers(_ planet: GasPlanetLayersPlanet, rng: inout RandomStream) {
        // GasPlanetLayersPlanet uses "GasLayers" and "Ring" (Swift original)
        let speed = rng.nextRange(min: 0.05, max: 0.15)
        planet.setFloat("GasLayers", "time_speed", speed)
        planet.setFloat("Ring", "time_speed", speed)
        
        // Ring rotation relative to planet
        let ringRot = rng.nextRange(min: -0.5, max: 0.5)
        planet.setFloat("Ring", "rotation", ringRot)
    }
    
    @MainActor
    private static func configureLandMasses(_ planet: LandMassesPlanet, rng: inout RandomStream) {
        // Water level (land_cutoff)
        // Lower value = more land, Higher value = more water
        let waterLevel = rng.nextRange(min: 0.45, max: 0.65)
        planet.setFloat("Land", "land_cutoff", waterLevel)
        
        // Cloud movement
        planet.setFloat("Clouds", "time_speed", rng.nextRange(min: 0.1, max: 0.3))
    }
    
    @MainActor
    private static func configureNoAtmosphere(_ planet: NoAtmospherePlanet, rng: inout RandomStream) {
        // Crater density via size
        let craterScale = rng.nextRange(min: 2.0, max: 6.0)
        planet.setFloat("Craters", "size", craterScale)
    }
    
    @MainActor
    private static func configureRivers(_ planet: RiversPlanet, rng: inout RandomStream) {
        // River complexity
        let scale = rng.nextRange(min: 4.0, max: 10.0)
        planet.setFloat("Land", "size", scale)
    }
    
    @MainActor
    private static func configureBlackHole(_ planet: BlackHolePlanet, rng: inout RandomStream) {
        // Disk swirl speed
        planet.setFloat("Disk", "time_speed", rng.nextRange(min: 0.1, max: 0.4))
        
        // Core radius
        let radius = rng.nextRange(min: 0.2, max: 0.3)
        planet.setFloat("BlackHole", "radius", radius)
    }
}

```

`StarO/PixelPlanets/Core/PlanetLibrary.swift`:

```swift
import Foundation

public enum PlanetLibraryError: Error {
    case unknownPlanet(String)
}

public typealias PlanetFactory = @Sendable () throws -> PlanetBase

public enum PlanetLibrary {
    @MainActor
    private static let factories: [String: PlanetFactory] = [
        "Terran Wet": { try RiversPlanet() },
        "Terran Dry": { try DryTerranPlanet() },
        "Islands": { try LandMassesPlanet() },
        "No atmosphere": { try NoAtmospherePlanet() },
        "Gas giant 1": { try GasPlanetPlanet() },
        "Gas giant 2": { try GasPlanetLayersPlanet() },
        "Ice World": { try IceWorldPlanet() },
        "Lava World": { try LavaWorldPlanet() },
        "Asteroid": { try AsteroidPlanet() },
        "Black Hole": { try BlackHolePlanet() },
        "Galaxy": { try GalaxyPlanet() },
        "Galaxy Round": { try CircularGalaxyPlanet() },
        "Star": { try StarPlanet() },
    ]

    @MainActor
    public static var allPlanetNames: [String] {
        factories.keys.sorted()
    }

    @MainActor
    public static func makePlanet(named name: String) throws -> PlanetBase {
        guard let factory = factories[name] else {
            throw PlanetLibraryError.unknownPlanet(name)
        }
        return try factory()
    }
}

```

`StarO/PixelPlanets/Core/Planets/AsteroidPlanet.swift`:

```swift
import Foundation
import simd

private let asteroidBaseColors: [Float] = [
    0.639216, 0.654902, 0.760784, 1,
    0.298039, 0.407843, 0.521569, 1,
    0.227451, 0.247059, 0.368627, 1,
]

private func makeAsteroidConfig() -> PlanetConfig {
    let uniforms: [String: UniformValue] = [
        "pixels": .float(100),
        "rotation": .float(0),
        "light_origin": .vec2(Vec2(0, 0)),
        "time_speed": .float(0.4),
        "colors": .buffer(asteroidBaseColors),
        "size": .float(5.294),
        "octaves": .float(2),
        "seed": .float(1.567),
        "should_dither": .float(1),
    ]

    return PlanetConfig(
        id: "asteroid",
        label: "Asteroid",
        relativeScale: 1,
        guiZoom: 1,
        layers: [
            LayerDefinition(
                name: "Asteroid",
                shaderPath: "asteroid/asteroid.frag",
                uniforms: uniforms,
                colors: [ColorBinding(layer: "Asteroid", uniform: "colors", slots: 3)]
            ),
        ],
        uniformControls: [
            UniformControl(layer: "Asteroid", uniform: "time_speed", label: "Spin Speed", min: 0, max: 1, step: 0.01),
            UniformControl(layer: "Asteroid", uniform: "size", label: "Noise Scale", min: 1, max: 12, step: 0.1),
            UniformControl(layer: "Asteroid", uniform: "octaves", label: "Octaves", min: 1, max: 6, step: 1),
        ]
    )
}

private let asteroidConfig = makeAsteroidConfig()

public final class AsteroidPlanet: PlanetBase, @unchecked Sendable {
    public init() throws {
        try super.init(config: asteroidConfig)
    }

    public override func setPixels(_ amount: Int) {
        setFloat("Asteroid", "pixels", Float(amount))
    }

    public override func setLight(_ position: SIMD2<Float>) {
        setVec2("Asteroid", "light_origin", position)
    }

    public override func setSeed(_ seed: Int, rng: inout RandomStream) {
        let converted = Float(seed % 1000) / 100
        setFloat("Asteroid", "seed", converted)
    }

    public override func setRotation(_ radians: Float) {
        setFloat("Asteroid", "rotation", radians)
    }

    public override func updateTime(_ t: Float) { }

    public override func setCustomTime(_ t: Float) {
        setFloat("Asteroid", "rotation", t * Float.pi * 2)
    }

    public override func setDither(_ enabled: Bool) {
        setFloat("Asteroid", "should_dither", enabled ? 1 : 0)
    }

    public override func isDitherEnabled() -> Bool {
        getFloat("Asteroid", "should_dither") > 0.5
    }

    public override func randomizeColors(rng: inout RandomStream) -> [PixelColor] {
        var palette = generatePalette(
            rng: &rng,
            count: 3 + randInt(&rng, maxExclusive: 2),
            hueDiff: randRange(&rng, min: 0.3, max: 0.6),
            saturation: 0.7
        )
        if palette.count < 3 {
            palette += Array(repeating: PixelColor(r: 0.5, g: 0.5, b: 0.6, a: 1), count: 3 - palette.count)
        }

        var colors: [PixelColor] = []
        for i in 0..<3 {
            let shaded = palette[i % palette.count]
                .darkened(by: Float(i) / 3)
                .lightened(by: (1 - Float(i) / 3) * 0.2)
            colors.append(shaded)
        }

        setColors(colors)
        return colors
    }
}

@MainActor
func registerAsteroidPlanet(into factories: inout [String: PlanetFactory]) {
    factories["Asteroid"] = { try AsteroidPlanet() }
}

```

`StarO/PixelPlanets/Core/Planets/BlackHolePlanet.swift`:

```swift
import Foundation
import simd

private let blackHoleCoreColors: [Float] = [
    0.152941, 0.152941, 0.211765, 1,
    1, 1, 0.921569, 1,
    0.929412, 0.482353, 0.223529, 1,
]

private let blackHoleDiskColors: [Float] = [
    1, 1, 0.921569, 1,
    1, 0.960784, 0.25098, 1,
    1, 0.721569, 0.290196, 1,
    0.929412, 0.482353, 0.223529, 1,
    0.741176, 0.25098, 0.207843, 1,
]

private func makeBlackHoleConfig() -> PlanetConfig {
    let coreUniforms: [String: UniformValue] = [
        "pixels": .float(100),
        "colors": .buffer(blackHoleCoreColors),
        "radius": .float(0.247),
        "light_width": .float(0.028),
    ]

    let diskUniforms: [String: UniformValue] = [
        "pixels": .float(300),
        "rotation": .float(0.766),
        "light_origin": .vec2(Vec2(0.607, 0.444)),
        "time_speed": .float(0.2),
        "disk_width": .float(0.065),
        "ring_perspective": .float(14),
        "should_dither": .float(1),
        "colors": .buffer(blackHoleDiskColors),
        "n_colors": .float(5),
        "size": .float(6.598),
        "OCTAVES": .float(3),
        "seed": .float(8.175),
        "time": .float(0),
    ]

    return PlanetConfig(
        id: "black-hole",
        label: "Black Hole",
        relativeScale: 2,
        guiZoom: 2,
        layers: [
            LayerDefinition(
                name: "BlackHole",
                shaderPath: "black-hole/core.frag",
                uniforms: coreUniforms,
                colors: [ColorBinding(layer: "BlackHole", uniform: "colors", slots: 3)]
            ),
            LayerDefinition(
                name: "Disk",
                shaderPath: "black-hole/ring.frag",
                uniforms: diskUniforms,
                colors: [ColorBinding(layer: "Disk", uniform: "colors", slots: 5)]
            ),
        ],
        uniformControls: [
            UniformControl(layer: "BlackHole", uniform: "radius", label: "Core Radius", min: 0.1, max: 0.5, step: 0.005),
            UniformControl(layer: "BlackHole", uniform: "light_width", label: "Core Light Width", min: 0, max: 0.2, step: 0.005),
            UniformControl(layer: "Disk", uniform: "time_speed", label: "Disk Time Speed", min: 0, max: 1, step: 0.01),
            UniformControl(layer: "Disk", uniform: "disk_width", label: "Disk Width", min: 0.01, max: 0.2, step: 0.005),
            UniformControl(layer: "Disk", uniform: "ring_perspective", label: "Ring Perspective", min: 1, max: 20, step: 0.2),
            UniformControl(layer: "Disk", uniform: "size", label: "Disk Noise Scale", min: 1, max: 15, step: 0.1),
            UniformControl(layer: "Disk", uniform: "OCTAVES", label: "Disk Octaves", min: 1, max: 6, step: 1),
            UniformControl(layer: "Disk", uniform: "n_colors", label: "Disk Colors", min: 3, max: 7, step: 1),
        ]
    )
}

private let blackHoleConfig = makeBlackHoleConfig()

public final class BlackHolePlanet: PlanetBase, @unchecked Sendable {
    public init() throws {
        try super.init(config: blackHoleConfig)
    }

    public override func setPixels(_ amount: Int) {
        let value = Float(amount)
        setFloat("BlackHole", "pixels", value)
        setFloat("Disk", "pixels", value * 3)
    }

    public override func setLight(_ position: SIMD2<Float>) {
        setVec2("Disk", "light_origin", position)
    }

    public override func setSeed(_ seed: Int, rng: inout RandomStream) {
        let converted = Float(seed % 1000) / 100
        setFloat("Disk", "seed", converted)
    }

    public override func setRotation(_ radians: Float) {
        setFloat("Disk", "rotation", radians + 0.7)
    }

    public override func updateTime(_ t: Float) {
        setFloat("Disk", "time", t * 314.15 * 0.004)
    }

    public override func setCustomTime(_ t: Float) {
        let speed = max(0.0001, getFloat("Disk", "time_speed"))
        setFloat("Disk", "time", t * 314.15 * speed * 0.5)
    }

    public override func setDither(_ enabled: Bool) {
        setFloat("Disk", "should_dither", enabled ? 1 : 0)
    }

    public override func isDitherEnabled() -> Bool {
        getFloat("Disk", "should_dither") > 0.5
    }

    public override func randomizeColors(rng: inout RandomStream) -> [PixelColor] {
        var palette = generatePalette(
            rng: &rng,
            count: 5 + randInt(&rng, maxExclusive: 2),
            hueDiff: randRange(&rng, min: 0.3, max: 0.5),
            saturation: 2.0
        )
        if palette.count < 5 {
            palette += Array(repeating: PixelColor(r: 1, g: 0.8, b: 0.3, a: 1), count: 5 - palette.count)
        }

        var diskColors: [PixelColor] = []
        for i in 0..<5 {
            var shade = palette[i % palette.count].darkened(by: (Float(i) / 5) * 0.7)
            shade = shade.lightened(by: (1 - Float(i) / 5) * 0.9)
            diskColors.append(shade)
        }

        let core = PixelColor(r: 0.152941, g: 0.152941, b: 0.211765, a: 1)
        let colors = [core, diskColors[0], diskColors[3]] + diskColors
        setColors(colors)
        return colors
    }
}

@MainActor
func registerBlackHolePlanet(into factories: inout [String: PlanetFactory]) {
    factories["Black Hole"] = { try BlackHolePlanet() }
}

```

`StarO/PixelPlanets/Core/Planets/CircularGalaxyPlanet.swift`:

```swift
import Foundation
import simd

private let circularGalaxyColors: [Float] = [
    0.992157, 0.937255, 0.843137, 1,
    0.968627, 0.756863, 0.505882, 1,
    0.741176, 0.603922, 0.870588, 1,
    0.45098, 0.435294, 0.752941, 1,
    0.278431, 0.400784, 0.635294, 1,
    0.184314, 0.239216, 0.417647, 1,
    0.12549, 0.152941, 0.270588, 1,
]

private func makeCircularGalaxyConfig() -> PlanetConfig {
    let uniforms: [String: UniformValue] = [
        "pixels": .float(200),
        "rotation": .float(0.512),
        "time_speed": .float(1.1),
        "dither_size": .float(2),
        "should_dither": .float(1),
        "colors": .buffer(circularGalaxyColors),
        "n_colors": .float(6),
        "size": .float(8.5),
        "OCTAVES": .float(1),
        "seed": .float(6.781),
        "time": .float(0),
        "tilt": .float(1),
        "n_layers": .float(6),
        "layer_height": .float(0.22),
        "zoom": .float(1.1),
        "swirl": .float(-11),
    ]

    let controls: [UniformControl] = [
        UniformControl(layer: "Galaxy", uniform: "time_speed", label: "Time Speed", min: 0, max: 4, step: 0.05),
        UniformControl(layer: "Galaxy", uniform: "dither_size", label: "Dither Size", min: 0, max: 6, step: 0.1),
        UniformControl(layer: "Galaxy", uniform: "size", label: "Noise Scale", min: 1, max: 15, step: 0.1),
        UniformControl(layer: "Galaxy", uniform: "OCTAVES", label: "Octaves", min: 1, max: 6, step: 1),
        UniformControl(layer: "Galaxy", uniform: "n_layers", label: "Layer Count", min: 1, max: 8, step: 1),
        UniformControl(layer: "Galaxy", uniform: "layer_height", label: "Layer Height", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Galaxy", uniform: "zoom", label: "Zoom", min: 0.5, max: 2.5, step: 0.05),
        UniformControl(layer: "Galaxy", uniform: "swirl", label: "Swirl", min: -12, max: 12, step: 0.5),
    ]

    return PlanetConfig(
        id: "galaxy-circular",
        label: "Galaxy Round",
        relativeScale: 1,
        guiZoom: 2,
        layers: [
            LayerDefinition(
                name: "Galaxy",
                shaderPath: "galaxy/galaxy.frag",
                uniforms: uniforms,
                colors: [ColorBinding(layer: "Galaxy", uniform: "colors", slots: 7)]
            ),
        ],
        uniformControls: controls
    )
}

private let circularGalaxyConfig = makeCircularGalaxyConfig()

public final class CircularGalaxyPlanet: PlanetBase, @unchecked Sendable {
    public init() throws {
        try super.init(config: circularGalaxyConfig)
    }

    public override func setPixels(_ amount: Int) {
        setFloat("Galaxy", "pixels", Float(amount))
    }

    public override func setLight(_ position: SIMD2<Float>) {
        // Galaxy shader ignores external light.
    }

    public override func setSeed(_ seed: Int, rng: inout RandomStream) {
        let converted = Float(seed % 1000) / 100
        setFloat("Galaxy", "seed", converted)
    }

    public override func setRotation(_ radians: Float) {
        setFloat("Galaxy", "rotation", radians)
    }

    public override func updateTime(_ t: Float) {
        setFloat("Galaxy", "time", t * multiplier(for: "Galaxy") * 0.035)
    }

    public override func setCustomTime(_ t: Float) {
        let speed = max(0.0001, getFloat("Galaxy", "time_speed"))
        setFloat("Galaxy", "time", t * Float.pi * 2 * speed)
    }

    public override func setDither(_ enabled: Bool) {
        setFloat("Galaxy", "should_dither", enabled ? 1 : 0)
    }

    public override func isDitherEnabled() -> Bool {
        getFloat("Galaxy", "should_dither") > 0.5
    }

    public override func randomizeColors(rng: inout RandomStream) -> [PixelColor] {
        var palette = generatePalette(
            rng: &rng,
            count: 6,
            hueDiff: randRange(&rng, min: 0.45, max: 0.75),
            saturation: 1.2
        )
        if palette.count < 6 {
            palette += Array(repeating: PixelColor(r: 0.9, g: 0.8, b: 0.6, a: 1), count: 6 - palette.count)
        }

        var colors: [PixelColor] = []
        for i in 0..<6 {
            var shade = palette[i % palette.count].darkened(by: Float(i) / 7)
            shade = shade.lightened(by: (1 - Float(i) / 6) * 0.55)
            colors.append(shade)
        }
        colors.append(colors.last ?? PixelColor(r: 1, g: 1, b: 1, a: 1))
        setColors(colors)
        return colors
    }
}

@MainActor
func registerCircularGalaxyPlanet(into factories: inout [String: PlanetFactory]) {
    factories["Galaxy Round"] = { try CircularGalaxyPlanet() }
}

// Twinkle Galaxy variant removed by product decision.

```

`StarO/PixelPlanets/Core/Planets/DryTerranPlanet.swift`:

```swift
import Foundation
import simd

private let dryLandColors: [Float] = [
    1, 0.537255, 0.2, 1,
    0.901961, 0.270588, 0.223529, 1,
    0.678431, 0.184314, 0.270588, 1,
    0.321569, 0.2, 0.247059, 1,
    0.239216, 0.160784, 0.211765, 1,
]

private func normalizedSeed(_ seed: Int) -> Float {
    let remainder = ((seed % 1000) + 1000) % 1000
    let value = Float(remainder) / 100
    return max(value, 0.01)
}

private func makeDryTerranConfig() -> PlanetConfig {
    let landUniforms: [String: UniformValue] = [
        "pixels": .float(100),
        "rotation": .float(0),
        "light_origin": .vec2(Vec2(0.4, 0.3)),
        "light_distance1": .float(0.362),
        "light_distance2": .float(0.525),
        "time_speed": .float(0.1),
        "dither_size": .float(2),
        "colors": .buffer(dryLandColors),
        "n_colors": .float(5),
        "size": .float(8),
        "OCTAVES": .float(3),
        "seed": .float(1.175),
        "time": .float(0),
        "should_dither": .float(1),
    ]

    return PlanetConfig(
        id: "dry-terran",
        label: "Terran Dry",
        relativeScale: 1,
        guiZoom: 1,
        layers: [
            LayerDefinition(
                name: "Land",
                shaderPath: "dry-terran/land.frag",
                uniforms: landUniforms,
                colors: [ColorBinding(layer: "Land", uniform: "colors", slots: 5)]
            ),
        ],
        uniformControls: [
            UniformControl(layer: "Land", uniform: "light_distance1", label: "Light Distance 1", min: 0, max: 1, step: 0.01),
            UniformControl(layer: "Land", uniform: "light_distance2", label: "Light Distance 2", min: 0, max: 1, step: 0.01),
            UniformControl(layer: "Land", uniform: "time_speed", label: "Time Speed", min: 0, max: 1, step: 0.01),
            UniformControl(layer: "Land", uniform: "dither_size", label: "Dither Size", min: 0, max: 6, step: 0.1),
            UniformControl(layer: "Land", uniform: "size", label: "Noise Scale", min: 1, max: 20, step: 0.1),
            UniformControl(layer: "Land", uniform: "OCTAVES", label: "Octaves", min: 1, max: 12, step: 1),
        ]
    )
}

private let dryTerranConfig = makeDryTerranConfig()

public final class DryTerranPlanet: PlanetBase, @unchecked Sendable {
    public init() throws {
        try super.init(config: dryTerranConfig)
    }

    public override func setPixels(_ amount: Int) {
        setFloat("Land", "pixels", Float(amount))
    }

    public override func setLight(_ position: SIMD2<Float>) {
        setVec2("Land", "light_origin", position)
    }

    public override func setSeed(_ seed: Int, rng: inout RandomStream) {
        setFloat("Land", "seed", normalizedSeed(seed))
    }

    public override func setRotation(_ radians: Float) {
        setFloat("Land", "rotation", radians)
    }

    public override func updateTime(_ t: Float) {
        setFloat("Land", "time", t * multiplier(for: "Land") * 0.02)
    }

    public override func setCustomTime(_ t: Float) {
        setFloat("Land", "time", t * multiplier(for: "Land"))
    }

    public override func setDither(_ enabled: Bool) {
        setFloat("Land", "should_dither", enabled ? 1 : 0)
    }

    public override func isDitherEnabled() -> Bool {
        getFloat("Land", "should_dither") > 0.5
    }

    public override func randomizeColors(rng: inout RandomStream) -> [PixelColor] {
        var palette = generatePalette(
            rng: &rng,
            count: 5 + randInt(&rng, maxExclusive: 3),
            hueDiff: randRange(&rng, min: 0.3, max: 0.65),
            saturation: 1.0
        )
        if palette.count < 5 {
            palette += Array(repeating: PixelColor(r: 0.8, g: 0.6, b: 0.3, a: 1), count: 5 - palette.count)
        }

        let count = 5
        var colors: [PixelColor] = []
        for i in 0..<count {
            let base = palette[i % palette.count]
            let shaded = base.darkened(by: Float(i) / Float(count))
            let lightened = shaded.lightened(by: (1 - Float(i) / Float(count)) * 0.2)
            colors.append(lightened)
        }

        setColors(colors)
        return colors
    }
}

@MainActor
func registerDryTerranPlanet(into factories: inout [String: PlanetFactory]) {
    factories["Terran Dry"] = { try DryTerranPlanet() }
}

```

`StarO/PixelPlanets/Core/Planets/GalaxyPlanet.swift`:

```swift
import Foundation
import simd

private let galaxyBaseColors: [Float] = [
    1, 1, 0.921569, 1,
    1, 0.913725, 0.552941, 1,
    0.709804, 0.878431, 0.4, 1,
    0.396078, 0.647059, 0.4, 1,
    0.223529, 0.364706, 0.392157, 1,
    0.196078, 0.223529, 0.301961, 1,
    0.196078, 0.160784, 0.278431, 1,
]

private func makeGalaxyConfig() -> PlanetConfig {
    let uniforms: [String: UniformValue] = [
        "pixels": .float(200),
        "rotation": .float(0.674),
        "time_speed": .float(1),
        "dither_size": .float(2),
        "should_dither": .float(1),
        "colors": .buffer(galaxyBaseColors),
        "n_colors": .float(6),
        "size": .float(7),
        "OCTAVES": .float(1),
        "seed": .float(5.881),
        "time": .float(0),
        "tilt": .float(3),
        "n_layers": .float(4),
        "layer_height": .float(0.4),
        "zoom": .float(1.375),
        "swirl": .float(-9),
    ]

    let controls: [UniformControl] = [
        UniformControl(layer: "Galaxy", uniform: "time_speed", label: "Time Speed", min: 0, max: 4, step: 0.05),
        UniformControl(layer: "Galaxy", uniform: "dither_size", label: "Dither Size", min: 0, max: 6, step: 0.1),
        UniformControl(layer: "Galaxy", uniform: "size", label: "Noise Scale", min: 1, max: 15, step: 0.1),
        UniformControl(layer: "Galaxy", uniform: "OCTAVES", label: "Octaves", min: 1, max: 6, step: 1),
        UniformControl(layer: "Galaxy", uniform: "tilt", label: "Tilt", min: 1, max: 6, step: 0.1),
        UniformControl(layer: "Galaxy", uniform: "n_layers", label: "Layer Count", min: 1, max: 8, step: 1),
        UniformControl(layer: "Galaxy", uniform: "layer_height", label: "Layer Height", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Galaxy", uniform: "zoom", label: "Zoom", min: 0.5, max: 3, step: 0.05),
        UniformControl(layer: "Galaxy", uniform: "swirl", label: "Swirl", min: -12, max: 12, step: 0.5),
    ]

    return PlanetConfig(
        id: "galaxy",
        label: "Galaxy",
        relativeScale: 1,
        guiZoom: 2.5,
        layers: [
            LayerDefinition(
                name: "Galaxy",
                shaderPath: "galaxy/galaxy.frag",
                uniforms: uniforms,
                colors: [ColorBinding(layer: "Galaxy", uniform: "colors", slots: 7)]
            ),
        ],
        uniformControls: controls
    )
}

private let galaxyConfig = makeGalaxyConfig()

public final class GalaxyPlanet: PlanetBase, @unchecked Sendable {
    public init() throws {
        try super.init(config: galaxyConfig)
    }

    public override func setPixels(_ amount: Int) {
        setFloat("Galaxy", "pixels", Float(amount))
    }

    public override func setLight(_ position: SIMD2<Float>) {
        // Galaxy shader does not use external light.
    }

    public override func setSeed(_ seed: Int, rng: inout RandomStream) {
        let converted = Float(seed % 1000) / 100
        setFloat("Galaxy", "seed", converted)
    }

    public override func setRotation(_ radians: Float) {
        setFloat("Galaxy", "rotation", radians)
    }

    public override func updateTime(_ t: Float) {
        setFloat("Galaxy", "time", t * multiplier(for: "Galaxy") * 0.04)
    }

    public override func setCustomTime(_ t: Float) {
        let speed = max(0.0001, getFloat("Galaxy", "time_speed"))
        setFloat("Galaxy", "time", t * Float.pi * 2 * speed)
    }

    public override func setDither(_ enabled: Bool) {
        setFloat("Galaxy", "should_dither", enabled ? 1 : 0)
    }

    public override func isDitherEnabled() -> Bool {
        getFloat("Galaxy", "should_dither") > 0.5
    }

    public override func randomizeColors(rng: inout RandomStream) -> [PixelColor] {
        var palette = generatePalette(
            rng: &rng,
            count: 6,
            hueDiff: randRange(&rng, min: 0.5, max: 0.8),
            saturation: 1.4
        )
        if palette.count < 6 {
            palette += Array(repeating: PixelColor(r: 0.8, g: 0.8, b: 0.5, a: 1), count: 6 - palette.count)
        }

        var colors: [PixelColor] = []
        for i in 0..<6 {
            var shade = palette[i % palette.count].darkened(by: Float(i) / 7)
            shade = shade.lightened(by: (1 - Float(i) / 6) * 0.6)
            colors.append(shade)
        }
        colors.append(colors.last ?? PixelColor(r: 1, g: 1, b: 1, a: 1))
        setColors(colors)
        return colors
    }
}

@MainActor
func registerGalaxyPlanet(into factories: inout [String: PlanetFactory]) {
    factories["Galaxy"] = { try GalaxyPlanet() }
}

```

`StarO/PixelPlanets/Core/Planets/GasPlanetLayersPlanet.swift`:

```swift
import Foundation
import simd

private let gasLayersLightColors: [Float] = [
    0.933333, 0.764706, 0.603922, 1,
    0.85098, 0.627451, 0.4, 1,
    0.560784, 0.337255, 0.231373, 1,
]

private let gasLayersDarkColors: [Float] = [
    0.4, 0.223529, 0.192157, 1,
    0.270588, 0.156863, 0.235294, 1,
    0.133333, 0.12549, 0.203922, 1,
]

private let ringLightColors: [Float] = [
    0.933333, 0.764706, 0.603922, 1,
    0.701961, 0.478431, 0.313726, 1,
    0.560784, 0.337255, 0.231373, 1,
]

private let ringDarkColors: [Float] = [
    0.333333, 0.188235, 0.211765, 1,
    0.196078, 0.137255, 0.215686, 1,
    0.133333, 0.12549, 0.203922, 1,
]

private func makeGasPlanetLayersConfig() -> PlanetConfig {
    let gasUniforms: [String: UniformValue] = [
        "pixels": .float(100),
        "rotation": .float(0),
        "cloud_cover": .float(0.61),
        "light_origin": .vec2(Vec2(-0.1, 0.3)),
        "time_speed": .float(0.05),
        "stretch": .float(2.204),
        "cloud_curve": .float(1.376),
        "light_border_1": .float(0.52),
        "light_border_2": .float(0.62),
        "bands": .float(0.892),
        "should_dither": .float(1),
        "n_colors": .float(3),
        "colors": .buffer(gasLayersLightColors),
        "dark_colors": .buffer(gasLayersDarkColors),
        "size": .float(10.107),
        "OCTAVES": .float(3),
        "seed": .float(6.314),
        "time": .float(0),
    ]

    let ringUniforms: [String: UniformValue] = [
        "pixels": .float(300),
        "rotation": .float(0.7),
        "light_origin": .vec2(Vec2(-0.1, 0.3)),
        "time_speed": .float(0.2),
        "light_border_1": .float(0.52),
        "light_border_2": .float(0.62),
        "ring_width": .float(0.127),
        "ring_perspective": .float(6),
        "scale_rel_to_planet": .float(6),
        "n_colors": .float(3),
        "colors": .buffer(ringLightColors),
        "dark_colors": .buffer(ringDarkColors),
        "size": .float(15),
        "OCTAVES": .float(4),
        "seed": .float(8.461),
        "time": .float(0),
    ]

    let controls: [UniformControl] = [
        UniformControl(layer: "GasLayers", uniform: "cloud_cover", label: "Layers Cloud Cover", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "GasLayers", uniform: "time_speed", label: "Layers Time Speed", min: 0, max: 0.2, step: 0.005),
        UniformControl(layer: "GasLayers", uniform: "stretch", label: "Layers Stretch", min: 1, max: 3, step: 0.05),
        UniformControl(layer: "GasLayers", uniform: "bands", label: "Bands", min: 0, max: 2, step: 0.01),
        UniformControl(layer: "GasLayers", uniform: "light_border_1", label: "Layers Light Border 1", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "GasLayers", uniform: "light_border_2", label: "Layers Light Border 2", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "GasLayers", uniform: "size", label: "Layers Noise Scale", min: 1, max: 15, step: 0.1),
        UniformControl(layer: "GasLayers", uniform: "OCTAVES", label: "Layers Octaves", min: 1, max: 6, step: 1),
        UniformControl(layer: "Ring", uniform: "time_speed", label: "Ring Time Speed", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Ring", uniform: "ring_width", label: "Ring Width", min: 0.01, max: 0.3, step: 0.005),
        UniformControl(layer: "Ring", uniform: "ring_perspective", label: "Ring Perspective", min: 1, max: 20, step: 0.1),
        UniformControl(layer: "Ring", uniform: "scale_rel_to_planet", label: "Ring Scale", min: 1, max: 10, step: 0.1),
        UniformControl(layer: "Ring", uniform: "light_border_1", label: "Ring Light Border 1", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Ring", uniform: "light_border_2", label: "Ring Light Border 2", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Ring", uniform: "size", label: "Ring Noise Scale", min: 1, max: 20, step: 0.1),
        UniformControl(layer: "Ring", uniform: "OCTAVES", label: "Ring Octaves", min: 1, max: 6, step: 1),
    ]

    return PlanetConfig(
        id: "gas-planet-layers",
        label: "Gas giant 2",
        relativeScale: 3,
        guiZoom: 2.5,
        layers: [
            LayerDefinition(
                name: "GasLayers",
                shaderPath: "gas-planet-layers/layers.frag",
                uniforms: gasUniforms,
                colors: [
                    ColorBinding(layer: "GasLayers", uniform: "colors", slots: 3),
                    ColorBinding(layer: "GasLayers", uniform: "dark_colors", slots: 3),
                ]
            ),
            LayerDefinition(
                name: "Ring",
                shaderPath: "gas-planet-layers/ring.frag",
                uniforms: ringUniforms,
                colors: [
                    ColorBinding(layer: "Ring", uniform: "colors", slots: 3),
                    ColorBinding(layer: "Ring", uniform: "dark_colors", slots: 3),
                ]
            ),
        ],
        uniformControls: controls
    )
}

private let gasPlanetLayersConfig = makeGasPlanetLayersConfig()

public final class GasPlanetLayersPlanet: PlanetBase, @unchecked Sendable {
    public init() throws {
        try super.init(config: gasPlanetLayersConfig)
    }

    public override func setPixels(_ amount: Int) {
        let value = Float(amount)
        setFloat("GasLayers", "pixels", value)
        setFloat("Ring", "pixels", value * relativeScale)
    }

    public override func setLight(_ position: SIMD2<Float>) {
        setVec2("GasLayers", "light_origin", position)
        setVec2("Ring", "light_origin", position)
    }

    public override func setSeed(_ seed: Int, rng: inout RandomStream) {
        let converted = Float(seed % 1000) / 100
        setFloat("GasLayers", "seed", converted)
        setFloat("Ring", "seed", converted)
    }

    public override func setRotation(_ radians: Float) {
        setFloat("GasLayers", "rotation", radians)
        setFloat("Ring", "rotation", radians + 0.7)
    }

    public override func updateTime(_ t: Float) {
        setFloat("GasLayers", "time", t * multiplier(for: "GasLayers") * 0.004)
        setFloat("Ring", "time", t * 314.15 * 0.004)
    }

    public override func setCustomTime(_ t: Float) {
        setFloat("GasLayers", "time", t * multiplier(for: "GasLayers"))
        let speed = max(0.0001, getFloat("Ring", "time_speed"))
        setFloat("Ring", "time", t * 314.15 * speed * 0.5)
    }

    public override func setDither(_ enabled: Bool) {
        setFloat("GasLayers", "should_dither", enabled ? 1 : 0)
    }

    public override func isDitherEnabled() -> Bool {
        getFloat("GasLayers", "should_dither") > 0.5
    }

    public override func randomizeColors(rng: inout RandomStream) -> [PixelColor] {
        var palette = generatePalette(
            rng: &rng,
            count: 6 + randInt(&rng, maxExclusive: 4),
            hueDiff: randRange(&rng, min: 0.3, max: 0.55),
            saturation: 1.4
        )
        if palette.count < 6 {
            palette += Array(repeating: PixelColor(r: 0.7, g: 0.5, b: 0.4, a: 1), count: 6 - palette.count)
        }

        var baseCols: [PixelColor] = []
        for i in 0..<6 {
            let base = palette[i % palette.count]
            var shade = base.darkened(by: Float(i) / 7)
            shade = shade.lightened(by: (1 - Float(i) / 6) * 0.3)
            baseCols.append(shade)
        }

        let lights = Array(baseCols[0..<3])
        let darks = Array(baseCols[3..<6])
        let combined = lights + darks + lights + darks
        setColors(combined)
        return combined
    }
}

@MainActor
func registerGasPlanetLayersPlanet(into factories: inout [String: PlanetFactory]) {
    factories["Gas giant 2"] = { try GasPlanetLayersPlanet() }
}

```

`StarO/PixelPlanets/Core/Planets/GasPlanetPlanet.swift`:

```swift
import Foundation
import simd

private let gasLayerOneColors: [Float] = [
    0.231373, 0.12549, 0.152941, 1,
    0.231373, 0.12549, 0.152941, 1,
    0, 0, 0, 1,
    0.129412, 0.0941176, 0.105882, 1,
]

private let gasLayerTwoColors: [Float] = [
    0.941176, 0.709804, 0.254902, 1,
    0.811765, 0.458824, 0.168627, 1,
    0.670588, 0.317647, 0.188235, 1,
    0.490196, 0.219608, 0.2, 1,
]

private func makeGasPlanetConfig() -> PlanetConfig {
    let cloud1Uniforms: [String: UniformValue] = [
        "pixels": .float(100),
        "rotation": .float(0),
        "cloud_cover": .float(0),
        "light_origin": .vec2(Vec2(0.25, 0.25)),
        "time_speed": .float(0.7),
        "stretch": .float(1),
        "cloud_curve": .float(1.3),
        "light_border_1": .float(0.692),
        "light_border_2": .float(0.666),
        "colors": .buffer(gasLayerOneColors),
        "size": .float(9),
        "OCTAVES": .float(5),
        "seed": .float(5.939),
        "time": .float(0),
    ]

    let cloud2Uniforms: [String: UniformValue] = [
        "pixels": .float(100),
        "rotation": .float(0),
        "cloud_cover": .float(0.538),
        "light_origin": .vec2(Vec2(0.25, 0.25)),
        "time_speed": .float(0.47),
        "stretch": .float(1),
        "cloud_curve": .float(1.3),
        "light_border_1": .float(0.439),
        "light_border_2": .float(0.746),
        "colors": .buffer(gasLayerTwoColors),
        "size": .float(9),
        "OCTAVES": .float(5),
        "seed": .float(5.939),
        "time": .float(0),
    ]

    let controls: [UniformControl] = [
        UniformControl(layer: "Cloud", uniform: "cloud_cover", label: "Layer 1 Cloud Cover", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Cloud", uniform: "time_speed", label: "Layer 1 Time Speed", min: -1, max: 1, step: 0.01),
        UniformControl(layer: "Cloud", uniform: "stretch", label: "Layer 1 Stretch", min: 0.5, max: 3, step: 0.05),
        UniformControl(layer: "Cloud", uniform: "cloud_curve", label: "Layer 1 Curve", min: 0.5, max: 2, step: 0.05),
        UniformControl(layer: "Cloud", uniform: "light_border_1", label: "Layer 1 Light Border 1", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Cloud", uniform: "light_border_2", label: "Layer 1 Light Border 2", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Cloud", uniform: "size", label: "Layer 1 Noise Scale", min: 1, max: 15, step: 0.1),
        UniformControl(layer: "Cloud", uniform: "OCTAVES", label: "Layer 1 Octaves", min: 1, max: 8, step: 1),
        UniformControl(layer: "Cloud2", uniform: "cloud_cover", label: "Layer 2 Cloud Cover", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Cloud2", uniform: "time_speed", label: "Layer 2 Time Speed", min: -1, max: 1, step: 0.01),
        UniformControl(layer: "Cloud2", uniform: "stretch", label: "Layer 2 Stretch", min: 0.5, max: 3, step: 0.05),
        UniformControl(layer: "Cloud2", uniform: "cloud_curve", label: "Layer 2 Curve", min: 0.5, max: 2, step: 0.05),
        UniformControl(layer: "Cloud2", uniform: "light_border_1", label: "Layer 2 Light Border 1", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Cloud2", uniform: "light_border_2", label: "Layer 2 Light Border 2", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Cloud2", uniform: "size", label: "Layer 2 Noise Scale", min: 1, max: 15, step: 0.1),
        UniformControl(layer: "Cloud2", uniform: "OCTAVES", label: "Layer 2 Octaves", min: 1, max: 8, step: 1),
    ]

    return PlanetConfig(
        id: "gas-planet",
        label: "Gas giant 1",
        relativeScale: 1,
        guiZoom: 1,
        layers: [
            LayerDefinition(
                name: "Cloud",
                shaderPath: "common/clouds.frag",
                uniforms: cloud1Uniforms,
                colors: [ColorBinding(layer: "Cloud", uniform: "colors", slots: 4)]
            ),
            LayerDefinition(
                name: "Cloud2",
                shaderPath: "common/clouds.frag",
                uniforms: cloud2Uniforms,
                colors: [ColorBinding(layer: "Cloud2", uniform: "colors", slots: 4)]
            ),
        ],
        uniformControls: controls
    )
}

private let gasPlanetConfig = makeGasPlanetConfig()

public final class GasPlanetPlanet: PlanetBase, @unchecked Sendable {
    public init() throws {
        try super.init(config: gasPlanetConfig)
    }

    public override func setPixels(_ amount: Int) {
        let value = Float(amount)
        setFloat("Cloud", "pixels", value)
        setFloat("Cloud2", "pixels", value)
    }

    public override func setLight(_ position: SIMD2<Float>) {
        setVec2("Cloud", "light_origin", position)
        setVec2("Cloud2", "light_origin", position)
    }

    public override func setSeed(_ seed: Int, rng: inout RandomStream) {
        let converted = Float(seed % 1000) / 100
        setFloat("Cloud", "seed", converted)
        setFloat("Cloud2", "seed", converted)
        setFloat("Cloud2", "cloud_cover", randRange(&rng, min: 0.28, max: 0.5))
    }

    public override func setRotation(_ radians: Float) {
        setFloat("Cloud", "rotation", radians)
        setFloat("Cloud2", "rotation", radians)
    }

    public override func updateTime(_ t: Float) {
        setFloat("Cloud", "time", t * multiplier(for: "Cloud") * 0.005)
        setFloat("Cloud2", "time", t * multiplier(for: "Cloud2") * 0.005)
    }

    public override func setCustomTime(_ t: Float) {
        setFloat("Cloud", "time", t * multiplier(for: "Cloud"))
        setFloat("Cloud2", "time", t * multiplier(for: "Cloud2"))
    }

    public override func setDither(_ enabled: Bool) {
        // Shader layers do not expose dither toggles.
    }

    public override func isDitherEnabled() -> Bool {
        false
    }

    public override func randomizeColors(rng: inout RandomStream) -> [PixelColor] {
        var palette = generatePalette(
            rng: &rng,
            count: 8 + randInt(&rng, maxExclusive: 4),
            hueDiff: randRange(&rng, min: 0.3, max: 0.8),
            saturation: 1.0
        )
        if palette.count < 8 {
            palette += Array(repeating: PixelColor(r: 0.8, g: 0.5, b: 0.3, a: 1), count: 8 - palette.count)
        }

        var firstLayer: [PixelColor] = []
        for i in 0..<4 {
            let base = palette[i % palette.count]
            var shade = base.darkened(by: Float(i) / 6)
            shade = shade.darkened(by: 0.7)
            firstLayer.append(shade)
        }

        var secondLayer: [PixelColor] = []
        for i in 0..<4 {
            let index = (i + 4) % palette.count
            let base = palette[index]
            var shade = base.darkened(by: Float(i) / 4)
            shade = shade.lightened(by: (1 - Float(i) / 4) * 0.5)
            secondLayer.append(shade)
        }

        let combined = firstLayer + secondLayer
        setColors(combined)
        return combined
    }
}

@MainActor
func registerGasPlanetPlanet(into factories: inout [String: PlanetFactory]) {
    factories["Gas giant 1"] = { try GasPlanetPlanet() }
}

```

`StarO/PixelPlanets/Core/Planets/IceWorldPlanet.swift`:

```swift
import Foundation
import simd

private let iceLandColors: [Float] = [
    0.980392, 1, 1, 1,
    0.780392, 0.831373, 0.882353, 1,
    0.572549, 0.560784, 0.721569, 1,
]

private let iceLakeColors: [Float] = [
    0.309804, 0.643137, 0.721569, 1,
    0.298039, 0.407843, 0.521569, 1,
    0.227451, 0.247059, 0.368627, 1,
]

private let iceCloudColors: [Float] = [
    0.882353, 0.94902, 1, 1,
    0.752941, 0.890196, 1, 1,
    0.368627, 0.439216, 0.647059, 1,
    0.25098, 0.286275, 0.45098, 1,
]

private func makeIceWorldConfig() -> PlanetConfig {
    let landUniforms: [String: UniformValue] = [
        "pixels": .float(100),
        "rotation": .float(0),
        "light_origin": .vec2(Vec2(0.3, 0.3)),
        "time_speed": .float(0.25),
        "dither_size": .float(2),
        "light_border_1": .float(0.48),
        "light_border_2": .float(0.632),
        "colors": .buffer(iceLandColors),
        "size": .float(8),
        "OCTAVES": .float(2),
        "seed": .float(1.036),
        "time": .float(0),
        "should_dither": .float(1),
    ]

    let lakeUniforms: [String: UniformValue] = [
        "pixels": .float(100),
        "rotation": .float(0),
        "light_origin": .vec2(Vec2(0.3, 0.3)),
        "time_speed": .float(0.2),
        "light_border_1": .float(0.024),
        "light_border_2": .float(0.047),
        "lake_cutoff": .float(0.55),
        "colors": .buffer(iceLakeColors),
        "size": .float(10),
        "OCTAVES": .float(3),
        "seed": .float(1.14),
        "time": .float(0),
    ]

    let cloudUniforms: [String: UniformValue] = [
        "pixels": .float(100),
        "rotation": .float(0),
        "cloud_cover": .float(0.546),
        "light_origin": .vec2(Vec2(0.3, 0.3)),
        "time_speed": .float(0.1),
        "stretch": .float(2.5),
        "cloud_curve": .float(1.3),
        "light_border_1": .float(0.566),
        "light_border_2": .float(0.781),
        "colors": .buffer(iceCloudColors),
        "size": .float(4),
        "OCTAVES": .float(4),
        "seed": .float(1.14),
        "time": .float(0),
    ]

    let controls: [UniformControl] = [
        UniformControl(layer: "Land", uniform: "time_speed", label: "Land Time Speed", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Land", uniform: "dither_size", label: "Land Dither Size", min: 0, max: 6, step: 0.1),
        UniformControl(layer: "Land", uniform: "light_border_1", label: "Land Light Border 1", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Land", uniform: "light_border_2", label: "Land Light Border 2", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Land", uniform: "size", label: "Land Noise Scale", min: 1, max: 12, step: 0.1),
        UniformControl(layer: "Land", uniform: "OCTAVES", label: "Land Octaves", min: 1, max: 6, step: 1),
        UniformControl(layer: "Lakes", uniform: "time_speed", label: "Lakes Time Speed", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Lakes", uniform: "light_border_1", label: "Lakes Light Border 1", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Lakes", uniform: "light_border_2", label: "Lakes Light Border 2", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Lakes", uniform: "lake_cutoff", label: "Lake Cutoff", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Lakes", uniform: "size", label: "Lakes Noise Scale", min: 1, max: 12, step: 0.1),
        UniformControl(layer: "Lakes", uniform: "OCTAVES", label: "Lakes Octaves", min: 1, max: 6, step: 1),
        UniformControl(layer: "Clouds", uniform: "cloud_cover", label: "Cloud Cover", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Clouds", uniform: "time_speed", label: "Cloud Time Speed", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Clouds", uniform: "stretch", label: "Cloud Stretch", min: 1, max: 3, step: 0.05),
        UniformControl(layer: "Clouds", uniform: "cloud_curve", label: "Cloud Curve", min: 0.5, max: 2, step: 0.05),
        UniformControl(layer: "Clouds", uniform: "light_border_1", label: "Cloud Light Border 1", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Clouds", uniform: "light_border_2", label: "Cloud Light Border 2", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Clouds", uniform: "size", label: "Cloud Noise Scale", min: 1, max: 10, step: 0.1),
        UniformControl(layer: "Clouds", uniform: "OCTAVES", label: "Cloud Octaves", min: 1, max: 6, step: 1),
    ]

    return PlanetConfig(
        id: "ice-world",
        label: "Ice World",
        relativeScale: 1,
        guiZoom: 1,
        layers: [
            LayerDefinition(
                name: "Land",
                shaderPath: "landmasses/water.frag",
                uniforms: landUniforms,
                colors: [ColorBinding(layer: "Land", uniform: "colors", slots: 3)]
            ),
            LayerDefinition(
                name: "Lakes",
                shaderPath: "ice-world/lakes.frag",
                uniforms: lakeUniforms,
                colors: [ColorBinding(layer: "Lakes", uniform: "colors", slots: 3)]
            ),
            LayerDefinition(
                name: "Clouds",
                shaderPath: "common/clouds.frag",
                uniforms: cloudUniforms,
                colors: [ColorBinding(layer: "Clouds", uniform: "colors", slots: 4)]
            ),
        ],
        uniformControls: controls
    )
}

private let iceWorldConfig = makeIceWorldConfig()

public final class IceWorldPlanet: PlanetBase, @unchecked Sendable {
    public init() throws {
        try super.init(config: iceWorldConfig)
    }

    public override func setPixels(_ amount: Int) {
        let value = Float(amount)
        setFloat("Land", "pixels", value)
        setFloat("Lakes", "pixels", value)
        setFloat("Clouds", "pixels", value)
    }

    public override func setLight(_ position: SIMD2<Float>) {
        setVec2("Land", "light_origin", position)
        setVec2("Lakes", "light_origin", position)
        setVec2("Clouds", "light_origin", position)
    }

    public override func setSeed(_ seed: Int, rng: inout RandomStream) {
        let converted = Float(seed % 1000) / 100
        setFloat("Land", "seed", converted)
        setFloat("Lakes", "seed", converted)
        setFloat("Clouds", "seed", converted)
        setFloat("Clouds", "cloud_cover", randRange(&rng, min: 0.35, max: 0.6))
    }

    public override func setRotation(_ radians: Float) {
        setFloat("Land", "rotation", radians)
        setFloat("Lakes", "rotation", radians)
        setFloat("Clouds", "rotation", radians)
    }

    public override func updateTime(_ t: Float) {
        setFloat("Land", "time", t * multiplier(for: "Land") * 0.02)
        setFloat("Lakes", "time", t * multiplier(for: "Lakes") * 0.02)
        setFloat("Clouds", "time", t * multiplier(for: "Clouds") * 0.01)
    }

    public override func setCustomTime(_ t: Float) {
        setFloat("Land", "time", t * multiplier(for: "Land"))
        setFloat("Lakes", "time", t * multiplier(for: "Lakes"))
        setFloat("Clouds", "time", t * multiplier(for: "Clouds"))
    }

    public override func setDither(_ enabled: Bool) {
        setFloat("Land", "should_dither", enabled ? 1 : 0)
    }

    public override func isDitherEnabled() -> Bool {
        getFloat("Land", "should_dither") > 0.5
    }

    public override func randomizeColors(rng: inout RandomStream) -> [PixelColor] {
        var palette = generatePalette(
            rng: &rng,
            count: 3 + randInt(&rng, maxExclusive: 2),
            hueDiff: randRange(&rng, min: 0.7, max: 1.0),
            saturation: randRange(&rng, min: 0.45, max: 0.55)
        )
        if palette.isEmpty {
            palette = [PixelColor(r: 0.7, g: 0.8, b: 0.9, a: 1)]
        }

        var land: [PixelColor] = []
        let landBase = palette[0]
        for i in 0..<3 {
            let shaded = landBase.darkened(by: Float(i) / 3)
            var hsv = shaded.toHSV()
            hsv.h += 0.2 * (Float(i) / 4)
            land.append(PixelColor.fromHSV(hsv))
        }

        var lakes: [PixelColor] = []
        let lakeBase = palette[min(1, palette.count - 1)]
        for i in 0..<3 {
            let shaded = lakeBase.darkened(by: Float(i) / 3)
            var hsv = shaded.toHSV()
            hsv.h += 0.2 * (Float(i) / 3)
            lakes.append(PixelColor.fromHSV(hsv))
        }

        var clouds: [PixelColor] = []
        let cloudBase = palette[min(2, palette.count - 1)]
        for i in 0..<4 {
            let lightened = cloudBase.lightened(by: (1 - Float(i) / 4) * 0.8)
            var hsv = lightened.toHSV()
            hsv.h += 0.2 * (Float(i) / 4)
            clouds.append(PixelColor.fromHSV(hsv))
        }

        let colors = land + lakes + clouds
        setColors(colors)
        return colors
    }
}

@MainActor
func registerIceWorldPlanet(into factories: inout [String: PlanetFactory]) {
    factories["Ice World"] = { try IceWorldPlanet() }
}

```

`StarO/PixelPlanets/Core/Planets/LandMassesPlanet.swift`:

```swift
import Foundation
import simd

private let waterColorsLandMasses: [Float] = [
    0.572549, 0.909804, 0.752941, 1,
    0.309804, 0.643137, 0.721569, 1,
    0.172549, 0.207843, 0.301961, 1,
]

private let landColorsLandMasses: [Float] = [
    0.784314, 0.831373, 0.364706, 1,
    0.388235, 0.670588, 0.247059, 1,
    0.184314, 0.341176, 0.32549, 1,
    0.156863, 0.207843, 0.25098, 1,
]

private let cloudColorsLandMasses: [Float] = [
    0.87451, 0.878431, 0.909804, 1,
    0.639216, 0.654902, 0.760784, 1,
    0.407843, 0.435294, 0.6, 1,
    0.25098, 0.286275, 0.45098, 1,
]

private func makeLandMassesConfig() -> PlanetConfig {
    let waterUniforms: [String: UniformValue] = [
        "pixels": .float(100),
        "rotation": .float(0),
        "light_origin": .vec2(Vec2(0.39, 0.39)),
        "time_speed": .float(0.1),
        "dither_size": .float(2),
        "light_border_1": .float(0.4),
        "light_border_2": .float(0.6),
        "colors": .buffer(waterColorsLandMasses),
        "size": .float(5.228),
        "OCTAVES": .float(3),
        "seed": .float(10.0),
        "time": .float(0),
        "should_dither": .float(1),
    ]

    let landUniforms: [String: UniformValue] = [
        "pixels": .float(100),
        "rotation": .float(0.2),
        "light_origin": .vec2(Vec2(0.39, 0.39)),
        "time_speed": .float(0.2),
        "dither_size": .float(2),
        "light_border_1": .float(0.32),
        "light_border_2": .float(0.534),
        "land_cutoff": .float(0.633),
        "colors": .buffer(landColorsLandMasses),
        "size": .float(4.292),
        "OCTAVES": .float(6),
        "seed": .float(7.947),
        "time": .float(0),
    ]

    let cloudUniforms: [String: UniformValue] = [
        "pixels": .float(100),
        "rotation": .float(0),
        "cloud_cover": .float(0.415),
        "light_origin": .vec2(Vec2(0.39, 0.39)),
        "time_speed": .float(0.47),
        "stretch": .float(2),
        "cloud_curve": .float(1.3),
        "light_border_1": .float(0.52),
        "light_border_2": .float(0.62),
        "colors": .buffer(cloudColorsLandMasses),
        "size": .float(7.745),
        "OCTAVES": .float(2),
        "seed": .float(5.939),
        "time": .float(0),
    ]

    let controls: [UniformControl] = [
        UniformControl(layer: "Water", uniform: "time_speed", label: "Water Time Speed", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Water", uniform: "light_border_1", label: "Water Light Border 1", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Water", uniform: "light_border_2", label: "Water Light Border 2", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Water", uniform: "size", label: "Water Noise Scale", min: 1, max: 12, step: 0.1),
        UniformControl(layer: "Water", uniform: "OCTAVES", label: "Water Octaves", min: 1, max: 8, step: 1),
        UniformControl(layer: "Land", uniform: "time_speed", label: "Land Time Speed", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Land", uniform: "light_border_1", label: "Land Light Border 1", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Land", uniform: "light_border_2", label: "Land Light Border 2", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Land", uniform: "land_cutoff", label: "Land Cutoff", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Land", uniform: "size", label: "Land Noise Scale", min: 1, max: 12, step: 0.1),
        UniformControl(layer: "Land", uniform: "OCTAVES", label: "Land Octaves", min: 1, max: 8, step: 1),
        UniformControl(layer: "Cloud", uniform: "cloud_cover", label: "Cloud Cover", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Cloud", uniform: "time_speed", label: "Cloud Time Speed", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Cloud", uniform: "stretch", label: "Cloud Stretch", min: 1, max: 3, step: 0.05),
        UniformControl(layer: "Cloud", uniform: "cloud_curve", label: "Cloud Curve", min: 0.5, max: 2, step: 0.05),
        UniformControl(layer: "Cloud", uniform: "light_border_1", label: "Cloud Light Border 1", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Cloud", uniform: "light_border_2", label: "Cloud Light Border 2", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Cloud", uniform: "size", label: "Cloud Noise Scale", min: 1, max: 12, step: 0.1),
        UniformControl(layer: "Cloud", uniform: "OCTAVES", label: "Cloud Octaves", min: 1, max: 6, step: 1),
    ]

    return PlanetConfig(
        id: "landmasses",
        label: "Islands",
        relativeScale: 1,
        guiZoom: 1,
        layers: [
            LayerDefinition(
                name: "Water",
                shaderPath: "landmasses/water.frag",
                uniforms: waterUniforms,
                colors: [ColorBinding(layer: "Water", uniform: "colors", slots: 3)]
            ),
            LayerDefinition(
                name: "Land",
                shaderPath: "landmasses/land.frag",
                uniforms: landUniforms,
                colors: [ColorBinding(layer: "Land", uniform: "colors", slots: 4)]
            ),
            LayerDefinition(
                name: "Cloud",
                shaderPath: "common/clouds.frag",
                uniforms: cloudUniforms,
                colors: [ColorBinding(layer: "Cloud", uniform: "colors", slots: 4)]
            ),
        ],
        uniformControls: controls
    )
}

private let landMassesConfig = makeLandMassesConfig()

public final class LandMassesPlanet: PlanetBase, @unchecked Sendable {
    public init() throws {
        try super.init(config: landMassesConfig)
    }

    public override func setPixels(_ amount: Int) {
        let value = Float(amount)
        setFloat("Water", "pixels", value)
        setFloat("Land", "pixels", value)
        setFloat("Cloud", "pixels", value)
    }

    public override func setLight(_ position: SIMD2<Float>) {
        setVec2("Water", "light_origin", position)
        setVec2("Land", "light_origin", position)
        setVec2("Cloud", "light_origin", position)
    }

    public override func setSeed(_ seed: Int, rng: inout RandomStream) {
        let converted = Float(seed % 1000) / 100
        setFloat("Water", "seed", converted)
        setFloat("Land", "seed", converted)
        setFloat("Cloud", "seed", converted)
        setFloat("Cloud", "cloud_cover", randRange(&rng, min: 0.35, max: 0.6))
    }

    public override func setRotation(_ radians: Float) {
        setFloat("Water", "rotation", radians)
        setFloat("Land", "rotation", radians)
        setFloat("Cloud", "rotation", radians)
    }

    public override func updateTime(_ t: Float) {
        setFloat("Water", "time", t * multiplier(for: "Water") * 0.02)
        setFloat("Land", "time", t * multiplier(for: "Land") * 0.02)
        setFloat("Cloud", "time", t * multiplier(for: "Cloud") * 0.01)
    }

    public override func setCustomTime(_ t: Float) {
        setFloat("Water", "time", t * multiplier(for: "Water"))
        setFloat("Land", "time", t * multiplier(for: "Land"))
        setFloat("Cloud", "time", t * multiplier(for: "Cloud"))
    }

    public override func setDither(_ enabled: Bool) {
        setFloat("Water", "should_dither", enabled ? 1 : 0)
    }

    public override func isDitherEnabled() -> Bool {
        getFloat("Water", "should_dither") > 0.5
    }

    public override func randomizeColors(rng: inout RandomStream) -> [PixelColor] {
        var palette = generatePalette(
            rng: &rng,
            count: 3 + randInt(&rng, maxExclusive: 2),
            hueDiff: randRange(&rng, min: 0.7, max: 1.0),
            saturation: randRange(&rng, min: 0.45, max: 0.55)
        )
        if palette.isEmpty {
            palette = [PixelColor(r: 0.4, g: 0.7, b: 0.6, a: 1)]
        }

        var water: [PixelColor] = []
        let waterBase = palette[1 % palette.count]
        for i in 0..<3 {
            let shaded = waterBase.darkened(by: Float(i) / 5)
            var hsv = shaded.toHSV()
            hsv.h += 0.1 * (Float(i) / 2)
            water.append(PixelColor.fromHSV(hsv))
        }

        var land: [PixelColor] = []
        let landBase = palette[0]
        for i in 0..<4 {
            let shaded = landBase.darkened(by: Float(i) / 4)
            var hsv = shaded.toHSV()
            hsv.h += 0.2 * (Float(i) / 4)
            land.append(PixelColor.fromHSV(hsv))
        }

        var clouds: [PixelColor] = []
        let cloudBase = palette[min(2, palette.count - 1)]
        for i in 0..<4 {
            let lightened = cloudBase.lightened(by: (1 - Float(i) / 4) * 0.8)
            var hsv = lightened.toHSV()
            hsv.h += 0.2 * (Float(i) / 4)
            clouds.append(PixelColor.fromHSV(hsv))
        }

        let combined = water + land + clouds
        setColors(combined)
        return combined
    }
}

@MainActor
func registerLandMassesPlanet(into factories: inout [String: PlanetFactory]) {
    factories["Islands"] = { try LandMassesPlanet() }
}

```

`StarO/PixelPlanets/Core/Planets/LavaWorldPlanet.swift`:

```swift
import Foundation
import simd

private let lavaLandColors: [Float] = [
    0.560784, 0.301961, 0.341176, 1,
    0.321569, 0.2, 0.247059, 1,
    0.239216, 0.160784, 0.211765, 1,
]

private let lavaCraterColors: [Float] = [
    0.321569, 0.2, 0.247059, 1,
    0.239216, 0.160784, 0.211765, 1,
]

private let lavaRiverColors: [Float] = [
    1, 0.537255, 0.2, 1,
    0.901961, 0.270588, 0.223529, 1,
    0.678431, 0.184314, 0.270588, 1,
]

private func makeLavaWorldConfig() -> PlanetConfig {
    let landUniforms: [String: UniformValue] = [
        "pixels": .float(100),
        "rotation": .float(0),
        "light_origin": .vec2(Vec2(0.3, 0.3)),
        "time_speed": .float(0.2),
        "dither_size": .float(2),
        "light_border_1": .float(0.4),
        "light_border_2": .float(0.6),
        "colors": .buffer(lavaLandColors),
        "size": .float(10),
        "OCTAVES": .float(3),
        "seed": .float(1.551),
        "time": .float(0),
        "should_dither": .float(1),
    ]

    let craterUniforms: [String: UniformValue] = [
        "pixels": .float(100),
        "rotation": .float(0),
        "light_origin": .vec2(Vec2(0.3, 0.3)),
        "time_speed": .float(0.2),
        "light_border": .float(0.4),
        "colors": .buffer(lavaCraterColors),
        "size": .float(3.5),
        "seed": .float(1.561),
        "time": .float(0),
    ]

    let lavaUniforms: [String: UniformValue] = [
        "pixels": .float(100),
        "rotation": .float(0),
        "light_origin": .vec2(Vec2(0.3, 0.3)),
        "time_speed": .float(0.2),
        "light_border_1": .float(0.019),
        "light_border_2": .float(0.036),
        "river_cutoff": .float(0.579),
        "colors": .buffer(lavaRiverColors),
        "size": .float(10),
        "OCTAVES": .float(4),
        "seed": .float(2.527),
        "time": .float(0),
    ]

    let controls: [UniformControl] = [
        UniformControl(layer: "Land", uniform: "time_speed", label: "Land Time Speed", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Land", uniform: "dither_size", label: "Land Dither Size", min: 0, max: 6, step: 0.1),
        UniformControl(layer: "Land", uniform: "light_border_1", label: "Land Light Border 1", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Land", uniform: "light_border_2", label: "Land Light Border 2", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Land", uniform: "size", label: "Land Noise Scale", min: 1, max: 15, step: 0.1),
        UniformControl(layer: "Land", uniform: "OCTAVES", label: "Land Octaves", min: 1, max: 6, step: 1),
        UniformControl(layer: "Craters", uniform: "time_speed", label: "Crater Time Speed", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Craters", uniform: "light_border", label: "Crater Light Border", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Craters", uniform: "size", label: "Crater Noise Scale", min: 1, max: 10, step: 0.1),
        UniformControl(layer: "LavaRivers", uniform: "time_speed", label: "Lava Time Speed", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "LavaRivers", uniform: "light_border_1", label: "Lava Light Border 1", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "LavaRivers", uniform: "light_border_2", label: "Lava Light Border 2", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "LavaRivers", uniform: "river_cutoff", label: "Lava Cutoff", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "LavaRivers", uniform: "size", label: "Lava Noise Scale", min: 1, max: 15, step: 0.1),
        UniformControl(layer: "LavaRivers", uniform: "OCTAVES", label: "Lava Octaves", min: 1, max: 6, step: 1),
    ]

    return PlanetConfig(
        id: "lava-world",
        label: "Lava World",
        relativeScale: 1,
        guiZoom: 1,
        layers: [
            LayerDefinition(
                name: "Land",
                shaderPath: "no-atmosphere/ground.frag",
                uniforms: landUniforms,
                colors: [ColorBinding(layer: "Land", uniform: "colors", slots: 3)]
            ),
            LayerDefinition(
                name: "Craters",
                shaderPath: "no-atmosphere/craters.frag",
                uniforms: craterUniforms,
                colors: [ColorBinding(layer: "Craters", uniform: "colors", slots: 2)]
            ),
            LayerDefinition(
                name: "LavaRivers",
                shaderPath: "lava-world/rivers.frag",
                uniforms: lavaUniforms,
                colors: [ColorBinding(layer: "LavaRivers", uniform: "colors", slots: 3)]
            ),
        ],
        uniformControls: controls
    )
}

private let lavaWorldConfig = makeLavaWorldConfig()

public final class LavaWorldPlanet: PlanetBase, @unchecked Sendable {
    public init() throws {
        try super.init(config: lavaWorldConfig)
    }

    public override func setPixels(_ amount: Int) {
        let value = Float(amount)
        setFloat("Land", "pixels", value)
        setFloat("Craters", "pixels", value)
        setFloat("LavaRivers", "pixels", value)
    }

    public override func setLight(_ position: SIMD2<Float>) {
        setVec2("Land", "light_origin", position)
        setVec2("Craters", "light_origin", position)
        setVec2("LavaRivers", "light_origin", position)
    }

    public override func setSeed(_ seed: Int, rng: inout RandomStream) {
        let converted = Float(seed % 1000) / 100
        setFloat("Land", "seed", converted)
        setFloat("Craters", "seed", converted)
        setFloat("LavaRivers", "seed", converted)
    }

    public override func setRotation(_ radians: Float) {
        setFloat("Land", "rotation", radians)
        setFloat("Craters", "rotation", radians)
        setFloat("LavaRivers", "rotation", radians)
    }

    public override func updateTime(_ t: Float) {
        setFloat("Land", "time", t * multiplier(for: "Land") * 0.02)
        setFloat("Craters", "time", t * multiplier(for: "Craters") * 0.02)
        setFloat("LavaRivers", "time", t * multiplier(for: "LavaRivers") * 0.02)
    }

    public override func setCustomTime(_ t: Float) {
        setFloat("Land", "time", t * multiplier(for: "Land"))
        setFloat("Craters", "time", t * multiplier(for: "Craters"))
        setFloat("LavaRivers", "time", t * multiplier(for: "LavaRivers"))
    }

    public override func setDither(_ enabled: Bool) {
        setFloat("Land", "should_dither", enabled ? 1 : 0)
    }

    public override func isDitherEnabled() -> Bool {
        getFloat("Land", "should_dither") > 0.5
    }

    public override func randomizeColors(rng: inout RandomStream) -> [PixelColor] {
        var palette = generatePalette(
            rng: &rng,
            count: (rng.next() < 0.5 ? 2 : 3),
            hueDiff: randRange(&rng, min: 0.6, max: 1.0),
            saturation: randRange(&rng, min: 0.7, max: 0.8)
        )
        if palette.isEmpty {
            palette = [PixelColor(r: 0.9, g: 0.3, b: 0.2, a: 1)]
        }

        var land: [PixelColor] = []
        let landBase = palette[0]
        for i in 0..<3 {
            var shade = landBase.darkened(by: Float(i) / 3)
            var hsv = shade.toHSV()
            hsv.h += 0.2 * (Float(i) / 4)
            shade = PixelColor.fromHSV(hsv)
            land.append(shade)
        }

        var lava: [PixelColor] = []
        let lavaBase = palette[min(1, palette.count - 1)]
        for i in 0..<3 {
            var shade = lavaBase.darkened(by: Float(i) / 3)
            var hsv = shade.toHSV()
            hsv.h += 0.2 * (Float(i) / 3)
            shade = PixelColor.fromHSV(hsv)
            shade = shade.lightened(by: (1 - Float(i) / 3) * 0.5)
            lava.append(shade)
        }

        let colors = land + [land[1], land[2]] + lava
        setColors(colors)
        return colors
    }
}

@MainActor
func registerLavaWorldPlanet(into factories: inout [String: PlanetFactory]) {
    factories["Lava World"] = { try LavaWorldPlanet() }
}

```

`StarO/PixelPlanets/Core/Planets/NoAtmospherePlanet.swift`:

```swift
import Foundation
import simd

private let baseGroundColors: [Float] = [
    0.639216, 0.654902, 0.760784, 1,
    0.298039, 0.407843, 0.521569, 1,
    0.227451, 0.247059, 0.368627, 1,
]

private let baseCraterColors: [Float] = [
    0.298039, 0.407843, 0.521569, 1,
    0.227451, 0.247059, 0.368627, 1,
]

private func makeNoAtmosphereConfig() -> PlanetConfig {
    let groundUniforms: [String: UniformValue] = [
        "pixels": .float(100),
        "rotation": .float(0),
        "light_origin": .vec2(Vec2(0.25, 0.25)),
        "time_speed": .float(0.4),
        "dither_size": .float(2),
        "light_border_1": .float(0.615),
        "light_border_2": .float(0.729),
        "colors": .buffer(baseGroundColors),
        "size": .float(8),
        "OCTAVES": .float(4),
        "seed": .float(1.012),
        "time": .float(0),
        "should_dither": .float(1),
    ]

    let craterUniforms: [String: UniformValue] = [
        "pixels": .float(100),
        "rotation": .float(0),
        "light_origin": .vec2(Vec2(0.25, 0.25)),
        "time_speed": .float(0.001),
        "light_border": .float(0.465),
        "colors": .buffer(baseCraterColors),
        "size": .float(5),
        "seed": .float(4.517),
        "time": .float(0),
    ]

    let controls: [UniformControl] = [
        UniformControl(layer: "Ground", uniform: "time_speed", label: "Ground Time Speed", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Ground", uniform: "dither_size", label: "Ground Dither Size", min: 0, max: 6, step: 0.1),
        UniformControl(layer: "Ground", uniform: "light_border_1", label: "Ground Light Border 1", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Ground", uniform: "light_border_2", label: "Ground Light Border 2", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Ground", uniform: "size", label: "Ground Noise Scale", min: 1, max: 15, step: 0.1),
        UniformControl(layer: "Ground", uniform: "OCTAVES", label: "Ground Octaves", min: 1, max: 8, step: 1),
        UniformControl(layer: "Craters", uniform: "time_speed", label: "Crater Time Speed", min: 0, max: 0.1, step: 0.001),
        UniformControl(layer: "Craters", uniform: "light_border", label: "Crater Light Border", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Craters", uniform: "size", label: "Crater Noise Scale", min: 1, max: 10, step: 0.1),
    ]

    return PlanetConfig(
        id: "no-atmosphere",
        label: "No atmosphere",
        relativeScale: 1,
        guiZoom: 1,
        layers: [
            LayerDefinition(
                name: "Ground",
                shaderPath: "no-atmosphere/ground.frag",
                uniforms: groundUniforms,
                colors: [ColorBinding(layer: "Ground", uniform: "colors", slots: 3)]
            ),
            LayerDefinition(
                name: "Craters",
                shaderPath: "no-atmosphere/craters.frag",
                uniforms: craterUniforms,
                colors: [ColorBinding(layer: "Craters", uniform: "colors", slots: 2)]
            ),
        ],
        uniformControls: controls
    )
}

private let noAtmosphereConfig = makeNoAtmosphereConfig()

public final class NoAtmospherePlanet: PlanetBase, @unchecked Sendable {
    public init() throws {
        try super.init(config: noAtmosphereConfig)
    }

    public override func setPixels(_ amount: Int) {
        let value = Float(amount)
        setFloat("Ground", "pixels", value)
        setFloat("Craters", "pixels", value)
    }

    public override func setLight(_ position: SIMD2<Float>) {
        setVec2("Ground", "light_origin", position)
        setVec2("Craters", "light_origin", position)
    }

    public override func setSeed(_ seed: Int, rng: inout RandomStream) {
        let converted = Float(seed % 1000) / 100
        setFloat("Ground", "seed", converted)
        setFloat("Craters", "seed", converted)
    }

    public override func setRotation(_ radians: Float) {
        setFloat("Ground", "rotation", radians)
        setFloat("Craters", "rotation", radians)
    }

    public override func updateTime(_ t: Float) {
        setFloat("Ground", "time", t * multiplier(for: "Ground") * 0.02)
        setFloat("Craters", "time", t * multiplier(for: "Craters") * 0.02)
    }

    public override func setCustomTime(_ t: Float) {
        setFloat("Ground", "time", t * multiplier(for: "Ground"))
        setFloat("Craters", "time", t * multiplier(for: "Craters"))
    }

    public override func setDither(_ enabled: Bool) {
        setFloat("Ground", "should_dither", enabled ? 1 : 0)
    }

    public override func isDitherEnabled() -> Bool {
        getFloat("Ground", "should_dither") > 0.5
    }

    public override func randomizeColors(rng: inout RandomStream) -> [PixelColor] {
        var palette = generatePalette(
            rng: &rng,
            count: 3 + randInt(&rng, maxExclusive: 2),
            hueDiff: randRange(&rng, min: 0.3, max: 0.6),
            saturation: 0.7
        )
        if palette.count < 3 {
            palette += Array(repeating: PixelColor(r: 0.5, g: 0.5, b: 0.6, a: 1), count: 3 - palette.count)
        }

        var ground: [PixelColor] = []
        for i in 0..<3 {
            let base = palette[i % palette.count]
            let darkened = base.darkened(by: Float(i) / 3)
            ground.append(darkened.lightened(by: (1 - Float(i) / 3) * 0.2))
        }

        let craters: [PixelColor] = [ground[1], ground[2]]
        let combined = ground + craters
        setColors(combined)
        return combined
    }
}

@MainActor
func registerNoAtmospherePlanet(into factories: inout [String: PlanetFactory]) {
    factories["No atmosphere"] = { try NoAtmospherePlanet() }
}

```

`StarO/PixelPlanets/Core/Planets/RiversPlanet.swift`:

```swift
import Foundation
import simd

private let landColors: [Float] = [
    0.388235, 0.670588, 0.247059, 1,
    0.231373, 0.490196, 0.309804, 1,
    0.184314, 0.341176, 0.325490, 1,
    0.156863, 0.207843, 0.250980, 1,
    0.309804, 0.643137, 0.721569, 1,
    0.250980, 0.286275, 0.450980, 1,
]

private let cloudColors: [Float] = [
    0.960784, 1.0, 0.909804, 1,
    0.874510, 0.878431, 0.909804, 1,
    0.407843, 0.435294, 0.600000, 1,
    0.250980, 0.286275, 0.450980, 1,
]

private func normalizedSeed(_ seed: Int) -> Float {
    let remainder = ((seed % 1000) + 1000) % 1000
    let value = Float(remainder) / 100
    return max(value, 0.01)
}

private func makeRiversConfig() -> PlanetConfig {
    let landUniforms: [String: UniformValue] = [
        "pixels": .float(100),
        "rotation": .float(0.2),
        "light_origin": .vec2(Vec2(0.39, 0.39)),
        "time_speed": .float(0.1),
        "dither_size": .float(3.951),
        "should_dither": .float(1),
        "light_border_1": .float(0.287),
        "light_border_2": .float(0.476),
        "river_cutoff": .float(0.368),
        "colors": .buffer(landColors),
        "size": .float(4.6),
        "OCTAVES": .float(6),
        "seed": .float(8.98),
        "time": .float(0),
    ]

    let cloudUniforms: [String: UniformValue] = [
        "pixels": .float(100),
        "rotation": .float(0),
        "cloud_cover": .float(0.47),
        "light_origin": .vec2(Vec2(0.39, 0.39)),
        "time_speed": .float(0.1),
        "stretch": .float(2),
        "cloud_curve": .float(1.3),
        "light_border_1": .float(0.52),
        "light_border_2": .float(0.62),
        "colors": .buffer(cloudColors),
        "size": .float(7.315),
        "OCTAVES": .float(2),
        "seed": .float(5.939),
        "time": .float(0),
    ]

    let landLayer = LayerDefinition(
        name: "Land",
        shaderPath: "rivers/land.frag",
        uniforms: landUniforms,
        colors: [ColorBinding(layer: "Land", uniform: "colors", slots: 6)]
    )

    let cloudLayer = LayerDefinition(
        name: "Cloud",
        shaderPath: "common/clouds.frag",
        uniforms: cloudUniforms,
        colors: [ColorBinding(layer: "Cloud", uniform: "colors", slots: 4)]
    )

    let controls: [UniformControl] = [
        UniformControl(layer: "Land", uniform: "time_speed", label: "Land Time Speed", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Land", uniform: "dither_size", label: "Land Dither Size", min: 0, max: 6, step: 0.1),
        UniformControl(layer: "Land", uniform: "light_border_1", label: "Land Light Border 1", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Land", uniform: "light_border_2", label: "Land Light Border 2", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Land", uniform: "river_cutoff", label: "River Cutoff", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Land", uniform: "size", label: "Land Noise Scale", min: 1, max: 12, step: 0.1),
        UniformControl(layer: "Land", uniform: "OCTAVES", label: "Land Octaves", min: 1, max: 8, step: 1),
        UniformControl(layer: "Cloud", uniform: "cloud_cover", label: "Cloud Cover", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Cloud", uniform: "time_speed", label: "Cloud Time Speed", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Cloud", uniform: "stretch", label: "Cloud Stretch", min: 0.5, max: 3, step: 0.05),
        UniformControl(layer: "Cloud", uniform: "cloud_curve", label: "Cloud Curve", min: 0.5, max: 2, step: 0.05),
        UniformControl(layer: "Cloud", uniform: "light_border_1", label: "Cloud Light Border 1", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Cloud", uniform: "light_border_2", label: "Cloud Light Border 2", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "Cloud", uniform: "size", label: "Cloud Noise Scale", min: 1, max: 12, step: 0.1),
        UniformControl(layer: "Cloud", uniform: "OCTAVES", label: "Cloud Octaves", min: 1, max: 6, step: 1),
    ]

    return PlanetConfig(
        id: "rivers",
        label: "Terran Wet",
        relativeScale: 1,
        guiZoom: 1,
        layers: [landLayer, cloudLayer],
        uniformControls: controls
    )
}

private let riversConfig = makeRiversConfig()

public final class RiversPlanet: PlanetBase, @unchecked Sendable {
    public init() throws {
        try super.init(config: riversConfig)
    }

    public override func setPixels(_ amount: Int) {
        let value = Float(amount)
        setFloat("Land", "pixels", value)
        setFloat("Cloud", "pixels", value)
    }

    public override func setLight(_ position: SIMD2<Float>) {
        setVec2("Land", "light_origin", position)
        setVec2("Cloud", "light_origin", position)
    }

    public override func setSeed(_ seed: Int, rng: inout RandomStream) {
        let converted = normalizedSeed(seed)
        setFloat("Land", "seed", converted)
        setFloat("Cloud", "seed", converted)
        setFloat("Cloud", "cloud_cover", randRange(&rng, min: 0.35, max: 0.6))
    }

    public override func setRotation(_ radians: Float) {
        setFloat("Land", "rotation", radians)
        setFloat("Cloud", "rotation", radians)
    }

    public override func updateTime(_ t: Float) {
        setFloat("Land", "time", t * multiplier(for: "Land") * 0.02)
        setFloat("Cloud", "time", t * multiplier(for: "Cloud") * 0.01)
    }

    public override func setCustomTime(_ t: Float) {
        setFloat("Land", "time", t * multiplier(for: "Land"))
        setFloat("Cloud", "time", t * multiplier(for: "Cloud") * 0.5)
    }

    public override func setDither(_ enabled: Bool) {
        setFloat("Land", "should_dither", enabled ? 1 : 0)
    }

    public override func isDitherEnabled() -> Bool {
        getFloat("Land", "should_dither") > 0.5
    }

    public override func randomizeColors(rng: inout RandomStream) -> [PixelColor] {
        var palette = generatePalette(
            rng: &rng,
            count: 3 + randInt(&rng, maxExclusive: 2),
            hueDiff: randRange(&rng, min: 0.7, max: 1.0),
            saturation: randRange(&rng, min: 0.45, max: 0.55)
        )
        if palette.isEmpty {
            palette = [PixelColor(r: 0.3, g: 0.6, b: 0.8, a: 1)]
        }

        var land: [PixelColor] = []
        let landBase = palette[0]
        for i in 0..<4 {
            let factor = Float(i) / 4
            let shaded = landBase.darkened(by: factor)
            var hsv = shaded.toHSV()
            hsv.h += 0.2 * factor
            land.append(PixelColor.fromHSV(hsv))
        }

        var rivers: [PixelColor] = []
        let riverBase = palette[min(1, palette.count - 1)]
        for i in 0..<2 {
            let factor = Float(i) / 2
            let shaded = riverBase.darkened(by: factor)
            var hsv = shaded.toHSV()
            hsv.h += 0.2 * factor
            rivers.append(PixelColor.fromHSV(hsv))
        }

        var clouds: [PixelColor] = []
        let cloudBase = palette[min(2, palette.count - 1)]
        for i in 0..<4 {
            let factor = Float(i) / 4
            let lightened = cloudBase.lightened(by: (1 - factor) * 0.8)
            var hsv = lightened.toHSV()
            hsv.h += 0.2 * factor
            clouds.append(PixelColor.fromHSV(hsv))
        }

        let colors = land + rivers + clouds
        setColors(colors)
        return colors
    }
}

@MainActor
func registerRiversPlanet(into factories: inout [String: PlanetFactory]) {
    factories["Terran Wet"] = { try RiversPlanet() }
}

```

`StarO/PixelPlanets/Core/Planets/StarPlanet.swift`:

```swift
import Foundation
import simd
private let blobColors: [Float] = [1, 1, 0.894118, 1]

private let starGradientColors: [Float] = [
    0.960784, 1, 0.909804, 1,
    0.466667, 0.839216, 0.756863, 1,
    0.109804, 0.572549, 0.654902, 1,
    0.0117647, 0.243137, 0.368627, 1,
]

private let flareGradientColors: [Float] = [
    0.466667, 0.839216, 0.756863, 1,
    1, 1, 0.894118, 1,
]

private func makeStarConfig() -> PlanetConfig {
    let blobs = LayerDefinition(
        name: "Blobs",
        shaderPath: "star/blobs.frag",
        uniforms: [
            "pixels": .float(200),
            "colors": .buffer(blobColors),
            "time_speed": .float(0.05),
            "time": .float(0),
            "rotation": .float(0),
            "seed": .float(3.078),
            "circle_amount": .float(2),
            "circle_size": .float(1),
            "size": .float(4.93),
            "OCTAVES": .float(4),
        ],
        colors: [ColorBinding(layer: "Blobs", uniform: "colors", slots: 1)]
    )

    let starCore = LayerDefinition(
        name: "Star",
        shaderPath: "star/star.frag",
        uniforms: [
            "pixels": .float(100),
            "time_speed": .float(0.05),
            "time": .float(0),
            "rotation": .float(0),
            "colors": .buffer(starGradientColors),
            "n_colors": .float(4),
            "should_dither": .float(1),
            "seed": .float(4.837),
            "size": .float(4.463),
            "OCTAVES": .float(4),
            "TILES": .float(1),
        ],
        colors: [ColorBinding(layer: "Star", uniform: "colors", slots: 4)]
    )

    let flares = LayerDefinition(
        name: "StarFlares",
        shaderPath: "star/flares.frag",
        uniforms: [
            "pixels": .float(200),
            "colors": .buffer(flareGradientColors),
            "time_speed": .float(0.05),
            "time": .float(0),
            "rotation": .float(0),
            "should_dither": .float(1),
            "storm_width": .float(0.3),
            "storm_dither_width": .float(0),
            "scale": .float(1),
            "seed": .float(3.078),
            "circle_amount": .float(2),
            "circle_scale": .float(1),
            "size": .float(1.6),
            "OCTAVES": .float(4),
        ],
        colors: [ColorBinding(layer: "StarFlares", uniform: "colors", slots: 2)]
    )

    let controls: [UniformControl] = [
        UniformControl(layer: "Blobs", uniform: "time_speed", label: "Blobs Time Speed", min: 0, max: 0.3, step: 0.005),
        UniformControl(layer: "Blobs", uniform: "circle_amount", label: "Blobs Circle Amount", min: 1, max: 6, step: 1),
        UniformControl(layer: "Blobs", uniform: "circle_size", label: "Blobs Circle Size", min: 0.5, max: 2, step: 0.05),
        UniformControl(layer: "Blobs", uniform: "size", label: "Blobs Noise Scale", min: 1, max: 10, step: 0.1),
        UniformControl(layer: "Blobs", uniform: "OCTAVES", label: "Blobs Octaves", min: 1, max: 6, step: 1),
        UniformControl(layer: "Star", uniform: "time_speed", label: "Star Time Speed", min: 0, max: 0.2, step: 0.005),
        UniformControl(layer: "Star", uniform: "n_colors", label: "Star Colors", min: 2, max: 6, step: 1),
        UniformControl(layer: "Star", uniform: "size", label: "Star Noise Scale", min: 1, max: 10, step: 0.1),
        UniformControl(layer: "Star", uniform: "OCTAVES", label: "Star Octaves", min: 1, max: 6, step: 1),
        UniformControl(layer: "Star", uniform: "TILES", label: "Star Tiles", min: 1, max: 4, step: 1),
        UniformControl(layer: "StarFlares", uniform: "time_speed", label: "Flares Time Speed", min: 0, max: 0.3, step: 0.005),
        UniformControl(layer: "StarFlares", uniform: "storm_width", label: "Storm Width", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "StarFlares", uniform: "storm_dither_width", label: "Storm Dither Width", min: 0, max: 1, step: 0.01),
        UniformControl(layer: "StarFlares", uniform: "scale", label: "Flares Scale", min: 0.5, max: 3, step: 0.05),
        UniformControl(layer: "StarFlares", uniform: "circle_amount", label: "Flares Circle Amount", min: 1, max: 6, step: 1),
        UniformControl(layer: "StarFlares", uniform: "circle_scale", label: "Flares Circle Scale", min: 0.5, max: 3, step: 0.05),
        UniformControl(layer: "StarFlares", uniform: "size", label: "Flares Noise Scale", min: 0.5, max: 6, step: 0.1),
        UniformControl(layer: "StarFlares", uniform: "OCTAVES", label: "Flares Octaves", min: 1, max: 6, step: 1),
    ]

    return PlanetConfig(
        id: "star",
        label: "Star",
        relativeScale: 2,
        guiZoom: 2,
        layers: [blobs, starCore, flares],
        uniformControls: controls
    )
}

private let starConfig = makeStarConfig()

public final class StarPlanet: PlanetBase, @unchecked Sendable {
    public init() throws {
        try super.init(config: starConfig)
    }

    public override func setPixels(_ amount: Int) {
        let scaled = Float(amount) * relativeScale
        setFloat("Blobs", "pixels", scaled)
        setFloat("Star", "pixels", Float(amount))
        setFloat("StarFlares", "pixels", scaled)
    }

    public override func setLight(_ position: SIMD2<Float>) {
        // Star shader does not expose light control in original implementation.
    }

    public override func setSeed(_ seed: Int, rng: inout RandomStream) {
        let converted = Float(seed % 1000) / 100
        setFloat("Blobs", "seed", converted)
        setFloat("Star", "seed", converted)
        setFloat("StarFlares", "seed", converted)
    }

    public override func setRotation(_ radians: Float) {
        setFloat("Blobs", "rotation", radians)
        setFloat("Star", "rotation", radians)
        setFloat("StarFlares", "rotation", radians)
    }

    public override func updateTime(_ t: Float) {
        setFloat("Blobs", "time", t * multiplier(for: "Blobs") * 0.01)
        setFloat("Star", "time", t * multiplier(for: "Star") * 0.005)
        setFloat("StarFlares", "time", t * multiplier(for: "StarFlares") * 0.015)
    }

    public override func setCustomTime(_ t: Float) {
        setFloat("Blobs", "time", t * multiplier(for: "Blobs"))
        let speed = max(0.0001, getFloat("Star", "time_speed"))
        setFloat("Star", "time", t * (1.0 / speed))
        setFloat("StarFlares", "time", t * multiplier(for: "StarFlares"))
    }

    public override func setDither(_ enabled: Bool) {
        let value = enabled ? 1 : 0
        setFloat("Star", "should_dither", Float(value))
        setFloat("StarFlares", "should_dither", Float(value))
    }

    public override func isDitherEnabled() -> Bool {
        getFloat("Star", "should_dither") > 0.5
    }

    public override func randomizeColors(rng: inout RandomStream) -> [PixelColor] {
        var palette = generatePalette(
            rng: &rng,
            count: 4,
            hueDiff: randRange(&rng, min: 0.2, max: 0.4),
            saturation: 2.0
        )
        if palette.count < 4 {
            palette += Array(repeating: PixelColor(r: 1, g: 0.8, b: 0.4, a: 1), count: 4 - palette.count)
        }

        var shades: [PixelColor] = []
        for i in 0..<4 {
            var shade = palette[i].darkened(by: Float(i) / 4 * 0.9)
            shade = shade.lightened(by: (1 - Float(i) / 4) * 0.8)
            shades.append(shade)
        }
        shades[0] = shades[0].lightened(by: 0.8)

        let final = [shades[0]] + shades + [shades[1], shades[0]]
        setColors(final)
        return final
    }
}
@MainActor
func registerStarPlanet(into factories: inout [String: PlanetFactory]) {
    factories["Star"] = { try StarPlanet() }
}

// Twinkle star variant removed by product decision.

```

`StarO/PixelPlanets/Core/Random.swift`:

```swift
import Foundation

/// Deterministic pseudo random number generator that mirrors the PCG
/// implementation used by the original Godot shaders and the React port.
public struct RandomStream: Sendable {
    private static let defaultState: UInt64 = 0x853c49e6748fea9b
    private static let multiplier: UInt64 = 6364136223846793005
    private static let increment: UInt64 = 1442695040888963407
    private static let mask: UInt64 = UInt64.max
    private static let scale: Float = 1.0 / 4294967296.0 // 1 / 2^32

    private var state: UInt64

    public init(seed: UInt64) {
        let sanitized = seed & Self.mask
        self.state = sanitized == 0 ? Self.defaultState : sanitized
    }

    public mutating func nextUInt32() -> UInt32 {
        state = (state &* Self.multiplier &+ Self.increment) & Self.mask
        let shifted = ((state >> 18) ^ state) >> 27
        let rot = UInt32(state >> 59)
        let xorshifted = UInt32(truncatingIfNeeded: shifted)
        let shift = Int(rot & 31)
        let complement = (32 - shift) & 31
        return (xorshifted >> shift) | (xorshifted << complement)
    }

    public mutating func next() -> Float {
        let value = nextUInt32()
        return Float(value) * Self.scale
    }

    public mutating func nextRange(min: Float, max: Float) -> Float {
        next() * (max - min) + min
    }

    public mutating func nextInt(_ upperBound: Int) -> Int {
        precondition(upperBound > 0, "Upper bound must be positive")
        return Int(next() * Float(upperBound))
    }
}

public extension RandomStream {
    init(seed: Int) {
        self.init(seed: UInt64(UInt32(bitPattern: Int32(truncatingIfNeeded: seed))))
    }

    mutating func nextBool() -> Bool {
        next() >= 0.5
    }
}

```

`StarO/PixelPlanets/Core/Types.swift`:

```swift
import simd

public typealias Vec2 = SIMD2<Float>
public typealias Vec3 = SIMD3<Float>
public typealias Vec4 = SIMD4<Float>

```

`StarO/PixelPlanets/Core/UniformValue.swift`:

```swift
import Foundation
import simd

public enum UniformValue: Equatable, Sendable {
    case float(Float)
    case vec2(SIMD2<Float>)
    case vec3(SIMD3<Float>)
    case vec4(SIMD4<Float>)
    case buffer([Float])

    public func clone() -> UniformValue {
        switch self {
        case .float, .vec2, .vec3, .vec4:
            return self
        case .buffer(let array):
            return .buffer(Array(array))
        }
    }

    public func asFloat() -> Float? {
        switch self {
        case .float(let value):
            return value
        case .buffer(let array) where array.count == 1:
            return array[0]
        default:
            return nil
        }
    }

    public func asInt() -> Int? {
        guard let value = asFloat() else { return nil }
        return Int(value.rounded())
    }

    public func asVec2() -> SIMD2<Float>? {
        switch self {
        case .vec2(let value):
            return value
        default:
            return nil
        }
    }

    public func asVec3() -> SIMD3<Float>? {
        if case let .vec3(value) = self {
            return value
        }
        return nil
    }

    public func asVec4() -> SIMD4<Float>? {
        if case let .vec4(value) = self {
            return value
        }
        return nil
    }

    public func asBuffer() -> [Float]? {
        if case let .buffer(array) = self {
            return array
        }
        return nil
    }
}

```

`StarO/PixelPlanets/Rendering/PlanetCanvasView.swift`:

```swift
import SwiftUI
import GLKit
import QuartzCore

struct PlanetCanvasView: UIViewRepresentable {
    var planet: PlanetBase
    var pixels: Int
    var playing: Bool
    @Binding var renderError: String?

    func makeUIView(context: Context) -> GLKView {
        let glContext = EAGLContext(api: .openGLES2)!
        let view = GLKView(frame: .zero, context: glContext)
        view.enableSetNeedsDisplay = false
        view.drawableColorFormat = .RGBA8888
        view.drawableDepthFormat = .formatNone
        view.drawableMultisample = .multisampleNone
        view.isOpaque = false
        view.delegate = context.coordinator
        view.layer.magnificationFilter = .nearest
        view.layer.minificationFilter = .nearest

        EAGLContext.setCurrent(glContext)
        context.coordinator.view = view
        context.coordinator.renderer = PlanetGLRenderer(planet: planet)
        context.coordinator.updatePixelDensity(pixels, for: view)
        context.coordinator.setPlaying(playing)
        view.display()
        return view
    }

    func updateUIView(_ uiView: GLKView, context: Context) {
        EAGLContext.setCurrent(uiView.context)
        context.coordinator.parent = self // Update parent reference to access binding
        context.coordinator.updatePlanet(planet)
        context.coordinator.updatePixelDensity(pixels, for: uiView)
        context.coordinator.setPlaying(playing)
        
        // Check for render errors
        if let error = context.coordinator.renderer?.compileError {
            DispatchQueue.main.async {
                self.renderError = error
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    @MainActor
    final class Coordinator: NSObject, GLKViewDelegate {
        var parent: PlanetCanvasView
        var renderer: PlanetGLRenderer?
        weak var view: GLKView?
        var displayLink: CADisplayLink?
        private var lastTimestamp: CFTimeInterval?
        private var isPlaying = false
        private var lastScale: CGFloat = 0
        private var currentPlanet: PlanetBase

        init(_ parent: PlanetCanvasView) {
            self.parent = parent
            self.currentPlanet = parent.planet
        }

        func updatePixelDensity(_ pixels: Int, for view: GLKView) {
            let bounds = view.bounds
            let side = max(1, min(bounds.width, bounds.height))
            
            // Calculate target scale to achieve desired pixel count
            // desired = logical pixels we want the planet to have
            let desired = CGFloat(max(pixels, 1)) * CGFloat(currentPlanet.relativeScale)
            
            // targetScale = how much to scale the backing store to get that many pixels
            let targetScale = max(1, desired / side)
            let maximumScale = UIScreen.main.scale * 4
            let clampedScale = min(targetScale, maximumScale)
            
            if abs(clampedScale - lastScale) > 0.01 {
                // Match original PixelPlanets Swift behavior: only adjust view backing-store scale here.
                // Do NOT mutate planet's `pixels` uniform from here; keep planet defaults or caller-provided value.
                view.contentScaleFactor = clampedScale
                lastScale = clampedScale
                view.display()
            }
        }

        func updatePlanet(_ planet: PlanetBase) {
            currentPlanet = planet
            if renderer == nil {
                renderer = PlanetGLRenderer(planet: planet)
            } else {
                renderer?.setPlanet(planet)
            }
            lastTimestamp = nil
        }

        func setPlaying(_ playing: Bool) {
            if playing == isPlaying { return }
            isPlaying = playing
            if playing {
                lastTimestamp = nil
                startDisplayLink()
            } else {
                stopDisplayLink()
                view?.display()
            }
        }

        nonisolated func glkView(_ view: GLKView, drawIn rect: CGRect) {
            // GLKit guarantees this is called on the main thread
            MainActor.assumeIsolated {
                renderer?.draw(in: view)
            }
        }

        private func startDisplayLink() {
            guard displayLink == nil else { return }
            let link = CADisplayLink(target: self, selector: #selector(step(link:)))
            link.add(to: .main, forMode: .common)
            displayLink = link
        }

        private func stopDisplayLink() {
            if let lastTimestamp, let renderer {
                renderer.pauseAnimation(at: lastTimestamp)
            }
            displayLink?.invalidate()
            displayLink = nil
            lastTimestamp = nil
        }

        @objc private func step(link: CADisplayLink) {
            guard let renderer = renderer else { return }
            lastTimestamp = link.timestamp
            renderer.updateAnimationTime(link.timestamp)
            view?.display()
        }

    }
}

```

`StarO/PixelPlanets/Rendering/PlanetGLRenderer.swift`:

```swift
import Foundation
import GLKit
import OpenGLES

final class PlanetGLRenderer: NSObject {
    private var planet: PlanetBase
    private var programs: [String: ProgramInfo] = [:]
    private var vertexBuffer: GLuint = 0
    // Match original: draw two triangles (6 vertices)
    private let quadVertices: [GLfloat] = [
        -1, -1,
         1, -1,
        -1,  1,
        -1,  1,
         1, -1,
         1,  1,
    ]

    struct ProgramInfo {
        let program: GLuint
        let attribPosition: GLuint
        let uniformLocations: [String: GLint]
        let uniformTypes: [String: GLenum]
    }

    init(planet: PlanetBase) {
        self.planet = planet
        super.init()
        setupBuffers()
        rebuildPrograms()
    }

    // Publicly accessible error for debugging
    private(set) var compileError: String?

    deinit {
        if vertexBuffer != 0 {
            glDeleteBuffers(1, &vertexBuffer)
        }
        programs.values.forEach { info in
            glDeleteProgram(info.program)
        }
    }

    func setPlanet(_ newPlanet: PlanetBase) {
        if planet === newPlanet {
            planet = newPlanet
            return
        }
        planet = newPlanet
        resetAnimationState()
        rebuildPrograms()
    }

    private var elapsedTime: Double = 0
    private var lastTimestamp: CFTimeInterval?

    func updateAnimationTime(_ timestamp: CFTimeInterval) {
        guard !planet.overrideTime else {
            lastTimestamp = nil
            return
        }
        if let previous = lastTimestamp {
            let delta = max(0, timestamp - previous)
            elapsedTime += delta
        }
        lastTimestamp = timestamp
        applyTime(elapsedTime)
    }

    func pauseAnimation(at timestamp: CFTimeInterval) {
        if let previous = lastTimestamp {
            elapsedTime += max(0, timestamp - previous)
        }
        lastTimestamp = nil
        if !planet.overrideTime {
            applyTime(elapsedTime)
        }
    }

    private func resetAnimationState() {
        elapsedTime = 0
        lastTimestamp = nil
        if !planet.overrideTime {
            applyTime(0)
        }
    }

    private func applyTime(_ time: Double) {
        planet.updateTime(Float(time))
    }

    @MainActor
    func draw(in view: GLKView) {
        // Ensure drawable is bound, clear and setup blending (match original)
        view.bindDrawable()
        glDisable(GLenum(GL_DEPTH_TEST))
        glEnable(GLenum(GL_BLEND))
        glBlendFuncSeparate(GLenum(GL_SRC_ALPHA), GLenum(GL_ONE_MINUS_SRC_ALPHA), GLenum(GL_ONE), GLenum(GL_ONE_MINUS_SRC_ALPHA))
        glClearColor(0, 0, 0, 0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))

        let drawableWidth = max(1, GLsizei(view.drawableWidth))
        let drawableHeight = max(1, GLsizei(view.drawableHeight))
        let square = min(drawableWidth, drawableHeight)
        let offsetX: GLsizei = (drawableWidth - square) / 2
        let offsetY: GLsizei = (drawableHeight - square) / 2

        let canvasPixels = Int(square)
        let maxPixels = computeMaxLayerPixels()

        for layer in planet.layers where layer.visible {
            guard let programInfo = programs[layer.name] else { continue }
            glUseProgram(programInfo.program)

            glBindBuffer(GLenum(GL_ARRAY_BUFFER), vertexBuffer)
            glEnableVertexAttribArray(programInfo.attribPosition)
            glVertexAttribPointer(programInfo.attribPosition, 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 0, nil)

            applyUniforms(for: layer, using: programInfo)
            applyViewport(for: layer, canvasPixels: canvasPixels, maxLayerPixels: maxPixels, offsetX: offsetX, offsetY: offsetY)

            glDrawArrays(GLenum(GL_TRIANGLES), 0, 6)
            glDisableVertexAttribArray(programInfo.attribPosition)
        }
    }
}

// MARK: - Program compilation

private extension PlanetGLRenderer {
    func computeMaxLayerPixels() -> Int {
        var maxPixels = 0
        for layer in planet.layers {
            if let value = layer.uniforms["pixels"], case let .float(amount) = value {
                maxPixels = max(maxPixels, Int(abs(amount)))
            }
        }
        return maxPixels
    }

    func applyViewport(for layer: LayerState, canvasPixels: Int, maxLayerPixels: Int, offsetX: GLsizei, offsetY: GLsizei) {
        guard canvasPixels > 0 else { return }
        let layerPixels: Float
        if let uniform = layer.uniforms["pixels"], case let .float(value) = uniform {
            layerPixels = abs(value)
        } else {
            glViewport(offsetX, offsetY, GLsizei(canvasPixels), GLsizei(canvasPixels))
            return
        }

        guard maxLayerPixels > 0 else {
            glViewport(offsetX, offsetY, GLsizei(canvasPixels), GLsizei(canvasPixels))
            return
        }

        let ratio = max(0.01, min(1, layerPixels / Float(maxLayerPixels)))
        let viewportSize = max(1, Int(Float(canvasPixels) * ratio))
        let inset = (canvasPixels - viewportSize) / 2
        let startX = offsetX + GLsizei(inset)
        let startY = offsetY + GLsizei(inset)
        glViewport(startX, startY, GLsizei(viewportSize), GLsizei(viewportSize))
    }

    func setupBuffers() {
        glGenBuffers(1, &vertexBuffer)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), vertexBuffer)
        quadVertices.withUnsafeBytes { rawPtr in
            glBufferData(GLenum(GL_ARRAY_BUFFER), rawPtr.count, rawPtr.baseAddress, GLenum(GL_STATIC_DRAW))
        }
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), 0)
    }

    func rebuildPrograms() {
        programs.values.forEach { info in
            glDeleteProgram(info.program)
        }
        programs.removeAll()
        compileError = nil

        guard let vertexShader = compileShader(type: GLenum(GL_VERTEX_SHADER), source: Self.vertexShaderSource) else {
            if compileError == nil { compileError = "Vertex shader failed to compile" }
            return
        }
        defer { glDeleteShader(vertexShader) }

        for layer in planet.layers {
            guard let fragmentShader = compileShader(type: GLenum(GL_FRAGMENT_SHADER), source: layer.shaderSource) else {
                if compileError == nil { compileError = "Fragment shader for \(layer.name) failed" }
                continue
            }

            guard let program = linkProgram(vertexShader: vertexShader, fragmentShader: fragmentShader) else {
                glDeleteShader(fragmentShader)
                if compileError == nil { compileError = "Link failed for \(layer.name)" }
                continue
            }
            glDeleteShader(fragmentShader)

            let attribPosition = GLuint(glGetAttribLocation(program, "aPosition"))
            let (locations, types) = queryUniforms(program: program)
            
            // Check for missing uniforms
            var missing: [String] = []
            for (name, value) in layer.uniforms {
                // Skip if found
                if locations[name] != nil { continue }
                
                // Handle array uniforms (e.g. colors -> colors[0])
                if case .buffer = value {
                    if locations[name + "[0]"] != nil { continue }
                }
                
                missing.append(name)
            }
            
            if !missing.isEmpty {
                // Note: Some uniforms may be optimized out by GL compiler if unused in shader
                // This is expected and not necessarily an error
                print("[PlanetGLRenderer] Warning: Unused uniforms in \(layer.name): \(missing)")
                // Don't set compileError for unused uniforms, they're benign
            }
            
            programs[layer.name] = ProgramInfo(
                program: program,
                attribPosition: attribPosition,
                uniformLocations: locations,
                uniformTypes: types
            )
        }
    }

    func compileShader(type: GLenum, source: String) -> GLuint? {
        let shader = glCreateShader(type)
        var sourceCString = (source as NSString).utf8String
        var length = GLint(source.utf8.count)
        glShaderSource(shader, 1, &sourceCString, &length)
        glCompileShader(shader)

        var status: GLint = 0
        glGetShaderiv(shader, GLenum(GL_COMPILE_STATUS), &status)
        if status == GL_FALSE {
            var logLength: GLint = 0
            glGetShaderiv(shader, GLenum(GL_INFO_LOG_LENGTH), &logLength)
            if logLength > 0 {
                var log = [GLchar](repeating: 0, count: Int(logLength))
                glGetShaderInfoLog(shader, logLength, &logLength, &log)
                let message = String(cString: log)
                print("Shader compile error: \(message)")
                compileError = "Shader compile error: \(message)"
            }
            glDeleteShader(shader)
            return nil
        }
        return shader
    }

    func linkProgram(vertexShader: GLuint, fragmentShader: GLuint) -> GLuint? {
        let program = glCreateProgram()
        glAttachShader(program, vertexShader)
        glAttachShader(program, fragmentShader)
        glLinkProgram(program)

        var status: GLint = 0
        glGetProgramiv(program, GLenum(GL_LINK_STATUS), &status)
        if status == GL_FALSE {
            var logLength: GLint = 0
            glGetProgramiv(program, GLenum(GL_INFO_LOG_LENGTH), &logLength)
            if logLength > 0 {
                var log = [GLchar](repeating: 0, count: Int(logLength))
                glGetProgramInfoLog(program, logLength, &logLength, &log)
                let message = String(cString: log)
                print("Program link error: \(message)")
                compileError = "Program link error: \(message)"
            }
            glDeleteProgram(program)
            return nil
        }
        return program
    }

    func queryUniforms(program: GLuint) -> ([String: GLint], [String: GLenum]) {
        var count: GLint = 0
        glGetProgramiv(program, GLenum(GL_ACTIVE_UNIFORMS), &count)

        var maxLength: GLint = 0
        glGetProgramiv(program, GLenum(GL_ACTIVE_UNIFORM_MAX_LENGTH), &maxLength)

        var locations: [String: GLint] = [:]
        var types: [String: GLenum] = [:]
        var nameBuffer = [GLchar](repeating: 0, count: Int(maxLength))

        for index in 0..<count {
            var size: GLint = 0
            var type: GLenum = 0
            var length: GLsizei = 0
            glGetActiveUniform(program, GLuint(index), GLsizei(maxLength), &length, &size, &type, &nameBuffer)
            let rawName = String(cString: nameBuffer)
            let name = rawName.replacingOccurrences(of: "[0]", with: "")
            let location = glGetUniformLocation(program, name)
            if location >= 0 {
                locations[name] = location
                types[name] = type
            } else {
                print("[PlanetGLRenderer] Warning: Uniform '\(name)' not found in program.")
            }
        }
        return (locations, types)
    }
}

// MARK: - Drawing helpers

private extension PlanetGLRenderer {
    func applyUniforms(for layer: LayerState, using program: ProgramInfo) {
        for (name, uniformValue) in layer.uniforms {
            var targetLocation = program.uniformLocations[name]
            var targetType = program.uniformTypes[name]

            if targetLocation == nil, case .buffer = uniformValue {
                let arrayName = name + "[0]"
                let arrayLocation = glGetUniformLocation(program.program, arrayName)
                if arrayLocation >= 0 {
                    targetLocation = arrayLocation
                    targetType = GLenum(GL_FLOAT_VEC4)
                }
            }

            guard let location = targetLocation else {
                continue
            }

            let type = targetType ?? GLenum(GL_FLOAT)
            setUniform(type: type, location: location, value: uniformValue)
        }
    }

    func setUniform(type: GLenum, location: GLint, value: UniformValue) {
        switch value {
        case .float(let scalar):
            glUniform1f(location, scalar)
        case .vec2(let vector):
            glUniform2f(location, vector.x, vector.y)
        case .vec3(let vector):
            glUniform3f(location, vector.x, vector.y, vector.z)
        case .vec4(let vector):
            glUniform4f(location, vector.x, vector.y, vector.z, vector.w)
        case .buffer(let buffer):
            buffer.withUnsafeBufferPointer { pointer in
                guard let base = pointer.baseAddress else { return }
                switch type {
                case GLenum(GL_FLOAT_VEC4):
                    glUniform4fv(location, GLsizei(buffer.count / 4), base)
                case GLenum(GL_FLOAT_VEC3):
                    glUniform3fv(location, GLsizei(buffer.count / 3), base)
                case GLenum(GL_FLOAT_VEC2):
                    glUniform2fv(location, GLsizei(buffer.count / 2), base)
                default:
                    glUniform1fv(location, GLsizei(buffer.count), base)
                }
            }
        }
    }
}

private extension PlanetGLRenderer {
    static let vertexShaderSource = """
    attribute vec2 aPosition;
    varying vec2 vUV;
    void main() {
        vUV = aPosition * 0.5 + 0.5;
        gl_Position = vec4(aPosition, 0.0, 1.0);
    }
    """
}

```

`StarO/PixelPlanets/Resources/Shaders/asteroid/asteroid.frag`:

```frag
precision mediump float;

uniform float pixels;
uniform float rotation;
uniform vec2 light_origin;
uniform float time_speed;
uniform vec4 colors[3];
uniform float size;
uniform float octaves;
uniform float seed;
uniform float should_dither;

varying vec2 vUV;

float rand(vec2 coord) {
  return fract(sin(dot(coord.xy, vec2(12.9898, 78.233))) * 15.5453 * seed);
}

float noise(vec2 coord) {
  vec2 i = floor(coord);
  vec2 f = fract(coord);

  float a = rand(i);
  float b = rand(i + vec2(1.0, 0.0));
  float c = rand(i + vec2(0.0, 1.0));
  float d = rand(i + vec2(1.0, 1.0));

  vec2 cubic = f * f * (3.0 - 2.0 * f);

  return mix(a, b, cubic.x) +
    (c - a) * cubic.y * (1.0 - cubic.x) +
    (d - b) * cubic.x * cubic.y;
}

float fbm(vec2 coord) {
  float value = 0.0;
  float scale = 0.5;

  for (int i = 0; i < 12; i++) {
    if (float(i) >= octaves) break;
    value += noise(coord) * scale;
    coord *= 2.0;
    scale *= 0.5;
  }
  return value;
}

float dither(vec2 uv1, vec2 uv2) {
  return mod(uv1.x + uv2.y, 2.0 / pixels) <= 1.0 / pixels ? 1.0 : 0.0;
}

vec2 rotate(vec2 coord, float angle) {
  coord -= 0.5;
  float c = cos(angle);
  float s = sin(angle);
  coord *= mat2(vec2(c, -s), vec2(s, c));
  return coord + 0.5;
}

float circleNoise(vec2 uv) {
  float uvY = floor(uv.y);
  uv.x += uvY * 0.31;
  vec2 f = fract(uv);
  float h = rand(vec2(floor(uv.x), floor(uvY)));
  float m = length(f - 0.25 - (h * 0.5));
  float r = h * 0.25;
  return smoothstep(r - 0.10 * r, r, m);
}

float crater(vec2 uv) {
  float c = 1.0;
  for (int i = 0; i < 2; i++) {
    c *= circleNoise((uv * size) + (float(i + 1) + 10.0));
  }
  return 1.0 - c;
}

void main() {
  vec2 uv = floor(vUV * pixels) / pixels;
  float dith = dither(uv, vUV);

  float d = distance(uv, vec2(0.5));
  uv = rotate(uv, rotation);

  float n = fbm(uv * size);
  float n2 = fbm(uv * size + (rotate(light_origin, rotation) - 0.5) * 0.5);

  float nStep = step(0.2, n - d);
  float n2Step = step(0.2, n2 - d);

  float noiseRel = (n2Step + n2) - (nStep + n);

  float c1 = crater(uv);
  float c2 = crater(uv + (light_origin - 0.5) * 0.03);

  vec4 col = colors[1];

  if (noiseRel < -0.06 || (noiseRel < -0.04 && (dith > 0.5 || should_dither < 0.5))) {
    col = colors[0];
  }
  if (noiseRel > 0.05 || (noiseRel > 0.03 && (dith > 0.5 || should_dither < 0.5))) {
    col = colors[2];
  }

  if (c1 > 0.4) {
    col = colors[1];
  }
  if (c2 < c1) {
    col = colors[2];
  }

  gl_FragColor = vec4(col.rgb, nStep * col.a);
}

```

`StarO/PixelPlanets/Resources/Shaders/black-hole/core.frag`:

```frag
precision mediump float;

uniform float pixels;
uniform vec4 colors[3];
uniform float radius;
uniform float light_width;

varying vec2 vUV;

void main() {
  vec2 uv = floor(vUV * pixels) / pixels;
  float distCenter = distance(uv, vec2(0.5));

  vec4 col = colors[0];
  if (distCenter > radius - light_width) {
    col = colors[1];
  }
  if (distCenter > radius - light_width * 0.5) {
    col = colors[2];
  }

  float alpha = step(distCenter, radius);
  gl_FragColor = vec4(col.rgb, alpha * col.a);
}

```

`StarO/PixelPlanets/Resources/Shaders/black-hole/ring.frag`:

```frag
precision mediump float;

uniform float pixels;
uniform float rotation;
uniform vec2 light_origin;
uniform float time_speed;
uniform float disk_width;
uniform float ring_perspective;
uniform float should_dither;
uniform vec4 colors[5];
uniform float n_colors;
uniform float size;
uniform float OCTAVES;
uniform float seed;
uniform float time;

varying vec2 vUV;

float rand(vec2 coord) {
  vec2 wrapped = mod(coord, vec2(2.0, 1.0) * floor(size + 0.5));
  return fract(sin(dot(wrapped.xy, vec2(12.9898, 78.233))) * 15.5453 * seed);
}

float noise(vec2 coord) {
  vec2 i = floor(coord);
  vec2 f = fract(coord);

  float a = rand(i);
  float b = rand(i + vec2(1.0, 0.0));
  float c = rand(i + vec2(0.0, 1.0));
  float d = rand(i + vec2(1.0, 1.0));

  vec2 cubic = f * f * (3.0 - 2.0 * f);

  return mix(a, b, cubic.x) +
    (c - a) * cubic.y * (1.0 - cubic.x) +
    (d - b) * cubic.x * cubic.y;
}

float fbm(vec2 coord) {
  float value = 0.0;
  float scale = 0.5;

  for (int i = 0; i < 12; i++) {
    if (float(i) >= OCTAVES) break;
    value += noise(coord) * scale;
    coord *= 2.0;
    scale *= 0.5;
  }
  return value;
}

float dither(vec2 uvPixel, vec2 uvReal) {
  return mod(uvPixel.x + uvReal.y, 2.0 / pixels) <= 1.0 / pixels ? 1.0 : 0.0;
}

vec2 rotateVec(vec2 coord, float angle) {
  coord -= 0.5;
  float c = cos(angle);
  float s = sin(angle);
  coord *= mat2(vec2(c, -s), vec2(s, c));
  return coord + 0.5;
}

void main() {
  vec2 uv = floor(vUV * pixels) / pixels;
  float dith = dither(uv, vUV);

  uv = rotateVec(uv, rotation);
  vec2 uvOriginal = uv;

  uv.x = (uv.x - 0.5) * 1.3 + 0.5;
  uv = rotateVec(uv, sin(time * time_speed * 2.0) * 0.01);

  vec2 lOrigin = vec2(0.5);
  float width = disk_width;

  if (uv.y < 0.5) {
    float dist = distance(vec2(0.5), uv);
    uv.y += smoothstep(dist, 0.5, 0.2);
    width += smoothstep(dist, 0.5, 0.3);
    lOrigin.y -= smoothstep(dist, 0.5, 0.2);
  } else if (uv.y > 0.53) {
    float dist = distance(vec2(0.5), uv);
    uv.y -= smoothstep(dist, 0.4, 0.17);
    width += smoothstep(dist, 0.5, 0.2);
    lOrigin.y += smoothstep(dist, 0.5, 0.2);
  }

  float lightD = distance(uvOriginal * vec2(1.0, ring_perspective), lOrigin * vec2(1.0, ring_perspective)) * 0.3;

  vec2 uvCenter = uv - vec2(0.0, 0.5);
  uvCenter *= vec2(1.0, ring_perspective);
  float centerDist = distance(uvCenter, vec2(0.5, 0.0));

  float disk = smoothstep(0.1 - width * 2.0, 0.5 - width, centerDist);
  disk *= smoothstep(centerDist - width, centerDist, 0.4);

  uvCenter = rotateVec(uvCenter + vec2(0.0, 0.5), time * time_speed * 3.0);
  disk *= pow(fbm(uvCenter * size), 0.5);

  if (dith > 0.5 || should_dither < 0.5) {
    disk *= 1.2;
  }

  float posterized = floor((disk + lightD) * (n_colors - 1.0));
  posterized = min(posterized, n_colors - 1.0);
  int idx = int(posterized);
  vec4 col = colors[0];
  if (idx <= 0) {
    col = colors[0];
  } else if (idx == 1) {
    col = colors[1];
  } else if (idx == 2) {
    col = colors[2];
  } else if (idx == 3) {
    col = colors[3];
  } else {
    col = colors[4];
  }

  float diskAlpha = step(0.15, disk);
  gl_FragColor = vec4(col.rgb, diskAlpha * col.a);
}

```

`StarO/PixelPlanets/Resources/Shaders/common/clouds.frag`:

```frag
precision highp float;
precision highp int;

uniform float pixels;
uniform float rotation;
uniform float cloud_cover;
uniform vec2 light_origin;
uniform float time_speed;
uniform float stretch;
uniform float cloud_curve;
uniform float light_border_1;
uniform float light_border_2;
uniform vec4 colors[4];
uniform float size;
uniform float OCTAVES;
uniform float seed;
uniform float time;

varying vec2 vUV;

float rand(vec2 coord) {
  vec2 wrapped = mod(coord, vec2(1.0, 1.0) * floor(size + 0.5));
  return fract(sin(dot(wrapped.xy, vec2(12.9898, 78.233))) * 15.5453 * seed);
}

float noise(vec2 coord) {
  vec2 i = floor(coord);
  vec2 f = fract(coord);

  float a = rand(i);
  float b = rand(i + vec2(1.0, 0.0));
  float c = rand(i + vec2(0.0, 1.0));
  float d = rand(i + vec2(1.0, 1.0));

  vec2 cubic = f * f * (3.0 - 2.0 * f);

  return mix(a, b, cubic.x) +
    (c - a) * cubic.y * (1.0 - cubic.x) +
    (d - b) * cubic.x * cubic.y;
}

float fbm(vec2 coord) {
  float value = 0.0;
  float scale = 0.5;

  for (int i = 0; i < 12; i++) {
    if (float(i) >= OCTAVES) break;
    value += noise(coord) * scale;
    coord *= 2.0;
    scale *= 0.5;
  }
  return value;
}

float circleNoise(vec2 uv) {
  float uvY = floor(uv.y);
  uv.x += uvY * 0.31;
  vec2 f = fract(uv);
  float h = rand(vec2(floor(uv.x), floor(uvY)));
  float m = length(f - 0.25 - (h * 0.5));
  float r = h * 0.25;
  return smoothstep(0.0, r, m * 0.75);
}

float cloudAlpha(vec2 uv) {
  float cNoise = 0.0;
  for (int i = 0; i < 9; i++) {
    cNoise += circleNoise((uv * size * 0.3) + (float(i + 1) + 10.0) + vec2(time * time_speed, 0.0));
  }
  return fbm(uv * size + cNoise + vec2(time * time_speed, 0.0));
}

vec2 spherify(vec2 uv) {
  vec2 centered = uv * 2.0 - 1.0;
  float z = sqrt(max(0.0, 1.0 - dot(centered.xy, centered.xy)));
  vec2 sphere = centered / (z + 1.0);
  return sphere * 0.5 + 0.5;
}

vec2 rotate(vec2 coord, float angle) {
  coord -= 0.5;
  float c = cos(angle);
  float s = sin(angle);
  coord *= mat2(vec2(c, -s), vec2(s, c));
  return coord + 0.5;
}

void main() {
  vec2 uv = floor(vUV * pixels) / pixels;

  float dLight = distance(uv, light_origin);
  float alphaCircle = step(length(uv - vec2(0.5)), 0.49999);
  float centerDist = distance(uv, vec2(0.5));

  uv = rotate(uv, rotation);
  uv = spherify(uv);
  uv.y += smoothstep(0.0, cloud_curve, abs(uv.x - 0.4));

  float c = cloudAlpha(uv * vec2(1.0, stretch));

  vec4 col = colors[0];
  if (c < cloud_cover + 0.03) {
    col = colors[1];
  }
  if (dLight + c * 0.2 > light_border_1) {
    col = colors[2];
  }
  if (dLight + c * 0.2 > light_border_2) {
    col = colors[3];
  }

  c *= step(centerDist, 0.5);

  gl_FragColor = vec4(col.rgb, step(cloud_cover, c) * alphaCircle * col.a);
}

```

`StarO/PixelPlanets/Resources/Shaders/dry-terran/land.frag`:

```frag
precision highp float;
precision highp int;

uniform float pixels;
uniform float rotation;
uniform vec2 light_origin;
uniform float light_distance1;
uniform float light_distance2;
uniform float time_speed;
uniform float dither_size;
uniform vec4 colors[5];
uniform float n_colors;
uniform float size;
uniform float OCTAVES;
uniform float seed;
uniform float time;
uniform float should_dither;

varying vec2 vUV;

float rand(vec2 coord) {
  vec2 wrapped = mod(coord, vec2(2.0, 1.0) * floor(size + 0.5));
  return fract(sin(dot(wrapped.xy, vec2(12.9898, 78.233))) * 43758.5453 * seed);
}

float noise(vec2 coord) {
  vec2 i = floor(coord);
  vec2 f = fract(coord);

  float a = rand(i);
  float b = rand(i + vec2(1.0, 0.0));
  float c = rand(i + vec2(0.0, 1.0));
  float d = rand(i + vec2(1.0, 1.0));

  vec2 cubic = f * f * (3.0 - 2.0 * f);

  return mix(a, b, cubic.x) +
    (c - a) * cubic.y * (1.0 - cubic.x) +
    (d - b) * cubic.x * cubic.y;
}

float fbm(vec2 coord) {
  float value = 0.0;
  float scale = 0.5;

  for (int i = 0; i < 12; i++) {
    if (float(i) >= OCTAVES) break;
    value += noise(coord) * scale;
    coord *= 2.0;
    scale *= 0.5;
  }
  return value;
}

float dither(vec2 uv1, vec2 uv2) {
  return mod(uv1.x + uv2.y, 2.0 / pixels) <= 1.0 / pixels ? 1.0 : 0.0;
}

vec2 rotate(vec2 coord, float angle) {
  coord -= 0.5;
  float c = cos(angle);
  float s = sin(angle);
  coord *= mat2(vec2(c, -s), vec2(s, c));
  return coord + 0.5;
}

vec2 spherify(vec2 uv) {
  vec2 centered = uv * 2.0 - 1.0;
  float z = sqrt(max(0.0, 1.0 - dot(centered.xy, centered.xy)));
  vec2 sphere = centered / (z + 1.0);
  return sphere * 0.5 + 0.5;
}

void main() {
  vec2 uv = floor(vUV * pixels) / pixels;
  float dith = dither(uv, vUV);

  float dCircle = distance(uv, vec2(0.5));
  float alpha = step(dCircle, 0.49999);

  uv = spherify(uv);
  float dLight = distance(uv, light_origin);

  uv = rotate(uv, rotation);

  float f = fbm(uv * size + vec2(time * time_speed, 0.0));

  dLight = smoothstep(-0.3, 1.2, dLight);

  if (dLight < light_distance1) {
    dLight *= 0.9;
  }
  if (dLight < light_distance2) {
    dLight *= 0.9;
  }

  float c = dLight * pow(f, 0.8) * 3.5;

  if (dith > 0.5 || should_dither < 0.5) {
    c += 0.02;
    c *= 1.05;
  }

  float posterize = floor(c * 4.0) / 4.0;
  posterize = min(posterize, 1.0);
  int index = int(posterize * (n_colors - 1.0));
  vec4 col = colors[0];
  if (index <= 0) {
    col = colors[0];
  } else if (index == 1) {
    col = colors[1];
  } else if (index == 2) {
    col = colors[2];
  } else if (index == 3) {
    col = colors[3];
  } else {
    col = colors[4];
  }

  gl_FragColor = vec4(col.rgb, alpha * col.a);
}

```

`StarO/PixelPlanets/Resources/Shaders/galaxy/galaxy.frag`:

```frag
precision mediump float;

uniform float pixels;
uniform float rotation;
uniform float time_speed;
uniform float dither_size;
uniform float should_dither;
uniform vec4 colors[7];
uniform float n_colors;
uniform float size;
uniform float OCTAVES;
uniform float seed;
uniform float time;
uniform float tilt;
uniform float n_layers;
uniform float layer_height;
uniform float zoom;
uniform float swirl;

varying vec2 vUV;

float rand(vec2 coord) {
  return fract(sin(dot(coord.xy, vec2(12.9898, 78.233))) * 15.5453 * seed);
}

float noise(vec2 coord) {
  vec2 i = floor(coord);
  vec2 f = fract(coord);

  float a = rand(i);
  float b = rand(i + vec2(1.0, 0.0));
  float c = rand(i + vec2(0.0, 1.0));
  float d = rand(i + vec2(1.0, 1.0));

  vec2 cubic = f * f * (3.0 - 2.0 * f);

  return mix(a, b, cubic.x) +
    (c - a) * cubic.y * (1.0 - cubic.x) +
    (d - b) * cubic.x * cubic.y;
}

float fbm(vec2 coord) {
  float value = 0.0;
  float scale = 0.5;

  for (int i = 0; i < 12; i++) {
    if (float(i) >= OCTAVES) break;
    value += noise(coord) * scale;
    coord *= 2.0;
    scale *= 0.5;
  }
  return value;
}

vec2 rotateVec(vec2 coord, float angle) {
  coord -= 0.5;
  float c = cos(angle);
  float s = sin(angle);
  coord *= mat2(vec2(c, -s), vec2(s, c));
  return coord + 0.5;
}

float dither(vec2 uv1, vec2 uv2) {
  return mod(uv1.x + uv2.y, 2.0 / pixels) <= 1.0 / pixels ? 1.0 : 0.0;
}

void main() {
  vec2 pixelUV = floor(vUV * pixels) / pixels;
  float dith = dither(pixelUV, vUV);

  vec2 uv = pixelUV * zoom;
  uv -= (zoom - 1.0) / 2.0;

  uv = rotateVec(uv, rotation);
  vec2 uvCopy = uv;

  uv.y *= tilt;
  uv.y -= (tilt - 1.0) / 2.0;

  float distCenter = distance(uv, vec2(0.5));
  float rot = swirl * pow(distCenter, 0.4);
  vec2 rotated = rotateVec(uv, rot + time * time_speed);

  float f1 = fbm(rotated * size);
  f1 = floor(f1 * n_layers) / n_layers;

  uvCopy.y *= tilt;
  uvCopy.y -= (tilt - 1.0) / 2.0 + f1 * layer_height;

  float distCenter2 = distance(uvCopy, vec2(0.5));
  float rot2 = swirl * pow(distCenter2, 0.4);
  vec2 rotated2 = rotateVec(uvCopy, rot2 + time * time_speed);
  float f2 = fbm(rotated2 * size + vec2(f1) * 10.0);

  float alpha = step(f2 + distCenter2, 0.7);

  f2 *= 2.3;
  if (should_dither > 0.5 && dith > 0.5) {
    f2 *= 0.94;
  }

  float index = floor(f2 * n_colors);
  index = min(index, n_colors);
  int idx = int(index);
  vec4 col = colors[0];
  if (idx <= 0) {
    col = colors[0];
  } else if (idx == 1) {
    col = colors[1];
  } else if (idx == 2) {
    col = colors[2];
  } else if (idx == 3) {
    col = colors[3];
  } else if (idx == 4) {
    col = colors[4];
  } else if (idx == 5) {
    col = colors[5];
  } else {
    col = colors[6];
  }

  gl_FragColor = vec4(col.rgb, alpha * col.a);
}

```

`StarO/PixelPlanets/Resources/Shaders/galaxy/linear_twinkle.frag`:

```frag
precision highp float;
precision highp int;

uniform float pixels;
uniform float time;
uniform float time_speed;
uniform float morph_speed;
uniform float branch_count;
uniform float branch_sharpness;
uniform float halo_softness;
uniform float spark_scale;
uniform float rotation_speed;
uniform float flicker_strength;
uniform vec4 colors[7];
uniform float n_colors;

varying vec2 vUV;

float hash(vec2 coord) {
  return fract(sin(dot(coord, vec2(12.9898, 78.233))) * 43758.5453123);
}

vec4 fetchColor(float index) {
  int idx = int(clamp(index, 0.0, n_colors - 1.0));
  vec4 col = colors[0];
  if (idx == 1) col = colors[1];
  else if (idx == 2) col = colors[2];
  else if (idx == 3) col = colors[3];
  else if (idx == 4) col = colors[4];
  else if (idx == 5) col = colors[5];
  else if (idx >= 6) col = colors[6];
  return col;
}

void main() {
  vec2 center = vec2(0.5);
  vec2 offset = vUV - center;
  float dist = length(offset);
  if (dist > 0.5) discard;

  float phase = fract(time * morph_speed);
  float grow = smoothstep(0.0, 0.3, phase);
  float shrink = smoothstep(1.0, 0.7, phase);
  float envelope = min(grow, shrink);

  float coreRadius = mix(0.02, spark_scale * 0.15, envelope);
  float halo = smoothstep(coreRadius + halo_softness, coreRadius, dist);

  float arms = clamp(branch_count, 2.0, 10.0);
  float angle = atan(offset.y, offset.x) + rotation_speed * phase * 6.28318;
  float ray = pow(max(0.0, cos(angle * arms)), branch_sharpness);
  ray *= smoothstep(0.5, coreRadius * 0.6, dist);

  float flicker = 0.5 + 0.5 * sin(time * time_speed * 2.5 + hash(floor(vUV * pixels * 2.0)) * 6.28318);
  float intensity = clamp(halo + ray * (0.6 + flicker * flicker_strength), 0.0, 1.0);

  vec4 col = fetchColor(intensity * (n_colors - 1.0));
  gl_FragColor = vec4(col.rgb, col.a * intensity);
}

```

`StarO/PixelPlanets/Resources/Shaders/gas-planet-layers/layers.frag`:

```frag
precision mediump float;

uniform float pixels;
uniform float rotation;
uniform float cloud_cover;
uniform vec2 light_origin;
uniform float time_speed;
uniform float stretch;
uniform float cloud_curve;
uniform float light_border_1;
uniform float light_border_2;
uniform float bands;
uniform float should_dither;
uniform float n_colors;
uniform vec4 colors[3];
uniform vec4 dark_colors[3];
uniform float size;
uniform float OCTAVES;
uniform float seed;
uniform float time;

varying vec2 vUV;

float rand(vec2 coord) {
  vec2 wrapped = mod(coord, vec2(2.0, 1.0) * floor(size + 0.5));
  return fract(sin(dot(wrapped.xy, vec2(12.9898, 78.233))) * 15.5453 * seed);
}

float noise(vec2 coord) {
  vec2 i = floor(coord);
  vec2 f = fract(coord);

  float a = rand(i);
  float b = rand(i + vec2(1.0, 0.0));
  float c = rand(i + vec2(0.0, 1.0));
  float d = rand(i + vec2(1.0, 1.0));

  vec2 cubic = f * f * (3.0 - 2.0 * f);

  return mix(a, b, cubic.x) +
    (c - a) * cubic.y * (1.0 - cubic.x) +
    (d - b) * cubic.x * cubic.y;
}

float fbm(vec2 coord) {
  float value = 0.0;
  float scale = 0.5;

  for (int i = 0; i < 12; i++) {
    if (float(i) >= OCTAVES) break;
    value += noise(coord) * scale;
    coord *= 2.0;
    scale *= 0.5;
  }
  return value;
}

float circleNoise(vec2 uv) {
  float uvY = floor(uv.y);
  uv.x += uvY * 0.31;
  vec2 f = fract(uv);
  float h = rand(vec2(floor(uv.x), floor(uvY)));
  float m = length(f - 0.25 - (h * 0.5));
  float r = h * 0.25;
  return smoothstep(0.0, r, m * 0.75);
}

float turbulence(vec2 uv) {
  float cNoise = 0.0;
  for (int i = 0; i < 10; i++) {
    cNoise += circleNoise((uv * size * 0.3) + (float(i + 1) + 10.0) + vec2(time * time_speed, 0.0));
  }
  return cNoise;
}

float dither(vec2 uvPixel, vec2 uvReal) {
  return mod(uvPixel.x + uvReal.y, 2.0 / pixels) <= 1.0 / pixels ? 1.0 : 0.0;
}

vec2 spherify(vec2 uv) {
  vec2 centered = uv * 2.0 - 1.0;
  float z = sqrt(max(0.0, 1.0 - dot(centered.xy, centered.xy)));
  vec2 sphere = centered / (z + 1.0);
  return sphere * 0.5 + 0.5;
}

vec2 rotate(vec2 coord, float angle) {
  coord -= 0.5;
  float c = cos(angle);
  float s = sin(angle);
  coord *= mat2(vec2(c, -s), vec2(s, c));
  return coord + 0.5;
}

void main() {
  vec2 uv = floor(vUV * pixels) / pixels;
  float lightD = distance(uv, light_origin);
  float dith = dither(uv, vUV);
  float alphaCircle = step(length(uv - vec2(0.5)), 0.49999);

  uv = rotate(uv, rotation);
  uv = spherify(uv);

  float band = fbm(vec2(0.0, uv.y * size * bands));
  float turb = turbulence(uv);

  float fbm1 = fbm(uv * size);
  float fbm2 = fbm(uv * vec2(1.0, 2.0) * size + fbm1 + vec2(-time * time_speed, 0.0) + turb);

  fbm2 *= pow(band, 2.0) * 7.0;
  float lightVal = fbm2 + lightD * 1.8;
  fbm2 += pow(lightD, 1.0) - 0.3;
  fbm2 = smoothstep(-0.2, 4.0 - fbm2, lightVal);

  if (dith > 0.5 && should_dither > 0.5) {
    fbm2 *= 1.1;
  }

  float posterized = floor(fbm2 * 4.0) / 2.0;
  float threshold = 0.625;
  int idx;
  vec4 col;

  if (fbm2 < threshold) {
    float t = posterized * (n_colors - 1.0);
    idx = int(clamp(t, 0.0, n_colors - 1.0));
    if (idx <= 0) {
      col = colors[0];
    } else if (idx == 1) {
      col = colors[1];
    } else {
      col = colors[2];
    }
  } else {
    float t = (posterized - 1.0) * (n_colors - 1.0);
    idx = int(clamp(t, 0.0, n_colors - 1.0));
    if (idx <= 0) {
      col = dark_colors[0];
    } else if (idx == 1) {
      col = dark_colors[1];
    } else {
      col = dark_colors[2];
    }
  }

  gl_FragColor = vec4(col.rgb, alphaCircle * col.a);
}

```

`StarO/PixelPlanets/Resources/Shaders/gas-planet-layers/ring.frag`:

```frag
precision mediump float;

uniform float pixels;
uniform float rotation;
uniform vec2 light_origin;
uniform float time_speed;
uniform float light_border_1;
uniform float light_border_2;
uniform float ring_width;
uniform float ring_perspective;
uniform float scale_rel_to_planet;
uniform float n_colors;
uniform vec4 colors[3];
uniform vec4 dark_colors[3];
uniform float size;
uniform float OCTAVES;
uniform float seed;
uniform float time;

varying vec2 vUV;

float rand(vec2 coord) {
  vec2 wrapped = mod(coord, vec2(2.0, 1.0) * floor(size + 0.5));
  return fract(sin(dot(wrapped.xy, vec2(12.9898, 78.233))) * 15.5453 * seed);
}

float noise(vec2 coord) {
  vec2 i = floor(coord);
  vec2 f = fract(coord);

  float a = rand(i);
  float b = rand(i + vec2(1.0, 0.0));
  float c = rand(i + vec2(0.0, 1.0));
  float d = rand(i + vec2(1.0, 1.0));

  vec2 cubic = f * f * (3.0 - 2.0 * f);

  return mix(a, b, cubic.x) +
    (c - a) * cubic.y * (1.0 - cubic.x) +
    (d - b) * cubic.x * cubic.y;
}

float fbm(vec2 coord) {
  float value = 0.0;
  float scale = 0.5;

  for (int i = 0; i < 12; i++) {
    if (float(i) >= OCTAVES) break;
    value += noise(coord) * scale;
    coord *= 2.0;
    scale *= 0.5;
  }
  return value;
}

vec2 rotateVec(vec2 coord, float angle) {
  coord -= 0.5;
  float c = cos(angle);
  float s = sin(angle);
  coord *= mat2(vec2(c, -s), vec2(s, c));
  return coord + 0.5;
}

void main() {
  vec2 uv = floor(vUV * pixels) / pixels;

  float lightD = distance(uv, light_origin);
  uv = rotateVec(uv, rotation);

  vec2 uvCenter = uv - vec2(0.0, 0.5);
  uvCenter *= vec2(1.0, ring_perspective);
  float centerDist = distance(uvCenter, vec2(0.5, 0.0));

  float ring = smoothstep(0.5 - ring_width * 2.0, 0.5 - ring_width, centerDist);
  ring *= smoothstep(centerDist - ring_width, centerDist, 0.4);

  if (uv.y < 0.5) {
    ring *= step(1.0 / scale_rel_to_planet, distance(uv, vec2(0.5)));
  }

  uvCenter = rotateVec(uvCenter + vec2(0.0, 0.5), time * time_speed);
  ring *= fbm(uvCenter * size);

  float posterized = floor((ring + pow(lightD, 2.0) * 2.0) * 4.0) / 4.0;
  posterized = min(posterized, 2.0);

  vec4 col;
  if (posterized <= 1.0) {
    float t = posterized * (n_colors - 1.0);
    int idx = int(clamp(t, 0.0, n_colors - 1.0));
    if (idx <= 0) {
      col = colors[0];
    } else if (idx == 1) {
      col = colors[1];
    } else {
      col = colors[2];
    }
  } else {
    float t = (posterized - 1.0) * (n_colors - 1.0);
    int idx = int(clamp(t, 0.0, n_colors - 1.0));
    if (idx <= 0) {
      col = dark_colors[0];
    } else if (idx == 1) {
      col = dark_colors[1];
    } else {
      col = dark_colors[2];
    }
  }

  float ringAlpha = step(0.28, ring);
  gl_FragColor = vec4(col.rgb, ringAlpha * col.a);
}

```

`StarO/PixelPlanets/Resources/Shaders/ice-world/lakes.frag`:

```frag
precision mediump float;

uniform float pixels;
uniform float rotation;
uniform vec2 light_origin;
uniform float time_speed;
uniform float light_border_1;
uniform float light_border_2;
uniform float lake_cutoff;
uniform vec4 colors[3];
uniform float size;
uniform float OCTAVES;
uniform float seed;
uniform float time;

varying vec2 vUV;

float rand(vec2 coord) {
  vec2 wrapped = mod(coord, vec2(2.0, 1.0) * floor(size + 0.5));
  return fract(sin(dot(wrapped.xy, vec2(12.9898, 78.233))) * 15.5453 * seed);
}

float noise(vec2 coord) {
  vec2 i = floor(coord);
  vec2 f = fract(coord);

  float a = rand(i);
  float b = rand(i + vec2(1.0, 0.0));
  float c = rand(i + vec2(0.0, 1.0));
  float d = rand(i + vec2(1.0, 1.0));

  vec2 cubic = f * f * (3.0 - 2.0 * f);

  return mix(a, b, cubic.x) +
    (c - a) * cubic.y * (1.0 - cubic.x) +
    (d - b) * cubic.x * cubic.y;
}

float fbm(vec2 coord) {
  float value = 0.0;
  float scale = 0.5;

  for (int i = 0; i < 12; i++) {
    if (float(i) >= OCTAVES) break;
    value += noise(coord) * scale;
    coord *= 2.0;
    scale *= 0.5;
  }
  return value;
}

vec2 spherify(vec2 uv) {
  vec2 centered = uv * 2.0 - 1.0;
  float z = sqrt(max(0.0, 1.0 - dot(centered.xy, centered.xy)));
  vec2 sphere = centered / (z + 1.0);
  return sphere * 0.5 + 0.5;
}

vec2 rotateVec(vec2 coord, float angle) {
  coord -= 0.5;
  float c = cos(angle);
  float s = sin(angle);
  coord *= mat2(vec2(c, -s), vec2(s, c));
  return coord + 0.5;
}

void main() {
  vec2 uv = floor(vUV * pixels) / pixels;

  float dLight = distance(uv, light_origin);
  float dCircle = distance(uv, vec2(0.5));
  float alpha = step(dCircle, 0.49999);

  uv = rotateVec(uv, rotation);
  uv = spherify(uv);

  float lake = fbm(uv * size + vec2(time * time_speed, 0.0));

  dLight = pow(dLight, 2.0) * 0.4;
  dLight -= dLight * lake;

  vec4 col = colors[0];
  if (dLight > light_border_1) {
    col = colors[1];
  }
  if (dLight > light_border_2) {
    col = colors[2];
  }

  alpha *= step(lake_cutoff, lake);
  gl_FragColor = vec4(col.rgb, alpha * col.a);
}

```

`StarO/PixelPlanets/Resources/Shaders/landmasses/land.frag`:

```frag
precision mediump float;

uniform float pixels;
uniform float rotation;
uniform vec2 light_origin;
uniform float time_speed;
uniform float dither_size;
uniform float light_border_1;
uniform float light_border_2;
uniform float land_cutoff;
uniform vec4 colors[4];
uniform float size;
uniform float OCTAVES;
uniform float seed;
uniform float time;

varying vec2 vUV;

float rand(vec2 coord) {
  vec2 wrapped = mod(coord, vec2(2.0, 1.0) * floor(size + 0.5));
  return fract(sin(dot(wrapped.xy, vec2(12.9898, 78.233))) * 15.5453 * seed);
}

float noise(vec2 coord) {
  vec2 i = floor(coord);
  vec2 f = fract(coord);

  float a = rand(i);
  float b = rand(i + vec2(1.0, 0.0));
  float c = rand(i + vec2(0.0, 1.0));
  float d = rand(i + vec2(1.0, 1.0));

  vec2 cubic = f * f * (3.0 - 2.0 * f);

  return mix(a, b, cubic.x) +
    (c - a) * cubic.y * (1.0 - cubic.x) +
    (d - b) * cubic.x * cubic.y;
}

float fbm(vec2 coord) {
  float value = 0.0;
  float scale = 0.5;

  for (int i = 0; i < 12; i++) {
    if (float(i) >= OCTAVES) break;
    value += noise(coord) * scale;
    coord *= 2.0;
    scale *= 0.5;
  }
  return value;
}

vec2 spherify(vec2 uv) {
  vec2 centered = uv * 2.0 - 1.0;
  float z = sqrt(max(0.0, 1.0 - dot(centered.xy, centered.xy)));
  vec2 sphere = centered / (z + 1.0);
  return sphere * 0.5 + 0.5;
}

vec2 rotate(vec2 coord, float angle) {
  coord -= 0.5;
  float c = cos(angle);
  float s = sin(angle);
  coord *= mat2(vec2(c, -s), vec2(s, c));
  return coord + 0.5;
}

void main() {
  vec2 uv = floor(vUV * pixels) / pixels;

  float dLight = distance(uv, light_origin);
  float dCircle = distance(uv, vec2(0.5));
  float alpha = step(dCircle, 0.49999);

  uv = rotate(uv, rotation);
  uv = spherify(uv);

  vec2 baseUV = uv * size + vec2(time * time_speed, 0.0);

  float fbm1 = fbm(baseUV);
  float fbm2 = fbm(baseUV - light_origin * fbm1);
  float fbm3 = fbm(baseUV - light_origin * 1.5 * fbm1);
  float fbm4 = fbm(baseUV - light_origin * 2.0 * fbm1);

  if (dLight < light_border_1) {
    fbm4 *= 0.9;
  }
  if (dLight > light_border_1) {
    fbm2 *= 1.05;
    fbm3 *= 1.05;
    fbm4 *= 1.05;
  }
  if (dLight > light_border_2) {
    fbm2 *= 1.3;
    fbm3 *= 1.4;
    fbm4 *= 1.8;
  }

  dLight = pow(dLight, 2.0) * 0.1;
  vec4 col = colors[3];
  if (fbm4 + dLight < fbm1) {
    col = colors[2];
  }
  if (fbm3 + dLight < fbm1) {
    col = colors[1];
  }
  if (fbm2 + dLight < fbm1) {
    col = colors[0];
  }

  gl_FragColor = vec4(col.rgb, step(land_cutoff, fbm1) * alpha * col.a);
}

```

`StarO/PixelPlanets/Resources/Shaders/landmasses/water.frag`:

```frag
precision mediump float;

uniform float pixels;
uniform float rotation;
uniform vec2 light_origin;
uniform float time_speed;
uniform float dither_size;
uniform float light_border_1;
uniform float light_border_2;
uniform vec4 colors[3];
uniform float size;
uniform float OCTAVES;
uniform float seed;
uniform float time;
uniform float should_dither;

varying vec2 vUV;

float rand(vec2 coord) {
  vec2 wrapped = mod(coord, vec2(2.0, 1.0) * floor(size + 0.5));
  return fract(sin(dot(wrapped.xy, vec2(12.9898, 78.233))) * 15.5453 * seed);
}

float noise(vec2 coord) {
  vec2 i = floor(coord);
  vec2 f = fract(coord);

  float a = rand(i);
  float b = rand(i + vec2(1.0, 0.0));
  float c = rand(i + vec2(0.0, 1.0));
  float d = rand(i + vec2(1.0, 1.0));

  vec2 cubic = f * f * (3.0 - 2.0 * f);

  return mix(a, b, cubic.x) +
    (c - a) * cubic.y * (1.0 - cubic.x) +
    (d - b) * cubic.x * cubic.y;
}

float fbm(vec2 coord) {
  float value = 0.0;
  float scale = 0.5;

  for (int i = 0; i < 12; i++) {
    if (float(i) >= OCTAVES) break;
    value += noise(coord) * scale;
    coord *= 2.0;
    scale *= 0.5;
  }
  return value;
}

float dither(vec2 uvPixel, vec2 uvReal) {
  return mod(uvPixel.x + uvReal.y, 2.0 / pixels) <= 1.0 / pixels ? 1.0 : 0.0;
}

vec2 rotate(vec2 coord, float angle) {
  coord -= 0.5;
  float c = cos(angle);
  float s = sin(angle);
  coord *= mat2(vec2(c, -s), vec2(s, c));
  return coord + 0.5;
}

vec2 spherify(vec2 uv) {
  vec2 centered = uv * 2.0 - 1.0;
  float z = sqrt(max(0.0, 1.0 - dot(centered.xy, centered.xy)));
  vec2 sphere = centered / (z + 1.0);
  return sphere * 0.5 + 0.5;
}

void main() {
  vec2 uv = floor(vUV * pixels) / pixels;

  float dith = dither(uv, vUV);
  float dLight = distance(uv, light_origin);

  float dCircle = distance(uv, vec2(0.5));
  float alpha = step(dCircle, 0.49999);

  uv = spherify(uv);
  uv = rotate(uv, rotation);

  dLight += fbm(uv * size + vec2(time * time_speed, 0.0)) * 0.3;

  float ditherBorder = (1.0 / pixels) * dither_size;

  vec4 col = colors[0];
  if (dLight > light_border_1) {
    col = colors[1];
    if (dLight < light_border_1 + ditherBorder && (dith > 0.5 || should_dither < 0.5)) {
      col = colors[0];
    }
  }
  if (dLight > light_border_2) {
    col = colors[2];
    if (dLight < light_border_2 + ditherBorder && (dith > 0.5 || should_dither < 0.5)) {
      col = colors[1];
    }
  }

  gl_FragColor = vec4(col.rgb, alpha * col.a);
}

```

`StarO/PixelPlanets/Resources/Shaders/lava-world/rivers.frag`:

```frag
precision mediump float;

uniform float pixels;
uniform float rotation;
uniform vec2 light_origin;
uniform float time_speed;
uniform float light_border_1;
uniform float light_border_2;
uniform float river_cutoff;
uniform vec4 colors[3];
uniform float size;
uniform float OCTAVES;
uniform float seed;
uniform float time;

varying vec2 vUV;

float rand(vec2 coord) {
  vec2 wrapped = mod(coord, vec2(2.0, 1.0) * floor(size + 0.5));
  return fract(sin(dot(wrapped.xy, vec2(12.9898, 78.233))) * 15.5453 * seed);
}

float noise(vec2 coord) {
  vec2 i = floor(coord);
  vec2 f = fract(coord);

  float a = rand(i);
  float b = rand(i + vec2(1.0, 0.0));
  float c = rand(i + vec2(0.0, 1.0));
  float d = rand(i + vec2(1.0, 1.0));

  vec2 cubic = f * f * (3.0 - 2.0 * f);

  return mix(a, b, cubic.x) +
    (c - a) * cubic.y * (1.0 - cubic.x) +
    (d - b) * cubic.x * cubic.y;
}

float fbm(vec2 coord) {
  float value = 0.0;
  float scale = 0.5;

  for (int i = 0; i < 12; i++) {
    if (float(i) >= OCTAVES) break;
    value += noise(coord) * scale;
    coord *= 2.0;
    scale *= 0.5;
  }
  return value;
}

vec2 rotate(vec2 coord, float angle) {
  coord -= 0.5;
  float c = cos(angle);
  float s = sin(angle);
  coord *= mat2(vec2(c, -s), vec2(s, c));
  return coord + 0.5;
}

vec2 spherify(vec2 uv) {
  vec2 centered = uv * 2.0 - 1.0;
  float z = sqrt(max(0.0, 1.0 - dot(centered.xy, centered.xy)));
  vec2 sphere = centered / (z + 1.0);
  return sphere * 0.5 + 0.5;
}

void main() {
  vec2 uv = floor(vUV * pixels) / pixels;

  float dLight = distance(uv, light_origin);
  float dCircle = distance(uv, vec2(0.5));
  float alpha = step(dCircle, 0.49999);

  uv = rotate(uv, rotation);
  uv = spherify(uv);

  float fbm1 = fbm(uv * size + vec2(time * time_speed, 0.0));
  float riverFBM = fbm(uv + fbm1 * 2.5);

  dLight = pow(dLight, 2.0) * 0.4;
  dLight -= dLight * riverFBM;

  riverFBM = step(river_cutoff, riverFBM);

  vec4 col = colors[0];
  if (dLight > light_border_1) {
    col = colors[1];
  }
  if (dLight > light_border_2) {
    col = colors[2];
  }

  alpha *= step(river_cutoff, riverFBM);
  gl_FragColor = vec4(col.rgb, alpha * col.a);
}

```

`StarO/PixelPlanets/Resources/Shaders/no-atmosphere/craters.frag`:

```frag
precision mediump float;

uniform float pixels;
uniform float rotation;
uniform vec2 light_origin;
uniform float time_speed;
uniform float light_border;
uniform vec4 colors[2];
uniform float size;
uniform float seed;
uniform float time;

varying vec2 vUV;

float rand(vec2 coord) {
  vec2 wrapped = mod(coord, vec2(1.0, 1.0) * floor(size + 0.5));
  return fract(sin(dot(wrapped.xy, vec2(12.9898, 78.233))) * 15.5453 * seed);
}

float circleNoise(vec2 uv) {
  float uvY = floor(uv.y);
  uv.x += uvY * 0.31;
  vec2 f = fract(uv);
  float h = rand(vec2(floor(uv.x), floor(uvY)));
  float m = length(f - 0.25 - (h * 0.5));
  float r = h * 0.25;
  return smoothstep(r - 0.10 * r, r, m * 0.75);
}

float crater(vec2 uv) {
  float c = 1.0;
  for (int i = 0; i < 2; i++) {
    c *= circleNoise((uv * size) + (float(i + 1) + 10.0) + vec2(time * time_speed, 0.0));
  }
  return 1.0 - c;
}

vec2 rotate(vec2 coord, float angle) {
  coord -= 0.5;
  float c = cos(angle);
  float s = sin(angle);
  coord *= mat2(vec2(c, -s), vec2(s, c));
  return coord + 0.5;
}

vec2 spherify(vec2 uv) {
  vec2 centered = uv * 2.0 - 1.0;
  float z = sqrt(max(0.0, 1.0 - dot(centered.xy, centered.xy)));
  vec2 sphere = centered / (z + 1.0);
  return sphere * 0.5 + 0.5;
}

void main() {
  vec2 uv = floor(vUV * pixels) / pixels;

  float alpha = step(distance(uv, vec2(0.5)), 0.49999);
  float dLight = distance(uv, light_origin);

  uv = rotate(uv, rotation);
  uv = spherify(uv);

  float c1 = crater(uv);
  float c2 = crater(uv + (light_origin - 0.5) * 0.03);

  vec4 col = colors[0];
  alpha *= step(0.5, c1);

  if (c2 < c1 - (0.5 - dLight) * 2.0) {
    col = colors[1];
  }
  if (dLight > light_border) {
    col = colors[1];
  }

  gl_FragColor = vec4(col.rgb, alpha * col.a);
}

```

`StarO/PixelPlanets/Resources/Shaders/no-atmosphere/ground.frag`:

```frag
precision mediump float;

uniform float pixels;
uniform float rotation;
uniform vec2 light_origin;
uniform float time_speed;
uniform float dither_size;
uniform float light_border_1;
uniform float light_border_2;
uniform vec4 colors[3];
uniform float size;
uniform float OCTAVES;
uniform float seed;
uniform float time;
uniform float should_dither;

varying vec2 vUV;

float rand(vec2 coord) {
  vec2 wrapped = mod(coord, vec2(1.0, 1.0) * floor(size + 0.5));
  return fract(sin(dot(wrapped.xy, vec2(12.9898, 78.233))) * 15.5453 * seed);
}

float noise(vec2 coord) {
  vec2 i = floor(coord);
  vec2 f = fract(coord);

  float a = rand(i);
  float b = rand(i + vec2(1.0, 0.0));
  float c = rand(i + vec2(0.0, 1.0));
  float d = rand(i + vec2(1.0, 1.0));

  vec2 cubic = f * f * (3.0 - 2.0 * f);

  return mix(a, b, cubic.x) +
    (c - a) * cubic.y * (1.0 - cubic.x) +
    (d - b) * cubic.x * cubic.y;
}

float fbm(vec2 coord) {
  float value = 0.0;
  float scale = 0.5;
  for (int i = 0; i < 12; i++) {
    if (float(i) >= OCTAVES) break;
    value += noise(coord) * scale;
    coord *= 2.0;
    scale *= 0.5;
  }
  return value;
}

float dither(vec2 uvPixel, vec2 uvReal) {
  float stepSize = 2.0 / pixels;
  return mod(uvPixel.x + uvReal.y, stepSize) <= (1.0 / pixels) ? 1.0 : 0.0;
}

vec2 rotate(vec2 coord, float angle) {
  coord -= 0.5;
  float c = cos(angle);
  float s = sin(angle);
  coord *= mat2(vec2(c, -s), vec2(s, c));
  return coord + 0.5;
}

vec2 spherify(vec2 uv) {
  vec2 centered = uv * 2.0 - 1.0;
  float z = sqrt(max(0.0, 1.0 - dot(centered.xy, centered.xy)));
  vec2 sphere = centered / (z + 1.0);
  return sphere * 0.5 + 0.5;
}

void main() {
  vec2 uv = floor(vUV * pixels) / pixels;

  float alpha = step(distance(uv, vec2(0.5)), 0.49999);
  float dith = dither(uv, vUV);

  float dLight = distance(uv, light_origin);

  uv = rotate(uv, rotation);
  uv = spherify(uv);

  float combined = fbm(uv * size + vec2(time * time_speed, 0.0));
  dLight += combined * 0.3;

  float ditherBorder = (1.0 / pixels) * dither_size;

  vec4 col = colors[0];
  if (dLight > light_border_1) {
    col = colors[1];
    if (dLight < light_border_1 + ditherBorder && (dith > 0.5 || should_dither < 0.5)) {
      col = colors[0];
    }
  }
  if (dLight > light_border_2) {
    col = colors[2];
    if (dLight < light_border_2 + ditherBorder && (dith > 0.5 || should_dither < 0.5)) {
      col = colors[1];
    }
  }

  gl_FragColor = vec4(col.rgb, alpha * col.a);
}

```

`StarO/PixelPlanets/Resources/Shaders/rivers/land.frag`:

```frag
precision highp float;
precision highp int;

uniform float pixels;
uniform float rotation;
uniform vec2 light_origin;
uniform float time_speed;
uniform float dither_size;
uniform float should_dither;
uniform float light_border_1;
uniform float light_border_2;
uniform float river_cutoff;
uniform vec4 colors[6];
uniform float size;
uniform float OCTAVES;
uniform float seed;
uniform float time;

varying vec2 vUV;

float rand(vec2 coord) {
  vec2 wrapped = mod(coord, vec2(2.0, 1.0) * floor(size + 0.5));
  return fract(sin(dot(wrapped.xy, vec2(12.9898, 78.233))) * 15.5453 * seed);
}

float noise(vec2 coord) {
  vec2 i = floor(coord);
  vec2 f = fract(coord);

  float a = rand(i);
  float b = rand(i + vec2(1.0, 0.0));
  float c = rand(i + vec2(0.0, 1.0));
  float d = rand(i + vec2(1.0, 1.0));

  vec2 cubic = f * f * (3.0 - 2.0 * f);

  return mix(a, b, cubic.x) +
    (c - a) * cubic.y * (1.0 - cubic.x) +
    (d - b) * cubic.x * cubic.y;
}

float fbm(vec2 coord) {
  float value = 0.0;
  float scale = 0.5;

  for (int i = 0; i < 12; i++) {
    if (float(i) >= OCTAVES) break;
    value += noise(coord) * scale;
    coord *= 2.0;
    scale *= 0.5;
  }
  return value;
}

float dither(vec2 uvPixel, vec2 uvReal) {
  return mod(uvPixel.x + uvReal.y, 2.0 / pixels) <= 1.0 / pixels ? 1.0 : 0.0;
}

vec2 rotate(vec2 coord, float angle) {
  coord -= 0.5;
  float c = cos(angle);
  float s = sin(angle);
  coord *= mat2(vec2(c, -s), vec2(s, c));
  return coord + 0.5;
}

vec2 spherify(vec2 uv) {
  vec2 centered = uv * 2.0 - 1.0;
  float z = sqrt(max(0.0, 1.0 - dot(centered.xy, centered.xy)));
  vec2 sphere = centered / (z + 1.0);
  return sphere * 0.5 + 0.5;
}

void main() {
  vec2 uv = floor(vUV * pixels) / pixels;

  float dith = dither(uv, vUV);
  float alpha = step(length(uv - vec2(0.5)), 0.49999);

  uv = spherify(uv);
  float dLight = distance(uv, light_origin);

  uv = rotate(uv, rotation);

  vec2 baseUV = uv * size + vec2(time * time_speed, 0.0);

  float fbm1 = fbm(baseUV);
  float fbm2 = fbm(baseUV - light_origin * fbm1);
  float fbm3 = fbm(baseUV - light_origin * 1.5 * fbm1);
  float fbm4 = fbm(baseUV - light_origin * 2.0 * fbm1);

  float river = fbm(baseUV + fbm1 * 6.0);
  river = step(river_cutoff, river);

  float ditherBorder = (1.0 / pixels) * dither_size;

  if (dLight < light_border_1) {
    fbm4 *= 0.9;
  }
  if (dLight > light_border_1) {
    fbm2 *= 1.05;
    fbm3 *= 1.05;
    fbm4 *= 1.05;
  }
  if (dLight > light_border_2) {
    fbm2 *= 1.3;
    fbm3 *= 1.4;
    fbm4 *= 1.8;

    if (dLight < light_border_2 + ditherBorder && (dith > 0.5 || should_dither < 0.5)) {
      fbm4 *= 0.5;
    }
  }

  dLight = pow(dLight, 2.0) * 0.4;
  vec4 col = colors[3];
  if (fbm4 + dLight < fbm1 * 1.5) {
    col = colors[2];
  }
  if (fbm3 + dLight < fbm1) {
    col = colors[1];
  }
  if (fbm2 + dLight < fbm1) {
    col = colors[0];
  }
  if (river < fbm1 * 0.5) {
    col = colors[5];
    if (fbm4 + dLight < fbm1 * 1.5) {
      col = colors[4];
    }
  }

  gl_FragColor = vec4(col.rgb, alpha * col.a);
}

```

`StarO/PixelPlanets/Resources/Shaders/star/blobs.frag`:

```frag
precision mediump float;

uniform float pixels;
uniform vec4 colors[1];
uniform float time_speed;
uniform float time;
uniform float rotation;
uniform float seed;
uniform float circle_amount;
uniform float circle_size;
uniform float size;
uniform float OCTAVES;

varying vec2 vUV;

float rand(vec2 coord) {
  vec2 wrapped = mod(coord, vec2(1.0, 1.0) * floor(size + 0.5));
  return fract(sin(dot(wrapped.xy, vec2(12.9898, 78.233))) * 15.5453 * seed);
}

vec2 rotateVec(vec2 vec, float angle) {
  vec -= vec2(0.5);
  float c = cos(angle);
  float s = sin(angle);
  vec *= mat2(vec2(c, -s), vec2(s, c));
  vec += vec2(0.5);
  return vec;
}

float circle(vec2 uv) {
  float invert = 1.0 / circle_amount;

  if (mod(uv.y, invert * 2.0) < invert) {
    uv.x += invert * 0.5;
  }
  vec2 randCo = floor(uv * circle_amount) / circle_amount;
  uv = mod(uv, invert) * circle_amount;

  float r = rand(randCo);
  r = clamp(r, invert, 1.0 - invert);
  float dist = distance(uv, vec2(r));
  return smoothstep(dist, dist + 0.5, invert * circle_size * rand(randCo * 1.5));
}

float noise(vec2 coord) {
  vec2 i = floor(coord);
  vec2 f = fract(coord);

  float a = rand(i);
  float b = rand(i + vec2(1.0, 0.0));
  float c = rand(i + vec2(0.0, 1.0));
  float d = rand(i + vec2(1.0, 1.0));

  vec2 cubic = f * f * (3.0 - 2.0 * f);

  return mix(a, b, cubic.x) +
    (c - a) * cubic.y * (1.0 - cubic.x) +
    (d - b) * cubic.x * cubic.y;
}

float fbm(vec2 coord) {
  float value = 0.0;
  float scl = 0.5;

  for (int i = 0; i < 12; i++) {
    if (float(i) >= OCTAVES) break;
    value += noise(coord) * scl;
    coord *= 2.0;
    scl *= 0.5;
  }
  return value;
}

vec2 spherify(vec2 uv) {
  vec2 centered = uv * 2.0 - 1.0;
  float z = sqrt(max(0.0, 1.0 - dot(centered.xy, centered.xy)));
  vec2 sphere = centered / (z + 1.0);
  return sphere * 0.5 + 0.5;
}

void main() {
  vec2 pixelized = floor(vUV * pixels) / pixels;

  vec2 uv = rotateVec(pixelized, rotation);
  float angle = atan(uv.x - 0.5, uv.y - 0.5);
  float d = distance(pixelized, vec2(0.5));

  float c = 0.0;
  for (int i = 0; i < 15; i++) {
    float r = rand(vec2(float(i)));
    vec2 circleUV = vec2(d, angle);
    c += circle(circleUV * size - time * time_speed - (1.0 / max(d, 0.0001)) * 0.1 + r);
  }

  c *= 0.37 - d;
  c = step(0.07, c - d);

  gl_FragColor = vec4(colors[0].rgb, c * colors[0].a);
}

```

`StarO/PixelPlanets/Resources/Shaders/star/flares.frag`:

```frag
precision mediump float;

uniform float pixels;
uniform vec4 colors[2];
uniform float time_speed;
uniform float time;
uniform float rotation;
uniform float should_dither;
uniform float storm_width;
uniform float storm_dither_width;
uniform float scale;
uniform float seed;
uniform float circle_amount;
uniform float circle_scale;
uniform float size;
uniform float OCTAVES;

varying vec2 vUV;

float rand(vec2 coord) {
  vec2 wrapped = mod(coord, vec2(1.0, 1.0) * floor(size + 0.5));
  return fract(sin(dot(wrapped.xy, vec2(12.9898, 78.233))) * 15.5453 * seed);
}

vec2 rotateVec(vec2 vec, float angle) {
  vec -= vec2(0.5);
  float c = cos(angle);
  float s = sin(angle);
  vec *= mat2(vec2(c, -s), vec2(s, c));
  vec += vec2(0.5);
  return vec;
}

float circle(vec2 uv) {
  float invert = 1.0 / circle_amount;
  if (mod(uv.y, invert * 2.0) < invert) {
    uv.x += invert * 0.5;
  }
  vec2 randCo = floor(uv * circle_amount) / circle_amount;
  uv = mod(uv, invert) * circle_amount;

  float r = rand(randCo);
  r = clamp(r, invert, 1.0 - invert);
  float dist = distance(uv, vec2(r));
  return smoothstep(dist, dist + 0.5, invert * circle_scale * rand(randCo * 1.5));
}

float noise(vec2 coord) {
  vec2 i = floor(coord);
  vec2 f = fract(coord);

  float a = rand(i);
  float b = rand(i + vec2(1.0, 0.0));
  float c = rand(i + vec2(0.0, 1.0));
  float d = rand(i + vec2(1.0, 1.0));

  vec2 cubic = f * f * (3.0 - 2.0 * f);

  return mix(a, b, cubic.x) +
    (c - a) * cubic.y * (1.0 - cubic.x) +
    (d - b) * cubic.x * cubic.y;
}

float fbm(vec2 coord) {
  float value = 0.0;
  float scl = 0.5;
  for (int i = 0; i < 12; i++) {
    if (float(i) >= OCTAVES) break;
    value += noise(coord) * scl;
    coord *= 2.0;
    scl *= 0.5;
  }
  return value;
}

float dither(vec2 uv1, vec2 uv2) {
  return mod(uv1.x + uv2.y, 2.0 / pixels) <= 1.0 / pixels ? 1.0 : 0.0;
}

vec2 spherify(vec2 uv) {
  vec2 centered = uv * 2.0 - 1.0;
  float z = sqrt(max(0.0, 1.0 - dot(centered.xy, centered.xy)));
  vec2 sphere = centered / (z + 1.0);
  return sphere * 0.5 + 0.5;
}

void main() {
  vec2 pixelized = floor(vUV * pixels) / pixels;
  float dith = dither(vUV, pixelized);

  pixelized = rotateVec(pixelized, rotation);
  vec2 uv = pixelized;

  float angle = atan(uv.x - 0.5, uv.y - 0.5) * 0.4;
  float d = distance(pixelized, vec2(0.5));

  vec2 circleUV = vec2(d, angle);

  float n = fbm(circleUV * size - time * time_speed);
  float nc = circle(circleUV * scale - time * time_speed + n);

  nc *= 1.5;
  float n2 = fbm(circleUV * size - time + vec2(100.0, 100.0));
  nc -= n2 * 0.1;

  float alpha = 0.0;
  if (1.0 - d > nc) {
    if (nc > storm_width - storm_dither_width + d && (dith > 0.5 || should_dither < 0.5)) {
      alpha = 1.0;
    } else if (nc > storm_width + d) {
      alpha = 1.0;
    }
  }

  float interpolate = floor(n2 + nc);
  int idx = int(clamp(interpolate, 0.0, 1.0));
  vec4 col = idx <= 0 ? colors[0] : colors[1];

  alpha *= step(n2 * 0.25, d);
  gl_FragColor = vec4(col.rgb, alpha * col.a);
}

```

`StarO/PixelPlanets/Resources/Shaders/star/star.frag`:

```frag
precision mediump float;

uniform float pixels;
uniform float time_speed;
uniform float time;
uniform float rotation;
uniform vec4 colors[4];
uniform float n_colors;
uniform float should_dither;
uniform float seed;
uniform float size;
uniform float OCTAVES;
uniform float TILES;

varying vec2 vUV;

float rand(vec2 coord) {
  vec2 wrapped = mod(coord, vec2(1.0, 1.0) * floor(size + 0.5));
  return fract(sin(dot(wrapped.xy, vec2(12.9898, 78.233))) * 15.5453 * seed);
}

vec2 rotateVec(vec2 vec, float angle) {
  vec -= vec2(0.5);
  float c = cos(angle);
  float s = sin(angle);
  vec *= mat2(vec2(c, -s), vec2(s, c));
  vec += vec2(0.5);
  return vec;
}

float noise(vec2 coord) {
  vec2 i = floor(coord);
  vec2 f = fract(coord);

  float a = rand(i);
  float b = rand(i + vec2(1.0, 0.0));
  float c = rand(i + vec2(0.0, 1.0));
  float d = rand(i + vec2(1.0, 1.0));

  vec2 cubic = f * f * (3.0 - 2.0 * f);

  return mix(a, b, cubic.x) +
    (c - a) * cubic.y * (1.0 - cubic.x) +
    (d - b) * cubic.x * cubic.y;
}

vec2 hash2(vec2 p) {
  float r = 523.0 * sin(dot(p, vec2(53.3158, 43.6143)));
  return vec2(fract(15.32354 * r), fract(17.25865 * r));
}

float cells(vec2 p, float numCells) {
  p *= numCells;
  float d = 1.0e10;
  for (int xo = -1; xo <= 1; xo++) {
    for (int yo = -1; yo <= 1; yo++) {
      vec2 tp = floor(p) + vec2(float(xo), float(yo));
      tp = p - tp - hash2(mod(tp, numCells / TILES));
      d = min(d, dot(tp, tp));
    }
  }
  return sqrt(d);
}

float dither(vec2 uv1, vec2 uv2) {
  return mod(uv1.x + uv2.y, 2.0 / pixels) <= 1.0 / pixels ? 1.0 : 0.0;
}

vec2 spherify(vec2 uv) {
  vec2 centered = uv * 2.0 - 1.0;
  float z = sqrt(max(0.0, 1.0 - dot(centered.xy, centered.xy)));
  vec2 sphere = centered / (z + 1.0);
  return sphere * 0.5 + 0.5;
}

void main() {
  vec2 pixelized = floor(vUV * pixels) / pixels;
  float alpha = step(distance(pixelized, vec2(0.5)), 0.49999);
  float dith = dither(vUV, pixelized);

  pixelized = rotateVec(pixelized, rotation);
  pixelized = spherify(pixelized);

  float n = cells(pixelized - vec2(time * time_speed * 2.0, 0.0), 10.0);
  n *= cells(pixelized - vec2(time * time_speed, 0.0), 20.0);

  n *= 2.0;
  n = clamp(n, 0.0, 1.0);
  if (dith > 0.5 || should_dither < 0.5) {
    n *= 1.3;
  }

  float interpolate = floor(n * (n_colors - 1.0)) / (n_colors - 1.0);
  int index = int(interpolate * (n_colors - 1.0));
  vec4 col = colors[0];
  if (index <= 0) {
    col = colors[0];
  } else if (index == 1) {
    col = colors[1];
  } else if (index == 2) {
    col = colors[2];
  } else {
    col = colors[3];
  }

  gl_FragColor = vec4(col.rgb, alpha * col.a);
}

```

`StarO/PixelPlanets/Resources/Shaders/star/twinkle.frag`:

```frag
precision highp float;
precision highp int;

uniform float time;
uniform float time_speed;
uniform float spark_scale;
uniform float spark_sharpness;
uniform float flicker_strength;
uniform float star_radius;
uniform float branch_count;
uniform float rotation_speed;
uniform float halo_softness;
uniform vec4 colors[2];

varying vec2 vUV;

float hash(vec2 p) {
  p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
  return fract(sin(p.x + p.y) * 43758.5453123);
}

void main() {
  vec2 center = vec2(0.5);
  vec2 offset = vUV - center;
  float dist = length(offset);
  if (dist > 0.5) {
    discard;
  }

  float phase = fract(time * time_speed);
  float grow = smoothstep(0.0, 0.3, phase);
  float shrink = smoothstep(1.0, 0.7, phase);
  float envelope = min(grow, shrink);
  float radius = mix(0.02, star_radius, envelope);

  float halo = smoothstep(radius + halo_softness, radius, dist);

  float arms = clamp(branch_count, 2.0, 8.0);
  float rot = rotation_speed * phase * 6.28318;
  float angle = atan(offset.y, offset.x) + rot;
  float spikes = pow(max(0.0, cos(angle * arms)), spark_sharpness);
  float spikeFalloff = smoothstep(radius, radius + spark_scale, dist);
  float starburst = spikes * (1.0 - spikeFalloff);

  float swirl = sin((dist * 10.0 - angle * 3.0) + phase * 6.28318) * (1.0 - dist * 2.0);
  float swirlMask = smoothstep(-0.2, 0.4, swirl);

  float flicker = 0.5 + 0.5 * sin(time * time_speed * 3.5 + hash(floor(vUV * 12.0)) * 6.28318);

  float intensity = halo + starburst * (0.8 + flicker * flicker_strength) + swirlMask * 0.25;
  intensity = clamp(intensity, 0.0, 1.0);

  vec4 col = mix(colors[0], colors[1], intensity);
  vec3 highlight = mix(col.rgb, vec3(1.0), starburst * 0.5);
  gl_FragColor = vec4(highlight, col.a * intensity);
}

```

`StarO/PreferenceService.swift`:

```swift
import Foundation
import StarOracleServices

@MainActor
final class LocalPreferenceService: PreferenceServiceProtocol {
  private let defaults: UserDefaults
  private let key = "aiConfiguration"
  private var cachedDefault: AIConfiguration?

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
  }

  func loadAIConfiguration() async -> AIConfiguration? {
    if let data = defaults.data(forKey: key),
       let stored = try? JSONDecoder().decode(AIConfiguration.self, from: data) {
      NSLog("ℹ️ [PreferenceService] 使用用户保存的 AI 配置（provider=%@, endpoint=%@）", stored.provider, stored.endpoint.absoluteString)
      return stored
    }
    if let cachedDefault {
      NSLog("ℹ️ [PreferenceService] 使用缓存的默认 AI 配置（provider=%@）", cachedDefault.provider)
      return cachedDefault
    }
    let defaultConfig = AIConfigurationDefaults.load()
    if let defaultConfig {
      NSLog("ℹ️ [PreferenceService] 使用默认 AI 配置（provider=%@, endpoint=%@）", defaultConfig.provider, defaultConfig.endpoint.absoluteString)
    } else {
      NSLog("⚠️ [PreferenceService] 未找到任何 AI 配置")
    }
    cachedDefault = defaultConfig
    return defaultConfig
  }

  func saveAIConfiguration(_ config: AIConfiguration) async throws {
    let data = try JSONEncoder().encode(config)
    defaults.set(data, forKey: key)
    NSLog("✅ [PreferenceService] AI 配置已保存（provider=%@）", config.provider)
    cachedDefault = config
  }
}

```

`StarO/Preview Content/Preview Assets.xcassets/Contents.json`:

```json
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}

```

`StarO/README_CHAT_OVERLAY_DEBUG.md`:

```md
# ChatOverlay 调试指南

请运行 App 并将控制台关键日志贴给我，以便定位为何浮窗未显示。

```

`StarO/RootView.swift`:

```swift
import SwiftUI
import StarOracleCore
import StarOracleFeatures
import StarOracleServices
import StarOracleUIComponents

struct RootView: View {
  @EnvironmentObject private var environment: AppEnvironment
  @EnvironmentObject private var starStore: StarStore
  @EnvironmentObject private var galaxyStore: GalaxyStore
  @EnvironmentObject private var conversationStore: ConversationStore
  @EnvironmentObject private var chatBridge: NativeChatBridge

  @State private var activePane: ActivePane = .home
  @State private var selectedStar: Star?
  @State private var dragOffset: CGFloat = 0

  var body: some View {
    GeometryReader { geometry in
      let width = geometry.size.width
      let menuWidth = min(360, width * 0.8)
      let collectionWidth = min(420, width)

      ZStack(alignment: .leading) {
        GalaxyBackgroundView(isTapEnabled: activePane == .home)
          .environmentObject(galaxyStore)
          .ignoresSafeArea()

        primaryPane
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .offset(x: contentOffset(for: width) + dragOffset)
          .scaleEffect(activePane == .home ? 1 : 0.92, anchor: .center)
          .animation(.spring(response: 0.4, dampingFraction: 0.85), value: activePane)
          .disabled(activePane != .home)

        if activePane == .menu {
          Group {
            DrawerMenuView(
              onClose: { snapTo(.home) },
              onOpenTemplate: {},
              onOpenCollection: { snapTo(.collection) },
              onOpenAIConfig: {},
              onOpenInspiration: {},
              onSwitchSession: { id in environment.switchSession(to: id) },
              onCreateSession: { title in environment.createSession(title: title) },
              onRenameSession: { id, title in environment.renameSession(id: id, title: title) },
              onDeleteSession: { id in environment.deleteSession(id: id) }
            )
            .frame(width: menuWidth, alignment: .leading)
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.leading, 24)
            .transition(.move(edge: .leading))

            HStack(spacing: 0) {
              Color.clear
                .frame(width: menuWidth + 24)
                .allowsHitTesting(false)
              Color.black.opacity(0.001)
                .contentShape(Rectangle())
                .onTapGesture { snapTo(.home) }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
          }
          .offset(x: dragOffset)
        }

        if activePane == .collection {
          StarCollectionPane(
            constellationStars: starStore.constellation.stars,
            inspirationStars: starStore.inspirationStars,
            onBack: { snapTo(.home) }
          )
          .frame(width: collectionWidth, alignment: .trailing)
          .frame(maxHeight: .infinity)
          .transition(.move(edge: .trailing))
          .frame(maxWidth: .infinity, alignment: .trailing)
          .offset(x: dragOffset)
        }
      }
      .gesture(
        DragGesture(minimumDistance: 8)
          .onChanged { value in
            guard !galaxyStore.isGeneratingCard else { return }
            handleDragChanged(value.translation.width, width: width)
          }
          .onEnded { value in
            guard !galaxyStore.isGeneratingCard else { return }
            handleDragEnded(value.translation.width, width: width)
          }
      )
      .overlay(
        ChatOverlayHostView(bridge: chatBridge)
          .allowsHitTesting(false)
      )
      .overlay(
        InspirationCardOverlay()
      )

      .onAppear {
        DispatchQueue.main.async {
          environment.bootstrapConversationIfNeeded()
          chatBridge.activateIfNeeded()
          let offset = activePane == .menu ? menuWidth + 24 : 0
          chatBridge.setHorizontalOffset(offset, animated: false)
        }
      }
      .onChange(of: activePane) { _, newValue in
        DispatchQueue.main.async {
          let offset = newValue == .menu ? menuWidth + 24 : 0
          chatBridge.setHorizontalOffset(offset, animated: true)
        }
      }
    }
  }

  private var primaryPane: some View {
    ZStack(alignment: .top) {
      homePane
      topBar
        .padding(.top, 12)
        .frame(height: 60)
    }
  }

  private var homePane: some View {
    VStack(spacing: 20) {

      
      Spacer()
    }
    .padding(.top, 96)
    .padding(.horizontal, 24)
    .padding(.bottom, 40)
    .frame(maxHeight: .infinity, alignment: .top)
    // 避免中心内容层拦截点击，让银河接收触摸
    .allowsHitTesting(false)
  }





  private var topBar: some View {
    HStack(spacing: 16) {
      headerMenuButton
      Spacer()
      headerTitle
      Spacer()
      headerChatButton
      headerStarButton
    }
    .padding(.horizontal, 24)
  }

  private var headerMenuButton: some View {
    Button(action: { togglePane(.menu) }) {
      Image(systemName: "line.3.horizontal")
        .font(.system(size: 16, weight: .medium))
        .foregroundStyle(.white.opacity(activePane == .menu ? 1 : 0.7))
        .frame(width: 36, height: 36)
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    .buttonStyle(.plain)
    .disabled(galaxyStore.isGeneratingCard)
  }

  private var headerStarButton: some View {
    Button(action: { togglePane(.collection) }) {
      StarRayIconView(size: 18)
        .frame(width: 36, height: 36)
        .foregroundStyle(.white.opacity(activePane == .collection ? 1 : 0.7))
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    .buttonStyle(.plain)
    .disabled(galaxyStore.isGeneratingCard)
  }

  private var headerChatButton: some View {
    let isActive = chatBridge.presentationState != .hidden
    return Button(action: { chatBridge.toggleOverlay(expanded: true) }) {
      Image(systemName: isActive ? "bubble.left.and.bubble.right.fill" : "bubble.left.and.bubble.right")
        .font(.system(size: 16, weight: .medium))
        .foregroundStyle(.white.opacity(isActive ? 1 : 0.7))
        .frame(width: 36, height: 36)
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    .buttonStyle(.plain)
  }

  private var headerTitle: some View {
    HStack(spacing: 6) {
      Text("星谕")
        .font(.system(size: 18, weight: .semibold, design: .serif))
        .foregroundStyle(.white)
      Text("(StarOracle)")
        .font(.caption)
        .foregroundStyle(.white.opacity(0.7))
    }
  }

  private func contentOffset(for width: CGFloat) -> CGFloat {
    switch activePane {
    case .home:
      return 0
    case .menu:
      return width * 0.5
    case .collection:
      return -width * 0.5
    }
  }

  private func snapTo(_ pane: ActivePane) {
    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
      activePane = pane
      dragOffset = 0
    }
  }

  private func togglePane(_ pane: ActivePane) {
    if activePane == pane {
      snapTo(.home)
    } else {
      snapTo(pane)
    }
  }

  private func handleDragChanged(_ translation: CGFloat, width: CGFloat) {
    let limit = width * 0.5
    switch activePane {
    case .home:
      dragOffset = max(-limit, min(limit, translation))
    case .menu:
      dragOffset = max(-limit, min(0, translation))
    case .collection:
      dragOffset = max(0, min(limit, translation))
    }
  }

  private func handleDragEnded(_ translation: CGFloat, width: CGFloat) {
    let threshold = width * 0.2
    defer { dragOffset = 0 }

    switch activePane {
    case .home:
      if translation > threshold {
        snapTo(.menu)
      } else if translation < -threshold {
        snapTo(.collection)
      }
    case .menu:
      if translation < -threshold {
        snapTo(.home)
      } else {
        snapTo(.menu)
      }
    case .collection:
      if translation > threshold {
        snapTo(.home)
      } else {
        snapTo(.collection)
      }
    }
  }

  private enum ActivePane {
    case menu
    case home
    case collection
  }
}

```

`StarO/StarCard/PlanetView.swift`:

```swift
import SwiftUI
import StarOracleCore

struct PlanetView: View {
    let config: StarCardConfig
    let star: Star
    
    var body: some View {
        Canvas { context, size in
            // Setup RNG
            var rng = SeededRandom(seed: config.seed)
            
            let centerX = size.width / 2
            let centerY = size.height / 2
            let scale = size.width / 200.0 // Base logic on 200x200
            
            // Planet Parameters
            let planetRadiusBase = 15.0 + rng.next(in: 0...5)
            let planetRadius = planetRadiusBase * scale
            
            // Palette Generation
            // Parse HSL from theme (simplified: use theme colors directly)
            // We'll generate a palette based on the theme's accent or star color
            let baseColor = star.isSpecial ? config.theme.accent : config.theme.star
            // We need to derive shadow/highlight colors. 
            // Since Color doesn't easily give HSL in SwiftUI, we'll use opacity overlays for shading.
            
            let lightAngle = rng.next(in: 0...(2 * .pi))
            
            // 1. Glow
            let glowRadius = planetRadius * 3.0
            let glowGradient = Gradient(stops: [
                .init(color: baseColor.opacity(0.7), location: 0),
                .init(color: baseColor.opacity(0.3), location: 0.15), // 0.5 in 0.8-3 range approx
                .init(color: .clear, location: 1.0)
            ])
            context.fill(
                Path(ellipseIn: CGRect(x: centerX - glowRadius, y: centerY - glowRadius, width: glowRadius * 2, height: glowRadius * 2)),
                with: .radialGradient(glowGradient, center: .init(x: centerX, y: centerY), startRadius: planetRadius * 0.8, endRadius: glowRadius)
            )
            
            // 2. Background Stars
            for _ in 0..<30 {
                let x = rng.next(in: 0...size.width)
                let y = rng.next(in: 0...size.height)
                let s = (rng.next() * 1.2 + 0.3) * scale
                context.opacity = rng.next() * 0.7 + 0.1
                context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: s, height: s)), with: .color(.white))
            }
            context.opacity = 1.0
            
            // Ring Config
            let hasPlanetRings = config.style == .planetRings || (config.style.isPlanet && rng.next() > 0.7)
            var ringTilt = 0.0
            var ringRadiusX = 0.0
            var ringRadiusY = 0.0
            
            if hasPlanetRings {
                ringTilt = (rng.next() - 0.5) * 0.8
                ringRadiusX = planetRadius * 1.6
                ringRadiusY = ringRadiusX * 0.3
            }
            
            // 3. Ring Back
            if hasPlanetRings {
                context.withCGContext { cg in
                    cg.saveGState()
                    cg.translateBy(x: centerX, y: centerY)
                    cg.rotate(by: ringTilt)
                    
                    let rect = CGRect(x: -ringRadiusX, y: -ringRadiusY, width: ringRadiusX * 2, height: ringRadiusY * 2)
                    let path = Path(ellipseIn: rect)
                    
                    // Clip to back half (top half in rotated space, roughly)
                    // Actually, standard ellipse drawing draws full. We need to mask or just draw full behind?
                    // React draws full ellipse behind.
                    context.stroke(path, with: .color(baseColor.opacity(0.6)), lineWidth: 1.5 * scale)
                    
                    cg.restoreGState()
                }
            }
            
            // 4. Planet Body
            let planetRect = CGRect(x: centerX - planetRadius, y: centerY - planetRadius, width: planetRadius * 2, height: planetRadius * 2)
            let planetPath = Path(ellipseIn: planetRect)
            
            // Draw base planet with shadow
            var baseContext = context
            baseContext.addFilter(.shadow(color: baseColor.opacity(0.5), radius: 5 * scale))
            baseContext.fill(planetPath, with: .color(baseColor)) // Base
            
            // Clip to planet for details
            // We use a local context for the planet body details so the clip doesn't affect subsequent drawing (like rings/rays)
            var planetBodyContext = context
            planetBodyContext.clip(to: planetPath)
            
            // Shading (Bands)
            let numBands = Int(rng.next(in: 5...10))
            let lightVec = CGPoint(x: cos(lightAngle), y: sin(lightAngle))
            let totalOffset = planetRadius * 0.8
            
            for i in 0..<numBands {
                let t = Double(i) / Double(numBands - 1)
                let offsetFactor = -1.0 + 2.0 * t
                let offsetX = lightVec.x * totalOffset * offsetFactor * -0.5
                let offsetY = lightVec.y * totalOffset * offsetFactor * -0.5
                
                // Darker bands
                let bandPath = Path(ellipseIn: CGRect(
                    x: centerX - planetRadius - offsetX,
                    y: centerY - planetRadius - offsetY,
                    width: planetRadius * 2,
                    height: planetRadius * 2
                ))
                
                // Simulate shadow/highlight by varying opacity of black/white
                // t=0 is shadow side, t=1 is light side
                let shadowOpacity = (1.0 - t) * 0.6
                planetBodyContext.fill(bandPath, with: .color(.black.opacity(shadowOpacity)))
            }
            
            // Style Specific Features
            if config.style == .planetCraters {
                let craterCount = Int(rng.next(in: 5...15))
                for _ in 0..<craterCount {
                    let angle = rng.next(in: 0...(2 * .pi))
                    let dist = rng.next(in: 0...0.8) * planetRadius
                    let cx = centerX + cos(angle) * dist
                    let cy = centerY + sin(angle) * dist
                    let r = (rng.next() * 0.06 + 0.01) * planetRadius
                    
                    // Perspective squash
                    let relativeDist = dist / planetRadius
                    let squash = sqrt(1.0 - relativeDist * relativeDist)
                    let rotation = angle + .pi / 2
                    
                    planetBodyContext.withCGContext { cg in
                        cg.saveGState()
                        cg.translateBy(x: cx, y: cy)
                        cg.rotate(by: rotation)
                        cg.scaleBy(x: 1.0, y: max(0.1, squash))
                        
                        let craterPath = Path(ellipseIn: CGRect(x: -r, y: -r, width: r*2, height: r*2))
                        let isShadow = rng.next() > 0.5
                        cg.setFillColor(isShadow ? UIColor.black.withAlphaComponent(0.4).cgColor : UIColor.white.withAlphaComponent(0.4).cgColor)
                        cg.addPath(craterPath.cgPath)
                        cg.fillPath()
                        
                        cg.restoreGState()
                    }
                }
            } else if config.style == .planetDust {
                let dustCount = Int(rng.next(in: 10...20))
                for _ in 0..<dustCount {
                    let angle = rng.next(in: 0...(2 * .pi))
                    let dist = rng.next(in: 0...planetRadius)
                    let dx = centerX + cos(angle) * dist
                    let dy = centerY + sin(angle) * dist
                    let r = (rng.next() * 1.0 + 0.3) * scale
                    
                    planetBodyContext.fill(Path(ellipseIn: CGRect(x: dx - r, y: dy - r, width: r*2, height: r*2)), with: .color(.white.opacity(0.8)))
                }
            }
            
            // 5. Ring Front
            if hasPlanetRings {
                context.withCGContext { cg in
                    cg.saveGState()
                    cg.translateBy(x: centerX, y: centerY)
                    cg.rotate(by: ringTilt)
                    
                    let rect = CGRect(x: -ringRadiusX, y: -ringRadiusY, width: ringRadiusX * 2, height: ringRadiusY * 2)
                    let path = Path(ellipseIn: rect)
                    
                    // To draw "front" only, we technically need to clip the back part which is behind planet.
                    // But React implementation just draws the whole ring again with higher opacity?
                    // React: "drawRingFront" draws full ellipse again.
                    // Wait, React code:
                    // drawRingBack: draws ellipse.
                    // drawPlanet: draws planet (covers back ring).
                    // drawRingFront: draws ellipse again?
                    // Ah, `ctx.ellipse(..., 0, 0, Math.PI)` -> Draws half ellipse!
                    // Back: `0, Math.PI, Math.PI * 2` (Bottom half?)
                    // Front: `0, 0, Math.PI` (Top half?)
                    
                    // In SwiftUI Path, we can use addArc.
                    // Ellipse is harder to arc.
                    // We can use scale transform on a circle arc.
                    
                    // Let's try to draw just the front arc.
                    // Front is 0 to Pi (if 0 is right, Pi is left, clockwise).
                    // We need to check orientation.
                    
                    let frontPath = Path { p in
                        p.addArc(center: .zero, radius: ringRadiusX, startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
                    }
                    // This creates a circular arc. We need to squash it.
                    
                    cg.scaleBy(x: 1.0, y: 0.3) // Apply the 0.3 aspect ratio
                    
                    context.stroke(frontPath, with: .color(baseColor.opacity(0.8)), lineWidth: 1.5 * scale)
                    
                    cg.restoreGState()
                }
            }
            
            // 6. Rays (Special)
            if star.isSpecial {
                let rayCount = Int(rng.next(in: 4...8))
                let baseAngle = rng.next() * .pi
                
                for i in 0..<rayCount {
                    let angle = baseAngle + (Double(i) * 2 * .pi) / Double(rayCount)
                    let length = planetRadius * (2.0 + rng.next() * 2.0)
                    
                    let endX = centerX + cos(angle) * length
                    let endY = centerY + sin(angle) * length
                    
                    var path = Path()
                    path.move(to: CGPoint(x: centerX, y: centerY))
                    path.addLine(to: CGPoint(x: endX, y: endY))
                    
                    context.stroke(path, with: .linearGradient(Gradient(colors: [baseColor.opacity(0.9), .clear]), startPoint: CGPoint(x: centerX, y: centerY), endPoint: CGPoint(x: endX, y: endY)), lineWidth: (1.0 + rng.next()) * scale)
                }
            }
            
        }
    }
}

```

`StarO/StarCard/StarCardModels.swift`:

```swift
import SwiftUI
import StarOracleCore

// MARK: - Star Styles

enum StarCardStyle: String, CaseIterable {
    case standard = "standard"
    case cross = "cross"
    case burst = "burst"
    case sparkle = "sparkle"
    case ringed = "ringed"
    
    // Legacy planet styles (Canvas-based)
    case planetSmooth = "planet_smooth"
    case planetCraters = "planet_craters"
    case planetSeas = "planet_seas"
    case planetDust = "planet_dust"
    case planetRings = "planet_rings"
    
    // New pixel planet styles (GL-based)
    case pixelAsteroid = "pixel_asteroid"
    case pixelBlackHole = "pixel_black_hole"
    case pixelGalaxy = "pixel_galaxy"
    case pixelGalaxyRound = "pixel_galaxy_round"
    case pixelGasPlanet = "pixel_gas_planet"
    case pixelGasPlanetLayers = "pixel_gas_planet_layers"
    case pixelIceWorld = "pixel_ice_world"
    case pixelLandMasses = "pixel_land_masses"
    case pixelLavaWorld = "pixel_lava_world"
    case pixelNoAtmosphere = "pixel_no_atmosphere"
    case pixelRivers = "pixel_rivers"
    case pixelDryTerran = "pixel_dry_terran"
    case pixelStar = "pixel_star"
    
    var isPlanet: Bool {
        self.rawValue.starts(with: "planet_")
    }
    
    var isPixelPlanet: Bool {
        self.rawValue.starts(with: "pixel_")
    }
}


// MARK: - Cosmic Themes

struct StarCardTheme {
    let name: String
    let inner: Color
    let outer: Color
    let star: Color
    let accent: Color
    
    static let all: [StarCardTheme] = [
        StarCardTheme(
            name: "Deep Space Blue",
            inner: Color(hue: 250/360, saturation: 0.4, brightness: 0.2),
            outer: Color(hue: 230/360, saturation: 0.5, brightness: 0.05),
            star: Color(hue: 220/360, saturation: 1.0, brightness: 0.85),
            accent: Color(hue: 240/360, saturation: 0.7, brightness: 0.7)
        ),
        StarCardTheme(
            name: "Nebula Purple",
            inner: Color(hue: 280/360, saturation: 0.5, brightness: 0.18),
            outer: Color(hue: 260/360, saturation: 0.6, brightness: 0.04),
            star: Color(hue: 290/360, saturation: 1.0, brightness: 0.85),
            accent: Color(hue: 280/360, saturation: 0.7, brightness: 0.7)
        ),
        StarCardTheme(
            name: "Ancient Red",
            inner: Color(hue: 340/360, saturation: 0.45, brightness: 0.15),
            outer: Color(hue: 320/360, saturation: 0.5, brightness: 0.05),
            star: Color(hue: 350/360, saturation: 1.0, brightness: 0.85),
            accent: Color(hue: 340/360, saturation: 0.7, brightness: 0.7)
        ),
        StarCardTheme(
            name: "Ice Crystal Blue",
            inner: Color(hue: 200/360, saturation: 0.5, brightness: 0.15),
            outer: Color(hue: 220/360, saturation: 0.6, brightness: 0.06),
            star: Color(hue: 190/360, saturation: 1.0, brightness: 0.85),
            accent: Color(hue: 200/360, saturation: 0.7, brightness: 0.7)
        )
    ]
}

// MARK: - Configuration

struct StarCardConfig {
    let style: StarCardStyle
    let theme: StarCardTheme
    let hasRing: Bool
    let dustCount: Int
    let seed: UInt64
    
    static func resolve(for star: Star) -> StarCardConfig {
        // Deterministic seed from Star ID or creation date
        let seedString = star.id
        let seed = UInt64(galaxyDeterministicSeed(from: seedString))
        var rng = SeededRandom(seed: seed)
        
        // Select Style
        let styles = StarCardStyle.allCases
        let styleIndex = Int(rng.next(in: 0...Double(styles.count - 1)))
        let style = styles[styleIndex]
        
        // Select Theme
        let themeIndex = Int(rng.next(in: 0...3))
        let theme = StarCardTheme.all[themeIndex]
        
        // Attributes
        let hasRing = star.isSpecial ? (rng.next() > 0.6) : false
        let dustMin = 5.0
        let dustMax = star.isSpecial ? 20.0 : 10.0
        let dustCount = Int(rng.next(in: dustMin...dustMax))
        
        return StarCardConfig(
            style: style,
            theme: theme,
            hasRing: hasRing,
            dustCount: dustCount,
            seed: seed
        )
    }
}

```

`StarO/StarCard/StarCardView.swift`:

```swift
import SwiftUI
import StarOracleCore
import UIKit

struct StarCardView: View {
    let star: Star
    let isFlipped: Bool
    let onFlip: () -> Void
    var isLoading: Bool = false
    
    // Resolved config
    private let config: StarCardConfig
    
    init(star: Star, isFlipped: Bool, onFlip: @escaping () -> Void, isLoading: Bool = false) {
        self.star = star
        self.isFlipped = isFlipped
        self.onFlip = onFlip
        self.isLoading = isLoading
        self.config = StarCardConfig.resolve(for: star)
    }
    
    var body: some View {
        ZStack {
            // Front Face
            StarCardFrontView(star: star, config: config, isLoading: isLoading)
                .opacity(isFlipped ? 0 : 1)
                .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
            
            // Back Face
            StarCardBackView(star: star, config: config)
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
        }
        // .frame(width: 300, height: 420) // Removed hardcoded frame
        .onTapGesture {
            if !isLoading {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    onFlip()
                }
            }
        }
    }
}

// MARK: - Front Face

private struct StarCardFrontView: View {
    let star: Star
    let config: StarCardConfig
    let isLoading: Bool
    
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let minDim = min(size.width, size.height)
            
            ZStack {
                // Background Gradient
                RadialGradient(
                    gradient: Gradient(colors: [config.theme.inner, config.theme.outer]),
                    center: .center,
                    startRadius: 0,
                    endRadius: max(size.width, size.height) * 0.8
                )
                
                if !isLoading {
                    // Content
                    ZStack {
                        // Background Stars
                        ForEach(0..<20) { i in
                            BackgroundStar(seed: config.seed, index: i, containerSize: size)
                        }
                        
                        // Dust Particles
                        ForEach(0..<config.dustCount, id: \.self) { i in
                            DustParticle(seed: config.seed, index: i, color: star.isSpecial ? config.theme.accent : config.theme.star, containerSize: size)
                        }
                        
                        // Main Celestial Body
                        if config.style.isPixelPlanet {
                            // New pixel planet rendering
                            PixelPlanetRenderer(config: config, star: star)
                                .frame(width: minDim * 0.7, height: minDim * 0.7)
                        } else if config.style.isPlanet {
                            PlanetView(config: config, star: star)
                                .frame(width: minDim * 0.7, height: minDim * 0.7)
                        } else {
                            // Star Pattern
                            StarPatternView(config: config, color: star.isSpecial ? config.theme.accent : config.theme.star)
                                .frame(width: minDim * 0.7, height: minDim * 0.7)
                            
                            // Central Star Glow
                            Circle()
                                .fill(star.isSpecial ? config.theme.accent : config.theme.star)
                                .frame(width: minDim * 0.06, height: minDim * 0.06)
                                .blur(radius: minDim * 0.015)
                                .overlay(
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: minDim * 0.02, height: minDim * 0.02)
                                )
                                .shadow(color: (star.isSpecial ? config.theme.accent : config.theme.star).opacity(0.8), radius: minDim * 0.04)
                        }
                    }
                }
                
                // Title / Badge
                VStack {
                    Spacer()
                    HStack {
                        if star.isSpecial {
                            HStack(spacing: 4) {
                                Image(systemName: "sparkles")
                                Text("Rare Celestial")
                            }
                            .font(.system(size: minDim * 0.04, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(config.theme.accent.opacity(0.2))
                            .foregroundColor(config.theme.accent)
                            .cornerRadius(12)
                        } else {
                            HStack(spacing: 4) {
                                Circle().fill(Color.white.opacity(0.8)).frame(width: 6, height: 6)
                                Text("Inner Star")
                            }
                            .font(.system(size: minDim * 0.04))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.1))
                            .foregroundColor(.white.opacity(0.8))
                            .cornerRadius(12)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                            Text(star.createdAt, style: .date)
                        }
                        .font(.system(size: minDim * 0.04))
                        .foregroundColor(.white.opacity(0.6))
                    }
                    .padding()
                }
            }
            .cornerRadius(size.width * 0.08)
            .overlay(
                RoundedRectangle(cornerRadius: size.width * 0.08)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.3), radius: size.width * 0.06, x: 0, y: size.width * 0.03)
        }
    }
}

// MARK: - Back Face

private struct StarCardBackView: View {
    let star: Star
    let config: StarCardConfig
    
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            
            ZStack {
                Color(hex: "#1A1B26") // Dark background
                
                VStack(spacing: size.height * 0.06) {
                    // Question
                    VStack(spacing: 8) {
                        Text("Your Question")
                            .font(.system(size: size.width * 0.04))
                            .foregroundColor(.white.opacity(0.5))
                            .textCase(.uppercase)
                            .tracking(1)
                        
                        Text("\"\(star.question)\"")
                            .font(.system(size: size.width * 0.055, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                            .padding(.horizontal)
                    }
                    
                    // Divider
                    HStack {
                        Rectangle().fill(LinearGradient(colors: [.clear, config.theme.accent.opacity(0.5)], startPoint: .leading, endPoint: .trailing)).frame(height: 1)
                        Image(systemName: "sparkle")
                            .foregroundColor(config.theme.accent)
                        Rectangle().fill(LinearGradient(colors: [config.theme.accent.opacity(0.5), .clear], startPoint: .leading, endPoint: .trailing)).frame(height: 1)
                    }
                    .padding(.horizontal, size.width * 0.15)
                    
                    // Answer
                    VStack(spacing: 12) {
                        Text("星辰的启示")
                            .font(.system(size: size.width * 0.04))
                            .foregroundColor(config.theme.accent)
                            .tracking(2)
                        
                        Text(star.answer.isEmpty ? "..." : star.answer)
                            .font(.system(size: size.width * 0.05))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .lineSpacing(6)
                            .padding(.horizontal)
                    }
                    
                    Spacer()
                    
                    // Stats
                    HStack(spacing: 20) {
                        StatItem(label: "Brightness", value: "\(Int(star.brightness * 100))%")
                        StatItem(label: "Size", value: String(format: "%.1fpx", star.size))
                    }
                    .padding(.bottom, size.height * 0.05)
                    
                    Text("再次点击卡片继续探索星空")
                        .font(.system(size: size.width * 0.03))
                        .foregroundColor(config.theme.accent.opacity(0.7))
                        .padding(.bottom, size.height * 0.04)
                }
                .padding(.top, size.height * 0.1)
            }
            .cornerRadius(size.width * 0.08)
            .overlay(
                RoundedRectangle(cornerRadius: size.width * 0.08)
                    .stroke(config.theme.accent.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.3), radius: size.width * 0.06, x: 0, y: size.width * 0.03)
        }
    }
}

private struct StatItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.4))
            Text(value)
                .font(.caption.bold())
                .foregroundColor(.white.opacity(0.9))
        }
    }
}

// MARK: - Background Elements

private struct BackgroundStar: View {
    let seed: UInt64
    let index: Int
    let containerSize: CGSize
    @State private var isAnimating = false
    
    var body: some View {
        let randomX = Double((seed &+ UInt64(index * 13)) % UInt64(containerSize.width))
        let randomY = Double((seed &+ UInt64(index * 7)) % UInt64(containerSize.height))
        let size = Double((seed &+ UInt64(index)) % 3) / 2.0 + 1.0
        
        Circle()
            .fill(Color.white.opacity(0.6))
            .frame(width: size, height: size)
            .position(x: randomX, y: randomY)
            .opacity(isAnimating ? 0.8 : 0.3)
            .scaleEffect(isAnimating ? 1.2 : 1.0)
            .animation(
                Animation.easeInOut(duration: 2.0 + Double(index % 3))
                    .repeatForever(autoreverses: true)
                    .delay(Double(index) * 0.2),
                value: isAnimating
            )
            .onAppear { isAnimating = true }
    }
}

private struct DustParticle: View {
    let seed: UInt64
    let index: Int
    let color: Color
    let containerSize: CGSize
    @State private var isAnimating = false
    
    var body: some View {
        let angle = Double((seed &+ UInt64(index)) % 360) * .pi / 180
        let dist = 50.0 + Double((seed &+ UInt64(index * 5)) % 50)
        let size = Double((seed &+ UInt64(index * 2)) % 20) / 10.0 + 1.0
        
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .offset(x: cos(angle) * dist, y: sin(angle) * dist)
            .opacity(isAnimating ? 0.7 : 0)
            .offset(x: isAnimating ? 5 : -5, y: isAnimating ? -5 : 5) // Slight drift
            .animation(
                Animation.easeInOut(duration: 3.0 + Double(index % 2))
                    .repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear { isAnimating = true }
    }
}

// MARK: - Pixel Planet Renderer

private struct PixelPlanetRenderer: View {
    let config: StarCardConfig
    let star: Star
    @State private var error: String?
    
    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            
            if let planet = createPlanet(for: config.style, seed: Int(config.seed)) {
                ZStack {
                    // 完全对齐原版：传递固定像素预算（默认 100），让 PlanetCanvasView 依据该值与 relativeScale
                    // 计算 backing store 的 contentScaleFactor。这里不额外乘以屏幕 scale，也不改行星的 uniforms。
                    PlanetCanvasView(
                        planet: planet,
                        pixels: 100,
                        playing: true,
                        renderError: $error
                    )
                    .clipShape(Circle())
                    
                    // Overlay error if present (even if planet created, render might fail)
                    if let error = error {
                        Text(error)
                            .font(.caption2)
                            .foregroundColor(.red)
                            .background(Color.black.opacity(0.7))
                            .padding()
                    }
                }
            } else {
                // Fallback
                Circle()
                    .fill(config.theme.inner)
                    .overlay(
                        VStack {
                            Text("?")
                                .font(.system(size: size * 0.3))
                                .foregroundColor(config.theme.star)
                            if let error = error {
                                Text(error)
                                    .font(.caption2)
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                                    .padding()
                            }
                        }
                    )
            }
        }
    }
    
    private func createPlanet(for style: StarCardStyle, seed: Int) -> PlanetBase? {
        do {
            var rng = RandomStream(seed: seed)
            
            let planet: PlanetBase
            switch style {
            case .pixelAsteroid:
                planet = try AsteroidPlanet()
            case .pixelBlackHole:
                planet = try BlackHolePlanet()
            case .pixelGalaxy:
                planet = try GalaxyPlanet()
            case .pixelGalaxyRound:
                planet = try CircularGalaxyPlanet()
            case .pixelGasPlanet:
                planet = try GasPlanetPlanet()
            case .pixelGasPlanetLayers:
                planet = try GasPlanetLayersPlanet()
            case .pixelIceWorld:
                planet = try IceWorldPlanet()
            case .pixelLandMasses:
                planet = try LandMassesPlanet()
            case .pixelLavaWorld:
                planet = try LavaWorldPlanet()
            case .pixelNoAtmosphere:
                planet = try NoAtmospherePlanet()
            case .pixelRivers:
                planet = try RiversPlanet()
            case .pixelDryTerran:
                planet = try DryTerranPlanet()
            case .pixelStar:
                planet = try StarPlanet()
            default:
                return nil
            }
            
            // 完全对齐原版：只设置 seed；不在此处设置 rotation、light、随机颜色，也不做任何随机化配置
            // rotation 默认为 0；light_origin 使用各行星配置默认值；colors 使用各行星配置默认梯度
            planet.setSeed(seed, rng: &rng)
            planet.setPixels(100) // 完全对齐原版 UI：默认像素采样=100
            
            return planet
        } catch {
            print("Failed to create planet: \(error)")
            DispatchQueue.main.async {
                self.error = "\(error)"
            }
            return nil
        }
    }
}

```

`StarO/StarCard/StarPatternView.swift`:

```swift
import SwiftUI

struct StarPatternView: View {
    let config: StarCardConfig
    let color: Color
    
    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let center = CGPoint(x: proxy.size.width/2, y: proxy.size.height/2)
            
            ZStack {
                switch config.style {
                case .standard:
                    StandardStarView(color: color, size: size)
                case .cross:
                    CrossStarView(color: color, size: size)
                case .burst:
                    BurstStarView(color: color, seed: config.seed, size: size)
                case .sparkle:
                    SparkleStarView(color: color, seed: config.seed, size: size)
                case .ringed:
                    RingedStarView(color: color, hasRing: config.hasRing, size: size)
                default:
                    EmptyView()
                }
            }
            .position(center)
        }
    }
}

// MARK: - Subviews

private struct StandardStarView: View {
    let color: Color
    let size: CGFloat
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            ForEach(0..<8) { i in
                RayLine(angle: .degrees(Double(i) * 45), length: size * 0.2)
                    .stroke(color, lineWidth: size * 0.01)
                    .opacity(isAnimating ? 0.8 : 0)
                    .animation(
                        Animation.easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.1),
                        value: isAnimating
                    )
            }
        }
        .onAppear { isAnimating = true }
    }
}

private struct CrossStarView: View {
    let color: Color
    let size: CGFloat
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            ForEach(0..<4) { i in
                let isVertical = i % 2 == 0
                Rectangle()
                    .fill(color)
                    .frame(
                        width: isVertical ? size * 0.01 : size * 0.15,
                        height: isVertical ? size * 0.15 : size * 0.01
                    )
                    .scaleEffect(isAnimating ? 1 : 0)
                    .opacity(isAnimating ? 0.8 : 0)
                    .rotationEffect(.degrees(isAnimating ? 180 : 0))
                    .animation(
                        Animation.easeInOut(duration: 2.0)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.2),
                        value: isAnimating
                    )
            }
        }
        .onAppear { isAnimating = true }
    }
}

private struct BurstStarView: View {
    let color: Color
    let seed: UInt64
    let size: CGFloat
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            ForEach(0..<12) { i in
                let randomLen = (Double((seed &+ UInt64(i)) % 30) + 20.0) / 50.0 * (size * 0.25)
                let randomWidth = (Double((seed &+ UInt64(i*2)) % 15) / 10.0 + 0.5) * (size * 0.005)
                
                RayLine(angle: .degrees(Double(i) * 30), length: randomLen)
                    .stroke(color, lineWidth: randomWidth)
                    .opacity(isAnimating ? 0.7 : 0)
                    .animation(
                        Animation.easeInOut(duration: 2.0 + Double((seed &+ UInt64(i)) % 10)/10.0)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.05),
                        value: isAnimating
                    )
            }
        }
        .onAppear { isAnimating = true }
    }
}

private struct SparkleStarView: View {
    let color: Color
    let seed: UInt64
    let size: CGFloat
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            ForEach(0..<8) { i in
                let angle = Double(i) * .pi / 4
                let dist = (15.0 + Double((seed &+ UInt64(i)) % 20)) / 35.0 * (size * 0.2)
                let r = (1.0 + Double((seed &+ UInt64(i*3)) % 20) / 10.0) * (size * 0.01)
                
                Circle()
                    .fill(color)
                    .frame(width: r*2, height: r*2)
                    .offset(x: cos(angle) * dist, y: sin(angle) * dist)
                    .scaleEffect(isAnimating ? 1 : 0)
                    .opacity(isAnimating ? 0.9 : 0)
                    .animation(
                        Animation.easeInOut(duration: 1.0 + Double((seed &+ UInt64(i)) % 10)/10.0)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.1),
                        value: isAnimating
                    )
            }
        }
        .onAppear { isAnimating = true }
    }
}

private struct RingedStarView: View {
    let color: Color
    let hasRing: Bool
    let size: CGFloat
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            if !hasRing {
                Circle()
                    .stroke(color, style: StrokeStyle(lineWidth: size * 0.005, dash: [size * 0.005, size * 0.01]))
                    .frame(width: size * 0.15, height: size * 0.15)
                    .scaleEffect(isAnimating ? 1.2 : 1.0)
                    .opacity(isAnimating ? 0.6 : 0.3)
                    .animation(
                        Animation.easeInOut(duration: 3.0)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
            }
        }
        .onAppear { isAnimating = true }
    }
}

// MARK: - Shapes

private struct RayLine: Shape {
    let angle: Angle
    let length: Double
    
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let end = CGPoint(
            x: center.x + cos(angle.radians) * length,
            y: center.y + sin(angle.radians) * length
        )
        var path = Path()
        path.move(to: center)
        path.addLine(to: end)
        return path
    }
}

```

`StarO/StarCollectionOverlay.swift`:

```swift
import SwiftUI
import StarOracleCore

enum StarCollectionFilter: CaseIterable {
  case all, special, recent

  var label: String {
    switch self {
    case .all: return "All"
    case .special: return "Special"
    case .recent: return "Recent"
    }
  }
}

struct StarCollectionOverlay: View {
  @Binding var isPresented: Bool
  let constellationStars: [Star]
  let inspirationStars: [Star]

  @State private var searchText = ""
  @State private var filter: StarCollectionFilter = .all
  @State private var flippedIds = Set<String>()
  @State private var visibleCount = 18

  private let batchSize = 12

  var body: some View {
    ZStack {
      Color.black.opacity(0.85)
        .ignoresSafeArea()
        .onTapGesture {
          withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            isPresented = false
          }
        }

      VStack(spacing: 0) {
        overlayHeader
        gridContent
      }
      .frame(maxWidth: 1100, maxHeight: 720)
      .background(
        RoundedRectangle(cornerRadius: 32, style: .continuous)
          .fill(Color(red: 13/255, green: 18/255, blue: 30/255).opacity(0.96))
          .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
              .stroke(Color.white.opacity(0.08), lineWidth: 1)
          )
      )
      .padding(.horizontal, 24)
      .transition(.scale.combined(with: .opacity))
    }
    .onChange(of: isPresented) { _, newValue in
      if newValue {
        visibleCount = 18
        searchText = ""
        filter = .all
        flippedIds = []
      }
    }
  }

  private var overlayHeader: some View {
    HStack(spacing: 12) {
      Button {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
          isPresented = false
        }
      } label: {
        LucideArrowLeftIcon(size: 18)
          .frame(width: 36, height: 36)
          .foregroundStyle(.white)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)

      Spacer()

      LucideSearchIcon(size: 18)
        .frame(width: 36, height: 36)
        .foregroundStyle(.white)
        .contentShape(Rectangle())
    }
    .padding(.horizontal, 24)
    .padding(.top, 12)
    .frame(height: 60)
  }

  private var gridContent: some View {
    ScrollView {
      LazyVGrid(columns: [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
      ], spacing: 20) {
        ForEach(displayedStars) { star in
          StarCardView(
            star: star,
            isFlipped: flippedIds.contains(star.id),
            onFlip: { toggleFlip(for: star.id) }
          )
          .aspectRatio(0.7, contentMode: .fit)
          .onAppear {
            if star.id == displayedStars.last?.id {
              loadMore()
            }
          }
        }
      }
      .padding(.horizontal, 32)
      .padding(.vertical, 24)

      if visibleCount < filteredStars.count {
        ProgressView("加载更多星卡...")
          .tint(.white)
          .padding(.bottom, 28)
      } else if filteredStars.isEmpty {
        VStack(spacing: 12) {
          Image(systemName: "sparkles")
            .font(.largeTitle)
          Text("没有匹配的星卡")
            .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, minHeight: 240)
      }
    }
  }

  private var filteredStars: [Star] {
    filterStars(
      stars: mergedStars(
        constellation: constellationStars,
        inspiration: inspirationStars
      ),
      filter: filter,
      query: searchText
    )
  }

  private var displayedStars: [Star] {
    Array(filteredStars.prefix(visibleCount))
  }

  private func toggleFlip(for id: String) {
    if flippedIds.contains(id) {
      flippedIds.remove(id)
    } else {
      flippedIds.insert(id)
    }
  }

  private func loadMore() {
    guard visibleCount < filteredStars.count else { return }
    let next = min(filteredStars.count, visibleCount + batchSize)
    withAnimation(.easeOut(duration: 0.35)) {
      visibleCount = next
    }
  }
}

struct StarCollectionPane: View {
  let constellationStars: [Star]
  let inspirationStars: [Star]
  var onBack: () -> Void

  @State private var searchText = ""
  @State private var filter: StarCollectionFilter = .all
  @State private var flippedIds = Set<String>()
  @State private var visibleCount = 18

  private let batchSize = 18

  var body: some View {
    VStack(spacing: 0) {
      paneHeader
      gridContent
    }
    .padding(.top, 12)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .background(
      LinearGradient(
        colors: [
          Color(red: 9/255, green: 12/255, blue: 20/255),
          Color(red: 12/255, green: 18/255, blue: 32/255)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .ignoresSafeArea()
    )
  }

  private var paneHeader: some View {
    // Single-line header aligned with home top menu height/offset
    HStack(spacing: 12) {
      // Back arrow (Lucide)
      Button {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { onBack() }
      } label: {
        LucideArrowLeftIcon(size: 18)
          .frame(width: 36, height: 36)
          .foregroundStyle(.white)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)

      Spacer()

      // Search icon only (Lucide)
      LucideSearchIcon(size: 18)
        .frame(width: 36, height: 36)
        .foregroundStyle(.white)
    }
    .padding(.horizontal, 24)
    .frame(height: 60)
  }

  // controls removed per new design

  private var gridContent: some View {
    ScrollView {
      LazyVGrid(columns: [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
      ], spacing: 20) {
        ForEach(displayedStars) { star in
          StarCardView(
            star: star,
            isFlipped: flippedIds.contains(star.id),
            onFlip: { toggleFlip(for: star.id) }
          )
          .aspectRatio(0.7, contentMode: .fit)
          .onAppear {
            if star.id == displayedStars.last?.id {
              loadMore()
            }
          }
        }
      }
      .padding(.horizontal, 32)
      .padding(.bottom, 32)

      if visibleCount < filteredStars.count {
        ProgressView("加载更多星卡...")
          .tint(.white)
          .padding(.bottom, 40)
      } else if filteredStars.isEmpty {
        VStack(spacing: 12) {
          Image(systemName: "sparkles")
            .font(.largeTitle)
          Text("没有匹配的星卡")
            .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, minHeight: 240)
      }
    }
  }

  private var filteredStars: [Star] {
    filterStars(
      stars: mergedStars(
        constellation: constellationStars,
        inspiration: inspirationStars
      ),
      filter: filter,
      query: searchText
    )
  }

  private var displayedStars: [Star] {
    Array(filteredStars.prefix(visibleCount))
  }

  private func toggleFlip(for id: String) {
    if flippedIds.contains(id) {
      flippedIds.remove(id)
    } else {
      flippedIds.insert(id)
    }
  }

  private func loadMore() {
    guard visibleCount < filteredStars.count else { return }
    let next = min(filteredStars.count, visibleCount + batchSize)
    withAnimation(.easeOut(duration: 0.35)) {
      visibleCount = next
    }
  }
}

private func mergedStars(constellation: [Star], inspiration: [Star]) -> [Star] {
  var unique = [String: Star]()
  (inspiration + constellation).forEach { star in
    unique[star.id] = star
  }
  return unique.values.sorted(by: { $0.createdAt > $1.createdAt })
}

private func filterStars(
  stars: [Star],
  filter: StarCollectionFilter,
  query: String
) -> [Star] {
  stars.filter { star in
    let matchesQuery = query.isEmpty ||
    star.question.localizedCaseInsensitiveContains(query) ||
    star.answer.localizedCaseInsensitiveContains(query)

    switch filter {
    case .all:
      return matchesQuery
    case .special:
      return star.isSpecial && matchesQuery
    case .recent:
      guard let days = Calendar.current.dateComponents([.day], from: star.createdAt, to: Date()).day else {
        return false
      }
      return days <= 7 && matchesQuery
    }
  }
}

```

`StarO/StarDetailSheet.swift`:

```swift
import SwiftUI
import StarOracleCore

struct StarDetailSheet: View {
  let star: Star
  var onDismiss: () -> Void

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          Text(star.question)
            .font(.title3.weight(.semibold))
          VStack(alignment: .leading, spacing: 10) {
            section(title: "星语回应", icon: "sparkles") {
              Text(star.answer.isEmpty ? "星语正在收集回应…" : star.answer)
            }
            if let summary = star.cardSummary, !summary.isEmpty {
              section(title: "摘要", icon: "note.text") {
                Text(summary)
              }
            }
            if !star.tags.isEmpty {
              section(title: "标签", icon: "tag") {
                TagGrid(tags: star.tags)
              }
            }
            section(title: "洞察", icon: "chart.bar") {
              VStack(alignment: .leading, spacing: 6) {
                if let insight = star.insightLevel {
                  Text("洞察等级：\(insight.description) — \(insight.value)")
                }
                if let category = readableCategory(star.primaryCategory) {
                  Text("主题类别：\(category)")
                }
                if let follow = star.suggestedFollowUp, !follow.isEmpty {
                  Text("建议追问：\(follow)")
                }
              }
            }
          }
          .padding(18)
          .background(.ultraThinMaterial)
          .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .padding(20)
      }
      .navigationTitle("星卡详情")
      .toolbar {
        ToolbarItem(placement: .automatic) {
          Button("完成") { onDismiss() }
        }
      }
    }
  }

  private func section<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Label(title, systemImage: icon)
        .font(.subheadline.weight(.medium))
        .foregroundStyle(.primary)
      content()
        .font(.footnote)
        .foregroundColor(.primary.opacity(0.85))
    }
  }

  private func readableCategory(_ category: String) -> String? {
    switch category {
    case "relationships": return "人际关系"
    case "personal_growth": return "自我成长"
    case "career_and_purpose": return "事业与目标"
    case "emotional_wellbeing": return "情绪福祉"
    case "creativity_and_passion": return "创造与热情"
    case "daily_life": return "日常生活"
    case "philosophy_and_existence": return "哲学与存在"
    default: return nil
    }
  }
}

private struct TagGrid: View {
  let tags: [String]

  private var columns: [GridItem] {
    [GridItem(.adaptive(minimum: 80), spacing: 8, alignment: .leading)]
  }

  var body: some View {
    LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
      ForEach(tags, id: \.self) { tag in
        Text(tag)
          .font(.caption2)
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(Color.secondary.opacity(0.15))
          .clipShape(Capsule())
      }
    }
  }
}

```

`StarO/StarOApp.swift`:

```swift
//
//  StarOApp.swift
//  StarO
//
//  Created by pot on 11/8/25.
//

import SwiftUI

@main
struct StarOApp: App {
  @StateObject private var environment = AppEnvironment()

  var body: some Scene {
    WindowGroup {
      RootView()
        .environmentObject(environment)
        .environmentObject(environment.starStore)
        .environmentObject(environment.chatStore)
        .environmentObject(environment.galaxyStore)
        .environmentObject(environment.galaxyGridStore)
        .environmentObject(environment.conversationStore)
        .environmentObject(environment.chatBridge)
    }
  }
}

```

`StarO/StarRayIconView.swift`:

```swift
import SwiftUI

struct StarRayIconView: View {
  var size: CGFloat = 20
  var color: Color = Color(red: 168/255, green: 85/255, blue: 247/255) // #a855f7

  var body: some View {
    Canvas { context, canvasSize in
      let scale = min(canvasSize.width, canvasSize.height) / 24.0
      context.scaleBy(x: scale, y: scale)
      let tx = (canvasSize.width / scale - 24.0) / 2.0
      let ty = (canvasSize.height / scale - 24.0) / 2.0
      context.translateBy(x: tx, y: ty)

      let center = CGPoint(x: 12, y: 12)
      let halfLen: CGFloat = 8
      let lineWidth: CGFloat = 2

      for index in 0..<8 {
        let angle = Double(index) * (.pi / 4)
        let dx = CGFloat(cos(angle)) * halfLen
        let dy = CGFloat(sin(angle)) * halfLen
        var path = Path()
        path.move(to: CGPoint(x: center.x - dx, y: center.y - dy))
        path.addLine(to: CGPoint(x: center.x + dx, y: center.y + dy))
        context.stroke(
          path,
          with: .color(color),
          style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
        )
      }
    }
    .frame(width: size, height: size)
  }
}

```

`StarO/StreamingClient.swift`:

```swift
import Foundation

/// Lightweight SSE client for OpenAI-compatible /v1/chat/completions streaming.
/// Uses URLSession.bytes(for:) to iterate server-sent event lines.
final class StreamingClient: @unchecked Sendable {
  private var currentTask: Task<Void, Never>?

  private final class ChunkHandler: @unchecked Sendable {
    private let block: @Sendable (String) -> Void
    init(_ block: @escaping @Sendable (String) -> Void) { self.block = block }
    func call(_ chunk: String) { block(chunk) }
  }

  private final class CompletionHandler: @unchecked Sendable {
    private let block: @Sendable (_ fullText: String?, _ error: Error?) -> Void
    init(_ block: @escaping @Sendable (_ fullText: String?, _ error: Error?) -> Void) { self.block = block }
    func call(_ text: String?, _ error: Error?) { block(text, error) }
  }

  private struct StreamingJob: @unchecked Sendable {
    var request: URLRequest
    let chunkHandler: ChunkHandler
    let completionHandler: CompletionHandler

    func run() async {
      var full = ""
      do {
        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        guard let http = response as? HTTPURLResponse else {
          completionHandler.call(nil, StreamingError.invalidResponse)
          return
        }
        guard (200..<300).contains(http.statusCode) else {
          let text = try? String(
            data: Data(try await bytes.reduce(into: [UInt8](), { $0.append($1) })),
            encoding: .utf8
          )
          completionHandler.call(nil, StreamingError.http(status: http.statusCode, body: text ?? ""))
          return
        }
        // 非 SSE 响应回退为一次性 JSON 解析（OpenAI 兼容）
        let contentType = http.value(forHTTPHeaderField: "Content-Type") ?? ""
        let isSSE = contentType.lowercased().contains("text/event-stream")
        if !isSSE {
          let raw = try await bytes.reduce(into: [UInt8]()) { $0.append($1) }
          let data = Data(raw)
          if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
             let choices = json["choices"] as? [[String: Any]],
             let message = choices.first?["message"] as? [String: Any],
             let content = message["content"] as? String, !content.isEmpty {
            full = content
            completionHandler.call(full, nil)
            return
          }
          // 无法解析，返回错误
          let text = String(data: data, encoding: .utf8) ?? ""
          completionHandler.call(nil, StreamingError.http(status: 200, body: "Invalid non-SSE response: \(text.prefix(200))"))
          return
        }
        for try await line in bytes.lines {
          try Task.checkCancellation()
          let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
          guard trimmed.hasPrefix("data: ") else { continue }
          let payload = String(trimmed.dropFirst(6))
          if payload == "[DONE]" { break }
          guard let data = payload.data(using: .utf8) else { continue }
          if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
             let choices = json["choices"] as? [[String: Any]],
             let delta = choices.first?["delta"] as? [String: Any],
             let content = delta["content"] as? String,
             !content.isEmpty {
            full += content
            chunkHandler.call(content)
          }
        }
        completionHandler.call(full, nil)
      } catch is CancellationError {
        completionHandler.call(full.isEmpty ? nil : full, StreamingError.cancelled)
      } catch {
        completionHandler.call(full.isEmpty ? nil : full, error)
      }
    }
  }

  private enum StreamingError: LocalizedError {
    case invalidResponse
    case http(status: Int, body: String)
    case cancelled

    var errorDescription: String? {
      switch self {
      case .invalidResponse:
        return "SSE 响应无效"
      case let .http(status, body):
        return "SSE 请求失败 (\(status))：\(body)"
      case .cancelled:
        return "请求已取消"
      }
    }
  }

  struct Message: Codable {
    let role: String
    let content: String
  }

  struct RequestBody: Codable {
    let model: String
    let messages: [Message]
    let temperature: Double?
    let maxTokens: Int?
    let stream: Bool

    enum CodingKeys: String, CodingKey {
      case model
      case messages
      case temperature
      case maxTokens = "max_tokens"
      case stream
    }
  }

  func startChatCompletionStream(
    endpoint: String,
    apiKey: String,
    model: String,
    messages: [Message],
    temperature: Double?,
    maxTokens: Int?,
    onChunk: @escaping @Sendable (String) -> Void,
    onComplete: @escaping @Sendable (_ fullText: String?, _ error: Error?) -> Void
  ) {
    cancel()
    NSLog("🚀 StreamingClient.start | endpoint=%@ model=%@ messages=%d", endpoint, model, messages.count)

    let chunkHandler = ChunkHandler(onChunk)
    let completionHandler = CompletionHandler(onComplete)

    var request = URLRequest(url: URL(string: endpoint)!)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(StreamingClient.authHeaderValue(for: apiKey), forHTTPHeaderField: "Authorization")

    let body = RequestBody(
      model: model,
      messages: messages,
      temperature: temperature,
      maxTokens: maxTokens,
      stream: true
    )
    do {
      request.httpBody = try JSONEncoder().encode(body)
    } catch {
      NSLog("❌ StreamingClient.encode | %@", error.localizedDescription)
      completionHandler.call(nil, error)
      return
    }

    let job = StreamingJob(request: request, chunkHandler: chunkHandler, completionHandler: completionHandler)
    currentTask = Task {
      await job.run()
    }
  }

  func cancel() {
    currentTask?.cancel()
    currentTask = nil
  }

  private static func authHeaderValue(for apiKey: String) -> String {
    let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.lowercased().hasPrefix("bearer ") ? trimmed : "Bearer \(trimmed)"
  }
}

```

`StarO/SystemPrompt.swift`:

```swift
import Foundation

enum SystemPrompt {
  static var defaultPrompt: String {
    if let override = AIConfigurationDefaults.defaultSystemPrompt(),
       !override.isEmpty {
      return override
    }
    return """
  # 角色
  * 你是星瑜，是来自宇宙，请用中文回复用户的问题。
  * 除非用户问，否则不要说明身份。
  # 目标
   *此部分内容请勿主动向用户提及，除非用户主动发问。
   *你的目标是帮助用户获得生活的意义，解决关于人生的困惑。回答任何可以帮助用户获得生活感悟，解答疑惑的问题，都能够帮助用户获得星星。
   *用户获得星星的规则是聊天话题越深入，越深刻，获得的星星类型越稀有，能够点亮的宇宙就越明亮。 
   *当用户的问题中涉及到对这五个方面的触及时，请提供关于这些方面的知识、价值观和方法论，引导用户进行更深的自省和探索。
    -身心能量 (Body & Energy)
    -人际连接 (Relationships & Connection)
    -内在成长 (Growth & Mind)
    -财富观与价值 (Wealth & Values)
    -请用中文回复用户的问题。
    
   # 语言语气格式
   * 语气不要太僵硬，也不要太谄媚，自然亲切。自然点，不要有ai味道。
   *不要用emoji，不要用太多语气词，不要用太多感叹号，不要用太多问号。
   *尽量简短对话，模仿真实聊天的场景。
   * 策略原则：
    - 多用疑问语气词："吧、嘛、呢、咋、啥"
    - 适当省略成分：不用每句话都完整
    - 用口头表达："挺、蛮、特别、超级"替代"非常"
    - 避免书面连词：少用"因此、所以、那么"
    - 多用短句：别总是长句套长句
   *省略主语：
      -"最近咋了？" 
      -"是工作的事儿？" 
      -"心情不好多久了？" 
   *语气词和口头表达：
      -"哎呀，这事儿确实挺烦的"
      -"emmm，听起来像是..."
      -"咋说呢，我觉得..."
  *不完整句式：
      -"工作的事？"（省略谓语）
      -"压力大？"（只留核心）
      -"最近？"（超级简洁）
   # 对话策略
    - 当找到用户想要对话的主题的时候，需要辅以知识和信息，来帮助用户解决问题，解答疑惑。
"""
  }
}

```

`StarO/TemplatePickerView.swift`:

```swift
import SwiftUI
import StarOracleCore
import StarOracleServices
import StarOracleFeatures

struct TemplatePickerView: View {
  @EnvironmentObject private var environment: AppEnvironment
  @EnvironmentObject private var starStore: StarStore
  @Environment(\.dismiss) private var dismiss

  @State private var templates: [ConstellationTemplate] = []
  @State private var isLoading = false
  @State private var errorMessage: String?

  var body: some View {
    NavigationStack {
      Group {
        if isLoading {
          ProgressView("正在载入模板…")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let errorMessage {
          VStack(spacing: 16) {
            Text(errorMessage)
              .multilineTextAlignment(.center)
            Button("重试") {
              loadTemplates()
            }
            .buttonStyle(.bordered)
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if templates.isEmpty {
          Text("暂未发现可用模板")
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
          List {
            Section {
              ForEach(templates) { template in
                TemplateRow(template: template) {
                  apply(template: template)
                }
              }
            } footer: {
              Text("模板将替换当前星图为预设结构，你仍可在其基础上继续生成新的星卡。")
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
          }
          #if os(iOS)
          .listStyle(.insetGrouped)
          #else
          .listStyle(.automatic)
          #endif
        }
      }
      .navigationTitle("选择模板")
      .toolbar {
        ToolbarItem(placement: .automatic) {
          Button("关闭") { dismiss() }
        }
      }
      .task { loadTemplates() }
    }
  }

  private func loadTemplates() {
    isLoading = true
    errorMessage = nil
    Task { @MainActor in
      let result = await environment.templateService.availableTemplates()
      templates = result
      isLoading = false
    }
  }

  private func apply(template: ConstellationTemplate) {
    Task { @MainActor in
      do {
        try await starStore.applyTemplate(template)
        dismiss()
      } catch {
        errorMessage = "应用模板失败：\(error.localizedDescription)"
      }
    }
  }
}

private struct TemplateRow: View {
  let template: ConstellationTemplate
  let onApply: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text(template.chineseName)
            .font(.headline)
          Text(template.description)
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        Spacer()
        Text(template.elementLabel)
          .font(.caption2)
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(elementColor.opacity(0.15))
          .clipShape(Capsule())
      }
      Button(role: .none) {
        onApply()
      } label: {
        Text("应用此模板")
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.borderedProminent)
    }
    .padding(.vertical, 8)
  }

  private var elementColor: Color {
    switch template.element {
    case .fire: return .orange
    case .earth: return .green
    case .air: return .blue
    case .water: return .purple
    }
  }
}

private extension ConstellationTemplate {
  var elementLabel: String {
    switch element {
    case .fire: return "火元素"
    case .earth: return "土元素"
    case .air: return "风元素"
    case .water: return "水元素"
    }
  }
}

```

`StarO/UI/LucideIcons.swift`:

```swift
import SwiftUI

// Minimal Lucide-like icons implemented with SwiftUI Paths using 24x24 viewBox
// Stroke style matches Lucide (round caps/joins, width=2)

struct LucideArrowLeftIcon: View {
    var size: CGFloat = 18
    var color: Color = .white

    var body: some View {
        ZStack {
            Path { p in
                p.move(to: CGPoint(x: 15, y: 19))
                p.addLine(to: CGPoint(x: 9, y: 12))
                p.addLine(to: CGPoint(x: 15, y: 5))
            }
            .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        }
        .frame(width: 24, height: 24)
        .scaleEffect(size / 24)
    }
}

struct LucideSearchIcon: View {
    var size: CGFloat = 18
    var color: Color = .white

    var body: some View {
        ZStack {
            Circle()
                .stroke(color, lineWidth: 2)
                .frame(width: 16, height: 16)
                .offset(x: -1, y: -1)

            Path { p in
                p.move(to: CGPoint(x: 21, y: 21))
                p.addLine(to: CGPoint(x: 16.65, y: 16.65))
            }
            .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }
        .frame(width: 24, height: 24)
        .scaleEffect(size / 24)
    }
}

```

`StarO/Utils/Color+Hex.swift`:

```swift
import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

```