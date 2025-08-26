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

// MARK: - ChatOverlayManager业务逻辑类
public class ChatOverlayManager {
    private var overlayWindow: UIWindow?
    private var isVisible = false
    private var messages: [ChatMessage] = []
    private var isLoading = false
    private var conversationTitle = ""
    private var keyboardHeight: CGFloat = 0
    private var viewportHeight: CGFloat = 0
    private var initialInput = ""
    private var followUpQuestion = ""
    
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
    
    func getVisibility() -> Bool {
        return isVisible
    }
    
    // MARK: - Private Methods
    
    private func createOverlayWindow() {
        NSLog("🎯 ChatOverlayManager: 创建简化版浮窗视图")
        
        // 创建简化版UIKit视图而不是SwiftUI
        overlayWindow = UIWindow(frame: UIScreen.main.bounds)
        overlayWindow?.windowLevel = UIWindow.Level.statusBar + 1
        overlayWindow?.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        
        // 创建简单的视图控制器
        let viewController = UIViewController()
        viewController.view.backgroundColor = UIColor.clear
        
        // 添加一个简单的标签用于测试
        let label = UILabel()
        label.text = "ChatOverlay 双文件架构测试"
        label.textColor = UIColor.white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        viewController.view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: viewController.view.centerYAnchor)
        ])
        
        // 添加关闭按钮
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("关闭", for: .normal)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.backgroundColor = UIColor.systemBlue
        closeButton.layer.cornerRadius = 8
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        
        viewController.view.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 20),
            closeButton.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 80),
            closeButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        overlayWindow?.rootViewController = viewController
        overlayWindow?.makeKeyAndVisible()
        
        NSLog("🎯 ChatOverlayManager: 简化版浮窗创建完成")
    }
    
    @objc private func closeButtonTapped() {
        NSLog("🎯 ChatOverlayManager: 关闭按钮被点击")
        hide()
    }
}