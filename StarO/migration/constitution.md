# Swift 迁移章程（本仓）

> 目标：让本仓（`staroracle-app_allreact`）在 Swift 迁移过程中始终保持“单一真值 + 可追溯 + 可协作”。

## 真值（SoT）

- 迁移文档（唯一真值）：`/Users/pot/Documents/staroracle-backend/docs/swift-migration/`
- 接口契约（唯一真值）：`/Users/pot/Documents/staroracle-backend/docs/contracts/`
- 本仓 `StarO/migration/*`：只记录“本仓实际做了什么/发现了什么”，**不维护完整计划/规格**。

## 记录与提交（强制）

### 1) 每次改动必须写迁移日志

- 每完成一个可交付改动（功能/修复/对齐契约），必须在 `StarO/migration/log.md` 追加记录。
- 日志要求尽可能详细，至少包含：
  - 改动目的（对应 SoT 的哪一条/哪个 endpoint/哪个验收点）
  - 关键实现点（涉及哪些模块/文件）
  - 风险与取舍（如有）
  - 自测方式（编译/运行路径/关键交互）

### 2) 每次改动必须有对应 git 提交

- 每个改动必须有对应的 git commit（不要把多个不相关改动揉进一个提交）。
- commit message 要能和 `StarO/migration/log.md` 的日志条目一一对应（读 commit 就知道改了什么，读日志能找到对应提交）。
- 推荐格式（不强制，但建议统一）：
  - `feat(staro): ...`
  - `fix(staro): ...`
  - `chore(migration): ...`

### 3) 用户输入记录必须标注已读/完成

- 用户输入会写入 `StarO/migration/userpromptrecord.md`，并以 `# <序号>` 分段（如 `# 2`）。
- 从现在起：**用户在对话中的每一次输入**（新增需求/问题/补充说明/修正）都必须追加到该文件，保持可追溯。
- 每次开始处理某条输入时，必须在对应标题上补充 `（已读 YYYY-MM-DD HH:MM）`。
- 若该条输入包含子任务列表，必须改为任务清单 `- [ ]`，并在对应改动完成且已提交后将该子任务标记为 `- [x]`，保持“输入 → 实现 → 提交 → 日志”可追溯。

## 禁止入库（强制）

- 本地 Supabase 配置：`StarO/StarO/SupabaseConfig.plist`（由脚本生成，必须忽略）
- 本地备份：`trash/`
- Xcode/工具临时目录：如 `.derivedData/`、`.tmp/` 等
