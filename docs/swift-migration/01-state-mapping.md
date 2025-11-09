# Zustand 状态与 Swift 映射草稿

## 1. 当前架构概览
- 入口 `src/App.tsx` 负责连接各个 React 组件、Zustand store 与 Capacitor 插件（`ChatOverlay`、`InputDrawer`），同时处理声音、触觉、状态栏、键盘等跨域逻辑。
- UI 主要由 `src/components/` 下的 React 组件构成，利用 framer-motion、Canvas、Tailwind 等技术实现银河背景、星卡翻转、抽屉菜单等交互。
- 数据与行为通过多个 Zustand store 共享：星图（`useStarStore`）、聊天（`useChatStore`）、银河交互（`useGalaxyStore`、`useGalaxyGridStore`）。AI 请求、音效、触觉反馈等由 `src/utils/` 下的工具模块提供。
- Capacitor 插件提供原生浮层与输入抽屉能力，Web 端使用 mock；迁移后需要全量替换为 Swift 原生实现。

## 2. Zustand store 详解与迁移映射

### 2.1 `src/store/useStarStore.ts`
- **核心状态**
  - `constellation`：记录全部星星与连线。
  - `inspirationStars`、`currentInspirationCard`：灵感卡相关数据。
  - `activeStarId`、`highlightedStarId`、`galaxyHighlights`：用于 UI 高亮与细节展示。
  - `isAsking`、`isLoading`、`pendingStarPosition`：控制提问流程与流式状态。
  - `hasTemplate`、`templateInfo`、`lastCreatedStarId`：模板星座与最新星卡信息。
- **主要动作**
  - `addStar`：调用 `aiTaggingUtils.generateAIResponse` 完成流式回答和 AI 分析，再更新星图与连线。
  - `drawInspirationCard`、`useInspirationCard`、`dismissInspirationCard`：灵感卡生命周期。
  - `setIsAsking`、`viewStar`、`hideStarDetail` 等控制界面交互。
  - `regenerateConnections`、`updateStarTags`、`applyTemplate`：基于标签和模板更新连线。
- **依赖模块**
  - AI：`aiTaggingUtils`（回答、分析、配置）。
  - 资源：`imageUtils`、`inspirationCards`、`constellationTemplates`。
  - 工具：`mobileUtils`（在多个组件中使用，以配合主 store）。
- **迁移建议**
  - Swift 侧定义 `class StarStore: ObservableObject`，内部持有 `@Published var constellation: ConstellationModel` 等字段。
  - 将 `Star`、`Connection`、`Constellation` 转为 `struct`/`class` 数据模型，使用 `Codable` 以便本地持久化。
  - `addStar` 拆分为 `AIService`（负责请求与流式回调） + `StarFactory`（生成占位星、合并分析结果）。
  - 灵感卡逻辑可拆到 `InspirationService`，保持与星卡状态轻耦合。
  - 连线计算 `generateSmartConnections` 可转成 Swift 静态方法，必要时用 Combine 或 Task 管理异步。

### 2.2 `src/store/useChatStore.ts`
- **核心状态**
  - `messages`: 聊天历史，支持流式字段 `isStreaming`、`streamingText`、`model` 等。
  - `isLoading`: 请求过程状态。
  - `conversationTitle`: 对话标题。
  - `conversationAwareness`: 聚合觉察指标（等级、深度、洞见列表、话题演进、分析状态）。
- **主要动作**
  - `addUserMessage`、`addAIMessage`、`addStreamingAIMessage`、`updateStreamingMessage`、`finalizeStreamingMessage`：消息生命周期。
  - `generateConversationTitle`: 调用 `generateAIResponse` 生成对话标题。
  - `startAwarenessAnalysis`、`completeAwarenessAnalysis`、`updateConversationAwareness`: 觉察分析与统计。
- **依赖模块**
  - `aiTaggingUtils.generateAIResponse`（生成标题）、觉察分析工具。
  - `useNativeChatOverlay`、`ChatOverlay` 插件、`ChatOverlay.tsx` 组件。
- **迁移建议**
  - Swift 侧建立 `ChatStore: ObservableObject`，内部维护 `messages: [ChatMessageModel]`、`conversationAwareness: ConversationAwarenessModel`。
  - 提供 `startStreaming`/`updateStreaming`/`finishStreaming` 方法，对接 Swift 原生聊天浮层。
  - 将觉察分析与标题生成抽离为 `AwarenessService`、`ConversationTitleService`，方便替换模型/接口。

### 2.3 `src/store/useGalaxyStore.ts`
- **核心状态**
  - 画布尺寸、热点列表、涟漪效果、hover 状态。
  - 负责银河背景交互（热点生成、点击、hover、FX 清理）。
- **迁移建议**
  - Swift 端可实现 `GalaxyInteractionStore`，并将热点、涟漪映射为 `struct GalaxyHotspot`、`Ripple`.
  - `generateHotspots`、`hoverAt`、`clickAt`、`cleanupFx` 可在 SwiftUI Canvas 或 Metal 场景中驱动动画。

### 2.4 `src/store/useGalaxyGridStore.ts`
- **核心状态**
  - 用于星网/网格噪声生成：站点集合、邻接数据、活动站点、标签贴图。
- **迁移建议**
  - 在 Swift 中建立 `GalaxyGridStore`，利用 `SIMD` 或 Accelerate 加速距离计算。
  - `rebuildLabelMap` 在原生实现需要替换为 Metal/CIImage 或 SwiftUI Canvas 的像素缓冲。

## 3. 关键工具与插件梳理
- **AI 工具 (`src/utils/aiTaggingUtils.ts`)**：统一管理 API 配置、流式响应、觉察分析、后续提问生成等；Swift 侧需实现对应的 `AIService`，支持流式与多 provider。
- **声音 (`src/utils/soundUtils.ts`)**：基于 Howler 预加载并播放音效。迁移后应使用 `AVAudioPlayer`/`AVAudioEngine` 管理，同步 ambient 循环与 UI 点击音。
- **触觉 (`src/utils/hapticUtils.ts`)**：通过 Capacitor Haptics 插件触发；Swift 需要使用 `UIImpactFeedbackGenerator`、`UINotificationFeedbackGenerator` 或 `CoreHaptics`。
- **原生插件**
  - `ChatOverlay`：负责原生聊天浮层展示、流式消息同步、键盘高度和视口事件。
  - `InputDrawer`：管理输入抽屉显示、文本同步、焦点控制。
  - Swift 版本需要将这两个插件替换成原生 `UIViewController`/`SwiftUI` 容器，并通过共享状态或 Combine 与 Store 同步。
- **其他工具**：`mobileUtils`（iOS 层级、Portal 处理）、`inspirationCards`、`constellationTemplates`、`imageUtils` 等需要转换为 Swift 资源管理器/静态数据表。

## 4. Swift 端初始建模建议
- **数据模型**
  - `struct StarModel`, `struct ConnectionModel`, `struct ConstellationModel` 对应现有 TypeScript 接口。
  - `struct ChatMessageModel`, `struct AwarenessInsightModel`, `struct GalaxyHotspot`, `struct Ripple`.
  - 利用 `Identifiable`、`Codable` 方便 SwiftUI 绑定和本地持久化。
- **服务层**
  - `AIService`: 负责 AI 请求、流式回调、觉察分析与标题生成（可根据 provider 切换 URLSession 或第三方 SDK）。
  - `SoundService`: 使用 `AVAudioPlayer` 管理音效与 ambient。
  - `HapticService`: 包装系统级触觉反馈。
  - `InspirationService`、`TemplateService`: 管理灵感卡与星座模板数据。
- **状态层**
  - `StarStore`, `ChatStore`, `GalaxyInteractionStore`, `GalaxyGridStore` 继承 `ObservableObject`。
  - 统一放入 `EnvironmentObject`，供 SwiftUI 视图访问。
  - 对应的异步操作使用 `Task.detached`/`async` 函数与主线程调度。
- **UI 层**
  - 使用 SwiftUI 构建主页容器、抽屉、星卡列表、银河背景等组件。
  - 银河动画可评估 `MetalKit`/`SceneKit`/`SwiftUI Canvas` 实现，保持与存储层交互协议一致。

## 5. 下一步行动（对应计划 Step 2）
1. 基于以上映射，在 `docs/swift-migration/` 下补充 Swift 目录结构与模块划分方案。
2. 设计 SwiftUI 根导航、菜单与输入抽屉的原生替代流程草图。
3. 明确每个服务的接口契约（例如 `AIService` 流式回调签名），为后续模块实现奠定基础。

