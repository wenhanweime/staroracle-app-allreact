import SwiftUI
import StarOracleServices

@MainActor
struct AIConfigSheet: View {
  @EnvironmentObject private var environment: AppEnvironment
  @State private var config: AIConfiguration = AIConfiguration(
    provider: "openai",
    apiKey: "",
    endpoint: URL(string: "https://api.openai.com/v1/chat/completions")!,
    model: "gpt-4o-mini"
  )
  @State private var validationMessage: String?
  @State private var isValidating = false
  @State private var isSaving = false

  var body: some View {
    NavigationStack {
      Form {
        Section("提供商") {
          TextField("Provider", text: $config.provider)
#if os(iOS)
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
#endif
        }
        Section("API 配置") {
          SecureField("API Key", text: $config.apiKey)
          TextField("Endpoint", text: Binding(
            get: { config.endpoint.absoluteString },
            set: { config.endpoint = URL(string: $0) ?? config.endpoint }
          ))
#if os(iOS)
          .keyboardType(.URL)
#endif
          TextField("模型", text: $config.model)
#if os(iOS)
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
#endif
        }
        Section("验证") {
          VStack(alignment: .leading, spacing: 12) {
            Button {
              Task { await validateConfig() }
            } label: {
              if isValidating {
                ProgressView()
              } else {
                Label("验证配置", systemImage: "checkmark.seal")
              }
            }
            .buttonStyle(.bordered)

            if let validationMessage {
              Text(validationMessage)
                .font(.footnote)
                .foregroundStyle(.secondary)
            } else {
              Text("验证会直接向配置的 Endpoint 发送一次最小请求，用于确认 API Key / 模型是否可用。")
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
          }
        }
      }
      .navigationTitle("AI 配置")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("关闭") {
            dismiss()
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button {
            Task { await saveConfig() }
          } label: {
            if isSaving {
              ProgressView()
            } else {
              Text("保存")
            }
          }
          .disabled(isSaving)
        }
      }
      .task {
        await loadConfig()
      }
    }
  }

  @Environment(\.dismiss) private var dismiss

  private func loadConfig() async {
    if let stored = await environment.preferenceService.loadAIConfiguration() {
      config = stored
    }
  }

  private func saveConfig() async {
    isSaving = true
    defer { isSaving = false }
    do {
      try await environment.preferenceService.saveAIConfiguration(config)
      validationMessage = "配置已保存。"
      dismiss()
    } catch {
      validationMessage = "保存失败：\(error.localizedDescription)"
    }
  }

  private func validateConfig() async {
    guard !isValidating else { return }
    isValidating = true
    defer { isValidating = false }
    do {
      try await environment.aiService.validate(configuration: config)
      validationMessage = "验证成功。"
    } catch {
      validationMessage = "验证失败：\(error.localizedDescription)"
    }
  }
}
