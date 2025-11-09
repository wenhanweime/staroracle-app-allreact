import SwiftUI
import StarOracleCore
import StarOracleServices
import StarOracleFeatures

struct TemplatePickerView: View {
  @EnvironmentObject private var environment: AppEnvironment
  @EnvironmentObject private var starStore: StarStore
  @Environment(\.dismiss) private var dismiss

  @State private var templates: [ConstellationTemplate] = []
  @State private var isLoading = false
  @State private var errorMessage: String?

  var body: some View {
    NavigationStack {
      Group {
        if isLoading {
          ProgressView("正在载入模板…")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let errorMessage {
          VStack(spacing: 16) {
            Text(errorMessage)
              .multilineTextAlignment(.center)
            Button("重试") {
              loadTemplates()
            }
            .buttonStyle(.bordered)
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if templates.isEmpty {
          Text("暂未发现可用模板")
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
          List {
            Section {
              ForEach(templates) { template in
                TemplateRow(template: template) {
                  apply(template: template)
                }
              }
            } footer: {
              Text("模板将替换当前星图为预设结构，你仍可在其基础上继续生成新的星卡。")
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
          }
          #if os(iOS)
          .listStyle(.insetGrouped)
          #else
          .listStyle(.automatic)
          #endif
        }
      }
      .navigationTitle("选择模板")
      .toolbar {
        ToolbarItem(placement: .automatic) {
          Button("关闭") { dismiss() }
        }
      }
      .task { loadTemplates() }
    }
  }

  private func loadTemplates() {
    isLoading = true
    errorMessage = nil
    Task { @MainActor in
      let result = await environment.templateService.availableTemplates()
      templates = result
      isLoading = false
    }
  }

  private func apply(template: ConstellationTemplate) {
    Task { @MainActor in
      do {
        try await starStore.applyTemplate(template)
        dismiss()
      } catch {
        errorMessage = "应用模板失败：\(error.localizedDescription)"
      }
    }
  }
}

private struct TemplateRow: View {
  let template: ConstellationTemplate
  let onApply: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text(template.chineseName)
            .font(.headline)
          Text(template.description)
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        Spacer()
        Text(template.elementLabel)
          .font(.caption2)
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(elementColor.opacity(0.15))
          .clipShape(Capsule())
      }
      Button(role: .none) {
        onApply()
      } label: {
        Text("应用此模板")
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.borderedProminent)
    }
    .padding(.vertical, 8)
  }

  private var elementColor: Color {
    switch template.element {
    case .fire: return .orange
    case .earth: return .green
    case .air: return .blue
    case .water: return .purple
    }
  }
}

private extension ConstellationTemplate {
  var elementLabel: String {
    switch element {
    case .fire: return "火元素"
    case .earth: return "土元素"
    case .air: return "风元素"
    case .water: return "水元素"
    }
  }
}
