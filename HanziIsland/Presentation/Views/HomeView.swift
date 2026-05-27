import SwiftUI

struct HomeView: View {
    @Bindable var viewModel: AppViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    badgesSection
                    levelOverview
                }
                .padding()
            }
            .navigationTitle("识字岛")
            .background(Color(.systemGroupedBackground))
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("长期掌握汉字")
                .font(.title2.bold())
            Text("认识 → 理解 → 使用 → 记住")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack {
                Label("\(viewModel.starCount) 星星", systemImage: "star.fill")
                    .foregroundStyle(.yellow)
                Spacer()
                Text("已掌握 \(viewModel.masteredCount) 字")
                    .font(.headline)
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }

    private var badgesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("成就徽章")
                .font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(MasteryBadge.all) { badge in
                        let earned = viewModel.masteredCount >= badge.threshold
                        VStack(spacing: 4) {
                            Text(badge.emoji)
                                .font(.largeTitle)
                                .opacity(earned ? 1 : 0.3)
                            Text(badge.title)
                                .font(.caption)
                            Text("\(badge.threshold)字")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: 88)
                        .padding(8)
                        .background(earned ? Color.green.opacity(0.15) : Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
    }

    private var levelOverview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("字库分级")
                .font(.headline)
            ForEach(1...4, id: \.self) { level in
                let count = viewModel.catalog.filter { $0.level == level }.count
                let mastered = viewModel.catalog.filter {
                    $0.level == level && viewModel.mastery(for: $0.id) >= .mastered
                }.count
                HStack {
                    Text("Level \(level)")
                    Spacer()
                    Text("\(mastered)/\(count)")
                        .foregroundStyle(.secondary)
                }
                ProgressView(value: Double(mastered), total: Double(max(count, 1)))
            }
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
    }
}
