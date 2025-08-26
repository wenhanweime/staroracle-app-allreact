import Foundation
import Capacitor

@objc(ChatOverlayPlugin)
public class ChatOverlayPlugin: CAPPlugin, CAPBridgedPlugin {
    
    public let identifier = "ChatOverlayPlugin"
    public let jsName = "ChatOverlay"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "show", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "hide", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "sendMessage", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "receiveAIResponse", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "updateMessages", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "setLoading", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "setConversationTitle", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "setKeyboardHeight", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "setViewportHeight", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "setInitialInput", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "setFollowUpQuestion", returnType: CAPPluginReturnPromise)
    ]
    
    public override init() {
        super.init()
        NSLog("🎯 ChatOverlayPlugin (Swift现代版本) 已初始化!")
    }
    
    @objc func show(_ call: CAPPluginCall) {
        NSLog("🎯 ChatOverlay show方法被调用!")
        call.resolve(["success": true])
    }
    
    @objc func hide(_ call: CAPPluginCall) {
        NSLog("🎯 ChatOverlay hide方法被调用!")
        call.resolve(["success": true])
    }
    
    @objc func sendMessage(_ call: CAPPluginCall) {
        NSLog("🎯 ChatOverlay sendMessage方法被调用!")
        call.resolve(["success": true])
    }
    
    @objc func receiveAIResponse(_ call: CAPPluginCall) {
        call.resolve(["success": true])
    }
    
    @objc func updateMessages(_ call: CAPPluginCall) {
        call.resolve(["success": true])
    }
    
    @objc func setLoading(_ call: CAPPluginCall) {
        call.resolve(["success": true])
    }
    
    @objc func setConversationTitle(_ call: CAPPluginCall) {
        call.resolve(["success": true])
    }
    
    @objc func setKeyboardHeight(_ call: CAPPluginCall) {
        call.resolve(["success": true])
    }
    
    @objc func setViewportHeight(_ call: CAPPluginCall) {
        call.resolve(["success": true])
    }
    
    @objc func setInitialInput(_ call: CAPPluginCall) {
        call.resolve(["success": true])
    }
    
    @objc func setFollowUpQuestion(_ call: CAPPluginCall) {
        call.resolve(["success": true])
    }
}