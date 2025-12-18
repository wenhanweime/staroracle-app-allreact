# chat-send 接口契约（SSE）

- 路径：`POST /functions/v1/chat-send`
- 认证：`Authorization: Bearer <JWT>`（Supabase Auth）
- 传输：SSE（Server-Sent Events）流；客户端需设置 `Accept: text/event-stream`
- 幂等：可选 `X-Idempotency-Key`（或 body.idempotency_key），用于避免重复请求
- 追踪：可选 `X-Trace-Id`（服务端必回显；若未传则服务端生成）

与“成星/点亮”相关的重要约束（产品拍板）
- `chat-send` 的 SSE `done` 仅表示“本轮对话消息已保存并完成输出”；成星发生在 `done` 之后的后台流程（异步）。
- 成星=生成/升级星卡（写入/更新 `stars`）；**每个 `chat_id` 对应 1 张星卡，可持续升级**（不会生成多张）。
- Galaxy 底图星点集合由 `profiles.galaxy_seed` 决定并在端侧生成；成星不会新增星点，只会点亮既有底图星点。
- 推荐后端落库 `stars.galaxy_star_indices`（int[]）作为“该星卡点亮的底图星点索引集合”，用于端侧持久化恢复点亮状态。
  - 重要澄清：用户点击 Galaxy 弹出的“灵感卡”是临时卡（不写 `stars`，不进入收藏）。用户若从该卡进入对话，则该 `chat_id` 在 `chat-send done` 后后台会生成/更新“资产星卡（stars 行）”，最低为 `insight_level=1（星辰）`，并写入 `galaxy_star_indices` 作为点亮 SoT。
  - 纯点击 Galaxy（不进入对话）的“临时高亮（TapHighlight）”走 `galaxy-highlights` 接口跨设备同步，最多保留 1 天（不写 `stars`）。

等级/计数规则（本期实现）
- 星卡等级：`stars.insight_level`（SoT；1..5：星辰/新星/恒星/超新星/白矮星）
- 觉察计数：`stars.reflection_count`
  - 来源：`done` 后后台调用 LLM “审查”输出 `has_reflection`；若为 true 则 `reflection_count + 1`
  - 去重：服务端会将该次审查结果写入 `messages.annotations`（`reflection_audited/has_reflection`），避免重试导致重复计数
- 回顾计数：`stars.review_count`
  - 进入星卡并首次发言算回顾：端侧仅在“进入某张星卡后第一次发送消息”时带上 `review_session_id`；服务端据此去重并在 `done` 后后台 `review_count + 1`
  - 仅打开/查看星卡不算回顾：需由端侧明确动作触发（例如点击“升级”按钮调用 `/functions/v1/star-evolve` 并传 `action=upgrade_button`）
- 等级计算：`insight_level = min(5, 1 + reflection_count + review_count)`（只升不降）

请求头
- `Authorization: Bearer <JWT>`（必填）
- `Accept: text/event-stream`（必填）
- `Content-Type: application/json`（必填）
- `X-Trace-Id: <可选>`
- `X-Idempotency-Key: <可选>`

请求体（JSON）
```
{
  "chat_id": "<uuid，可选：自由对话可省略，由后端决定当前 chat；星卡内对话必须提供>",
  "message": "用户发送的文本",
  "review_session_id": "<可选：进入某张星卡后首次发言时生成的 session id；用于把“进入并产生一次对话”计为一次回顾；同一 session 只会 +1>",
  "galaxy_star_indices": [12, 98, 431], // 可选：本轮对话若成星，则使用该索引集合点亮（通常来自“点击 Galaxy 的高亮区域”）
  "config_override": { 
    "temperature": 0.6,   // 可选：本轮调用上游模型时生效
    "mask_id": "<uuid>"   // 可选：临时覆盖 Mask（优先级高于 chats.mask_id）
  },
  "idempotency_key": "<可选，等同于请求头>"
}
```

SSE 事件（按序）
- `delta` 事件（多次）：`{"text":"<追加文本>", "trace_id":"..."}`
- `done` 事件（一次）：`{"message_id":"<uuid|null>", "chat_id":"<uuid>", "trace_id":"..."}`
- `error` 事件（异常时一次）：`{"code":"CHxx", "message":"...", "trace_id":"...|''|<缺失>"}`

错误码（CHxx，节选）
- `CH01 401 unauthorized`：缺少/无效 JWT
- `CH02 400 invalid argument`：缺少/空 `message`；或（星卡内对话）缺少/非法 `chat_id`
- `CH03 429 rate limited`：命中限流（响应头含 `Retry-After`）
- `CH04 500 context build failed`：历史读取/拼接或 DB 写入失败
- `CH05 504 upstream timeout`：上游模型超时（可按环境配置）
- `CH06 502 upstream error`：上游模型错误
- `CH07 409 idempotency conflict`：同一个幂等键但请求体不同
- `CH08 404 chat not found`：会话不存在或 RLS 限制
- `CH99 500 unknown`：未分类错误

幂等语义
- 同一 `X-Idempotency-Key` + 相同 body 再次请求，会被短路为 `done` 事件并返回第一次的 `message_id`
- 注意：`done` 会回传服务端最终使用的 `chat_id`；自由对话场景端侧应以该 `chat_id` 作为当前会话真值
- 同一键不同 body → 409 `CH07`

cURL 示例
```
SUPABASE_URL=https://<project>.supabase.co
TOKEN=<supabase_jwt>
KEY=$(uuidgen)

curl -N \
  -H "Authorization: Bearer $TOKEN" \
  -H "Accept: text/event-stream" \
  -H "Content-Type: application/json" \
  -H "X-Idempotency-Key: $KEY" \
  -d '{
    "chat_id": "b4d7d9f2-1a2b-4450-9ad5-7c0b5e00f111",
    "message": "我最近总是很焦虑，怎么办？"
  }' \
  "$SUPABASE_URL/functions/v1/chat-send"
```

返回示例（片段）
```
event: delta
data: {"text":"先说结论：焦虑不是敌人……","trace_id":"3f6e..."}

event: delta
data: {"text":" 先关注呼吸，再聚焦最重要的一件事。","trace_id":"3f6e..."}

event: done
data: {"message_id":"5c0b...","trace_id":"3f6e..."}
```

注意
- SSE 客户端需逐行解析 `event:` 和 `data:`；`data:` 为 JSON 字符串
- 限流返回 429；请读取 `Retry-After` 头并指数退避
- 追踪与排障：服务端会输出结构化日志，包含 `duration_ms/sse_first_token_ms/tokens_in/out` 与 `trace_id`
- Mask：若提供 `config_override.mask_id`，本轮对话即时生效；长期绑定请更新 `chats.mask_id`。上下文顺序为：`system(基础)+mask.system_prompt`→`memory_prompt`→`历史(按token预算截断)`→`当前输入`。
