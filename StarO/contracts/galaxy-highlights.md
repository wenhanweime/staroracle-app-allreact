# galaxy-highlights 接口契约（点击 Galaxy 临时高亮，跨设备 1 天）

- 路径：`GET|POST /functions/v1/galaxy-highlights`
- 认证：`Authorization: Bearer <JWT>`（Supabase Auth）
- 传输：HTTP JSON
- 追踪：可选 `X-Trace-Id`（服务端回显）

用途（产品语义）
- 用户“纯点击 Galaxy（不进入对话）”时，也会产生高亮效果；这些高亮需要跨设备同步，但只保留最多 1 天。
- 该能力仅持久化“高亮集合”，不生成 `stars` 行，不进入收藏/collection。
- 一天内允许存在多条高亮记录（用户多次点击会累积多个高亮区域）。

POST 创建一条临时高亮

请求体（JSON）
```
{
  "galaxy_star_indices": [12, 98, 431]
}
```

成功响应（200 JSON）
```
{
  "ok": true,
  "highlight": {
    "id": "<uuid>",
    "galaxy_star_indices": [12, 98, 431],
    "created_at": "2025-12-15T01:00:00Z",
    "expires_at": "2025-12-16T01:00:00Z"
  },
  "trace_id": "3f6e..."
}
```

GET 拉取当前用户未过期的高亮列表

成功响应（200 JSON）
```
{
  "ok": true,
  "highlights": [
    {
      "id": "<uuid>",
      "galaxy_star_indices": [12, 98, 431],
      "created_at": "2025-12-15T01:00:00Z",
      "expires_at": "2025-12-16T01:00:00Z"
    }
  ],
  "trace_id": "3f6e..."
}
```

