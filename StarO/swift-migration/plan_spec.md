# StarOracle Swift 迁移计划与规格 (Plan & Spec)

> **版本**：1.2  
> **日期**：2025-12-13

---

## 1. 里程碑规划

```
M0: 准备阶段 ──────────▶ M1: Auth 基础 ──────────▶ M1.5: 多登录方式
      │                      │                        │
      │ 添加依赖              │ 邮箱/密码              │ Apple/Google
      │ 环境配置              │ Token 管理             │ （Phone 暂缓）
      │                      │                        │
      ▼                      ▼                        ▼
M2: Chat 对接 ──────────▶ M3: Stars 对接 ──────────▶ M4: 数据同步
      │                      │                        │
      │ SSE 流式对话          │ star-cast              │ chats 同步
      │ 消息同步              │ star-pluck             │ messages/stars
      │                      │                        │
      ▼                      ▼                        ▼
M5: 测试验收 ──────────▶ M6: App Store 付费
      │                      │
      │ E2E 测试              │ StoreKit 2
      │ 回归测试              │ 收据验证
      │                      │ 订阅状态管理
```

---

## 2. 里程碑详情

### M0: 准备阶段

**目标**：环境搭建，最小化验证 Supabase SDK 集成

**产出**：
- [ ] 添加 `supabase-swift` SPM 依赖
- [ ] 创建 `SupabaseManager.swift` 单例
- [ ] 配置 Supabase URL 和 Anon Key

**代码变更**：

#### [NEW] `StarO/StarO/Services/SupabaseManager.swift`

```swift
import Supabase

@MainActor
final class SupabaseManager {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: "https://pqpudakplohyqpcrlpou.supabase.co")!,
            supabaseKey: "<ANON_KEY>"
        )
    }
    
    var currentSession: Session? {
        client.auth.currentSession
    }
    
    var accessToken: String? {
        currentSession?.accessToken
    }
}
```

---

### M1: Auth 集成

**目标**：用户可通过邮箱/密码注册、登录，Token 自动管理

**产出**：
- [ ] 登录/注册 UI（可复用现有配置页或新建）
- [ ] `AuthService` 封装认证逻辑
- [ ] 登录状态持久化
- [ ] 启动即匿名登录（无感获取 JWT；支持“先聊后绑”）

**代码变更**：

#### [NEW] `StarO/StarO/Services/AuthService.swift`

```swift
import Supabase

@MainActor
final class AuthService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    
    private var client: SupabaseClient { SupabaseManager.shared.client }
    
    func signIn(email: String, password: String) async throws {
        let session = try await client.auth.signIn(email: email, password: password)
        isAuthenticated = true
        currentUser = session.user
    }
    
    func signUp(email: String, password: String) async throws {
        let response = try await client.auth.signUp(email: email, password: password)
        if let session = response.session {
            isAuthenticated = true
            currentUser = session.user
        }
    }
    
    func signOut() async throws {
        try await client.auth.signOut()
        isAuthenticated = false
        currentUser = nil
    }
    
    func restoreSession() async {
        if let session = client.auth.currentSession {
            isAuthenticated = true
            currentUser = session.user
            return
        }

        // 启动即匿名登录：保持“开箱即聊”的体验
        // 注意：需要在 Supabase Dashboard 开启 Anonymous sign-ins；具体 SDK API 以 supabase-swift 2.x 为准
        do {
            let session = try await client.auth.signInAnonymously()
            isAuthenticated = true
            currentUser = session.user
        } catch {
            isAuthenticated = false
            currentUser = nil
        }
    }
}
```

---

### M1.5: 多登录方式支持

**目标**：支持 Apple/Google/邮箱三种登录方式（Phone 暂缓），并支持“匿名账号 → 绑定账号”的渐进式升级

**依赖配置**：

| Provider | Swift 端依赖                  | Supabase Dashboard 配置             |
| -------- | ----------------------------- | ----------------------------------- |
| Apple    | AuthenticationServices (系统) | Authentication → Providers → Apple  |
| Google   | GoogleSignIn-iOS SPM          | Authentication → Providers → Google |
| Email    | 无需                          | 默认已开启                          |
| Phone    | 无需                          | 暂缓（短信成本与合规复杂度）         |

**产出**：
- [ ] 添加 `GoogleSignIn-iOS` SPM 依赖
- [ ] 扩展 `AuthService` 支持三种登录（Email/Google/Apple；Phone 暂缓）
- [ ] 创建统一登录 UI
- [ ] 渐进式强制登录策略（示例：聊 2 轮 / 查看星卡内容 / 付费 前要求绑定）

**匿名账号绑定策略（必须拍板并落实）**：
- 目标：用户先匿名聊、生成星与聊天记录；后续绑定 Apple/Google/邮箱时 **不丢数据**。
- 推荐：使用 Supabase 的「Identity Linking」把新 provider 绑定到同一个用户上（避免 `user_id` 变化）。
- 备选：若 iOS SDK 无法完成 linking，需要后端提供“合并账号/迁移数据”能力（把匿名用户的 chats/messages/stars 迁移到新账号）。

**代码变更**：

#### [MODIFY] `StarO/StarO/Services/AuthService.swift`

```swift
import AuthenticationServices
import GoogleSignIn

extension AuthService {
    // MARK: - Sign in with Apple
    func signInWithApple(idToken: String, nonce: String) async throws {
        try await client.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
        )
        await restoreSession()
    }
    
    // MARK: - Sign in with Google
    func signInWithGoogle(from viewController: UIViewController) async throws {
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: viewController)
        guard let idToken = result.user.idToken?.tokenString else {
            throw AuthError.missingToken
        }
        try await client.auth.signInWithIdToken(
            credentials: .init(provider: .google, idToken: idToken)
        )
        await restoreSession()
    }
}
```

#### [NEW] `StarO/StarO/Views/LoginView.swift` 统一登录入口

```swift
struct LoginView: View {
    @StateObject private var authService = AuthService()
    @State private var showEmailLogin = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Sign in with Apple
            SignInWithAppleButton { request in
                request.requestedScopes = [.email, .fullName]
            } onCompletion: { result in
                handleAppleSignIn(result)
            }
            .frame(height: 50)
            
            // Sign in with Google
            Button("使用 Google 登录") {
                Task { try await authService.signInWithGoogle(from: rootVC) }
            }
            
            // Email Login
            Button("使用邮箱登录") { showEmailLogin = true }
        }
    }
}
```

---

### M2: Chat 对接

**目标**：SSE 流式对话通过 `chat-send` Edge Function

**关键改动**：`LiveAIService` 改用 Supabase endpoint

**代码变更**：

#### [MODIFY] `StarO/StarO/AppEnvironment.swift` - `LiveAIService.streamResponse`

```diff
- let endpoint = configuration.endpoint.absoluteString
- let apiKey = configuration.apiKey
+ let supabaseURL = SupabaseManager.shared.client.supabaseURL.absoluteString
+ let endpoint = "\(supabaseURL)/functions/v1/chat-send"
+ let accessToken = SupabaseManager.shared.accessToken ?? ""

  var request = URLRequest(url: URL(string: endpoint)!)
  request.httpMethod = "POST"
  request.setValue("application/json", forHTTPHeaderField: "Content-Type")
+ request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
- request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
+ request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
+ // 可选：追踪与幂等（强烈建议至少在重试场景加）
+ // request.setValue(UUID().uuidString, forHTTPHeaderField: "X-Trace-Id")
+ // request.setValue(UUID().uuidString, forHTTPHeaderField: "X-Idempotency-Key")
```

#### [MODIFY] 请求体格式

```diff
- let body = StreamingClient.RequestBody(model: ..., messages: ..., stream: true)
+ let body: [String: Any] = [
+     "chat_id": currentChatId,
+     "message": question,
+     // 可选：临时覆盖（mask/温度）
+     // "config_override": ["temperature": 0.6, "mask_id": "<uuid>"], // 现状：temperature 后端未使用（T-M2-BE-01 计划补齐）
+     // 可选：与请求头 X-Idempotency-Key 等价
+     // "idempotency_key": "<uuid>"
+ ]
```

#### [NEW] SSE 响应格式对齐

后端 `chat-send` 返回的 SSE 格式（见 `StarO/contracts/chat-send.md`）：
```
event: delta
data: {"text": "...", "trace_id": "..."}

event: done
data: {"message_id": "...|null", "trace_id": "..."}

event: error
data: {"code": "CHxx", "message": "...", "trace_id": "...|''|<缺失>"}
```

现有 `StreamingClient` 需适配 `event:`/`data:` 行解析：
- `event: delta` → 解析 `data.text` 并 append 到 UI
- `event: done` → 结束流（可拿到 `message_id` 做同步/幂等）
- `event: error` → 抛错并显示错误提示（注意 429 需读取 `Retry-After`）

---

### M3: Stars 对接

**目标**：铸星和摘星功能对接后端

**目标主链路（异步铸星；需后端实现 `T-M2-BE-04`）**：
- `chat-send` 完成（SSE `event: done`）后，后端异步生成 star 并写入 `stars` 表。
- Swift 端通过 Supabase Realtime 订阅 `stars` 的 INSERT（或轮询 `fetchStars()`）感知新增：
  - 播放“文字 → 星星飞入银河”的动效
  - 更新星系数据（不需要在 `done` 时立刻调用 `star-cast`）
- `star-cast` 仍保留为独立能力（如点击坐标铸星/调试/补偿），但不作为主链路依赖。

**当前后端现状（用于过渡期联调）**：
- `chat-send` 目前不会自动铸星；若需要验证“出星链路”，可在 `done` 后临时调用 `star-cast`（最终以异步铸星主链路为准）。

**代码变更**：

#### [NEW] `StarO/StarO/Services/StarService.swift`

```swift
import Foundation
import Supabase

@MainActor
final class StarService {
    private var supabase: SupabaseClient { SupabaseManager.shared.client }

    struct CastStarResponse: Decodable {
        let ok: Bool
        let coordX: Double
        let coordY: Double
        let coordZ: Double
        let traceId: String?

        enum CodingKeys: String, CodingKey {
            case ok
            case coordX = "coord_x"
            case coordY = "coord_y"
            case coordZ = "coord_z"
            case traceId = "trace_id"
        }
    }
    
    /// 铸星：调用 star-cast
    func castStar(chatId: String, x: Double? = nil, y: Double? = nil, region: String? = nil) async throws -> CastStarResponse {
        let url = URL(string: "\(supabase.supabaseURL)/functions/v1/star-cast")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(SupabaseManager.shared.accessToken ?? "")", forHTTPHeaderField: "Authorization")
        
        var body: [String: Any] = ["chat_id": chatId]
        if let x { body["x"] = x }
        if let y { body["y"] = y }
        if let region { body["region"] = region }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(CastStarResponse.self, from: data)
    }

    struct PluckInspirationResponse: Decodable {
        struct InspirationSource: Decodable {
            let id: String
            let contentType: String
            let question: String?
            let answer: String?
            let tags: [String]?
            let createdAt: String

            enum CodingKeys: String, CodingKey {
                case id
                case contentType = "content_type"
                case question, answer, tags
                case createdAt = "created_at"
            }
        }
        let type: String
        let content: InspirationSource
        let traceId: String?

        enum CodingKeys: String, CodingKey {
            case type, content
            case traceId = "trace_id"
        }
    }

    /// 摘星：inspiration（公共灵感库）
    func pluckInspiration(tag: String? = nil) async throws -> PluckInspirationResponse {
        let url = URL(string: "\(supabase.supabaseURL)/functions/v1/star-pluck")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(SupabaseManager.shared.accessToken ?? "")", forHTTPHeaderField: "Authorization")
        
        var body: [String: Any] = ["mode": "inspiration"]
        if let tag { body["tag"] = tag }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(PluckInspirationResponse.self, from: data)
    }
}
```

---

### M4: 数据同步

**目标**：chats/messages/stars 与 Supabase 同步

**代码变更**：

#### [MODIFY] `ConversationStore` → 云端存储

当前 `ConversationStore` 使用本地存储，需改为：

1. 创建 chat 时调用 Supabase `POST /rest/v1/chats`
2. 发送消息后，`chat-send` 自动存储消息
3. 获取历史会话时从 Supabase 拉取

#### [NEW] `StarO/StarO/Services/SyncService.swift`

```swift
@MainActor
final class SyncService {
    private var supabase: SupabaseClient { SupabaseManager.shared.client }
    
    func fetchChats() async throws -> [Chat] {
        try await supabase
            .from("chats")
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value
    }
    
    func createChat(title: String? = nil) async throws -> Chat {
        guard let userId = SupabaseManager.shared.currentSession?.user.id else {
            throw URLError(.userAuthenticationRequired)
        }
        try await supabase
            .from("chats")
            .insert(["title": title ?? "新对话", "user_id": userId])
            .select()
            .single()
            .execute()
            .value
    }
    
    func fetchMessages(chatId: String) async throws -> [Message] {
        try await supabase
            .from("messages")
            .select()
            .eq("chat_id", value: chatId)
            .order("created_at", ascending: true)
            .execute()
            .value
    }
    
    func fetchStars() async throws -> [Star] {
        try await supabase
            .from("stars")
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value
    }
}
```

---

### M6: App Store 付费

**目标**：支持 App Store 内购，收据验证，订阅状态管理

**架构**：

```
┌─────────────────────────────────────────┐
│         Swift 端 (StoreKit 2)           │
│  - 展示商品列表                          │
│  - 发起购买                              │
│  - 获取 Transaction                      │
└──────────────────┬──────────────────────┘
                   ▼
┌─────────────────────────────────────────┐
│    Supabase Edge Function               │
│    /functions/v1/verify-receipt         │
│  - 调用 Apple Server API 验证            │
│  - 更新 subscriptions 表                 │
└──────────────────┬──────────────────────┘
                   ▼
┌─────────────────────────────────────────┐
│         Supabase Database               │
│  - subscriptions (订阅记录)              │
│  - user_entitlements (权益状态)          │
└─────────────────────────────────────────┘
```

**产出**：
- [ ] 后端：创建 `subscriptions` 和 `user_entitlements` 表
- [ ] 后端：创建 `verify-receipt` Edge Function
- [ ] Swift：创建 `PaymentService` (StoreKit 2)
- [ ] Swift：创建商品展示 UI

**代码变更**：

#### [BACKEND] `staroracle-backend/supabase/migrations/20251212200000_subscriptions.sql`

```sql
create table if not exists public.subscriptions (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid not null references auth.users on delete cascade,
    product_id text not null,
    original_transaction_id text not null unique,
    expires_at timestamptz,
    is_active boolean default true,
    created_at timestamptz default now(),
    updated_at timestamptz default now()
);

alter table public.subscriptions enable row level security;
create policy "Users can view own subs" on public.subscriptions
    for select using (auth.uid() = user_id);

create table if not exists public.user_entitlements (
    user_id uuid primary key references auth.users on delete cascade,
    is_premium boolean default false,
    premium_expires_at timestamptz,
    updated_at timestamptz default now()
);

alter table public.user_entitlements enable row level security;
create policy "Users can view own entitlements" on public.user_entitlements
    for select using (auth.uid() = user_id);
```

#### [NEW] `StarO/StarO/Services/PaymentService.swift`

```swift
import StoreKit

@MainActor
final class PaymentService: ObservableObject {
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    
    private let productIDs = ["staroracle.premium.monthly", "staroracle.premium.yearly"]
    
    func loadProducts() async throws {
        products = try await Product.products(for: productIDs)
    }
    
    func purchase(_ product: Product) async throws -> Transaction? {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            
            // 发送到后端验证
            try await verifyWithBackend(transaction: transaction)
            
            return transaction
        case .pending, .userCancelled:
            return nil
        @unknown default:
            return nil
        }
    }
    
    private func verifyWithBackend(transaction: Transaction) async throws {
        let url = URL(string: "\(SupabaseManager.shared.client.supabaseURL)/functions/v1/verify-receipt")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(SupabaseManager.shared.accessToken ?? "")", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "transaction_id": String(transaction.id),
            "original_id": transaction.originalID,
            "product_id": transaction.productID,
            "environment": transaction.environment.rawValue,
            // 开发期可用：后端支持 mock_verify（详见 `StarO/contracts/payment.md`）
            // "mock_verify": true
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw PaymentError.verificationFailed
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified:
            throw PaymentError.unverified
        }
    }
}

enum PaymentError: LocalizedError {
    case verificationFailed
    case unverified
}
```

---

## 3. API 契约参考

### chat-send

```http
POST /functions/v1/chat-send
Authorization: Bearer <jwt>
Accept: text/event-stream
Content-Type: application/json

{"chat_id": "uuid", "message": "用户输入", "config_override": {"mask_id":"<uuid>"}, "idempotency_key":"<uuid>"}
```

**SSE 响应**：
- `event: delta` → `{"text": "...", "trace_id": "..."}`
- `event: done` → `{"message_id": "...|null", "trace_id": "..."}`
- `event: error` → `{"code": "CHxx", "message": "...", "trace_id": "...|''|<缺失>"}`（现状：部分错误分支可能缺失）

详见 [chat-send.md](../contracts/chat-send.md)

---

### star-cast

```http
POST /functions/v1/star-cast
Authorization: Bearer <jwt>
Content-Type: application/json

{"chat_id": "uuid"}
```

**响应**：
```json
{
  "ok": true,
  "coord_x": 12.3,
  "coord_y": -4.5,
  "coord_z": 0.0,
  "trace_id": "..."
}
```

详见 [star-cast.md](../contracts/star-cast.md)

---

### star-pluck

```http
POST /functions/v1/star-pluck
Authorization: Bearer <jwt>
Content-Type: application/json

{"mode":"inspiration","tag":"mindful"}
```

**响应**：
```json
{
  "type": "inspiration",
  "content": {
    "id": "uuid",
    "content_type": "question|quote",
    "question": "...",
    "answer": "...",
    "tags": ["daily","mindful"],
    "created_at": "..."
  },
  "trace_id": "..."
}
```

详见 [star-pluck.md](../contracts/star-pluck.md)

---

### payment（App Store 内购）

```http
POST /functions/v1/verify-receipt
Authorization: Bearer <jwt>
Content-Type: application/json

{"transaction_id":"...","original_id":"...","product_id":"...","environment":"Sandbox","mock_verify":true}
```

```http
GET /functions/v1/get-entitlements
Authorization: Bearer <jwt>
```

详见 [payment.md](../contracts/payment.md)

---

## 4. 验证计划

### 4.1 单元测试

| 测试项    | 文件                         | 验证点                |
| --------- | ---------------------------- | --------------------- |
| Auth 登录 | `AuthServiceTests.swift`     | signIn/signUp/signOut |
| SSE 解析  | `StreamingClientTests.swift` | delta 格式解析        |
| Star 数据 | `StarServiceTests.swift`     | cast/pluck 响应解析   |

### 4.2 集成测试

```bash
# 在 Swift 端执行
1. 登录 → 获取 Token
2. 创建 Chat → 获取 chat_id
3. 发送消息 → SSE 流式返回
4. 铸星 → 返回 ok + 坐标；stars 表新增记录
5. 摘星 → 获取灵感卡
```

### 4.3 手动验证

- [ ] 启动 App → 登录页正常显示
- [ ] 输入邮箱密码 → 登录成功
- [ ] 发送消息 → 看到流式回复
- [ ] 对话结束后 → 星系中出现新星星
- [ ] 点击星星 → 显示灵感卡
- [ ] 杀掉 App 重启 → 数据仍在

---

## 5. 风险与回滚

- **回滚入口**：保留 `AIConfigSheet` 直连 OpenAI 配置
- **灰度策略**：通过 UserDefaults flag 控制是否使用 Supabase 后端
- **监控**：Supabase Dashboard 查看 Edge Function 调用日志

---

## 6. 待澄清 / 待对齐（基于后端当前实现）

> 已拍板：本节从“待澄清”更新为“已拍板/待讨论清单”，用于指导后端与 Swift 联调实现。

### 6.1 已拍板（本期执行）

1. **temperature 可调**：`config_override.temperature` 会影响本轮回答的稳定/发散（需要后端在调用上游模型时真正使用该值）。
2. **trace_id 全链路**：所有成功/失败响应都必须带 `trace_id`（含 `CH01/CH02/429` 等），客户端可展示“错误编号”用于排障。
3. **真实 token_count**：后端写入 `messages.token_count`（或同等可靠值），保证长对话截断与摘要触发稳定。
4. **review 会更新**：`star-pluck(mode=review)` 除返回内容外，还要更新“回顾次数/相关字段”（用于后续养成/推荐等）。
5. **登录分层**：启动即匿名登录；在关键点（示例：聊 2 轮、点亮星卡查看内容、付费）再强引导绑定账号。
6. **异步铸星（仅指“生成星卡/写入 stars”）**：
   - `chat-send` 完成后，后端异步用大模型判定“是否足够深刻”；只有判定为“需要成星”时才写入 `stars`（生成星卡）。
   - **Galaxy 底图星星恒亮**：是否成星不影响 Galaxy 的底图布局/悬臂形态；只影响“是否出现一张新的星卡（可被点亮/回顾）”。
   - 客户端在 `done` 后进入“正在成星…”等待态，并通过 **轮询** 感知 `stars` 新增来触发动效与插入星卡。
7. **星卡等级/演化（本期必须有）**：
   - “等级/演化”只影响星卡（Card）样式/稀有度/微反馈，不改变 Galaxy 底图的布局形态。
   - 后端需把等级/演化结果落库到 `stars`（字段方案待定：可用 `evolution_stage/insight_level` 或新增 `card_level` 等）。
8. **点亮规则（两条入口统一语义）**：
   - 路径 A（先点 Galaxy 再对话）：用户选中一个“区域”（多个底图星点索引）；对话完成后点亮该区域内的多个星点，并（若成星）生成 1 张星卡。
   - 路径 B（直接对话）：后端按规则选择多个底图星点索引；对话完成后点亮这些星点，并（若成星）生成 1 张星卡。
   - 点亮状态必须可持久化：推荐由 `stars.galaxy_star_indices` 推导已点亮集合（打开 App 重载 `stars` 即可恢复），避免“下次打开清空”。
9. **点击即出“灵感卡”（路径 A 的钩子，独立于成星）**：
   - 用户在 Galaxy 上的最后一次点击（区域/星点）都会弹出一张“灵感卡”，用于吸引用户继续对话。
   - 灵感卡内容来自公共灵感库（`star-pluck(mode=inspiration)` → `inspiration_source`），可包含不同类型（如 question/quote 等）。
   - 灵感卡 **不等于** 星卡：即使最终深度不足没有生成星卡（不写 `stars`），灵感卡也照常弹出与展示。

### 6.2 需要详细讨论（下阶段专门对齐）

1. **region/五大悬臂分配方案**：需要更细的“内容→region/arm→坐标/视觉”规则，避免改动后星图布局大幅漂移。
2. **坐标映射统一方案**：`[-400,400]` ↔ 渲染坐标/交互坐标 的确定算法与跨设备一致性（见下文“坐标系说明”）。
3. **轮询策略细则**：轮询频率/超时/去重规则（见下文“轮询说明”）。

---

## 7. 术语说明（避免误解）

### 7.1 坐标系说明（为什么要对齐、影响是什么）

后端 `stars.coord_x/coord_y/coord_z` 是“银河内部坐标”（一个稳定的世界坐标系），用于 **持久化** 星卡位置，让：
- 同一个用户在不同设备/重装后看到的星卡位置一致；
- 点击命中（hit-test）与动画落点一致（点哪颗就是哪颗）。

这不等于“改变种子策略”：
- 你的主银河骨架/底图仍可以继续走“后端生成 `profiles.galaxy_seed` → Swift 按种子生成五大悬臂/底图星点”的链路；
- `stars.coord_*` 只是“星卡点亮的落点”，后端当前也是用 `profiles.galaxy_seed + 用户历史星数` 来确定性生成（与对话内容无关），因此不会因为内容/深度去改变银河布局形态。

**你已拍板的关键约束（非常重要）**：
- **星卡不能“新增一颗星”**：成星=生成星卡（写入 `stars`），同时**点亮 Galaxy 底图里早已存在的一颗星点**。
- 换句话说：Galaxy 底图有一个由 `galaxy_seed` 决定的“候选星点集合”（很多颗，默认都不亮）；每次成星只是在其中选中一个“槽位（index）”点亮。

并且你进一步拍板：
- 点亮不止 1 颗星点：无论是“先点 Galaxy 再对话”（路径 A）还是“直接对话”（路径 B），一次对话完成后会点亮 **多个** 底图星点。
- 但一段对话最多生成 **1 张星卡**（若深度不足则可能 0 张）。

因此建议把“成星落点”定义为“底图星点索引集合”，而不是自由坐标：
- 后端在写 `stars` 时写入 `galaxy_star_indices: int[]`（该星卡对应的底图星点索引集合，建议至少包含 1 个 index）；
- 端侧以 `galaxy_star_indices` 点亮对应底图星点；并可用“集合中的第一个 index”作为该星卡的主锚点（用于命中/动画起落点）。
- `coord_x/y/z` 继续保留为渲染与兼容字段，但其来源必须来自底图星点集合（由 index 推导），而不是随意新算一个不在底图库的坐标点。

> 这样可以保证：不会出现“对话越多 → Galaxy 里凭空长出新星点”的体验；永远只是“点亮既有底图星点 + 出现一张新卡”。

Swift/Metal 的渲染坐标是“屏幕/视口坐标”（会随设备尺寸、缩放、相机参数变化）。因此必须有一层 **映射**：
- 把后端世界坐标（例如 `[-400,400]` 范围）映射到当前相机/屏幕下的渲染位置；
- 反过来把用户点击的屏幕位置反投影为世界坐标（用于点选/交互）。

如果不统一/不写清楚，会出现典型问题：
- 星星位置“飘”（不同屏幕比例下同一颗星偏移）；
- 点 A 触发 B（hit-test 与渲染不一致）；
- “文字→成星飞入银河”的动画落点不准。

当前建议（低风险，兼容历史数据）：
- **后端继续存世界坐标**（保持现有 `coord_*` 语义不变）；
- Swift 端固定一套相机/缩放规则，把 `coord_*` 映射到渲染空间；必要时做“不同设备同视觉密度”的适配。

### 7.2 轮询说明（为什么需要、怎么做体验最好）

由于你已拍板“异步铸星”（成星发生在 `chat-send` 返回 `done` 之后的后台流程），客户端需要一个机制知道：
“星卡什么时候真正写入 `stars` 了？”

本期选择：**轮询**（实现简单，不依赖 Realtime 配置）。

推荐做法（避免“拉全量 stars”过重）：
- 在 `done` 后记录一个 `pollStartAt`（本地时间即可）；
- 轮询查询条件尽量收敛为：`stars.chat_id = currentChatId` 且 `created_at >= pollStartAt - 5s`（给后端写入时间与时钟误差留余量）；
- 轮询间隔：前 10 秒 `1s` 一次，之后指数退避到 `2s/3s/5s`；总超时例如 `30s`；
- 一旦发现新 star：
  - 在当前对话 UI 的“最后一条消息后面”插入这张星卡；
  - 同步点亮 Galaxy 中对应的星卡星点（不改底图布局）。
