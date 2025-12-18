# 交接文档：Swift 迁移（本仓增量记录）

## 背景

本仓（`staroracle-app_allreact`）里曾同时存在两套同名迁移文档：
- `StarO/swift-migration/*`（Swift 迁移章程/计划/任务）
- `docs/swift-migration/*`（React/Zustand → Swift 映射草稿）

同时后端仓库（`/Users/pot/Documents/staroracle-backend/`）也维护了一份更完整、且会持续更新的迁移文档与接口契约：
- 迁移文档（SoT）：`/Users/pot/Documents/staroracle-backend/docs/swift-migration/`
- 接口契约（SoT）：`/Users/pot/Documents/staroracle-backend/docs/contracts/`

多份同名文档导致“真值漂移”，团队很难判断当前迁移计划/任务的真实进度。

## 本次对话的目标

1) 以**后端文档为唯一真值（SoT）**；本仓不再保留同名的 `swift-migration` 文档目录。  
2) 本仓只保留**迁移进度日志**与**待澄清增量**，用于记录“本仓实际推进情况/变化”，而不是再维护完整计划。

## 已完成事项（本次会话落地）

### 1) 备份旧文档

已在仓库根目录创建 `trash/`，并将以下目录备份（带时间戳）：
- `trash/docs-swift-migration_YYYYMMDD_HHMMSS/`（原 `docs/swift-migration/` 备份）
- `trash/StarO-swift-migration_YYYYMMDD_HHMMSS/`（原 `StarO/swift-migration/` 备份）

> 备注：本次实际备份时间戳为 `20251217_031931`。

### 2) 移除同名目录（避免双真值）

已删除：
- `docs/swift-migration/`
- `StarO/swift-migration/`

### 3) 新建本仓增量记录入口

新增目录 `StarO/migration/`：
- `StarO/migration/log.md`：迁移日志（只记录本仓发生了什么/什么时候）
- `StarO/migration/clarifications.md`：待澄清（只记录 SoT 未覆盖的增量问题）
- `StarO/migration/handoff.md`：本交接文档

并在 `.gitignore` 追加忽略：
- `trash/`（本地备份不入库）

## 关键决策（给下一位工程师的“唯一真值”规则）

### 真值来源

- 迁移计划/任务/规格的唯一真值（SoT）：`/Users/pot/Documents/staroracle-backend/docs/swift-migration/`
- API 契约唯一真值（SoT）：`/Users/pot/Documents/staroracle-backend/docs/contracts/`

本仓 `StarO/migration/*` **不是**完整计划，只做增量记录与追踪。

## 当前主线任务是什么（迁移的真实缺口概览）

本次会话主要做了“文档真值统一与清理”，没有继续推进功能编码。

但在会话中已确认当前 Swift 端（本仓 `StarO/StarO/*`）相对 SoT 的“主线缺口”仍包括：
- `chat-send`：`X-Idempotency-Key` / `X-Trace-Id` 注入与一致性（SoT 强烈建议）
- `review_session_id` / `galaxy_star_indices` 的真实串联规则（仅首条消息携带；星卡续聊首条携带 review_session_id）
- `done` 后的“成星/升级提示”：按 `chat_id` 轮询/订阅 `stars` 变化，并在对话 UI 给出“已生成/已升级”入口
- `star-pluck`（inspiration/review）、`get-energy`、`star-evolve`（升级/能量）
- 云端 messages/stars 同步（ConversationStore 仍以本地持久化为主）

上述以 `staroracle-backend/docs/swift-migration/` 的 `tasks.md` 与 `clarifications.md` 为执行顺序与验收口径。

## 其它关键信息 / 注意事项

- 本次会话曾扫描到 `gAAA` 字符串，但后续已按产品指示“忽略该问题”。当前仓库里命中的 `gAAA` 来自构建产物/依赖缓存（如 `.vite/`、`ios/App/App.xcarchive/`），不是迁移主线阻塞项。
- `trash/` 已加入 `.gitignore`，用于本地备份；不要提交到仓库。

## 下一步建议（行动清单）
首先根据当前的staro项目文件夹的代码，和后端的两份文档 包括后端代码和swift迁移文档，评估当前项目的状态，并看下swiftmigration里面的plan tasks是否完善合理。
1) 以 SoT 为准重新对齐迁移推进节奏：打开 `/Users/pot/Documents/staroracle-backend/docs/swift-migration/tasks.md`，按模块逐项推进。
2) 在本仓每完成一个关键节点，在 `StarO/migration/log.md` 追加记录；遇到 SoT 未覆盖的坑，写入 `StarO/migration/clarifications.md`。
3) 若需要把 SoT 变更同步给其他工程师：优先改后端仓库文档；本仓只记“执行结果/差异”。

