import SwiftUI
import StarOracleCore
import StarOracleFeatures

struct StarCardFocusOverlay: View {
  let star: Star
  var onDismiss: () -> Void
  var onOpenDetail: (() -> Void)?

  @State private var isFlipped = false
  @State private var isAppearing = false
  @State private var dragOffset: CGSize = .zero
  @State private var isClosing = false

  private let cardWidth: CGFloat = 300
  private let cardHeight: CGFloat = 440

  var body: some View {
    ZStack {
      Color.black.opacity(isClosing ? 0 : 0.6)
        .ignoresSafeArea()
        .onTapGesture { dismiss() }
        .animation(.easeOut(duration: 0.25), value: isClosing)

      VStack(spacing: 14) {
        StarCardView(
          star: star,
          isFlipped: isFlipped,
          onFlip: { isFlipped.toggle() }
        )
        .frame(width: cardWidth, height: cardHeight)
        .offset(dragOffset)
        .rotationEffect(.degrees(Double(dragOffset.width / 18)))
        .scaleEffect(isClosing ? 0.85 : (isAppearing ? 1 : 0.92))
        .opacity(isClosing ? 0 : (isAppearing ? 1 : 0))
        .gesture(
          DragGesture()
            .onChanged { value in
              dragOffset = value.translation
            }
            .onEnded { value in
              let threshold: CGFloat = 110
              if abs(value.translation.width) > threshold || abs(value.velocity.width) > 650 {
                dismiss(velocity: value.velocity)
              } else {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                  dragOffset = .zero
                }
              }
            }
        )

        HStack(spacing: 12) {
          if let onOpenDetail {
            Button("详情") { onOpenDetail() }
              .buttonStyle(.bordered)
              .tint(.white.opacity(0.9))
          }
          Button("关闭") { dismiss() }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
        }
      }
      .padding(.horizontal, 24)
    }
    .zIndex(200)
    .onAppear {
      withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.05)) {
        isAppearing = true
      }
    }
  }

  private func dismiss(velocity: CGSize = .zero) {
    withAnimation(.easeIn(duration: 0.22)) {
      isClosing = true
      if velocity != .zero {
        dragOffset.width += velocity.width * 0.18
        dragOffset.height += velocity.height * 0.18
      }
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
      onDismiss()
      isFlipped = false
      isAppearing = false
      isClosing = false
      dragOffset = .zero
    }
  }
}

