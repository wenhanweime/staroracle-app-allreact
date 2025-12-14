# chat-send 接口契约（SSE）

- 路径：`POST /functions/v1/chat-send`
- 认证：`Authorization: Bearer <JWT>`（Supabase Auth）
- 传输：SSE（Server-Sent Events）流；客户端需设置 `Accept: text/event-stream`
- 幂等：可选 `X-Idempotency-Key`（或 body.idempotency_key），用于避免重复请求
- 追踪：可选 `X-Trace-Id`（服务端尽力回显；**部分早期错误分支可能缺失**；若未传则服务端在可生成的分支生成 `trace_id`）

与“成星/点亮”相关的重要约束（产品拍板）
- `chat-send` 的 SSE `done` 仅表示“本轮对话消息已保存并完成输出”；成星发生在 `done` 之后的后台流程（异步）。
- 成星=生成星卡（写入 `stars`）；每段对话最多生成 1 张星卡（深度不足时可能 0 张）。
- Galaxy 底图星点集合由 `profiles.galaxy_seed` 决定并在端侧生成；成星不会新增星点，只会点亮既有底图星点。
- 推荐后端落库 `stars.galaxy_star_indices`（int[]）作为“该星卡点亮的底图星点索引集合”，用于端侧持久化恢复点亮状态。

请求头
- `Authorization: Bearer <JWT>`（必填）
- `Accept: text/event-stream`（必填）
- `Content-Type: application/json`（必填）
- `X-Trace-Id: <可选>`
- `X-Idempotency-Key: <可选>`

请求体（JSON）
```
{
  "chat_id": "<uuid>",
  "message": "用户发送的文本",
  "config_override": { 
    "temperature": 0.6,   // 预留：当前后端未使用（传了也不会改变回答风格）
    "mask_id": "<uuid>"   // 可选：临时覆盖 Mask（优先级高于 chats.mask_id）
  },
  "idempotency_key": "<可选，等同于请求头>"
}
```

SSE 事件（按序）
- `delta` 事件（多次）：`{"text":"<追加文本>", "trace_id":"..."}`
- `done` 事件（一次）：`{"message_id":"<uuid|null>", "trace_id":"..."}`
- `error` 事件（异常时一次）：`{"code":"CHxx", "message":"...", "trace_id":"...|''|<缺失>"}`

错误码（CHxx，节选）
- `CH01 401 unauthorized`：缺少/无效 JWT
- `CH02 400 invalid argument`：缺少 `chat_id` 或 `message`
- `CH03 429 rate limited`：命中限流（响应头含 `Retry-After`）
- `CH04 500 context build failed`：历史读取/拼接或 DB 写入失败
- `CH05 504 upstream timeout`：上游模型超时（可按环境配置）
- `CH06 502 upstream error`：上游模型错误
- `CH07 409 idempotency conflict`：同一个幂等键但请求体不同
- `CH08 404 chat not found`：会话不存在或 RLS 限制
- `CH99 500 unknown`：未分类错误

> 现状说明：`trace_id/X-Trace-Id` 在 `CH01/CH02/CH03/CH04` 等分支可能为空或缺失；客户端需容忍（迁移计划中已将“trace_id 全链路一致”列为后端必改项）。

幂等语义
- 同一 `X-Idempotency-Key` + 相同 body 再次请求，会被短路为 `done` 事件并返回第一次的 `message_id`
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
