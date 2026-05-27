import SwiftUI

struct GrowthIslandView: View {
    @Bindable var viewModel: AppViewModel
    @State private var message: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    HStack {
                        Text("⭐")
                            .font(.largeTitle)
                        Text("\(viewModel.starCount) 颗星星")
                            .font(.title2.bold())
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(colors: [.yellow.opacity(0.3), .orange.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: RoundedRectangle(cornerRadius: 16)
                    )

                    Text("用星星解锁新岛屿")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    ForEach(IslandTheme.catalog) { island in
                        islandCard(island)
                    }

                    if let message {
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("成长岛")
        }
    }

    private func islandCard(_ island: IslandTheme) -> some View {
        let unlocked = viewModel.unlockedIslands.contains(island.id)
        return HStack {
            Text(island.emoji)
                .font(.system(size: 48))
            VStack(alignment: .leading) {
                Text(island.name)
                    .font(.headline)
                Text(unlocked ? "已解锁" : "需要 \(island.starCost) 星星")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if unlocked {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Button("解锁") {
                    Task {
                        let ok = await viewModel.unlockIsland(island)
                        message = ok ? "解锁成功：\(island.name)！" : "星星还不够哦"
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.starCount < island.starCost)
            }
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}
