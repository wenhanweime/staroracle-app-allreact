# 🔍 CodeFind 历史记录

## 最新查询记录

### 2025-08-24 - 点击输入框之后 输入框跟随键盘弹起的过程

**查询**: `点击输入框之后 输入框跟随键盘弹起的过程`

**技术名称**: 输入框键盘交互和定位

**涉及文件**:
- `src/components/ConversationDrawer.tsx` ⭐⭐⭐⭐⭐ (底部输入抽屉组件)
- `src/components/ChatOverlay.tsx` ⭐⭐⭐⭐ (对话浮窗组件)
- `src/index.css` ⭐⭐⭐⭐ (全局样式和键盘优化)
- `src/App.tsx` ⭐⭐⭐ (主应用组件)
- `src/utils/mobileUtils.ts` ⭐⭐ (移动端工具函数)
- `capacitor.config.ts` ⭐⭐ (原生平台配置)

**关键功能点**:
- 🎯 移除所有键盘监听逻辑，让系统原生处理键盘行为
- 🎯 iOS专用输入框优化 - 确保键盘弹起
- 🎯 视口高度监听（仅用于修复iOS浮窗显示问题，不干预键盘行为）
- 🎯 完全移除样式计算，让系统原生处理所有定位
- 🎯 计算吸附位置：浮窗顶部 = 输入框底部 - 5px
- 🎯 事件解耦优化：onInputFocus → onSendMessage 接口重构

**技术策略**:
- **系统原生处理**: 移除所有自定义键盘监听，让系统原生处理键盘弹起
- **iOS特殊优化**: 使用CSS @supports检测iOS并应用特殊样式
- **固定定位**: 使用`fixed bottom-0`确保输入框始终在底部
- **浮窗协调**: 通过inputBottomSpace参数协调输入框与浮窗的位置关系
- **性能优化**: 解耦输入聚焦和浮窗动画，提升响应速度

**详细报告**: 查看 `Codefind.md` 获取完整代码内容

---

### 2025-08-24 - 点击输入框之后键盘弹起和之后的输入框跟随键盘上移的整个过程的代码

**查询**: `点击输入框之后键盘弹起和之后的输入框跟随键盘上移的整个过程的代码`

**技术名称**: 键盘交互和输入框定位

**涉及文件**:
- `src/components/ConversationDrawer.tsx` ⭐⭐⭐⭐⭐ (底部输入抽屉组件)
- `src/components/ChatOverlay.tsx` ⭐⭐⭐⭐ (对话浮窗组件)
- `src/index.css` ⭐⭐⭐⭐ (全局样式和键盘优化)
- `src/App.tsx` ⭐⭐⭐ (主应用组件)

**关键功能点**:
- 🎯 移除所有键盘监听逻辑，让系统原生处理键盘行为
- 🎯 iOS专用输入框优化 - 确保键盘弹起
- 🎯 视口高度监听（仅用于修复iOS浮窗显示问题，不干预键盘行为）
- 🎯 完全移除样式计算，让系统原生处理所有定位
- 🎯 计算吸附位置：浮窗顶部 = 输入框底部 - 5px

**技术策略**:
- **系统原生处理**: 移除所有自定义键盘监听，让系统原生处理键盘弹起
- **iOS特殊优化**: 使用CSS @supports检测iOS并应用特殊样式
- **固定定位**: 使用`fixed bottom-0`确保输入框始终在底部
- **浮窗协调**: 通过inputBottomSpace参数协调输入框与浮窗的位置关系

**详细报告**: 查看 `Codefind.md` 获取完整代码内容

---

### 2025-08-20 00:59 - Web端对话抽屉代码和iOS端对话抽屉代码

**查询**: `/findcode web端对话抽屉代码和ios端对话抽屉代码,要具体到更细节的按钮,包括左侧加号按钮,右侧麦克风按钮以及右侧八条线星星按钮`

**技术名称**: ConversationDrawer (对话抽屉)

**涉及文件**:
- `src/components/ConversationDrawer.tsx` ⭐⭐⭐⭐⭐ (主组件)
- `src/index.css` ⭐⭐⭐⭐⭐ (iOS修复样式)
- `src/components/StarRayIcon.tsx` ⭐⭐⭐⭐ (八条线星星图标)
- `src/store/useStarStore.ts` ⭐⭐⭐ (状态管理)
- `src/utils/soundUtils.ts` ⭐⭐ (音效工具)
- `src/utils/hapticUtils.ts` ⭐⭐ (触觉反馈)

**关键功能点**:
- 🎯 左侧加号按钮 (`Plus` icon, `handleAddClick`)
- 🎯 右侧麦克风按钮 (`Mic` icon, 支持录音状态, `handleMicClick`)
- 🎯 右侧八条线星星按钮 (`StarRayIcon`, 支持动画, `handleStarClick`)
- 🎯 iOS特定修复 (`.conversation-right-buttons`, 安全区域适配)

**平台差异**:
- **Web端**: 标准CSS hover效果，无触觉反馈
- **iOS端**: iOS Safari样式覆盖，触觉反馈，安全区域适配

**详细报告**: 查看 `Codefind.md` 获取完整代码内容

---