import SwiftUI
import UIKit
import PhotosUI
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
  @State private var isShowingCloudModelEditor = false
  @State private var errorMessage: String?
  @State private var isVerboseLogsEnabled: Bool = StarOracleDebug.verboseLogsEnabled
  @State private var isRefreshingLongTermMemory: Bool = false
  @State private var longTermMemoryRefreshStatus: String?
  @State private var lastRemoteReloadAt: Date?

  @State private var draftDisplayName: String = ""
  @State private var draftAvatarEmoji: String = ""
  @State private var draftPreferredModelId: String = ""
  @State private var avatarPhotoItem: PhotosPickerItem?
  @State private var avatarPhotoPreview: UIImage?
  @State private var avatarPhotoJPEG: Data?
  @State private var shouldClearAvatarPhoto: Bool = false

  private let avatarOptions: [String] = ["🪐", "🌙", "⭐️", "🌟", "✨", "☄️", "🌌", "🛰️", "🚀", "🔭", "🧿", "🌑"]
  private let modelOptions: [String] = ["gpt-4.1-mini", "gpt-4.1", "gpt-4o-mini", "gpt-4o", "gpt-3.5-turbo"]

  var body: some View {
    NavigationStack {
      Form {
        profileHeaderSection
        if isEditing {
          editSection
        }
        statsSection
        accountInfoSection
        settingsSection
        debugSection
        longTermMemorySection

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
      .onAppear {
        hydrateFromCacheIfPossible()
        Task { await reload(force: false) }
      }
      .onChange(of: avatarPhotoItem) { _, newValue in
        guard let newValue else { return }
        Task { @MainActor in
          do {
            guard let data = try await newValue.loadTransferable(type: Data.self) else { return }
            guard let processed = AvatarImageProcessor.makeAvatarJPEG(from: data) else {
              errorMessage = "图片处理失败，请换一张试试。"
              return
            }
            avatarPhotoJPEG = processed.jpeg
            avatarPhotoPreview = processed.preview
            shouldClearAvatarPhoto = false
          } catch {
            errorMessage = error.localizedDescription
          }
        }
      }
    }
    .sheet(isPresented: $isShowingAIConfig) {
      AIConfigSheet()
        .environmentObject(environment)
    }
    .sheet(isPresented: $isShowingCloudModelEditor) {
      cloudModelEditorSheet
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
        Text("头像照片")
          .font(.footnote)
          .foregroundStyle(.secondary)

        PhotosPicker(selection: $avatarPhotoItem, matching: .images) {
          HStack(spacing: 10) {
            Image(systemName: "photo")
            Text("从相册选择")
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .overlay(alignment: .trailing) {
            Image(systemName: "chevron.right")
              .font(.caption2)
              .foregroundStyle(.secondary)
          }
        }
        .disabled(isSaving)

        HStack(spacing: 12) {
          ZStack {
            Circle()
              .fill(Color.white.opacity(0.08))
            if shouldClearAvatarPhoto {
              Image(systemName: "person.crop.circle.badge.xmark")
                .foregroundStyle(.secondary)
            } else if let preview = avatarPhotoPreview {
              Image(uiImage: preview)
                .resizable()
                .scaledToFill()
            } else if let url = resolvedAvatarPhotoURL {
              AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                  image.resizable().scaledToFill()
                default:
                  Color.clear
                }
              }
            } else {
              Image(systemName: "person.crop.circle")
                .foregroundStyle(.secondary)
            }
          }
          .frame(width: 64, height: 64)
          .clipShape(Circle())
          .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))

          VStack(alignment: .leading, spacing: 6) {
            Text(shouldClearAvatarPhoto ? "将移除照片头像" : (resolvedAvatarPhotoURL != nil || avatarPhotoPreview != nil ? "已选择照片头像" : "未设置照片头像"))
              .font(.footnote)
              .foregroundStyle(.secondary)

            HStack(spacing: 10) {
              if shouldClearAvatarPhoto {
                Button("撤销移除") {
                  shouldClearAvatarPhoto = false
                }
                .buttonStyle(.bordered)
              } else if resolvedAvatarPhotoURL != nil || avatarPhotoPreview != nil {
                Button(role: .destructive) {
                  shouldClearAvatarPhoto = true
                  avatarPhotoItem = nil
                  avatarPhotoPreview = nil
                  avatarPhotoJPEG = nil
                } label: {
                  Text("移除照片")
                }
                .buttonStyle(.bordered)
              }
            }
          }

          Spacer()
        }
      }
      .padding(.vertical, 6)

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
      if hasSupabaseConfig {
        Button {
          beginEditCloudModel()
        } label: {
          HStack {
            Text("云端模型")
            Spacer()
            Text(resolvedPreferredModelDisplayText)
              .foregroundStyle(.secondary)
              .lineLimit(1)
              .truncationMode(.middle)
            Image(systemName: "chevron.right")
              .font(.caption2)
              .foregroundStyle(.secondary)
          }
        }
        .disabled(isSaving || isLoading)

        Text("云端对话会优先使用该模型；留空表示使用云端默认。")
          .font(.footnote)
          .foregroundStyle(.secondary)
      }

      Button {
        isShowingAIConfig = true
      } label: {
        Text(hasSupabaseConfig ? "本地 AI 配置（兜底）" : "AI 配置")
      }
      .disabled(isSaving || isLoading)

      if hasSupabaseConfig {
        Text("本地 AI 配置仅在未启用云端会话时生效。")
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
    }
  }

  private var cloudModelEditorSheet: some View {
    NavigationStack {
      Form {
        Section("云端模型 ID") {
          TextField("留空=默认", text: $draftPreferredModelId)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

          VStack(alignment: .leading, spacing: 10) {
            Text("快速选择")
              .font(.footnote)
              .foregroundStyle(.secondary)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
              ForEach(modelOptions, id: \.self) { model in
                Button {
                  draftPreferredModelId = model
                } label: {
                  Text(model)
                    .font(.footnote.weight(.medium))
                    .frame(maxWidth: .infinity, minHeight: 36)
                    .background(
                      RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(draftPreferredModelId == model ? Color.accentColor.opacity(0.18) : Color.clear)
                    )
                }
                .buttonStyle(.plain)
              }
            }
          }
          .padding(.vertical, 6)

          Button(role: .destructive) {
            draftPreferredModelId = ""
          } label: {
            Text("恢复默认（清空）")
          }
        }
      }
      .navigationTitle("云端模型")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("取消") { isShowingCloudModelEditor = false }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button {
            Task { await saveCloudModel() }
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

  private var longTermMemorySection: some View {
    Section("长期记忆") {
      if !hasSupabaseConfig {
        Text("未启用（需要 Supabase 配置）")
          .font(.footnote)
          .foregroundStyle(.secondary)
      } else if let memory = resolvedLongTermMemoryPrompt, !memory.isEmpty {
        Text(memory)
          .font(.footnote)
          .textSelection(.enabled)
        labeledValueRow(title: "更新时间", value: resolvedLongTermMemoryUpdatedAtText)
        labeledValueRow(title: "纳入消息截止", value: resolvedLongTermMemoryLastMessageAtText)
      } else {
        Text("暂无（会在对话后自动生成）")
          .font(.footnote)
          .foregroundStyle(.secondary)
      }

      if hasSupabaseConfig {
        HStack {
          Button {
            Task { await refreshLongTermMemory() }
          } label: {
            if isRefreshingLongTermMemory {
              ProgressView()
            } else {
              Text("立即刷新")
            }
          }
          .disabled(isRefreshingLongTermMemory || isSaving || isLoading)
          Spacer()
        }

        if let status = longTermMemoryRefreshStatus?.trimmingCharacters(in: .whitespacesAndNewlines),
           !status.isEmpty {
          Text(status)
            .font(.footnote)
            .foregroundStyle(status.hasPrefix("刷新失败") ? .red : .secondary)
        }
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
    let uid = resolvedUserId.trimmingCharacters(in: .whitespacesAndNewlines)
    let localURL = uid.isEmpty ? nil : AvatarDiskCache.localURL(for: uid)

    return ZStack {
      Circle()
        .fill(LinearGradient(
          colors: [Color.purple.opacity(0.65), Color.blue.opacity(0.55)],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        ))
      if !shouldClearAvatarPhoto, let preview = avatarPhotoPreview {
        avatarPhotoLayer(preview)
      } else if !shouldClearAvatarPhoto, let localURL, let image = UIImage(contentsOfFile: localURL.path) {
        avatarPhotoLayer(image)
      } else if !shouldClearAvatarPhoto, let url = resolvedAvatarPhotoURL {
        avatarPhotoLayer(url)
      } else if let emoji {
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

  private func avatarPhotoLayer(_ url: URL) -> some View {
    AsyncImage(url: url) { phase in
      switch phase {
      case .success(let image):
        image
          .resizable()
          .scaledToFill()
      default:
        Color.clear
      }
    }
    .clipShape(Circle())
  }

  private func avatarPhotoLayer(_ image: UIImage) -> some View {
    Image(uiImage: image)
      .resizable()
      .scaledToFill()
      .clipShape(Circle())
  }

  private var resolvedAvatarPhotoURL: URL? {
    let raw = (profile?.avatarUrl ?? authService.resolvedAvatarUrl ?? "")
      .trimmingCharacters(in: .whitespacesAndNewlines)
    guard !raw.isEmpty else { return nil }
    return URL(string: raw)
  }

  private var resolvedDisplayName: String {
    let backendName = profile?.displayName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    if !backendName.isEmpty { return backendName }
    return authService.resolvedDisplayName
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

  private var resolvedPreferredModelId: String {
    (profile?.preferredModelId ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private var resolvedPreferredModelDisplayText: String {
    let raw = resolvedPreferredModelId
    return raw.isEmpty ? "默认（云端）" : raw
  }

  private var resolvedLongTermMemoryPrompt: String? {
    let raw = profile?.longTermMemoryPrompt?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    return raw.isEmpty ? nil : raw
  }

  private var resolvedLongTermMemoryUpdatedAtText: String {
    guard let raw = profile?.longTermMemoryUpdatedAt?.trimmingCharacters(in: .whitespacesAndNewlines),
          !raw.isEmpty else { return "—" }
    if let parsed = parseISODate(raw) {
      return DateFormatter.localizedString(from: parsed, dateStyle: .medium, timeStyle: .short)
    }
    return raw
  }

  private var resolvedLongTermMemoryLastMessageAtText: String {
    guard let raw = profile?.longTermMemoryLastMessageAt?.trimmingCharacters(in: .whitespacesAndNewlines),
          !raw.isEmpty else { return "—" }
    if let parsed = parseISODate(raw) {
      return DateFormatter.localizedString(from: parsed, dateStyle: .medium, timeStyle: .short)
    }
    return raw
  }

  private var resolvedAvatarEmoji: String? {
    let raw = profile?.avatarEmoji?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    if !raw.isEmpty { return raw }
    return authService.resolvedAvatarEmoji
  }

  private var resolvedAvatarFallback: String {
    authService.resolvedAvatarFallback
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
    avatarPhotoItem = nil
    avatarPhotoPreview = nil
    avatarPhotoJPEG = nil
    shouldClearAvatarPhoto = false
    errorMessage = nil
  }

  private func beginEditCloudModel() {
    draftPreferredModelId = resolvedPreferredModelId
    isShowingCloudModelEditor = true
    errorMessage = nil
  }

  private func cancelEdit() {
    isEditing = false
    avatarPhotoItem = nil
    avatarPhotoPreview = nil
    avatarPhotoJPEG = nil
    shouldClearAvatarPhoto = false
    errorMessage = nil
  }

  private func saveCloudModel() async {
    guard hasSupabaseConfig else { return }
    guard !isSaving else { return }
    isSaving = true
    defer { isSaving = false }
    errorMessage = nil

    do {
      let result = try await ProfileService.updateProfile(
        displayName: nil,
        avatarEmoji: nil,
        preferredModelId: draftPreferredModelId.trimmingCharacters(in: .whitespacesAndNewlines)
      )
      user = result.user
      profile = result.profile
      persistProfileSnapshot()
      isShowingCloudModelEditor = false
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  private func saveEdit() async {
    guard !isSaving else { return }
    isSaving = true
    defer { isSaving = false }
    errorMessage = nil

    do {
      var avatarUrlUpdate: String? = nil
      if shouldClearAvatarPhoto {
        avatarUrlUpdate = ""
        let uid = resolvedUserId
        if !uid.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
          AvatarDiskCache.clear(userId: uid)
        }
      } else if let jpeg = avatarPhotoJPEG {
        let uid = resolvedUserId
        if uid.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
          throw AvatarUploadService.AvatarUploadError.invalidUserId
        }
        avatarUrlUpdate = try await AvatarUploadService.uploadAvatarJPEG(jpeg, userId: uid)
        if let avatarUrlUpdate {
          AvatarDiskCache.save(jpeg, userId: uid, remoteURL: avatarUrlUpdate)
        } else {
          AvatarDiskCache.save(jpeg, userId: uid)
        }
      }

      let result = try await ProfileService.updateProfile(
        displayName: draftDisplayName,
        avatarEmoji: draftAvatarEmoji,
        avatarUrl: avatarUrlUpdate
      )
      user = result.user
      profile = result.profile
      authService.applyProfile(
        displayName: result.profile.displayName,
        avatarEmoji: result.profile.avatarEmoji,
        avatarUrl: result.profile.avatarUrl
      )
      persistProfileSnapshot()
      avatarPhotoItem = nil
      avatarPhotoPreview = nil
      avatarPhotoJPEG = nil
      shouldClearAvatarPhoto = false
      isEditing = false
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  private func reload(force: Bool) async {
    guard !isLoading else { return }
    if !force,
       let last = lastRemoteReloadAt,
       Date().timeIntervalSince(last) < 60 {
      return
    }
    isLoading = true
    defer { isLoading = false }
    errorMessage = nil

    do {
      let result = try await ProfileService.getProfile()
      user = result.user
      profile = result.profile
      stats = result.stats
      authService.applyProfile(
        displayName: result.profile.displayName,
        avatarEmoji: result.profile.avatarEmoji,
        avatarUrl: result.profile.avatarUrl
      )
      persistProfileSnapshot()
      lastRemoteReloadAt = Date()
    } catch {
      stats = nil
      errorMessage = error.localizedDescription
    }
  }

  private func reload() async {
    await reload(force: true)
  }

  private func hydrateFromCacheIfPossible() {
    let currentUserId = authService.userId ?? AuthSessionStore.load()?.userId
    let currentEmail = authService.userEmail ?? AuthSessionStore.load()?.email
    if user != nil && profile != nil { return }
    guard let snapshot = ProfileSnapshotStore.load(userId: currentUserId, email: currentEmail) else { return }
    user = snapshot.user
    profile = snapshot.profile
    stats = snapshot.stats
  }

  private func persistProfileSnapshot() {
    guard let user, let profile else { return }
    let currentUserId = authService.userId ?? AuthSessionStore.load()?.userId
    let currentEmail = authService.userEmail ?? AuthSessionStore.load()?.email
    ProfileSnapshotStore.save(
      user: user,
      profile: profile,
      stats: stats,
      userId: currentUserId,
      email: currentEmail
    )
  }

  private func refreshLongTermMemory() async {
    guard hasSupabaseConfig else { return }
    guard !isRefreshingLongTermMemory else { return }
    isRefreshingLongTermMemory = true
    defer { isRefreshingLongTermMemory = false }

    do {
      let result = try await UserMemoryRefreshService.refresh(force: true)
      let updated = String(result.updated ?? false)
      let reason = result.reason ?? "nil"
      let processed = result.processedMessages.map(String.init) ?? "nil"
      let tokens = result.approxTokens.map(String.init) ?? "nil"
      longTermMemoryRefreshStatus = "刷新完成：updated=\(updated) reason=\(reason) processed=\(processed) tokens=\(tokens)"
      await reload()
    } catch {
      longTermMemoryRefreshStatus = "刷新失败：\(error.localizedDescription)"
    }
  }
}
