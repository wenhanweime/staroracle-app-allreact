# 🍎 iOS项目配置说明

## 🎯 目标
在Xcode中集成原生ChatOverlay插件

## 📋 配置步骤

### 1. 打开Xcode项目
```bash
npx cap open ios
```

### 2. 添加SwiftUI文件到项目
在Xcode中：
- 右键点击 `App/App` 文件夹
- 选择 "New Group"，命名为 "ChatOverlay"
- 将以下文件添加到该组：
  - `NativeChatOverlay.swift`
  - `ChatOverlayPlugin.swift`

### 3. 在Plugin.m中注册插件
文件：`ios/App/App/Plugin.m`
```objc
#import <Capacitor/Capacitor.h>

CAP_PLUGIN(ChatOverlayPlugin, "ChatOverlay",
  CAP_PLUGIN_METHOD(show, CAPPluginReturnPromise);
  CAP_PLUGIN_METHOD(hide, CAPPluginReturnPromise);
  CAP_PLUGIN_METHOD(sendMessage, CAPPluginReturnPromise);
)
```

### 4. 设置iOS部署目标
在项目设置中确保：
- iOS Deployment Target >= 14.0 (SwiftUI要求)
- Swift Language Version = Swift 5

### 5. 构建并测试
1. 在Xcode中按 ⌘+R 运行项目
2. 测试原生ChatOverlay功能
3. 验证动画效果和性能

## 🔧 可能遇到的问题

### SwiftUI @available警告
如果遇到版本兼容性警告，在每个SwiftUI组件前添加：
```swift
@available(iOS 14.0, *)
```

### 插件未注册
确保Plugin.m文件正确配置了插件导出

### 动画性能
SwiftUI动画应该比React动画更流畅，如果有性能问题：
- 检查动画参数设置
- 确保使用了正确的动画修饰符

## 📱 测试要点

- [x] 浮窗显示/隐藏动画
- [x] 拖拽交互手势
- [x] 消息发送和接收
- [x] 与输入框的协调工作
- [x] 性能对比（应显著优于React版本）