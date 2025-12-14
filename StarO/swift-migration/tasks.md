# StarOracle Swift 迁移任务清单 (Tasks)

> **版本**：1.2  
> **日期**：2025-12-13

---

## 任务状态说明

- `[ ]` 未开始
- `[/]` 进行中
- `[x]` 已完成
- `[!]` 阻塞/需讨论

---

## M0: 准备阶段

### T-M0-01: 添加 Supabase SDK 依赖

- **状态**：`[ ]`
- **预计**：0.5h
- **负责人**：-

**操作步骤**：

1. 打开 `StarO.xcodeproj`
2. File → Add Package Dependencies
3. 添加 `https://github.com/supabase/supabase-swift`
4. 选择版本 `2.0.0` 或更高
5. 编译验证无报错

---

### T-M0-02: 创建 SupabaseManager

- **状态**：`[ ]`
- **预计**：0.5h
- **负责人**：-

**新建文件**：`StarO/StarO/Services/SupabaseManager.swift`

```swift
import Supabase

@MainActor
final class SupabaseManager {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: "https://pqpudakplohyqpcrlpou.supabase.co")!,
            supabaseKey: "YOUR_ANON_KEY_HERE"
        )
    }
    
    var currentSession: Session? {
        client.auth.currentSession
    }
    
    var accessToken: String? {
        currentSession?.accessToken
    }
    
    var isAuthenticated: Bool {
        currentSession != nil
    }
}
```

**验证**：App 启动不崩溃，`SupabaseManager.shared.client` 可访问。

---

### T-M0-03: 配置环境变量

- **状态**：`[ ]`
- **预计**：0.25h
- **负责人**：-

**方案 A**：硬编码（开发阶段）
**方案 B**：Info.plist 或 xcconfig

建议先用方案 A 快速验证，后续改为方案 B。

---

## M1: Auth 集成

### T-M1-01: 创建 AuthService

- **状态**：`[ ]`
- **预计**：1h
- **负责人**：-

**新建文件**：`StarO/StarO/Services/AuthService.swift`

功能：
- `signIn(email:password:)` - 登录
- `signUp(email:password:)` - 注册
- `signOut()` - 登出
- `restoreSession()` - 恢复会话（无 session 时走匿名登录）
- `signInAnonymously()` - 匿名登录（无感拿 JWT；支持“先聊后绑”）

---

### T-M1-02: 创建登录 UI

- **状态**：`[ ]`
- **预计**：1.5h
- **负责人**：-

**新建文件**：`StarO/StarO/Views/LoginView.swift`

UI 元素：
- 邮箱输入框
- 密码输入框
- 登录/注册按钮
- 错误提示

**集成点（本期决策：先匿名，后绑定）**：
- App 启动后直接进入主页/聊天（匿名登录完成后即可调用后端）。
- 登录 UI 作为“绑定账号弹窗/页面”，在触发点出现（示例：聊 2 轮后、点亮星卡想看内容时、付费前）。

---

### T-M1-03: App 启动时恢复会话

- **状态**：`[ ]`
- **预计**：0.5h
- **负责人**：-

**修改文件**：`StarO/StarO/StarOApp.swift`

```swift
.task {
    await authService.restoreSession()
}
```

---

### T-M1-04: 启动即匿名登录（无感获取 JWT）

- **状态**：`[ ]`
- **预计**：0.5h
- **负责人**：-

**修改文件**：`StarO/StarO/Services/AuthService.swift`

行为：
- 若存在 `currentSession`：直接使用
- 若不存在：调用 Supabase 匿名登录（拿到 JWT），确保 `chat-send/star-pluck/...` 可用

依赖：
- Supabase Dashboard 开启 Anonymous sign-ins
- 若后续要“绑定账号不丢数据”，需配合完成 Identity Linking（见 T-M1.5-07）

## M1.5: 多登录方式支持

### T-M1.5-01: 添加 GoogleSignIn SDK

- **状态**：`[ ]`
- **预计**：0.5h
- **负责人**：-

**操作步骤**：
1. File → Add Package Dependencies
2. 添加 `https://github.com/google/GoogleSignIn-iOS`
3. 选择版本 `7.0.0` 或更高

---

### T-M1.5-02: 配置 Supabase Auth Providers

- **状态**：`[/]`
- **预计**：1h
- **负责人**：-

**Supabase Dashboard 配置**：
1. Authentication → Providers → Apple
   - 配置 Client ID (来自 Apple Developer)
2. Authentication → Providers → Google
   - 配置 Client ID 和 Secret (来自 Google Cloud Console)
3. Phone 登录：暂缓（短信成本与合规复杂度）

**快速核对**（推荐）：在后端仓库执行 `deno run -A scripts/auth-providers-status.ts .env.remote` 查看远端 provider 是否 enabled。

当前状态（2025-12-13）：
- Email：enabled（默认）
- Google：enabled（已配置）
- Apple：待开通（需 Apple 开发者账号）

---

### T-M1.5-03: 扩展 AuthService 支持 Apple 登录

- **状态**：`[ ]`
- **预计**：1.5h
- **负责人**：-

**修改文件**：`StarO/StarO/Services/AuthService.swift`

功能：
- `signInWithApple(idToken:nonce:)` - Apple 登录

---

### T-M1.5-04: 扩展 AuthService 支持 Google 登录

- **状态**：`[ ]`
- **预计**：1h
- **负责人**：-

**修改文件**：`StarO/StarO/Services/AuthService.swift`

功能：
- `signInWithGoogle(from:)` - Google 登录

---

### T-M1.5-05: 扩展 AuthService 支持手机号 OTP

- **状态**：`[!]`
- **预计**：1h
- **负责人**：-

**修改文件**：`StarO/StarO/Services/AuthService.swift`

说明：本期暂不做 Phone 登录（短信成本高），该任务保留占位，后续如需再开启。

功能：
- `sendOTP(phone:)` - 发送验证码
- `verifyOTP(phone:code:)` - 验证码验证

---

### T-M1.5-06: 创建统一登录 UI

- **状态**：`[ ]`
- **预计**：2h
- **负责人**：-

**新建/修改文件**：`StarO/StarO/Views/LoginView.swift`

UI 元素：
- Sign in with Apple 按钮
- Sign in with Google 按钮
- 邮箱登录入口
- 手机号登录入口（暂缓）
- 切换登录方式

---

### T-M1.5-07: 匿名账号 → 绑定账号（不丢数据）

- **状态**：`[!]`
- **预计**：2-4h
- **负责人**：-

目标（用户视角）：先随便聊/先生成星；后续绑定 Apple/Google/邮箱后，历史 chats/messages/stars 还在。

推荐实现（优先）：
- 使用 Supabase 的 Identity Linking，把新 provider 绑定到同一个用户上（保持 `user_id` 不变）。

备选实现（兜底）：
- 若 iOS SDK 无法完成 linking，则需要后端提供“合并账号/迁移数据”能力（将匿名用户产生的数据迁移到新账号）。

该任务是“先聊后绑”体验能否成立的关键，未完成前不建议上线强制绑定触发点。

---

### T-M1.5-08: 渐进式强制登录触发点（产品策略落地）

- **状态**：`[ ]`
- **预计**：1-2h
- **负责人**：-

触发点建议（可组合）：
- 聊满 2 轮后提示“绑定账号以保存星图”
- 点亮星卡想查看完整内容时要求绑定
- 付费前要求绑定（避免订阅归属不清）

实现要点：
- 匿名用户依旧可看“基础体验”（避免过早打断）
- 触发时弹出 `LoginView`；绑定成功后回到原上下文继续

## M2: Chat 对接

### T-M2-01: 适配 StreamingClient SSE 格式

- **状态**：`[ ]`
- **预计**：1h
- **负责人**：-

**修改文件**：`StarO/StarO/StreamingClient.swift`

当前解析 OpenAI 格式：
```
data: {"choices":[{"delta":{"content":"..."}}]}
```

需支持后端格式：
```
event: delta
data: {"text": "...", "trace_id": "..."}

event: done
data: {"message_id": "...|null", "trace_id": "..."}

event: error
data: {"code":"CHxx","message":"...","trace_id":"...|''|<缺失>"}
```

**改动点**：
1. 增加 `event:`/`data:` 行解析（SSE 标准格式）
2. `event=delta`：解析 JSON 的 `text` 并 yield 到 UI
3. `event=done`：结束流（可记录 `message_id` 做同步/幂等）
4. `event=error`：抛错；若 HTTP=429，读取 `Retry-After` 做退避重试

---

### T-M2-BE-01: chat-send 支持 temperature（后端必改）

- **状态**：`[ ]`
- **预计**：0.5-1h
- **负责人**：-

后端：`/Users/pot/Documents/staroracle-backend/supabase/functions/chat-send/index.ts`

改动：
- 读取 `config_override.temperature`（若存在）并在调用上游模型时作为 `temperature` 传入
- 说明：这决定了用户感知到的“回答更稳 or 更发散”

---

### T-M2-BE-02: trace_id 全链路一致（后端必改）

- **状态**：`[ ]`
- **预计**：0.5h
- **负责人**：-

目标：
- 所有成功/失败（含 `401/400/429/502/...`）都返回可用 `trace_id`
- `X-Trace-Id` 若传入则回显；未传则服务端生成

---

### T-M2-BE-03: 写入真实 token_count（后端必改）

- **状态**：`[ ]`
- **预计**：1-2h
- **负责人**：-

目标（用户视角）：长对话不“断片/变慢/莫名失败”，摘要与截断逻辑稳定。

实现建议：
- 在写入 `messages` 时同时写入 `token_count`（至少是可靠估算；如需精确可引入 tokenizer）

---

### T-M2-BE-04: chat-send 异步铸星（后端必改）

- **状态**：`[ ]`
- **预计**：2-4h
- **负责人**：-

本期决策：对话完成后由后端异步判定“是否需要成星”，仅在需要时才写入 `stars`（生成星卡）。客户端不再在 `done` 后显式调用 `star-cast`。

实现建议：
- chat-send 完成保存 assistant message 后，异步执行两步：
  1) 深度判定：大模型判断本次对话是否“足够深刻需要成星”（否则直接结束，不写 stars）
  2) 成星写入：若通过，执行“结构化提取 + 写 stars”（可复用/抽取 `star-cast` 的结构化提取与坐标逻辑）
- 重要：是否成星 **不影响 Galaxy 底图布局**；只影响是否新增一张星卡（stars 记录）
- 客户端通过 Realtime 订阅 `stars` INSERT（或轮询）来播放“成星”动效与点亮

---

### T-M2-BE-05: 星卡等级/演化字段落库（后端必改）

- **状态**：`[ ]`
- **预计**：2-4h（取决于规则复杂度）
- **负责人**：-

目标（用户视角）：
- 星卡有“等级/演化”的差异化样式与稀有度反馈；
- 不改变 Galaxy 底图形态与布局。

后端现状核对：
- `stars.evolution_stage`/`stars.brightness` 在 schema 中存在默认值，但当前 `star-cast`/`chat-send` 没有基于“深度/回顾”去更新它们。
- schema 中还存在 `stars.insight_level` / `stars.star_arm_assignment` 等扩展列（若环境已应用对齐迁移），但当前未写入。

待拍板（需要明确输出契约，避免返工）：
- 采用哪些字段作为“等级/演化”的 SoT：
  - 方案 A：复用 `evolution_stage`（字符串枚举）+ `insight_level`（数字）
  - 方案 B：新增 `card_level` / `card_pattern_id`（或 `stars.metadata` JSONB）
- “深度判定结果”如何映射到等级（例如 low/med/high → 1/2/3 级）
- 回顾（review_count）是否会推动升级（若是，需要同时实现 T-M3-BE-01 并新增/更新 `review_count` 字段）

---

### T-M2-BE-06: 成星绑定底图星点（不新增星点）（后端必改）

- **状态**：`[ ]`
- **预计**：1-2h（不含 DB 迁移）
- **负责人**：-

目标（产品拍板）：
- 生成星卡时，点亮的是 **Galaxy 底图已存在的星点**；不允许“凭空新增一个新坐标点”。

实现建议（推荐）：
- DB：为 `stars` 增加 `galaxy_star_indices int4[]`（该星卡绑定的底图星点索引集合，SoT）。
- 写入：在异步成星（chat-send 后台）或 `star-cast` 写 `stars` 时同时写入 `galaxy_star_indices`；
  - 路径 A：由客户端在开始对话前选中一个“区域”（多个 index），后端在成星时写入该集合（或其子集）。
  - 路径 B：由后端按规则选择一组 index（必须来自底图星点集合）。
- 渲染：Swift 端以 `galaxy_star_indices` 点亮对应底图星点；可用集合第一个 index 作为该卡主锚点；`coord_*` 可由 index 推导写入以兼容旧逻辑。

备注：
- 若暂时不加字段，也必须保证后端写入的 `coord_*` 来自“底图星点集合”中的点（同一套算法/同一套索引），否则会出现“点亮不到/误点亮”的问题。

### T-M2-02: LiveAIService 改用 Supabase Endpoint

- **状态**：`[ ]`
- **预计**：1h
- **负责人**：-

**修改文件**：`StarO/StarO/AppEnvironment.swift` - `LiveAIService`

改动：
1. Endpoint 改为 `$SUPABASE_URL/functions/v1/chat-send`
2. Header 改为 `Authorization: Bearer <ACCESS_TOKEN>`
3. Header 添加 `Accept: text/event-stream`
4. （可选，强烈建议）Header 添加 `X-Trace-Id` 与 `X-Idempotency-Key`
5. Body 改为 `{"chat_id":"...","message":"...","config_override":{"mask_id":"<uuid>","temperature":0.6},"idempotency_key":"<uuid>"}`（可选字段按需）

---

### T-M2-03: 创建 Chat 时调用 Supabase

- **状态**：`[ ]`
- **预计**：1h
- **负责人**：-

**修改文件**：`StarO/StarO/AppEnvironment.swift` - `createSession()`

改动：
1. 调用 `POST /rest/v1/chats` 创建 chat
   - 注意：`chats.user_id` 在当前后端 schema 中为 `NOT NULL` 且无默认值，客户端插入时需显式带上 `user_id = session.user.id`（同时满足 RLS）。
2. 获取返回的 `chat_id`
3. 传递给后续 chat-send 调用

---

### T-M2-04: 消息 ID 处理

- **状态**：`[ ]`
- **预计**：0.5h
- **负责人**：-

`chat-send` 返回 `event: done` 时包含 `message_id`，可用于本地/云端消息定位与同步；但 **铸星 `star-cast` 只需要 chat_id**（不依赖 message_id）。

---

## M3: Stars 对接

### T-M3-01: 创建 StarService

- **状态**：`[ ]`
- **预计**：1h
- **负责人**：-

**新建文件**：`StarO/StarO/Services/StarService.swift`

功能：
- `castStar(chatId:x:y:region:)` - 铸星（点击坐标/调试/补偿；主链路不依赖）
- `pluckInspiration(tag:)` - 摘星（公共灵感库）
- `pluckReview()` - 回顾（最近一颗星）

---

### T-M3-02: 对话结束后触发铸星

- **状态**：`[ ]`
- **预计**：1h
- **负责人**：-

**修改文件**：`StarO/StarO/NativeChatBridge.swift` - `performStreaming()`

在 SSE 完成后（`event: done`），进入“铸星等待态”并监听新星出现：
1. 结束流式 UI（回答已完整）
2. （可选）显示轻提示：“正在成星…”
3. 通过轮询等待 `stars` 新增（推荐：按 `chat_id` + `created_at` 条件查询，避免全量拉取）：
   - 收到新 star 后播放“文字 → 星星飞入银河”的动效
   - 在当前对话的“最后一条消息后面”插入星卡
   - 刷新星系数据（点亮 `stars.galaxy_star_indices` 对应的底图星点；不改 Galaxy 底图布局）

说明：
- 主链路的“铸星”由后端异步完成（见 T-M2-BE-04）
- `star-cast` 仍可用于“点击坐标铸星/调试/补偿”，但不应成为主链路依赖

---

### T-M3-BE-01: review 更新（后端必改）

- **状态**：`[ ]`
- **预计**：1-2h
- **负责人**：-

后端：`/Users/pot/Documents/staroracle-backend/supabase/functions/star-pluck/index.ts`

改动：
- `mode=review` 时，在返回 star 的同时更新“回顾次数/相关字段”（用于后续养成与推荐）
- 说明：需要确认字段设计（如 `stars.review_count` 是否新增；以及未来是否影响星卡等级/图案）

### T-M3-03: 星星点击触发摘星

- **状态**：`[ ]`
- **预计**：1h
- **负责人**：-

**修改文件**：`StarO/StarO/Galaxy/GalaxyTouchOverlay.swift` 或相关触摸处理

点击星星时：
1. **若点击命中已点亮星点（有星卡）**：直接展示本地已加载的星卡详情（来自 `stars` 表同步/缓存；必要时回源查表）。
2. **若点击命中未点亮星点 / 或点击一个区域**：弹出“灵感卡”（钩子），调用 `StarService.pluckInspiration(tag:)` 显示 `InspirationSheet`。
3. 灵感卡用于引导继续对话：用户点击卡片输入区进入对话；对话结束后异步判定是否生成 1 张星卡（可能 0 张）。

---

### T-M3-04: 星星数据模型

- **状态**：`[ ]`
- **预计**：0.5h
- **负责人**：-

**新建文件**：`StarO/StarO/Models/SupabaseStar.swift`

```swift
struct SupabaseStar: Codable, Identifiable {
    let id: String
    let question: String?
    let answer: String?
    let summary: String?
    let tags: [String]?
    let coordX: Double
    let coordY: Double
    let coordZ: Double
    let primaryColorHex: String?
    let hapticPatternId: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, question, answer, summary, tags
        case coordX = "coord_x"
        case coordY = "coord_y"
        case coordZ = "coord_z"
        case primaryColorHex = "primary_color_hex"
        case hapticPatternId = "haptic_pattern_id"
        case createdAt = "created_at"
    }
}
```

---

### T-M3-05: 星卡等级/图案（仅影响卡片样式）

- **状态**：`[ ]`
- **预计**：1-2h
- **负责人**：-

说明（用户视角）：
- “等级/图案”用于让星卡（Card）更有层次与稀有感
- **不改变** Galaxy 内星星形态与位置（本期暂定）

实现建议：
- 后端在生成 star 时写入卡片相关字段（例如 `card_level` / `card_pattern_id`，或统一放入 `stars.metadata` JSONB）
- Swift 端根据字段渲染对应的星卡图案与样式

注意：
- 字段命名与落库方式需要先拍板（避免后续兼容成本）

## M4: 数据同步

### T-M4-01: 创建 SyncService

- **状态**：`[ ]`
- **预计**：1h
- **负责人**：-

**新建文件**：`StarO/StarO/Services/SyncService.swift`

功能：
- `fetchChats()` - 获取会话列表
- `fetchMessages(chatId:)` - 获取消息列表
- `fetchStars()` - 获取星星列表

---

### T-M4-02: ConversationStore 改为云端

- **状态**：`[ ]`
- **预计**：2h
- **负责人**：-

**修改文件**：`StarO/StarO/ConversationStore.swift`

改动：
1. 初始化时从 Supabase 拉取会话
2. 创建会话时调用 SyncService
3. 保留本地缓存作为离线支持

---

### T-M4-03: 星系数据从 Supabase 加载

- **状态**：`[ ]`
- **预计**：1h
- **负责人**：-

**修改文件**：`StarO/StarO/Galaxy/GalaxyViewModel.swift` 或 `ios-native/Packages/StarOracleFeatures/Sources/StarOracleFeatures/Stores/GalaxyStore.swift`

改动：
1. 启动时调用 `SyncService.fetchStars()`
2. 将 Stars 坐标传递给 `GalaxyGenerator`

---

## M5: 测试验收

### T-M5-01: 登录流程手动测试

- **状态**：`[ ]`
- **预计**：0.5h
- **负责人**：-

**验证项**：
- [ ] 注册新用户成功
- [ ] 登录已有用户成功
- [ ] 登出后 Token 清除
- [ ] 重启 App 自动恢复会话

---

### T-M5-02: Chat 流程手动测试

- **状态**：`[ ]`
- **预计**：0.5h
- **负责人**：-

**验证项**：
- [ ] 发送消息 → SSE 流式返回
- [ ] 回复内容符合星瑜提示词风格
- [ ] 消息保存到 Supabase（在 Dashboard 查看）

---

### T-M5-03: Stars 流程手动测试

- **状态**：`[ ]`
- **预计**：0.5h
- **负责人**：-

**验证项**：
- [ ] 对话结束后自动铸星
- [ ] 星系中显示新星星
- [ ] 点击星星 → 显示灵感卡

---

### T-M5-04: 数据同步手动测试

- **状态**：`[ ]`
- **预计**：0.5h
- **负责人**：-

**验证项**：
- [ ] 重启 App → 历史会话仍在
- [ ] 多次对话 → 消息顺序正确
- [ ] 星星数量与 Dashboard 一致

---

## M6: App Store 付费

### T-M6-01: 创建订阅相关数据表

- **状态**：`[ ]`
- **预计**：1h
- **负责人**：-

**后端文件**：`staroracle-backend/supabase/migrations/20251212200000_subscriptions.sql`

数据表：
- `subscriptions` - 订阅记录
- `user_entitlements` - 用户权益

---

### T-M6-02: 创建 verify-receipt Edge Function

- **状态**：`[ ]`
- **预计**：2h
- **负责人**：-

**后端文件**：`staroracle-backend/supabase/functions/verify-receipt/index.ts`

功能：
- 接收 Transaction 数据
- 调用 Apple Server API 验证
- 更新 subscriptions 表
- 提供 `GET /functions/v1/get-entitlements` 查询权益（见 `StarO/contracts/payment.md`）

---

### T-M6-03: 创建 PaymentService

- **状态**：`[ ]`
- **预计**：2h
- **负责人**：-

**新建文件**：`StarO/StarO/Services/PaymentService.swift`

功能 (StoreKit 2)：
- `loadProducts()` - 加载商品
- `purchase(_:)` - 发起购买
- `verifyWithBackend(_:)` - 后端验证

---

### T-M6-04: 创建商品展示 UI

- **状态**：`[ ]`
- **预计**：2h
- **负责人**：-

**新建文件**：`StarO/StarO/Views/SubscriptionView.swift`

UI 元素：
- 商品列表（月度/年度）
- 价格展示
- 购买按钮
- 当前订阅状态

---

### T-M6-05: 集成付费状态检查

- **状态**：`[ ]`
- **预计**：1h
- **负责人**：-

**修改文件**：功能入口处

改动：
- 优先调用 `GET /functions/v1/get-entitlements` 获取 `is_premium`
- 非付费用户显示升级提示

---

### T-M6-06: 付费功能测试

- **状态**：`[ ]`
- **预计**：1h
- **负责人**：-

**验证项**：
- [ ] 沙盒环境购买成功
- [ ] 收据验证正确
- [ ] 订阅状态更新
- [ ] 权益生效

---

## 任务依赖关系

```
M0 ──▶ M1 ──▶ M1.5 ──▶ M2 ──▶ M3 ──▶ M4 ──▶ M5 ──▶ M6
 │      │       │        │      │      │      │      │
准备  邮箱    多登录    Chat  Stars  Sync   验收   付费
```

---

## 预计总工时

| 里程碑             | 工时             |
| ------------------ | ---------------- |
| M0: 准备阶段       | 1.25h            |
| M1: Auth 基础      | 3h               |
| M1.5: 多登录方式   | 7h               |
| M2: Chat 对接      | 3.5h             |
| M3: Stars 对接     | 3.5h             |
| M4: 数据同步       | 4h               |
| M5: 测试验收       | 2h               |
| M6: App Store 付费 | 9h               |
| **总计**           | **~33h** (~5 天) |
