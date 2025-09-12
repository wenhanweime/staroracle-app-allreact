# Git 历史汇总（表格预览）

- 字段: short_hash, date, author, type, scope, breaking, subject, files_changed, insertions, deletions, tags, branches, remotes, reachable, reflog_only
- 生成时间: 2025-09-07T14:39:33+08:00

```tsv
short_hash	date	author	type	scope	breaking	subject	files_changed	insertions	deletions	tags	branches	remotes	reachable	reflog_only
4bd6d4b	2025-09-07T03:34:38+08:00	git stash	merge		no	On (no branch): wip:  emp before swi ch  o main	3	307	184				yes	no
cf2c9bd	2025-09-07T03:34:38+08:00	git stash	other		no	index on (no branch): 7ec8266 chore(参数): 锁定银河默认参数为指定数值 n n- 核心密度: 0.7, 核心半径: 25 n- 旋臂数量: 5, 旋臂密度: 0.6, 螺旋紧密度: 0.29 n- 内侧宽度: 29, 外侧宽度: 53, 宽度增长: 2.5 n- 臂间基础密度: 0.15, 山坡平缓度: 7.3 n- 淡化起始: 0.5, 淡化结束: 1.54 n- 背景密度: 0.00045 n- 垂直抖动强度: 17, 噪声缩放: 0.041, 噪声强度: 0.9 n- 星大小倍数: 旋臂 0.8, 臂间 1, 背景 0.7 n n后续不再轻易修改默认参数，如需变更将另行说明。	0	0	0				yes	no
49c0fa9	2025-09-07T03:34:38+08:00	git stash	merge		no	un racked files on (no branch): 7ec8266 chore(参数): 锁定银河默认参数为指定数值 n n- 核心密度: 0.7, 核心半径: 25 n- 旋臂数量: 5, 旋臂密度: 0.6, 螺旋紧密度: 0.29 n- 内侧宽度: 29, 外侧宽度: 53, 宽度增长: 2.5 n- 臂间基础密度: 0.15, 山坡平缓度: 7.3 n- 淡化起始: 0.5, 淡化结束: 1.54 n- 背景密度: 0.00045 n- 垂直抖动强度: 17, 噪声缩放: 0.041, 噪声强度: 0.9 n- 星大小倍数: 旋臂 0.8, 臂间 1, 背景 0.7 n n后续不再轻易修改默认参数，如需变更将另行说明。	0	0	0				yes	no
7ec8266	2025-09-06T13:31:51+08:00	pot	chore	参数	no	chore(参数): 锁定银河默认参数为指定数值 n n- 核心密度: 0.7, 核心半径: 25 n- 旋臂数量: 5, 旋臂密度: 0.6, 螺旋紧密度: 0.29 n- 内侧宽度: 29, 外侧宽度: 53, 宽度增长: 2.5 n- 臂间基础密度: 0.15, 山坡平缓度: 7.3 n- 淡化起始: 0.5, 淡化结束: 1.54 n- 背景密度: 0.00045 n- 垂直抖动强度: 17, 噪声缩放: 0.041, 噪声强度: 0.9 n- 星大小倍数: 旋臂 0.8, 臂间 1, 背景 0.7 n n后续不再轻易修改默认参数，如需变更将另行说明。	1	63	22		params-lock-7ec8266;		yes	no
cbb1168	2025-09-06T13:19:47+08:00	pot	feat	视觉	no	fea (视觉): 按星系结构分色并加入前台开关 n n- 新增结构着色开关（默认关闭），启用后按核心/臂脊/臂内/臂边/尘埃/外围分类上色 n- 保持背景全屏白星、不随缩放/旋转；主体仍按差速旋转呈现 n- 保留固定随机种子，保证同参数形态一致 n- 未开启开关时维持白星风格，便于性能与形态对比	1	42	2		params-lock-7ec8266;		yes	no
8582f39	2025-09-06T02:05:22+08:00	pot	feat	visual	no	fea (visual): replace dual-layer spin wi h differen ial ro a ion by radial bands; de erminis ic RNG for s able morphology; keep background full-screen	1	36	22		params-lock-7ec8266;		yes	no
e14b1d5	2025-09-06T01:57:05+08:00	pot	chore	galaxy	no	chore(galaxy): upda e defaul s per la es  user params (galaxyScale=0.68, armDensi y=0.70, spiralB=0.21, inner=55, ou er=101, fade 0.2-1.36, bgDensi y=0.0006, ji  er=16, noiseS reng h=0.9, mul ipliers 0.8/0.9) and sync docs	2	88	57		params-lock-7ec8266;		yes	no
17442cb	2025-09-06T01:35:58+08:00	pot	chore	galaxy	no	chore(galaxy): upda e defaul s per la es   uning (armDensi y=0.65, innerWid h=56, grow h=2.8, bgDensi y=0.00057, noiseScale=0.049, galaxyScale=0.6) and docs	2	18	13		params-lock-7ec8266;		yes	no
3c8d835	2025-09-06T01:18:41+08:00	pot	feat	visual	no	fea (visual): add galaxyScale (defaul  0.618) and apply scale around cen er; expose slider in debug panel	1	6	0		params-lock-7ec8266;		yes	no
a6a062b	2025-09-06T01:06:20+08:00	pot	chore	galaxy	no	chore(galaxy): apply user-adjus ed defaul s (ou erWid h=53, bgDensi y=0.00045, noiseScale=0.006, e c.) and upda e docs/log	3	9	6		params-lock-7ec8266;		yes	no
ea08028	2025-09-06T00:58:22+08:00	pot	feat	debug	no	fea (debug): add pause-ro a ion  oggle in galaxy debug panel (defaul  paused when debugging)	3	92	12		params-lock-7ec8266;		yes	no
daa4cc0	2025-09-06T00:41:40+08:00	pot	chore	galaxy	no	chore(galaxy): se  homepage galaxy defaul s  o user-provided params and upda e doc	2	136	26		params-lock-7ec8266;		yes	no
6b9db23	2025-09-06T00:24:27+08:00	pot	fix	visual	no	fix(visual): align galaxy params  o saved ref and remove glow/overlays	1	31	131		params-lock-7ec8266;		yes	no
7dd6d1a	2025-09-05T23:59:43+08:00	pot	feat	visual	no	fea (visual): ro a ing living galaxy wi h brea hing and 3-arm pale  e	2	210	74		params-lock-7ec8266;		yes	no
2e9bb34	2025-09-05T23:46:02+08:00	pot	feat	galaxy	no	fea (galaxy): living galaxy in egra ion and in erac ion loop	24	19631	28		params-lock-7ec8266;		yes	no
00aaeff	2025-09-05T01:40:21+08:00	codex-cli	style		no	s yle: 调整搜索框与编辑按钮间距为30px n n- 顶栏使用 gap-[30px] 并移除输入容器 mr，确保两者间固定30px间距 n- 保持圆角与边框样式不变	1	3	3		main;	origin/HEAD;origin/main;	yes	no
27adf62	2025-09-05T01:31:58+08:00	codex-cli	style		no	s yle: 顶栏搜索框宽度与间距优化 n n- 使用 flex-1 + mr-2 + gap-3 替代固定 calc 宽度，避免与右侧按钮交叉 n- 保持圆角与边框样式不变，提升自适应布局稳定性	1	2	2		main;	origin/HEAD;origin/main;	yes	no
fd54381	2025-09-05T01:25:56+08:00	codex-cli	fix		no	fix: 侧边栏搜索框圆角被重置覆盖的问题 n n- 为搜索输入增加 sidebar-search-inpu  类并在全局样式中以 !impor an  强制圆角 n- 兼容 iOS 的输入重置（appearance/border-radius），确保真机圆角生效 n- 更新文档记录该覆盖策略	3	16	2		main;	origin/HEAD;origin/main;	yes	no
c209613	2025-09-05T01:17:39+08:00	codex-cli	style		no	s yle: 搜索框圆角与宽度微调 n n- 顶栏容器增加 gap，搜索输入改为 rounded-full 并缩短整体宽度（比按钮多预留一个图标宽度） n- 通过 calc(100% - 2.5rem) 精准控制右侧留白，避免与编辑按钮贴合	1	2	2		main;	origin/HEAD;origin/main;	yes	no
741251e	2025-09-05T01:13:50+08:00	codex-cli	style		no	s yle: 优化侧边栏搜索框与新建按钮样式 n n- 搜索输入改为圆角并加边框，父容器加 gap 保留与按钮间距 n- 将新建按钮替换为 lucide-reac  的 SquarePen 图标，并增强 hover/边框视觉 n- 文档记录样式与布局的调整	2	9	8		main;	origin/HEAD;origin/main;	yes	no
edf6a0b	2025-09-05T01:09:54+08:00	codex-cli	feat		no	fea : 侧边栏布局改版（搜索 + 新建） n n- 移除列表上方“新建会话”按钮；顶部右侧改为铅笔图标并触发新建 n- 顶部标题替换为搜索框，支持按标题关键字过滤 n- 保持遮罩点击可关闭抽屉 n- 文档追加布局调整记录	2	32	13		main;	origin/HEAD;origin/main;	yes	no
353062b	2025-09-05T01:03:56+08:00	codex-cli	feat		no	fea : 侧边栏滚动优化 n n- DrawerMenu 抽屉容器改为 flex 列布局，中部列表区域启用 overflow-y-au o 并支持 iOS 惯性滚动 n- 文档追加滚动优化的修改日志	2	10	3		main;	origin/HEAD;origin/main;	yes	no
973dd36	2025-09-05T01:01:30+08:00	codex-cli	feat		no	fea : 历史会话AI标题总结与侧边交互修复 n n- 移除侧栏历史对话重命名/删除按钮，点击直接切换并唤起浮窗 n- 新增基于弹幕链路的会话标题AI总结（取消条数阈值，所有会话均总结） n- iOS 插件：lis Sessions/sessionsChanged 返回 messagesCoun /rawTi le/displayTi le/hasCus omTi le；新增 ge SessionSummaryCon ex ；会话存储变更广播 n- 展示标题兜底逻辑优化，优先显示持久化标题；过渡展示使用裁剪文本 n- Web s ub 同步补齐接口避免开发态报错 n- 文档：更新 历史会话和会话能力升级.md 变更记录	11	749	12		main;	origin/HEAD;origin/main;	yes	no
4b9bb00	2025-09-04T02:15:06+08:00	codex-cli	perf	ios-startup	no	perf(ios-s ar up): 立即隐藏启动屏以消除首次点击输入框的延迟	1	6	6		main;	origin/HEAD;origin/main;	yes	no
d895a13	2025-09-04T02:05:49+08:00	codex-cli	fix	ios-first-collapse	no	fix(ios-firs -collapse): 首次收缩在键盘可见时也上移输入框为浮窗预留空间（仅一次）	1	23	4		main;	origin/HEAD;origin/main;	yes	no
9ec8afe	2025-09-04T02:00:37+08:00	codex-cli	chore	ref	no	chore(ref): rever  unin ended changes  o ref/s elloracle-home. sx (no func ional impac )	1	2	14		main;	origin/HEAD;origin/main;	yes	no
1ed95eb	2025-09-04T01:59:30+08:00	codex-cli	fix	ios-first-collapse	no	fix(ios-firs -collapse): 仅修复首次收缩的对齐	3	26	2		main;	origin/HEAD;origin/main;	yes	no
40de917	2025-09-04T01:42:52+08:00	codex-cli	fix	ios	no	fix(ios): 仅首次收缩延迟由输入框实际位置驱动对齐，之后保持原逻辑	1	34	15		main;	origin/HEAD;origin/main;	yes	no
08bdbb9	2025-09-04T01:36:26+08:00	codex-cli	other		no	Rever  "fix(ios): 修正收缩定位公式为‘浮窗在输入框上方’并随实际位置联动"	2	11	13		main;	origin/HEAD;origin/main;	yes	no
2c35362	2025-09-04T01:34:55+08:00	codex-cli	fix	ios	no	fix(ios): 修正收缩定位公式为‘浮窗在输入框上方’并随实际位置联动	2	13	11		main;	origin/HEAD;origin/main;	yes	no
```
