# 首页星系点击点亮实现说明

## 数据准备
- `src/utils/galaxyModel.ts` 在生成星点时为每个点分配唯一 `id`，并依据结构层 `layer` 同时提供基础颜色与高亮颜色。
- `src/components/GalaxyLightweight.tsx` 将星点渲染为 DOM 元素，并通过 `data-star-id`、`data-base-color`、`data-lit-color` 等属性暴露给后续交互层查找；所有星点默认以灰度风格显示。

## 点击触发流程
1. `GalaxyDOMPulseOverlay.tsx` 监听点击事件，基于点击位置筛选附近星点，并产生彩色脉冲动画。
2. 脉冲动画记录命中的星点 `id`，并通过 `onHighlight` 回调传回父组件。
3. 同时调用 `onGalaxyClick`，将点击坐标、区域及窗口尺寸返还，用于后续热点命中与灵感卡片调用。

## 持久高亮
- `InteractiveGalaxyBackground.tsx` 的 `handleHighlightPersist` 接收星点 `id`，利用 `document.querySelector([data-star-id=…])` 获取 DOM 元素。
- `burstHighlight` 对命中的星点执行 Web Animations API：先短暂放大（scale≈1.16）、提升亮度阴影，再缓动至稳定状态（scale≈1.08，保留彩色阴影）。
- 动画结束后，星点保持高亮状态，直至下一次更新或页面刷新。

## 灵感卡片
- `handleGalaxyTap` 在点亮流程中同步触发 `clickHs` 和 `drawInspirationCard`，并根据点击区域延时弹出灵感卡片，延时与脉冲持续时长保持一致（默认为 1100ms）。

## 关键参数
- `glowCfg` 提供点击半径、动画时长等可调参数，影响脉冲动画与卡片延时。
- 如需调整高亮色彩，可在“高亮配色”面板/本地配置中修改 `litPalette`，调色后实时生效。
