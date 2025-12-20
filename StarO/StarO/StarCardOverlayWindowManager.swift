import SwiftUI
import UIKit
import StarOracleCore

@MainActor
final class StarCardOverlayWindowManager {
  private weak var windowScene: UIWindowScene?
  private var overlayWindow: UIWindow?
  private var hostingController: UIHostingController<AnyView>?

  func attach(to scene: UIWindowScene) {
    windowScene = scene
    if let window = overlayWindow {
      window.windowScene = scene
      window.frame = scene.screen.bounds
    }
  }

  func present(star: Star, onOpenDetail: (() -> Void)? = nil) {
    ensureWindow()
    guard let window = overlayWindow, let hostingController else { return }

    let dismiss: () -> Void = { [weak self] in
      guard let self else { return }
      self.dismiss()
    }

    let openDetail: (() -> Void)? = onOpenDetail.map { handler in
      { [weak self] in
        self?.dismiss()
        handler()
      }
    }

    hostingController.rootView = AnyView(
      StarCardFocusOverlay(
        star: star,
        onDismiss: dismiss,
        onOpenDetail: openDetail
      )
    )

    window.isHidden = false
    window.alpha = 1
  }

  func dismiss() {
    overlayWindow?.isHidden = true
    hostingController?.rootView = AnyView(EmptyView())
  }

  private func ensureWindow() {
    guard overlayWindow == nil else { return }
    let scene = windowScene ?? UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
    let bounds = scene?.screen.bounds ?? UIScreen.main.bounds

    let window = UIWindow(frame: bounds)
    if let scene {
      window.windowScene = scene
    }
    window.windowLevel = UIWindow.Level.alert + 1
    window.backgroundColor = .clear
    window.isUserInteractionEnabled = true
    window.isHidden = true

    let hosting = UIHostingController(rootView: AnyView(EmptyView()))
    hosting.view.backgroundColor = .clear
    window.rootViewController = hosting

    overlayWindow = window
    hostingController = hosting
  }
}

