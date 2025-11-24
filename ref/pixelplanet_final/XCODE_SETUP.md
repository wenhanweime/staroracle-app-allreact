# Xcode 设置指南

如果项目在 Xcode 中无法正常识别 Swift Package 依赖，请按照以下步骤操作：

## 步骤 1：打开项目

1. 打开 Finder，导航到 `pixelplanet_final` 文件夹
2. 双击 `PixelPlanetsSwiftUIApp/PixelPlanetsSwiftUIApp.xcodeproj` 文件
3. 等待 Xcode 加载项目

## 步骤 2：检查并重新链接 Swift Package

### 如果 Xcode 显示包依赖错误：

1. **在项目导航器中**
   - 点击左侧最顶部的项目图标（蓝色图标，显示 "PixelPlanetsSwiftUIApp"）

2. **选择项目设置**
   - 在中间面板，确保选中了 `PROJECT` 下的 `PixelPlanetsSwiftUIApp`（不是 TARGETS）
   - 如果看不到，点击项目导航器中最顶部的蓝色图标

3. **打开 Package Dependencies**
   - 在中间面板的顶部，找到 `Package Dependencies` 标签页
   - 点击进入

4. **删除旧的包引用（如果存在）**
   - 如果列表中已经有 `PixelPlanetsSwift` 但显示错误
   - 选中它，点击下方的 `-` 按钮删除

5. **添加本地包**
   - 点击 `+` 按钮
   - 选择 `Add Local...`
   - 在文件选择器中，导航到 `pixelplanet_final/PixelPlanetsSwift` 文件夹
   - 点击 `Add Package` 按钮

6. **添加产品到 Target**
   - 在弹出窗口中，确保 `PixelPlanetsCore` 产品被选中
   - 在右侧的 "Add to Target" 列中，勾选 `PixelPlanetsSwiftUIApp`
   - 点击 `Add Package`

## 步骤 3：验证依赖

1. **检查 Target 设置**
   - 在项目导航器中，展开 `TARGETS`
   - 选择 `PixelPlanetsSwiftUIApp`
   - 切换到 `General` 标签页
   - 向下滚动到 `Frameworks, Libraries, and Embedded Content` 部分
   - 应该能看到 `PixelPlanetsCore` 在列表中

2. **检查 Package Dependencies**
   - 在 `TARGETS` → `PixelPlanetsSwiftUIApp` → `Package Dependencies` 标签页
   - 应该能看到 `PixelPlanetsSwift` 包和 `PixelPlanetsCore` 产品

## 步骤 4：清理并构建

1. **清理构建缓存**
   - 按 `⌘ShiftK` 或选择 `Product` → `Clean Build Folder`
   - 如果提示，点击 `Clean`

2. **重新构建**
   - 按 `⌘B` 或选择 `Product` → `Build`
   - 等待构建完成

3. **检查构建错误**
   - 如果还有错误，查看错误信息
   - 常见问题：
     - 包路径错误：重复步骤 2，确保选择了正确的 `PixelPlanetsSwift` 文件夹
     - 模块找不到：确保在步骤 6 中正确添加了 `PixelPlanetsCore` 到 Target

## 步骤 5：运行项目

1. **选择运行目标**
   - 在 Xcode 顶部工具栏，点击 Scheme 下拉菜单
   - 选择 `PixelPlanetsSwiftUIApp`
   - 点击 Destination 下拉菜单
   - 选择任意 iOS 模拟器（如 `iPhone 15 Pro`）

2. **运行**
   - 按 `⌘R` 或点击左上角的播放按钮
   - 等待模拟器启动并运行应用

## 常见问题

### Q: Xcode 提示 "No such module 'PixelPlanetsCore'"

**A:** 包依赖没有正确链接。请按照步骤 2 重新添加本地包。

### Q: 构建时提示找不到文件

**A:** 
1. 确保 `PixelPlanetsSwift` 文件夹在 `pixelplanet_final` 目录下
2. 检查相对路径是否正确（应该是 `../PixelPlanetsSwift`）

### Q: 包依赖显示为红色

**A:**
1. 删除包依赖（步骤 2.4）
2. 重新添加（步骤 2.5-2.6）
3. 清理并重新构建（步骤 4）

### Q: 模拟器无法启动

**A:**
1. 确保 Xcode Command Line Tools 已安装
2. 在 Xcode 中，选择 `Xcode` → `Settings` → `Platforms`
3. 下载所需的 iOS 模拟器运行时

## 验证项目结构

确保你的文件夹结构如下：

```
pixelplanet_final/
├── PixelPlanetsSwift/              ← Swift Package
│   ├── Package.swift
│   └── Sources/
│       └── PixelPlanetsCore/
└── PixelPlanetsSwiftUIApp/         ← iOS App
    └── PixelPlanetsSwiftUIApp.xcodeproj
```

如果结构正确，按照上述步骤操作后应该可以正常运行。

