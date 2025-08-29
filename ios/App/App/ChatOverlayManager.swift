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
    static let chatOverlayVisibilityChanged = Notification.Name("chatOverlayVisibilityChanged")
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
    
    // 状态变化回调
    private var onStateChange: ((OverlayState) -> Void)?
    
    // 背景视图变换 - 用于3D缩放效果
    private weak var backgroundView: UIView?
    
    // MARK: - Public API
    
    func show(animated: Bool = true, expanded: Bool = false, completion: @escaping (Bool) -> Void) {
        NSLog("🎯 ChatOverlayManager: 显示浮窗, expanded: \(expanded)")
        
        DispatchQueue.main.async {
            if self.overlayWindow != nil {
                NSLog("🎯 浮窗已存在，直接显示并设置状态")
                self.overlayWindow?.isHidden = false
                self.isVisible = true
                
                // 根据参数设置初始状态
                if expanded {
                    self.currentState = .expanded
                    self.applyBackgroundTransform(for: .expanded, animated: animated)
                    // 发送状态通知
                    NotificationCenter.default.post(
                        name: .chatOverlayStateChanged,
                        object: nil,
                        userInfo: ["state": "expanded", "height": UIScreen.main.bounds.height - 100]
                    )
                } else {
                    self.currentState = .collapsed
                    self.applyBackgroundTransform(for: .collapsed, animated: animated)
                    // 发送状态通知，让InputDrawer先调整位置
                    NotificationCenter.default.post(
                        name: .chatOverlayStateChanged,
                        object: nil,
                        userInfo: ["state": "collapsed", "height": 65]
                    )
                }
                
                // 稍微延迟更新UI，确保InputDrawer已经调整位置
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.updateUI(animated: animated)
                }
                
                // 发送可见性和状态通知
                NotificationCenter.default.post(
                    name: .chatOverlayVisibilityChanged,
                    object: nil,
                    userInfo: ["visible": true]
                )
                NotificationCenter.default.post(
                    name: .chatOverlayStateChanged,
                    object: nil,
                    userInfo: ["state": expanded ? "expanded" : "collapsed", "height": expanded ? UIScreen.main.bounds.height - 100 : 65]
                )
                
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
                    
                    // 初始显示时立即更新UI
                    self.updateUI(animated: false)
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
                self.updateUI(animated: false)
                self.applyBackgroundTransform(for: self.currentState, animated: false)
                
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
        
        DispatchQueue.main.async {
            guard let window = self.overlayWindow else {
                completion()
                return
            }
            
            // 恢复背景状态
            self.applyBackgroundTransform(for: .collapsed, animated: animated)
            
            // 发送隐藏通知
            NotificationCenter.default.post(
                name: .chatOverlayVisibilityChanged,
                object: nil,
                userInfo: ["visible": false]
            )
            
            if animated {
                UIView.animate(withDuration: 0.3) {
                    window.alpha = 0
                } completion: { _ in
                    window.isHidden = true
                    self.isVisible = false
                    self.currentState = .hidden
                    completion()
                }
            } else {
                window.isHidden = true
                self.isVisible = false
                self.currentState = .hidden
                completion()
            }
        }
    }
    
    func updateMessages(_ messages: [ChatMessage]) {
        NSLog("🎯 ChatOverlayManager: 更新消息列表，数量: \(messages.count)")
        for (index, message) in messages.enumerated() {
            NSLog("🎯 消息[\(index)]: \(message.isUser ? "用户" : "AI") - \(message.text)")
        }
        self.messages = messages
        
        // 通知OverlayViewController更新消息显示
        DispatchQueue.main.async {
            NSLog("🎯 通知OverlayViewController更新消息显示")
            self.overlayViewController?.updateMessages(messages)
        }
    }
    
    func setLoading(_ loading: Bool) {
        NSLog("🎯 ChatOverlayManager: 设置加载状态: \(loading)")
        self.isLoading = loading
        // 这里可以更新UI，暂时先简化
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
        
        // 延迟更新UI，等待InputDrawer完成位置调整（从0.0改为0.2秒）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.updateUI(animated: true)
        }
        
        applyBackgroundTransform(for: .collapsed, animated: true)
        onStateChange?(.collapsed)
        
        // 注意：浮窗位置会在延迟后更新，确保基于正确的InputDrawer位置
    }
    
    func switchToExpanded() {
        NSLog("🎯 ChatOverlayManager: 切换到展开状态")
        currentState = .expanded
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
        currentState = (currentState == .collapsed) ? .expanded : .collapsed
        updateUI(animated: true)
        applyBackgroundTransform(for: currentState, animated: true)
        onStateChange?(currentState)
    }
    
    func setOnStateChange(_ callback: @escaping (OverlayState) -> Void) {
        self.onStateChange = callback
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
        
        let duration = animated ? 0.5 : 0.0
        let options: UIView.AnimationOptions = [.curveEaseInOut, .allowUserInteraction]
        
        UIView.animate(withDuration: duration, delay: 0, options: options, animations: {
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
        
        let duration = animated ? 0.3 : 0.0
        
        UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseInOut], animations: {
            overlayViewController.updateForState(self.currentState)
        }, completion: nil)
    }
    
    @objc private func closeButtonTapped() {
        NSLog("🎯 ChatOverlayManager: 关闭按钮被点击")
        hide()
    }
}

// MARK: - OverlayViewController - 处理双状态UI显示
class OverlayViewController: UIViewController {
    private weak var manager: ChatOverlayManager?
    internal var containerView: UIView!  // 改为internal让PassthroughWindow可以访问
    private var collapsedView: UIView!
    private var expandedView: UIView!
    private var backgroundMaskView: UIView!
    private var messagesList: UITableView!
    private var dragIndicator: UIView!
    
    // 拖拽相关状态 - 移到OverlayViewController中
    private var isDragging = false
    private var dragStartY: CGFloat = 0
    
    // 约束
    private var containerTopConstraint: NSLayoutConstraint!
    private var containerHeightConstraint: NSLayoutConstraint!
    private var containerLeadingConstraint: NSLayoutConstraint!
    private var containerTrailingConstraint: NSLayoutConstraint!
    
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
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // 在视图出现后设置触摸事件透传
        setupPassthroughView()
    }
    
    private func setupInputDrawerObservers() {
        // 注意：浮窗位置固定，不需要监听输入框位置变化
        // 只有InputDrawer会根据浮窗状态调整自己的位置
        NSLog("🎯 ChatOverlay: 浮窗使用固定位置，无需监听InputDrawer位置变化")
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
        backgroundMaskView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        backgroundMaskView.alpha = 0
        backgroundMaskView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backgroundMaskView)
        
        // 创建主容器
        containerView = UIView()
        containerView.backgroundColor = UIColor.systemGray6
        containerView.layer.cornerRadius = 12
        // 设置只有顶部两个角为圆角，营造从屏幕底部延伸上来的效果
        containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        containerView.translatesAutoresizingMaskIntoConstraints = false
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
        containerLeadingConstraint = containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16)
        containerTrailingConstraint = containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        
        containerTopConstraint.isActive = true
        containerHeightConstraint.isActive = true
        containerLeadingConstraint.isActive = true
        containerTrailingConstraint.isActive = true
        
        setupCollapsedView()
        setupExpandedView()
        
        // 添加手势
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        containerView.addGestureRecognizer(tapGesture)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        containerView.addGestureRecognizer(panGesture)
    }
    
    private func setupCollapsedView() {
        collapsedView = UIView()
        collapsedView.translatesAutoresizingMaskIntoConstraints = false
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
            bottomSpaceView.heightAnchor.constraint(equalToConstant: 80)
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
            containerLeadingConstraint.constant = 16
            containerTrailingConstraint.constant = -16
            
            collapsedView.alpha = 1
            expandedView.alpha = 0
            backgroundMaskView.alpha = 0
            // 收缩状态圆角：恢复原始12px圆角
            containerView.layer.cornerRadius = 12
            containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            
            NSLog("🎯 收缩状态 - 输入框底部: \(inputDrawerBottomCollapsed)px, 浮窗顶部: \(floatingTop)px, 相对安全区顶部: \(relativeTopFromSafeArea)px, 间距: \(gap)px")
            
        case .expanded:
            // 展开状态：覆盖大部分屏幕，底部留出空间给输入框
            // 这里可以假设输入框会自动调整位置
            let expandedBottomMargin: CGFloat = 80 // 给输入框预留足够空间
            
            containerTopConstraint.constant = max(safeAreaTop, 80)  // 顶部留空
            containerHeightConstraint.constant = screenHeight - max(safeAreaTop, 80) - expandedBottomMargin
            
            // 展开状态：覆盖整个屏幕宽度（无边距）
            containerLeadingConstraint.constant = 0
            containerTrailingConstraint.constant = 0
            
            collapsedView.alpha = 0
            expandedView.alpha = 1
            backgroundMaskView.alpha = 1
            // 展开状态圆角：恢复原始12px圆角
            containerView.layer.cornerRadius = 12
            containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            
            NSLog("🎯 展开状态 - 底部边距: \(expandedBottomMargin)px")
            
        case .hidden:
            // 隐藏状态：不显示
            containerView.alpha = 0
            NSLog("🎯 隐藏状态")
        }
        
        NSLog("🎯 最终约束 - Top: \(containerTopConstraint.constant), Height: \(containerHeightConstraint.constant)")
    }
    
    @objc private func handleTap() {
        guard let manager = manager else { return }
        manager.toggleState()
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)
        
        switch gesture.state {
        case .began:
            NSLog("🎯 开始拖拽手势")
            dragStartY = gesture.location(in: view).y
            isDragging = true
            
            // 检查是否在拖拽区域
            let touchPoint = gesture.location(in: containerView)
            let isDragHandle = expandedView.alpha > 0 && touchPoint.y <= 80 // 头部80px为拖拽区域
            NSLog("🎯 触摸点: \(touchPoint), 是否在拖拽区域: \(isDragHandle)")
            
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
                            // 实时更新位置预览
                            let progress = min(deltaY / 150, 1.0) // 150px完全切换
                            let originalTop = containerTopConstraint.constant
                            containerTopConstraint.constant = originalTop + deltaY * 0.3
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
                manager?.switchToCollapsed()
            } else {
                NSLog("🎯 拖拽不足，回弹到原状态")
                // 回弹动画
                UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: [], animations: {
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
    
    func updateMessages(_ messages: [ChatMessage]) {
        NSLog("🎯 OverlayViewController: updateMessages被调用，消息数量: \(messages.count)")
        guard let manager = manager else { 
            NSLog("⚠️ OverlayViewController: manager为nil")
            return 
        }
        NSLog("🎯 OverlayViewController: manager存在，准备更新UI")
        DispatchQueue.main.async {
            NSLog("🎯 OverlayViewController: 执行reloadData")
            self.messagesList.reloadData()
            // 滚动到底部显示最新消息
            if manager.messages.count > 0 {
                NSLog("🎯 OverlayViewController: 滚动到最新消息，索引: \(manager.messages.count - 1)")
                let indexPath = IndexPath(row: manager.messages.count - 1, section: 0)
                self.messagesList.scrollToRow(at: indexPath, at: .bottom, animated: true)
            } else {
                NSLog("⚠️ OverlayViewController: manager.messages为空")
            }
        }
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension OverlayViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = manager?.messages.count ?? 0
        NSLog("🎯 TableView numberOfRows: \(count)")
        return count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        NSLog("🎯 TableView cellForRowAt: \(indexPath.row)")
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath) as! MessageTableViewCell
        
        if let messages = manager?.messages, indexPath.row < messages.count {
            let message = messages[indexPath.row]
            NSLog("🎯 配置cell: \(message.isUser ? "用户" : "AI") - \(message.text)")
            cell.configure(with: message)
        } else {
            NSLog("⚠️ 无法获取消息数据，索引: \(indexPath.row)")
        }
        
        return cell
    }
}

// MARK: - MessageTableViewCell - 消息显示Cell

class MessageTableViewCell: UITableViewCell {
    
    private let messageContainerView = UIView()
    private let messageLabel = UILabel()
    private let timeLabel = UILabel()
    
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
        
        // 设置固定的约束
        NSLayoutConstraint.activate([
            messageContainerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            messageContainerView.bottomAnchor.constraint(equalTo: timeLabel.topAnchor, constant: -4),
            
            messageLabel.topAnchor.constraint(equalTo: messageContainerView.topAnchor, constant: 12),
            messageLabel.leadingAnchor.constraint(equalTo: messageContainerView.leadingAnchor, constant: 16),
            messageLabel.trailingAnchor.constraint(equalTo: messageContainerView.trailingAnchor, constant: -16),
            messageLabel.bottomAnchor.constraint(equalTo: messageContainerView.bottomAnchor, constant: -12),
            
            timeLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    
    func configure(with message: ChatMessage) {
        messageLabel.text = message.text
        
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
            messageContainerView.backgroundColor = UIColor.systemGray5
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