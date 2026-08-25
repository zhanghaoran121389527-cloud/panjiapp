import SwiftUI

/// 登录流程根：启动恢复 → 登录 / 昵称 / 收藏柜占位。
/// 用根视图阶段切换而非导航压栈：完成后无导航栈残留，昵称页不可回退（线框 02）。
@MainActor
struct AuthRootView: View {
    @State private var session = SessionStore()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.PanJi.background.ignoresSafeArea()
                switch session.phase {
                case .restoring:
                    ProgressView()
                        .tint(Color.PanJi.accent)
                case .restoreFailed:
                    RestoreFailedView { Task { await session.restore() } }
                case .needLogin:
                    LoginView(session: session)
                case .needNickname:
                    NicknameView(session: session)
                case .signedIn:
                    CabinetView(session: session)
                }
            }
        }
        .task { await session.restore() }
    }
}

/// 启动恢复失败的整页错误态（08-states A：圆底图标 + 标题 + 说明 + 重试）
private struct RestoreFailedView: View {
    let retry: () -> Void

    var body: some View {
        VStack(spacing: CGFloat.PanJi.spaceM) {
            ZStack {
                Circle()
                    .fill(Color.PanJi.accentSoft)
                    .frame(width: 96, height: 96)
                Image(systemName: "wifi.slash")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.PanJi.accent)
            }
            Text("网络不太顺畅")
                .font(Font.PanJi.heading)
                .foregroundStyle(Color.PanJi.textPrimary)
            Text("请检查网络后重试")
                .font(Font.PanJi.secondary)
                .foregroundStyle(Color.PanJi.textSecondary)
            Button("重试", action: retry)
                .buttonStyle(PanJiPrimaryButtonStyle())
                .frame(width: 240)
                .padding(.top, CGFloat.PanJi.spaceS)
        }
    }
}

#Preview {
    AuthRootView()
}
