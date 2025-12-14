# StarOracle Swift 迁移章程 (Constitution)

> **版本**：1.3  
> **日期**：2025-12-13  
> **状态**：执行中（Phone 暂缓；Apple 待开通）

---

## 1. 项目概述

将 StarOracle iOS 客户端从"本地直连 OpenAI"架构迁移到"Supabase 统一后端"架构，实现：

- **用户认证**：通过 Supabase Auth 管理用户身份
- **对话服务**：通过 `chat-send` Edge Function 进行 SSE 流式对话
- **铸星服务**：由后端在 `chat-send` 完成后异步铸星（并写入 `stars`）；`star-cast` 仍保留为独立能力（如坐标点击铸星/调试/补偿）
- **摘星服务**：通过 `star-pluck` Edge Function 获取灵感卡
- **数据同步**：chats/messages/stars 存储在 Supabase PostgreSQL

---

## 2. 项目目标

### 2.1 必须实现 (Must Have)

| ID   | 目标               | 验收标准                                 |
| ---- | ------------------ | ---------------------------------------- |
| M1   | Supabase Auth 集成 | 用户可注册/登录，Token 自动刷新          |
| M1.5 | 多登录方式支持     | Apple/Google/邮箱三种登录方式可用（Phone 暂缓） |
| M2   | chat-send 对接     | SSE 流式对话正常，消息同步到云端         |
| M3   | star-cast 对接     | 对话结束后可铸星，星星数据入库           |
| M4   | star-pluck 对接    | 点击星星可获取灵感卡                     |
| M5   | 数据同步           | 本地/云端数据一致，支持离线缓存          |
| M6   | App Store 付费     | 支持内购，收据验证，订阅状态管理         |

### 2.2 可选实现 (Nice to Have)

| ID  | 目标       | 说明                  |
| --- | ---------- | --------------------- |
| N1  | Mask 支持  | 用户自定义角色/提示词 |
| N2  | 多设备同步 | 换设备后数据自动同步  |
| N3  | 离线模式   | 无网络时可查看历史    |

---

## 3. 技术决策

### 3.1 架构模式

```
┌─────────────────────────────────────────────────────────┐
│                    StarOracle iOS                        │
├─────────────────────────────────────────────────────────┤
│  SupabaseManager (Auth + Client)                        │
│  ├── AuthService (多登录方式)                            │
│  │   ├── Sign in with Apple                             │
│  │   ├── Sign in with Google                            │
│  │   ├── Email + Password                               │
│  │   └── Phone + OTP（暂缓）                              │
│  ├── ChatService (chat-send SSE)                        │
│  ├── StarService (star-pluck / star-cast(可选))          │
│  ├── SyncService (chats/messages/stars CRUD)            │
│  └── PaymentService (StoreKit 2 + 收据验证)              │
├─────────────────────────────────────────────────────────┤
│  现有组件（复用）                                         │
│  ├── StreamingClient (SSE 解析) ⚙️ 需适配后端 SSE 事件格式 │
│  ├── NativeChatBridge (UI 桥接) ⚙️ 需适配                │
│  ├── ConversationStore (会话管理) ⚙️ 需改为云端          │
│  └── Galaxy/* (星系渲染) ✅ 无需改动                      │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│                 Supabase Backend                         │
├─────────────────────────────────────────────────────────┤
│  Edge Functions: chat-send / star-cast / star-pluck     │
│  Edge Functions: verify-receipt / get-entitlements      │
│  Database: profiles / chats / messages / stars / masks  │
│  Database: inspiration_source / idempotency_keys        │
│  Database: rate_limit_events / subscriptions / user_entitlements │
│  Auth: JWT Token + Apple/Google/Email（Phone 暂缓）       │
└─────────────────────────────────────────────────────────┘
```

### 3.2 依赖选型

| 依赖                                                           | 版本 | 用途                                 |
| -------------------------------------------------------------- | ---- | ------------------------------------ |
| [supabase-swift](https://github.com/supabase/supabase-swift)   | 2.x  | Auth + Realtime + PostgREST          |
| [GoogleSignIn-iOS](https://github.com/google/GoogleSignIn-iOS) | 7.x  | Sign in with Google                  |
| AuthenticationServices                                         | 系统 | Sign in with Apple                   |
| StoreKit 2                                                     | 系统 | App Store 内购                       |
| 现有 URLSession                                                | -    | SSE 流式请求（复用 StreamingClient） |

### 3.3 关键设计决策

1. **后端契约为准**：以 **后端仓库** `docs/contracts/*` 为接口真理源；本仓 `StarO/contracts/*` 为同步副本（用于 Swift 文档引用与联调）
2. **SSE 事件格式**：`chat-send` 输出 `event: delta/done/error`，Swift 需解析 `event:` + `data:`（非 OpenAI 原始 SSE）
3. **TraceId 全链路**：所有成功/失败响应必须携带 `trace_id`（与 `X-Trace-Id` 回显一致；未传则服务端生成），用于排障与客服闭环
4. **Token 计数写入**：后端写入真实/可用的 `messages.token_count`，保证“长对话记忆/摘要/截断”稳定生效
5. **温度可调**：支持 `config_override.temperature`（用于不同场景/Mask 的回答稳定度与发散度控制；需要后端实现）
6. **异步铸星**：对话 `done` 后由后端异步生成星星写入 `stars`；客户端以 Realtime/轮询感知新增并播放“文字转星”动效
7. **登录体验分层**：启动即匿名登录保持无门槛；在关键点（如聊到第 N 轮/查看星卡内容/付费等）再引导绑定 Apple/Google/邮箱
8. **渐进式迁移**：保留直连 OpenAI 的入口，支持灰度与回滚
9. **本地缓存策略**：云端为真相源，本地仅做缓存/离线展示（冲突策略需单独定义）

---

## 4. 项目约束

### 4.1 技术约束

- **最低 iOS 版本**：iOS 17.0（当前工程 Target）
- **Swift 版本**：5.9+
- **依赖管理**：Swift Package Manager

### 4.2 时间约束

- **预计工期**：3-5 个工作日
- **里程碑**：Auth → Chat → Stars → Sync

### 4.3 兼容性约束

- 迁移期间保留直连 OpenAI 的入口，便于调试
- 现有星系渲染、UI 组件不做改动
- **星卡等级/图案（本期）**：等级与图案主要影响“星卡（Card）样式”，不影响 Galaxy 内星星形态与位置（后续如变更需保留兼容扩展位）

---

## 5. 风险与缓解

| 风险                    | 影响 | 缓解措施                     |
| ----------------------- | ---- | ---------------------------- |
| Supabase SDK 兼容性问题 | 高   | 先做最小化集成验证           |
| SSE 格式差异            | 高   | 以契约为准：解析 `event: delta/done/error` + `data: JSON`（见 `StarO/contracts/chat-send.md`） |
| Token 过期处理          | 中   | 使用 SDK 内置 Token 刷新     |
| 限流/重试导致重复发送   | 中   | 使用 `X-Idempotency-Key` 幂等键；命中 429 读取 `Retry-After` 并退避 |
| 网络不稳定              | 低   | 本地缓存 + 重试机制          |

---

## 6. 相关文档

- [后端 API 契约 - chat-send](../contracts/chat-send.md)
- [后端 API 契约 - star-cast](../contracts/star-cast.md)
- [后端 API 契约 - star-pluck](../contracts/star-pluck.md)
- [后端 API 契约 - payment](../contracts/payment.md)
- [后端 API 契约 - mask](../contracts/mask.md)
- [Swift 迁移计划](./plan_spec.md)：详细改造步骤
- [Swift 迁移任务](./tasks.md)：任务拆解与进度

---

## 7. 审批

| 角色       | 姓名 | 状态   |
| ---------- | ---- | ------ |
| 产品负责人 | -    | 待审核 |
| 技术负责人 | -    | 待审核 |

---

## 8. 跨仓协同规则（强制）

> 目的：避免“前端改着改着发现后端缺东西，但没人记/记在聊天里丢了”；也避免“后端改了契约，前端不知道导致联调炸裂”。

1. **发现对方依赖必须落文档**：在本仓开发过程中，只要发现需要后端/前端配合的改动，必须在**对方仓库**的 `constitution/plan_spec/tasks` 中登记（至少 tasks），并在本仓 `tasks.md` 留交叉引用；若当下无法直接修改对方仓库（权限/不在当前工作区），至少先在本仓建任务并标记“待同步到对方仓库”。
2. **接口/契约变更双向同步**：
   - 后端真实实现（`supabase/functions/*` + 后端契约）为最终 SoT；
   - 本仓 `StarO/contracts/*` 为同步镜像（在本仓内优先级最高，避免散落文档互相打架）；
   - 任一方改动契约/实现，必须同步更新另一份，并在两边任务里记录“变更原因/影响/兼容策略”。
3. **破坏性变更先拍板再落地**：涉及接口字段/事件格式/DB 字段的破坏性变更，先在两边 `plan_spec.md` 写清楚影响与迁移路径，再开始编码。
4. **任务命名约定**：本仓 `tasks.md` 中需要后端配合的任务，统一用 `T-*-BE-*` 标注；后端仓库 `docs/tasks.md` 中对应任务需注明来源（引用本仓任务 ID）。
