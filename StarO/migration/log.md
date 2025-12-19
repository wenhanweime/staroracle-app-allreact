# Swift 迁移日志（本仓）

**真值（SoT）**
- 迁移文档：`../staroracle-backend/docs/swift-migration/`
- 接口契约：`../staroracle-backend/docs/contracts/`

> 说明：这里只记录“本仓相对 SoT 的执行进度、关键改动与决策”，用于追溯迁移过程；不在本文件内维护完整计划/规格，避免与 SoT 漂移。

## 2025-12-17

- 文档真值切换：移除本仓 `StarO/swift-migration/` 与 `docs/swift-migration/`，旧内容已备份到 `trash/`。
- 新增本仓迁移记录入口：`StarO/migration/clarifications.md` 与 `StarO/migration/log.md`。
- 新增交接文档：`StarO/migration/handoff.md`。
- 对齐契约：为 Edge Functions 请求补齐 `X-Trace-Id`；`chat-send` 补齐 `X-Idempotency-Key` + `body.idempotency_key`（并兼容 `done.chat_id` 缺失时回退到请求 chat_id）。
- 对齐对话串联：TapHighlight 选中的 `galaxy_star_indices` 暂存并仅在“新会话首条 chat-send”携带；成功 `done` 后清理（`review_session_id` 已预留端侧入口）。
- 对齐交互：灵感卡提交在有 Supabase 配置时改为“新建会话 → 进入 chat-send 对话”，不再走本地 `addStar` 生成星星。
- 对齐摘星：点击 Galaxy 生成灵感卡在有 Supabase 配置时优先调用 `POST /functions/v1/star-pluck (mode=inspiration)`，失败则回退到本地 mock。
- 对齐成星提示：`chat-send done` 后短轮询 `stars(chat_id=...)`，发现首条星卡/等级提升时在对话插入“点击查看星卡”提示，点击后跳转收藏并打开星卡详情。
- 对齐能量与升级：星卡详情页在有 Supabase 配置时调用 `GET /functions/v1/get-energy` 展示能量余额，并提供“升级”按钮调用 `POST /functions/v1/star-evolve (action=upgrade_button)`；成功后回源刷新 `stars(id=...)` 并更新 `StarStore`。
- 对齐回顾续聊：从历史会话切换/对话内打开星卡时生成 `review_session_id` 并仅在该次进入后的首条 `chat-send` 携带；当 `review_session_id` 待发送时跳过 10 分钟分段，确保复用原 `chat_id`。
- 对齐点亮真值：`Star` 模型新增 `galaxyStarIndices`，从 `stars.galaxy_star_indices` 注入；Galaxy 背景将这些索引作为“永久点亮”渲染，不再依赖坐标近邻匹配。
- 对齐星点点击：（误读，后续已回退）曾实现“点击已永久点亮的银河星点（`s-<index>`）→ 按 `galaxyStarIndices` 反查星卡并打开详情”（复用 `.chatOverlayOpenStar` 通知链路）；现已拍板 Galaxy 单击不作为资产星卡入口。

## 2025-12-18

- 数据同步（Stars）：新增 `GET /rest/v1/stars` 拉取资产星卡列表（`StarsService.fetchStars`），并在 App 启动（`RootView`）触发 `AppEnvironment.syncSupabaseStarsIfNeeded()` 批量 upsert 到 `StarStore`，用于银河/收藏展示云端星卡。
- 数据同步（Messages/Chats）：新增 `GET /rest/v1/messages` 拉取会话消息（`ChatMessagesService.fetchMessages`）；侧边栏“云端会话”支持点击打开，导入到 `ConversationStore` 并载入 `ChatStore`（同时生成 `review_session_id` 以对齐回顾续聊规则）。
- 工程对齐：修复 async IIFE 写法导致的编译错误，并移除非 Sendable 的全局 `ISO8601DateFormatter` 静态缓存以通过严格并发检查。
- Auth（M1 邮箱登录）：新增 `LoginView` + `AuthService`（直连 Supabase Auth REST），Session 写入 Keychain；`SupabaseRuntime.loadConfig()` 会从 Keychain 读取 access token，从而在“未提供 TOKEN/SUPABASE_JWT”时也能调用后端；启动时自动恢复会话并尝试调用 `get-energy` 做每日能量初始化。
- Auth 体验修复：即使 `SupabaseConfig.plist` 含 `SUPABASE_JWT`（测试 token），当 Keychain 无会话时也会优先展示登录界面；并且 `SupabaseRuntime.loadConfig()` 优先使用 Keychain 的 access token（避免登录后仍走测试 token）。
- UI 回归：恢复星卡“可翻转/紫色带动画”风格（`StarCardConfig` 固定 Nebula Purple + 仅保留星型样式），并在星卡详情页顶部展示可翻转星卡；（曾尝试）点击银河已点亮星点打开星卡时不再强制切换到收藏页（后续已回退，见下条）。
- Auth 文案：登录失败时对常见错误做更友好映射（如“邮箱或密码错误/网络不可用/网络连接中断”等），避免误提示为 network lost。
- 协作规则：新增 `StarO/migration/constitution.md`，强制要求“每次改动必须补迁移日志 + 对应 git 提交”。
- 交互回退：删除 Galaxy 单击“命中永久点亮星点 → 直接打开资产星卡详情”的分支，避免出现两套点击交互；Galaxy 单击统一保持“点亮区域 → 弹出灵感卡”，资产星卡入口只保留在收藏/对话提示。
- 星卡多样性：恢复 `planet_*` 经典行星样式参与抽样（该次未启用 `pixel_*`，后续补齐），修复“planet 类型不出现/动画过于简单”的问题。
- 星卡多样性（补齐）：启用 `pixel_*` 像素行星样式并与 star/planet 并列抽样（按组各占 1/3，类内均匀），修复“像素星星不出现/类型不全”的问题。
- 个人主页（Account）：左侧菜单底部新增固定“用户头像/名称”入口（不随历史对话滚动），点击进入个人主页；页面展示用户 ID/注册时间/银河种子/能量与云端聚合统计，并支持编辑昵称与头像（`avatar_emoji`），对齐 `get-profile`/`update-profile` 契约。
- 菜单面板空间优化：移除顶部“星谕”标题、移除“宇宙计数”、移除底部“关闭”按钮；搜索框置顶；底部账号入口简化描边并压缩高度，以增大历史会话可视面积。
- 菜单面板再精简：历史会话区移除“云端（可打开）/本地（旧链路）”标题与未配置提示；移除“新建会话”按钮；菜单操作区清空；AI 配置入口移至个人主页并增加“云端会话”状态展示。
- 对话联通修复：在调用 `chat-send` 前先通过 PostgREST upsert 创建 `public.chats` 记录（使用本地 sessionId 作为 chat_id），避免 `CH08 chat not found` 导致“未能获取星语回应”。
- 对话卡住修复：`chat-send` SSE 收到 `event: done` 后立即主动结束流并取消底层请求，避免服务端 keep-alive/连接未及时关闭导致客户端一直 loading 转圈。
- 对话 SSE 解析修复：弃用 `URLSession.AsyncBytes.lines`（在部分系统上会出现“lines 为空但实际有 body 数据”），改为按字节手动切行解析 SSE，恢复 `delta/done` 正常接收。
- Auth 稳定性：对 Supabase access token 过期做自动刷新（`SupabaseRuntime.loadConfigRefreshingIfNeeded()`），并在 chat-send / chat-create 前统一刷新再发请求，修复“已登录但请求 401/表无新增记录”的问题；同时登录时若 Keychain 写入失败则不再误判为已登录。
- 对话兜底回源：若 `chat-send` 未收到任何 `delta`（如幂等短路仅返回 `done`、或流式被系统吞掉），则在 `done.message_id` 存在时自动回源 `GET /rest/v1/messages?id=eq.<message_id>` 拉取 assistant 内容并补写到 UI，避免前端空消息一直转圈。
- 修复编译：`chat-send` 兜底回源逻辑中对 `String??` 的可选绑定写法不正确导致编译失败，已改为显式扁平化后再判断。
- 网络异常恢复：`chat-send` SSE 过程中遇到 `networkConnectionLost/timedOut` 等错误时，不立即展示失败文案；先轮询 `GET /rest/v1/messages (role=assistant, order=desc, limit=1)`，若发现本次请求后产生的新 assistant 消息则补写到 UI 并结束 loading，避免“后端已落库但前端显示失败/一直转圈”。
- 输入框闪烁修复：`InputDrawerManager.attach(to:)` 增加同一 `UIWindowScene` 的去重，避免 SwiftUI 键盘布局变更触发频繁 attach 导致窗口抖动；输入框键盘联动改为监听 `keyboardWillChangeFrame` 并使用系统提供的 duration/curve 同步动画，降低第三方键盘多次 frame 变化导致的闪烁。
- 星卡弹窗层级修复：当系统 Sheet（星卡详情/个人主页）出现时，将 `ChatOverlay` 与 `InputDrawer` 的 `UIWindowLevel` 临时下沉到 `normal` 以下，确保弹窗始终显示在对话浮窗之上（避免“点击查看星卡被浮窗压住/看不到”）。
- 对话重试入口：当 AI 消息显示“未能获取星语回应/发送失败/请求已取消”等失败文案时，在该气泡内展示“重试”按钮；点击后会基于最后一条用户消息（复用 `idempotency_key`）重新发起 `chat-send` 并复用当前 AI 占位进行流式更新。
- 星卡提示优化：将“已生成一颗星星/点击查看星卡”渲染为紧凑胶囊提示（自适应宽度、压缩行高），并在对话浮窗内按时间戳合并排序提示与消息，避免提示一直固定占据最后一条位置。
- 历史会话回放修复：对话过程中将 `ChatStore.messages` 同步写入 `ConversationStore`（避免只存标题/时间导致点开为空）；切换历史会话时若本地消息为空且已配置 Supabase，则自动回源 `GET /rest/v1/messages?chat_id=...` 拉取并回填后再载入（`NativeChatBridge.observeChatStore` / `AppEnvironment.switchSession` / `ConversationStore.replaceSessionMessages`）。自测：本地编译通过；发起多轮对话后从左侧菜单切换历史会话应能正常回放。
- 对话历史规则（24h 连续展示）：保持现有“10 分钟 inactivity 分段 / chat_id 可变 / 上下文与记忆策略不变”，但聊天浮窗改为聚合展示最近 24 小时内的多段会话消息，视觉上连续、可上滑回看；若当前切换到超过 24 小时的旧会话，则仅展示该会话自身消息（`NativeChatBridge.refreshOverlayMessages`）。
- 交互补齐：点击输入框（获得焦点）时，若对话浮窗处于隐藏/收缩状态，则自动弹出并展开浮窗，避免“必须先发送消息才弹出浮窗”的割裂体验（`NativeChatBridge.inputDrawerDidFocus`）。
- 性能（日志）：新增 `StarOracleDebug.verboseLogs` 开关（默认关闭），并将 `ChatOverlayManager/InputDrawerManager/NativeChatBridge` 的 `NSLog` 输出改为受该开关控制；同时将 `ChatStore/StarStore/GalaxyStore/GalaxyGridStore/ConversationStore/KeyboardObserver` 的 callStack 日志改为默认关闭；个人主页（Account）“调试”中新增“详细日志”开关便于需要时再打开。
- 性能（Galaxy 点击）：将 Galaxy 点击防抖等待从 600ms 调整为 120ms，并避免 `GalaxyViewModel.handleTap` 在外部已提供 onTap 回调时重复触发默认高亮计算（减少一次全量候选扫描），降低点击卡顿与延迟感。
- 性能（Galaxy 灵感卡）：有 Supabase 配置时不再等待云端 `star-pluck` 返回才弹出灵感卡；改为先弹出本地灵感卡，再异步回填云端内容（保持卡片 id 不变，避免关闭/提交时错位），从而不让网络阻塞“弹出星卡/翻牌”交互（`GalaxyBackgroundView` / `StarStore.replaceCurrentInspirationCard`）。
- 修复编译（StarOracleDebug 可见性）：部分环境下 SwiftPM/Xcode 未及时识别新增源文件导致 `StarOracleFeatures` 内引用 `StarOracleDebug` 编译失败；已将 `StarOracleDebug` 定义移动到 `StarOracleCore` 既有源文件 `Models/Inspiration.swift` 并删除独立文件，避免增量构建遗漏。
- Auth 启动体验：新增 `AuthService.hasRestoredSession`，在会话异步恢复完成前不展示登录页，避免已登录用户启动时闪现 `LoginView`（`RootView.shouldShowLogin`）。
- 星卡入口：点击对话内“查看星卡”提示仅弹出星卡详情 Sheet，不再自动切换右侧 `StarCollection` 面板（移除 `RootView` 内 `snapTo(.collection)`）。
- 对话底部间距：展开态 `ChatOverlay` 的 `contentInset.bottom` 改为使用输入框实际高度（`InputDrawerState.latestHeight`）计算遮挡重叠；并将无重叠时默认 bottom inset 从固定 `120px` 改为 `safeAreaBottom + 12px`，修复“提示与输入框间距过大”的视觉问题。
- 对话顶起统一：移除展开态布局里额外的 `bottomSpaceView(120px)` 固定占位，避免与 `contentInset.bottom` 叠加导致“气泡被顶起过高”；展开态底部避让只由一套动态规则负责（`adjustExpandedContentInset`）。
- 键盘联动一致性：输入框/键盘位置变化时提前发布“目标 bottomSpace”（不等待动画完成），让 `ChatOverlay` 与键盘同节奏调整；同时输入框聚焦时统一触发“滚到底”请求，解决“上滑查看历史后点输入无法顶起/体验不一致”。

## 2025-12-19

- 迁移协作：章程补充 `StarO/migration/userpromptrecord.md` 的“已读/子任务完成”标注规则，并将 `# 2` 转为任务清单以便逐条验收与追溯。
- UI（主页顶栏）：ChatOverlay 展开时不再对背景根视图做“向上位移/3D 旋转”，仅保留轻微缩放，修复主页顶部按钮被顶进灵动岛/安全区的问题（`ChatOverlayManager.applyBackgroundTransform`）。
- 历史会话标题：修复“标题一直是新会话/未命名会话”的链路——`ChatStore.generateConversationTitle()` 原先要求 `conversationTitle` 为空才会触发；现在将 `"新会话"/"未命名会话"` 视为占位标题也允许生成；并在 `chat-send` 完成与打开云端会话时触发生成，生成后写回本地 `ConversationStore`，同时 `PATCH /rest/v1/chats?id=eq.<chat_id>` 同步更新云端 `chats.title`（仅在未自定义标题时覆盖，避免误改用户命名）。
- 菜单抽屉样式：将左侧菜单从“圆角卡片”改为“全高侧拉抽屉”，背景铺满安全区并增加右侧分隔线；同时移除 `RootView` 中的左侧额外 padding，并将 ChatOverlay/InputDrawer 的水平顶起偏移从 `menuWidth + 24` 改为 `menuWidth`（`DrawerMenuView` / `RootView`）。
- 抽屉顶起对齐：支持 ChatOverlay/InputDrawer 的“负向水平偏移”，当右侧 `StarCollection` 抽屉打开时将对话浮窗/输入框整体向左顶起（`RootView` 在 `.collection` 时传 `-collectionWidth`；移除 `ChatOverlayManager/OverlayViewController/InputDrawerManager/InputViewController` 对 offset 的 `max(0, ...)` 限制）。
- 灵感卡内容（答案之书/名言）：引入“答案之书”全量答案（本地 `BookOfAnswers.answers`），并在 `star-pluck` 返回 `content_type=question` 且 `answer` 为空时自动用答案之书补齐；同时将 `content_type` 写入 tags（`content_type:quote/question`），并在灵感卡背面按类型调整展示——quote 类型大字显示引用（`question`），署名作为底部小字（`reflection`），修复“只看到尼采/格式不对”的问题（`StarPluckService` / `InspirationCardOverlay`）。
- 语音输入（Speech）：接入 Apple `Speech` + `AVAudioEngine`，点击输入框右侧麦克风按钮开始/停止中文语音转文字并实时回填输入框；补齐 `NSMicrophoneUsageDescription` 与 `NSSpeechRecognitionUsageDescription`（通过 `GENERATE_INFOPLIST_FILE` 的 `INFOPLIST_KEY_*` 配置注入）。
- 星卡交互（收藏）：`StarCollection` 网格内点击不再直接翻转星卡；改为弹出“单卡聚焦浮层”（尺寸与灵感卡一致），在浮层内允许翻转，并可进一步进入详情（`StarCardFocusOverlay` / `StarCollectionPane` / `StarCardView.isTapToFlipEnabled`）。
- 星卡交互（对话提示）：对话内“点击查看星卡”从直接打开详情 Sheet 改为弹出同款“单卡聚焦浮层”；并在浮层展示期间调用 `NativeChatBridge.setSystemModalPresented(true)` 下沉 ChatOverlay/InputDrawer 的窗口层级，确保星卡浮层始终在最上层（`RootView`）。
- 对话渲染（Markdown）：普通消息气泡启用 Markdown（`NSAttributedString(markdown:)` + `InlinePresentationIntent` 映射为 bold/italic/code/删除线），并加 200 条缓存减少滚动/刷新时的重复解析；`hint-star:` 仍保持轻量胶囊样式与点击行为不变（`ChatOverlayManager.MessageTableViewCell`）。
- 长期记忆（用户级）：后端 `chat-send` 在 `done` 后异步增量维护 `profiles.long_term_memory_prompt`（跨 `chat_id`），并在后续对话上下文中注入以提升跨会话个性化；个人主页新增“长期记忆”展示区用于排障（`AccountView` / `ProfileService`）。
- Galaxy 历史点亮恢复：修复“已登录用户冷启动后历史点亮/永久点亮丢失”——此前 `RootView/GalaxyBackgroundView` 的 `.task` 早于 `AuthService.restoreSessionIfNeeded()` 完成触发，导致 `stars/galaxy_seed/TapHighlights` 首次拉取被 `SupabaseRuntime.loadConfig()==nil` 短路且后续不再触发；现在改为在 `hasRestoredSession==true` 后补触发同步（`StarOApp` 会话恢复后主动 `syncSupabaseStarsIfNeeded()`，`RootView/GalaxyBackgroundView` 也以 `hasRestoredSession` 为 id 重新执行一次）。
