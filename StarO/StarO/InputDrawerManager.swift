import Foundation
import AVFoundation
import Speech
import SwiftUI
import UIKit
import StarOracleCore

private func NSLog(_ format: String, _ args: CVarArg...) {
    guard StarOracleDebug.verboseLogsEnabled else { return }
    if args.isEmpty {
        Foundation.NSLog("%@", format)
    } else {
        withVaList(args) { Foundation.NSLogv(format, $0) }
    }
}

// MARK: - InputPassthroughWindow - 自定义窗口类，支持触摸事件穿透
class InputPassthroughWindow: UIWindow {
    weak var inputDrawerViewController: InputViewController?  // 改名避免与系统属性冲突
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let hitView = super.hitTest(point, with: event) else {
            return nil
        }

        if hitView == self.rootViewController?.view {
            inputDrawerViewController?.textField.resignFirstResponder()
            return nil
        }

        if let passthroughView = hitView as? PassthroughView {
            if let containerView = passthroughView.containerView {
                let convertedPoint = passthroughView.convert(point, to: containerView)
                if !containerView.bounds.contains(convertedPoint) {
                    inputDrawerViewController?.textField.resignFirstResponder()
                    return nil
                }
            }
            return hitView
        }

        return hitView
    }
}

// MARK: - InputDrawer事件协议
public protocol InputDrawerDelegate: AnyObject {
    func inputDrawerDidSubmit(_ text: String)
    func inputDrawerDidChange(_ text: String)
    func inputDrawerDidFocus()
    func inputDrawerDidBlur()
}

// MARK: - InputDrawerManager业务逻辑类
@MainActor
public class InputDrawerManager {
    private var inputWindow: UIWindow?
    private weak var windowScene: UIWindowScene?
    private var isVisible = false
    private var currentText = ""
    internal var placeholder = "输入文字..." // 改为internal让InputViewController访问
    internal var bottomSpace: CGFloat = 20 // 默认20px，匹配React版本
    internal var horizontalOffset: CGFloat = 0
    private var inputViewController: InputViewController?
    private var isExternalModalPresented = false
    private var externalModalWindowLevelBackup: UIWindow.Level?
    
    // 事件代理
    public weak var delegate: InputDrawerDelegate?
    
    // MARK: - Public API
    
    func attach(to scene: UIWindowScene) {
        // 若已经绑定同一 scene，避免重复 rebind 造成窗口闪烁
        if windowScene === scene, let window = inputWindow, window.windowScene === scene {
            return
        }
        windowScene = scene
        if let window = inputWindow {
            window.windowScene = scene
            window.frame = scene.screen.bounds
        }
    }

    func setExternalModalPresented(_ presented: Bool) {
        isExternalModalPresented = presented
        guard let window = inputWindow else { return }
        if presented {
            if externalModalWindowLevelBackup == nil {
                externalModalWindowLevelBackup = window.windowLevel
            }
            window.isUserInteractionEnabled = false
            window.windowLevel = UIWindow.Level.normal - 1
        } else {
            window.isUserInteractionEnabled = true
            window.windowLevel = externalModalWindowLevelBackup ?? (UIWindow.Level.statusBar - 0.5)
            externalModalWindowLevelBackup = nil
        }
    }
    
    func show(animated: Bool = true, completion: @escaping (Bool) -> Void) {
        NSLog("🎯 InputDrawerManager: 显示输入框")
        
        DispatchQueue.main.async {
            if self.inputWindow != nil {
                NSLog("🎯 输入框已存在，直接显示")
                self.inputWindow?.isHidden = false
                self.inputWindow?.isUserInteractionEnabled = true
                self.isVisible = true
                completion(true)
                return
            }
            
            self.createInputWindow()
            
            if animated {
                self.inputWindow?.alpha = 0
                UIView.animate(withDuration: 0.3) {
                    self.inputWindow?.alpha = 1
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
        NSLog("🎯 InputDrawerManager: 隐藏输入框")
        
        DispatchQueue.main.async {
            guard let window = self.inputWindow else {
                completion()
                return
            }
            
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
    
    func setText(_ text: String) {
        NSLog("🎯 InputDrawerManager: 设置文本: \(text)")
        currentText = text
        inputViewController?.updateText(text)
    }
    
    func getText() -> String {
        NSLog("🎯 InputDrawerManager: 获取文本")
        return currentText
    }
    
    func focus() {
        NSLog("🎯 InputDrawerManager: 聚焦输入框")
        inputViewController?.focusInput()
    }
    
    func blur() {
        NSLog("🎯 InputDrawerManager: 失焦输入框")
        inputViewController?.blurInput()
    }
    
    func setBottomSpace(_ space: CGFloat) {
        NSLog("🎯 InputDrawerManager: 设置底部空间: \(space)")
        bottomSpace = space
        inputViewController?.updateBottomSpace(space)
    }
    
    func setPlaceholder(_ placeholder: String) {
        NSLog("🎯 InputDrawerManager: 设置占位符: \(placeholder)")
        self.placeholder = placeholder
        inputViewController?.updatePlaceholder(placeholder)
    }

    func setHorizontalOffset(_ offset: CGFloat, animated: Bool = true) {
        NSLog("🎯 InputDrawer: 更新水平偏移 -> \(offset) (animated: \(animated))")
        NSLog("🎯 InputDrawerManager: 设置水平偏移: \(offset)")
        horizontalOffset = offset
        DispatchQueue.main.async { [weak self] in
            self?.inputViewController?.updateHorizontalOffset(offset, animated: animated)
        }
    }
    
    func getVisibility() -> Bool {
        return isVisible
    }
    
    // MARK: - Private Methods
    
    private func createInputWindow() {
        NSLog("🎯 InputDrawerManager: 创建输入框窗口")
        let scene = windowScene ?? UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        if windowScene == nil && scene == nil {
            NSLog("⚠️ InputDrawerManager: 未找到可用的UIWindowScene，使用UIScreen.main作为兜底")
        }
        let bounds = scene?.screen.bounds ?? UIScreen.main.bounds
        
        // 创建输入框窗口 - 使用自定义的InputPassthroughWindow支持触摸穿透
        let window = InputPassthroughWindow(frame: bounds)
        if let scene {
            window.windowScene = scene
        }
        window.windowLevel = isExternalModalPresented ? (UIWindow.Level.normal - 1) : (UIWindow.Level.statusBar - 0.5)  // 略低于statusBar，但高于普通窗口
        window.backgroundColor = UIColor.clear
        window.isUserInteractionEnabled = !isExternalModalPresented
        
        // 关键：让窗口不阻挡其他交互，只处理输入框区域的触摸
        window.isHidden = false
        
        // 创建输入框视图控制器
        inputViewController = InputViewController(manager: self)
        window.rootViewController = inputViewController
        inputViewController?.loadViewIfNeeded()
        inputViewController?.updateText(currentText)
        inputViewController?.updatePlaceholder(placeholder)
        inputViewController?.updateBottomSpace(bottomSpace)
        inputViewController?.updateHorizontalOffset(horizontalOffset, animated: false)
        
        // 设置窗口对视图控制器的引用，用于收起键盘
        window.inputDrawerViewController = inputViewController  // 使用新的属性名
        
        // 保存窗口引用
        inputWindow = window
        
        // 不使用makeKeyAndVisible()，避免抢夺焦点，让触摸事件更容易透传
        window.isHidden = false
        
        NSLog("🎯 InputDrawerManager: 输入框窗口创建完成")
        NSLog("🎯 InputDrawer窗口层级: \(window.windowLevel.rawValue)")
        NSLog("🎯 StatusBar层级: \(UIWindow.Level.statusBar.rawValue)")
        NSLog("🎯 Alert层级: \(UIWindow.Level.alert.rawValue)")
        NSLog("🎯 Normal层级: \(UIWindow.Level.normal.rawValue)")
    }
    
    // MARK: - 输入框事件处理
    
    internal func handleTextChange(_ text: String) {
        currentText = text
        delegate?.inputDrawerDidChange(text)
    }
    
    internal func handleTextSubmit(_ text: String) {
        currentText = text
        delegate?.inputDrawerDidSubmit(text)
        NSLog("🎯 InputDrawerManager: 文本提交: \(text)")
    }
    
    internal func handleFocus() {
        delegate?.inputDrawerDidFocus()
        NSLog("🎯 InputDrawerManager: 输入框获得焦点")
    }
    
    internal func handleBlur() {
        delegate?.inputDrawerDidBlur()
        NSLog("🎯 InputDrawerManager: 输入框失去焦点")
    }
}

// MARK: - InputViewController - 处理输入框UI显示
class InputViewController: UIViewController {
    private weak var manager: InputDrawerManager?
    private var containerView: UIView!
    internal var textField: UITextField!  // 改为internal让InputPassthroughWindow可以访问
    private var sendButton: UIButton!
    private var micButton: UIButton!
    private var awarenessView: FloatingAwarenessPlanetView!

    // MARK: - Speech (Apple Speech framework)
    private let speechRecognizer: SFSpeechRecognizer? = {
        let zh = Locale(identifier: "zh-CN")
        return SFSpeechRecognizer(locale: zh)
    }()
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var isSpeechRecording: Bool = false
    private var isSpeechStopping: Bool = false
    private var didInstallSpeechTap: Bool = false
    private var pendingSpeechDeactivateTask: Task<Void, Never>?
    private var speechToken: UUID?
    private var speechBaseText: String = ""
    
    // 约束
    private var containerLeadingConstraint: NSLayoutConstraint!
    private var containerTrailingConstraint: NSLayoutConstraint!
    private var containerBottomConstraint: NSLayoutConstraint!
    private var horizontalOffset: CGFloat = 0
    
    // 添加属性来保存键盘出现前的位置
    private var bottomSpaceBeforeKeyboard: CGFloat = 20
    // 新增：键盘可见状态与（已扣安全区的）当前键盘高度
    private var isKeyboardVisible: Bool = false
    private var currentKeyboardActualHeight: CGFloat = 0
    // 仅首轮：在 ChatOverlay 第一次收缩时，键盘可见情况下也要为浮窗预留空间
    private var didAdjustForFirstCollapse: Bool = false
    
    init(manager: InputDrawerManager) {
        self.manager = manager
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupKeyboardObservers()
        setupChatOverlayObservers()  // 新增：监听ChatOverlay状态
        
        // 关键：让view只处理输入框区域的触摸，其他区域透传
        view.backgroundColor = UIColor.clear
        
        // 重要：设置view不拦截触摸事件，让PassthroughView完全控制
        view.isUserInteractionEnabled = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // 在视图出现后设置触摸事件透传
        setupPassthroughView()
        
        // 发送初始位置通知，让ChatOverlay知道输入框的初始位置
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.notifyInputDrawerActualPosition()
        }
    }
    
    private func setupPassthroughView() {
        // 使用更简单的方式：PassthroughView作为背景层，不移动现有的containerView
        let passthroughView = PassthroughView()
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
        
        NSLog("🎯 InputDrawer: PassthroughView设置完成，保持原有布局")
    }
    
    private func setupUI() {
        // 确保背景透明，不阻挡其他UI
        view.backgroundColor = UIColor.clear
        
        // 创建主容器 - 匹配原版：圆角全包围，灰黑背景，边框
        containerView = UIView()
        containerView.backgroundColor = UIColor(red: 17/255.0, green: 24/255.0, blue: 39/255.0, alpha: 1.0) // bg-gray-900
        containerView.layer.cornerRadius = 24 // rounded-full for h-12
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor(red: 31/255.0, green: 41/255.0, blue: 55/255.0, alpha: 1.0).cgColor // border-gray-800
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        containerView.layer.shadowOpacity = 0.25
        containerView.layer.shadowRadius = 8
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        // 创建左侧觉察动画 - 精确匹配Web版FloatingAwarenessPlanet尺寸
        // Web版: <FloatingAwarenessPlanet className="w-8 h-8 ml-3 ... " /> (w-8 h-8 = 32x32px)
        awarenessView = FloatingAwarenessPlanetView()
        awarenessView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(awarenessView)
        
        // 创建输入框 - 匹配原版：透明背景，白色文字，灰色placeholder
        textField = UITextField()
        textField.placeholder = "询问任何问题" // 匹配原版placeholder
        textField.font = UIFont.systemFont(ofSize: 16)
        textField.borderStyle = .none
        textField.backgroundColor = UIColor.clear
        textField.textColor = UIColor.white
        textField.attributedPlaceholder = NSAttributedString(
            string: "询问任何问题",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor(white: 1.0, alpha: 0.4)]
        )
        textField.returnKeyType = .send
        textField.delegate = self
        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        textField.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(textField)
        
        // 创建发送按钮 - 使用SF Symbols paperplane图标
        sendButton = UIButton(type: .system)
        sendButton.backgroundColor = UIColor.clear
        sendButton.layer.cornerRadius = 16
        sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        sendButton.isEnabled = false
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        
        // 使用SF Symbols paperplane图标
        let paperplaneImage = UIImage(systemName: "paperplane.fill")
        sendButton.setImage(paperplaneImage, for: .normal)
        sendButton.tintColor = UIColor(white: 1.0, alpha: 0.3) // 默认灰色
        containerView.addSubview(sendButton)
        
        // 创建麦克风按钮 - 使用SF Symbols mic图标
        micButton = UIButton(type: .system)
        micButton.backgroundColor = UIColor.clear
        micButton.layer.cornerRadius = 16
        micButton.addTarget(self, action: #selector(micButtonTapped), for: .touchUpInside)
        micButton.translatesAutoresizingMaskIntoConstraints = false
        
        // 使用SF Symbols mic图标
        let micImage = UIImage(systemName: "mic.fill")
        micButton.setImage(micImage, for: .normal)
        micButton.tintColor = UIColor(white: 1.0, alpha: 0.6) // 匹配Web版颜色
        containerView.addSubview(micButton)
        
        // 设置约束 - 完全匹配原版：左侧觉察动画 + 输入框 + 右侧按钮组
        containerBottomConstraint = containerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -(manager?.bottomSpace ?? 20))
        horizontalOffset = manager?.horizontalOffset ?? 0
        containerLeadingConstraint = containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16 + horizontalOffset)
        containerTrailingConstraint = containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        
        NSLayoutConstraint.activate([
            // 容器约束 - 匹配原版h-12 = 48px高度
            containerLeadingConstraint,
            containerTrailingConstraint,
            containerView.heightAnchor.constraint(equalToConstant: 48), // h-12
            containerBottomConstraint,
            
            // 左侧觉察动画约束 - 精确匹配Web版w-8 h-8 ml-3 (32x32px, 12px左边距)
            awarenessView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12), // ml-3 = 12px
            awarenessView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            awarenessView.widthAnchor.constraint(equalToConstant: 32), // w-8 = 32px
            awarenessView.heightAnchor.constraint(equalToConstant: 32), // h-8 = 32px
            
            // 输入框约束 - 精确匹配Web版pl-2 pr-4的内边距
            textField.leadingAnchor.constraint(equalTo: awarenessView.trailingAnchor, constant: 8), // pl-2 = 8px
            textField.trailingAnchor.constraint(equalTo: micButton.leadingAnchor, constant: -16), // pr-4 = 16px
            textField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            
            // 麦克风按钮约束 - 匹配原版：space-x-2，圆形按钮 (p-2 = 8px padding)
            micButton.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8), // space-x-2
            micButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            micButton.widthAnchor.constraint(equalToConstant: 32), // 16px icon + 8px padding each side
            micButton.heightAnchor.constraint(equalToConstant: 32),
            
            // 发送按钮约束 - 匹配原版：mr-3，圆形按钮 (p-2 = 8px padding)
            sendButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12), // mr-3
            sendButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 36), // 20px icon + 8px padding each side
            sendButton.heightAnchor.constraint(equalToConstant: 36)
        ])
    }
    
    private func setupChatOverlayObservers() {
        // 🔧 只保留状态变化监听器，移除冗余的可见性监听器
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(chatOverlayStateChanged(_:)),
            name: Notification.Name("chatOverlayStateChanged"),
            object: nil
        )
        
        NSLog("🎯 InputDrawer: 开始监听ChatOverlay状态变化（已移除冗余的可见性监听器）")
    }
    
    @objc private func chatOverlayStateChanged(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let state = userInfo["state"] as? String else { return }
        
        // 🔧 新增：检查visible状态（如果有）
        let visible = userInfo["visible"] as? Bool ?? true
        
        NSLog("🎯 InputDrawer: 收到ChatOverlay统一状态通知 - state: \(state), visible: \(visible)")
        
        // 根据ChatOverlay状态调整输入框位置
        switch state {
        case "collapsed":
            if visible {
                // ChatOverlay收缩状态且可见：为浮窗预留空间
                let overlayReserve: CGFloat = 40
                if isKeyboardVisible && !didAdjustForFirstCollapse {
                    // 仅第一次：键盘可见时也在键盘之上额外预留 overlayReserve 空间
                    let target = -(currentKeyboardActualHeight + 16 + overlayReserve)
                    if abs(containerBottomConstraint.constant - target) > 0.5 {
                        containerBottomConstraint.constant = target
                        UIView.animate(withDuration: 0.26, delay: 0, options: [.allowUserInteraction, .curveEaseInOut, .beginFromCurrentState]) {
                            self.view.layoutIfNeeded()
                        } completion: { _ in
                            self.didAdjustForFirstCollapse = true
                            NSLog("🎯 InputDrawer: 首次收缩(键盘可见) 预留浮窗空间完成 bottom=\(target)")
                            self.notifyInputDrawerActualPosition()
                        }
                    }
                } else {
                    // 后续或键盘不可见：按原逻辑更新到 40
                    let newBottomSpace: CGFloat = overlayReserve
                    updateBottomSpace(newBottomSpace)
                    NSLog("🎯 InputDrawer: 移动到collapsed位置，bottomSpace: \(newBottomSpace)")
                }
            }
            
        case "expanded":
            if visible {
                // ChatOverlay展开状态：输入框回到原始位置
                let originalBottomSpace: CGFloat = 20
                updateBottomSpace(originalBottomSpace)
                NSLog("🎯 InputDrawer: 回到expanded位置，bottomSpace: \(originalBottomSpace)")
            }
            
        case "hidden":
            // ChatOverlay隐藏：输入框回到原始位置（无论 visible 值）
            let originalBottomSpace: CGFloat = 20
            updateBottomSpace(originalBottomSpace)
            NSLog("🎯 InputDrawer: 回到hidden位置，bottomSpace: \(originalBottomSpace)")
            
        default:
            // 未知状态，检查visible状态
            if !visible {
                let originalBottomSpace: CGFloat = 20
                updateBottomSpace(originalBottomSpace)
                NSLog("🎯 InputDrawer: 未知状态但不可见，回到原始位置")
            }
        }
    }
    
    // 🔧 已移除chatOverlayVisibilityChanged方法，避免重复动画
    // 现在只使用chatOverlayStateChanged来统一管理所有状态变化
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChangeFrame(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        NSLog("🎯 InputDrawer: 移除所有通知观察者")
    }
    
    // MARK: - Public Methods
    
    func updateText(_ text: String) {
        textField.text = text
        updateSendButtonState()
    }
    
    func updatePlaceholder(_ placeholder: String) {
        textField.placeholder = placeholder
    }
    
    func updateBottomSpace(_ space: CGFloat) {
        // 更新管理器中的bottomSpace值（键盘隐藏时会按此值恢复）
        let oldSpace = manager?.bottomSpace ?? 20
        manager?.bottomSpace = space

        // 若键盘可见：保持由键盘驱动的位置，避免覆盖（首个收缩场景关键修复）
        if isKeyboardVisible {
            NSLog("🎯 InputDrawer: 键盘可见，保持键盘位置，跳过覆盖 bottomSpace -> -\(currentKeyboardActualHeight) - 16")
            containerBottomConstraint.constant = -currentKeyboardActualHeight - 16
            self.view.layoutIfNeeded()
            // 首轮联动所需：广播当前实际位置，供浮窗对齐（不改变既有布局，仅发送事件）
            self.notifyInputDrawerActualPosition()
            return
        }

        // 键盘未显示：仅当变动显著时才更新
        if abs(oldSpace - space) < 1 {
            NSLog("🎯 InputDrawer: 位置未发生显著变化，跳过更新")
            return
        }

        // 使用与浮窗一致的轻量动画，营造柔和的推上推下效果
        containerBottomConstraint.constant = -space
        // 先发布“目标位置”（不等待动画完成），让 ChatOverlay 同步做避让与滚动策略，保证交互一致
        let predictedBottomSpaceFromScreen = view.safeAreaInsets.bottom + space
        InputDrawerState.shared.latestActualBottomSpace = predictedBottomSpaceFromScreen
        InputDrawerState.shared.latestHeight = containerView.bounds.height
        UIView.animate(
            withDuration: 0.26,
            delay: 0,
            options: [.allowUserInteraction, .curveEaseInOut, .beginFromCurrentState]
        ) {
            self.view.layoutIfNeeded()
        } completion: { _ in
            NSLog("🎯 InputDrawer: 位置更新完成（动画），bottomSpace: \(space)")
            // 通知ChatOverlay输入框的新位置
            self.notifyInputDrawerActualPosition()
        }
    }

    func updateHorizontalOffset(_ offset: CGFloat, animated: Bool) {
        if abs(horizontalOffset - offset) < 0.5 {
            horizontalOffset = offset
            return
        }
        horizontalOffset = offset
        containerLeadingConstraint.constant = 16 + offset
        containerTrailingConstraint.constant = -16 + offset

        let updates = {
            self.view.layoutIfNeeded()
            self.notifyInputDrawerActualPosition()
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
    
    func focusInput() {
        textField.becomeFirstResponder()
    }
    
    func blurInput() {
        textField.resignFirstResponder()
    }
    
    // MARK: - Private Methods
    
    private func updateSendButtonState() {
        let hasText = !(textField.text?.isEmpty ?? true)
        sendButton.isEnabled = hasText
        
        // 更新发送按钮颜色 - 精确匹配Web版逻辑
        // Web版: 当有文字时变为cosmic-accent紫色，无文字时为白色半透明
        let cosmicAccentColor = UIColor(red: 168/255.0, green: 85/255.0, blue: 247/255.0, alpha: 1.0) // #a855f7
        let defaultColor = UIColor(white: 1.0, alpha: 0.3) // 匹配Web版默认白色半透明
        sendButton.tintColor = hasText ? cosmicAccentColor : defaultColor
    }
    
    @objc private func textFieldDidChange() {
        updateSendButtonState()
        manager?.handleTextChange(textField.text ?? "")
    }
    
    @objc private func sendButtonTapped() {
        guard let text = textField.text, !text.isEmpty else { return }
        
        manager?.handleTextSubmit(text)
        textField.text = ""
        updateSendButtonState()
    }
    
    @objc private func micButtonTapped() {
        NSLog("🎯 麦克风按钮被点击")
        Task { @MainActor [weak self] in
            guard let self else { return }
            if self.isSpeechStopping { return }
            if self.isSpeechRecording {
                self.stopSpeechRecognition()
            } else {
                await self.startSpeechRecognitionIfPossible()
            }
        }
    }

    @MainActor
    private func startSpeechRecognitionIfPossible() async {
        guard !isSpeechStopping else { return }
        guard validateSpeechUsageDescriptions() else { return }
        guard let speechRecognizer else {
            presentPermissionAlert(title: "无法使用语音识别", message: "当前设备不支持语音识别。")
            return
        }
	        guard speechRecognizer.isAvailable else {
            presentPermissionAlert(title: "语音识别暂不可用", message: "语音识别服务当前不可用，请稍后再试。")
            return
        }

        let speechOK = await requestSpeechAuthorization()
        guard speechOK else {
            presentPermissionAlert(title: "需要语音识别权限", message: "请在系统设置中允许“语音识别”权限后再试。")
            return
        }

        let micOK = await requestMicrophonePermission()
        guard micOK else {
            presentPermissionAlert(title: "需要麦克风权限", message: "请在系统设置中允许“麦克风”权限后再试。")
            return
        }

        do {
            try beginSpeechRecognition()
        } catch {
            presentPermissionAlert(title: "语音识别启动失败", message: error.localizedDescription)
            stopSpeechRecognition()
        }
    }

	    private func validateSpeechUsageDescriptions() -> Bool {
	        let missingKeys: [String] = [
	            "NSSpeechRecognitionUsageDescription",
	            "NSMicrophoneUsageDescription",
	        ].filter { key in
	            guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String else { return true }
	            return value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
	        }
	        guard missingKeys.isEmpty else {
	            Task { @MainActor [weak self] in
	                self?.presentPermissionAlert(
	                    title: "缺少权限说明",
	                    message: "App 缺少 Info.plist 字段：\(missingKeys.joined(separator: "、"))。\n系统在请求权限时会直接崩溃，请补齐后重新安装。"
	                )
	            }
	            return false
	        }
	        return true
	    }

    @MainActor
    private func requestSpeechAuthorization() async -> Bool {
        let status = SFSpeechRecognizer.authorizationStatus()
        if status == .authorized { return true }
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { newStatus in
                continuation.resume(returning: newStatus == .authorized)
            }
        }
    }

    @MainActor
    private func requestMicrophonePermission() async -> Bool {
        let session = AVAudioSession.sharedInstance()
        switch session.recordPermission {
        case .granted:
            return true
        case .denied:
            return false
        case .undetermined:
            return await withCheckedContinuation { continuation in
                session.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        @unknown default:
            return false
        }
    }

    private func beginSpeechRecognition() throws {
        let token = UUID()
        let baseText = textField.text ?? ""

        speechToken = token

        pendingSpeechDeactivateTask?.cancel()
        pendingSpeechDeactivateTask = nil
        stopSpeechRecognitionLocked(token: nil, deactivateAudioSession: false, force: true)

        speechBaseText = baseText

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
        try audioSession.setActive(true)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)
        didInstallSpeechTap = false
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0,
                             bufferSize: 1024,
                             format: recordingFormat,
                             block: makeNonisolatedSpeechTap(request: request))
        didInstallSpeechTap = true

        audioEngine.prepare()
        try audioEngine.start()

        isSpeechRecording = true
        updateMicButton(isRecording: true)

        recognitionTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                guard self.speechToken == token else { return }

                if let result {
                    let spoken = result.bestTranscription.formattedString
                    let merged = self.mergeSpeechText(base: self.speechBaseText, spoken: spoken)
                    self.textField.text = merged
                    self.updateSendButtonState()
                    self.manager?.handleTextChange(merged)
                }

                if error != nil || (result?.isFinal ?? false) {
                    self.stopSpeechRecognitionLocked(token: token, deactivateAudioSession: true, force: false)
                }
            }
        }
    }

    private func stopSpeechRecognition() {
        let token = speechToken
        stopSpeechRecognitionLocked(token: token, deactivateAudioSession: true, force: false)
    }

    private func stopSpeechRecognitionLocked(token: UUID?, deactivateAudioSession: Bool, force: Bool) {
        guard !isSpeechStopping else { return }
        if let current = speechToken, let token, current != token, !force { return }
        isSpeechStopping = true

        // 先让 UI 立即响应（避免用户感觉“按了停不下来”）
        isSpeechRecording = false
        DispatchQueue.main.async { [weak self] in
            self?.updateMicButton(isRecording: false)
        }

        if audioEngine.isRunning {
            audioEngine.stop()
        }
        if didInstallSpeechTap {
            audioEngine.inputNode.removeTap(onBus: 0)
            didInstallSpeechTap = false
        }

        recognitionRequest?.endAudio()
        recognitionRequest = nil

        recognitionTask?.cancel()
        recognitionTask = nil

        audioEngine.reset()

        if deactivateAudioSession {
            pendingSpeechDeactivateTask?.cancel()
            pendingSpeechDeactivateTask = Task { @MainActor [weak self] in
                do {
                    try await Task.sleep(nanoseconds: 250_000_000)
                } catch {
                    return
                }
                guard let self, !Task.isCancelled, !self.isSpeechRecording else { return }
                try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            }
        }

        if force || token == speechToken {
            speechToken = nil
        }
        isSpeechStopping = false
    }

    private func updateMicButton(isRecording: Bool) {
        let name = isRecording ? "stop.circle.fill" : "mic.fill"
        let image = UIImage(systemName: name)
        micButton.setImage(image, for: .normal)
        micButton.tintColor = isRecording
          ? UIColor(red: 168/255.0, green: 85/255.0, blue: 247/255.0, alpha: 1.0)
          : UIColor(white: 1.0, alpha: 0.6)
    }

    private func mergeSpeechText(base: String, spoken: String) -> String {
        let trimmedBase = base.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSpoken = spoken.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedBase.isEmpty { return trimmedSpoken }
        if trimmedSpoken.isEmpty { return trimmedBase }
        return "\(trimmedBase) \(trimmedSpoken)"
    }

    @MainActor
    private func presentPermissionAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "好的", style: .default))
        present(alert, animated: true)
    }

// MARK: - Speech tap helper (non-isolated)
/// 在音频线程执行的 tap，保持非 MainActor，避免队列断言。
private func makeNonisolatedSpeechTap(request: SFSpeechAudioBufferRecognitionRequest) -> AVAudioNodeTapBlock {
    return { buffer, _ in
        request.append(buffer)
    }
}
    
    @objc private func keyboardWillChangeFrame(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }

        let duration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double) ?? 0.25
        let curveValue = (notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt) ?? 7
        let curveOptions = UIView.AnimationOptions(rawValue: curveValue << 16)

        // 计算：从 safeArea 底部到键盘顶部的实际覆盖高度（px）
        let safeAreaBottom = view.safeAreaInsets.bottom
        let keyboardFrameInView = view.convert(keyboardFrame, from: nil)
        let safeBottomY = view.bounds.maxY - safeAreaBottom
        let overlapFromSafe = max(0, safeBottomY - keyboardFrameInView.minY)

        if overlapFromSafe > 0 {
            if !isKeyboardVisible {
                bottomSpaceBeforeKeyboard = manager?.bottomSpace ?? 20
                NSLog("🎯 键盘即将显示，保存当前bottomSpace: \(bottomSpaceBeforeKeyboard)")
            }
            isKeyboardVisible = true
            currentKeyboardActualHeight = overlapFromSafe
            containerBottomConstraint.constant = -(overlapFromSafe + 16)
            NSLog("🎯 键盘变化: safeBottom=\(safeAreaBottom), overlapFromSafe=\(overlapFromSafe)")
        } else {
            if isKeyboardVisible {
                NSLog("🎯 键盘即将隐藏，恢复到位置: \(bottomSpaceBeforeKeyboard)")
            }
            isKeyboardVisible = false
            currentKeyboardActualHeight = 0
            let restoreSpace = manager?.bottomSpace ?? bottomSpaceBeforeKeyboard
            bottomSpaceBeforeKeyboard = restoreSpace
            containerBottomConstraint.constant = -restoreSpace
        }

        // 先发布“目标位置”（不等待键盘动画完成），让 ChatOverlay 同步做避让与滚动策略，保证顶起体验一致
        let predictedBottomSpaceFromScreen = view.safeAreaInsets.bottom - containerBottomConstraint.constant
        InputDrawerState.shared.latestActualBottomSpace = predictedBottomSpaceFromScreen
        InputDrawerState.shared.latestHeight = containerView.bounds.height

        UIView.animate(withDuration: duration,
                       delay: 0,
                       options: [.allowUserInteraction, .beginFromCurrentState, curveOptions]) {
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.notifyInputDrawerActualPosition()
        }
    }
    
    // MARK: - 通知ChatOverlay输入框的实际屏幕位置
    private func notifyInputDrawerActualPosition() {
        // 计算输入框底部在屏幕中的实际Y坐标
        let containerFrame = containerView.frame
        let containerBottom = containerFrame.maxY
        let screenHeight = UIScreen.main.bounds.height
        
        // 计算输入框底部距离屏幕底部的实际距离
        let actualBottomSpaceFromScreen = screenHeight - containerBottom
        
        NSLog("🎯 InputDrawer实际位置 - 容器底部Y: \(containerBottom), 屏幕高度: \(screenHeight), 实际底部距离: \(actualBottomSpaceFromScreen)")
        
        // 记录最新的实际位置，供 ChatOverlay 初次出现时立即读取
        InputDrawerState.shared.latestActualBottomSpace = actualBottomSpaceFromScreen
        InputDrawerState.shared.latestHeight = containerFrame.height

        // 去通知化：不再通过全局通知广播，改由协议回调（InputDrawerPositionObservable）
        NSLog("🎯 InputDrawer: 已更新实际位置 actualBottomSpace=\(actualBottomSpaceFromScreen)")
    }
}

// MARK: - 输入框共享状态（供 ChatOverlay 初次出现时立即对齐）
@MainActor
final class InputDrawerState: InputDrawerPositionObservable {
    static let shared = InputDrawerState()
    private init() {}

    // 位置变化回调（供协调者使用）
    var onBottomSpaceChanged: ((CGFloat) -> Void)?

    // 兼容旧字段（保持与已有调用的一致性）
    var latestActualBottomSpace: CGFloat = 70 {
        didSet {
            // 同步到新协议字段并回调
            latestBottomSpace = latestActualBottomSpace
        }
    }

    // 协议所需字段：屏幕底部到输入框底部的实际距离（px）
    var latestBottomSpace: CGFloat = 70 {
        didSet { onBottomSpaceChanged?(latestBottomSpace) }
    }

    // 输入框容器的实际高度（px）
    var latestHeight: CGFloat = 56
}

// MARK: - PassthroughView - 处理触摸事件透传的自定义View
class PassthroughView: UIView {
    weak var containerView: UIView?
    
    // 重写这个方法来决定是否拦截触摸事件
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        NSLog("🎯 InputDrawer PassthroughView hitTest: \(point)")
        
        // 首先让父类正常处理触摸测试
        let hitView = super.hitTest(point, with: event)
        
        // 如果触摸点不在containerView区域内，返回nil让事件透传
        guard let containerView = containerView else {
            NSLog("🎯 无containerView，返回hitView: \(String(describing: hitView))")
            return hitView
        }
        
        // 将点转换到containerView的坐标系
        let convertedPoint = convert(point, to: containerView)
        let containerBounds = containerView.bounds
        
        NSLog("🎯 转换后坐标: \(convertedPoint), 容器边界: \(containerBounds)")
        
        // 如果触摸点在containerView的边界内，正常返回hitView
        if containerBounds.contains(convertedPoint) {
            NSLog("🎯 触摸在输入框容器内，返回hitView: \(String(describing: hitView))")
            return hitView
        } else {
            NSLog("🎯 触摸在输入框容器外，返回nil透传事件")
            // 触摸点在containerView外部，返回nil透传给下层
            return nil
        }
    }
}

// MARK: - UITextFieldDelegate
extension InputViewController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        manager?.handleFocus()
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        manager?.handleBlur()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let text = textField.text, !text.isEmpty else { return false }
        
        sendButtonTapped()
        return true
    }
}

// MARK: - FloatingAwarenessPlanetView - 完全匹配原版动画效果
class FloatingAwarenessPlanetView: UIView {
    private var centerDot: CAShapeLayer!
    private var rayLayers: [CAShapeLayer] = []
    private var isAnimating = false
    private var level: String = "medium" // none, low, medium, high
    private var isAnalyzing = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = UIColor.clear
        
        // 创建中心圆点（跟Web版一样）
        centerDot = CAShapeLayer()
        let centerPath = UIBezierPath(ovalIn: CGRect(x: 14.5, y: 14.5, width: 3, height: 3)) // r=1.5, centered at 16,16
        centerDot.path = centerPath.cgPath
        centerDot.fillColor = getStarColor().cgColor
        layer.addSublayer(centerDot)
        
        // 创建12条射线
        for i in 0..<12 {
            let rayLayer = CAShapeLayer()
            let angle = Double(i) * Double.pi * 2.0 / 12.0
            
            // 随机长度和粗细（匹配原版算法）
            let seedRandom = { (seed: Double) -> Double in
                let x = sin(seed) * 10000
                return x - floor(x)
            }
            let length = 5 + seedRandom(Double(i)) * 8 // 缩小长度适应32px容器
            let strokeWidth = seedRandom(Double(i + 12)) * 1.2 + 0.3
            
            let startX = 16.0
            let startY = 16.0
            let endX = startX + cos(angle) * length
            let endY = startY + sin(angle) * length
            
            let rayPath = UIBezierPath()
            rayPath.move(to: CGPoint(x: startX, y: startY))
            rayPath.addLine(to: CGPoint(x: endX, y: endY))
            
            rayLayer.path = rayPath.cgPath
            rayLayer.strokeColor = getStarColor().cgColor
            rayLayer.lineWidth = CGFloat(strokeWidth)
            rayLayer.lineCap = .round
            rayLayer.strokeStart = 0
            rayLayer.strokeEnd = 0.2 // 初始状态
            rayLayer.opacity = 0.2
            
            layer.addSublayer(rayLayer)
            rayLayers.append(rayLayer)
        }
        
        startAnimation()
    }
    
    private func getStarColor() -> UIColor {
        if isAnalyzing {
            return UIColor(red: 138/255.0, green: 95/255.0, blue: 189/255.0, alpha: 1.0) // #8A5FBD
        }
        
        let progress: Double = 
            level == "none" ? 0 :
            level == "low" ? 0.33 :
            level == "medium" ? 0.66 :
            level == "high" ? 1 : 0.66 // 默认medium
        
        // 从灰色到紫色的渐变
        let gray = (r: 136.0, g: 136.0, b: 136.0)
        let purple = (r: 138.0, g: 95.0, b: 189.0)
        
        let r = gray.r + (purple.r - gray.r) * progress
        let g = gray.g + (purple.g - gray.g) * progress
        let b = gray.b + (purple.b - gray.b) * progress
        
        return UIColor(red: r/255.0, green: g/255.0, blue: b/255.0, alpha: 1.0)
    }
    
    private func startAnimation() {
        guard !isAnimating else { return }
        isAnimating = true
        
        // 中心圆点动画（匹配Web版）
        let centerScaleAnimation = CAKeyframeAnimation(keyPath: "transform.scale")
        centerScaleAnimation.values = [1.0, 1.2, 1.0]
        centerScaleAnimation.keyTimes = [0.0, 0.5, 1.0]
        centerScaleAnimation.duration = 2.0
        centerScaleAnimation.repeatCount = .infinity
        
        let centerOpacityAnimation = CAKeyframeAnimation(keyPath: "opacity")
        centerOpacityAnimation.values = [0.8, 1.0, 0.8]
        centerOpacityAnimation.keyTimes = [0.0, 0.5, 1.0]
        centerOpacityAnimation.duration = 2.0
        centerOpacityAnimation.repeatCount = .infinity
        
        centerDot.add(centerScaleAnimation, forKey: "scale")
        centerDot.add(centerOpacityAnimation, forKey: "opacity")
        
        // 射线动画
        for (i, rayLayer) in rayLayers.enumerated() {
            let strokeAnimation = CAKeyframeAnimation(keyPath: "strokeEnd")
            strokeAnimation.values = [0.0, 1.0, 0.0]
            strokeAnimation.keyTimes = [0.0, 0.5, 1.0]
            strokeAnimation.duration = 2.0 + Double(i) * 0.1 // 轻微的延迟差异
            strokeAnimation.repeatCount = .infinity
            strokeAnimation.beginTime = CACurrentMediaTime() + Double(i) * 0.05
            
            let opacityAnimation = CAKeyframeAnimation(keyPath: "opacity")
            opacityAnimation.values = [0.0, 0.7, 0.0]
            opacityAnimation.keyTimes = [0.0, 0.5, 1.0]
            opacityAnimation.duration = 2.0 + Double(i) * 0.1
            opacityAnimation.repeatCount = .infinity
            opacityAnimation.beginTime = CACurrentMediaTime() + Double(i) * 0.05
            
            rayLayer.add(strokeAnimation, forKey: "strokeEnd")
            rayLayer.add(opacityAnimation, forKey: "opacity")
        }
    }
}
