import SwiftUI

struct GrowthIslandView: View {
    @Bindable var viewModel: AppViewModel
    @State private var message: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                HStack(spacing: 12) {
                    Text("⭐")
                        .font(.system(size: 48))
                    Text("\(viewModel.starCount)")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundStyle(.orange)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(
                    LinearGradient(
                        colors: [.yellow.opacity(0.35), .orange.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 28)
                )

                Text("用星星解锁新岛屿 🏝️")
                    .font(.title3.bold())

                ForEach(IslandTheme.catalog) { island in
                    islandCard(island)
                }

                if let message {
                    Text(message)
                        .font(.title3.bold())
                        .foregroundStyle(.orange)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(20)
        }
        .background(
            LinearGradient(
                colors: [Color.orange.opacity(0.1), Color(.systemBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .onAppear {
            SpeechService.shared.speak("这里是星星岛！攒够星星就能解锁新岛屿。")
        }
    }

    private func islandCard(_ island: IslandTheme) -> some View {
        let unlocked = viewModel.unlockedIslands.contains(island.id)
        return HStack(spacing: 16) {
            Text(island.emoji)
                .font(.system(size: 56))
            VStack(alignment: .leading, spacing: 4) {
                Text(island.name)
                    .font(.title2.bold())
                Text(unlocked ? "✅ 已解锁" : "需要 ⭐\(island.starCost)")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if unlocked {
                Text("🎉")
                    .font(.largeTitle)
            } else {
                Button {
                    Task {
                        let ok = await viewModel.unlockIsland(island)
                        if ok {
                            message = "解锁成功：\(island.name)！"
                            SpeechService.shared.speak("太棒了！解锁了\(island.name)！")
                        } else {
                            message = "星星还不够哦，继续学习吧！"
                            SpeechService.shared.speak("星星还不够哦，继续学习吧！")
                        }
                    }
                } label: {
                    Text("解锁")
                        .font(.headline.bold())
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                }
                .buttonStyle(KidPrimaryButtonStyle(color: .orange))
                .disabled(viewModel.starCount < island.starCost)
            }
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 24))
    }
}
