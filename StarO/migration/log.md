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
