import SwiftUI

/// Dev Login（线框 01 · 契约 3.1）：手机号一步进入；M1 无短信验证。
struct LoginView: View {
    let session: SessionStore

    @State private var phone = ""
    @State private var submitting = false
    @State private var errorText: String?
    @FocusState private var phoneFocused: Bool

    private var canSubmit: Bool {
        phone.count == 11 && phone.allSatisfy(\.isNumber) && !submitting
    }

    var body: some View {
        VStack(spacing: CGFloat.PanJi.spaceXL) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.PanJi.accent)
                    .frame(width: 88, height: 88)
                Text("盘")
                    .font(Font.PanJi.display)
                    .foregroundStyle(Color.PanJi.onAccent)
            }

            VStack(spacing: CGFloat.PanJi.spaceS) {
                Text("盘迹")
                    .font(Font.PanJi.display)
                    .foregroundStyle(Color.PanJi.textPrimary)
                Text("记录每一次盘玩")
                    .font(Font.PanJi.secondary)
                    .foregroundStyle(Color.PanJi.textSecondary)
            }

            PanJiTextField(placeholder: "手机号", text: $phone,
                           keyboardType: .numberPad, isFocused: $phoneFocused)
                .onChange(of: phone) { _, newValue in
                    let filtered = String(newValue.filter(\.isNumber).prefix(11))
                    if filtered != newValue { phone = filtered }
                }
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("完成") { phoneFocused = false }
                    }
                }

            VStack(spacing: CGFloat.PanJi.spaceS) {
                if let errorText {
                    Text(errorText)
                        .font(Font.PanJi.caption)
                        .foregroundStyle(Color.PanJi.danger)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                Button {
                    submit()
                } label: {
                    if submitting {
                        HStack(spacing: CGFloat.PanJi.spaceS) {
                            ProgressView().tint(Color.PanJi.onAccent)
                            Text("进入中…")
                        }
                    } else {
                        Text("进入盘迹")
                    }
                }
                .buttonStyle(PanJiPrimaryButtonStyle())
                .disabled(!canSubmit)
            }

            Text("M1 开发版：输入任意手机号即可，不发验证码")
                .font(Font.PanJi.caption)
                .foregroundStyle(Color.PanJi.textTertiary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(.horizontal, CGFloat.PanJi.spaceL)
        .onAppear {
            if phone.isEmpty { phone = session.lastPhone }
        }
    }

    private func submit() {
        guard canSubmit else { return }
        phoneFocused = false
        submitting = true
        errorText = nil
        Task { @MainActor in
            defer { submitting = false }
            do {
                try await session.login(phone: phone)
            } catch APIError.authRequired {
                session.signOut()
            } catch {
                errorText = (error as? APIError)?.userMessage ?? "出了点问题，请稍后再试"
            }
        }
    }
}
