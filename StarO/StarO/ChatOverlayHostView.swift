import SwiftUI
import UIKit

struct ChatOverlayHostView: UIViewRepresentable {
  let bridge: NativeChatBridge

  func makeUIView(context: Context) -> OverlayAnchorView {
    let view = OverlayAnchorView()
    view.bridge = bridge
    return view
  }

  func updateUIView(_ uiView: OverlayAnchorView, context: Context) {
    uiView.bridge = bridge
    uiView.syncBridgeIfNeeded()
  }
}

final class OverlayAnchorView: UIView {
  weak var bridge: NativeChatBridge?

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .clear
    isUserInteractionEnabled = false
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func didMoveToWindow() {
    super.didMoveToWindow()
    syncBridgeIfNeeded()
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    syncBridgeIfNeeded()
  }

  func syncBridgeIfNeeded() {
    guard let bridge, let window = window, let scene = window.windowScene else { return }
    bridge.attach(to: scene)
  }
}
