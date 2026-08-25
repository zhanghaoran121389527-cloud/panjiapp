import SwiftUI

/// 首次资料：昵称（线框 02 · 契约 3.3）；1~20 字，不可跳过（裁决 B5）。
struct NicknameView: View {
    let session: SessionStore

    @State private var nickname = ""
    @State private var submitting = false
    @State private var errorText: String?
    @FocusState private var nicknameFocused: Bool

    private var trimmed: String {
        nickname.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSubmit: Bool { !trimmed.isEmpty && !submitting }

    var body: some View {
        VStack(spacing: CGFloat.PanJi.spaceXL) {
            Spacer()

            Text("给自己起个名字")
                .font(Font.PanJi.itemTitle)
                .foregroundStyle(Color.PanJi.textPrimary)

            PanJiTextField(placeholder: "昵称（1~20 字）", text: $nickname, isFocused: $nicknameFocused)
                .onChange(of: nickname) { _, newValue in
                    if newValue.count > 20 { nickname = String(newValue.prefix(20)) }
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
                            Text("保存中…")
                        }
                    } else {
                        Text("开始盘玩")
                    }
                }
                .buttonStyle(PanJiPrimaryButtonStyle())
                .disabled(!canSubmit)
            }

            Text("以后可在设置中修改")
                .font(Font.PanJi.caption)
                .foregroundStyle(Color.PanJi.textTertiary)

            Spacer()
        }
        .padding(.horizontal, CGFloat.PanJi.spaceL)
        .onAppear { nicknameFocused = true }
        .onSubmit { submit() }
    }

    private func submit() {
        guard canSubmit else { return }
        submitting = true
        errorText = nil
        Task { @MainActor in
            defer { submitting = false }
            do {
                try await session.saveNickname(trimmed)
            } catch APIError.authRequired {
                session.signOut()
            } catch {
                errorText = (error as? APIError)?.userMessage ?? "出了点问题，请稍后再试"
            }
        }
    }
}
