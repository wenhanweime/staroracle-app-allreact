import SwiftUI
import UIKit
import Capacitor

// MARK: - PassthroughWindow - 自定义窗口类，支持触摸事件穿透
class PassthroughWindow: UIWindow {
    weak var overlayViewController: OverlayViewController?
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // 先让窗口正常处理触摸测试
        guard let hitView = super.hitTest(point, with: event) else {
            NSLog("🎯 PassthroughWindow: 没有找到hitView，透传事件")
            return nil
        }
        
        // 获取containerView
        guard let containerView = overlayViewController?.containerView else {
            // 如果没有containerView，检查是否点击在根视图上
            if hitView == self.rootViewController?.view {
                NSLog("🎯 PassthroughWindow: 点击在背景上，透传事件")
                return nil
            }
            return hitView
        }
        
        // 将点转换到containerView的坐标系
        let convertedPoint = convert(point, to: containerView)
        
        // 如果点击在containerView区域内，正常处理
        if containerView.bounds.contains(convertedPoint) {
            NSLog("🎯 PassthroughWindow: 点击在ChatOverlay内，正常处理")
            return hitView
        }
        
        // 如果点击在containerView外，透传事件
        NSLog("🎯 PassthroughWindow: 点击在ChatOverlay外，透传事件")
        self.endEditing(true) // 收起键盘
        return nil // 透传事件
    }
}

// MARK: - ChatOverlay数据模型
public struct ChatMessage: Codable {
    let id: String
    let text: String
    let isUser: Bool
    let timestamp: Double
}

// MARK: - ChatOverlay状态管理
enum OverlayState {
    case collapsed   // 收缩状态：65px高度
    case expanded    // 展开状态：全屏显示
    case hidden      // 隐藏状态
}

// MARK: - ChatOverlay状态变化通知
extension Notification.Name {
    static let chatOverlayStateChanged = Notification.Name("chatOverlayStateChanged")
    // 🔧 已移除chatOverlayVisibilityChanged，统一使用chatOverlayStateChanged
    static let inputDrawerPositionChanged = Notification.Name("inputDrawerPositionChanged")  // 新增：输入框位置变化通知
}

// MARK: - ChatOverlayManager业务逻辑类
public class ChatOverlayManager {
    private var overlayWindow: UIWindow?
    private var isVisible = false
    internal var currentState: OverlayState = .collapsed
    internal var messages: [ChatMessage] = []
    private var isLoading = false
    private var conversationTitle = ""
    private var keyboardHeight: CGFloat = 0
    private var viewportHeight: CGFloat = UIScreen.main.bounds.height
    private var initialInput = ""
    private var followUpQuestion = ""
    private var overlayViewController: OverlayViewController?
    // 协调延迟任务：收缩态更新可能的延迟任务（用于在展开前取消以避免竞态）
    private var pendingCollapsedWork: DispatchWorkItem?
    // NOTE: Removed stray non-code line accidentally inserted during docs; no functional change.
    // 关闭后下次输入强制新会话
    private var startNewOnNextInput: Bool = false
    fileprivate var horizontalOffset: CGFloat = 0
    
    // 原生流式客户端（可选使用）
    private let streamingClient = StreamingClient()
    
    // 状态变化回调
    private var onStateChange: ((OverlayState) -> Void)?
    private var systemPromptText: String = ""
    
    // 背景视图变换 - 用于3D缩放效果
    private weak var backgroundView: UIView?
    
    // 动画触发跟踪 - 🎯 【关键新增】用Set管理已播放动画的消息ID
    internal var animatedMessageIDs = Set<String>()  // 改为internal，让OverlayViewController能访问
    private var lastMessages: [ChatMessage] = [] // 用来对比
    
    // 🔧 新增：防止重复同步的时间戳记录
    private var lastSyncTimestamp: TimeInterval = 0
    private let syncThrottleInterval: TimeInterval = 0.1  // 100ms内的重复调用将被忽略
    
    // 🚨 【关键修复】基于状态机的消息去重机制
    private var lastMessagesHash: String = ""
    
    // MARK: - Public API
    
    func show(animated: Bool = true, expanded: Bool = false, completion: @escaping (Bool) -> Void) {
        NSLog("🎯 ChatOverlayManager: 显示浮窗, expanded: \(expanded)")
        
        DispatchQueue.main.async {
            if self.overlayWindow != nil {
                NSLog("🎯 浮窗已存在，直接显示并设置状态")
                self.overlayWindow?.isHidden = false
                self.overlayWindow?.alpha = 1  // 🔧 修复：恢复alpha值
                self.isVisible = true
                
                // 🚨 【3D动画修复】设置状态并一次性完成所有动画
                self.currentState = expanded ? .expanded : .collapsed
                NSLog("🎯 设置状态为: \(self.currentState)")
                
                // 发送状态通知，让InputDrawer先调整位置
                NotificationCenter.default.post(
                    name: .chatOverlayStateChanged,
                    object: nil,
                    userInfo: [
                        "state": expanded ? "expanded" : "collapsed", 
                        "height": expanded ? UIScreen.main.bounds.height - 100 : 65
                    ]
                )
                
                // 稍微延迟更新UI，确保InputDrawer已经调整位置
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    // 🚨 【3D动画修复】同步更新UI与背景3D变换，保证首帧与过渡一致
                    self.updateUI(animated: animated)
                    self.applyBackgroundTransform(for: self.currentState, animated: animated)
                }
                
                completion(true)
                return
            }
            
            self.createOverlayWindow()
            
            // 根据参数设置初始状态
            self.currentState = expanded ? .expanded : .collapsed
            NSLog("🎯 设置初始状态为: \(self.currentState)")
            
            if animated {
                self.overlayWindow?.alpha = 0
                UIView.animate(withDuration: 0.3) {
                    self.overlayWindow?.alpha = 1
                } completion: { _ in
                    self.isVisible = true
                    
                    // 🚨 【3D动画修复】初始显示时一次性更新UI和背景变换
                    self.updateUI(animated: true)
                    self.applyBackgroundTransform(for: self.currentState, animated: true)
                    
                    // 发送通知让InputDrawer调整位置
                    if self.currentState == .collapsed {
                        NotificationCenter.default.post(
                            name: .chatOverlayStateChanged,
                            object: nil,
                            userInfo: ["state": "collapsed", "height": 65]
                        )
                    }
                    
                    completion(true)
                }
            } else {
                self.isVisible = true
                // 🚨 【3D动画修复】无动画模式一次性更新UI和背景变换
                self.updateUI(animated: false)
                
                // 发送通知让InputDrawer调整位置
                if self.currentState == .collapsed {
                    NotificationCenter.default.post(
                        name: .chatOverlayStateChanged,
                        object: nil,
                        userInfo: ["state": "collapsed", "height": 65]
                    )
                }
                
                completion(true)
            }
        }
    }
    
    func hide(animated: Bool = true, completion: @escaping () -> Void = {}) {
        NSLog("🎯 ChatOverlayManager: 隐藏浮窗")
        
        // 立即更新状态，不等动画完成
        self.isVisible = false
        self.currentState = .hidden
        
        DispatchQueue.main.async {
            guard let window = self.overlayWindow else {
                completion()
                return
            }
            
            // 🔧 修复：恢复背景状态应该对应hidden状态（等同于collapsed的效果）
            self.applyBackgroundTransform(for: .hidden, animated: animated)
            
            // 🔧 修复：触发状态变化回调，确保前端能收到正确的状态
            self.onStateChange?(.hidden)
            
            // 🔧 只发送状态通知，移除冗余的可见性通知  
            NotificationCenter.default.post(
                name: .chatOverlayStateChanged,
                object: nil,
                userInfo: [
                    "state": "hidden",
                    "visible": false  // 🔧 在状态通知中包含可见性信息
                ]
            )

            // 将当前消息落盘为当前会话历史，并置位“下次输入新会话”
            ConversationStore.shared.setMessages(self.messages)
            self.startNewOnNextInput = true
            
            if animated {
                UIView.animate(withDuration: 0.3) {
                    window.alpha = 0
                } completion: { _ in
                    window.isHidden = true
                    completion()
                }
            } else {
                window.isHidden = true
                completion()
            }
        }
    }
    
    func updateMessages(_ messages: [ChatMessage]) {
        NSLog("🎯 ChatOverlayManager: 更新消息列表，数量: \(messages.count)")
        
        for (index, message) in messages.enumerated() {
            NSLog("🎯 消息[\(index)]: \(message.isUser ? "用户" : "AI") - \(message.text.prefix(50))")
        }
        
        // 🚨 【关键修复】消息内容去重：生成消息内容的哈希值
        let messagesHash = messages.map { "\($0.id)-\($0.isUser)-\($0.text)" }.joined(separator: "|")
        
        // 如果消息内容没有变化，跳过更新
        if lastMessagesHash == messagesHash {
            NSLog("🎯 [去重] 消息内容未变化，跳过更新")
            return
        }
        
        lastMessagesHash = messagesHash
        
        // 🚨 【关键修复】基于状态机的动画判断
        let latestUserMessage = messages.last(where: { $0.isUser })
        var shouldAnimate = false
        var animationIndex: Int? = nil
        
        // 状态机逻辑：只要不处于用户插入动画中即可触发（idle/aiStreaming/completed 均可）
        let currentAnimState = overlayViewController?.animationState ?? OverlayViewController.AnimationState.idle
        if let userMessage = latestUserMessage,
           !animatedMessageIDs.contains(userMessage.id),
           currentAnimState == .idle {
            // 🎯 发现新用户消息（仅在空闲态触发），准备进入动画状态
            shouldAnimate = true
            overlayViewController?.animationState = .userAnimating
            overlayViewController?.pendingUserMessageId = userMessage.id
            animatedMessageIDs.insert(userMessage.id)
            animationIndex = messages.firstIndex(where: { $0.id == userMessage.id })
            NSLog("🎯 ✅ [状态机] 发现新用户消息！ID: \(userMessage.id), 状态: \(overlayViewController?.animationState ?? .idle), 索引: \(animationIndex ?? -1)")
        } else {
            // 根据当前状态决定处理方式
            switch overlayViewController?.animationState ?? .idle {
            case .idle:
                NSLog("🎯 ☑️ [状态机] 空闲状态，无新用户消息")
            case .userAnimating:
                NSLog("🎯 ☑️ [状态机] 用户消息动画中，跳过新动画")
            case .aiStreaming:
                NSLog("🎯 ☑️ [状态机] AI流式输出中，跳过新动画")
            case .completed:
                NSLog("🎯 ☑️ [状态机] 完成状态，重置为空闲")
                overlayViewController?.animationState = .idle
            }
        }
        
        // 更新消息列表
        self.lastMessages = self.messages
        self.messages = messages
        
        // 🎯 通知ViewController更新UI，只在真正需要动画时才传递true
        DispatchQueue.main.async {
            NSLog("🎯 通知OverlayViewController更新消息显示，需要动画: \(shouldAnimate)")
            if let index = animationIndex {
                NSLog("🎯 动画索引: \(index)")
            }
            self.overlayViewController?.updateMessages(messages, oldMessages: self.lastMessages, shouldAnimateNewUserMessage: shouldAnimate, animationIndex: animationIndex)
        }
    }
    
    func setLoading(_ loading: Bool) {
        NSLog("🎯 ChatOverlayManager: 设置加载状态: \(loading)")
        self.isLoading = loading
        // 这里可以更新UI，暂时先简化
    }

    func cancelStreaming() {
        NSLog("🎯 ChatOverlayManager: 取消流式/回放")
        DispatchQueue.main.async {
            self.overlayViewController?.cancelStreaming()
        }
        streamingClient.cancel()
    }

    // MARK: - 流式增量接口（供插件调用）
    func appendAIChunk(delta: String, messageId: String?) {
        guard !delta.isEmpty else { return }
        // 优先根据 messageId 精确更新本轮 AI 占位
        if let mid = messageId, let idx = messages.firstIndex(where: { !$0.isUser && $0.id == mid }) {
            let last = messages[idx]
            let newText = last.text + delta
            messages[idx] = ChatMessage(id: last.id, text: newText, isUser: last.isUser, timestamp: last.timestamp)
            ConversationStore.shared.replaceLastAssistantText(newText)
        } else if let lastIndex = messages.lastIndex(where: { !$0.isUser }) {
            // 退回到更新最后一条AI
            let last = messages[lastIndex]
            let newText = last.text + delta
            messages[lastIndex] = ChatMessage(id: last.id, text: newText, isUser: last.isUser, timestamp: last.timestamp)
            ConversationStore.shared.replaceLastAssistantText(newText)
        } else {
            // 如果不存在AI消息，占位一条空AI再追加
            let ts = Date().timeIntervalSince1970 * 1000
            let new = ChatMessage(id: messageId ?? "ai-\(Int(ts))", text: delta, isUser: false, timestamp: ts)
            messages.append(new)
            ConversationStore.shared.append(new)
        }
        // 通知VC增量刷新（count 未变化或 +1，仅最后行）
        let current = messages
        DispatchQueue.main.async {
            self.overlayViewController?.updateMessages(current, oldMessages: self.lastMessages, shouldAnimateNewUserMessage: false, animationIndex: nil)
        }
    }

    func updateLastAI(text: String, messageId: String?) {
        if let mid = messageId, let idx = messages.firstIndex(where: { !$0.isUser && $0.id == mid }) {
            let last = messages[idx]
            messages[idx] = ChatMessage(id: last.id, text: text, isUser: last.isUser, timestamp: last.timestamp)
            ConversationStore.shared.replaceLastAssistantText(text)
        } else if let lastIndex = messages.lastIndex(where: { !$0.isUser }) {
            let last = messages[lastIndex]
            messages[lastIndex] = ChatMessage(id: last.id, text: text, isUser: last.isUser, timestamp: last.timestamp)
            ConversationStore.shared.replaceLastAssistantText(text)
        } else {
            let ts = Date().timeIntervalSince1970 * 1000
            let new = ChatMessage(id: messageId ?? "ai-\(Int(ts))", text: text, isUser: false, timestamp: ts)
            messages.append(new)
            ConversationStore.shared.append(new)
        }
        let current = messages
        DispatchQueue.main.async {
            self.overlayViewController?.updateMessages(current, oldMessages: self.lastMessages, shouldAnimateNewUserMessage: false, animationIndex: nil)
        }
    }

    // MARK: - 可选：直接在原生侧发起流式请求（OpenAI 兼容）
    // 说明：当前项目主要由 JS 发起请求并通过 appendAIChunk/updateLastAI 增量更新。
    // 若需要从原生直接请求，可调用此方法。
    func startNativeStreaming(endpoint: String, apiKey: String, model: String, messages: [ChatMessage], temperature: Double? = nil, maxTokens: Int? = nil) {
        NSLog("🎯 [NativeStream] startNativeStreaming | endpoint=%@ model=%@ messages=%d", endpoint, model, messages.count)
        // 1) UI侧仅基于原生已有消息源进行追加，不用外部messages重置UI，避免上一轮AI被覆盖
        //    外部messages仅用于LLM上下文（reqMessages）
        // 若被标记为“下次输入新会话”，先创建并切换
        if startNewOnNextInput {
            _ = ConversationStore.shared.createSession(title: "新会话")
            startNewOnNextInput = false
            self.lastMessages = self.messages
            self.messages = []
            DispatchQueue.main.async {
                self.overlayViewController?.updateMessages(self.messages, oldMessages: self.lastMessages, shouldAnimateNewUserMessage: false, animationIndex: nil)
            }
        }
        let old = self.messages
        self.lastMessages = old

        // 从外部参数获取最新的用户消息内容
        if let paramLastUser = messages.last(where: { $0.isUser }) {
            // 追加到原生消息源（用户行 + 立即追加AI空占位，保证首次也有spinner）
            let newUser = ChatMessage(id: UUID().uuidString, text: paramLastUser.text, isUser: true, timestamp: Date().timeIntervalSince1970 * 1000)
            self.messages.append(newUser)
            let aiPlaceholder = ChatMessage(id: UUID().uuidString, text: "", isUser: false, timestamp: Date().timeIntervalSince1970 * 1000)
            self.messages.append(aiPlaceholder)
            // 同步到持久层
            ConversationStore.shared.append(newUser)
            ConversationStore.shared.append(aiPlaceholder)

            // 触发插入动画（允许在非 userAnimating 状态下触发：idle/aiStreaming/completed）
            if let vc = self.overlayViewController, vc.animationState != .userAnimating {
                DispatchQueue.main.async {
                    NSLog("🎯 [NativeStream] 触发用户插入动画: id=\(newUser.id)")
                    vc.animationState = .userAnimating
                    vc.pendingUserMessageId = newUser.id
                    self.animatedMessageIDs.insert(newUser.id)
                    vc.updateMessages(self.messages, oldMessages: self.lastMessages, shouldAnimateNewUserMessage: true, animationIndex: self.messages.firstIndex(where: { $0.id == newUser.id }) ?? (self.messages.count - 2))
                }
            } else {
                NSLog("ℹ️ [NativeStream] 动画进行中/其他状态，无动画刷新以确保可见")
                DispatchQueue.main.async {
                    self.overlayViewController?.updateMessages(self.messages, oldMessages: self.lastMessages, shouldAnimateNewUserMessage: false, animationIndex: nil)
                }
            }
        } else {
            NSLog("⚠️ [NativeStream] 外部参数未提供用户消息，跳过追加")
            DispatchQueue.main.async {
                self.overlayViewController?.updateMessages(self.messages, oldMessages: self.lastMessages, shouldAnimateNewUserMessage: false, animationIndex: nil)
            }
        }

        // 2) 启动原生流式（SSE），在插入动画期间由VC缓存增量，动画完成后回放
        // 基于原生消息源构建上下文窗口 + system prompt
        let window = 20
        var ctx = Array(self.messages.suffix(window))
        var reqMessages: [StreamingClient.Message] = []
        let sys = systemPromptText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !sys.isEmpty {
            reqMessages.append(StreamingClient.Message(role: "system", content: sys))
        }
        reqMessages.append(contentsOf: ctx.map { StreamingClient.Message(role: $0.isUser ? "user" : "assistant", content: $0.text) })
        var started = false
        // 已在追加用户行时同步追加AI占位，这里不再重复
        var lastId = self.messages.last(where: { !$0.isUser })?.id
        streamingClient.startChatCompletionStream(
            endpoint: endpoint,
            apiKey: apiKey,
            model: model,
            messages: reqMessages,
            temperature: temperature,
            maxTokens: maxTokens,
            onChunk: { [weak self] (delta: String) in
                NSLog("✉️ [NativeStream] chunk len=%d", delta.count)
                guard let self = self else { return }
                if !started { started = true }
                self.appendAIChunk(delta: delta, messageId: lastId)
            },
            onComplete: { [weak self] (full: String?, error: Error?) in
                guard let self = self else { return }
                if let error = error {
                    NSLog("❌ [NativeStream] 完成时错误: \(error.localizedDescription)")
                } else {
                    NSLog("✅ [NativeStream] 完成 fullLen=%d", full?.count ?? 0)
                }
                if let text = full, !text.isEmpty {
                    self.updateLastAI(text: text, messageId: lastId)
                }
                if let error = error { NSLog("❌ [NativeStream] 错误: \(error.localizedDescription)") }
                // 将状态从 aiStreaming 过渡到 completed，再回到 idle，确保下一次发送可触发插入动画
                DispatchQueue.main.async {
                    if let vc = self.overlayViewController {
                        vc.animationState = .completed
                        NSLog("🎯 [NativeStream] 流式完成，状态=completed → idle 复位")
                        // 轻微延迟，确保最后一轮UI更新完成
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            vc.animationState = .idle
                        }
                    }
                }
            }
        )
    }
    
    func setConversationTitle(_ title: String) {
        NSLog("🎯 ChatOverlayManager: 设置对话标题: \(title)")
        self.conversationTitle = title
        // 这里可以更新UI，暂时先简化
    }
    
    func setKeyboardHeight(_ height: CGFloat) {
        NSLog("🎯 ChatOverlayManager: 设置键盘高度: \(height)")
        self.keyboardHeight = height
        // 这里可以更新UI，暂时先简化
    }
    
    func setViewportHeight(_ height: CGFloat) {
        NSLog("🎯 ChatOverlayManager: 设置视口高度: \(height)")
        self.viewportHeight = height
        // 这里可以更新UI，暂时先简化
    }
    
    func setInitialInput(_ input: String) {
        NSLog("🎯 ChatOverlayManager: 设置初始输入: \(input)")
        self.initialInput = input
        // 这里可以更新UI，暂时先简化
    }
    
    func setFollowUpQuestion(_ question: String) {
        NSLog("🎯 ChatOverlayManager: 设置后续问题: \(question)")
        self.followUpQuestion = question
        // 这里可以更新UI，暂时先简化
    }

    func setHorizontalOffset(_ offset: CGFloat, animated: Bool = true) {
        let normalized = max(0, offset)
        NSLog("🎯 ChatOverlayManager: 设置水平偏移: \(normalized) (animated: \(animated))")
        horizontalOffset = normalized
        DispatchQueue.main.async { [weak self] in
            self?.overlayViewController?.setHorizontalOffset(normalized, animated: animated)
        }
    }
    
    func setInputBottomSpace(_ space: CGFloat) {
        NSLog("🎯 ChatOverlayManager: InputDrawer位置设置为: \(space)px")
        // 注意：浮窗位置固定，无需根据输入框位置调整
    }
    
    func getVisibility() -> Bool {
        return isVisible
    }
    
    // MARK: - 状态切换方法
    
    func switchToCollapsed() {
        NSLog("🎯 ChatOverlayManager: 切换到收缩状态")
        currentState = .collapsed

        // 先发送状态变化通知，让InputDrawer调整位置
        NotificationCenter.default.post(
            name: .chatOverlayStateChanged,
            object: nil,
            userInfo: ["state": "collapsed", "height": 65]
        )
        // 取消任何挂起的延迟任务，避免与后续展开竞态
        pendingCollapsedWork?.cancel()
        pendingCollapsedWork = nil
        
        // 首次收缩：让 InputDrawer 先到位，再由VC监听实际位置进行一次性对齐动画
        if let vc = overlayViewController, !vc.didFirstCollapseAlign {
            vc.awaitingFirstCollapseAlign = true
            // 背景可以先动，窗口位置等对齐通知后再动，避免首帧不一致
            applyBackgroundTransform(for: .collapsed, animated: true)
            onStateChange?(.collapsed)
            // 不立即调用 updateUI 动画，由对齐通知来驱动首次位置动画
            // 兜底：若短时间内未收到对齐通知，则按既有路径执行一次定位，避免悬置
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                guard let self = self else { return }
                if let vc = self.overlayViewController, vc.awaitingFirstCollapseAlign && !vc.didFirstCollapseAlign {
                    NSLog("🎯 ChatOverlay: 首次对齐未及时收到位置广播，执行兜底定位")
                    self.updateUI(animated: true)
                    vc.awaitingFirstCollapseAlign = false
                    vc.didFirstCollapseAlign = true
                }
            }
        } else {
            // 非首次：按既有路径动画
            updateUI(animated: true)
            applyBackgroundTransform(for: .collapsed, animated: true)
            onStateChange?(.collapsed)
        }

        // 注意：浮窗位置会在延迟后更新，确保基于正确的InputDrawer位置
    }
    
    // 新增：专门用于拖拽切换的流畅方法，无延迟
    func switchToCollapsedFromDrag() {
        NSLog("🎯 ChatOverlayManager: 从拖拽切换到收缩状态（无延迟）")
        currentState = .collapsed
        
        // 发送状态变化通知
        NotificationCenter.default.post(
            name: .chatOverlayStateChanged,
            object: nil,
            userInfo: ["state": "collapsed", "height": 65]
        )
        
        // 🚨 【动画冲突修复】同时触发UI和背景动画，避免时序冲突
        updateUI(animated: true)
        applyBackgroundTransform(for: .collapsed, animated: true)
        onStateChange?(.collapsed)
        
        NSLog("🎯 拖拽切换完成，UI和背景同步更新")
    }
    
    func switchToExpanded() {
        NSLog("🎯 ChatOverlayManager: 切换到展开状态")
        // 展开前取消任何挂起的收缩态延迟任务，避免覆盖展开动画
        pendingCollapsedWork?.cancel()
        pendingCollapsedWork = nil
        currentState = .expanded
        // 🚨 【动画冲突修复】同时触发UI和背景动画，避免时序冲突
        updateUI(animated: true)
        applyBackgroundTransform(for: .expanded, animated: true)
        onStateChange?(.expanded)
        
        // 发送状态变化通知
        NotificationCenter.default.post(
            name: .chatOverlayStateChanged,
            object: nil,
            userInfo: ["state": "expanded", "height": UIScreen.main.bounds.height - 100]
        )
    }
    
    func toggleState() {
        NSLog("🎯 ChatOverlayManager: 切换状态")
        // 切换前先取消可能存在的收缩延迟任务
        pendingCollapsedWork?.cancel()
        pendingCollapsedWork = nil
        currentState = (currentState == .collapsed) ? .expanded : .collapsed
        // 🚨 【动画冲突修复】同时触发UI和背景动画，避免时序冲突
        updateUI(animated: true)
        applyBackgroundTransform(for: currentState, animated: true)
        onStateChange?(currentState)
    }
    
    func setOnStateChange(_ callback: @escaping (OverlayState) -> Void) {
        self.onStateChange = callback
    }

    // 会话/上下文管理（简易版本，不依赖外部文件）
    func setSystemPrompt(_ text: String) {
        self.systemPromptText = text
        ConversationStore.shared.setSystemPrompt(text)
    }
    func loadHistory() -> Int {
        // 从会话存储加载为真源
        let list = ConversationStore.shared.messages
        self.lastMessages = self.messages
        self.messages = list
        DispatchQueue.main.async {
            self.overlayViewController?.updateMessages(self.messages, oldMessages: self.lastMessages, shouldAnimateNewUserMessage: false, animationIndex: nil)
        }
        return self.messages.count
    }
    func clearAll() {
        self.lastMessages = self.messages
        self.messages = []
        DispatchQueue.main.async {
            self.overlayViewController?.updateMessages(self.messages, oldMessages: self.lastMessages, shouldAnimateNewUserMessage: false, animationIndex: nil)
        }
    }
    
    // MARK: - 背景3D效果方法
    
    func setBackgroundView(_ view: UIView) {
        NSLog("🎯 ChatOverlayManager: 设置背景视图用于3D变换")
        self.backgroundView = view
    }
    
    private func applyBackgroundTransform(for state: OverlayState, animated: Bool = true) {
        guard let backgroundView = backgroundView else { 
            NSLog("⚠️ 背景视图未设置，跳过3D变换")
            return 
        }

        NSLog("🎯 应用背景3D变换，状态: \(state)")
        // 若插入动画进行中，避免与发送动画叠加，改为无动画
        let shouldAnimate = (overlayViewController?.isAnimatingInsert == true) ? false : animated

        // 🎯 基线校准：展开动画起点强制为 scale=1（避免任何>1的起跳错觉）
        if state == .expanded {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            backgroundView.layer.removeAllAnimations()
            backgroundView.layer.transform = CATransform3DIdentity
            backgroundView.alpha = 1.0
            CATransaction.commit()
            NSLog("🧭 基线校准：已无动画重置为 scale=1.0, alpha=1.0")
        }
        if shouldAnimate {
            // 🎯 改为无弹簧的单调 ease-out 动画，避免任何反向/反弹
            UIView.animate(withDuration: 0.26,
                           delay: 0,
                           options: [.allowUserInteraction, .curveEaseOut],
                           animations: {
                switch state {
                case .expanded:
                    // 展开状态：缩放0.92，向上移动15px，绕X轴旋转4度，降低亮度
                    var transform = CATransform3DIdentity
                    transform.m34 = -1.0 / 1000.0  // 设置透视效果
                    transform = CATransform3DScale(transform, 0.92, 0.92, 1.0)
                    transform = CATransform3DTranslate(transform, 0, -15, 0)
                    transform = CATransform3DRotate(transform, 4.0 * .pi / 180.0, 1, 0, 0)  // 绕X轴旋转4度
                    
                    backgroundView.layer.transform = transform
                    backgroundView.alpha = 0.6  // 降低亮度到60%
                    
                case .collapsed, .hidden:
                    // 收缩状态或隐藏状态：还原到原始状态
                    backgroundView.layer.transform = CATransform3DIdentity
                    backgroundView.alpha = 1.0  // 恢复原始亮度
                }
            }, completion: nil)
        } else {
            // 无动画模式：立即设置状态
            switch state {
            case .expanded:
                var transform = CATransform3DIdentity
                transform.m34 = -1.0 / 1000.0
                transform = CATransform3DScale(transform, 0.92, 0.92, 1.0)
                transform = CATransform3DTranslate(transform, 0, -15, 0)
                transform = CATransform3DRotate(transform, 4.0 * .pi / 180.0, 1, 0, 0)
                
                backgroundView.layer.transform = transform
                backgroundView.alpha = 0.6
                
            case .collapsed, .hidden:
                backgroundView.layer.transform = CATransform3DIdentity
                backgroundView.alpha = 1.0
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func createOverlayWindow() {
        NSLog("🎯 ChatOverlayManager: 创建双状态浮窗视图")
        
        // 创建浮窗窗口 - 使用自定义的PassthroughWindow支持触摸穿透
        let window = PassthroughWindow(frame: UIScreen.main.bounds)
        // 设置层级：确保在星座之上但低于InputDrawer (statusBar-0.5)
        window.windowLevel = UIWindow.Level.statusBar - 1  // 比InputDrawer低0.5级
        window.backgroundColor = UIColor.clear
        
        // 关键：让窗口不阻挡其他交互，只处理容器内的触摸
        window.isHidden = false
        
        // 创建自定义视图控制器
        overlayViewController = OverlayViewController(manager: self)
        window.rootViewController = overlayViewController
        overlayViewController?.loadViewIfNeeded()
        overlayViewController?.setHorizontalOffset(horizontalOffset, animated: false)

        // 设置窗口对视图控制器的引用
        window.overlayViewController = overlayViewController
        
        // 保存窗口引用
        overlayWindow = window
        
        // 不使用makeKeyAndVisible()，避免抢夺焦点，确保InputDrawer始终在最前
        window.isHidden = false
        
        // 注意：不在这里设置初始状态，由show方法控制
        NSLog("🎯 ChatOverlayManager: 双状态浮窗创建完成")
        NSLog("🎯 ChatOverlayManager: 窗口层级: \(window.windowLevel.rawValue)")
        NSLog("🎯 StatusBar层级: \(UIWindow.Level.statusBar.rawValue)")
        NSLog("🎯 Alert层级: \(UIWindow.Level.alert.rawValue)")
        NSLog("🎯 Normal层级: \(UIWindow.Level.normal.rawValue)")
    }
    
    private func updateUI(animated: Bool) {
        guard let overlayViewController = overlayViewController else { return }
        
        // 若插入动画进行中，避免任何包裹动画的状态切换，直接无动画更新
        if (overlayViewController.isAnimatingInsert) {
            NSLog("🧊 冻结窗口：插入动画期间，updateUI无动画执行")
            overlayViewController.updateForState(self.currentState)
            overlayViewController.view.layoutIfNeeded()
            return
        }
        
        if animated {
            // 🎯 使用轻微弹性过渡，营造柔和“推上/落下”手感
            UIView.animate(withDuration: 0.28,
                           delay: 0,
                           usingSpringWithDamping: 0.9,
                           initialSpringVelocity: 0.3,
                           options: [.allowUserInteraction, .curveEaseInOut, .beginFromCurrentState],
                           animations: {
                overlayViewController.updateForState(self.currentState)
                overlayViewController.view.layoutIfNeeded()
            }, completion: nil)
        } else {
            overlayViewController.updateForState(self.currentState)
        }
    }
    
    @objc private func closeButtonTapped() {
        NSLog("🎯 ChatOverlayManager: 关闭按钮被点击")
        hide()
    }
}

// MARK: - OverlayViewController - 处理双状态UI显示
class OverlayViewController: UIViewController {
    
    // 🚨 【关键修复】动画状态枚举
    enum AnimationState {
        case idle           // 空闲状态
        case userAnimating  // 用户消息动画中
        case aiStreaming    // AI流式输出中
        case completed      // 完成状态
    }
    private weak var manager: ChatOverlayManager?
    internal var containerView: UIView!  // 改为internal让PassthroughWindow可以访问
    private var collapsedView: UIView!
    private var expandedView: UIView!
    private var backgroundMaskView: UIView!
    private var messagesList: UITableView!
    private var dragIndicator: UIView!
    // 去除渐变，改为与输入框一致的风格（纯色+浅色描边）
    
    // 渲染层可见消息（与数据层解耦）：用于发送动画期间隐藏AI占位
    fileprivate var visibleMessages: [ChatMessage] = []
    // 流式缓冲/回放控制：在发送动画期间缓存AI文本，动画完成后按节奏回放
    private var aiBufferTimer: Timer?
    private var aiTargetFullText: String = ""
    private var aiDisplayedText: String = ""
    private var aiMessageId: String = ""
    // 动画去重与节流（双保险）
    private var hasScheduledInsertAnimation: Bool = false
    private var lastAnimatedUserMessageId: String? = nil
    private var lastAnimationTimestamp: CFTimeInterval = 0

    // 首次收缩对齐控制
    internal var awaitingFirstCollapseAlign: Bool = false
    internal var didFirstCollapseAlign: Bool = false

    // 自动滚动策略：仅在接近底部时才自动滚动
    private let autoScrollThreshold: CGFloat = 100 // px
    private func shouldAutoScrollToBottom() -> Bool {
        guard let table = messagesList else { return true }
        let contentHeight = table.contentSize.height
        if contentHeight <= 0 { return true }
        let visibleHeight = table.bounds.height
        let offsetY = table.contentOffset.y
        let distanceFromBottom = contentHeight - (offsetY + visibleHeight)
        let isUserInteracting = table.isDragging || table.isTracking || table.isDecelerating || isDragging
        let nearBottom = distanceFromBottom < autoScrollThreshold
        NSLog("🧭 AutoScroll 判定: contentH=\(contentHeight), visibleH=\(visibleHeight), offsetY=\(offsetY), dist=\(distanceFromBottom), nearBottom=\(nearBottom), interacting=\(isUserInteracting)")
        return nearBottom && !isUserInteracting
    }

    // MARK: - 冻结窗口内的安全UI操作封装
    private func isFrozen() -> Bool { return isAnimatingInsert }

    private func safeReloadData(reason: String) {
        if isFrozen() {
            NSLog("🧊 [冻结] reloadData 被抑制，原因: \(reason)")
            return
        }
        NSLog("🔄 reloadData 执行，原因: \(reason)")
        messagesList.reloadData()
    }

    private func safeReloadRows(_ rows: [IndexPath], reason: String, animation: UITableView.RowAnimation = .none) {
        if isFrozen() {
            NSLog("🧊 [冻结] reloadRows 被抑制，原因: \(reason), rows=\(rows)")
            return
        }
        NSLog("🔄 reloadRows 执行，原因: \(reason), rows=\(rows)")
        messagesList.reloadRows(at: rows, with: animation)
    }

    private func safeScrollToRow(_ indexPath: IndexPath, at position: UITableView.ScrollPosition, animated: Bool, reason: String) {
        if isFrozen() {
            NSLog("🧊 [冻结] scrollToRow 被抑制，原因: \(reason), indexPath=\(indexPath.row)")
            return
        }
        NSLog("🧭 scrollToRow 执行，原因: \(reason), indexPath=\(indexPath.row), animated=\(animated)")
        messagesList.scrollToRow(at: indexPath, at: position, animated: animated)
    }
    
    // 拖拽相关状态 - 移到OverlayViewController中
    private var isDragging = false
    private var dragStartY: CGFloat = 0
    private var originalTopConstraint: CGFloat = 0  // 记录拖拽开始时的原始位置
    
    // 滚动收起相关状态
    private var hasTriggeredScrollCollapse = false  // 防止重复触发滚动收起
    
    // 🔧 新增：动画相关状态
    private var pendingAnimationIndex: Int?  // 需要播放动画的消息索引
    
    // 🚨 【动画锁定机制】核心属性
    internal var isAnimatingInsert = false  // 动画期间锁定标记（对Manager可见）
    private var pendingAIUpdates: [ChatMessage] = []  // 动画期间暂存的AI更新
    
    // 🚨 【关键修复】流式输出与动画协调机制
    internal var isUserMessageAnimating = false  // 用户消息动画进行中（对Manager可见）
    private var aiStreamingBuffer: [String] = []  // AI流式内容缓冲
    private var lastAIStreamingTime: TimeInterval = 0  // 上次AI流式更新时间
    
    // 🚨 【关键修复】状态机属性
    var animationState: AnimationState = .idle
    var pendingUserMessageId: String? = nil
    
    // 🚨 【新增】专门用于抑制AI滚动动画的状态
    private var isAnimatingUserMessage = false  // 用户消息飞入动画期间的标记
    // 🔧 新增：插入动画前后短窗抑制AI滚动（基于CACurrentMediaTime）
    private var suppressAIAnimatedScrollUntil: CFTimeInterval = 0
    private func shouldSuppressAIAnimatedScroll() -> Bool {
        return isAnimatingUserMessage || CACurrentMediaTime() < suppressAIAnimatedScrollUntil
    }

    // 过滤函数：发送动画期间隐藏尾部的AI占位（空文本）
    private func filteredVisibleMessagesForAnimation(all: [ChatMessage]) -> [ChatMessage] {
        // 不再隐藏尾部AI空占位，保证首次发送也能看到加载动画
        return all
    }
    
    // 约束
    private var containerTopConstraint: NSLayoutConstraint!
    private var containerHeightConstraint: NSLayoutConstraint!
    private var containerLeadingConstraint: NSLayoutConstraint!
    private var containerTrailingConstraint: NSLayoutConstraint!
    private var horizontalOffset: CGFloat = 0
    
    init(manager: ChatOverlayManager) {
        self.manager = manager
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupInputDrawerObservers()  // 新增：监听输入框位置变化
        // 初始化可见消息为当前数据层
        visibleMessages = manager?.messages ?? []
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // 在视图出现后设置触摸事件透传
        setupPassthroughView()
    }
    
    private func setupInputDrawerObservers() {
        // 监听输入框实际位置变化：仅用于首次收缩的精确对齐（之后不再依赖）
        NotificationCenter.default.addObserver(
            forName: Notification.Name("inputDrawerActualPositionChanged"),
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let self = self else { return }
            guard let manager = self.manager else { return }
            guard manager.currentState == .collapsed else { return }
            guard let value = note.userInfo?["actualBottomSpace"] as? CGFloat else { return }

            let screenHeight = UIScreen.main.bounds.height
            let safeAreaTop = self.view.safeAreaInsets.top
            let gap: CGFloat = 10
            // 浮窗顶部 = 输入框底部 + gap
            let floatingTop = screenHeight - value + gap
            let relativeTopFromSafeArea = floatingTop - safeAreaTop

            if self.awaitingFirstCollapseAlign && !self.didFirstCollapseAlign {
                self.containerTopConstraint.constant = relativeTopFromSafeArea
                UIView.animate(
                    withDuration: 0.26,
                    delay: 0,
                    options: [.allowUserInteraction, .curveEaseInOut, .beginFromCurrentState]
                ) {
                    self.view.layoutIfNeeded()
                } completion: { _ in
                    self.didFirstCollapseAlign = true
                    self.awaitingFirstCollapseAlign = false
                    NSLog("🎯 ChatOverlay: 首次收缩对齐完成 actualBottom=\(value), top=\(relativeTopFromSafeArea)")
                }
            } else {
                // 非首次：不强制调整，由既有逻辑（updateUI）控制，避免双重动画
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        NSLog("🎯 ChatOverlay: 移除所有通知观察者")
    }
    
    private func setupPassthroughView() {
        // 使用更简单的方式：PassthroughView作为背景层，不移动现有的视图
        let passthroughView = ChatPassthroughView()
        passthroughView.manager = manager
        passthroughView.containerView = containerView
        passthroughView.backgroundColor = UIColor.clear
        
        // 将PassthroughView插入到view的最底层，不影响现有布局
        view.insertSubview(passthroughView, at: 0)
        passthroughView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            passthroughView.topAnchor.constraint(equalTo: view.topAnchor),
            passthroughView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            passthroughView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            passthroughView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        NSLog("🎯 ChatOverlay: PassthroughView设置完成，保持原有布局")
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.clear
        
        // 创建背景遮罩（仅在展开时显示）
        backgroundMaskView = UIView()
        // 稍微变浅的遮罩，避免整体过暗
        backgroundMaskView.backgroundColor = UIColor.black.withAlphaComponent(0.25)
        backgroundMaskView.alpha = 0
        backgroundMaskView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backgroundMaskView)
        
        // 创建主容器
        containerView = UIView()
        // 与输入框一致风格：深色纯色 + 浅色描边
        containerView.backgroundColor = UIColor(red: 17/255.0, green: 24/255.0, blue: 39/255.0, alpha: 0.96) // bg-gray-900 近似
        containerView.layer.cornerRadius = 12
        // 设置只有顶部两个角为圆角，营造从屏幕底部延伸上来的效果
        containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        containerView.layer.masksToBounds = true
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor(red: 31/255.0, green: 41/255.0, blue: 55/255.0, alpha: 1.0).cgColor // border-gray-800 近似
        containerView.layer.masksToBounds = true
        containerView.translatesAutoresizingMaskIntoConstraints = false
        // 🚨 【残影修复】初始化时隐藏容器，避免创建时显示空白形状
        containerView.alpha = 0
        view.addSubview(containerView)
        
        // 设置约束
        NSLayoutConstraint.activate([
            // 背景遮罩填满整个屏幕
            backgroundMaskView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundMaskView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundMaskView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundMaskView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        // 创建可变约束 - 包括宽度约束
        containerTopConstraint = containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 80)
        containerHeightConstraint = containerView.heightAnchor.constraint(equalToConstant: 65)
        horizontalOffset = manager?.horizontalOffset ?? 0
        containerLeadingConstraint = containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16 + horizontalOffset)
        containerTrailingConstraint = containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        
        containerTopConstraint.isActive = true
        containerHeightConstraint.isActive = true
        containerLeadingConstraint.isActive = true
        containerTrailingConstraint.isActive = true
        
        setupCollapsedView()
        setupExpandedView()
        
        // 只添加拖拽手势到整个容器，移除点击手势避免误触
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        containerView.addGestureRecognizer(panGesture)
    }

    // 移除误放置在类外的布局方法（已移动到OverlayViewController内部）
    
    private func setupCollapsedView() {
        collapsedView = UIView()
        collapsedView.translatesAutoresizingMaskIntoConstraints = false
        // 🚨 【残影修复】初始化时就隐藏collapsedView，避免创建时短暂显示
        collapsedView.alpha = 0
        containerView.addSubview(collapsedView)
        
        // 创建收缩状态的控制栏
        let controlBar = UIView()
        controlBar.translatesAutoresizingMaskIntoConstraints = false
        collapsedView.addSubview(controlBar)
        
        // 完成按钮
        let completeButton = UIButton(type: .system)
        completeButton.setTitle("完成", for: .normal)
        completeButton.setTitleColor(.systemBlue, for: .normal)
        completeButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        completeButton.addTarget(self, action: #selector(completeButtonTapped), for: .touchUpInside)
        completeButton.translatesAutoresizingMaskIntoConstraints = false
        controlBar.addSubview(completeButton)
        
        // 当前对话标题
        let titleLabel = UILabel()
        titleLabel.text = "当前对话"
        titleLabel.textColor = .systemGray
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        controlBar.addSubview(titleLabel)
        
        // 关闭按钮
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("×", for: .normal)
        closeButton.setTitleColor(.systemGray, for: .normal)
        closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        controlBar.addSubview(closeButton)
        
        // 为收缩状态添加点击放大手势
        let collapsedTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleCollapsedTap))
        collapsedView.addGestureRecognizer(collapsedTapGesture)
        
        NSLayoutConstraint.activate([
            // 收缩视图填满容器
            collapsedView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            collapsedView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            collapsedView.topAnchor.constraint(equalTo: containerView.topAnchor),
            collapsedView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            // 控制栏约束
            controlBar.leadingAnchor.constraint(equalTo: collapsedView.leadingAnchor, constant: 16),
            controlBar.trailingAnchor.constraint(equalTo: collapsedView.trailingAnchor, constant: -16),
            controlBar.centerYAnchor.constraint(equalTo: collapsedView.centerYAnchor),
            controlBar.heightAnchor.constraint(equalToConstant: 40),
            
            // 按钮约束
            completeButton.leadingAnchor.constraint(equalTo: controlBar.leadingAnchor),
            completeButton.centerYAnchor.constraint(equalTo: controlBar.centerYAnchor),
            
            titleLabel.centerXAnchor.constraint(equalTo: controlBar.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: controlBar.centerYAnchor),
            
            closeButton.trailingAnchor.constraint(equalTo: controlBar.trailingAnchor),
            closeButton.centerYAnchor.constraint(equalTo: controlBar.centerYAnchor),
        ])
    }
    
    private func setupExpandedView() {
        expandedView = UIView()
        expandedView.translatesAutoresizingMaskIntoConstraints = false
        expandedView.alpha = 0
        containerView.addSubview(expandedView)
        
        // 拖拽指示器
        dragIndicator = UIView()
        dragIndicator.backgroundColor = .systemGray3
        dragIndicator.layer.cornerRadius = 2
        dragIndicator.translatesAutoresizingMaskIntoConstraints = false
        expandedView.addSubview(dragIndicator)
        
        // 头部标题区域
        let headerView = UIView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        expandedView.addSubview(headerView)
        
        let titleLabel = UILabel()
        titleLabel.text = "ChatOverlay 对话"
        titleLabel.textColor = .label
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(titleLabel)
        
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("×", for: .normal)
        closeButton.setTitleColor(.systemGray, for: .normal)
        closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(closeButton)
        
        // 为头部区域添加点击收起手势（只在头部有效）
        let headerTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleHeaderTap))
        headerView.addGestureRecognizer(headerTapGesture)
        
        // 为拖拽指示器也添加点击手势
        let dragIndicatorTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleHeaderTap))
        dragIndicator.addGestureRecognizer(dragIndicatorTapGesture)
        
        // 消息列表
        messagesList = UITableView()
        messagesList.backgroundColor = .clear
        messagesList.separatorStyle = .none
        messagesList.translatesAutoresizingMaskIntoConstraints = false
        messagesList.dataSource = self
        messagesList.delegate = self
        messagesList.register(MessageTableViewCell.self, forCellReuseIdentifier: "MessageCell")
        messagesList.estimatedRowHeight = 60
        messagesList.rowHeight = UITableView.automaticDimension
        expandedView.addSubview(messagesList)
        
        // 底部留空区域
        let bottomSpaceView = UIView()
        bottomSpaceView.translatesAutoresizingMaskIntoConstraints = false
        expandedView.addSubview(bottomSpaceView)
        
        NSLayoutConstraint.activate([
            // 展开视图填满容器
            expandedView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            expandedView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            expandedView.topAnchor.constraint(equalTo: containerView.topAnchor),
            expandedView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            // 拖拽指示器
            dragIndicator.topAnchor.constraint(equalTo: expandedView.topAnchor, constant: 16),
            dragIndicator.centerXAnchor.constraint(equalTo: expandedView.centerXAnchor),
            dragIndicator.widthAnchor.constraint(equalToConstant: 48),
            dragIndicator.heightAnchor.constraint(equalToConstant: 4),
            
            // 头部区域
            headerView.topAnchor.constraint(equalTo: dragIndicator.bottomAnchor, constant: 16),
            headerView.leadingAnchor.constraint(equalTo: expandedView.leadingAnchor, constant: 16),
            headerView.trailingAnchor.constraint(equalTo: expandedView.trailingAnchor, constant: -16),
            headerView.heightAnchor.constraint(equalToConstant: 44),
            
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            
            closeButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            closeButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            
            // 消息列表
            messagesList.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 16),
            messagesList.leadingAnchor.constraint(equalTo: expandedView.leadingAnchor),
            messagesList.trailingAnchor.constraint(equalTo: expandedView.trailingAnchor),
            messagesList.bottomAnchor.constraint(equalTo: bottomSpaceView.topAnchor),
            
            // 底部留空
            bottomSpaceView.leadingAnchor.constraint(equalTo: expandedView.leadingAnchor),
            bottomSpaceView.trailingAnchor.constraint(equalTo: expandedView.trailingAnchor),
            bottomSpaceView.bottomAnchor.constraint(equalTo: expandedView.bottomAnchor),
            bottomSpaceView.heightAnchor.constraint(equalToConstant: 120)  // 增加到120px，为输入框预留足够空间
        ])
    }
    
    func updateForState(_ state: OverlayState) {
        let screenHeight = UIScreen.main.bounds.height
        let safeAreaTop = view.safeAreaLayoutGuide.layoutFrame.minY
        let safeAreaBottom = screenHeight - view.safeAreaLayoutGuide.layoutFrame.maxY
        
        NSLog("🎯 更新UI状态: \(state), 屏幕高度: \(screenHeight), 安全区顶部: \(safeAreaTop), 安全区底部: \(safeAreaBottom)")
        
        switch state {
        case .collapsed:
            // 收缩状态：浮窗顶部与收缩状态下输入框底部-10px对齐
            let floatingHeight: CGFloat = 65
            let gap: CGFloat = 10  // 浮窗顶部与输入框底部的间隙
            
            // InputDrawer在collapsed状态下的bottomSpace是40px（降低整体高度50px）
            let inputBottomSpaceCollapsed: CGFloat = 40
            
            // 计算输入框在collapsed状态下的底部位置
            // 输入框底部 = 屏幕高度 - 安全区底部 - bottomSpace
            let inputDrawerBottomCollapsed = screenHeight - safeAreaBottom - inputBottomSpaceCollapsed
            
            // 浮窗顶部 = 输入框底部 + 间隙
            // 浮窗在输入框下方10px
            let floatingTop = inputDrawerBottomCollapsed + gap
            
            // 转换为相对于安全区顶部的坐标
            let relativeTopFromSafeArea = floatingTop - safeAreaTop
            
            containerTopConstraint.constant = relativeTopFromSafeArea
            containerHeightConstraint.constant = floatingHeight
            
            // 收起状态：与输入框一样宽度（屏幕宽度减去左右各16px边距）
            containerLeadingConstraint.constant = 16 + horizontalOffset
            containerTrailingConstraint.constant = -16 + horizontalOffset
            
            collapsedView.alpha = 1
            expandedView.alpha = 0
            backgroundMaskView.alpha = 0
            // 收缩状态圆角：恢复原始12px圆角
            containerView.layer.cornerRadius = 12
            containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            
            // 重置滚动收起标记，允许下次触发
            hasTriggeredScrollCollapse = false
            
            NSLog("🎯 收缩状态 - 输入框底部: \(inputDrawerBottomCollapsed)px, 浮窗顶部: \(floatingTop)px, 相对安全区顶部: \(relativeTopFromSafeArea)px, 间距: \(gap)px")
            
        case .expanded:
            // 展开状态：覆盖整个屏幕高度，营造从屏幕外延伸的效果
            let expandedTopMargin = max(safeAreaTop, 80)  // 顶部留空
            let expandedBottomExtension: CGFloat = 20  // 底部向外延伸20px，营造延伸效果
            
            containerTopConstraint.constant = expandedTopMargin - safeAreaTop  // 转换为相对安全区坐标
            // 高度计算：从顶部到屏幕底部再延伸20px
            containerHeightConstraint.constant = screenHeight - expandedTopMargin + expandedBottomExtension
            
            // 展开状态：覆盖整个屏幕宽度（无边距）
            containerLeadingConstraint.constant = horizontalOffset
            containerTrailingConstraint.constant = horizontalOffset
            
            NSLog("🔥 [残影修复] 设置UI元素可见性 - containerView: 显示, collapsedView: 隐藏, expandedView: 显示")
            containerView.alpha = 1  // 🚨 【残影修复】展开状态时显示容器
            collapsedView.alpha = 0
            expandedView.alpha = 1
            backgroundMaskView.alpha = 1
            // 展开状态圆角：只有顶部圆角，底部延伸到屏幕外
            containerView.layer.cornerRadius = 12
            containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            
            // 重置滚动收起标记，允许触发
            hasTriggeredScrollCollapse = false
            
            NSLog("🎯 展开状态 - 顶部位置: \(expandedTopMargin)px, 高度: \(screenHeight - expandedTopMargin + expandedBottomExtension)px, 底部延伸: \(expandedBottomExtension)px")
            
        case .hidden:
            // 隐藏状态：不显示
            containerView.alpha = 0
            hasTriggeredScrollCollapse = false
            NSLog("🎯 隐藏状态")
        }
        
        NSLog("🎯 最终约束 - Top: \(containerTopConstraint.constant), Height: \(containerHeightConstraint.constant)")
    }

    func setHorizontalOffset(_ offset: CGFloat, animated: Bool) {
        let normalized = max(0, offset)
        NSLog("🎯 ChatOverlay VC: 更新水平偏移 -> \(normalized) (animated: \(animated))")
        if abs(horizontalOffset - normalized) < 0.5 {
            horizontalOffset = normalized
            return
        }
        horizontalOffset = normalized
        let state = manager?.currentState ?? .collapsed
        let updates = {
            self.updateForState(state)
            self.view.layoutIfNeeded()
        }
        if animated {
            UIView.animate(
                withDuration: 0.25,
                delay: 0,
                usingSpringWithDamping: 0.85,
                initialSpringVelocity: 0.3,
                options: [.allowUserInteraction, .beginFromCurrentState]
            ) {
                updates()
            }
        } else {
            updates()
        }
    }
    
    @objc private func handleHeaderTap() {
        NSLog("🎯 头部区域被点击，切换状态")
        guard let manager = manager else { return }
        manager.toggleState()
    }
    
    @objc private func handleCollapsedTap() {
        NSLog("🎯 收缩状态被点击，放大浮窗")
        guard let manager = manager else { return }
        manager.switchToExpanded()
    }
    
    @objc private func handleTap() {
        // 这个方法现在不会被调用，因为已经移除了通用点击手势
        // 保留方法以防后续需要
        NSLog("🎯 通用点击处理（已禁用）")
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)
        
        switch gesture.state {
        case .began:
            NSLog("🎯 开始拖拽手势")
            dragStartY = gesture.location(in: view).y
            originalTopConstraint = containerTopConstraint.constant  // 记录拖拽开始的位置
            isDragging = true
            
            // 检查是否在拖拽区域
            let touchPoint = gesture.location(in: containerView)
            let isDragHandle = expandedView.alpha > 0 && touchPoint.y <= 80 // 头部80px为拖拽区域
            NSLog("🎯 触摸点: \(touchPoint), 是否在拖拽区域: \(isDragHandle), 初始Top: \(originalTopConstraint)")
            
        case .changed:
            guard isDragging else { return }
            
            let deltaY = translation.y
            NSLog("🎯 拖拽变化: \(deltaY)px")
            
            // 处理展开状态下的拖拽
            if manager?.currentState == .expanded {
                // 只允许向下拖拽收起
                if deltaY > 0 {
                    // 检查消息列表是否滚动到顶部
                    if let messagesList = expandedView.subviews.first(where: { $0 is UITableView }) as? UITableView {
                        let isAtTop = messagesList.contentOffset.y <= 1
                        
                        if isAtTop || deltaY <= 20 { // 微小拖拽优先级最高
                            NSLog("🎯 允许拖拽收起: deltaY=\(deltaY), isAtTop=\(isAtTop)")
                            // 更流畅的实时预览 - 基于原始位置计算
                            let dampedDelta = deltaY * 0.2 // 减少跟手程度
                            let newTop = originalTopConstraint + dampedDelta
                            
                            // 直接设置约束，无动画，实现流畅跟手
                            containerTopConstraint.constant = newTop
                            view.layoutIfNeeded()
                        }
                    }
                }
            }
            
        case .ended, .cancelled:
            guard isDragging else { return }
            isDragging = false
            
            let deltaY = translation.y
            let velocityY = velocity.y
            
            NSLog("🎯 拖拽结束: deltaY=\(deltaY), velocityY=\(velocityY)")
            
            // 判断是否应该切换状态
            let shouldSwitchToCollapsed = deltaY > 50 || (deltaY > 20 && velocityY > 500)
            
            if manager?.currentState == .expanded && shouldSwitchToCollapsed {
                NSLog("🎯 拖拽距离/速度足够，切换到收缩状态")
                // 使用专门的拖拽切换方法，避免延迟造成的卡顿
                manager?.switchToCollapsedFromDrag()
            } else {
                NSLog("🎯 拖拽不足，回弹到原状态")
                // 回弹动画 - 使用与主动画相同的spring参数
                UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: [.allowUserInteraction, .curveEaseInOut], animations: {
                    if let currentState = self.manager?.currentState {
                        self.updateForState(currentState)
                    }
                    self.view.layoutIfNeeded()
                })
            }
            
        default:
            break
        }
    }
    
    @objc private func completeButtonTapped() {
        manager?.hide()
    }
    
    @objc private func closeButtonTapped() {
        manager?.hide()
    }
    
    // MARK: - 更新消息列表
    
    func updateMessages(_ messages: [ChatMessage], oldMessages: [ChatMessage], shouldAnimateNewUserMessage: Bool, animationIndex: Int? = nil) {
        NSLog("🎯 OverlayViewController: updateMessages被调用，消息数量: \(messages.count)")
        NSLog("🎯 状态快照: animationState=\(animationState), isAnimatingInsert=\(isAnimatingInsert), isUserMessageAnimating=\(isUserMessageAnimating), visibleMessages=\(visibleMessages.count)")
        guard let manager = manager else { 
            NSLog("⚠️ OverlayViewController: manager为nil")
            return 
        }
        
        // 🚨 【动画锁定机制】第一层检查：如果正在播放插入动画，缓存AI文本，动画完成后回放
        if isAnimatingInsert {
            NSLog("🚨 【动画锁定】正在播放用户插入动画：缓存AI文本，动画完成后回放")
            // 同步数据层
            manager.messages = messages
            if let last = messages.last, !last.isUser {
                aiTargetFullText = last.text
                aiMessageId = last.id
                NSLog("🚨 【动画锁定】缓存AI目标文本长度: \(aiTargetFullText.count)")
            }
            return
        }
        
        // 🚨 【关键修复】流式输出与动画协调：如果用户消息动画进行中，缓冲AI流式更新
        if isUserMessageAnimating {
            NSLog("🚨 【流式协调】用户消息动画进行中，缓冲AI流式更新")
            if let last = messages.last, !last.isUser {
                // 将AI流式更新加入缓冲
                aiStreamingBuffer.append(last.text)
                lastAIStreamingTime = CACurrentMediaTime()
                NSLog("🚨 【流式协调】AI流式内容已缓冲，当前缓冲长度: \(aiStreamingBuffer.count)")
            }
            return
        }
        
        NSLog("🎯 OverlayViewController: manager存在，准备更新UI")
        NSLog("🎯 是否需要播放用户消息动画: \(shouldAnimateNewUserMessage)")
        if let index = animationIndex {
            NSLog("🎯 动画索引: \(index)")
        }
        
        // 记录旧消息数量，用于判断更新场景（使用传入的oldMessages而非当前manager.messages）
        let oldMessagesCount = oldMessages.count
        
        // 先更新manager的消息列表，并同步到渲染层（非动画期）
        manager.messages = messages
        self.visibleMessages = messages
        
        DispatchQueue.main.async {
            if shouldAnimateNewUserMessage, let targetIndex = animationIndex {
                // 🎯 场景1：有新用户消息，需要整体重载并播放动画
                NSLog("🎯 【场景1】新用户消息需要动画，执行完整重载和动画")
                // 双保险：若已有调度或处于动画中，直接跳过本次动画调度
                if self.hasScheduledInsertAnimation || self.isAnimatingInsert {
                    NSLog("🚧 已有插入动画在调度/进行，跳过重复调度")
                    return
                }
                // 若同一消息在短时间内已播放过动画，跳过（防止抖动重复）
                if let lastId = self.lastAnimatedUserMessageId,
                   messages.indices.contains(targetIndex),
                   messages[targetIndex].id == lastId,
                   CACurrentMediaTime() - self.lastAnimationTimestamp < 1.0 {
                    NSLog("🚧 同一消息短窗重复触发，跳过动画调度")
                    return
                }

                // 🚨 【动画锁定】加锁
                self.isAnimatingInsert = true
                self.hasScheduledInsertAnimation = true
                self.pendingAnimationIndex = targetIndex
                // 🔧 预先设定短窗抑制，保证插入动画前的准备阶段不被AI滚动打断
                self.suppressAIAnimatedScrollUntil = CACurrentMediaTime() + 0.4
                // 发送动画期间隐藏尾部AI占位
                self.visibleMessages = self.filteredVisibleMessagesForAnimation(all: messages)
                self.messagesList.reloadData()
                // 布局稳定屏障：确保列表和父视图在开始动画前完成布局
                self.messagesList.layoutIfNeeded()
                self.view.layoutIfNeeded()

                self.scrollToBottomAndPlayAnimation(messages: self.visibleMessages) {
                    // 🚨 【动画锁定】动画完成回调 - 解锁并处理
                    NSLog("🚨 【动画锁定】动画完成，解锁并呈现当前文本")
                    self.isAnimatingInsert = false
                    self.hasScheduledInsertAnimation = false
                    // 动画完成：直接呈现当前文本（不启用原生回放，由JS逐字推进）
                    self.visibleMessages = self.manager?.messages ?? []
                    self.safeReloadData(reason: "动画完成呈现当前文本")
                    if let count = self.manager?.messages.count, count > 0 {
                        let indexPath = IndexPath(row: count - 1, section: 0)
                        self.safeScrollToRow(indexPath, at: .bottom, animated: false, reason: "动画完成滚到底")
                    }
                    // 清空期间缓存（由JS继续逐字）
                    self.pendingAIUpdates.removeAll()
                }
                
            } else if messages.count == oldMessagesCount && messages.count > 0 {
                // 🎯 场景2：AI流式更新（消息总数不变，只是内容变了）
                NSLog("🎯 【场景2】AI流式更新，使用精细化cell更新")
                let lastMessageIndex = messages.count - 1
                let indexPath = IndexPath(row: lastMessageIndex, section: 0)
                
                if let lastCell = self.messagesList.cellForRow(at: indexPath) as? MessageTableViewCell {
                    // 直接更新cell的内容，不触发reloadData
                    NSLog("🎯 ✅ 直接更新最后一个AI消息cell")
                    if self.aiBufferTimer != nil {
                        // 正在回放：仅更新目标全文，不直接改UI，交由计时器推进
                        self.aiTargetFullText = messages[lastMessageIndex].text
                        NSLog("🎯 回放中：更新AI目标全文长度为 \(self.aiTargetFullText.count)")
                    } else {
                        lastCell.configure(with: messages[lastMessageIndex])
                        // 使动态高度立即生效，且不做高度动画
                        lastCell.setNeedsLayout()
                        lastCell.layoutIfNeeded()
                        UIView.performWithoutAnimation {
                            self.messagesList.beginUpdates()
                            self.messagesList.endUpdates()
                        }
                    }
                    
                    // 🚨 【关键修复】检查短窗/动画状态，决定是否滚动
                    let shouldAnimateScroll = !self.shouldSuppressAIAnimatedScroll()
                    NSLog("🚨 【动画抑制】AI更新滚动检查: isAnimatingUserMessage = \(self.isAnimatingUserMessage), suppressUntil = \(self.suppressAIAnimatedScrollUntil), now = \(CACurrentMediaTime()), shouldAnimateScroll = \(shouldAnimateScroll)")
                    
                    // 确保滚动到底部显示完整内容（接近底部才滚动；并根据动画状态决定是否使用动画）
                    if self.shouldAutoScrollToBottom() {
                        self.safeScrollToRow(indexPath, at: .bottom, animated: shouldAnimateScroll, reason: "AI流式可见cell")
                    } else {
                        NSLog("🧭 AutoScroll 取消：不在底部或用户正在交互")
                    }
                    
                    if shouldAnimateScroll {
                        NSLog("🎯 ✅ AI滚动动画正常执行")
                    } else {
                        NSLog("🚨 【动画抑制】AI滚动动画被抑制，使用静默滚动")
                    }
                } else {
                    // 如果cell不可见，reloadData是无法避免的后备方案
                    NSLog("🎯 ⚠️ AI消息cell不可见，使用后备reloadData方案")
                    if self.aiBufferTimer != nil {
                        // 回放时避免一次性呈现，改为只更新目标全文
                        self.aiTargetFullText = messages[lastMessageIndex].text
                        NSLog("🎯 回放中（不可见）：更新AI目标全文长度为 \(self.aiTargetFullText.count)")
                    } else {
                        self.visibleMessages = messages
                        self.messagesList.reloadData()
                    }
                    
                    // 同样应用自动滚动与动画抑制逻辑到后备方案
                    let shouldAnimateScroll = !self.shouldSuppressAIAnimatedScroll()
                    if self.shouldAutoScrollToBottom() {
                        self.safeScrollToRow(indexPath, at: .bottom, animated: shouldAnimateScroll, reason: "AI流式后备")
                    } else {
                        NSLog("🧭 AutoScroll 取消（后备）：不在底部或用户正在交互")
                    }
                }
                
            } else {
                // 🎯 场景3：其他情况（例如，从历史记录加载），直接重载
                NSLog("🎯 【场景3】其他更新场景，执行常规重载")
                self.visibleMessages = messages
                self.safeReloadData(reason: "场景3常规重载")
                if messages.count > 0 {
                    let indexPath = IndexPath(row: messages.count - 1, section: 0)
                    if self.shouldAutoScrollToBottom() {
                        self.safeScrollToRow(indexPath, at: .bottom, animated: false, reason: "场景3滚动到底")
                    }
                }
            }
        }
    }
    
    // 🔧 修改：滚动并播放动画的辅助方法 - 添加完成回调支持
    private func scrollToBottomAndPlayAnimation(messages: [ChatMessage], completion: @escaping () -> Void) {
        guard messages.count > 0 else { 
            completion()  // 如果没有消息，直接调用完成回调
            return 
        }
        
        NSLog("🎯 滚动到最新消息并准备动画")
        // 使用可见消息列表，隐藏AI占位时不把它计入滚动目标
        let targetRow = max(0, self.visibleMessages.count - 1)
        let indexPath = IndexPath(row: targetRow, section: 0)
        self.messagesList.scrollToRow(at: indexPath, at: .bottom, animated: false)
        
        NSLog("🎯 准备播放用户消息动画")
        // 立即设置动画初始状态，防止出现直接显示
        DispatchQueue.main.async {
            NSLog("🎯 立即设置动画初始状态")
            self.setAnimationInitialState(messages: messages)
            // 布局稳定屏障：再次确保布局稳定后立刻开始动画
            self.messagesList.layoutIfNeeded()
            self.view.layoutIfNeeded()
            NSLog("🎯 开始播放动画")
            self.playUserMessageAnimation(messages: messages, completion: completion)
        }
    }

    // MARK: - 动画完成后回放AI缓冲
    private func beginAIReplayAfterAnimation() {
        // 停止可能存在的计时器
        aiBufferTimer?.invalidate(); aiBufferTimer = nil
        guard var all = manager?.messages, !all.isEmpty else { return }
        // 如果最后一条是AI，将其显示文本重置为当前已显示值（通常是空或已有部分）
        if let last = all.last, !last.isUser {
            aiTargetFullText = last.text
            aiDisplayedText = "" // 从空开始回放
            aiMessageId = last.id
            // 更新可见消息为完整列表，但将最后AI文本置空，准备回放
            if !visibleMessages.isEmpty {
                visibleMessages = all
                var lastVisible = visibleMessages.removeLast()
                lastVisible = ChatMessage(id: lastVisible.id, text: "", isUser: lastVisible.isUser, timestamp: lastVisible.timestamp)
                visibleMessages.append(lastVisible)
                safeReloadData(reason: "回放开始前呈现空AI行")
                let indexPath = IndexPath(row: visibleMessages.count - 1, section: 0)
                safeScrollToRow(indexPath, at: .bottom, animated: false, reason: "回放开始滚到底")
                // 首次出现淡入：让AI行从0到1的轻淡入
                if let cell = messagesList.cellForRow(at: indexPath) as? MessageTableViewCell {
                    cell.alpha = 0.0
                    cell.transform = CGAffineTransform(translationX: 0, y: 8)
                    UIView.animate(withDuration: 0.12) {
                        cell.alpha = 1.0
                        cell.transform = .identity
                    }
                }
            }
            // 启动回放计时器（每30ms追加一小段）
            aiBufferTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { [weak self] t in
                guard let self = self else { return }
                // 若目标文本增长（来自后续流式），继续以目标为准
                let target = self.aiTargetFullText
                if self.aiDisplayedText.count >= target.count {
                    t.invalidate(); self.aiBufferTimer = nil
                    return
                }
                // 每次追加最多6个字符（近似流逝效果）
                let nextEnd = min(target.count, self.aiDisplayedText.count + 6)
                let startIdx = target.index(target.startIndex, offsetBy: self.aiDisplayedText.count)
                let endIdx = target.index(target.startIndex, offsetBy: nextEnd)
                let chunk = String(target[startIdx..<endIdx])
                self.aiDisplayedText += chunk
                // 更新渲染层最后一个AI消息
                if !self.visibleMessages.isEmpty, let last = self.visibleMessages.last, !last.isUser {
                    var updated = self.visibleMessages.removeLast()
                    updated = ChatMessage(id: updated.id, text: self.aiDisplayedText, isUser: updated.isUser, timestamp: updated.timestamp)
                    self.visibleMessages.append(updated)
                    // 刷新最后一行
                    let indexPath = IndexPath(row: self.visibleMessages.count - 1, section: 0)
                    if let cell = self.messagesList.cellForRow(at: indexPath) as? MessageTableViewCell {
                        cell.configure(with: updated)
                        cell.setNeedsLayout(); cell.layoutIfNeeded()
                    } else {
                        self.safeReloadRows([indexPath], reason: "回放增量刷新最后一行", animation: .none)
                    }
                    self.messagesList.beginUpdates(); self.messagesList.endUpdates()
                    self.safeScrollToRow(indexPath, at: .bottom, animated: false, reason: "回放推进滚到底")
                }
            }
            RunLoop.main.add(aiBufferTimer!, forMode: .common)
        } else {
            // 无AI消息，直接呈现完整列表
            visibleMessages = all
            messagesList.reloadData()
        }
    }

    // 取消当前回放/流式呈现
    func cancelStreaming() {
        NSLog("🎯 OverlayViewController: 停止AI回放计时器")
        aiBufferTimer?.invalidate()
        aiBufferTimer = nil
    }
    
    // 🚨 【关键修复】处理缓冲的AI流式更新
    private func processBufferedAIUpdates() {
        guard !aiStreamingBuffer.isEmpty else {
            NSLog("🚨 【流式协调】无缓冲的AI更新需要处理")
            return
        }
        
        NSLog("🚨 【流式协调】开始处理\(aiStreamingBuffer.count)个缓冲的AI更新")
        
        // 获取最新的AI内容
        let latestAIContent = aiStreamingBuffer.last ?? ""
        aiStreamingBuffer.removeAll()
        
        // 更新消息列表中的AI内容
        if !visibleMessages.isEmpty, let lastIndex = visibleMessages.lastIndex(where: { !$0.isUser }) {
            var updatedMessages = visibleMessages
            updatedMessages[lastIndex] = ChatMessage(
                id: updatedMessages[lastIndex].id,
                text: latestAIContent,
                isUser: updatedMessages[lastIndex].isUser,
                timestamp: updatedMessages[lastIndex].timestamp
            )
            visibleMessages = updatedMessages
            
            // 更新UI
            let indexPath = IndexPath(row: lastIndex, section: 0)
            if let cell = messagesList.cellForRow(at: indexPath) as? MessageTableViewCell {
                cell.configure(with: updatedMessages[lastIndex])
                cell.setNeedsLayout()
                cell.layoutIfNeeded()
                messagesList.beginUpdates()
                messagesList.endUpdates()
                messagesList.scrollToRow(at: indexPath, at: .bottom, animated: true)
            } else {
                messagesList.reloadData()
            }
            
            NSLog("🚨 【流式协调】AI流式更新处理完成，内容长度: \(latestAIContent.count)")
            
            // 🚨 【关键修复】状态机转换：AI流式完成 -> 完成状态
            self.animationState = .completed
            NSLog("🚨 【状态机】AI流式更新完成，状态转换: aiStreaming -> completed")
        }
    }
    
    // 🔧 新增：设置动画初始状态
    private func setAnimationInitialState(messages: [ChatMessage]) {
        guard let lastUserMessageIndex = messages.lastIndex(where: { $0.isUser }) else { return }
        
        NSLog("🎯 设置动画初始状态，索引: \(lastUserMessageIndex)")
        NSLog("🎯 当前pendingAnimationIndex: \(pendingAnimationIndex ?? -1)")
        
        let indexPath = IndexPath(row: lastUserMessageIndex, section: 0)
        
        if let cell = self.messagesList.cellForRow(at: indexPath) {
            NSLog("🎯 找到用户消息cell，设置初始动画状态")
            
            // 🔧 关键修复：设置动画起始位置
            let inputToMessageDistance: CGFloat = 180
            let initialTransform = CGAffineTransform(translationX: 0, y: inputToMessageDistance)
            cell.transform = initialTransform
            cell.alpha = 0.0
            
            NSLog("🎯 ✅ 成功设置动画初始状态：Y偏移 \(inputToMessageDistance)px, alpha=0")
        } else {
            NSLog("⚠️ 未找到用户消息cell，无法设置初始状态")
        }
    }
    
    // 🔧 新增：播放用户消息动画
    // 🔧 修改：播放用户消息动画 - 添加完成回调支持
    private func playUserMessageAnimation(messages: [ChatMessage], completion: @escaping () -> Void) {
        guard let lastUserMessageIndex = messages.lastIndex(where: { $0.isUser }) else { 
            completion()  // 如果没有用户消息，直接调用完成回调
            return 
        }
        
        NSLog("🎯 播放用户消息动画，索引: \(lastUserMessageIndex)")
        NSLog("🎯 当前pendingAnimationIndex: \(pendingAnimationIndex ?? -1)")
        
        // 🔧 安全检查：确保这是我们要动画的消息
        guard pendingAnimationIndex == lastUserMessageIndex else {
            NSLog("⚠️ 索引不匹配，跳过动画。期望: \(pendingAnimationIndex ?? -1), 实际: \(lastUserMessageIndex)")
            completion()  // 即使跳过动画，也要调用完成回调
            return
        }
        
        let indexPath = IndexPath(row: lastUserMessageIndex, section: 0)
        
        if let cell = self.messagesList.cellForRow(at: indexPath) {
            NSLog("🎯 找到用户消息cell，开始播放从输入框到消息位置的动画")
            
            // 🚨 【关键修复】在动画真正开始时才标记消息为"已动画"，防止重复触发
            let userMessage = messages[lastUserMessageIndex]
            NSLog("🚨 【重复修复】动画开始，将消息ID加入animatedMessageIDs: \(userMessage.id)")
            
            // 🔧 立即清除动画标记，防止重复执行
            self.pendingAnimationIndex = nil
            NSLog("🎯 清除pendingAnimationIndex，防止重复动画")
            
                            // 🚨 【关键修复】设置用户消息动画状态，抑制AI滚动动画
                self.isAnimatingUserMessage = true
                self.isUserMessageAnimating = true  // 新增：标记用户消息动画进行中
                NSLog("🚨 【动画抑制】开始用户消息动画，设置isAnimatingUserMessage = true")
            
            // 🔧 修正：使用更自然的动画参数，纯垂直移动
            UIView.animate(
                withDuration: 0.5, // 🔧 加快到0.5秒，更流畅
                delay: 0,
                usingSpringWithDamping: 0.85, // 🔧 稍微提高阻尼，减少弹跳
                initialSpringVelocity: 0.6, // 🔧 提高初始速度
                options: [.curveEaseOut, .allowUserInteraction],
                animations: {
            // 已在Manager判定阶段记录animatedMessageIDs，这里不再重复插入
                    
                    // 🔧 关键：只有位移变换，移动到最终位置
                    cell.transform = .identity  // 恢复原始变换（0,0位移）
                    cell.alpha = 1.0           // 渐变显示
                    
                    // 🚨 【统一动画指挥权】在ChatOverlay动画中同步控制InputDrawer位移
                    // 发送消息后，ChatOverlay通常会切换到collapsed状态，InputDrawer需要上移
                    NSLog("🚨 【统一动画】同步控制InputDrawer位移到collapsed位置")
                    NotificationCenter.default.post(
                        name: Notification.Name("chatOverlayStateChanged"),
                        object: nil,
                        userInfo: [
                            "state": "collapsed",
                            "visible": true,
                            "source": "unified_animation"  // 标记这是统一动画控制
                        ]
                    )
                },
                completion: { finished in
                    NSLog("🎯 🚨 用户消息动画完成, finished: \(finished)")
                    
                    // 🚨 【关键修复】状态机转换：用户动画完成 -> AI流式状态
                    self.isAnimatingUserMessage = false
                    self.isUserMessageAnimating = false
                    self.animationState = .aiStreaming  // 转换到AI流式状态
                    NSLog("🚨 【状态机】用户消息动画完成，状态转换: userAnimating -> aiStreaming")
                    // 📣 通知JS：发送插入动画已完成（用于解锁逐字流式泵）
                    NotificationCenter.default.post(name: Notification.Name("chatOverlaySendAnimationCompleted"), object: nil)
                    
                    // 🔧 动画完成后，继续短暂抑制AI滚动动画，避免紧随的首包造成叠加观感
                    self.suppressAIAnimatedScrollUntil = CACurrentMediaTime() + 0.15
                    // 记录已播放动画的消息ID与时间戳
                    if let userIdx = messages.lastIndex(where: { $0.isUser }) {
                        self.lastAnimatedUserMessageId = messages[userIdx].id
                        self.lastAnimationTimestamp = CACurrentMediaTime()
                    }
                    
                    // 🚨 【关键修复】动画完成后开启回放计时器（逐字流逝）
                    self.beginAIReplayAfterAnimation()
                    
                    // 🚨 【关键】调用完成回调，通知动画锁定机制解锁
                    completion()
                }
            )
        } else {
            NSLog("⚠️ 未找到用户消息cell，动画失败")
            self.pendingAnimationIndex = nil
            self.isAnimatingUserMessage = false
            completion()  // 即使动画失败，也要调用完成回调
        }
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension OverlayViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = visibleMessages.count
        NSLog("🎯 TableView numberOfRows: \(count)")
        return count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        NSLog("🎯 TableView cellForRowAt: \(indexPath.row)")
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath) as! MessageTableViewCell

        if indexPath.row < visibleMessages.count {
            let message = visibleMessages[indexPath.row]
            NSLog("🎯 配置cell: \(message.isUser ? "用户" : "AI") - \(message.text)")
            cell.configure(with: message)

            // 🔧 简化：所有cell都设置为正常状态，动画状态在reloadData后单独设置
            cell.transform = .identity
            cell.alpha = 1.0

        } else {
            NSLog("⚠️ 无法获取消息数据，索引: \(indexPath.row)")
        }

        return cell
    }

    // willDisplay 未做特殊处理
    
    // MARK: - 滚动监听：简化的下滑收起功能
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // 只在展开状态下处理滚动收起逻辑
        guard manager?.currentState == .expanded else { return }
        
        // 如果已经触发过滚动收起，不再重复处理
        guard !hasTriggeredScrollCollapse else { return }
        
        let currentOffset = scrollView.contentOffset.y
        NSLog("🎯 TableView滚动监听: contentOffset.y = \(currentOffset)")
        
        // 简化逻辑：只要向下拉超过110px就收起浮窗
        let minimumDownwardPull: CGFloat = -110.0
        
        if currentOffset <= minimumDownwardPull {
            NSLog("🎯 向下拉超过110px (\(currentOffset)px)，触发收起浮窗")
            
            // 设置标记，防止重复触发
            hasTriggeredScrollCollapse = true
            
            // 立即收起浮窗
            manager?.switchToCollapsedFromDrag()
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        let currentOffset = scrollView.contentOffset.y
        NSLog("🎯 开始拖拽TableView，起始offset: \(currentOffset)")
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        let finalOffset = scrollView.contentOffset.y
        NSLog("🎯 结束拖拽TableView，最终offset: \(finalOffset)，是否继续减速: \(decelerate)")
    }
}

// MARK: - MessageTableViewCell - 消息显示Cell

class MessageTableViewCell: UITableViewCell {
    
    private let messageContainerView = UIView()
    private let messageLabel = UILabel()
    private let timeLabel = UILabel()
    private let activity = StarRayActivityView()
    
    private var leadingConstraint: NSLayoutConstraint?
    private var trailingConstraint: NSLayoutConstraint?
    private var timeLabelConstraint: NSLayoutConstraint?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        // 重置约束
        leadingConstraint?.isActive = false
        trailingConstraint?.isActive = false
        timeLabelConstraint?.isActive = false
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        // 消息容器
        messageContainerView.layer.cornerRadius = 16
        messageContainerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(messageContainerView)
        
        // 消息文本
        messageLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageContainerView.addSubview(messageLabel)
        
        // 时间标签
        timeLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        timeLabel.textColor = .systemGray
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(timeLabel)
        
        // 自定义加载指示器（八芒星旋转）
        activity.translatesAutoresizingMaskIntoConstraints = false
        messageContainerView.addSubview(activity)
        
        // 设置固定的约束
        NSLayoutConstraint.activate([
            messageContainerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            messageContainerView.bottomAnchor.constraint(equalTo: timeLabel.topAnchor, constant: -4),
            
            messageLabel.topAnchor.constraint(equalTo: messageContainerView.topAnchor, constant: 12),
            messageLabel.leadingAnchor.constraint(equalTo: messageContainerView.leadingAnchor, constant: 16),
            messageLabel.trailingAnchor.constraint(equalTo: messageContainerView.trailingAnchor, constant: -16),
            messageLabel.bottomAnchor.constraint(equalTo: messageContainerView.bottomAnchor, constant: -12),
            
            activity.centerYAnchor.constraint(equalTo: messageContainerView.centerYAnchor),
            activity.leadingAnchor.constraint(equalTo: messageLabel.leadingAnchor),
            activity.widthAnchor.constraint(equalToConstant: 20),
            activity.heightAnchor.constraint(equalToConstant: 20),
            
            timeLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    
    func configure(with message: ChatMessage) {
        // 回退：使用普通文本渲染，避免富文本带来的替换/渲染问题
        messageLabel.attributedText = nil
        messageLabel.text = message.text
        // AI空文本 -> 显示loading指示器
        let isLoadingAI = (!message.isUser && message.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        if isLoadingAI {
            // 仅显示Star加载，不显示橄榄球样式的气泡/时间
            activity.isHidden = false
            activity.tintColor = UIColor.systemPurple
            activity.start()
            timeLabel.isHidden = true
            messageContainerView.backgroundColor = .clear
        } else {
            activity.stop()
            activity.isHidden = true
            timeLabel.isHidden = false
        }
        
        // 重置之前的约束
        leadingConstraint?.isActive = false
        trailingConstraint?.isActive = false
        timeLabelConstraint?.isActive = false
        
        // 根据是否是用户消息设置不同的样式
        if message.isUser {
            // 用户消息 - 右侧蓝色气泡
            messageContainerView.backgroundColor = UIColor.systemBlue
            messageLabel.textColor = .white
            
            // 设置约束 - 右对齐
            leadingConstraint = messageContainerView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 80)
            trailingConstraint = messageContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
            timeLabelConstraint = timeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        
        } else {
            // AI消息 - 左侧灰色气泡
            // 加载中已设置为透明；有内容时显示灰色气泡
            if !isLoadingAI {
                messageContainerView.backgroundColor = UIColor.systemGray5
            }
            messageLabel.textColor = .label
            
            // 设置约束 - 左对齐
            leadingConstraint = messageContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
            trailingConstraint = messageContainerView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -80)
            timeLabelConstraint = timeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
        }
        
        // 激活新约束
        leadingConstraint?.isActive = true
        trailingConstraint?.isActive = true
        timeLabelConstraint?.isActive = true
        
        // 格式化时间显示
        let date = Date(timeIntervalSince1970: message.timestamp / 1000)
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        timeLabel.text = formatter.string(from: date)
    }
}


// MARK: - ChatPassthroughView - 处理ChatOverlay触摸事件透传的自定义View
// 自定义旋转八芒星加载视图
class StarRayActivityView: UIView {
    private let rayCount = 8
    private let rayLength: CGFloat = 10
    private let rayWidth: CGFloat = 2
    private var rays: [CAShapeLayer] = []
    private var isAnimating = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        isOpaque = false
        setup()
    }

    private func setup() {
        // 创建8条射线
        for _ in 0..<rayCount {
            let layer = CAShapeLayer()
            layer.lineCap = .round
            layer.lineWidth = rayWidth
            layer.strokeColor = (tintColor ?? UIColor.systemPurple).cgColor
            layer.fillColor = UIColor.clear.cgColor
            self.layer.addSublayer(layer)
            rays.append(layer)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius: CGFloat = max(8, min(bounds.width, bounds.height) * 0.35)
        for (index, ray) in rays.enumerated() {
            let angle = CGFloat(index) * (2 * .pi / CGFloat(rayCount))
            let start = CGPoint(x: center.x + cos(angle) * (radius - rayLength),
                                y: center.y + sin(angle) * (radius - rayLength))
            let end = CGPoint(x: center.x + cos(angle) * (radius),
                              y: center.y + sin(angle) * (radius))
            let path = UIBezierPath()
            path.move(to: start)
            path.addLine(to: end)
            ray.path = path.cgPath
            ray.strokeColor = (tintColor ?? UIColor.systemPurple).cgColor
        }
    }

    func start() {
        guard !isAnimating else { return }
        isAnimating = true
        let anim = CABasicAnimation(keyPath: "transform.rotation.z")
        anim.fromValue = 0
        anim.toValue = 2 * Double.pi
        anim.duration = 1.0
        anim.repeatCount = .infinity
        anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        layer.add(anim, forKey: "star-rotate")
        isHidden = false
    }

    func stop() {
        guard isAnimating else { return }
        isAnimating = false
        layer.removeAnimation(forKey: "star-rotate")
    }
}

class ChatPassthroughView: UIView {
    weak var manager: ChatOverlayManager?
    weak var containerView: UIView?
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        NSLog("🎯 ChatPassthroughView hitTest: \(point), state: \(manager?.currentState ?? .collapsed)")
        
        guard let containerView = containerView else {
            NSLog("🎯 无containerView，透传触摸事件")
            return nil // 透传所有触摸
        }
        
        // 将点转换到containerView的坐标系
        let convertedPoint = convert(point, to: containerView)
        let containerBounds = containerView.bounds
        
        // 如果触摸点在containerView的边界内
        if containerBounds.contains(convertedPoint) {
            NSLog("🎯 触摸在ChatOverlay容器内，处理事件")
            return super.hitTest(point, with: event)
        } else {
            NSLog("🎯 触摸在ChatOverlay容器外，透传给下层")
            // 触摸点在containerView外部，透传给下层
            return nil
        }
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard let containerView = containerView else {
            return false
        }
        
        let convertedPoint = convert(point, to: containerView)
        let isInside = containerView.bounds.contains(convertedPoint)
        NSLog("🎯 ChatPassthroughView point inside: \(point) -> \(isInside)")
        return isInside
    }
}
    // removed misplaced viewDidLayoutSubviews (now correctly inside OverlayViewController)
