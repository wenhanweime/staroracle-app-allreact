# chat-list 接口契约（历史对话列表）

- 路径：`GET /functions/v1/chat-list`
- 认证：`Authorization: Bearer <JWT>`（Supabase Auth）
- 传输：HTTP JSON
- 追踪：可选 `X-Trace-Id`（服务端回显）

用途（产品语义）
- 侧边栏展示“历史对话列表”（自由对话的分段 chat 需要可见）。
- 注意：对话框内“不保留历史对话痕迹”靠 `FREE_CHAT_IDLE_SEC` 触发新 `chat_id` 实现；该接口只负责列出历史 chat 容器。

查询参数（Query）
- `limit`：可选，默认 `30`，最大 `100`
- `before`：可选，ISO8601；返回 `updated_at <= before` 的分页（按 `updated_at desc`）
- `kind`：可选，`free|star`

成功响应（200 JSON）
```
{
  "ok": true,
  "chats": [
    {
      "id": "<uuid>",
      "title": "……",
      "created_at": "2025-12-15T01:00:00Z",
      "updated_at": "2025-12-15T01:08:00Z",
      "kind": "free"
    }
  ],
  "trace_id": "..."
}
```

