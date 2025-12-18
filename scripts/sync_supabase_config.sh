#!/usr/bin/env bash
set -euo pipefail

ENV_FILE_PATH="${1:-../staroracle-backend/.env.remote}"
OUTPUT_PLIST_PATH="${2:-StarO/StarO/SupabaseConfig.plist}"

if [[ ! -f "$ENV_FILE_PATH" ]]; then
  echo "未找到 env 文件：$ENV_FILE_PATH" >&2
  echo "用法：bash scripts/sync_supabase_config.sh /path/to/staroracle-backend/.env.remote" >&2
  exit 1
fi

python3 - <<'PY' "$ENV_FILE_PATH" "$OUTPUT_PLIST_PATH"
import plistlib
import sys
from pathlib import Path

env_path = Path(sys.argv[1]).expanduser().resolve()
out_path = Path(sys.argv[2]).expanduser().resolve()

def parse_env(path: Path) -> dict:
  result = {}
  for raw in path.read_text(encoding="utf-8").splitlines():
    line = raw.strip()
    if not line or line.startswith("#"):
      continue
    if "=" not in line:
      continue
    key, value = line.split("=", 1)
    key = key.strip()
    value = value.strip()
    if not key:
      continue
    if value.startswith('"') and value.endswith('"') and len(value) >= 2:
      value = value[1:-1]
    if value.startswith("'") and value.endswith("'") and len(value) >= 2:
      value = value[1:-1]
    result[key] = value
  return result

env = parse_env(env_path)

supabase_url = env.get("SUPABASE_URL") or env.get("VITE_SUPABASE_URL")
token = (
  env.get("SUPABASE_JWT")
  or env.get("SUPABASE_TOKEN")
  or env.get("TOKEN")
  or env.get("Personal_Access_Token")
  or env.get("VITE_SUPABASE_JWT")
)
anon_key = env.get("SUPABASE_ANON_KEY")

if not supabase_url:
  raise SystemExit("缺少 SUPABASE_URL")

payload = {"SUPABASE_URL": supabase_url}
if anon_key:
  payload["SUPABASE_ANON_KEY"] = anon_key
if token:
  payload["SUPABASE_JWT"] = token

out_path.parent.mkdir(parents=True, exist_ok=True)
with out_path.open("wb") as f:
  plistlib.dump(payload, f, fmt=plistlib.FMT_XML, sort_keys=True)

print(f"已生成：{out_path}（已写入 SUPABASE_URL{', SUPABASE_ANON_KEY' if anon_key else ''}{', SUPABASE_JWT' if token else ''}）")
PY

