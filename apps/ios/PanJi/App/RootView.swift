import SwiftUI

/// App 壳根视图：M1-006 起由登录流程（AuthRootView）接管（M0-003 占位页退役）。
struct RootView: View {
    var body: some View {
        AuthRootView()
    }
}

#Preview {
    RootView()
}
