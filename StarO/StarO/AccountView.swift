import SwiftUI
import UIKit
import StarOracleCore
import StarOracleFeatures
import StarOracleServices

@MainActor
struct AccountView: View {
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject private var environment: AppEnvironment
  @EnvironmentObject private var authService: AuthService
  @EnvironmentObject private var starStore: StarStore
  @EnvironmentObject private var conversationStore: ConversationStore

  @State private var user: ProfileService.User?
  @State private var profile: ProfileService.Profile?
  @State private var stats: ProfileService.Stats?

  @State private var isLoading = false
  @State private var isEditing = false
  @State private var isSaving = false
  @State private var isShowingAIConfig = false
  @State private var errorMessage: String?
  @State private var isVerboseLogsEnabled: Bool = StarOracleDebug.verboseLogsEnabled

  @State private var draftDisplayName: String = ""
  @State private var draftAvatarEmoji: String = ""

  private let avatarOptions: [String] = ["🪐", "🌙", "⭐️", "🌟", "✨", "☄️", "🌌", "🛰️", "🚀", "🔭", "🧿", "🌑"]

  var body: some View {
    NavigationStack {
      Form {
        profileHeaderSection
        statsSection
        accountInfoSection
        settingsSection
        debugSection

        if isEditing {
          editSection
        }

        actionsSection

        if let errorMessage {
          Section {
            Text(errorMessage)
              .font(.footnote)
              .foregroundStyle(.red)
          }
        }
      }
      .navigationTitle("个人主页")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("关闭") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button {
            Task { await reload() }
          } label: {
            if isLoading {
              ProgressView()
            } else {
              Text("刷新")
            }
          }
          .disabled(isLoading || isSaving)
        }
      }
      .task {
        await reload()
      }
    }
    .sheet(isPresented: $isShowingAIConfig) {
      AIConfigSheet()
        .environmentObject(environment)
    }
  }

  private var profileHeaderSection: some View {
    Section {
      HStack(spacing: 14) {
        avatarView(size: 54)
        VStack(alignment: .leading, spacing: 4) {
          Text(resolvedDisplayName)
            .font(.headline)
          Text(resolvedEmail)
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        Spacer()
        Button {
          beginEdit()
        } label: {
          Text("编辑")
        }
        .disabled(isSaving)
      }
      .padding(.vertical, 6)
    }
  }

  private var statsSection: some View {
    Section("统计") {
      labeledValueRow(title: "能量", value: resolvedEnergyText)
      labeledValueRow(title: "星卡数", value: resolvedStarsCountText)
      labeledValueRow(title: "对话数", value: resolvedChatsCountText)
    }
  }

  private var accountInfoSection: some View {
    Section("账号信息") {
      copyRow(title: "用户 ID", value: resolvedUserId)
      labeledValueRow(title: "注册时间", value: resolvedCreatedAtText)
      copyRow(title: "银河种子", value: resolvedGalaxySeed)
    }
  }

  private var editSection: some View {
    Section("编辑资料") {
      TextField("昵称（可留空）", text: $draftDisplayName)
      TextField("头像（emoji，可留空）", text: $draftAvatarEmoji)

      VStack(alignment: .leading, spacing: 10) {
        Text("快速选择")
          .font(.footnote)
          .foregroundStyle(.secondary)
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 6), spacing: 10) {
          ForEach(avatarOptions, id: \.self) { emoji in
            Button {
              draftAvatarEmoji = emoji
            } label: {
              Text(emoji)
                .font(.system(size: 22))
                .frame(maxWidth: .infinity, minHeight: 34)
                .background(
                  RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(draftAvatarEmoji == emoji ? Color.accentColor.opacity(0.2) : Color.clear)
                )
            }
            .buttonStyle(.plain)
          }
        }
      }
      .padding(.vertical, 6)

      HStack {
        Button("取消") { cancelEdit() }
          .buttonStyle(.bordered)
        Spacer()
        Button {
          Task { await saveEdit() }
        } label: {
          if isSaving {
            ProgressView()
          } else {
            Text("保存")
          }
        }
        .buttonStyle(.borderedProminent)
        .disabled(isSaving)
      }
    }
  }

  private var actionsSection: some View {
    Section("操作") {
      Button(role: .destructive) {
        Task {
          await authService.signOut()
          dismiss()
        }
      } label: {
        Text("退出登录")
      }
      .disabled(isSaving)
    }
  }

  private var settingsSection: some View {
    Section("设置") {
      Button {
        isShowingAIConfig = true
      } label: {
        Text("AI 配置")
      }
      .disabled(isSaving || isLoading)
    }
  }

  private var debugSection: some View {
    Section("调试") {
      labeledValueRow(title: "云端会话", value: hasSupabaseConfig ? "可打开" : "未启用")
      Toggle("详细日志", isOn: $isVerboseLogsEnabled)
        .onChange(of: isVerboseLogsEnabled) { _, newValue in
          StarOracleDebug.setVerboseLogsEnabled(newValue)
        }
    }
  }

  private var hasSupabaseConfig: Bool {
    SupabaseRuntime.loadConfig() != nil
  }

  private func labeledValueRow(title: String, value: String) -> some View {
    HStack {
      Text(title)
      Spacer()
      Text(value)
        .foregroundStyle(.secondary)
    }
  }

  private func copyRow(title: String, value: String) -> some View {
    HStack {
      Text(title)
      Spacer()
      Text(value)
        .foregroundStyle(.secondary)
        .lineLimit(1)
        .truncationMode(.middle)
      Button {
        UIPasteboard.general.string = value
      } label: {
        Image(systemName: "doc.on.doc")
      }
      .buttonStyle(.plain)
      .disabled(value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
  }

  private func avatarView(size: CGFloat) -> some View {
    let emoji = resolvedAvatarEmoji
    let fallback = resolvedAvatarFallback

    return ZStack {
      Circle()
        .fill(LinearGradient(
          colors: [Color.purple.opacity(0.65), Color.blue.opacity(0.55)],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        ))
      if let emoji {
        Text(emoji)
          .font(.system(size: size * 0.55))
      } else {
        Text(fallback)
          .font(.system(size: size * 0.45, weight: .semibold))
          .foregroundStyle(.white.opacity(0.9))
      }
    }
    .frame(width: size, height: size)
    .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1))
  }

  private var resolvedDisplayName: String {
    let backendName = profile?.displayName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    if !backendName.isEmpty { return backendName }
    let emailPrefix = (resolvedEmail.split(separator: "@").first.map(String.init) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    return emailPrefix.isEmpty ? "未设置昵称" : emailPrefix
  }

  private var resolvedEmail: String {
    (user?.email ?? authService.userEmail ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private var resolvedUserId: String {
    let remote = (user?.id ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    if !remote.isEmpty { return remote }
    return (AuthSessionStore.load()?.userId ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private var resolvedGalaxySeed: String {
    (profile?.galaxySeed ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private var resolvedEnergyText: String {
    if let remaining = authService.energyRemaining {
      return "\(remaining)"
    }
    return "—"
  }

  private var resolvedStarsCountText: String {
    if let remote = stats?.starsCount {
      return "\(remote)"
    }
    return "\(starStore.constellation.stars.count)（本地）"
  }

  private var resolvedChatsCountText: String {
    if let remote = stats?.chatsCount {
      return "\(remote)"
    }
    return "\(conversationStore.listSessions().count)（本地）"
  }

  private var resolvedCreatedAtText: String {
    guard let raw = profile?.createdAt?.trimmingCharacters(in: .whitespacesAndNewlines),
          !raw.isEmpty else { return "—" }
    if let parsed = parseISODate(raw) {
      return DateFormatter.localizedString(from: parsed, dateStyle: .medium, timeStyle: .none)
    }
    return raw
  }

  private var resolvedAvatarEmoji: String? {
    let raw = profile?.avatarEmoji?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    return raw.isEmpty ? nil : raw
  }

  private var resolvedAvatarFallback: String {
    let base = resolvedDisplayName
    let trimmed = base.trimmingCharacters(in: .whitespacesAndNewlines)
    if let first = trimmed.first {
      return String(first).uppercased()
    }
    return "?"
  }

  private func parseISODate(_ raw: String) -> Date? {
    let withFraction = ISO8601DateFormatter()
    withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let parsed = withFraction.date(from: raw) { return parsed }

    let noFraction = ISO8601DateFormatter()
    noFraction.formatOptions = [.withInternetDateTime]
    return noFraction.date(from: raw)
  }

  private func beginEdit() {
    isEditing = true
    draftDisplayName = profile?.displayName ?? ""
    draftAvatarEmoji = profile?.avatarEmoji ?? ""
    errorMessage = nil
  }

  private func cancelEdit() {
    isEditing = false
    errorMessage = nil
  }

  private func saveEdit() async {
    guard !isSaving else { return }
    isSaving = true
    defer { isSaving = false }
    errorMessage = nil

    do {
      let result = try await ProfileService.updateProfile(
        displayName: draftDisplayName,
        avatarEmoji: draftAvatarEmoji
      )
      user = result.user
      profile = result.profile
      isEditing = false
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  private func reload() async {
    guard !isLoading else { return }
    isLoading = true
    defer { isLoading = false }
    errorMessage = nil

    do {
      let result = try await ProfileService.getProfile()
      user = result.user
      profile = result.profile
      stats = result.stats
    } catch {
      stats = nil
      errorMessage = error.localizedDescription
    }
  }
}
