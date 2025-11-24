# PixelPlanets Final - 独立运行版本

这是一个整理好的独立版本，包含了所有必要的依赖，可以直接运行。

## 项目结构

```
pixelplanet_final/
├── PixelPlanetsSwift/          # Swift Package（核心库）
│   ├── Package.swift
│   └── Sources/
│       └── PixelPlanetsCore/   # 核心行星渲染库
└── PixelPlanetsSwiftUIApp/     # iOS SwiftUI 应用
    └── PixelPlanetsSwiftUIApp.xcodeproj
```

## 运行步骤

### 方法 1：直接打开 Xcode 项目（推荐）

1. **打开项目**
   ```bash
   cd pixelplanet_final
   open PixelPlanetsSwiftUIApp/PixelPlanetsSwiftUIApp.xcodeproj
   ```

2. **在 Xcode 中重新链接 Swift Package（如果需要）**
   - 如果 Xcode 提示找不到包依赖，请按以下步骤操作：
     - 在 Xcode 左侧项目导航器中，选择项目根节点 `PixelPlanetsSwiftUIApp`
     - 选择 `TARGETS` → `PixelPlanetsSwiftUIApp`
     - 切换到 `Package Dependencies` 标签页
     - 如果看到 `PixelPlanetsSwift` 包，点击它，然后点击 `-` 删除
     - 点击 `+` 添加本地包
     - 选择 `Add Local...`
     - 导航到 `pixelplanet_final/PixelPlanetsSwift` 文件夹并选择
     - 确保 `PixelPlanetsCore` 产品被添加到项目中

3. **选择运行目标**
   - 在 Xcode 顶部工具栏，选择 Scheme: `PixelPlanetsSwiftUIApp`
   - 选择 Destination: 任意 iOS 模拟器（如 iPhone 15 Pro）

4. **运行项目**
   - 按 `⌘R` 或点击运行按钮
   - 应用将在模拟器中启动

### 方法 2：使用命令行构建（可选）

```bash
cd pixelplanet_final/PixelPlanetsSwift
swift build
```

## 功能特性

- ✅ 完整的行星渲染系统
- ✅ 支持多种行星类型（Terran Wet、Gas Giant、Star 等）
- ✅ 实时参数调整
- ✅ 动画控制
- ✅ 颜色调色板预览

## 依赖说明

- **PixelPlanetsSwift**: Swift Package，包含所有行星渲染逻辑和着色器
- **PixelPlanetsSwiftUIApp**: iOS 应用，提供 SwiftUI 界面和 OpenGL ES 渲染

两个项目已经正确配置了相对路径依赖，无需额外配置。

## 注意事项

- 确保使用 Xcode 15.0 或更高版本
- iOS 部署目标：iOS 17.0
- 如果遇到包依赖问题，请按照上面的步骤重新链接

## 故障排除

### 问题：Xcode 找不到 PixelPlanetsCore 模块

**解决方案：**
1. 在 Xcode 中，选择 `File` → `Packages` → `Reset Package Caches`
2. 然后选择 `File` → `Packages` → `Resolve Package Versions`
3. 如果问题仍然存在，按照"方法 1"中的步骤重新添加本地包

### 问题：构建错误

**解决方案：**
1. 清理构建：`⌘ShiftK` 或 `Product` → `Clean Build Folder`
2. 重新构建：`⌘B` 或 `Product` → `Build`

## 开发说明

- 修改行星逻辑：编辑 `PixelPlanetsSwift/Sources/PixelPlanetsCore/` 中的文件
- 修改 UI：编辑 `PixelPlanetsSwiftUIApp/PixelPlanetsSwiftUIApp/` 中的 SwiftUI 文件
- SwiftUI 应用会自动引用最新的包代码

