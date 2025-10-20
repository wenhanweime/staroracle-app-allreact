import Foundation
import Capacitor

@objc(InputDrawerPlugin)
public class InputDrawerPlugin: CAPPlugin, CAPBridgedPlugin {
    
    // 插件配置
    public let identifier = "InputDrawerPlugin"
    public let jsName = "InputDrawer"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "show", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "hide", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "setText", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getText", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "focus", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "blur", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "setBottomSpace", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "setPlaceholder", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "setHorizontalOffset", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "isVisible", returnType: CAPPluginReturnPromise)
    ]
    
    // 业务逻辑管理器
    private lazy var drawerManager: InputDrawerManager = {
        let manager = InputDrawerManager()
        manager.delegate = self // 设置代理
        return manager
    }()
    
    public override init() {
        super.init()
        NSLog("🎯 InputDrawerPlugin (CAPBridgedPlugin架构) 初始化成功!")
    }
    
    // MARK: - Capacitor方法实现
    
    @objc func show(_ call: CAPPluginCall) {
        NSLog("🎯 InputDrawer show方法被调用!")
        let animated = call.getBool("animated") ?? true
        
        DispatchQueue.main.async {
            self.drawerManager.show(animated: animated) { success in
                if success {
                    call.resolve(["success": true, "visible": true])
                } else {
                    call.reject("显示输入框失败")
                }
            }
        }
    }
    
    @objc func hide(_ call: CAPPluginCall) {
        NSLog("🎯 InputDrawer hide方法被调用!")
        let animated = call.getBool("animated") ?? true
        
        DispatchQueue.main.async {
            self.drawerManager.hide(animated: animated) {
                call.resolve(["success": true, "visible": false])
            }
        }
    }
    
    @objc func setText(_ call: CAPPluginCall) {
        NSLog("🎯 InputDrawer setText方法被调用!")
        guard let text = call.getString("text") else {
            call.reject("text参数缺失")
            return
        }
        
        DispatchQueue.main.async {
            self.drawerManager.setText(text)
            call.resolve(["success": true])
        }
    }
    
    @objc func getText(_ call: CAPPluginCall) {
        NSLog("🎯 InputDrawer getText方法被调用!")
        
        DispatchQueue.main.async {
            let text = self.drawerManager.getText()
            call.resolve(["text": text])
        }
    }
    
    @objc func focus(_ call: CAPPluginCall) {
        NSLog("🎯 InputDrawer focus方法被调用!")
        
        DispatchQueue.main.async {
            self.drawerManager.focus()
            call.resolve(["success": true])
        }
    }
    
    @objc func blur(_ call: CAPPluginCall) {
        NSLog("🎯 InputDrawer blur方法被调用!")
        
        DispatchQueue.main.async {
            self.drawerManager.blur()
            call.resolve(["success": true])
        }
    }
    
    @objc func setBottomSpace(_ call: CAPPluginCall) {
        NSLog("🎯 InputDrawer setBottomSpace方法被调用!")
        let space = call.getFloat("space") ?? 100
        
        DispatchQueue.main.async {
            self.drawerManager.setBottomSpace(CGFloat(space))
            call.resolve(["success": true])
        }
    }
    
    @objc func setPlaceholder(_ call: CAPPluginCall) {
        NSLog("🎯 InputDrawer setPlaceholder方法被调用!")
        guard let placeholder = call.getString("placeholder") else {
            call.reject("placeholder参数缺失")
            return
        }
        
        DispatchQueue.main.async {
            self.drawerManager.setPlaceholder(placeholder)
            call.resolve(["success": true])
        }
    }

    @objc func setHorizontalOffset(_ call: CAPPluginCall) {
        NSLog("🎯 InputDrawer setHorizontalOffset方法被调用!")
        let offset = CGFloat(call.getDouble("offset") ?? 0)
        let animated = call.getBool("animated") ?? true
        
        DispatchQueue.main.async {
            self.drawerManager.setHorizontalOffset(max(0, offset), animated: animated)
            call.resolve(["success": true])
        }
    }

    @objc func isVisible(_ call: CAPPluginCall) {
        NSLog("🎯 InputDrawer isVisible方法被调用!")
        let visible = drawerManager.getVisibility()
        call.resolve(["visible": visible])
    }
}

// MARK: - InputDrawerDelegate实现
extension InputDrawerPlugin: InputDrawerDelegate {
    
    public func inputDrawerDidSubmit(_ text: String) {
        NSLog("🎯 InputDrawer消息提交: \(text)")
        // 发送Capacitor事件到JavaScript端
        notifyListeners("messageSubmitted", data: [
            "text": text,
            "timestamp": Date().timeIntervalSince1970 * 1000 // 毫秒时间戳
        ])
    }
    
    public func inputDrawerDidChange(_ text: String) {
        NSLog("🎯 InputDrawer文本变化: \(text)")
        // 发送文本变化事件到JavaScript端
        notifyListeners("textChanged", data: [
            "text": text
        ])
    }
    
    public func inputDrawerDidFocus() {
        NSLog("🎯 InputDrawer获得焦点")
        notifyListeners("inputFocused", data: [:])
    }
    
    public func inputDrawerDidBlur() {
        NSLog("🎯 InputDrawer失去焦点")
        notifyListeners("inputBlurred", data: [:])
    }
}
