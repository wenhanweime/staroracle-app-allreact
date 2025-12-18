# Swift 迁移待澄清（本仓增量）

**真值（SoT）**
- 迁移文档：`../staroracle-backend/docs/swift-migration/`
- 接口契约：`../staroracle-backend/docs/contracts/`

> 说明：这里只记录“本仓在实现/联调过程中新增发现，但后端 SoT 文档尚未覆盖或需要拍板”的事项。  
> 后端已在 SoT 文档写清楚的内容不要重复记录在这里，避免双真值。

## Open

- [ ] 点击银河星点打开星卡：若多个 `stars` 共享同一个 `galaxy_star_indices` 的 index（重叠点亮），端侧点击该星点应打开哪一张星卡？当前实现为“命中第一张”。
- [ ] 云端 messages 同步：本地发送消息的 id（`user-.../ai-...`）与服务端 `messages.id` / `done.message_id` 未对齐；若后续要实现“回源刷新后不重复 + 双向同步”，需要设计 messageId 映射或调整本地 id 策略。
- [ ] Auth SDK 选型：SoT 任务包含接入 `supabase-swift`；当前端侧先用 Auth REST + Keychain 打通邮箱登录，后续若要支持 Apple/Google（M1.5）建议再评估是否切回 `supabase-swift` 以减少 OAuth/PKCE 自研成本。

## Done

- [ ] （占位）在这里补充已澄清项
