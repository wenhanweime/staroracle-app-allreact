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
        CAPPluginMethod(name: "setInputBottomSpace", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "setupBackgroundTransform", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "isVisible", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "sendMessage", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "receiveAIResponse", returnType: CAPPluginReturnPromise),
        // 新增：流式增量接口
        CAPPluginMethod(name: "appendAIChunk", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "updateLastAI", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "cancelStreaming", returnType: CAPPluginReturnPromise)
        ,
        // 可选：直接在原生侧发起流式请求
        CAPPluginMethod(name: "startNativeStream", returnType: CAPPluginReturnPromise),
        // 会话/上下文管理
        CAPPluginMethod(name: "setSystemPrompt", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "loadHistory", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "clearConversation", returnType: CAPPluginReturnPromise)
    ]
    
    // 业务逻辑管理器
    private lazy var overlayManager = ChatOverlayManager()
    
    public override init() {
        super.init()
        NSLog("🎯 ChatOverlayPlugin (CAPBridgedPlugin架构) 初始化成功!")
        // 设置状态变化回调
        setupStateChangeCallback()
        // 监听发送动画完成事件，转发给JS
        NotificationCenter.default.addObserver(self, selector: #selector(onSendAnimationCompleted), name: Notification.Name("chatOverlaySendAnimationCompleted"), object: nil)
    }

    @objc func cancelStreaming(_ call: CAPPluginCall) {
        NSLog("🎯 ChatOverlay cancelStreaming")
        overlayManager.cancelStreaming()
        call.resolve(["success": true])
    }
    
    // MARK: - 状态同步
    
    private func setupStateChangeCallback() {
        overlayManager.setOnStateChange { [weak self] state in
            DispatchQueue.main.async {
                self?.notifyOverlayStateChanged(state: state)
            }
        }
    }
    
    private func notifyOverlayStateChanged(state: OverlayState) {
        let isVisible = overlayManager.getVisibility()
        let isOpen = (state == .expanded) // 🔧 修复：isOpen应该基于展开状态，而不是可见性
        let stateString = state == .expanded ? "expanded" : (state == .collapsed ? "collapsed" : "hidden")
        
        NSLog("🎯 [ChatOverlayPlugin] 通知前端浮窗状态变化:")
        NSLog("🎯 - isVisible: \(isVisible)")
        NSLog("🎯 - isOpen (展开状态): \(isOpen)")
        NSLog("🎯 - state: \(stateString)")
        
        self.notifyListeners("overlayStateChanged", data: [
            "isOpen": isOpen,
            "state": stateString,
            "visible": isVisible
        ])
        
        NSLog("🎯 [ChatOverlayPlugin] overlayStateChanged事件已发送 - isOpen修复为基于展开状态")
    }
    
    // MARK: - Capacitor方法实现
    
    @objc func show(_ call: CAPPluginCall) {
        NSLog("🎯 ChatOverlay show方法被调用!")
        let animated = call.getBool("animated") ?? true
        let isOpen = call.getBool("isOpen") ?? false  // 获取展开状态参数
        
        NSLog("🎯 显示浮窗参数 - animated: \(animated), expanded: \(isOpen)")
        
        DispatchQueue.main.async {
            // 自动设置背景视图（如果尚未设置）：优先使用根VC视图，更稳定
            if let rootView = self.bridge?.viewController?.view {
                NSLog("🎯 自动设置根视图为背景视图")
                self.overlayManager.setBackgroundView(rootView)
            } else if let webView = self.bridge?.webView,
                      let containerView = webView.superview {
                NSLog("🎯 回退：设置WebView容器为背景视图")
                self.overlayManager.setBackgroundView(containerView)
            } else {
                NSLog("⚠️ 未找到合适的背景视图容器")
            }
            
            self.overlayManager.show(animated: animated, expanded: isOpen) { success in
                if success {
                    // 手动通知状态变化（因为show操作可能不会触发onStateChange回调）
                    DispatchQueue.main.async {
                        self.notifyOverlayStateChanged(state: self.overlayManager.currentState)
                    }
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
                // 立即通知隐藏状态变化（因为状态已经立即更新了）
                self.notifyOverlayStateChanged(state: .hidden)
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
    
    @objc func setInputBottomSpace(_ call: CAPPluginCall) {
        let space = call.getFloat("space") ?? 70
        NSLog("🎯 ChatOverlay setInputBottomSpace: \(space)")
        
        overlayManager.setInputBottomSpace(CGFloat(space))
        call.resolve(["success": true])
    }
    
    @objc func setupBackgroundTransform(_ call: CAPPluginCall) {
        NSLog("🎯 ChatOverlay setupBackgroundTransform方法被调用!")
        
        DispatchQueue.main.async {
            // 优先根视图，其次webView.superview
            if let rootView = self.bridge?.viewController?.view {
                NSLog("🎯 设置根视图为背景视图")
                self.overlayManager.setBackgroundView(rootView)
                call.resolve(["success": true, "message": "背景视图已设置为根视图"])
            } else if let webView = self.bridge?.webView,
                      let containerView = webView.superview {
                NSLog("🎯 回退：设置WebView容器为背景视图")
                self.overlayManager.setBackgroundView(containerView)
                call.resolve(["success": true, "message": "背景视图已设置为WebView容器"])
            } else {
                NSLog("⚠️ 未找到合适的背景视图")
                call.resolve(["success": false, "message": "未找到背景视图"])
            }
        }
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

    @objc private func onSendAnimationCompleted() {
        NSLog("🎯 [ChatOverlayPlugin] 发送动画完成 -> 通知JS sendAnimationCompleted")
        self.notifyListeners("sendAnimationCompleted", data: [:])
    }

    // MARK: - 新增：流式增量接口
    @objc func appendAIChunk(_ call: CAPPluginCall) {
        let delta = call.getString("delta") ?? ""
        let id = call.getString("id") // 可选
        NSLog("🎯 ChatOverlay appendAIChunk: id=\(id ?? "nil"), len=\(delta.count)")
        overlayManager.appendAIChunk(delta: delta, messageId: id)
        call.resolve(["success": true])
    }

    @objc func updateLastAI(_ call: CAPPluginCall) {
        let text = call.getString("text") ?? ""
        let id = call.getString("id")
        NSLog("🎯 ChatOverlay updateLastAI: id=\(id ?? "nil"), len=\(text.count)")
        overlayManager.updateLastAI(text: text, messageId: id)
        call.resolve(["success": true])
    }

    // MARK: - 可选：在原生发起流式（OpenAI 兼容）
    @objc func startNativeStream(_ call: CAPPluginCall) {
        guard let endpoint = call.getString("endpoint"), let model = call.getString("model") else {
            call.reject("缺少必要参数 endpoint/model")
            return
        }
        let apiKey = call.getString("apiKey") ?? ""
        let temperature = call.getDouble("temperature")
        let maxTokens = call.getInt("maxTokens")

        var messages: [ChatMessage] = []
        if let msgs = call.getArray("messages", Any.self) as? [[String: Any]] {
            messages = msgs.compactMap { m in
                guard let role = m["role"] as? String, let content = m["content"] as? String else { return nil }
                let isUser = (role == "user")
                return ChatMessage(id: UUID().uuidString, text: content, isUser: isUser, timestamp: Date().timeIntervalSince1970 * 1000)
            }
        }

        if endpoint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            call.reject("endpoint 为空")
            return
        }
        if model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            call.reject("model 为空")
            return
        }
        NSLog("🎯 [NativeStream] 开始: endpoint=\(endpoint), model=\(model), messages=\(messages.count)")
        overlayManager.startNativeStreaming(endpoint: endpoint, apiKey: apiKey, model: model, messages: messages, temperature: temperature, maxTokens: maxTokens)
        call.resolve(["success": true])
    }

    // MARK: - 会话/上下文管理
    @objc func setSystemPrompt(_ call: CAPPluginCall) {
        let text = call.getString("text") ?? ""
        NSLog("🎯 setSystemPrompt: len=\(text.count)")
        ConversationStore.shared.setSystemPrompt(text)
        call.resolve(["success": true])
    }

    @objc func loadHistory(_ call: CAPPluginCall) {
        let list = ConversationStore.shared
        let msgs = list.messages
        NSLog("🎯 loadHistory: count=\(msgs.count)")
        overlayManager.updateMessages(msgs)
        call.resolve(["success": true, "count": msgs.count])
    }

    @objc func clearConversation(_ call: CAPPluginCall) {
        NSLog("🎯 clearConversation")
        ConversationStore.shared.clear()
        overlayManager.updateMessages([])
        call.resolve(["success": true])
    }
}
