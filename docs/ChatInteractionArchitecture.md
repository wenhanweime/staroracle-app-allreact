# 原生对话交互架构更新计划（UIKit + Capacitor）

## 目标与范围
- 目标：稳定发送动画与 AI 流式输出，消除“动画被打断/重复加载”，让回复呈现自然、顺滑、可控。
- 范围：iOS 原生 Overlay（UIKit）、Capacitor 插件（Native<->JS 桥）、Web/JS 层（状态与调用），不改后端。

## 设计原则
- 单源数据：以渲染层可见列表为唯一数据源驱动 UITableView。
- 最小刷新：只更新“最后一条 AI 行”，避免 reloadData/全表刷新。
- 动画解耦：发送动画与滚动/布局/流式更新解耦；动画窗口内冻结 UI 动效。
- 主线程合流：流式 chunk 以主线程合流更新；必要时轻量节流/合帧。
- 幂等与去重：新用户消息动画只触发一次；短窗内重复事件忽略。

## 当前问题（症状→根因）
- 重复加载/被打断：插入动画窗口内发生 reload/滚动/约束重排，打断首次动画；稳定后再次呈现，看似“二次动画”。
- 不流逝/一坨出现：抑制了内容更新或只在动画完成后统一 reload，导致“加载”假象或“一次性出现”。
- 状态竞态：isOpen 等在 JS/Native 间滞后，容易错判重复 show 或重复 UI 更新。

## 目标架构（高层）
- 渲染驱动：Overlay 内维护 `visibleMessages: [ChatMessage]` 作为唯一 UITableView 数据源。
- 发送动画“闸门”：动画期间冻结 UI 动效，只缓存数据；动画完成瞬间“一次性呈现当前最新文本”并恢复流式。
- 流式“增量策略”：非动画期按 chunk 只更新最后一行（可见：configure+begin/endUpdates；不可见：reloadRows([last])）。
- 滚动：动画窗口内的滚动强制 `animated: false`；窗口外轻动画滚动到底；不做全表滚动。
- 插件 API 增量化（建议）：新增 `appendAIChunk/updateLastAI`，避免 JS 每次传整表。

## 数据模型
- ChatMessage: `id`, `text`, `isUser`, `timestamp`, `isStreaming?`（JS store侧）。
- Native 渲染态：`visibleMessages`（UITableView 数据源）；`aiTargetFullText/aiDisplayedText`（回放用）。
- 状态标志：`isAnimatingInsert`, `hasScheduledInsertAnimation`, `lastAnimatedUserMessageId`, `suppressAIAnimatedScrollUntil`。

## 状态机（关键态）
- Idle → 用户发送 → 进入 InsertingAnimation（冻结）。
- InsertingAnimation：冻结 UI；只缓存 AI 文本。
- AnimationCompleted：一次性呈现“当前最新文本”，进入 AIStreaming（按 chunk 或回放计时器推进）。
- AIStreaming：更新最后一行 + 行高重算 + 轻滚动，完成后回到 Idle。

## 关键流程
### 发送流程
1) 插入用户行 → reloadRows/scrollToRow(last, animated:false) → `layoutIfNeeded()`（布局稳定屏障）。
2) 设置用户行初始 transform/alpha → 立刻开始动画（可放 `performBatchUpdates` completion）。
3) Manager 判定新用户消息时立即写入 `animatedMessageIDs`（判定即去重）。

### 流式处理
- 动画期间：只更新 `aiTargetFullText` 缓存，不触碰 UI。
- 动画完成：若已有目标文本，用计时器（20–40ms/4–8字）“回放”至目标；回放期间新 chunk 更新目标文本，UI 由计时器推进。
- 非回放/非动画：可见 cell 直接更新最后一行文本 + begin/endUpdates；不可见时 reloadRows([last])。

## UIKit 层（Overlay）实现要点
- 数据源使用 `visibleMessages`。
- 单行刷新：仅更新最后一行；可见：`configure` + `begin/endUpdates`；不可见：`reloadRows([last])`。
- 滚动策略：仅对最后一行 `scrollToRow`；动画窗口内 `animated:false`，窗口外轻动画。
- 布局稳定屏障：动画前对父视图/table 执行 `layoutIfNeeded()`；或把“设初始 transform + 开始动画”放入 `performBatchUpdates` completion。
- 约束抖动兜底：expanded 内部固定高度约束（header/bottomSpace）优先级降至 999/750；`updateForState` 约束变更用 `UIView.performWithoutAnimation` 包裹。

## Capacitor 插件 API（建议）
- 保留：`show`, `hide`, `updateMessages`, `setLoading`。
- 新增：`appendAIChunk({ id, delta })`、`updateLastAI({ id, text })`；（可选）`beginSendAnimation/endSendAnimation`。
- 流式期间优先用 `appendAIChunk`，避免整表刷新。

## Web/JS 层（最小改动）
- onStream 合帧节流（16–33ms 窗口）调用 `appendAIChunk`/`updateLastAI`。
- show/hide 幂等；不依赖滞后的 isOpen 判定。
- 唯一更新对象：最后一条 AI 消息。

## 错误与恢复
- 网络异常：JS 捕获并 `setLoading(false)` + 展示错误行；原生不自持加载 UI。
- 中断/取消：停止计时器，维持已呈现文本，状态回 Idle。
- 重试：增量更新，避免整表替换。

## 性能与节流
- UI 合帧：仅更新最后一行，避免全表操作。
- 文本解析（可选）：阈值解析大文本（如累计64字符或遇到 ``` 再解析）。
- 回放速度：按文本长度动态调整。

## 日志与监控
- 关键埋点：动画调度/开始/完成、滚动抑制判定、布局稳定屏障触达、流式/回放推进、错误。
- 调试开关：统一 logger level。

## 迁移计划（分阶段）
### 第1阶段（稳定发送动画 + 恢复流逝，1–2天）
- 加布局稳定屏障（layoutIfNeeded 或 performBatchUpdates completion）。
- 动画窗口冻结 UI：isAnimatingInsert 时不做 reload/滚动/高度更新（只缓存）。
- 动画完成：一次性呈现当前最新文本；开启回放计时器；非回放期单行增量更新。
- 滚动短窗抑制（仅控动效）。
- Manager 判定即去重；VC 侧调度防抖/短窗同 ID 跳过。

### 第2阶段（接口与性能，1–2天）
- 插件新增 `appendAIChunk` / `updateLastAI`；JS onStream 合帧节流调用。
- 引入简单 Markdown 分段解析（可选）。

### 第3阶段（终极稳定，可选，2–4天）
- 引入飞行气泡动画（发送动画与 table 完全解耦）。
- 细化错误/重试/取消/撤回等高级交互。

## 验收标准
- 发送动画：每条仅触发一次，不中断，无“先动一下又重来”。
- 流式表现：动画完成后 200ms 内开始“流逝”，每 20–40ms 增量推进；长文 1–2s 内完整呈现；无“一坨出现”。
- 滚动体验：动画期间滚动无动画；其他时刻轻滚到底；无突兀跳变。
- 稳定性：无 Auto Layout 冲突日志；CPU/掉帧可控（列表仅单行更新）。

