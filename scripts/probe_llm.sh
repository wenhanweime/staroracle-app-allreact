#!/usr/bin/env bash
set -euo pipefail

PLIST="StarO/StarO/AIConfigurationDefaults.plist"
if [[ ! -f "$PLIST" ]]; then
  echo "找不到 $PLIST" >&2
  exit 1
fi

# 读取配置（不在控制台回显敏感值）
API_KEY=$(/usr/libexec/PlistBuddy -c 'Print :APIKey' "$PLIST" 2>/dev/null || true)
ENDPOINT=$(/usr/libexec/PlistBuddy -c 'Print :Endpoint' "$PLIST" 2>/dev/null || true)
MODEL=$(/usr/libexec/PlistBuddy -c 'Print :Model' "$PLIST" 2>/dev/null || true)

if [[ -z "${API_KEY}" || -z "${ENDPOINT}" || -z "${MODEL}" ]]; then
  echo "从 plist 读取API配置失败，请检查 Provider/APIKey/Endpoint/Model" >&2
  exit 2
fi

echo "🔎 正在测试服务可用性（非流式）" >&2
echo "  - Endpoint: ${ENDPOINT}" >&2
echo "  - Model: ${MODEL}" >&2
echo "  - Key 前缀: ${API_KEY:0:6}**** (len=${#API_KEY})" >&2

payload=$(cat <<JSON
{
  "model": "${MODEL}",
  "messages": [
    {"role":"system","content":"你是星瑜,请用中文简短回复"},
    {"role":"user","content":"你好,这是一条健康检查,请只回复: 测试成功"}
  ],
  "temperature": 0.2,
  "max_tokens": 32,
  "stream": false
}
JSON
)

echo "-- 请求头/状态 --" >&2
status_and_headers=$(mktemp)
body=$(mktemp)

curl -sS \
  -D "$status_and_headers" \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Content-Type: application/json" \
  -X POST "$ENDPOINT" \
  --data "$payload" \
  --output "$body" || true

sed -n '1,40p' "$status_and_headers" >&2 || true
echo "-- 响应体(前500字节) --" >&2
head -c 500 "$body" | sed 's/\x1b\[[0-9;]*m//g' || true
echo >&2

echo "\n-- 解析JSON摘要 --" >&2
if command -v jq >/dev/null 2>&1; then
  (jq '{status: .status, head: .choices[0].message.content}' "$body" 2>/dev/null || true) >&2
fi

echo "\n✅ 完成非流式探测" >&2

echo "\n🔎 正在测试服务（尝试流式）" >&2
payload_stream=$(cat <<JSON
{
  "model": "${MODEL}",
  "messages": [
    {"role":"system","content":"你是星瑜,请用中文简短回复"},
    {"role":"user","content":"请逐字输出: 星瑜可用"}
  ],
  "temperature": 0.2,
  "max_tokens": 32,
  "stream": true
}
JSON
)

curl -sS \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Content-Type: application/json" \
  -X POST "$ENDPOINT" \
  --data "$payload_stream" \
  --no-buffer | sed -n '1,40p' || true

echo >&2
echo "✅ 完成流式探测(截断到前40行)" >&2

