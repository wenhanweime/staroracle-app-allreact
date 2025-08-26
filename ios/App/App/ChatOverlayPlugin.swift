import Foundation
import Capacitor

@objc(ChatOverlayPlugin)
public class ChatOverlayPlugin: CAPPlugin, CAPBridgedPlugin {
    
    // 插件配置
    public let identifier = "ChatOverlayPlugin"
    public let jsName = "ChatOverlay"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "show", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "hide", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "updateMessages", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "setLoading", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "setConversationTitle", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "setKeyboardHeight", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "setViewportHeight", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "setInitialInput", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "setFollowUpQuestion", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "isVisible", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "sendMessage", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "receiveAIResponse", returnType: CAPPluginReturnPromise)
    ]
    
    // 业务逻辑管理器
    private lazy var overlayManager = ChatOverlayManager()
    
    public override init() {
        super.init()
        NSLog("🎯 ChatOverlayPlugin (CAPBridgedPlugin架构) 初始化成功!")
    }
    
    // MARK: - Capacitor方法实现
    
    @objc func show(_ call: CAPPluginCall) {
        NSLog("🎯 ChatOverlay show方法被调用!")
        let animated = call.getBool("animated") ?? true
        
        DispatchQueue.main.async {
            self.overlayManager.show(animated: animated) { success in
                if success {
                    call.resolve(["success": true, "visible": true])
                } else {
                    call.reject("显示浮窗失败")
                }
            }
        }
    }
    
    @objc func hide(_ call: CAPPluginCall) {
        NSLog("🎯 ChatOverlay hide方法被调用!")
        let animated = call.getBool("animated") ?? true
        
        DispatchQueue.main.async {
            self.overlayManager.hide(animated: animated) {
                call.resolve(["success": true, "visible": false])
            }
        }
    }
    
    @objc func updateMessages(_ call: CAPPluginCall) {
        NSLog("🎯 ChatOverlay updateMessages方法被调用!")
        guard let messagesArray = call.getArray("messages") as? [[String: Any]] else {
            call.reject("消息数组格式不正确")
            return
        }
        
        let messages = messagesArray.compactMap { msgData -> ChatMessage? in
            guard let id = msgData["id"] as? String,
                  let text = msgData["text"] as? String,
                  let isUser = msgData["isUser"] as? Bool,
                  let timestamp = msgData["timestamp"] as? Double else {
                return nil
            }
            return ChatMessage(id: id, text: text, isUser: isUser, timestamp: timestamp)
        }
        
        overlayManager.updateMessages(messages)
        call.resolve(["success": true])
    }
    
    @objc func setLoading(_ call: CAPPluginCall) {
        let loading = call.getBool("loading") ?? false
        NSLog("🎯 ChatOverlay setLoading: \(loading)")
        
        overlayManager.setLoading(loading)
        call.resolve(["success": true])
    }
    
    @objc func setConversationTitle(_ call: CAPPluginCall) {
        let title = call.getString("title") ?? ""
        NSLog("🎯 ChatOverlay setConversationTitle: \(title)")
        
        overlayManager.setConversationTitle(title)
        call.resolve(["success": true])
    }
    
    @objc func setKeyboardHeight(_ call: CAPPluginCall) {
        let height = call.getFloat("height") ?? 0
        NSLog("🎯 ChatOverlay setKeyboardHeight: \(height)")
        
        overlayManager.setKeyboardHeight(CGFloat(height))
        call.resolve(["success": true])
    }
    
    @objc func setViewportHeight(_ call: CAPPluginCall) {
        let height = call.getFloat("height") ?? 0
        NSLog("🎯 ChatOverlay setViewportHeight: \(height)")
        
        overlayManager.setViewportHeight(CGFloat(height))
        call.resolve(["success": true])
    }
    
    @objc func setInitialInput(_ call: CAPPluginCall) {
        let input = call.getString("input") ?? ""
        NSLog("🎯 ChatOverlay setInitialInput: \(input)")
        
        overlayManager.setInitialInput(input)
        call.resolve(["success": true])
    }
    
    @objc func setFollowUpQuestion(_ call: CAPPluginCall) {
        let question = call.getString("question") ?? ""
        NSLog("🎯 ChatOverlay setFollowUpQuestion: \(question)")
        
        overlayManager.setFollowUpQuestion(question)
        call.resolve(["success": true])
    }
    
    @objc func isVisible(_ call: CAPPluginCall) {
        let visible = overlayManager.getVisibility()
        call.resolve(["visible": visible])
    }
    
    // 保持向后兼容的方法
    @objc func sendMessage(_ call: CAPPluginCall) {
        NSLog("🎯 ChatOverlay sendMessage方法被调用(向后兼容)!")
        call.resolve(["success": true])
    }
    
    @objc func receiveAIResponse(_ call: CAPPluginCall) {
        call.resolve(["success": true])
    }
}