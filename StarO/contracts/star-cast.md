# star-cast 接口契约（铸星）

- 路径：`POST /functions/v1/star-cast`
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
  "chat_id": "<uuid>",
  "x": 12.34,      // 可选：点击坐标 X（存在则不重算）
  "y": -56.78,     // 可选：点击坐标 Y（存在则不重算）
  "region": "emotion|relation|growth" // 可选：星臂分配提示
}
```

成功响应（200 JSON）
```
{
  "ok": true,
  "coord_x": 12.34,
  "coord_y": -56.78,
  "coord_z": 0.0,
  "trace_id": "3f6e..."
}
```

错误码（STxx，节选）
- `ST03 401 unauthorized`：缺少/无效 JWT
- `ST01 404 missing chat`：会话不存在或 RLS 限制
- `ST05 502 upstream error`：上游模型分析失败
- `ST06 429 rate limited`：命中限流（响应头含 `Retry-After`）
- `ST99 500 unknown/db error`：未分类或数据库错误

坐标规则
- `x/y` 存在：后端不重算坐标，直接入库
- `x/y` 缺失：后端读取 `profiles.galaxy_seed` 与用户历史星数自动计算 `(x,y[,z])`

重要约束（产品拍板）
- 成星=生成星卡（写入 `stars`），同时点亮 **Galaxy 底图已存在的星点**；不会“新增一颗新星点”。
- 建议后端落库 `galaxy_star_indices`（int[]，底图星点索引集合）作为最终真值，以确保端侧能稳定点亮同一批底图星点（避免浮点误差/算法不一致）。每段对话最多 1 张星卡，但可点亮多颗底图星点。

星卡字段（写入 `stars` 表，供端侧渲染/展示）
- 最小结构（工程侧保证）：`question`、`summary`、`primary_color_hex?`、`tags?`
- 视觉/感官：`coord_x/coord_y/coord_z`、`haptic_pattern_id`
- 其它字段：`answer/primary_emotion/star_arm_assignment/evolution_*` 等为可选扩展

cURL 示例
```
SUPABASE_URL=https://<project>.supabase.co
TOKEN=<supabase_jwt>

# 自动坐标（结构化最小 schema，避免“未解析”）
curl -sS \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"chat_id":"b4d7d9f2-1a2b-4450-9ad5-7c0b5e00f111"}' \
  "$SUPABASE_URL/functions/v1/star-cast"

# 点击坐标
curl -sS \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"chat_id":"b4d7d9f2-1a2b-4450-9ad5-7c0b5e00f111","x":12.3,"y":-4.5,"region":"emotion"}' \
  "$SUPABASE_URL/functions/v1/star-cast"
```
