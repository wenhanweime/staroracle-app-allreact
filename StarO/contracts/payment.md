# 支付与权益 API 契约（Payment & Entitlements)

- 路径前缀：`/functions/v1/*`
- 认证：`Authorization: Bearer <JWT>`（Supabase Auth）
- 说明：本期验证采用“客户端收据 + 服务端校验 + 服务端更新权益”的模式；生产接入 Apple Server API 时仅需替换校验实现。

## verify-receipt（校验收据并更新权益）
- 路径：`POST /functions/v1/verify-receipt`
- CORS：支持
- 请求头：
  - `Authorization: Bearer <JWT>`（必填）
  - `Content-Type: application/json`
- 请求体：
```
{
  "transaction_id": "<string>",
  "original_id": "<string>",
  "product_id": "<string>",
  "environment": "Production|Sandbox",
  "mock_verify": true       // 可选：开发期使用
}
```
- 响应（200 成功）：
```
{
  "verified": true,
  "subscription_id": "<uuid>",
  "expires_at": "2025-01-12T00:00:00Z|null",
  "is_premium": true,
  "trace_id": "..."
}
```
- 错误码：
  - `VR01 401 unauthorized`：缺少/无效 JWT
  - `VR02 400 invalid argument`：字段缺失或非法
  - `VR03 400 invalid transaction`：校验失败
  - `VR04 502 apple api error`：Apple 校验失败（保留位）
  - `VR99 500 unknown error`：未分类

## get-entitlements（查询当前用户权益）
- 路径：`GET /functions/v1/get-entitlements`
- CORS：支持
- 请求头：
  - `Authorization: Bearer <JWT>`（必填）
- 响应（200 成功）：
```
{
  "ok": true,
  "is_premium": false,
  "premium_expires_at": null,
  "trace_id": "..."
}
```
- 错误码：
  - `EN01 401 unauthorized`：缺少/无效 JWT
  - `EN02 405 method not allowed`：方法不被允许
  - `EN99 500 unknown/db error`：未分类

## 数据库结构（简要）
- `public.subscriptions`
  - `user_id`、`product_id`、`original_transaction_id`（唯一）、`expires_at`、`is_active`、`environment`
  - RLS：仅本人可查询
- `public.user_entitlements`
  - `user_id`（PK）、`is_premium`、`premium_expires_at`
  - 触发器：新用户自动建一行（默认非付费）
  - 函数：`refresh_user_entitlements(p_user_id uuid)` 用于根据订阅刷新权益

## 部署与配置（必要）
- 在 Supabase 项目（远端）设置 Edge Function Secrets：
  - `SUPABASE_SERVICE_ROLE_KEY`（用于服务端 upsert 订阅和刷新权益）
  - `SUPABASE_URL`、`SUPABASE_ANON_KEY`（通常已存在）
  - 生产接入 Apple Server API：
    - `APPLE_API_KEY_ID`（App Store Connect 中生成的 Key 的 Key ID）
    - `APPLE_ISSUER_ID`（App Store Connect 的 Issuer ID）
    - `APPLE_PRIVATE_KEY`（.p8 私钥内容；可直接粘贴 PEM，或使用 base64(PEM) 存储）
    - `APP_BUNDLE_ID`（应用 Bundle ID，用于 JWT 的 bid 声明）
    - 环境切换：请求体 `environment` = `Sandbox|Production` 自动选择域名
- 部署：`scripts/deploy-functions.sh verify-receipt`、`scripts/deploy-functions.sh get-entitlements`

可选（授权产品白名单）：
- `PREMIUM_PRODUCT_IDS`：逗号分隔的付费订阅商品 ID 列表（设置后仅这些商品会赋予 premium 权益；未设置则默认所有商品均视为可赋权）

## cURL 示例（Sandbox 开发）
```
SUPABASE_URL=https://<project>.supabase.co
TOKEN=<supabase_jwt>

# 1) verify-receipt（mock）
curl -sS \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "transaction_id":"sandbox_12345",
    "original_id":"orig_sandbox_12345",
    "product_id":"staroracle.premium.monthly",
    "environment":"Sandbox",
    "mock_verify":true
  }' \
  "$SUPABASE_URL/functions/v1/verify-receipt"

# 2) get-entitlements
curl -sS \
  -H "Authorization: Bearer $TOKEN" \
  "$SUPABASE_URL/functions/v1/get-entitlements"
```

## Swift 对接要点（简）
- 购买成功后，获取 Transaction 的 `originalID/transactionID/productID` 与 `environment`，调用 `verify-receipt`
- 启动/前台激活时，周期性调用 `get-entitlements` 刷新本地状态
- 后端返回 `is_premium=true` 则解锁付费功能；`premium_expires_at` 可用于显示到期时间

