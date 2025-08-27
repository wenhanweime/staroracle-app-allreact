import SwiftUI
import UIKit
import Capacitor

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
}

// MARK: - ChatOverlayManager业务逻辑类
public class ChatOverlayManager {
    private var overlayWindow: UIWindow?
    private var isVisible = false
    internal var currentState: OverlayState = .collapsed
    private var messages: [ChatMessage] = []
    private var isLoading = false
    private var conversationTitle = ""
    private var keyboardHeight: CGFloat = 0
    private var viewportHeight: CGFloat = UIScreen.main.bounds.height
    private var initialInput = ""
    private var followUpQuestion = ""
    private var overlayViewController: OverlayViewController?
    internal var inputBottomSpace: CGFloat = 70  // 输入框底部空间，默认70px
    
    // 状态变化回调
    private var onStateChange: ((OverlayState) -> Void)?
    
    // 背景视图变换 - 用于3D缩放效果
    private weak var backgroundView: UIView?
    
    // MARK: - Public API
    
    func show(animated: Bool = true, completion: @escaping (Bool) -> Void) {
        NSLog("🎯 ChatOverlayManager: 显示浮窗")
        
        DispatchQueue.main.async {
            if self.overlayWindow != nil {
                NSLog("🎯 浮窗已存在，直接显示")
                self.overlayWindow?.isHidden = false
                self.isVisible = true
                completion(true)
                return
            }
            
            self.createOverlayWindow()
            
            if animated {
                self.overlayWindow?.alpha = 0
                UIView.animate(withDuration: 0.3) {
                    self.overlayWindow?.alpha = 1
                } completion: { _ in
                    self.isVisible = true
                    completion(true)
                }
            } else {
                self.isVisible = true
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
            
            if animated {
                UIView.animate(withDuration: 0.3) {
                    window.alpha = 0
                } completion: { _ in
                    window.isHidden = true
                    self.isVisible = false
                    completion()
                }
            } else {
                window.isHidden = true
                self.isVisible = false
                completion()
            }
        }
    }
    
    func updateMessages(_ messages: [ChatMessage]) {
        NSLog("🎯 ChatOverlayManager: 更新消息列表，数量: \(messages.count)")
        self.messages = messages
        // 这里可以更新UI，暂时先简化
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
        NSLog("🎯 ChatOverlayManager: 设置输入框底部空间: \(space)")
        self.inputBottomSpace = space
        // 如果浮窗处于收缩状态，更新位置
        if currentState == .collapsed && overlayViewController != nil {
            updateUI(animated: true)
        }
    }
    
    func getVisibility() -> Bool {
        return isVisible
    }
    
    // MARK: - 状态切换方法
    
    func switchToCollapsed() {
        NSLog("🎯 ChatOverlayManager: 切换到收缩状态")
        currentState = .collapsed
        updateUI(animated: true)
        applyBackgroundTransform(for: .collapsed, animated: true)
        onStateChange?(.collapsed)
    }
    
    func switchToExpanded() {
        NSLog("🎯 ChatOverlayManager: 切换到展开状态")
        currentState = .expanded
        updateUI(animated: true)
        applyBackgroundTransform(for: .expanded, animated: true)
        onStateChange?(.expanded)
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
                
            case .collapsed:
                // 收缩状态：还原到原始状态
                backgroundView.layer.transform = CATransform3DIdentity
                backgroundView.alpha = 1.0  // 恢复原始亮度
            }
        }, completion: nil)
    }
    
    // MARK: - Private Methods
    
    private func createOverlayWindow() {
        NSLog("🎯 ChatOverlayManager: 创建双状态浮窗视图")
        
        // 创建浮窗窗口
        overlayWindow = UIWindow(frame: UIScreen.main.bounds)
        overlayWindow?.windowLevel = UIWindow.Level.statusBar + 1
        overlayWindow?.backgroundColor = UIColor.clear
        
        // 创建自定义视图控制器
        overlayViewController = OverlayViewController(manager: self)
        overlayWindow?.rootViewController = overlayViewController
        overlayWindow?.makeKeyAndVisible()
        
        // 初始状态为收缩状态
        currentState = .collapsed
        updateUI(animated: false)
        
        NSLog("🎯 ChatOverlayManager: 双状态浮窗创建完成")
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
    private var containerView: UIView!
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
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        // 设置约束
        NSLayoutConstraint.activate([
            // 背景遮罩填满整个屏幕
            backgroundMaskView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundMaskView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundMaskView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundMaskView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // 容器约束
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
        ])
        
        // 创建可变约束
        containerTopConstraint = containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 80)
        containerHeightConstraint = containerView.heightAnchor.constraint(equalToConstant: 65)
        
        containerTopConstraint.isActive = true
        containerHeightConstraint.isActive = true
        
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
        
        // 从manager获取inputBottomSpace
        let inputBottomSpace = manager?.inputBottomSpace ?? 70
        
        NSLog("🎯 更新UI状态: \(state), 屏幕高度: \(screenHeight), 安全区顶部: \(safeAreaTop), 安全区底部: \(safeAreaBottom), 输入框底部空间: \(inputBottomSpace)")
        
        switch state {
        case .collapsed:
            // 按照原版逻辑计算吸附位置：浮窗顶部 = 输入框底部 - 5px
            let gap: CGFloat = 5 // 浮窗顶部与输入框底部的间隙
            let floatingHeight: CGFloat = 65 // 浮窗关闭时高度65px
            
            // 浮窗顶部绝对位置 = 屏幕高度 - (inputBottomSpace - gap)
            let floatingTop = screenHeight - (inputBottomSpace - gap)
            
            // 设置约束值
            containerTopConstraint.constant = floatingTop - floatingHeight
            containerHeightConstraint.constant = floatingHeight
            collapsedView.alpha = 1
            expandedView.alpha = 0
            backgroundMaskView.alpha = 0
            containerView.layer.cornerRadius = 32.5  // 圆形外观
            
            NSLog("🎯 收缩状态计算 - gap: \(gap), floatingTop: \(floatingTop), containerTop: \(containerTopConstraint.constant)")
            
        case .expanded:
            // 展开状态：顶部留空80px，几乎全屏
            containerTopConstraint.constant = max(safeAreaTop, 80)  // 顶部留空
            containerHeightConstraint.constant = screenHeight - max(safeAreaTop, 80) - safeAreaBottom - 20  // 几乎全屏，底部留20px
            collapsedView.alpha = 0
            expandedView.alpha = 1
            backgroundMaskView.alpha = 1
            containerView.layer.cornerRadius = 12  // 方形外观
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
}