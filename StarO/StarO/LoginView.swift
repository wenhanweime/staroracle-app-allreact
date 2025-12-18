import SwiftUI

struct LoginView: View {
  enum Mode: String, CaseIterable {
    case signIn = "登录"
    case signUp = "注册"
  }

  @EnvironmentObject private var authService: AuthService

  @State private var mode: Mode = .signIn
  @State private var email: String = ""
  @State private var password: String = ""

  private var canSubmit: Bool {
    !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
    !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  private var projectHint: String? {
    guard SupabaseRuntime.loadProjectConfig() == nil else { return nil }
    return "未配置 SUPABASE_URL / SUPABASE_ANON_KEY。\n可运行：bash scripts/sync_supabase_config.sh ../staroracle-backend/.env.remote"
  }

  var body: some View {
    ZStack {
      LinearGradient(
        colors: [
          Color(red: 9/255, green: 12/255, blue: 20/255),
          Color(red: 12/255, green: 18/255, blue: 32/255)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .ignoresSafeArea()

      VStack(spacing: 18) {
        VStack(spacing: 6) {
          Text("星谕")
            .font(.system(size: 28, weight: .semibold, design: .serif))
            .foregroundStyle(.white)
          Text("登录以连接云端对话与星卡")
            .font(.footnote)
            .foregroundStyle(.white.opacity(0.7))
        }
        .padding(.top, 20)

        if let hint = projectHint {
          Text(hint)
            .font(.footnote)
            .foregroundStyle(.yellow.opacity(0.9))
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
              RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
        }

        Picker("Mode", selection: $mode) {
          ForEach(Mode.allCases, id: \.self) { mode in
            Text(mode.rawValue).tag(mode)
          }
        }
        .pickerStyle(.segmented)

        VStack(spacing: 12) {
          TextField("邮箱", text: $email)
            .textInputAutocapitalization(.never)
            .keyboardType(.emailAddress)
            .submitLabel(.next)
            .padding(14)
            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
            .overlay(
              RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )

          SecureField("密码", text: $password)
            .textInputAutocapitalization(.never)
            .submitLabel(.go)
            .padding(14)
            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
            .overlay(
              RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
        }

        Button {
          Task {
            switch mode {
            case .signIn:
              await authService.signIn(email: email, password: password)
            case .signUp:
              await authService.signUp(email: email, password: password)
            }
          }
        } label: {
          HStack(spacing: 10) {
            if authService.isLoading {
              ProgressView()
                .tint(.white)
            } else {
              Image(systemName: mode == .signIn ? "arrow.right.circle.fill" : "person.badge.plus")
            }
            Text(mode.rawValue)
              .font(.footnote.weight(.semibold))
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, 14)
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
        .disabled(!canSubmit || authService.isLoading)

        if let error = authService.errorMessage, !error.isEmpty {
          Text(error)
            .font(.footnote)
            .foregroundStyle(.red.opacity(0.95))
            .frame(maxWidth: .infinity, alignment: .leading)
        }

        Spacer()
      }
      .padding(.horizontal, 24)
      .padding(.bottom, 40)
      .frame(maxWidth: 520)
    }
    .task {
      await authService.restoreSessionIfNeeded()
    }
  }
}

