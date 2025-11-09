# Swift 迁移差距梳理（截至当前进度）

## 1. 已完成的骨架功能
- Swift 包架构与依赖注入环境（`AppEnvironment`、Mock 服务）
- 星图静态渲染、星卡列表、灵感提示、基础聊天占位
- 模板选择、星卡收藏网格、星卡详情弹窗

## 2. 原版核心功能对照

| 模块 | 原版 Capacitor + React 功能 | Swift 版本现状 | 缺口说明 |
|------|-----------------------------|----------------|-----------|
| 银河背景 | `InteractiveGalaxyBackground` Canvas 动画、热点点击、涟漪互动 | 仅有静态 `ConstellationView`，无银河动画或热点逻辑 | 需重写 Canvas/Metal 动画、与 `GalaxyStore`/`GalaxyGridStore` 联动 |
| 菜单/导航 | DrawerMenu、AIConfigPanel、灵感入口、收藏入口 | RootView 仅提供按钮入口，缺少抽屉式导航与配置面板 | 需实现 SwiftUI 抽屉、配置 sheet、灵感列表等 |
| 星卡收藏 | `StarCollection` 搜索、筛选、翻转、灵感抽卡、渐进加载 | Swift 版提供基础网格 + 翻转 | 缺少高级筛选、灵感触发、渐进加载、动画强化 |
| 模板系统 | 完整 12 星座模板、模板应用后的提示、模板清空 | Swift 版仅迁移 2 个模板数据，基础应用逻辑 | 需补全模板数据、应用提示、模板清除/还原流程 |
| 聊天/浮层 | 原生 ChatOverlay、输入抽屉、流式展示、键盘跟随 | Swift 版显示列表 + 文本框，使用 Mock AI | 需重写浮层 UI、键盘适配、与 `StarStore`/`ChatStore` 协作、真实流式接入 |
| AI 配置 | `AIConfigPanel` 输入 provider/endpoint/key/model，验证 API | Swift 版尚无配置 UI，Mock 读取默认配置 | 需迁移配置表单、保存逻辑、Validation 调用 |
| 灵感系统 | 灵感卡抽取、使用灵感生成星卡、灵感历史 | Swift 版仅展示最后一个灵感、抽取按钮 | 需增加灵感列表、使用灵感提问逻辑、卡片管理 |
| 声音/触觉 | Howler 音效、Capacitor Haptics 集成 | Swift 版无声音/触觉实现 | 需接入 AVFoundation、CoreHaptics |
| 原生插件 | Capacitor `ChatOverlay`/`InputDrawer` 管理浮层 | Swift 版暂未实现 | 需重写原生浮层/输入组件，弃用老插件 |
| 数据持久化 | 星卡本地缓存、AI 配置保存、灵感历史 | Swift 版全部使用内存 Mock | 需规划持久化层（UserDefaults/CoreData/文件） |
| 工程化 | Capacitor + iOS 项目、打包脚本 | Swift 版仅 Swift Package，无 Xcode target | 需创建 Xcode Workspace/target，准备资源、CI、真机构建 |

## 3. 推荐后续迭代顺序
1. **导航框架**：实现 SwiftUI Drawer 菜单与配置面板，串联现有功能入口。
2. **银河背景**：迁移银河 Canvas/Metal 动画，结合热点/涟漪互动。
3. **聊天浮层**：重建 ChatOverlay / InputDrawer，支持真实流式与键盘响应。
4. **AI 配置与服务**：迁移配置面板，逐步替换 Mock 服务为真实 API。
5. **灵感与模板扩展**：补充数据、强化交互与说明文案。
6. **声音／触觉 & 持久化**：接入 AVFoundation/CoreHaptics，本地化星卡与配置。
7. **工程整合**：创建 Xcode 项目、整合资源与 CI。

此文档需持续更新，随着功能迁移完成逐项标记已完成功能。
