import SwiftUI

/// 儿童向大按钮样式
struct KidPrimaryButtonStyle: ButtonStyle {
    var color: Color = Color("AccentGreen")

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 24, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 22)
            .background(color.opacity(configuration.isPressed ? 0.75 : 1), in: RoundedRectangle(cornerRadius: 24))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// 紧贴文字/句子旁的听音按钮（认识新字、拆解区等共用）
struct KidInlineAudioButton: View {
    var label: String? = nil
    var iconSize: CGFloat = 28
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("🔊")
                    .font(.system(size: iconSize))
                if let label {
                    Text(label)
                        .font(.caption.bold())
                }
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(.teal)
        .accessibilityLabel(label ?? "播放语音")
    }
}

struct KidOptionButton: View {
    let text: String
    let fontSize: CGFloat
    let background: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: fontSize, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(uiColor: .label))
                .frame(maxWidth: .infinity, minHeight: 72)
                .padding(.horizontal, 8)
                .background(background, in: RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }
}
