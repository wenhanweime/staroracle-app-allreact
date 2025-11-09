# Swift 项目结构与初始化方案

## 1. 总体目标
- 构建完全原生的 SwiftUI 应用，取代现有 Capacitor + React 方案，同时保留银河背景、星卡管理、聊天浮层等核心体验。
- 通过模块化目录与 Swift Package Manager（SPM）实现业务逻辑、服务层、UI 分层，方便后续维护与扩展。
- 保留与现有 JavaScript 逻辑一致的数据模型、AI 接口契约，确保迁移期间业务行为可验证。

## 2. 推荐目录结构
```
StarOracle/
├─ Packages/
│  ├─ StarOracleCore/            # 数据模型、状态存储、协议
│  ├─ StarOracleServices/        # AI、声音、触觉、资源、持久化
│  ├─ StarOracleFeatures/        # 功能模块（星卡、银河、聊天等）
│  └─ StarOracleUIComponents/    # 通用 UI 组件库
├─ StarOracleApp/                # 主 App target (SwiftUI)
│  ├─ App/                       # App 入口、AppState、SceneDelegate
│  ├─ Bootstrap/                 # 依赖注入、环境配置、构建器
│  ├─ Features/                  # 组合 Features 中的 ViewModel + View
│  ├─ Resources/                 # Assets.xcassets、Fonts、Localization
│  └─ Support/                   # App 常量、调试工具、扩展
└─ Tests/
   ├─ CoreTests/
   ├─ ServicesTests/
   └─ FeatureSnapshotTests/
```
- 可先以单一 Xcode Workspace 管理，后续逐步拆分为独立 SPM 包；迁移初期也可将 Packages 以内嵌文件夹方式存在，待稳定后再拆包。

## 3. 模块职责划分

### 3.1 StarOracleCore
- **数据模型**：`Star`, `Connection`, `Constellation`, `ChatMessage`, `AwarenessInsight`, `GalaxyHotspot`, `Ripple` 等，全部使用 `struct` + `Codable` + `Identifiable`。
- **状态协议**：定义 `StarStoreProtocol`, `ChatStoreProtocol`, `GalaxyInteractionStoreProtocol`，描述对外暴露的属性与方法。
- **工具算法**：迁移 `generateSmartConnections`、随机星图算法、噪声函数等纯计算逻辑。

### 3.2 StarOracleServices
- **AIService**：封装对接 OpenAI / 自建 API，支持流式响应（Combine + AsyncSequence），并提供觉察分析、标题生成接口。
- **InspirationService / TemplateService**：提供灵感卡与模板数据源（可先加载本地 JSON，后续再接入远程配置）。
- **SoundService**：封装 `AVAudioPlayer`/`AVAudioEngine`，支持预加载、并发播放、ambient 循环。
- **HapticService**：包装 `UIImpactFeedbackGenerator`、`UINotificationFeedbackGenerator`。
- **PreferenceService**：管理用户设置、AI 配置的本地持久化（`UserDefaults` 或 `FileManager`）。
- **ResourceService**：统一加载图片、动画数据、Shader、JSON 等资源。

### 3.3 StarOracleFeatures
- **StarFeature**：星卡创建、模板应用、灵感卡逻辑；提供 `StarViewModel` 供 UI 层使用。
- **ChatFeature**：聊天消息管理、流式渲染、觉察分析；包括原生浮层输入组件的 ViewModel。
- **GalaxyFeature**：银河背景、交互热点、涟漪动画算法；后期可拆分 `GalaxyCanvas` + `GalaxyInteraction`.
- **MenuFeature / DrawerFeature**：侧边菜单、抽屉配置面板等通用功能。
- 每个 Feature 依赖 Core 模型 + Services 服务，通过 DI 注入。

### 3.4 StarOracleUIComponents
- 封装 SwiftUI 通用组件（按钮、玻璃拟态背景、卡片翻转动画、模态容器）。
- 集中存放自定义 Modifier、Style、动画工具，便于 Features 组合复用。

## 4. 主 App 结构
- `StarOracleApp.swift`：使用 `@main` 启动，初始化依赖注入容器 `AppContainer`。
- `AppState`：持有共享的 Store 实例（`StarStore`, `ChatStore`, `GalaxyStore`），通过 `EnvironmentObject` 注入根视图树。
- `Bootstrap/DependencyBuilder.swift`：负责将 Services 构建为单例或 scoped 实例，注入各 Feature ViewModel。
- `RootView.swift`：原首页容器，包含银河背景、顶部导航、抽屉、聊天浮层；将 React 组件映射为 SwiftUI 视图组合。
- `SceneDelegate`（如需多 scene 控制）：处理后台/前台、URL scheme 等。

## 5. 初始化流程建议
1. **创建 Workspace**：在现有 `ios/` 目录旁新增 `StarOracle.xcworkspace`，内含 `StarOracleApp` 与多个 Swift Package。
2. **设定最低版本与依赖**：目标 iOS 17+（便于使用最新 SwiftUI API），在 `Package.swift` 中声明常用依赖（如需网络层可选用 `Alamofire`，否则保留原生 `URLSession`）。
3. **实现基础模型**：先迁移 `Star`、`Connection`、`ChatMessage` 等数据结构与枚举，编写单元测试验证序列化。
4. **搭建服务骨架**：为 `AIService`, `SoundService`, `HapticService`, `PreferenceService` 编写协议与空实现，确保依赖注入无环。
5. **构建 Store 雏形**：仿照 Zustand 功能，在 `StarStore`, `ChatStore`, `GalaxyStore` 中实现最小可运行逻辑（例如加载静态星图、展示空白聊天）。
6. **搭建 RootView**：创建 SwiftUI 主页骨架，集成背景占位、顶部导航、底部输入抽屉（占位），确保 App 可以运行。
7. **集成服务实现**：逐步填充 AI 流式、声音、触觉等，实现与 UI 的联动。
8. **资源迁移**：将图片、音效、模板 JSON 等放入 `Resources` 并在 `ResourceService` 中加载，确保与新模型兼容。

## 6. 迁移阶段的互操作策略
- 在完全迁移前，可保留 Capacitor 工程作为回退方案；SwiftUI App 可作为同一 Workspace 下的新 target，与旧工程并行测试。
- 若需复用现有 Web 数据（例如模板 JSON），可通过共享资源目录或脚本同步，避免重复维护。
- 建议新增一个 `MigrationPlayground.app` scheme，用于快速加载部分功能（例如仅银河动画），以便验证 Swift 实现细节。

## 7. 后续工作指引
1. 在 `StarOracleCore` 中定义所有模型与协议（对应 Step 1 中整理的字段）。
2. 设计 AIService 与 ChatStore 的流式回调接口，确保后续 UI 可以平滑过渡（对应计划 Step 3）。
3. 起草 SwiftUI 页面结构图与导航关系，准备替换 Drawer/Menu/ChatOverlay 等组件。

