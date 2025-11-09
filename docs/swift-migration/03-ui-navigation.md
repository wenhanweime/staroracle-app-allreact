# SwiftUI 导航与界面替换规划

## 1. 根视图结构
- **RootView**
  - 使用 `ZStack` 作为总体容器，底层展示银河背景，中层承载主内容与状态提示，顶层放置浮层（聊天、输入抽屉、菜单）。
  - 通过 `EnvironmentObject` 注入 `StarStore`, `ChatStore`, `GalaxyStore`，保证子视图响应状态变化。
  - 关键区域：
    - `GalaxyBackgroundView`：全屏 Canvas/Metal 视图，响应触摸事件并将坐标传递给 `GalaxyStore` 和 `StarStore.setIsAsking(...)`。
    - `MainHUD`：顶部导航栏（logo、音量/设置按钮）、右上角菜单入口、灵感卡提示。
    - `ConstellationLayer`：在银河背景上叠加星卡节点、连线、星光动画。
    - `BottomActionBar`：包含提问入口（OracleInput）、抽屉触发器、状态指示。
    - `FloatingPanels`：包括聊天浮层、AI 配置面板、星卡详情、灵感卡弹出等。

## 2. 导航与浮层体系
- 使用自定义的 `OverlayController` 管理多个浮层的显示状态（聊天、收藏、配置、模板选择等），内部维护优先级与转场动画。
- 核心浮层映射：
  | React 组件 | SwiftUI 对应 | 展示形式 | 说明 |
  |------------|--------------|----------|------|
  | `DrawerMenu` | `DrawerMenuView` | 左侧半高抽屉 | 使用 `transition(.move(edge: .leading))` + 背景蒙层 |
  | `AIConfigPanel` | `AIConfigPanelView` | 全屏或半屏 sheet | 支持 `PresentationDetent` 调整高度 |
  | `StarCollection` | `StarCollectionView` | 全屏覆盖 + `matchedGeometryEffect` | 支持搜索、筛选、翻转动画 |
  | `StarDetail` | `StarDetailSheet` | 半屏可拖动 sheet | 展示星卡详情与后续操作 |
  | `ChatOverlay` | `ChatOverlayView` | 悬浮窗 + 拖拽 | 模拟原生浮窗，支持最小化/展开、流式更新 |
  | `OracleInput` | `OracleInputBar` | 底部固定输入条 | 集成文本框、发送、灵感卡按钮 |
  | `InteractiveGalaxyBackground` | `GalaxyBackgroundView` | Canvas/Metal 层 | 负责银河可视化与热区交互 |

- 导航状态通过 `OverlayState`（`enum Overlay { case chat, collection, config, template, none }`）管理，可扩展支持并行浮层（例如聊天 + 输入框）。
- 对话浮层与输入条需共享键盘高度、拖拽状态；建议使用 `GeometryReader` + 自定义 `DragGesture`，配合 `KeyboardObserver` 服务同步安全区域。

## 3. 主要界面拆分

### 3.1 银河背景与交互
- **GalaxyBackgroundView**
  - 使用 `Canvas` 或 `MetalViewRepresentable` 实现星点绘制与动画。
  - 将鼠标/手势事件传入 `GalaxyStore`（更新热点、涟漪）与 `StarStore.setIsAsking`。
  - 支持 `TapGesture` 触发星卡创建、`DragGesture` 用于探索模式。
- **ConstellationOverlay**
  - 根据 `StarStore.constellation` 绘制星卡与连线，提供 `matchedGeometryEffect` 支持星卡详情放大。
  - 使用 `TimelineView` 或 `DisplayLink` 更新闪烁、脉冲效果。

### 3.2 星卡详情与收藏
- **StarCardView**
  - 映射 `StarCard.tsx` 的翻转动画，可使用 `Rotation3DEffect` + `withAnimation`.
  - 支持快速操作（收藏、标记、追问），调用 `StarStore` 对应方法。
- **StarCollectionView**
  - 使用 `LazyVGrid` + 自定义 `FlipCard` 组件实现网格翻转。
  - 搜索与筛选映射到 SwiftUI `SearchBar`（iOS 17 可使用 `Searchable`）。
  - 灵感卡按钮触发 `InspirationService`，更新 `StarStore`.

### 3.3 聊天体验
- **ChatOverlayView**
  - 包含顶部标题区、消息列表、底部快速操作。
  - 消息列表使用 `ScrollViewReader` + `LazyVStack` 支持流式插入与自动滚动。
  - 流式状态通过 `ChatStore.messages` 中的 `isStreaming` 字段驱动，利用 `TimelineView` 刷新输入光标。
  - 承载后续问题、觉察分析等按钮，直接调用 `ChatStore` 与 `AIService`.
- **OracleInputBar**
  - 常驻底部，支持 placeholder、键盘跟随、灵感卡入口。
  - 与聊天浮层共享发送逻辑：点击发送 -> `StarStore.addStar`，同时打开聊天浮层以呈现回答。

### 3.4 菜单与配置
- **DrawerMenuView**
  - 重用 `StarStore` 与 `ChatStore` 数据展示快捷项（最近星卡、对话）。
  - 提供跳转按钮，更新 `OverlayState` 打开对应浮层。
- **AIConfigPanelView**
  - 使用 `Form` + Section 设计输入项（Provider、Endpoint、API Key、Model 等）。
  - 触发 `AIService.validateConfiguration`，结果通过弹窗提示。

## 4. 状态与导航同步
- 定义 `AppNavigationState`（`ObservableObject`），管理当前激活浮层、模态、Tab（若后续扩展）。
- 重要状态流：
  - `StarStore.isAsking` → 打开 `OracleInputBar` 并提示位置选择。
  - `StarStore.lastCreatedStarId` 更新 → 自动滚动聊天列表、突出最新星卡。
  - `ChatStore.conversationTitle` → 同步到 `ChatOverlayView` 标题。
  - `GalaxyStore.hoveredId` → 在 `ConstellationOverlay` 中高亮对应星卡。
- 所有浮层使用 `AppNavigationState` 控制显隐；例如 `showCollection()` 将 `activeOverlay = .collection`，并通过 `withAnimation` 切换。

## 5. 动画与转场策略
- 利用 `matchedGeometryEffect` 实现星卡从网格放大到详情的连贯动画。
- 银河背景动画使用 `TimelineView(.animation)` 驱动帧更新，避免自定义 CADisplayLink。
- 浮层过渡设计：
  - 聊天浮层：自定义 `OverlayTransition`，支持拖拽最小化（类似 iOS 原生卡片）。
  - 收藏面板：右侧/上方滑入 + 背景模糊。
  - 灵感卡弹窗：使用 `scaleEffect` + `opacity`，快速弹出与关闭。
- 保持动画参数（时长、插值）与现有体验一致，可在 `UIComponents` 中集中配置。

## 6. 手势与键盘处理
- 创建 `KeyboardObserver`（Combine 发布者）监听键盘高度变化，驱动 `OracleInputBar` 和 `ChatOverlayView` 调整位置。
- 浮层拖拽使用 `DragGesture`，结合 `GestureState` 跟踪偏移；在释放时根据速度决定回弹或 dismiss。
- 银河画布使用手势代理让点击与拖拽共存（优先处理短按创建星卡，长按或拖动切换探索模式）。

## 7. 下一步实施建议
1. 在 Swift 项目中定义 `AppNavigationState` 与基本浮层管理机制，实现 RootView 的 `ZStack` 架构。
2. 完成 `GalaxyBackgroundView` 的占位实现（静态星点 + 热区点击回调），确保星卡创建流程可串联。
3. 逐个迁移浮层：先实现 `StarCollectionView`（静态数据），再接入 `ChatOverlayView` 的原生流式界面。

