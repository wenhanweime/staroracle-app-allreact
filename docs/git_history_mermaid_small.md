# Git 历史（Mermaid：短哈希 + 注释，最近 40 条）

- 生成时间: 2025-09-07T14:26:05+08:00
- 说明: 限制为最近 40 条提交，避免图过大导致渲染失败。

## 分支/标签可达提交（最近 40）
```mermaid
flowchart LR
  C4bd6d4b["4bd6d4b - On (no branch): wip: temp before switch to main"]
  Ccf2c9bd["cf2c9bd - index on (no branch): 7ec8266 chore(参数): 锁定银河默认参数为指定数值 ·..."]
  C49c0fa9["49c0fa9 - untracked files on (no branch): 7ec8266 chore(参数): 锁定银河默认参数为指�..."]
  C7ec8266["7ec8266 - chore(参数): 锁定银河默认参数为指定数值 · · - 核心密度: 0.7, 核�..."]
  Ccbb1168["cbb1168 - feat(视觉): 按星系结构分色并加入前台开关 · · - 新增结构着色开�..."]
  C8582f39["8582f39 - feat(visual): replace dual-layer spin with differential rotation by radial bands; deter..."]
  Ce14b1d5["e14b1d5 - chore(galaxy): update defaults per latest user params (galaxyScale=0.68, armDensity=0.7..."]
  C17442cb["17442cb - chore(galaxy): update defaults per latest tuning (armDensity=0.65, innerWidth=56, growt..."]
  C3c8d835["3c8d835 - feat(visual): add galaxyScale (default 0.618) and apply scale around center; expose sli..."]
  Ca6a062b["a6a062b - chore(galaxy): apply user-adjusted defaults (outerWidth=53, bgDensity=0.00045, noiseSca..."]
  Cea08028["ea08028 - feat(debug): add pause-rotation toggle in galaxy debug panel (default paused when debug..."]
  Cdaa4cc0["daa4cc0 - chore(galaxy): set homepage galaxy defaults to user-provided params and update doc"]
  C6b9db23["6b9db23 - fix(visual): align galaxy params to saved ref and remove glow/overlays"]
  C7dd6d1a["7dd6d1a - feat(visual): rotating living galaxy with breathing and 3-arm palette"]
  C2e9bb34["2e9bb34 - feat(galaxy): living galaxy integration and interaction loop"]
  C00aaeff["00aaeff - style: 调整搜索框与编辑按钮间距为30px · · - 顶栏使用 gap-[30px] 并�..."]
  C27adf62["27adf62 - style: 顶栏搜索框宽度与间距优化 · · - 使用 flex-1 + mr-2 + gap-3 替代..."]
  Cfd54381["fd54381 - fix: 侧边栏搜索框圆角被重置覆盖的问题 · · - 为搜索输入增加 sid..."]
  Cc209613["c209613 - style: 搜索框圆角与宽度微调 · · - 顶栏容器增加 gap，搜索输入改�..."]
  C741251e["741251e - style: 优化侧边栏搜索框与新建按钮样式 · · - 搜索输入改为圆角�..."]
  Cedf6a0b["edf6a0b - feat: 侧边栏布局改版（搜索 + 新建） · · - 移除列表上方“新建会..."]
  C353062b["353062b - feat: 侧边栏滚动优化 · · - DrawerMenu 抽屉容器改为 flex 列布局，中�..."]
  C973dd36["973dd36 - feat: 历史会话AI标题总结与侧边交互修复 · · - 移除侧栏历史对话�..."]
  C4b9bb00["4b9bb00 - perf(ios-startup): 立即隐藏启动屏以消除首次点击输入框的延迟"]
  Cd895a13["d895a13 - fix(ios-first-collapse): 首次收缩在键盘可见时也上移输入框为浮窗预�..."]
  C9ec8afe["9ec8afe - chore(ref): revert unintended changes to ref/stelloracle-home.tsx (no functional impact)"]
  C1ed95eb["1ed95eb - fix(ios-first-collapse): 仅修复首次收缩的对齐"]
  C40de917["40de917 - fix(ios): 仅首次收缩延迟由输入框实际位置驱动对齐，之后保持原�..."]
  C08bdbb9["08bdbb9 - Revert "fix(ios): 修正收缩定位公式为‘浮窗在输入框上方’并随实际..."]
  C2c35362["2c35362 - fix(ios): 修正收缩定位公式为‘浮窗在输入框上方’并随实际位置�..."]
  C8b41562["8b41562 - fix(ios): 首次收缩未对齐问题 — 监听输入框实际位置并同步对齐"]
  C10ad80a["10ad80a - feat(ios): 为输入框与对话浮窗加入柔和位移动画"]
  Cb21a241["b21a241 - fix: 统一AI对话系统Prompt并注入原生"]
  C28e72a4["28e72a4 - fix: 修复首次缩小时输入框无法被键盘顶起的问题"]
  Cbd74745["bd74745 - chore: checkpoint — 浮窗样式与输入框一致（bg-gray-900 + border-gray-800）..."]
  C000f16c["000f16c - style(overlay): match InputDrawer style (bg-gray-900 + border-gray-800), remove gradient"]
  Cc07f315["c07f315 - chore: checkpoint — 增加旋转Star加载动画；存在视觉重叠与偶发bug（�..."]
  Cfc2a0ab["fc2a0ab - chore: checkpoint — 对话基本问题已修复；prompt 被修改、流式未完全�..."]
  C10d605e["10d605e - fix(build): remove direct ConversationStore references from plugin; use manager wrappers"]
  C7ec8266 --> C4bd6d4b
  Ccf2c9bd --> C4bd6d4b
  C49c0fa9 --> C4bd6d4b
  C7ec8266 --> Ccf2c9bd
  Ccbb1168 --> C7ec8266
  C8582f39 --> Ccbb1168
  Ce14b1d5 --> C8582f39
  C17442cb --> Ce14b1d5
  C3c8d835 --> C17442cb
  Ca6a062b --> C3c8d835
  Cea08028 --> Ca6a062b
  Cdaa4cc0 --> Cea08028
  C6b9db23 --> Cdaa4cc0
  C7dd6d1a --> C6b9db23
  C2e9bb34 --> C7dd6d1a
  C27adf62 --> C00aaeff
  Cfd54381 --> C27adf62
  Cc209613 --> Cfd54381
  C741251e --> Cc209613
  Cedf6a0b --> C741251e
  C353062b --> Cedf6a0b
  C973dd36 --> C353062b
  C4b9bb00 --> C973dd36
  Cd895a13 --> C4b9bb00
  C9ec8afe --> Cd895a13
  C1ed95eb --> C9ec8afe
  C40de917 --> C1ed95eb
  C08bdbb9 --> C40de917
  C2c35362 --> C08bdbb9
  C8b41562 --> C2c35362
  C10ad80a --> C8b41562
  Cb21a241 --> C10ad80a
  C28e72a4 --> Cb21a241
  Cbd74745 --> C28e72a4
  C000f16c --> Cbd74745
  Cc07f315 --> C000f16c
  Cfc2a0ab --> Cc07f315
  C10d605e --> Cfc2a0ab
  C801b436 --> C10d605e
```
