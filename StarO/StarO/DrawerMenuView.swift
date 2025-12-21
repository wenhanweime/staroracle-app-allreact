import Foundation
import SwiftUI
import UIKit
import StarOracleCore
import StarOracleFeatures

struct DrawerMenuView: View {
  @EnvironmentObject private var conversationStore: ConversationStore
  @EnvironmentObject private var authService: AuthService

  var onClose: () -> Void
  var onOpenAccount: () -> Void
  var onOpenServerChat: (ChatListService.Chat) -> Void
  var onSwitchSession: (String) -> Void
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
      VStack(alignment: .leading, spacing: 16) {
        searchBar
      }
      .padding(.horizontal, 24)
      .padding(.top, 56)
      .padding(.bottom, 12)
      Divider().overlay(Color.white.opacity(0.1))

      ScrollView(showsIndicators: false) {
        VStack(alignment: .leading, spacing: 18) {
          sessionList
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
      }

      Divider().overlay(Color.white.opacity(0.05))
      accountSection
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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
      .ignoresSafeArea()
    )
    .overlay(
      Rectangle()
        .fill(Color.white.opacity(0.08))
        .frame(width: 1)
        .frame(maxWidth: .infinity, alignment: .trailing)
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
      async let chatsTask: Void = refreshServerChats()
      async let profileTask: Void = authService.refreshProfileIfNeeded(force: false)
      _ = await (chatsTask, profileTask)
    }
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
    }
  }

  private var sessionList: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(spacing: 8) {
        Text("历史会话")
          .font(.caption)
          .foregroundStyle(.white.opacity(0.6))
        Spacer()
        if hasSupabaseConfig {
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
          .disabled(isLoadingServerChats)
        }
      }

      let hasAnyServer = hasSupabaseConfig && !filteredServerChats.isEmpty
      let hasAnyLocal = !filteredSessions.isEmpty

      if hasAnyServer {
        ForEach(filteredServerChats) { chat in
          serverChatRow(chat)
        }
      }

      if hasAnyServer && hasAnyLocal {
        Divider().overlay(Color.white.opacity(0.05))
      }

      if hasAnyLocal {
        ForEach(filteredSessions) { session in
          sessionRow(session)
        }
      }

      if !hasAnyServer && !hasAnyLocal {
        Text("暂无记录")
          .font(.footnote)
          .foregroundStyle(.white.opacity(0.4))
          .frame(maxWidth: .infinity, alignment: .leading)
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
        accountAvatarView
          .frame(width: 34, height: 34)

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
      .padding(.vertical, 8)
      .padding(.horizontal, 10)
      .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    .buttonStyle(.plain)
  }

  private var accountTitle: String {
    authService.resolvedDisplayName
  }

  private var accountSubtitle: String {
    (authService.userEmail ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private var accountAvatarView: some View {
    let uid = (authService.userId ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    let local = uid.isEmpty ? nil : AvatarDiskCache.localURL(for: uid)
    let remote = authService.resolvedAvatarUrl.flatMap(URL.init(string:))
    return ZStack {
      if let local, let image = UIImage(contentsOfFile: local.path) {
        Image(uiImage: image)
          .resizable()
          .scaledToFill()
      } else if let remote {
        AsyncImage(url: remote) { phase in
          switch phase {
          case .success(let image):
            image
              .resizable()
              .scaledToFill()
          default:
            accountAvatarPlaceholder(hasRemotePhoto: true)
          }
        }
      } else {
        accountAvatarPlaceholder(hasRemotePhoto: false)
      }
    }
    .clipShape(Circle())
    .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1))
  }

  private func accountAvatarPlaceholder(hasRemotePhoto: Bool) -> some View {
    ZStack {
      Circle()
        .fill(
          LinearGradient(
            colors: [Color.purple.opacity(0.75), Color.blue.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
      if let emoji = authService.resolvedAvatarEmoji {
        Text(emoji)
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(.white.opacity(0.9))
      } else if hasRemotePhoto {
        Image(systemName: "person.crop.circle.fill")
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(.white.opacity(0.85))
      } else {
        Text(authService.resolvedAvatarFallback)
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(.white.opacity(0.9))
      }
    }
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
