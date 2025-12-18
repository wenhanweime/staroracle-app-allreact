import Foundation
import SwiftUI
import StarOracleCore
import StarOracleFeatures

struct DrawerMenuView: View {
  @EnvironmentObject private var starStore: StarStore
  @EnvironmentObject private var chatStore: ChatStore
  @EnvironmentObject private var conversationStore: ConversationStore
  @EnvironmentObject private var authService: AuthService

  var onClose: () -> Void
  var onOpenTemplate: () -> Void
  var onOpenCollection: () -> Void
  var onOpenAIConfig: () -> Void
  var onOpenInspiration: () -> Void
  var onOpenAccount: () -> Void
  var onOpenServerChat: (ChatListService.Chat) -> Void
  var onSwitchSession: (String) -> Void
  var onCreateSession: (String?) -> Void
  var onRenameSession: (String, String) -> Void
  var onDeleteSession: (String) -> Void

  @State private var query: String = ""
  @State private var sessionToRename: ConversationStore.Session?
  @State private var renameText: String = ""
  @State private var sessionToDelete: ConversationStore.Session?
  @State private var serverChats: [ChatListService.Chat] = []
  @State private var isLoadingServerChats: Bool = false

  private var filteredSessions: [ConversationStore.Session] {
    let sessions = conversationStore.listSessions()
    guard !query.isEmpty else { return sessions }
    return sessions.filter { session in
      session.displayTitle.localizedCaseInsensitiveContains(query) ||
      session.systemPrompt.localizedCaseInsensitiveContains(query)
    }
  }

  private var hasSupabaseConfig: Bool {
    SupabaseRuntime.loadConfig() != nil
  }

  private var filteredServerChats: [ChatListService.Chat] {
    guard !query.isEmpty else { return serverChats }
    return serverChats.filter { chat in
      (chat.title ?? "").localizedCaseInsensitiveContains(query)
    }
  }

  var body: some View {
    VStack(spacing: 0) {
      header
      Divider().overlay(Color.white.opacity(0.1))
      VStack(alignment: .leading, spacing: 16) {
        searchBar
      }
      .padding(.horizontal, 24)
      .padding(.top, 20)
      .padding(.bottom, 12)

      ScrollView(showsIndicators: false) {
        VStack(alignment: .leading, spacing: 18) {
          sessionList
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
      }

      Divider().overlay(Color.white.opacity(0.05))
      VStack(alignment: .leading, spacing: 18) {
        menuSection
        Divider().overlay(Color.white.opacity(0.05))
        statsSection
      }
      .padding(.horizontal, 24)
      .padding(.vertical, 16)

      Divider().overlay(Color.white.opacity(0.05))
      accountSection
        .padding(.horizontal, 24)
        .padding(.vertical, 14)

      closeButton
    }
    .frame(width: 340)
    .frame(maxHeight: .infinity, alignment: .top)
    .background(
      LinearGradient(
        colors: [
          Color(red: 13/255, green: 18/255, blue: 30/255).opacity(0.96),
          Color(red: 6/255, green: 8/255, blue: 15/255).opacity(0.98)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .overlay(Color.white.opacity(0.05), alignment: .top)
    )
    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    .shadow(color: .black.opacity(0.4), radius: 30, x: 0, y: 20)
    .overlay(
      RoundedRectangle(cornerRadius: 28, style: .continuous)
        .stroke(Color.white.opacity(0.06), lineWidth: 1)
    )
    .sheet(item: $sessionToRename, onDismiss: { renameText = "" }) { session in
      RenameSessionSheet(
        title: session.displayTitle,
        initialValue: renameText.isEmpty ? session.displayTitle : renameText
      ) { newTitle in
        onRenameSession(session.id, newTitle)
      }
    }
    .alert("删除会话？", isPresented: Binding(
      get: { sessionToDelete != nil },
      set: { if !$0 { sessionToDelete = nil } }
    )) {
      Button("取消", role: .cancel) { sessionToDelete = nil }
      if let target = sessionToDelete {
        Button("删除", role: .destructive) {
          onDeleteSession(target.id)
          sessionToDelete = nil
        }
      }
    } message: {
      if let target = sessionToDelete {
        Text("历史记录将被移除：\(target.displayTitle)")
      }
    }
    .task {
      await refreshServerChats()
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("星谕")
        .font(.system(size: 22, weight: .semibold, design: .serif))
        .foregroundStyle(.white)
      Text("StarOracle Atlas")
        .font(.footnote)
        .foregroundStyle(.white.opacity(0.6))
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, 24)
    .padding(.top, 48)
    .padding(.bottom, 20)
  }

  private var searchBar: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Image(systemName: "magnifyingglass")
        TextField("搜索对话…", text: $query)
          .textInputAutocapitalization(.none)
      }
      .padding(14)
      .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
      .overlay(
        RoundedRectangle(cornerRadius: 16)
          .stroke(Color.white.opacity(0.12), lineWidth: 1)
      )

      Button {
        onCreateSession(nil)
      } label: {
        Label("新建会话", systemImage: "sparkles")
          .font(.footnote.weight(.medium))
          .frame(maxWidth: .infinity)
          .padding(.vertical, 12)
          .background(
            LinearGradient(
              colors: [Color.purple.opacity(0.8), Color.blue.opacity(0.6)],
              startPoint: .leading,
              endPoint: .trailing
            ),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
          )
      }
      .buttonStyle(.plain)
    }
  }

  private var sessionList: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("历史会话")
        .font(.caption)
        .foregroundStyle(.white.opacity(0.6))
      serverSessionList
      Divider().overlay(Color.white.opacity(0.05))
      localSessionList
    }
  }

  private var serverSessionList: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(spacing: 8) {
        Text("云端（可打开）")
          .font(.footnote.weight(.medium))
          .foregroundStyle(.white.opacity(0.8))
        Spacer()
        if isLoadingServerChats {
          ProgressView()
            .progressViewStyle(.circular)
            .tint(.white.opacity(0.7))
            .scaleEffect(0.7)
        }
        Button {
          Task { await refreshServerChats() }
        } label: {
          Image(systemName: "arrow.clockwise")
            .font(.caption)
            .foregroundStyle(.white.opacity(0.8))
            .padding(6)
            .background(Color.white.opacity(0.08), in: Circle())
        }
        .buttonStyle(.plain)
        .disabled(!hasSupabaseConfig || isLoadingServerChats)
      }

      if !hasSupabaseConfig {
        Text("未配置 SUPABASE_URL + TOKEN/SUPABASE_JWT")
          .font(.footnote)
          .foregroundStyle(.white.opacity(0.4))
          .frame(maxWidth: .infinity, alignment: .leading)
      } else if filteredServerChats.isEmpty {
        Text("暂无记录")
          .font(.footnote)
          .foregroundStyle(.white.opacity(0.4))
          .frame(maxWidth: .infinity, alignment: .leading)
      } else {
        ForEach(filteredServerChats) { chat in
          serverChatRow(chat)
        }
      }
    }
  }

  private var localSessionList: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("本地（旧链路）")
        .font(.footnote.weight(.medium))
        .foregroundStyle(.white.opacity(0.8))
      if filteredSessions.isEmpty {
        Text("暂无记录")
          .font(.footnote)
          .foregroundStyle(.white.opacity(0.4))
          .frame(maxWidth: .infinity, alignment: .leading)
      } else {
        ForEach(filteredSessions) { session in
          sessionRow(session)
        }
      }
    }
  }

  private func serverChatRow(_ chat: ChatListService.Chat) -> some View {
    Button {
      onOpenServerChat(chat)
      onClose()
    } label: {
      VStack(alignment: .leading, spacing: 4) {
        Text((chat.title ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "未命名会话" : (chat.title ?? "未命名会话"))
          .font(.headline)
          .foregroundStyle(.white)
        if let kind = chat.kind {
          Text(kind == "free" ? "自由对话" : (kind == "star" ? "星卡内对话" : kind))
            .font(.caption2)
            .foregroundStyle(.white.opacity(0.6))
        }
      }
      .padding()
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(
        RoundedRectangle(cornerRadius: 18, style: .continuous)
          .fill(Color.white.opacity(0.04))
          .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
              .stroke(Color.white.opacity(0.08), lineWidth: 1)
          )
      )
    }
    .buttonStyle(.plain)
  }

  private func sessionRow(_ session: ConversationStore.Session) -> some View {
    let isActive = session.id == conversationStore.currentSessionId
    return Button {
      onSwitchSession(session.id)
      onClose()
    } label: {
      HStack(alignment: .top, spacing: 12) {
        VStack(alignment: .leading, spacing: 4) {
          Text(session.displayTitle)
            .font(.headline)
            .foregroundStyle(.white)
          Text(session.formattedUpdatedAt)
            .font(.caption2)
            .foregroundStyle(.white.opacity(0.6))
        }
        Spacer()
        Menu {
          Button("重命名") {
            renameText = session.displayTitle
            sessionToRename = session
          }
          Button("删除", role: .destructive) {
            sessionToDelete = session
          }
        } label: {
          Image(systemName: "ellipsis")
            .font(.caption)
            .padding(6)
            .background(Color.white.opacity(0.08), in: Circle())
        }
        .menuIndicator(.hidden)
      }
      .padding()
      .background(
        RoundedRectangle(cornerRadius: 18, style: .continuous)
          .fill(isActive ? Color.white.opacity(0.16) : Color.white.opacity(0.04))
          .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
              .stroke(isActive ? Color.white.opacity(0.3) : Color.white.opacity(0.08), lineWidth: 1)
          )
      )
    }
    .buttonStyle(.plain)
  }

  private func refreshServerChats() async {
    guard hasSupabaseConfig else {
      serverChats = []
      return
    }
    guard !isLoadingServerChats else { return }
    isLoadingServerChats = true
    defer { isLoadingServerChats = false }
    serverChats = await ChatListService.fetchChats(kind: "free", limit: 30)
  }

  private var accountSection: some View {
    Button {
      onOpenAccount()
      onClose()
    } label: {
      HStack(spacing: 12) {
        ZStack {
          Circle()
            .fill(
              LinearGradient(
                colors: [Color.purple.opacity(0.75), Color.blue.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
            )
          Text(accountAvatarText)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.white.opacity(0.9))
        }
        .frame(width: 38, height: 38)
        .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1))

        VStack(alignment: .leading, spacing: 2) {
          Text(accountTitle)
            .font(.footnote.weight(.medium))
            .foregroundStyle(.white)
          if !accountSubtitle.isEmpty {
            Text(accountSubtitle)
              .font(.caption2)
              .foregroundStyle(.white.opacity(0.6))
              .lineLimit(1)
              .truncationMode(.middle)
          }
        }
        Spacer()
        Image(systemName: "chevron.right")
          .font(.caption2)
          .foregroundStyle(.white.opacity(0.6))
      }
      .padding(.vertical, 10)
      .padding(.horizontal, 12)
      .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: 14, style: .continuous)
          .stroke(Color.white.opacity(0.08), lineWidth: 1)
      )
    }
    .buttonStyle(.plain)
  }

  private var accountTitle: String {
    let email = (authService.userEmail ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    let prefix = (email.split(separator: "@").first.map(String.init) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    return prefix.isEmpty ? "个人主页" : prefix
  }

  private var accountSubtitle: String {
    (authService.userEmail ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private var accountAvatarText: String {
    let value = accountTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    if let first = value.first { return String(first).uppercased() }
    return "?"
  }

  private var menuSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("操作")
        .font(.caption)
        .foregroundStyle(.white.opacity(0.6))
      VStack(spacing: 10) {
        DrawerMenuButton(title: "所有项目", icon: "square.grid.2x2", badge: "\(starStore.constellation.stars.count)") { }
        DrawerMenuButton(title: "选择星座", icon: "sparkles") {
          onOpenTemplate()
          onClose()
        }
        DrawerMenuButton(title: "灵感卡", icon: "wand.and.stars") {
          onOpenInspiration()
          onClose()
        }
        DrawerMenuButton(title: "星卡收藏", icon: "bookmark") {
          onOpenCollection()
          onClose()
        }
        DrawerMenuButton(title: "AI 配置", icon: "slider.horizontal.3") {
          onOpenAIConfig()
          onClose()
        }
      }
    }
  }

  private var statsSection: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("宇宙计数")
        .font(.caption)
        .foregroundStyle(.white.opacity(0.6))
      statRow(title: "星卡", value: "\(starStore.constellation.stars.count)")
      statRow(title: "灵感", value: "\(starStore.inspirationStars.count)")
      statRow(title: "对话", value: "\(chatStore.messages.count)")
    }
  }

  private func statRow(title: String, value: String) -> some View {
    HStack {
      Text(title)
        .font(.footnote)
        .foregroundStyle(.white.opacity(0.7))
      Spacer()
      Text(value)
        .font(.footnote.weight(.medium))
        .foregroundStyle(.white)
    }
    .padding(.vertical, 4)
  }

  private var closeButton: some View {
    Button {
      onClose()
    } label: {
      Label("关闭", systemImage: "xmark")
        .font(.footnote.weight(.medium))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.08))
    }
    .buttonStyle(.plain)
  }
}

private struct DrawerMenuButton: View {
  let title: String
  let icon: String
  var badge: String?
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack {
        Label(title, systemImage: icon)
          .foregroundStyle(.white)
        Spacer()
        if let badge {
          Text(badge)
            .font(.caption2)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.white.opacity(0.12), in: Capsule())
        }
        Image(systemName: "chevron.right")
          .font(.caption2)
          .foregroundStyle(.white.opacity(0.6))
      }
      .padding(.vertical, 10)
      .padding(.horizontal, 12)
      .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))
    }
    .buttonStyle(.plain)
  }
}

private struct RenameSessionSheet: View {
  let title: String
  @State var value: String
  let onConfirm: (String) -> Void
  @Environment(\.dismiss) private var dismiss

  init(title: String, initialValue: String, onConfirm: @escaping (String) -> Void) {
    self.title = title
    self._value = State(initialValue: initialValue)
    self.onConfirm = onConfirm
  }

  var body: some View {
    NavigationStack {
      Form {
        Section("新的会话名称") {
          TextField(title, text: $value)
            .textInputAutocapitalization(.never)
        }
      }
      .navigationTitle("重命名会话")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("取消") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("保存") {
            onConfirm(value.trimmingCharacters(in: .whitespacesAndNewlines))
            dismiss()
          }
          .disabled(value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
      }
    }
    .presentationDetents([.medium])
  }
}
