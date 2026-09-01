import SwiftUI

/// 时间轴照片全屏预览（B7 / 线框 05）：黑色底、左右滑动切图、点关闭按钮关闭。
struct PhotoPreviewView: View {
    let urls: [String]
    let initialIndex: Int

    @Environment(\.dismiss) private var dismiss
    @State private var selection: Int

    init(urls: [String], initialIndex: Int) {
        self.urls = urls
        self.initialIndex = initialIndex
        _selection = State(initialValue: initialIndex)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            TabView(selection: $selection) {
                ForEach(Array(urls.enumerated()), id: \.offset) { index, path in
                    AsyncImage(url: APIClient.shared.imageURL(for: path)) { phase in
                        if case .success(let image) = phase {
                            image
                                .resizable()
                                .scaledToFit()
                        } else {
                            ProgressView()
                                .tint(.white)
                        }
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))

            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    .padding()
                }
                Spacer()
            }
        }
        .statusBarHidden()
    }
}
