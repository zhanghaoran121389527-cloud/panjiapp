import SwiftUI

/// M0 占位首页：验证工程可运行、主题 token 生效、baseURL 注入成功。
/// T-106 起由登录流程替换，本页届时删除。
struct RootView: View {
    var body: some View {
        ZStack {
            Color.PanJi.background
                .ignoresSafeArea()

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.PanJi.accent)
                        .frame(width: 88, height: 88)
                    Text("盘")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundStyle(Color.PanJi.background)
                }

                Text("盘迹")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(Color.PanJi.textPrimary)

                Text("M0 工程底座 · 占位首页")
                    .font(.subheadline)
                    .foregroundStyle(Color.PanJi.textSecondary)

                Text("API: \(AppConfig.apiBaseURL)")
                    .font(.footnote)
                    .foregroundStyle(Color.PanJi.textSecondary)
                    .padding(.top, 40)
            }
        }
    }
}

#Preview {
    RootView()
}
