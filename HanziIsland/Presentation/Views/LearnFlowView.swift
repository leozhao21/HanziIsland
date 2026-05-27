import SwiftUI

struct LearnFlowView: View {
    @Bindable var viewModel: AppViewModel
    @State private var session: LearnSession?

    var body: some View {
        NavigationStack {
            Group {
                if let session {
                    QuizSessionView(viewModel: viewModel, session: session) {
                        self.session = nil
                    }
                } else {
                    dailyTaskContent
                }
            }
            .navigationTitle("今日任务")
            .onAppear { viewModel.reloadTodayProgress() }
        }
    }

    private var dailyTaskContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                DailyGoalCard(viewModel: viewModel)
                modePicker

                if let plan = viewModel.dailyPlan {
                    taskSection(title: "新字 · \(plan.newCharacters.count)", chars: plan.newCharacters, color: .blue)
                    taskSection(title: "复习 · \(plan.reviewCharacters.count)", chars: plan.reviewCharacters, color: .orange)
                    taskSection(title: "随机检查 · \(plan.randomCheckCharacters.count)", chars: plan.randomCheckCharacters, color: .purple)

                    Button("开始学习") {
                        let all = plan.newCharacters + plan.reviewCharacters + plan.randomCheckCharacters
                        let questions = viewModel.makeQuizSession(characters: all, count: min(all.count, 10))
                        viewModel.beginStudySession(characterIds: all.map(\.id))
                        session = LearnSession(questions: questions, learnCharacters: plan.newCharacters)
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                } else {
                    ProgressView("正在生成今日任务…")
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

struct LearnSession {
    var questions: [QuizQuestion]
    var learnCharacters: [HanziCharacter]
    var currentLearnIndex: Int = 0
}

/// 网格展示今日任务汉字
struct FlowLayout: View {
    let chars: [String]
    private let columns = [GridItem(.adaptive(minimum: 44), spacing: 8)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(chars, id: \.self) { char in
                Text(char)
                    .font(.title2)
                    .frame(width: 44, height: 44)
                    .background(.background, in: Circle())
            }
        }
    }
}
