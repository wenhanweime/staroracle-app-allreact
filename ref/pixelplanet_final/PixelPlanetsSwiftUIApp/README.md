# PixelPlanetsSwiftUIApp (Xcode 工程)

该目录是一个标准的 Xcode iOS App 项目，已经将 `../PixelPlanetsSwift` 作为本地 Swift Package 依赖引入，并复用了 SwiftUI 控制台 / 预览界面。打开方法：

1. `open PixelPlanetsSwiftUIApp/PixelPlanetsSwiftUIApp.xcodeproj`
2. 在 Scheme 菜单选择 `PixelPlanetsSwiftUIApp`，Destination 选择任意 iOS 模拟器（iPhone 15 Pro 等）。
3. `⌘R` 运行即可看到控制台 UI；右侧的 `PlanetCanvasView` 已通过 OpenGL ES 渲染 Rivers 行星的实际着色器效果（与 Godot/WebGL 版本一致），并支持实时调参/动画。

如需修改行星逻辑，继续在 `../PixelPlanetsSwift` 包中编辑；SwiftUI 工程会自动引用最新代码。
