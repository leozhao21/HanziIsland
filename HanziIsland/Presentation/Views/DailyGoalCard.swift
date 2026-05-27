import SwiftUI

/// 今日学习目标设定与进度
struct DailyGoalCard: View {
    @Bindable var viewModel: AppViewModel

    private var progress: TodayLearningProgress { viewModel.todayProgress }
    private var goal: DailyLearningGoal { viewModel.dailyLearningGoal }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            progressRing
            goalControls
            statsRow
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color("AccentGreen").opacity(0.12), Color.blue.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 16)
        )
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("今日学习目标")
                    .font(.headline)
                if goal.followStudyMode {
                    Text("已跟随学习模式（推荐 \(viewModel.recommendedDailyGoal) 字）")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("自定义目标")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if progress.isGoalMet {
                Label("已完成", systemImage: "checkmark.seal.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.green)
            }
        }
    }

    private var progressRing: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                Circle()
                    .trim(from: 0, to: progress.progress)
                    .stroke(
                        progress.isGoalMet ? Color.green : Color("AccentGreen"),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: progress.progress)
                VStack(spacing: 2) {
                    Text("\(progress.completedCount)")
                        .font(.title.bold())
                    Text("/ \(goal.targetCount)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 88, height: 88)

            VStack(alignment: .leading, spacing: 6) {
                if progress.isGoalMet {
                    Text("太棒了，今日目标达成！")
                        .font(.subheadline.bold())
                        .foregroundStyle(.green)
                } else {
                    Text("还差 \(progress.remaining) 个汉字")
                        .font(.subheadline.bold())
                }
                Text("已答题 \(progress.questionsAnswered) 道 · 正确 \(progress.correctCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if progress.newMasteredCount > 0 {
                    Text("新掌握 \(progress.newMasteredCount) 字")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
        }
    }

    private var goalControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("目标字数")
                .font(.subheadline.bold())

            HStack(spacing: 8) {
                ForEach(DailyLearningGoal.presets, id: \.value) { preset in
                    Button {
                        viewModel.updateDailyLearningGoal(targetCount: preset.value)
                    } label: {
                        Text("\(preset.label)\n\(preset.value)")
                            .font(.caption2)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                goal.targetCount == preset.value && !goal.followStudyMode
                                    ? Color("AccentGreen").opacity(0.25)
                                    : Color(.secondarySystemBackground),
                                in: RoundedRectangle(cornerRadius: 8)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack {
                Button {
                    adjustGoal(by: -DailyLearningGoal.step)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                }
                .disabled(goal.targetCount <= DailyLearningGoal.minCount)

                Text("\(goal.targetCount) 字")
                    .font(.title3.bold())
                    .frame(minWidth: 72)

                Button {
                    adjustGoal(by: DailyLearningGoal.step)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
                .disabled(goal.targetCount >= DailyLearningGoal.maxCount)
            }
            .frame(maxWidth: .infinity)

            Toggle("跟随学习模式", isOn: Binding(
                get: { goal.followStudyMode },
                set: { viewModel.setFollowStudyModeGoal($0) }
            ))
            .font(.subheadline)

            if !goal.followStudyMode {
                Button("使用模式推荐（\(viewModel.recommendedDailyGoal) 字）") {
                    viewModel.applyRecommendedDailyGoal()
                }
                .font(.caption)
            }
        }
    }

    private var statsRow: some View {
        let planTotal = viewModel.dailyPlan?.totalCount ?? viewModel.recommendedDailyGoal
        return HStack {
            Label("今日任务 \(planTotal) 字", systemImage: "list.bullet")
            Spacer()
            Label("目标 \(goal.targetCount) 字", systemImage: "flag.fill")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    private func adjustGoal(by delta: Int) {
        viewModel.updateDailyLearningGoal(targetCount: goal.targetCount + delta)
    }
}
