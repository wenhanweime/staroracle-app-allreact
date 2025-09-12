# Git 提交图（Graph，含分支与游离记录）

- 生成时间: 2025-09-07T14:11:05+08:00
- 说明: 第一部分展示所有分支/标签可达提交（--all）；第二部分追加仅在 reflog 出现、当前无引用可达的游离提交（若有）。

## 1) Graph（所有分支/标签可达提交）
```
*-.   4bd6d4b (refs/stash) On (no branch): wip: temp before switch to main
|\ \  
| * | cf2c9bd index on (no branch): 7ec8266 chore(参数): 锁定银河默认参数为指定数值\n\n- 核心密度: 0.7, 核心半径: 25\n- 旋臂数量: 5, 旋臂密度: 0.6, 螺旋紧密度: 0.29\n- 内侧宽度: 29, 外侧宽度: 53, 宽度增长: 2.5\n- 臂间基础密度: 0.15, 山坡平缓度: 7.3\n- 淡化起始: 0.5, 淡化结束: 1.54\n- 背景密度: 0.00045\n- 垂直抖动强度: 17, 噪声缩放: 0.041, 噪声强度: 0.9\n- 星大小倍数: 旋臂 0.8, 臂间 1, 背景 0.7\n\n后续不再轻易修改默认参数，如需变更将另行说明。
|/ /  
| * 49c0fa9 untracked files on (no branch): 7ec8266 chore(参数): 锁定银河默认参数为指定数值\n\n- 核心密度: 0.7, 核心半径: 25\n- 旋臂数量: 5, 旋臂密度: 0.6, 螺旋紧密度: 0.29\n- 内侧宽度: 29, 外侧宽度: 53, 宽度增长: 2.5\n- 臂间基础密度: 0.15, 山坡平缓度: 7.3\n- 淡化起始: 0.5, 淡化结束: 1.54\n- 背景密度: 0.00045\n- 垂直抖动强度: 17, 噪声缩放: 0.041, 噪声强度: 0.9\n- 星大小倍数: 旋臂 0.8, 臂间 1, 背景 0.7\n\n后续不再轻易修改默认参数，如需变更将另行说明。
* 7ec8266 (HEAD -> params-lock-7ec8266) chore(参数): 锁定银河默认参数为指定数值\n\n- 核心密度: 0.7, 核心半径: 25\n- 旋臂数量: 5, 旋臂密度: 0.6, 螺旋紧密度: 0.29\n- 内侧宽度: 29, 外侧宽度: 53, 宽度增长: 2.5\n- 臂间基础密度: 0.15, 山坡平缓度: 7.3\n- 淡化起始: 0.5, 淡化结束: 1.54\n- 背景密度: 0.00045\n- 垂直抖动强度: 17, 噪声缩放: 0.041, 噪声强度: 0.9\n- 星大小倍数: 旋臂 0.8, 臂间 1, 背景 0.7\n\n后续不再轻易修改默认参数，如需变更将另行说明。
* cbb1168 feat(视觉): 按星系结构分色并加入前台开关\n\n- 新增结构着色开关（默认关闭），启用后按核心/臂脊/臂内/臂边/尘埃/外围分类上色\n- 保持背景全屏白星、不随缩放/旋转；主体仍按差速旋转呈现\n- 保留固定随机种子，保证同参数形态一致\n- 未开启开关时维持白星风格，便于性能与形态对比
* 8582f39 feat(visual): replace dual-layer spin with differential rotation by radial bands; deterministic RNG for stable morphology; keep background full-screen
* e14b1d5 chore(galaxy): update defaults per latest user params (galaxyScale=0.68, armDensity=0.70, spiralB=0.21, inner=55, outer=101, fade 0.2-1.36, bgDensity=0.0006, jitter=16, noiseStrength=0.9, multipliers 0.8/0.9) and sync docs
* 17442cb chore(galaxy): update defaults per latest tuning (armDensity=0.65, innerWidth=56, growth=2.8, bgDensity=0.00057, noiseScale=0.049, galaxyScale=0.6) and docs
* 3c8d835 feat(visual): add galaxyScale (default 0.618) and apply scale around center; expose slider in debug panel
* a6a062b chore(galaxy): apply user-adjusted defaults (outerWidth=53, bgDensity=0.00045, noiseScale=0.006, etc.) and update docs/log
* ea08028 feat(debug): add pause-rotation toggle in galaxy debug panel (default paused when debugging)
* daa4cc0 chore(galaxy): set homepage galaxy defaults to user-provided params and update doc
* 6b9db23 fix(visual): align galaxy params to saved ref and remove glow/overlays
* 7dd6d1a feat(visual): rotating living galaxy with breathing and 3-arm palette
* 2e9bb34 feat(galaxy): living galaxy integration and interaction loop
| * 00aaeff (origin/main, origin/HEAD, main) style: 调整搜索框与编辑按钮间距为30px\n\n- 顶栏使用 gap-[30px] 并移除输入容器 mr，确保两者间固定30px间距\n- 保持圆角与边框样式不变
| * 27adf62 style: 顶栏搜索框宽度与间距优化\n\n- 使用 flex-1 + mr-2 + gap-3 替代固定 calc 宽度，避免与右侧按钮交叉\n- 保持圆角与边框样式不变，提升自适应布局稳定性
| * fd54381 fix: 侧边栏搜索框圆角被重置覆盖的问题\n\n- 为搜索输入增加 sidebar-search-input 类并在全局样式中以 !important 强制圆角\n- 兼容 iOS 的输入重置（appearance/border-radius），确保真机圆角生效\n- 更新文档记录该覆盖策略
| * c209613 style: 搜索框圆角与宽度微调\n\n- 顶栏容器增加 gap，搜索输入改为 rounded-full 并缩短整体宽度（比按钮多预留一个图标宽度）\n- 通过 calc(100% - 2.5rem) 精准控制右侧留白，避免与编辑按钮贴合
| * 741251e style: 优化侧边栏搜索框与新建按钮样式\n\n- 搜索输入改为圆角并加边框，父容器加 gap 保留与按钮间距\n- 将新建按钮替换为 lucide-react 的 SquarePen 图标，并增强 hover/边框视觉\n- 文档记录样式与布局的调整
| * edf6a0b feat: 侧边栏布局改版（搜索 + 新建）\n\n- 移除列表上方“新建会话”按钮；顶部右侧改为铅笔图标并触发新建\n- 顶部标题替换为搜索框，支持按标题关键字过滤\n- 保持遮罩点击可关闭抽屉\n- 文档追加布局调整记录
| * 353062b feat: 侧边栏滚动优化\n\n- DrawerMenu 抽屉容器改为 flex 列布局，中部列表区域启用 overflow-y-auto 并支持 iOS 惯性滚动\n- 文档追加滚动优化的修改日志
| * 973dd36 feat: 历史会话AI标题总结与侧边交互修复\n\n- 移除侧栏历史对话重命名/删除按钮，点击直接切换并唤起浮窗\n- 新增基于弹幕链路的会话标题AI总结（取消条数阈值，所有会话均总结）\n- iOS 插件：listSessions/sessionsChanged 返回 messagesCount/rawTitle/displayTitle/hasCustomTitle；新增 getSessionSummaryContext；会话存储变更广播\n- 展示标题兜底逻辑优化，优先显示持久化标题；过渡展示使用裁剪文本\n- Web stub 同步补齐接口避免开发态报错\n- 文档：更新 历史会话和会话能力升级.md 变更记录
| * 4b9bb00 perf(ios-startup): 立即隐藏启动屏以消除首次点击输入框的延迟
| * d895a13 fix(ios-first-collapse): 首次收缩在键盘可见时也上移输入框为浮窗预留空间（仅一次）
| * 9ec8afe chore(ref): revert unintended changes to ref/stelloracle-home.tsx (no functional impact)
| * 1ed95eb fix(ios-first-collapse): 仅修复首次收缩的对齐
| * 40de917 fix(ios): 仅首次收缩延迟由输入框实际位置驱动对齐，之后保持原逻辑
| * 08bdbb9 Revert "fix(ios): 修正收缩定位公式为‘浮窗在输入框上方’并随实际位置联动"
| * 2c35362 fix(ios): 修正收缩定位公式为‘浮窗在输入框上方’并随实际位置联动
| * 8b41562 fix(ios): 首次收缩未对齐问题 — 监听输入框实际位置并同步对齐
| * 10ad80a feat(ios): 为输入框与对话浮窗加入柔和位移动画
| * b21a241 fix: 统一AI对话系统Prompt并注入原生
| * 28e72a4 fix: 修复首次缩小时输入框无法被键盘顶起的问题
| * bd74745 chore: checkpoint — 浮窗样式与输入框一致（bg-gray-900 + border-gray-800）；修复残余渐变引用编译错误
| * 000f16c style(overlay): match InputDrawer style (bg-gray-900 + border-gray-800), remove gradient
| * c07f315 chore: checkpoint — 增加旋转Star加载动画；存在视觉重叠与偶发bug（待优化）
| * fc2a0ab chore: checkpoint — 对话基本问题已修复；prompt 被修改、流式未完全恢复、偶发英文回复（待跟进）
| * 10d605e fix(build): remove direct ConversationStore references from plugin; use manager wrappers
| * 801b436 feat(M2): logging + conversation bridge + history load
| * 65b1d18 feat(conversation): add ConversationStore; expose system prompt + history APIs; include system prompt + context window in native stream
| * 2fa3e68 fix(ios/js): correct plugin usage in App.tsx; ensure assistant placeholder exists; start replay after insert animation
| * 204d367 fix(ios): - Preserve previous AI messages by not resetting UI messages from JS param; only append new user row in startNativeStreaming - Start gradual replay (beginAIReplayAfterAnimation) after insert animation to show streaming effect - Show loading indicator for AI empty text in MessageTableViewCell - Use updated Zustand state in App.tsx; remove conflicting pre-render native updateMessages in native path
| * 49621c0 chore: checkpoint — 修复原生发消息不显示；AI回复被顶掉，且无流式输出（待修复）
| * 9577657 refactor(send): remove pre-render native updateMessages; use fresh Zustand state for startNativeStream
| * a49a8d1 fix(send): use fresh Zustand state after addUserMessage for native bootstrap and conversation
| * 2da6073 fix(ui): push user+AI placeholder to native overlay before starting stream
| * b4b0d92 fix(fallback): ensure messages visible by JS fallback streaming to native when startNativeStream fails
| * 6e5f467 chore(native-stream): no-op JS nativeChatOverlay.updateMessages when native streaming enabled
| * 8f49f10 fix(ios): use oldMessages.count to detect insert vs stream in VC.updateMessages
| * d7392ac fix(ios): ensure user message visible even when insert animation not triggered
| * 31d2dba fix(ios): reset animation state to idle after native stream completes
| * 26a7f91 fix(ios): idle-only guarded insert animation at native stream start
| * 6b6f644 feat(ios): trigger user insert animation at native stream start
| * e9712be feat(native-stream): switch iOS chat to native StreamingClient
| * 1e3e82a chore: checkpoint — 当前保留3D/主页动画修复；首条消息发送仍有双重发送/打断问题，其他问题基本正常
| * 7b4760a revert(send): align user send animation trigger with 9e1a3a8 logic
| * ede2dd7 fix(ios): resolve AnimationState type ambiguity; compare against .userAnimating using qualified default state
| * 436c845 fix(ios): always animate user sends even during AI streaming
| * ac44054 fix(ios): gate first user send animation until layout expansion completes
| * 16fd9a4 fix: iOS background 3D scaling animation
| * 8cd7eee fix: 初步修复聊天浮窗残影问题
| * 9e1a3a8 fix: 修复流式输出和动画重复问题的综合解决方案
| * b2dd330 feat(stream): ensure per-char streaming to native via appendAIChunk fallback to updateLastAI; add periodic beat sync; fix InputDrawer visibility
| * 97483d5 chore: snapshot after InputDrawer visibility safeguards and AGENTS.md
| * b02d420 基于iChatGPT设计优化流式输出实现
| * d80919a 修复Swift编译错误：状态机属性引用问题
| * 23fb004 优化：从时间限制改为状态机机制，避免极端案例
| * 56d1292 修复原生对话框发送动画重复和流式输出冲突问题
| * 76e9cb5 cursor修复之前 - 保存当前版本用于问题分析
| * c631692 (tag: snapshot-20250831-171235) chore: snapshot after animation fix 2025-08-31T17:12:35Z
| * d658b5d (tag: pre-codex-20250831-104949) chore: snapshot before Codex changes 2025-08-31T10:49:49Z
| * 4c1c144 🚀 彻底解决ChatOverlay双重动画问题 - 多层次架构优化
| * 0aeade3 🎯 优化ChatOverlay交互体验 - 完善滑动收起和动画效果
| * 4c2aee7 🐛 修复第一次缩小浮窗位置异常bug - 添加时序控制确保位置计算准确
| * c6e946f 🎯 完善ChatOverlay和InputDrawer定位系统 - 降低整体高度50px
| * 595b768 🎯 解决触摸事件穿透问题 - 实现PassthroughWindow智能触摸处理
| * 578982f 🎯 修复ChatOverlay原生插件消息同步和AI对话逻辑
| * 64824c9 📝 更新CLAUDE.md构建指令 - 添加Xcode自动化命令
| * d0a107c 🎯 ChatOverlay原生插件核心功能完成 - 解决三大问题
| * 1624d53 📝 清理历史文档和调试代码
| * ac5ab2f ✅ ChatOverlay双文件架构完成 - 删除所有测试UI
| * 3ff0401 初步跑通swift原生插件
| * 5de8d6b 🎯 输入框原生化优化完成 - 迈向混合架构
|/  
* ca82a1c 优化输入框响应速度 - 解耦聚焦行为和浮窗动画
* 5b1b510 优化对话浮窗UI和交互体验
* 84c9d73 增加对话浮窗功能
* 6dbe319 重构对话架构 - 分离主页和对话功能
* 1a5f090 修复聊天时背景点击问题和字体大小一致性
* 50bbad0 完善觉察动画位置和布局优化
* 224c32d 重新设计觉察图标 - 使用星星动画设计
* f6c2736 修复觉察功能的所有问题
* b251e86 实现觉察功能完整体系
* 40d71be 实现多轮对话功能和文本格式优化
* f2fcc58 优化流式输出UI体验和聊天界面
* 880032e 实现流式AI回复输出功能
* cdc6486 修复AI功能 - 解决环境变量读取和API调用问题
* d7293af 接入真实AI API到聊天系统
* e9b7a6f 进一步优化主星星出现速度 - 延迟设为0
* 5f1b7a3 加快灵感卡片主星星出现速度
* 6ed8040 修复灵感卡片翻转不可逆问题
* 6654625 修复背景星星状态切换导致的视觉跳变问题
* e8a2232 优化灵感卡片动画时序 - 背景星星在主星星完成后开始
* 27f6d0f 修复灵感卡片星星上下位移问题
* 0754276 修复背景星星微小位移问题
* 9d66576 修复灵感卡片背景星星位置跳变问题
* 1dd6d46 优化灵感卡片动画性能 - 分阶段加载动画
* 64c14df 修复灵感卡片翻转时自动弹出键盘的问题
* 641caf2 修改主屏幕点击交互，复用右键出星卡逻辑
* 4f1653d 优化界面交互体验，禁用不必要的长按复制功能
* f745e44 实现首页对话框功能并集成模拟AI回复
* 0f73b2a 完成字体系统统一，准备进一步优化输入框逻辑
* 47c905e 实现iOS键盘与输入框同步弹起优化
* 889e75e 移除抽屉菜单图标并优化iOS键盘交互
* 8e45863 Localize Star Collection to 集星 and remove drawer menu border
* 9878f10 修复了左侧抽屉按钮里面的文字顶部的高度
* 3d823de 调整了所有按钮的效果
* c7c9f3e Optimize Header positioning to perfectly align with Dynamic Island
* 47be20f Fix drawer menu close button to match invisible button style
* 2c3e9b4 Remove button background color changes, keep only content color transitions
* 682f0d0 Unify button styles across the application
* 0b07dab Fix drawer menu styling to match cosmic theme
* 6b66caf Move Template button functionality to drawer menu
* 5e6f029 Implement new header layout with drawer menu and logo button
* 74d1d93 Remove plus button from input bars for cleaner design
* 2bf00b8 Remove input border styling to match reference design
* 419a890 Fix iOS Safari button styling with dialog-transparent-button CSS class
* 7eed6f8 FINAL FIX: Remove conflicting CSS padding rules that broke button styling
* 2b6e2ec Ultimate fix for iOS ConversationDrawer button issues: Perfect circles and transparent backgrounds
* 9ab5d72 Optimize ConversationDrawer: Merge DarkInputBar design with iOS compatibility
* 0a965e0 Add code-fine and diff commands, prepare for conversation drawer fixes
* a8474f7 Fix ConversationDrawer input bar transparent background - Phase 1
* 092036c Fix iOS StarCard alignment issues with Safari-specific optimizations
* 9d0a923 Fix StarCard layout alignment issues
* d8f18b0 重新安装依赖之前 为了使用capacitor external
* 994e555 Implement dark input bar design for ConversationDrawer
* e73ca84 Fix Xcode compatibility issues and update dependencies
* bc61bd3 Save project state before fixing Xcode compatibility issues
* 023a751 Initial commit: StarOracle Capacitor App
```

## 2) Graph（仅 Reflog 游离提交 — 当前无分支/标签指向）
（暂无游离提交；所有提交均被分支/标签/远端引用覆盖）
