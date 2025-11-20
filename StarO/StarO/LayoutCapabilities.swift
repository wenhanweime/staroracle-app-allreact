import UIKit

// MARK: - 能力协议：根据输入框位置调整聊天视口布局，避免气泡被遮挡
@MainActor
protocol InputOverlayAvoidingLayout: AnyObject {
    /// 输入：屏幕底部到输入框底部的实际距离（px）
    func updateLayoutForInputDrawer(bottomSpaceFromScreen: CGFloat)
}

// MARK: - 位置可观测源协议：提供最新的输入框位置，并在变化时回调
@MainActor
protocol InputDrawerPositionObservable: AnyObject {
    var latestBottomSpace: CGFloat { get }
    var onBottomSpaceChanged: ((CGFloat) -> Void)? { get set }
}

// MARK: - 协调者：把输入框位置变化派发给布局能力
@MainActor
final class InputDrawerLayoutCoordinator {
    private weak var layout: InputOverlayAvoidingLayout?
    private weak var observable: InputDrawerPositionObservable?

    init(layout: InputOverlayAvoidingLayout, observable: InputDrawerPositionObservable) {
        self.layout = layout
        self.observable = observable
        // 监听位置变化并派发（本类与 observable 均在 MainActor 上）
        observable.onBottomSpaceChanged = { [weak self] bottom in
            guard let self, let layout = self.layout else { return }
            layout.updateLayoutForInputDrawer(bottomSpaceFromScreen: bottom)
        }
    }

    /// 首次出现/状态切换后，强制同步一次，保证“永不遮挡”强规则
    @MainActor
    func syncInitialLayout() {
        guard let layout = layout, let observable = observable else { return }
        layout.updateLayoutForInputDrawer(bottomSpaceFromScreen: observable.latestBottomSpace)
    }
}
