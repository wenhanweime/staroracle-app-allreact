import Combine
import SwiftUI
import StarOracleCore

#if os(iOS)
import UIKit

@MainActor
final class KeyboardObserver: ObservableObject {
  static let shared = KeyboardObserver()
  @Published var keyboardHeight: CGFloat = 0 {
    willSet { logStateChange("keyboardHeight -> \(newValue)") }
  }
  private var cancellables = Set<AnyCancellable>()

  private init() {
    NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)
      .merge(with: NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification))
      .sink { [weak self] notification in
        guard let self else { return }
        if notification.name == UIResponder.keyboardWillHideNotification {
          keyboardHeight = 0
          return
        }
        if let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
          keyboardHeight = frame.height
        }
      }
      .store(in: &cancellables)
  }
}

private extension KeyboardObserver {
  func logStateChange(_ label: String) {
    guard StarOracleDebug.verboseLogsEnabled else { return }
    NSLog("⚠️ KeyboardObserver mutate \(label) | stack:\n\(Thread.callStackSymbols.joined(separator: "\n"))")
  }
}
#endif
