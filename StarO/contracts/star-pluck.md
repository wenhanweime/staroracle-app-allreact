# star-pluck 接口契约（摘星/回顾）

- 路径：`POST /functions/v1/star-pluck`
- 认证：`Authorization: Bearer <JWT>`（Supabase Auth）
- 传输：HTTP JSON
- 追踪：可选 `X-Trace-Id`（服务端回显）

请求头
- `Authorization: Bearer <JWT>`（必填）
- `Content-Type: application/json`（必填）
- `X-Trace-Id: <可选>`

请求体（JSON）
```
{
  "mode": "inspiration|review",
  "tag": "<可选：inspiration 用于抽取过滤；review 用于按标签回顾>",
  "before": "<可选，仅对 review 生效：ISO8601，回顾此时间点之前的最近一颗>"
}
```

成功响应（200 JSON）
- mode = `inspiration`：返回 `inspiration_source` 表中的一条灵感卡（可按 tag 过滤）
  - 用途（产品语义）：用于“点击 Galaxy 即出卡”的钩子；即使最终没有生成星卡（不写 `stars`），灵感卡也照常弹出与展示。
  - 重要：该灵感卡是“临时灵感卡（InspirationCard）”，不进入收藏/collection；用户若从该卡进入对话，则该 `chat_id` 在 `chat-send done` 后后台会生成/更新“资产星卡（stars 行）”，最低为 `insight_level=1（星辰）`，并可随“觉察/回顾”持续升级。
```
{
  "type": "inspiration",
  "content": {
    "id": "<uuid>",
    "content_type": "question|quote",
    "question": "……",
    "answer": "……",
    "tags": ["daily","mindful"],
    "created_at": "2025-12-11T01:40:29Z"
  },
  "trace_id": "3f6e..."
}
```
- mode = `review`：返回当前用户最近一颗 `stars` 记录
  - 说明：**仅“查看/打开”不计入回顾次数**；`review_count` 只会在用户触发明确动作时增加（例如点击“升级”按钮调用 `/functions/v1/star-evolve` 并传 `action=upgrade_button`，或在该星卡所属 `chat_id` 中继续对话由 `chat-send` 记为回顾）。
```
{
  "type": "review",
  "content": {
    "id": "<uuid>",
    "question": "……",
    "answer": "……",
    "summary": "……",
    "coord_x": 12.3,
    "coord_y": -4.5,
    "coord_z": 0.0,
    "galaxy_star_indices": [12, 98, 431],
    "review_count": 7,
    "primary_color_hex": "#FFD700",
    "haptic_pattern_id": "soft_pulse",
    "created_at": "2025-12-11T01:00:00Z"
  },
  "trace_id": "3f6e..."
}
```

错误码（PLxx，节选）
- `PL02 401 unauthorized`：缺少/无效 JWT
- `PL03 400/405 invalid argument`：参数非法 / 方法不支持
- `PL04 404 content not found`：无灵感卡/无历史星
- `PL05 429 rate limited`：命中限流（响应头含 `Retry-After`）
- `PL99 500 unknown`：未分类错误

cURL 示例
```
SUPABASE_URL=https://<project>.supabase.co
TOKEN=<supabase_jwt>

# 灵感
curl -sS \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"mode":"inspiration","tag":"mindful"}' \
  "$SUPABASE_URL/functions/v1/star-pluck"

# 回顾
curl -sS \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"mode":"review"}' \
  "$SUPABASE_URL/functions/v1/star-pluck"
```
