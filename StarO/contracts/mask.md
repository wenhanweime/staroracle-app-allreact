# Mask 契约（服务端托管）

- 目标：以服务端托管的 Mask（人格/场景预设）增强对话一致性，允许按会话或临时覆盖切换。
- 表结构：`public.masks`（RLS：仅本人可见）
  - `id uuid`：主键
  - `user_id uuid`：= `auth.users.id`
  - `name text`：名称
  - `system_prompt text`：附加到基础 system 的提示词
  - `model_config jsonb`：可选模型参数（如温度、top_p、模型别名）
  - `created_at timestamptz`
- 关联：`public.chats.mask_id`（可空）

## chat-send 与 Mask 的关系

- chat-send 会按如下优先级选择 Mask：
  1) 请求体 `config_override.mask_id`
  2) `chats.mask_id`
  3) 无 Mask（仅基础 system）

- 上下文构建顺序：
  - `system(基础)` + `mask.system_prompt` → `memory_prompt` → `最近历史（按 token 预算截断）` → `当前输入`

- 请求体（节选）：
```
{
  "chat_id": "<uuid>",
  "message": "……",
  "config_override": {
    "mask_id": "<uuid>"   // 可选：临时覆盖当前对话使用的 Mask
  }
}
```

- 行为：
  - 若覆盖提供了 Mask，当前轮次即时生效，不修改 `chats.mask_id`；
  - 若要长期绑定某个会话与 Mask，请更新 `chats.mask_id`。

## API 与数据

- 创建 Mask（REST 示例）：
```
POST /rest/v1/masks
Authorization: Bearer <JWT>
apikey: <ANON>
Content-Type: application/json

{
  "user_id": "<USER_ID>",
  "name": "更聚焦情绪反思",
  "system_prompt": "你擅长以情绪命名法帮助用户识别与表达情绪。回答要简洁、具体、有操作性。",
  "model_config": { "temperature": 0.3 }
}
```

- 绑定会话：
```
PATCH /rest/v1/chats?id=eq.<CHAT_ID>
Authorization: Bearer <JWT>
apikey: <ANON>
Content-Type: application/json

{ "mask_id": "<MASK_ID>" }
```

- 临时覆盖（chat-send 请求体）：见上节 `config_override.mask_id`。

## 兼容与扩展
- 未设置 Mask 时行为与既有版本一致。
- `model_config` 当前未在 Edge 内部强制使用，后续可扩展为：
  - 覆盖对话模型/温度等参数；
  - 仅当字段存在时生效，未设置保持环境默认。

