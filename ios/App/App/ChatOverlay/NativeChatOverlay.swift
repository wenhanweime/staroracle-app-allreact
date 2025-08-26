import SwiftUI
import Combine

@available(iOS 14.0, *)
struct NativeChatOverlay: View {
    @Binding var isExpanded: Bool
    
    // 拖拽状态
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    @State private var startDragY: CGFloat = 0
    
    // 对话状态
    @State private var conversationTitle = ""
    @State private var conversationAwareness: ConversationAwareness = ConversationAwareness()
    
    // 消息和加载状态
    @State private var messages: [ChatMessage] = []
    @State private var isLoading = false
    @State private var streamingMessage: ChatMessage? = nil
    
    // 键盘高度（从Capacitor传入）
    @State private var keyboardHeight: CGFloat = 0
    @State private var isKeyboardOpen = false
    
    // 输入框底部空间（动态计算）
    @State private var inputBottomSpace: CGFloat = 70
    
    // 视口高度（用于iOS键盘适配）
    @State private var viewportHeight: CGFloat = UIScreen.main.bounds.height
    
    // 初始输入和后续问题
    @State private var initialInput: String = ""
    @State private var followUpQuestion: String = ""
    @State private var hasProcessedInitialInput = false
    
    // 回调函数
    let onClose: () -> Void
    let onReopen: (() -> Void)? // 移除不必要的onSendMessage回调
    let onFollowUpProcessed: (() -> Void)?
    
    // 屏幕尺寸
    private var screenHeight: CGFloat {
        UIScreen.main.bounds.height
    }
    
    private var screenWidth: CGFloat {
        UIScreen.main.bounds.width
    }
    
    // 计算吸附位置 - 完全对应Web版本的getAttachedBottomPosition逻辑
    private func getAttachedBottomPosition() -> CGFloat {
        let gap: CGFloat = 5 // 浮窗顶部与输入框底部的间隙
        let floatingHeight: CGFloat = 65 // 浮窗关闭时高度65px
        
        // 浮窗顶部绝对位置 = 屏幕高度 - (inputBottomSpace - gap)
        // CSS bottom值 = (inputBottomSpace - gap) - floatingHeight
        return (inputBottomSpace - gap) - floatingHeight
    }
    
    var body: some View {
        ZStack {
            // 遮罩层 - 对应Web版本的背景遮罩
            if isExpanded {
                Color.black.opacity(0.4) // 对应Web版本bg-opacity-40
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            onClose()
                        }
                    }
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: isExpanded)
            }
            
            // 浮窗内容 - 关闭时吸附在底部，展开时全屏
            Group {
                if isExpanded {
                    expandedOverlayContent
                        .frame(maxWidth: .infinity)
                        .frame(height: calculateExpandedHeight())
                } else {
                    collapsedOverlayContent
                        .frame(height: 65) // 对应Web版本的固定高度
                        .frame(width: min(448, screenWidth - 32)) // 对应Web版本的 min(28rem, calc(100vw - 2rem))
                }
            }
            .background(
                RoundedRectangle(cornerRadius: isExpanded ? 16 : 32.5) // 对应Web版本的 rounded-t-2xl 和 rounded-full
                    .fill(Color(red: 0.11, green: 0.11, blue: 0.15)) // 对应Web版本的 bg-gray-900
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: -5) // 对应Web版本的 shadow-2xl
            )
            .position(calculatePosition())
            .opacity(calculateOpacity()) // 对应Web版本的拖拽透明度变化
            .animation(.spring(response: 0.3, dampingFraction: 0.8, blendDuration: 0.1), value: isExpanded)
            .animation(.easeOut(duration: 0.15), value: dragOffset)
            .onTapGesture {
                if !isExpanded {
                    if let onReopen = onReopen {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            onReopen()
                        }
                    }
                }
            }
            .simultaneousGesture(
                isExpanded ? expandedDragGesture : nil
            )
        }
        .onAppear {
            processInitialInput()
        }
        .onChange(of: followUpQuestion) { _ in
            processFollowUpQuestion()
        }
        .onChange(of: isExpanded) { expanded in
            if !expanded {
                hasProcessedInitialInput = false
                dragOffset = 0
            }
        }
    }
    
    // 收缩状态内容 - 对应Web版本的 !isOpen 状态
    private var collapsedOverlayContent: some View {
        attachedStateContent
    }
    
    // 展开状态内容 - 对应Web版本的 isOpen 状态
    private var expandedOverlayContent: some View {
        expandedStateContent
    }
    
    // 收缩状态的吸附栏 - 完全对应Web版本的 !isOpen 内容
    private var attachedStateContent: some View {
        HStack {
            // 左侧：完成按钮 - 对应Web版本的"完成"按钮
            Button("完成") {
                onClose()
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.blue)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 16)
            
            // 中间：当前对话标题 - 对应Web版本的"当前对话"
            Text("当前对话")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity)
            
            // 右侧：关闭按钮 - 对应Web版本的X按钮
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.trailing, 16)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            // 点击吸附栏展开浮窗 - 对应Web版本的onClick展开逻辑
            if let onReopen = onReopen {
                onReopen()
            }
        }
    }
    
    // 计算位置 - 对应Web版本的animate位置逻辑
    private func calculatePosition() -> CGPoint {
        if isExpanded {
            let topOffset = max(80.0, 80.0 + dragOffset)
            let availableHeight = viewportHeight - topOffset
            return CGPoint(
                x: screenWidth / 2,
                y: topOffset + availableHeight / 2
            )
        } else {
            return CGPoint(
                x: screenWidth / 2,
                y: screenHeight - getAttachedBottomPosition() - 32.5
            )
        }
    }
    
    // 计算展开状态高度 - 对应Web版本的高度计算
    private func calculateExpandedHeight() -> CGFloat {
        let topOffset = max(80.0, 80.0 + dragOffset)
        return viewportHeight - topOffset
    }
    
    // 计算透明度 - 对应Web版本的拖拽透明度变化
    private func calculateOpacity() -> Double {
        return max(0.9, 1.0 - Double(dragOffset / 500.0))
    }
    
    // 收缩状态点击手势
    private var collapsedTapGesture: some Gesture {
        TapGesture()
            .onEnded { _ in
                if let onReopen = onReopen {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        onReopen()
                    }
                }
            }
    }
    
    // 展开状态的拖拽手势 - 对应Web版本的拖拽逻辑
    private var expandedDragGesture: some Gesture {
        DragGesture(coordinateSpace: .global)
            .onChanged { value in
                if !isDragging {
                    isDragging = true
                    startDragY = value.startLocation.y
                }
                
                let deltaY = value.location.y - startDragY
                
                // 微小下拉动作（优先级最高）- 对应Web版本逻辑
                if deltaY > 0 && deltaY <= 20 {
                    print("📱 检测到微小下拉: \(deltaY)px，在整个浮窗范围内允许收起")
                    dragOffset = min(deltaY, screenHeight * 0.8)
                    return
                }
                
                // 大于20px的下拉动作才需要考虑滚动状态
                if deltaY > 20 {
                    print("📱 大幅下拉，允许拖拽浮窗")
                    dragOffset = min(deltaY, screenHeight * 0.8)
                }
            }
            .onEnded { value in
                isDragging = false
                let deltaY = value.location.y - startDragY
                
                print("📱 手指抬起，当前dragY: \(deltaY)px")
                
                // 微小拖拽更敏感的阈值 - 只要5px就能关闭浮窗
                if deltaY > 5 {
                    print("🔽 拖拽距离足够，关闭浮窗")
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        onClose()
                    }
                } else {
                    // 否则回弹到原位置
                    print("↩️ 拖拽距离不够，回弹")
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        dragOffset = 0
                    }
                }
            }
    }
    
    // 展开状态的内容 - 对应Web版本的展开状态
    private var expandedStateContent: some View {
        VStack(spacing: 0) {
            // 拖拽指示器和头部 - 对应Web版本的drag-handle区域
            VStack(spacing: 0) {
                // 拖拽指示器 - 对应Web版本的灰色小条
                HStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.6)) // 对应Web版本的bg-gray-600
                        .frame(width: 48, height: 6) // 对应Web版本的w-12 h-1.5
                    Spacer()
                }
                .padding(.top, 16)
                .padding(.bottom, 16)
                
                // 头部标题栏 - 对应Web版本的标题和关闭按钮区域
                HStack {
                    if !conversationTitle.isEmpty {
                        Text(conversationTitle)
                            .font(.system(size: 18, weight: .medium)) // 对应Web版本的stellar-title
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    }
                    .padding(8)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            
            // 消息列表区域 - 对应Web版本的ChatMessages组件
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        ForEach(messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                        
                        // AI加载指示器 - 对应Web版本的加载动画
                        if isLoading {
                            HStack {
                                HStack(spacing: 4) {
                                    ForEach(0..<3, id: \.self) { index in
                                        Circle()
                                            .fill(Color.gray)
                                            .frame(width: 8, height: 8)
                                            .scaleEffect(isLoading ? 1.0 : 0.5)
                                            .animation(
                                                .easeInOut(duration: 0.6)
                                                    .repeatForever()
                                                    .delay(Double(index) * 0.2),
                                                value: isLoading
                                            )
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color(red: 0.15, green: 0.15, blue: 0.2))
                                )
                                
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.vertical, 16)
                }
                .onChange(of: messages.count) { _ in
                    if let lastMessage = messages.last {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            .frame(maxHeight: .infinity)
            
            // 底部留空区域 - 对应Web版本的"底部留空，让主界面的ConversationDrawer输入框显示在这里"
            // 这里不放任何输入组件，输入框由JavaScript端的ConversationDrawer处理
            Spacer()
                .frame(height: isKeyboardOpen ? keyboardHeight + 20 : 100) // 为ConversationDrawer输入框和键盘留足够空间
        }
    }
    
    // 获取最后一条消息用于预览 - 对应Web版本的相同逻辑
    private func getLastMessagePreview() -> String {
        guard !messages.isEmpty else { return "" }
        let lastMessage = messages.last!
        let maxLength = 15 // 最大显示长度
        
        if lastMessage.text.count <= maxLength {
            return lastMessage.text
        }
        return String(lastMessage.text.prefix(maxLength)) + "..."
    }
    
    // 自动处理初始输入 - 通过JavaScript桥接发送到ConversationDrawer
    private func processInitialInput() {
        if !initialInput.isEmpty && !hasProcessedInitialInput {
            print("🔄 ChatOverlay接收到初始输入，转发给ConversationDrawer: \(initialInput)")
            hasProcessedInitialInput = true
            // 这里应该通过Capacitor通知JavaScript端的ConversationDrawer处理输入
        }
    }
    
    // 处理后续问题 - 通过JavaScript桥接发送到ConversationDrawer
    private func processFollowUpQuestion() {
        if !followUpQuestion.isEmpty {
            print("🔄 ChatOverlay接收到后续问题，转发给ConversationDrawer: \(followUpQuestion)")
            // 这里应该通过Capacitor通知JavaScript端的ConversationDrawer处理输入
            if let onFollowUpProcessed = onFollowUpProcessed {
                onFollowUpProcessed()
            }
        }
    }
    
    // 公共方法：从外部更新消息列表
    func updateMessages(_ newMessages: [ChatMessage]) {
        messages = newMessages
    }
    
    // 公共方法：设置加载状态
    func setLoading(_ loading: Bool) {
        isLoading = loading
    }
    
    // 公共方法：设置对话标题
    func setConversationTitle(_ title: String) {
        conversationTitle = title
    }
    
    // 公共方法：设置键盘高度（从Capacitor传入）
    func setKeyboardHeight(_ height: CGFloat) {
        keyboardHeight = height
        isKeyboardOpen = height > 0
        
        // 动态计算输入框底部空间
        if isKeyboardOpen {
            inputBottomSpace = height + 10
        } else {
            inputBottomSpace = 70 // 默认值
        }
    }
    
    // 公共方法：设置视口高度（用于iOS键盘适配）
    func setViewportHeight(_ height: CGFloat) {
        viewportHeight = height
    }
    
    // 公共方法：设置初始输入
    func setInitialInput(_ input: String) {
        initialInput = input
        processInitialInput()
    }
    
    // 公共方法：设置后续问题
    func setFollowUpQuestion(_ question: String) {
        followUpQuestion = question
        processFollowUpQuestion()
    }
}

// 对话觉察数据模型
struct ConversationAwareness {
    var overallLevel: Float = 0.0
    var isAnalyzing: Bool = false
    var conversationDepth: Int = 0
}

// 消息数据模型
struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    let timestamp: Date
}

// 消息气泡组件 - 对应Web版本的消息样式
@available(iOS 14.0, *)
struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
                
                Text(message.text)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.purple]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                    )
                    .foregroundColor(.white)
                    .frame(maxWidth: screenWidth * 0.7, alignment: .trailing)
            } else {
                Text(message.text)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(red: 0.15, green: 0.15, blue: 0.2))
                    )
                    .foregroundColor(.white)
                    .frame(maxWidth: screenWidth * 0.7, alignment: .leading)
                
                Spacer()
            }
        }
        .padding(.horizontal, 16)
    }
    
    private var screenWidth: CGFloat {
        UIScreen.main.bounds.width
    }
}