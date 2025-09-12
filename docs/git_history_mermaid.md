# Git 历史（Mermaid Graph：短哈希 + 提交注释）

- 生成时间: 2025-09-07T14:24:37+08:00
- 说明: 第一部分为所有分支/标签可达提交；第二部分为仅在 reflog 中出现、当前无引用的游离提交。

## 1) 分支/标签可达提交
```mermaid
flowchart LR
  C000f16c[000f16c - style(overlay): match InputDrawer style (bg-gray-900 + border-gray-800), remove gradient]
  C00aaeff[00aaeff - style: 调整搜索框与编辑按钮间距为30px · · - 顶栏使用 gap-[30px] 并�...]
  C023a751[023a751 - Initial commit: StarOracle Capacitor App]
  C0754276[0754276 - 修复背景星星微小位移问题]
  C08bdbb9[08bdbb9 - Revert "fix(ios): 修正收缩定位公式为‘浮窗在输入框上方’并随实际...]
  C092036c[092036c - Fix iOS StarCard alignment issues with Safari-specific optimizations]
  C0a965e0[0a965e0 - Add code-fine and diff commands, prepare for conversation drawer fixes]
  C0aeade3[0aeade3 - 🎯 优化ChatOverlay交互体验 - 完善滑动收起和动画效果]
  C0b07dab[0b07dab - Fix drawer menu styling to match cosmic theme]
  C0f73b2a[0f73b2a - 完成字体系统统一，准备进一步优化输入框逻辑]
  C10ad80a[10ad80a - feat(ios): 为输入框与对话浮窗加入柔和位移动画]
  C10d605e[10d605e - fix(build): remove direct ConversationStore references from plugin; use manager wrappers]
  C1624d53[1624d53 - 📝 清理历史文档和调试代码]
  C16fd9a4[16fd9a4 - fix: iOS background 3D scaling animation]
  C17442cb[17442cb - chore(galaxy): update defaults per latest tuning (armDensity=0.65, innerWidth=56, growt...]
  C1a5f090[1a5f090 - 修复聊天时背景点击问题和字体大小一致性]
  C1dd6d46[1dd6d46 - 优化灵感卡片动画性能 - 分阶段加载动画]
  C1e3e82a[1e3e82a - chore: checkpoint — 当前保留3D/主页动画修复；首条消息发送仍有双�...]
  C1ed95eb[1ed95eb - fix(ios-first-collapse): 仅修复首次收缩的对齐]
  C204d367[204d367 - fix(ios): - Preserve previous AI messages by not resetting UI messages from JS param; o...]
  C224c32d[224c32d - 重新设计觉察图标 - 使用星星动画设计]
  C23fb004[23fb004 - 优化：从时间限制改为状态机机制，避免极端案例]
  C26a7f91[26a7f91 - fix(ios): idle-only guarded insert animation at native stream start]
  C27adf62[27adf62 - style: 顶栏搜索框宽度与间距优化 · · - 使用 flex-1 + mr-2 + gap-3 替代...]
  C27f6d0f[27f6d0f - 修复灵感卡片星星上下位移问题]
  C28e72a4[28e72a4 - fix: 修复首次缩小时输入框无法被键盘顶起的问题]
  C2b6e2ec[2b6e2ec - Ultimate fix for iOS ConversationDrawer button issues: Perfect circles and transparent ...]
  C2bf00b8[2bf00b8 - Remove input border styling to match reference design]
  C2c35362[2c35362 - fix(ios): 修正收缩定位公式为‘浮窗在输入框上方’并随实际位置�...]
  C2c3e9b4[2c3e9b4 - Remove button background color changes, keep only content color transitions]
  C2da6073[2da6073 - fix(ui): push user+AI placeholder to native overlay before starting stream]
  C2e9bb34[2e9bb34 - feat(galaxy): living galaxy integration and interaction loop]
  C2fa3e68[2fa3e68 - fix(ios/js): correct plugin usage in App.tsx; ensure assistant placeholder exists; star...]
  C31d2dba[31d2dba - fix(ios): reset animation state to idle after native stream completes]
  C353062b[353062b - feat: 侧边栏滚动优化 · · - DrawerMenu 抽屉容器改为 flex 列布局，中�...]
  C3c8d835[3c8d835 - feat(visual): add galaxyScale (default 0.618) and apply scale around center; expose sli...]
  C3d823de[3d823de - 调整了所有按钮的效果]
  C3ff0401[3ff0401 - 初步跑通swift原生插件]
  C40d71be[40d71be - 实现多轮对话功能和文本格式优化]
  C40de917[40de917 - fix(ios): 仅首次收缩延迟由输入框实际位置驱动对齐，之后保持原�...]
  C419a890[419a890 - Fix iOS Safari button styling with dialog-transparent-button CSS class]
  C436c845[436c845 - fix(ios): always animate user sends even during AI streaming]
  C47be20f[47be20f - Fix drawer menu close button to match invisible button style]
  C47c905e[47c905e - 实现iOS键盘与输入框同步弹起优化]
  C49621c0[49621c0 - chore: checkpoint — 修复原生发消息不显示；AI回复被顶掉，且无流式...]
  C49c0fa9[49c0fa9 - untracked files on (no branch): 7ec8266 chore(参数): 锁定银河默认参数为指�...]
  C4b9bb00[4b9bb00 - perf(ios-startup): 立即隐藏启动屏以消除首次点击输入框的延迟]
  C4bd6d4b[4bd6d4b - On (no branch): wip: temp before switch to main]
  C4c1c144[4c1c144 - 🚀 彻底解决ChatOverlay双重动画问题 - 多层次架构优化]
  C4c2aee7[4c2aee7 - 🐛 修复第一次缩小浮窗位置异常bug - 添加时序控制确保位置计算�...]
  C4f1653d[4f1653d - 优化界面交互体验，禁用不必要的长按复制功能]
  C50bbad0[50bbad0 - 完善觉察动画位置和布局优化]
  C56d1292[56d1292 - 修复原生对话框发送动画重复和流式输出冲突问题]
  C578982f[578982f - 🎯 修复ChatOverlay原生插件消息同步和AI对话逻辑]
  C595b768[595b768 - 🎯 解决触摸事件穿透问题 - 实现PassthroughWindow智能触摸处理]
  C5b1b510[5b1b510 - 优化对话浮窗UI和交互体验]
  C5de8d6b[5de8d6b - 🎯 输入框原生化优化完成 - 迈向混合架构]
  C5e6f029[5e6f029 - Implement new header layout with drawer menu and logo button]
  C5f1b7a3[5f1b7a3 - 加快灵感卡片主星星出现速度]
  C641caf2[641caf2 - 修改主屏幕点击交互，复用右键出星卡逻辑]
  C64824c9[64824c9 - 📝 更新CLAUDE.md构建指令 - 添加Xcode自动化命令]
  C64c14df[64c14df - 修复灵感卡片翻转时自动弹出键盘的问题]
  C65b1d18[65b1d18 - feat(conversation): add ConversationStore; expose system prompt + history APIs; include...]
  C6654625[6654625 - 修复背景星星状态切换导致的视觉跳变问题]
  C682f0d0[682f0d0 - Unify button styles across the application]
  C6b66caf[6b66caf - Move Template button functionality to drawer menu]
  C6b6f644[6b6f644 - feat(ios): trigger user insert animation at native stream start]
  C6b9db23[6b9db23 - fix(visual): align galaxy params to saved ref and remove glow/overlays]
  C6dbe319[6dbe319 - 重构对话架构 - 分离主页和对话功能]
  C6e5f467[6e5f467 - chore(native-stream): no-op JS nativeChatOverlay.updateMessages when native streaming e...]
  C6ed8040[6ed8040 - 修复灵感卡片翻转不可逆问题]
  C741251e[741251e - style: 优化侧边栏搜索框与新建按钮样式 · · - 搜索输入改为圆角�...]
  C74d1d93[74d1d93 - Remove plus button from input bars for cleaner design]
  C76e9cb5[76e9cb5 - cursor修复之前 - 保存当前版本用于问题分析]
  C7b4760a[7b4760a - revert(send): align user send animation trigger with 9e1a3a8 logic]
  C7dd6d1a[7dd6d1a - feat(visual): rotating living galaxy with breathing and 3-arm palette]
  C7ec8266[7ec8266 - chore(参数): 锁定银河默认参数为指定数值 · · - 核心密度: 0.7, 核�...]
  C7eed6f8[7eed6f8 - FINAL FIX: Remove conflicting CSS padding rules that broke button styling]
  C801b436[801b436 - feat(M2): logging + conversation bridge + history load]
  C84c9d73[84c9d73 - 增加对话浮窗功能]
  C8582f39[8582f39 - feat(visual): replace dual-layer spin with differential rotation by radial bands; deter...]
  C880032e[880032e - 实现流式AI回复输出功能]
  C889e75e[889e75e - 移除抽屉菜单图标并优化iOS键盘交互]
  C8b41562[8b41562 - fix(ios): 首次收缩未对齐问题 — 监听输入框实际位置并同步对齐]
  C8cd7eee[8cd7eee - fix: 初步修复聊天浮窗残影问题]
  C8e45863[8e45863 - Localize Star Collection to 集星 and remove drawer menu border]
  C8f49f10[8f49f10 - fix(ios): use oldMessages.count to detect insert vs stream in VC.updateMessages]
  C9577657[9577657 - refactor(send): remove pre-render native updateMessages; use fresh Zustand state for st...]
  C973dd36[973dd36 - feat: 历史会话AI标题总结与侧边交互修复 · · - 移除侧栏历史对话�...]
  C97483d5[97483d5 - chore: snapshot after InputDrawer visibility safeguards and AGENTS.md]
  C9878f10[9878f10 - 修复了左侧抽屉按钮里面的文字顶部的高度]
  C994e555[994e555 - Implement dark input bar design for ConversationDrawer]
  C9ab5d72[9ab5d72 - Optimize ConversationDrawer: Merge DarkInputBar design with iOS compatibility]
  C9d0a923[9d0a923 - Fix StarCard layout alignment issues]
  C9d66576[9d66576 - 修复灵感卡片背景星星位置跳变问题]
  C9e1a3a8[9e1a3a8 - fix: 修复流式输出和动画重复问题的综合解决方案]
  C9ec8afe[9ec8afe - chore(ref): revert unintended changes to ref/stelloracle-home.tsx (no functional impact)]
  Ca49a8d1[a49a8d1 - fix(send): use fresh Zustand state after addUserMessage for native bootstrap and conver...]
  Ca6a062b[a6a062b - chore(galaxy): apply user-adjusted defaults (outerWidth=53, bgDensity=0.00045, noiseSca...]
  Ca8474f7[a8474f7 - Fix ConversationDrawer input bar transparent background - Phase 1]
  Cac44054[ac44054 - fix(ios): gate first user send animation until layout expansion completes]
  Cac5ab2f[ac5ab2f - ✅ ChatOverlay双文件架构完成 - 删除所有测试UI]
  Cb02d420[b02d420 - 基于iChatGPT设计优化流式输出实现]
  Cb21a241[b21a241 - fix: 统一AI对话系统Prompt并注入原生]
  Cb251e86[b251e86 - 实现觉察功能完整体系]
  Cb2dd330[b2dd330 - feat(stream): ensure per-char streaming to native via appendAIChunk fallback to updateL...]
  Cb4b0d92[b4b0d92 - fix(fallback): ensure messages visible by JS fallback streaming to native when startNat...]
  Cbc61bd3[bc61bd3 - Save project state before fixing Xcode compatibility issues]
  Cbd74745[bd74745 - chore: checkpoint — 浮窗样式与输入框一致（bg-gray-900 + border-gray-800）...]
  Cc07f315[c07f315 - chore: checkpoint — 增加旋转Star加载动画；存在视觉重叠与偶发bug（�...]
  Cc209613[c209613 - style: 搜索框圆角与宽度微调 · · - 顶栏容器增加 gap，搜索输入改�...]
  Cc631692[c631692 - chore: snapshot after animation fix 2025-08-31T17:12:35Z]
  Cc6e946f[c6e946f - 🎯 完善ChatOverlay和InputDrawer定位系统 - 降低整体高度50px]
  Cc7c9f3e[c7c9f3e - Optimize Header positioning to perfectly align with Dynamic Island]
  Cca82a1c[ca82a1c - 优化输入框响应速度 - 解耦聚焦行为和浮窗动画]
  Ccbb1168[cbb1168 - feat(视觉): 按星系结构分色并加入前台开关 · · - 新增结构着色开�...]
  Ccdc6486[cdc6486 - 修复AI功能 - 解决环境变量读取和API调用问题]
  Ccf2c9bd[cf2c9bd - index on (no branch): 7ec8266 chore(参数): 锁定银河默认参数为指定数值 ·...]
  Cd0a107c[d0a107c - 🎯 ChatOverlay原生插件核心功能完成 - 解决三大问题]
  Cd658b5d[d658b5d - chore: snapshot before Codex changes 2025-08-31T10:49:49Z]
  Cd7293af[d7293af - 接入真实AI API到聊天系统]
  Cd7392ac[d7392ac - fix(ios): ensure user message visible even when insert animation not triggered]
  Cd80919a[d80919a - 修复Swift编译错误：状态机属性引用问题]
  Cd895a13[d895a13 - fix(ios-first-collapse): 首次收缩在键盘可见时也上移输入框为浮窗预�...]
  Cd8f18b0[d8f18b0 - 重新安装依赖之前 为了使用capacitor external]
  Cdaa4cc0[daa4cc0 - chore(galaxy): set homepage galaxy defaults to user-provided params and update doc]
  Ce14b1d5[e14b1d5 - chore(galaxy): update defaults per latest user params (galaxyScale=0.68, armDensity=0.7...]
  Ce73ca84[e73ca84 - Fix Xcode compatibility issues and update dependencies]
  Ce8a2232[e8a2232 - 优化灵感卡片动画时序 - 背景星星在主星星完成后开始]
  Ce9712be[e9712be - feat(native-stream): switch iOS chat to native StreamingClient]
  Ce9b7a6f[e9b7a6f - 进一步优化主星星出现速度 - 延迟设为0]
  Cea08028[ea08028 - feat(debug): add pause-rotation toggle in galaxy debug panel (default paused when debug...]
  Cede2dd7[ede2dd7 - fix(ios): resolve AnimationState type ambiguity; compare against .userAnimating using q...]
  Cedf6a0b[edf6a0b - feat: 侧边栏布局改版（搜索 + 新建） · · - 移除列表上方“新建会...]
  Cf2fcc58[f2fcc58 - 优化流式输出UI体验和聊天界面]
  Cf6c2736[f6c2736 - 修复觉察功能的所有问题]
  Cf745e44[f745e44 - 实现首页对话框功能并集成模拟AI回复]
  Cfc2a0ab[fc2a0ab - chore: checkpoint — 对话基本问题已修复；prompt 被修改、流式未完全�...]
  Cfd54381[fd54381 - fix: 侧边栏搜索框圆角被重置覆盖的问题 · · - 为搜索输入增加 sid...]
  C000f16c --> Cbd74745
  C023a751 --> Cbc61bd3
  C0754276 --> C27f6d0f
  C08bdbb9 --> C40de917
  C092036c --> Ca8474f7
  C0a965e0 --> C9ab5d72
  C0aeade3 --> C4c1c144
  C0b07dab --> C682f0d0
  C0f73b2a --> Cf745e44
  C10ad80a --> C8b41562
  C10d605e --> Cfc2a0ab
  C1624d53 --> Cd0a107c
  C16fd9a4 --> Cac44054
  C17442cb --> Ce14b1d5
  C1a5f090 --> C6dbe319
  C1dd6d46 --> C9d66576
  C1e3e82a --> Ce9712be
  C1ed95eb --> C9ec8afe
  C204d367 --> C2fa3e68
  C224c32d --> C50bbad0
  C23fb004 --> Cd80919a
  C26a7f91 --> C31d2dba
  C27adf62 --> C00aaeff
  C27f6d0f --> Ce8a2232
  C28e72a4 --> Cb21a241
  C2b6e2ec --> C7eed6f8
  C2bf00b8 --> C74d1d93
  C2c35362 --> C08bdbb9
  C2c3e9b4 --> C47be20f
  C2da6073 --> Ca49a8d1
  C2e9bb34 --> C7dd6d1a
  C2fa3e68 --> C65b1d18
  C31d2dba --> Cd7392ac
  C353062b --> Cedf6a0b
  C3c8d835 --> C17442cb
  C3d823de --> C9878f10
  C3ff0401 --> Cac5ab2f
  C40d71be --> Cb251e86
  C40de917 --> C1ed95eb
  C419a890 --> C2bf00b8
  C436c845 --> Cede2dd7
  C47be20f --> Cc7c9f3e
  C47c905e --> C0f73b2a
  C49621c0 --> C204d367
  C49c0fa9 --> C4bd6d4b
  C4b9bb00 --> C973dd36
  C4c1c144 --> Cd658b5d
  C4c2aee7 --> C0aeade3
  C4f1653d --> C641caf2
  C50bbad0 --> C1a5f090
  C56d1292 --> C23fb004
  C578982f --> C595b768
  C595b768 --> Cc6e946f
  C5b1b510 --> Cca82a1c
  C5de8d6b --> C3ff0401
  C5e6f029 --> C6b66caf
  C5f1b7a3 --> Ce9b7a6f
  C641caf2 --> C64c14df
  C64824c9 --> C578982f
  C64c14df --> C1dd6d46
  C65b1d18 --> C801b436
  C6654625 --> C6ed8040
  C682f0d0 --> C2c3e9b4
  C6b66caf --> C0b07dab
  C6b6f644 --> C26a7f91
  C6b9db23 --> Cdaa4cc0
  C6dbe319 --> C84c9d73
  C6e5f467 --> Cb4b0d92
  C6ed8040 --> C5f1b7a3
  C741251e --> Cc209613
  C74d1d93 --> C5e6f029
  C76e9cb5 --> C56d1292
  C7b4760a --> C1e3e82a
  C7dd6d1a --> C6b9db23
  C7ec8266 --> C4bd6d4b
  C7ec8266 --> Ccf2c9bd
  C7eed6f8 --> C419a890
  C801b436 --> C10d605e
  C84c9d73 --> C5b1b510
  C8582f39 --> Ccbb1168
  C880032e --> Cf2fcc58
  C889e75e --> C47c905e
  C8b41562 --> C2c35362
  C8cd7eee --> C16fd9a4
  C8e45863 --> C889e75e
  C8f49f10 --> C6e5f467
  C9577657 --> C49621c0
  C973dd36 --> C353062b
  C97483d5 --> Cb2dd330
  C9878f10 --> C8e45863
  C994e555 --> Cd8f18b0
  C9ab5d72 --> C2b6e2ec
  C9d0a923 --> C092036c
  C9d66576 --> C0754276
  C9e1a3a8 --> C8cd7eee
  C9ec8afe --> Cd895a13
  Ca49a8d1 --> C9577657
  Ca6a062b --> C3c8d835
  Ca8474f7 --> C0a965e0
  Cac44054 --> C436c845
  Cac5ab2f --> C1624d53
  Cb02d420 --> C97483d5
  Cb21a241 --> C10ad80a
  Cb251e86 --> Cf6c2736
  Cb2dd330 --> C9e1a3a8
  Cb4b0d92 --> C2da6073
  Cbc61bd3 --> Ce73ca84
  Cbd74745 --> C28e72a4
  Cc07f315 --> C000f16c
  Cc209613 --> Cfd54381
  Cc631692 --> C76e9cb5
  Cc6e946f --> C4c2aee7
  Cc7c9f3e --> C3d823de
  Cca82a1c --> C2e9bb34
  Cca82a1c --> C5de8d6b
  Ccbb1168 --> C7ec8266
  Ccdc6486 --> C880032e
  Ccf2c9bd --> C4bd6d4b
  Cd0a107c --> C64824c9
  Cd658b5d --> Cc631692
  Cd7293af --> Ccdc6486
  Cd7392ac --> C8f49f10
  Cd80919a --> Cb02d420
  Cd895a13 --> C4b9bb00
  Cd8f18b0 --> C9d0a923
  Cdaa4cc0 --> Cea08028
  Ce14b1d5 --> C8582f39
  Ce73ca84 --> C994e555
  Ce8a2232 --> C6654625
  Ce9712be --> C6b6f644
  Ce9b7a6f --> Cd7293af
  Cea08028 --> Ca6a062b
  Cede2dd7 --> C7b4760a
  Cedf6a0b --> C741251e
  Cf2fcc58 --> C40d71be
  Cf6c2736 --> C224c32d
  Cf745e44 --> C4f1653d
  Cfc2a0ab --> Cc07f315
  Cfd54381 --> C27adf62
```

## 2) 仅 Reflog 的游离提交
（暂无：当前没有仅存在于 reflog 的游离提交。此前的游离提交已被分支引用，因此计入上面的主图。）
