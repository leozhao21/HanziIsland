import SwiftUI

/// 家长专用：任务设置、应用设置、数据统计
struct ParentHubView: View {
    @Bindable var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var tab = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $tab) {
                    Text("任务").tag(0)
                    Text("设置").tag(1)
                    Text("数据").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()

                switch tab {
                case 0:
                    ParentTodaySettingsView(viewModel: viewModel)
                case 1:
                    SettingsView()
                default:
                    ParentCenterView(viewModel: viewModel)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("家长中心")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}

/// 今日学习任务（家长向）
struct ParentTodaySettingsView: View {
    @Bindable var viewModel: AppViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                DailyGoalCard(viewModel: viewModel)
                modePicker

                if let plan = viewModel.dailyPlan {
                    taskSection(title: "新字 · \(plan.newCharacters.count)", chars: plan.newCharacters, color: .blue)
                    taskSection(title: "复习 · \(plan.reviewCharacters.count)", chars: plan.reviewCharacters, color: .orange)
                    taskSection(title: "随机检查 · \(plan.randomCheckCharacters.count)", chars: plan.randomCheckCharacters, color: .purple)
                }
            }
            .padding()
        }
    }

    private var modePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("学习模式")
                .font(.headline)
            Picker("模式", selection: Binding(
                get: { viewModel.studyMode },
                set: { viewModel.updateStudyMode($0) }
            )) {
                ForEach(StudyMode.allCases) { mode in
                    Text("\(mode.displayName)（\(mode.newCharactersPerDay)新字）").tag(mode)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private func taskSection(title: String, chars: [HanziCharacter], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(color)
            if chars.isEmpty {
                Text("暂无")
                    .foregroundStyle(.secondary)
            } else {
                FlowLayout(chars: chars.map(\.character))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }
}
