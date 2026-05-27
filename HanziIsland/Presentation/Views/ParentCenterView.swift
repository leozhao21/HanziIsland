import SwiftUI
import Charts

struct ParentCenterView: View {
    @Bindable var viewModel: AppViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                let stats = viewModel.parentDashboard
                let trend = viewModel.studyTrend
                VStack(alignment: .leading, spacing: 20) {
                    statsGrid(stats)
                    dailyVolumeChart(trend.dailyVolume)
                    masteredGrowthChart(trend.masteredGrowth)
                    forgettingChart(trend.forgettingTrend)
                    weeklyReport(stats)
                    intensiveList
                }
                .padding()
            }
            .navigationTitle("家长中心")
            .onAppear { viewModel.reloadStudyTrend() }
        }
    }

    private func statsGrid(_ stats: ParentDashboardStats) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            statCard("累计学习", "\(stats.totalLearned) 字", .blue)
            statCard("真正掌握", "\(stats.trulyMastered) 字", .green)
            statCard("复习中", "\(stats.inReview) 字", .orange)
            statCard("容易遗忘", "\(stats.easyToForget) 字", .red)
        }
    }

    private func statCard(_ title: String, _ value: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }

    private func dailyVolumeChart(_ data: [DailyStudySnapshot]) -> some View {
        chartCard(title: "每日学习量", subtitle: "答题次数 / 接触汉字数") {
            Chart(data) { point in
                BarMark(
                    x: .value("日期", point.dayStart, unit: .day),
                    y: .value("答题", point.questionsAnswered)
                )
                .foregroundStyle(.blue.opacity(0.7))
                LineMark(
                    x: .value("日期", point.dayStart, unit: .day),
                    y: .value("识字", point.charactersStudied)
                )
                .foregroundStyle(.orange)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 2)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month().day(), centered: true)
                }
            }
            .frame(height: 160)
        }
    }

    private func masteredGrowthChart(_ data: [DailyStudySnapshot]) -> some View {
        chartCard(title: "掌握增长曲线", subtitle: "累计完全掌握字数") {
            Chart(data) { point in
                LineMark(
                    x: .value("日期", point.dayStart, unit: .day),
                    y: .value("掌握", point.cumulativeMastered)
                )
                .foregroundStyle(.green)
                AreaMark(
                    x: .value("日期", point.dayStart, unit: .day),
                    y: .value("掌握", point.cumulativeMastered)
                )
                .foregroundStyle(.green.opacity(0.15))
            }
            .frame(height: 160)
        }
    }

    private func forgettingChart(_ data: [DailyStudySnapshot]) -> some View {
        chartCard(title: "遗忘率变化", subtitle: "当日在学汉字平均遗忘率") {
            Chart(data) { point in
                LineMark(
                    x: .value("日期", point.dayStart, unit: .day),
                    y: .value("遗忘率", point.averageForgettingRate * 100)
                )
                .foregroundStyle(.orange)
            }
            .chartYScale(domain: 0...100)
            .chartYAxisLabel("%")
            .frame(height: 140)
        }
    }

    private func chartCard<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
            content()
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
    }

    private func weeklyReport(_ stats: ParentDashboardStats) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("本周报告")
                .font(.headline)
            Text("本周新增掌握")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if stats.weeklyNewMastered.isEmpty {
                Text("暂无新掌握汉字")
                    .foregroundStyle(.secondary)
            } else {
                HStack {
                    ForEach(stats.weeklyNewMastered) { char in
                        Text(char.character)
                            .font(.title2)
                            .frame(width: 40, height: 40)
                            .background(.green.opacity(0.15), in: Circle())
                    }
                }
            }
            Text("共增加：\(stats.weeklyMasteredCount) 个汉字")
                .font(.headline)
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
    }

    private var intensiveList: some View {
        let intensive = viewModel.progressMap.values
            .filter { $0.inIntensiveReview }
            .sorted { $0.memory.forgettingRate > $1.memory.forgettingRate }

        return VStack(alignment: .leading, spacing: 8) {
            Text("重点复习库")
                .font(.headline)
            if intensive.isEmpty {
                Text("暂无 — 继续保持！")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(intensive) { item in
                    HStack {
                        Text(item.character.character)
                            .font(.title2)
                        Text(item.character.sentence)
                            .font(.caption)
                            .lineLimit(1)
                        Spacer()
                        Text(String(format: "遗忘率 %.0f%%", item.memory.forgettingRate * 100))
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }
            }
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
    }
}
