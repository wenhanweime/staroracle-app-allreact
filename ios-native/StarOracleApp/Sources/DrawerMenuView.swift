import SwiftUI
import StarOracleCore
import StarOracleFeatures

struct DrawerMenuView: View {
  @EnvironmentObject private var starStore: StarStore
  @EnvironmentObject private var chatStore: ChatStore

  var onClose: () -> Void
  var onOpenTemplate: () -> Void
  var onOpenCollection: () -> Void
  var onOpenAIConfig: () -> Void
  var onOpenInspiration: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 24) {
      header
      section(title: "快速操作", systemImage: "bolt.fill") {
        MenuButton(title: "生成星卡", icon: "sparkles") {
          Task { try? await starStore.addStar(question: "宇宙想和我说什么？", at: nil) }
        }
        MenuButton(title: "抽取灵感卡", icon: "moon.stars") {
          _ = starStore.drawInspirationCard(region: nil)
        }
      }
      section(title: "导航", systemImage: "list.bullet") {
        MenuButton(title: "模板库", icon: "hexagon") { onOpenTemplate() }
        MenuButton(title: "星卡收藏", icon: "rectangle.grid.2x2") { onOpenCollection() }
        MenuButton(title: "灵感卡", icon: "sparkles") { onOpenInspiration() }
        MenuButton(title: "AI 配置", icon: "slider.horizontal.3") { onOpenAIConfig() }
      }
      section(title: "统计", systemImage: "chart.bar.doc.horizontal") {
        Label("星卡：\(starStore.constellation.stars.count)", systemImage: "star")
          .foregroundStyle(.secondary)
        Label("对话：\(chatStore.messages.count/2)", systemImage: "bubble.left.and.bubble.right")
          .foregroundStyle(.secondary)
        Label("灵感卡：\(starStore.inspirationStars.count)", systemImage: "lightbulb")
          .foregroundStyle(.secondary)
      }
      Spacer()
      Button(role: .none) {
        onClose()
      } label: {
        Label("关闭", systemImage: "xmark")
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.bordered)
    }
    .padding(24)
    .frame(maxWidth: 320, maxHeight: .infinity, alignment: .topLeading)
    .background(.ultraThinMaterial)
    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    .shadow(color: .black.opacity(0.25), radius: 20, x: 0, y: 12)
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("StarOracle")
        .font(.title3.weight(.semibold))
      Text("原生迁移预览")
        .font(.caption)
        .foregroundStyle(.secondary)
    }
  }

  private func section<Content: View>(title: String, systemImage: String, @ViewBuilder content: () -> Content) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Label(title, systemImage: systemImage)
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
      VStack(alignment: .leading, spacing: 8) {
        content()
      }
    }
  }
}

private struct MenuButton: View {
  let title: String
  let icon: String
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Label(title, systemImage: icon)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .buttonStyle(.borderedProminent)
  }
}
