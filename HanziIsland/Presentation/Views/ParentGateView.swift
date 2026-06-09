import SwiftUI

/// 简单算术题，防止小朋友误进家长区
struct ParentGateView: View {
    let onUnlock: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var answer = ""
    @State private var showWrong = false

    @State private var left: Int
    @State private var right: Int

    init(onUnlock: @escaping () -> Void) {
        self.onUnlock = onUnlock
        _left = State(initialValue: Int.random(in: 3...9))
        _right = State(initialValue: Int.random(in: 2...8))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("家长验证")
                    .font(.title2.bold())
                Text("请输入答案（仅家长操作）")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("\(left) + \(right) = ?")
                    .font(.system(size: 48, weight: .bold, design: .rounded))

                TextField("答案", text: $answer)
                    .keyboardType(.numberPad)
                    .font(.title)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                    .frame(maxWidth: 200)

                if showWrong {
                    Text("答案不对，请再试一次")
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Button("进入家长中心") {
                    verify()
                }
                .buttonStyle(.borderedProminent)
                .disabled(answer.isEmpty)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func verify() {
        if Int(answer) == left + right {
            onUnlock()
        } else {
            showWrong = true
            answer = ""
        }
    }
}
