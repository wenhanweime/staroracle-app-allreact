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
- 语音崩溃兜底：在启动语音识别前校验 `Info.plist` 是否包含 `NSSpeechRecognitionUsageDescription/NSMicrophoneUsageDescription`，若缺失则提示并直接返回，避免触发系统 TCC（`com.avaudiosession.tccserver`）导致 `brk #0x1` 崩溃（`InputViewController.validateSpeechUsageDescriptions`）。
- 语音停止修复：停止按钮点击后先立刻更新 UI，再在后台线程清理 `AVAudioEngine/SFSpeech` 资源；并增加 `isSpeechStopping/didInstallSpeechTap` 防止重复停止/未装 tap 时误清理，避免停止阶段再次触发 `brk #0x1`（`InputViewController.stopSpeechRecognition`）。
- 语音停止进一步修复：为 `recognitionTask` 回调增加“request 身份校验”，忽略旧 request 的回调，避免 stop 过程中 cancel 触发回调导致二次 stop；并调整 stop 顺序为：先 stop engine → removeTap → endAudio/cancel，降低停止阶段卡死/断点风险（`InputViewController.beginSpeechRecognition/stopSpeechRecognition`）。
- 星卡交互（收藏）：`StarCollection` 网格内点击不再直接翻转星卡；改为弹出“单卡聚焦浮层”（尺寸与灵感卡一致），在浮层内允许翻转，并可进一步进入详情（`StarCardFocusOverlay` / `StarCollectionPane` / `StarCardView.isTapToFlipEnabled`）。
- 星卡交互（对话提示）：对话内“点击查看星卡”从直接打开详情 Sheet 改为弹出同款“单卡聚焦浮层”；并在浮层展示期间调用 `NativeChatBridge.setSystemModalPresented(true)` 下沉 ChatOverlay/InputDrawer 的窗口层级，确保星卡浮层始终在最上层（`RootView`）。
- 对话渲染（Markdown）：普通消息气泡启用 Markdown（`NSAttributedString(markdown:)` + `InlinePresentationIntent` 映射为 bold/italic/code/删除线），并加 200 条缓存减少滚动/刷新时的重复解析；`hint-star:` 仍保持轻量胶囊样式与点击行为不变（`ChatOverlayManager.MessageTableViewCell`）。
- 长期记忆（用户级）：后端 `chat-send` 在 `done` 后异步增量维护 `profiles.long_term_memory_prompt`（跨 `chat_id`），并在后续对话上下文中注入以提升跨会话个性化；个人主页新增“长期记忆”展示区用于排障（`AccountView` / `ProfileService`）。
- Galaxy 历史点亮恢复：修复“已登录用户冷启动后历史点亮/永久点亮丢失”——此前 `RootView/GalaxyBackgroundView` 的 `.task` 早于 `AuthService.restoreSessionIfNeeded()` 完成触发，导致 `stars/galaxy_seed/TapHighlights` 首次拉取被 `SupabaseRuntime.loadConfig()==nil` 短路且后续不再触发；现在改为在 `hasRestoredSession==true` 后补触发同步（`StarOApp` 会话恢复后主动 `syncSupabaseStarsIfNeeded()`，`RootView/GalaxyBackgroundView` 也以 `hasRestoredSession` 为 id 重新执行一次）。
- 对话兜底增强：为 `chat-send` SSE 增加“25s 无流量 idle 超时”并映射为 `URLError.timedOut`，避免连接卡死导致 UI 永久 loading；同时在 SSE 正常结束但未收到任何内容时，自动回源拉取最新 assistant 消息补写到 UI，否则落失败文案并露出“重试”（`ChatSendService` / `NativeChatBridge.performCloudStreaming`）。
- Loading 动画停转修复：`StarRayActivityView` 在窗口层级切换/重挂载导致动画丢失时自动补挂旋转动画，避免加载指示器停在原地（`ChatOverlayManager.StarRayActivityView`）。

## 2025-12-19

- 长期记忆（用户级）SoT 更新：后端补齐“idle 触发 + 游标可观测性”
  - 新增接口：`POST /functions/v1/user-memory-refresh`（端侧在用户 idle 5-10 分钟后调用，可 `force=true`）
  - 游标补充：`profiles.long_term_memory_last_message_id/long_term_memory_last_chat_id`（用于排障“总结到哪个对话/消息”）
  - 首次构建：从“最近用户消息”开始构建长期记忆，避免从最早历史回填导致长期看不到效果
  - 契约参考：`../staroracle-backend/docs/contracts/user-memory-refresh.md` 与 `../staroracle-backend/docs/contracts/chat-send.md`
- 长期记忆（用户级）端侧补齐：对话结束后启动 idle 计时（默认 5 分钟），计时到达调用 `POST /functions/v1/user-memory-refresh (force=true)`；发送新消息/点“重试”会取消并重置该计时（`NativeChatBridge` / `UserMemoryRefreshService`）。
- 语音停止卡死/崩溃再修复：修复“begin 内部调用 stop 会创建延迟停用任务，而取消该任务时因 `try? Task.sleep` 吞掉取消导致立刻 `setActive(false)`”的竞态；现在 begin 会先取消 pending deactivation，再以 `deactivateAudioSession=false` 方式做资源清理；真正停止时延迟停用会正确响应取消（catch `CancellationError` 直接 return），并补充 `audioEngine.reset()` 与 `setActive(true)`（不带 deactivation options）降低停用阶段触发 `brk #0x1` 风险（`StarO/StarO/InputDrawerManager.swift`）。自测：`xcodebuild -scheme StarO -sdk iphonesimulator build`。
- 语音 stop 队列断言修复：修复 `libdispatch.dylib _dispatch_assert_queue_fail`（常见于 stop 时 tap 仍在追加 buffer、与 `endAudio()` 并发导致系统内部队列断言）；现在 stop 顺序调整为“先 stop engine → removeTap → endAudio/cancel”，并将 tap block 改为直接捕获 `request`（不再通过 `self.recognitionRequest` 取引用）以减少竞态（`StarO/StarO/InputDrawerManager.swift`）。自测：`xcodebuild -scheme StarO -sdk iphonesimulator build`。
- ChatOverlay 约束警告修复：初始化时不再激活 expanded 约束（保持 `isExpandedLayoutActive=false` 且隐藏 expandedView），避免在 collapsed 高度 65 下触发布局冲突日志，expanded 状态仍在切换时动态激活（`StarO/StarO/ChatOverlayManager.swift`）。
- 语音串行域统一：参考《语音问题诊断》，将 Speech/Audio 操作收敛到主线程串行执行，引入 `speechToken` 防止旧回调/延迟 stop 干扰当前会话；全部 UI 更新与状态切换保持在主线程，减少 `_dispatch_assert_queue_fail` 队列断言风险（`StarO/StarO/InputDrawerManager.swift`）。自测：`xcodebuild -scheme StarO -sdk iphonesimulator build`。
- 语音 tap 再加固：tap block 抽到非 MainActor 的 helper（只追加 buffer，不触碰 self/UI），避免因 UIKit/UIViewController 隐式 MainActor 隔离导致音频线程触发 `_dispatch_assert_queue_fail`（`StarO/StarO/InputDrawerManager.swift`）。
- 语音 tap 闭包隔离修复：将 tap helper 从 `UIViewController` 类型内部挪到文件级作用域，避免闭包在 MainActor 上下文创建时被推断为 `@MainActor`，从根上消除 `_swift_task_checkIsolatedSwift → dispatch_assert_queue` 触发路径（`StarO/StarO/InputDrawerManager.swift`）。自测：`xcodebuild -scheme StarO -sdk iphonesimulator build`。
- 语音可用性提示修复：InputDrawerWindow 为了触摸透传不会 `makeKeyAndVisible()`，导致在其 VC 上 `present` 提示弹窗可能静默失败；改为从主窗口的 top VC `present`，确保权限/不可用原因能展示给用户；同时为 `SFSpeechRecognizer(locale: zh-CN)` 增加 fallback（`StarO/StarO/InputDrawerManager.swift`）。自测：`xcodebuild -scheme StarO -sdk iphonesimulator build`。
- 语音“无反应”可见反馈：麦克风点击时显示 toast“正在开启语音…”，并在权限/服务不可用/启动抛错等分支同步 toast + `Foundation.NSLog` 错误日志，避免用户无反馈（`StarO/StarO/InputDrawerManager.swift`）。自测：`xcodebuild -scheme StarO -sdk iphonesimulator build`。
- 语音定位增强：在语音启动的每个关键 guard/权限分支加入不可屏蔽的 `Foundation.NSLog`，便于从控制台直接判断卡在“Info.plist/服务可用性/语音权限/麦克风权限/AVAudioEngine 启动异常”的哪一步（`StarO/StarO/InputDrawerManager.swift`）。自测：`xcodebuild -scheme StarO -sdk iphonesimulator build`。
- 语音识别链路诊断：新增 tap 首包日志与识别回调日志（len/final/error），并在支持时启用 `requiresOnDeviceRecognition` + `taskHint=.dictation`，用于区分“音频未采集”与“识别服务无回调/网络问题”（`StarO/StarO/InputDrawerManager.swift`）。自测：`xcodebuild -scheme StarO -sdk iphonesimulator build`。
- 语音无回调兜底（回退）：曾实现“4s 无回调自动重试/联网回退”，但会在用户静默时误触发且提示易误导；现已移除联网回退与相关 toast，仅保留“请开始说话”提示（`StarO/StarO/InputDrawerManager.swift`）。
- 语音无输出修复：修复 beginSpeechRecognition 内部先写 `speechToken` 又调用 `stopSpeechRecognitionLocked(force: true)` 导致 token 被清空，使得识别回调/兜底任务的 token 校验永远失败（表现为“开始说话但永远无识别回调日志/无兜底”）；改为 stop 之后再写入 token（`StarO/StarO/InputDrawerManager.swift`）。自测：`xcodebuild -scheme StarO -sdk iphonesimulator build`。

## 2025-12-20

- 语音输入累计：Speech partial result 改为“单调追加”策略（增长追加 delta、回退忽略），避免输入框内容反复回退刷新导致“无法持续累计”的体感问题（`StarO/StarO/InputDrawerManager.swift`）。
- 麦克风按钮状态修复：移除 stop 清理阶段异步 `DispatchQueue.main.async` 更新导致的“后写覆盖”，改为主线程同步更新图标/高亮，确保录音态显示停止图标并高亮（`StarO/StarO/InputDrawerManager.swift`）。
- 语音 UI 回归：麦克风按钮录音态显示“停止”图标并以紫色底高亮；toast 仅保留“请开始说话”，避免让用户误以为需要等待联网后才能开始说话（`StarO/StarO/InputDrawerManager.swift`）。自测：`xcodebuild -scheme StarO -sdk iphonesimulator build`。
- 语音按钮状态增强：录音态同时设置 `.normal/.highlighted/.selected` 多种 control state 的图标，并显式设置 `isSelected`，避免个别状态仍渲染旧麦克风图标；并强制 `setNeedsLayout/layoutIfNeeded` 触发重绘（`StarO/StarO/InputDrawerManager.swift`）。自测：`xcodebuild -scheme StarO -sdk iphonesimulator build`。
- 语音交互再加固：麦克风按钮状态改为与 `isSpeechRecording` 的 `didSet` 绑定（跨线程自动回主线程更新），并在 begin 时先切到录音态以保证 UI 立即反馈；转写显示改为“最长文本胜出 + 内容未变化跳过更新”，减少 partial 改写导致的反复刷新与按钮态被覆盖（`StarO/StarO/InputDrawerManager.swift`）。自测：`xcodebuild -project StarO/StarO.xcodeproj -scheme StarO -sdk iphonesimulator build`。
- 语音发送联动：录音态下点击“发送/回车提交”会先停止语音识别与麦克风监听，再提交消息，避免发送后识别回调继续写回输入框造成“发出后又出现新文字”的问题（`StarO/StarO/InputDrawerManager.swift`）。自测：`xcodebuild -project StarO/StarO.xcodeproj -scheme StarO -sdk iphonesimulator build`。
- Galaxy 启动点亮提速：现状永久点亮依赖 `syncSupabaseStarsIfNeeded()->StarsService.fetchStars`，导致启动时 `StarStore.constellation` 为空、星点需要等云端回源才出现；新增本地缓存 `GalaxyStateCache`（seed/permanentIndices/24h 临时高亮），启动先读缓存立即点亮，再异步拉取云端 seed/highlights/stars 回源刷新并回写缓存（`StarO/StarO/GalaxyStateCache.swift`、`StarO/StarO/GalaxyBackgroundView.swift`）；自测：`xcodebuild -project StarO/StarO.xcodeproj -scheme StarO -sdk iphonesimulator build`。
- 长期记忆补齐：生产环境部署 `user-memory-refresh` Edge Function（`supabase functions deploy user-memory-refresh`），并在端侧恢复登录后按 idle 判定触发一次补刷新；个人主页“长期记忆”区增加“立即刷新”按钮，展示 updated/reason/processed/tokens 便于验证与排障（`StarO/StarO/RootView.swift`、`StarO/StarO/NativeChatBridge.swift`、`StarO/StarO/AccountView.swift`、`StarO/StarO/UserMemoryRefreshService.swift`）。
- 长期记忆排障：确认远端 `profiles.long_term_memory_*` 字段尚未执行 migration，导致 `user-memory-refresh` 500 UM99；端侧补齐错误文案把后端 `error` 字段展示出来，避免只看到 unknown，便于提示“先跑远端迁移”（`StarO/StarO/UserMemoryRefreshService.swift`）。
- 仓库卫生：将 `xcuserdata/*.xcuserstate` 等 Xcode 用户态文件加入 `.gitignore` 并从 git index 移除追踪，避免制造无意义 diff 与冲突。

## 2025-12-21

- 长期记忆（用户级）UM99 修复闭环：后端已补齐远端 `profiles.long_term_memory_*` 迁移（此前缺字段导致 `user-memory-refresh` 500），并修复 `SUMMARY_MODEL_ID` 为空字符串时的模型回退；回归 `user-memory-refresh (force=true)` 可成功更新并回填游标，个人主页长期记忆区可见最新摘要（后端记录见 `staroracle-backend/docs/log.md`）。
- Galaxy 防误触：顶部菜单栏及周边区域禁用 Galaxy 点击；未命中星点时不生成灵感卡片（仅命中星点才触发高亮与出卡）（`StarO/StarO/GalaxyBackgroundView.swift`、`StarO/StarO/Galaxy/GalaxyViewModel.swift`）。
- 键盘弹起卡顿优化：预热 ChatOverlay 窗口（隐藏态提前创建窗口/UITableView），并将“输入框聚焦滚到底”改为非强制（仅接近底部才滚动），减少聚焦瞬间主线程负载（`StarO/StarO/NativeChatBridge.swift`、`StarO/StarO/ChatOverlayManager.swift`）。
