# 📚 Capacitor iOS Swift插件开发完整指南

> 基于实战经验总结的Swift原生插件最佳实践

## 📋 目录
- [快速开始](#快速开始)
- [插件架构设计](#插件架构设计)
- [详细实现步骤](#详细实现步骤)
- [常见问题排查](#常见问题排查)
- [最佳实践](#最佳实践)
- [完整示例](#完整示例)

---

## 🚀 快速开始

### 核心概念
- **Capacitor插件** = JavaScript调用 + Swift实现 + 双向桥接
- **现代方式**：使用 `CAPPlugin` + `CAPBridgedPlugin` 协议
- **避免过时**：不使用 `CAP_PLUGIN` 宏

### 基础文件结构
```
ios/App/App/
├── AppDelegate.swift (修改) - 插件注册中心
├── Plugins/
│   ├── MyPlugin/
│   │   ├── MyPlugin.swift - Capacitor桥接
│   │   └── MyManager.swift - 业务逻辑(可选)
```

---

## 🏗️ 插件架构设计

### 文件数量选择

#### 1️⃣ 简单插件 - 单文件架构
**适用场景：** 工具类插件、简单API调用、数据处理
```swift
// StoragePlugin.swift
@objc(StoragePlugin)
public class StoragePlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "StoragePlugin"
    public let jsName = "Storage"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "set", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "get", returnType: CAPPluginReturnPromise)
    ]
    
    @objc func set(_ call: CAPPluginCall) {
        guard let key = call.getString("key"),
              let value = call.getString("value") else {
            call.reject("参数缺失")
            return
        }
        UserDefaults.standard.set(value, forKey: key)
        call.resolve(["success": true])
    }
    
    @objc func get(_ call: CAPPluginCall) {
        guard let key = call.getString("key") else {
            call.reject("key参数缺失")
            return
        }
        let value = UserDefaults.standard.string(forKey: key)
        call.resolve(["value": value ?? ""])
    }
}
```

#### 2️⃣ 复杂插件 - 双文件架构 ⭐️ 推荐
**适用场景：** UI组件、相机、地图、复杂交互

**桥接文件：** `ChatOverlayPlugin.swift`
```swift
@objc(ChatOverlayPlugin)
public class ChatOverlayPlugin: CAPPlugin, CAPBridgedPlugin {
    
    // 插件配置
    public let identifier = "ChatOverlayPlugin"
    public let jsName = "ChatOverlay"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "show", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "hide", returnType: CAPPluginReturnPromise)
    ]
    
    // 业务逻辑管理器
    private lazy var overlayManager = ChatOverlayManager()
    
    // Capacitor方法实现
    @objc func show(_ call: CAPPluginCall) {
        let message = call.getString("message") ?? ""
        
        DispatchQueue.main.async {
            self.overlayManager.show(message: message) { [weak self] result in
                if result {
                    call.resolve(["success": true])
                } else {
                    call.reject("显示失败")
                }
            }
        }
    }
    
    @objc func hide(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            self.overlayManager.hide()
            call.resolve(["success": true])
        }
    }
}
```

**业务逻辑文件：** `ChatOverlayManager.swift`
```swift
import SwiftUI
import UIKit

public class ChatOverlayManager {
    private var overlayWindow: UIWindow?
    
    func show(message: String, completion: @escaping (Bool) -> Void) {
        // 复杂的UI实现
        let overlayView = ChatOverlayView(
            message: message,
            onClose: { [weak self] in
                self?.hide()
            }
        )
        
        // 创建UI窗口
        overlayWindow = UIWindow(frame: UIScreen.main.bounds)
        overlayWindow?.rootViewController = UIHostingController(rootView: overlayView)
        overlayWindow?.makeKeyAndVisible()
        
        // 动画显示
        overlayWindow?.alpha = 0
        UIView.animate(withDuration: 0.3) {
            self.overlayWindow?.alpha = 1
        } completion: { _ in
            completion(true)
        }
    }
    
    func hide() {
        UIView.animate(withDuration: 0.3) {
            self.overlayWindow?.alpha = 0
        } completion: { _ in
            self.overlayWindow?.isHidden = true
            self.overlayWindow = nil
        }
    }
}

// SwiftUI视图组件
struct ChatOverlayView: View {
    let message: String
    let onClose: () -> Void
    
    var body: some View {
        VStack {
            Text(message)
                .font(.title2)
                .padding()
            
            Button("关闭") {
                onClose()
            }
            .padding()
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 8)
    }
}
```

---

## 📋 详细实现步骤

### Step 1: JavaScript端插件定义

**创建插件接口：** `src/plugins/MyPlugin.ts`
```typescript
import { registerPlugin } from '@capacitor/core';

export interface MyPlugin {
  doSomething(options: { message: string }): Promise<{ result: string }>;
}

export const MyPluginInstance = registerPlugin<MyPlugin>('MyPlugin', {
  web: () => ({
    doSomething: async (options) => ({ 
      result: `Web实现: ${options.message}` 
    })
  })
});
```

### Step 2: Swift插件实现

**创建Swift插件：** `ios/App/App/Plugins/MyPlugin.swift`
```swift
import Capacitor

@objc(MyPlugin)
public class MyPlugin: CAPPlugin, CAPBridgedPlugin {
    
    public let identifier = "MyPlugin"
    public let jsName = "MyPlugin"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "doSomething", returnType: CAPPluginReturnPromise)
    ]
    
    public override init() {
        super.init()
        NSLog("🎯 MyPlugin 初始化成功")
    }
    
    @objc func doSomething(_ call: CAPPluginCall) {
        NSLog("🎯 MyPlugin doSomething 被调用")
        
        guard let message = call.getString("message") else {
            call.reject("message参数缺失")
            return
        }
        
        // 执行业务逻辑
        let result = "iOS处理: \(message)"
        
        // 返回结果
        call.resolve([
            "result": result
        ])
    }
}
```

### Step 3: 插件注册配置

**修改AppDelegate：** `ios/App/App/AppDelegate.swift`
```swift
import UIKit
import Capacitor

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // 设置自定义视图控制器来注册插件
        setupCustomViewController()
        
        return true
    }
    
    private func setupCustomViewController() {
        window = UIWindow(frame: UIScreen.main.bounds)
        let customViewController = MainViewController()
        window?.rootViewController = customViewController
        window?.makeKeyAndVisible()
    }
}
```

**创建主视图控制器：** `ios/App/App/MainViewController.swift`
```swift
import UIKit
import Capacitor

class MainViewController: CAPBridgeViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSLog("🎯 MainViewController 加载完成")
    }
    
    override func capacitorDidLoad() {
        NSLog("🎯 开始注册自定义插件")
        
        // 注册所有自定义插件
        registerCustomPlugins()
        
        super.capacitorDidLoad()
    }
    
    private func registerCustomPlugins() {
        // 注册插件实例
        bridge?.registerPluginInstance(MyPlugin())
        bridge?.registerPluginInstance(ChatOverlayPlugin())
        // ... 添加更多插件
        
        NSLog("🎯 所有插件注册完成")
    }
}
```

### Step 4: Xcode项目配置

1. **添加Swift文件到项目**
   - 在Xcode中右键 `App` 文件夹
   - 选择 "Add Files to 'App'..."
   - 选择Swift文件
   - ✅ 勾选 "Add to target: App"
   - ✅ 勾选 "Copy items if needed"

2. **验证文件添加成功**
   - 在Xcode左侧导航器中能看到文件
   - 文件图标不是灰色
   - 右侧属性面板显示 "Target Membership: App ✓"

### Step 5: 构建和测试

```bash
# 构建Web资源
npm run build

# 同步到iOS
npx cap sync ios

# 运行应用
npx cap run ios --target="设备ID"
```

---

## 🔍 常见问题排查

### 问题1: `{"code":"UNIMPLEMENTED"}` 错误

**症状：** JavaScript调用返回UNIMPLEMENTED
```javascript
MyPlugin.doSomething({message: "test"})  // 返回 {"code":"UNIMPLEMENTED"}
```

**排查步骤：**

1. **验证文件是否在Xcode项目中**
   ```bash
   # 在Xcode中检查文件是否存在且不是灰色
   ```

2. **验证插件是否被注册**
   ```bash
   # 启动日志监听
   xcrun simctl spawn [设备ID] log stream --predicate 'eventMessage contains "🎯"' --style syslog
   
   # 查看是否有注册成功的日志
   ```

3. **验证插件配置正确**
   ```swift
   // 检查jsName是否与JavaScript端一致
   public let jsName = "MyPlugin"  // 必须与registerPlugin()的名称一致
   ```

4. **验证方法签名正确**
   ```swift
   @objc func doSomething(_ call: CAPPluginCall) {  // @objc 必需
       // 方法名必须在pluginMethods中声明
   }
   ```

### 问题2: 插件注册代码未执行

**症状：** 没有看到插件初始化日志

**解决方案：**
1. 确保 `MainViewController` 被 `AppDelegate` 使用
2. 确保 `capacitorDidLoad()` 被调用
3. 添加调试日志验证执行流程

### 问题3: Swift编译错误

**常见错误及解决：**

```swift
// ❌ 错误：缺少@objc
func doSomething(_ call: CAPPluginCall) { }

// ✅ 正确：添加@objc
@objc func doSomething(_ call: CAPPluginCall) { }
```

```swift
// ❌ 错误：方法未在pluginMethods中声明
public let pluginMethods: [CAPPluginMethod] = []

// ✅ 正确：声明所有@objc方法
public let pluginMethods: [CAPPluginMethod] = [
    CAPPluginMethod(name: "doSomething", returnType: CAPPluginReturnPromise)
]
```

### 问题4: JavaScript端找不到插件

**症状：** `MyPlugin is undefined`

**解决方案：**
1. 确保使用 `registerPlugin()` 而不是直接访问 `Capacitor.Plugins`
2. 检查导入路径是否正确
3. 确保插件名称匹配

---

## ⭐ 最佳实践

### 1. 插件命名规范

```swift
// ✅ 推荐命名
@objc(ChatOverlayPlugin)
public class ChatOverlayPlugin: CAPPlugin, CAPBridgedPlugin {
    public let jsName = "ChatOverlay"  // JavaScript端名称
}
```

```typescript
// JavaScript端对应
export const ChatOverlay = registerPlugin<ChatOverlayPlugin>('ChatOverlay');
```

### 2. 错误处理

```swift
@objc func riskyMethod(_ call: CAPPluginCall) {
    // 参数验证
    guard let requiredParam = call.getString("required") else {
        call.reject("required参数缺失")
        return
    }
    
    // 异步操作错误处理
    someAsyncOperation { result in
        DispatchQueue.main.async {
            switch result {
            case .success(let data):
                call.resolve(["data": data])
            case .failure(let error):
                call.reject("操作失败: \(error.localizedDescription)")
            }
        }
    }
}
```

### 3. 线程安全

```swift
@objc func uiMethod(_ call: CAPPluginCall) {
    // UI操作必须在主线程
    DispatchQueue.main.async {
        // UI代码
        self.updateUserInterface()
        call.resolve(["success": true])
    }
}

@objc func backgroundMethod(_ call: CAPPluginCall) {
    // 耗时操作在后台线程
    DispatchQueue.global(qos: .background).async {
        let result = self.heavyComputation()
        
        DispatchQueue.main.async {
            call.resolve(["result": result])
        }
    }
}
```

### 4. 文件组织结构

```
ios/App/App/
├── AppDelegate.swift
├── MainViewController.swift
├── Plugins/
│   ├── Storage/
│   │   └── StoragePlugin.swift
│   ├── Camera/
│   │   ├── CameraPlugin.swift
│   │   └── CameraManager.swift
│   └── ChatOverlay/
│       ├── ChatOverlayPlugin.swift
│       ├── ChatOverlayManager.swift
│       └── Views/
│           └── ChatOverlayView.swift
```

### 5. 调试技巧

```swift
public override init() {
    super.init()
    NSLog("🎯 \(identifier) 插件初始化")
}

@objc func debugMethod(_ call: CAPPluginCall) {
    NSLog("🎯 \(identifier) debugMethod called with: \(call.options)")
    
    // 处理逻辑...
    
    NSLog("🎯 \(identifier) debugMethod completed")
    call.resolve(["success": true])
}
```

---

## 📖 完整示例

### 相机插件示例

**JavaScript定义：**
```typescript
// src/plugins/Camera.ts
import { registerPlugin } from '@capacitor/core';

export interface CameraPlugin {
  takePicture(): Promise<{ imagePath: string }>;
  selectFromGallery(): Promise<{ imagePath: string }>;
}

export const Camera = registerPlugin<CameraPlugin>('Camera', {
  web: () => ({
    takePicture: async () => ({ imagePath: 'web-camera-mock.jpg' }),
    selectFromGallery: async () => ({ imagePath: 'web-gallery-mock.jpg' })
  })
});
```

**Swift实现：**
```swift
// ios/App/App/Plugins/CameraPlugin.swift
import Capacitor
import UIKit
import AVFoundation

@objc(CameraPlugin)
public class CameraPlugin: CAPPlugin, CAPBridgedPlugin {
    
    public let identifier = "CameraPlugin"
    public let jsName = "Camera"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "takePicture", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "selectFromGallery", returnType: CAPPluginReturnPromise)
    ]
    
    private var currentCall: CAPPluginCall?
    
    @objc func takePicture(_ call: CAPPluginCall) {
        currentCall = call
        
        DispatchQueue.main.async {
            self.presentCamera()
        }
    }
    
    @objc func selectFromGallery(_ call: CAPPluginCall) {
        currentCall = call
        
        DispatchQueue.main.async {
            self.presentGallery()
        }
    }
    
    private func presentCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            currentCall?.reject("相机不可用")
            return
        }
        
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        
        bridge?.viewController?.present(picker, animated: true)
    }
    
    private func presentGallery() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        
        bridge?.viewController?.present(picker, animated: true)
    }
}

// MARK: - UIImagePickerControllerDelegate
extension CameraPlugin: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        picker.dismiss(animated: true)
        
        guard let image = info[.originalImage] as? UIImage else {
            currentCall?.reject("获取图片失败")
            return
        }
        
        // 保存图片并返回路径
        let imagePath = saveImage(image)
        currentCall?.resolve(["imagePath": imagePath])
        currentCall = nil
    }
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
        currentCall?.reject("用户取消")
        currentCall = nil
    }
    
    private func saveImage(_ image: UIImage) -> String {
        // 实现图片保存逻辑
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let imageName = "camera_\(Date().timeIntervalSince1970).jpg"
        let imagePath = "\(documentsPath)/\(imageName)"
        
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            try? imageData.write(to: URL(fileURLWithPath: imagePath))
        }
        
        return imagePath
    }
}
```

**使用方式：**
```typescript
// React组件中使用
import { Camera } from '../plugins/Camera';

const handleTakePicture = async () => {
  try {
    const result = await Camera.takePicture();
    console.log('图片路径:', result.imagePath);
  } catch (error) {
    console.error('拍照失败:', error);
  }
};
```

---

## 🎯 总结

### 开发流程快速检查清单

- [ ] 创建JavaScript插件定义 (`src/plugins/`)
- [ ] 创建Swift插件文件 (`ios/App/App/Plugins/`)
- [ ] 在Xcode中添加Swift文件到项目
- [ ] 在`MainViewController`中注册插件
- [ ] 运行 `npm run build && npx cap sync ios`
- [ ] 测试插件功能

### 关键要点

1. **现代架构**：使用 `CAPPlugin + CAPBridgedPlugin`
2. **文件分离**：复杂插件使用双文件架构
3. **集中注册**：在 `MainViewController.capacitorDidLoad()` 中注册
4. **错误处理**：完善的参数验证和异常处理
5. **线程安全**：UI操作在主线程，耗时操作在后台线程

### 调试流程

1. **验证文件在项目中**：Xcode文件导航器检查
2. **验证插件注册**：日志监听 `🎯` 标记
3. **验证JavaScript调用**：控制台输出检查
4. **验证返回值**：成功/失败响应检查

通过遵循这个指南，你可以高效地开发出稳定可靠的Capacitor iOS插件！🚀

---

## 📝 更新记录

**v1.0** - 2024年8月
- 基于ChatOverlay插件实战经验整理
- 包含完整的问题排查流程
- 提供最佳实践和完整示例

**特别感谢：** 本指南基于StarOracle项目中ChatOverlay插件的开发经验总结，经历了从UNIMPLEMENTED错误到成功实现的完整调试过程。