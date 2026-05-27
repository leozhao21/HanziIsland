import SwiftUI

struct QuizSessionView: View {
    @Bindable var viewModel: AppViewModel
    @State var session: LearnSession
    let onFinish: () -> Void

    @State private var phase: Phase = .learn
    @State private var questionIndex = 0
    @State private var selectedIndex: Int?
    @State private var showResult = false
    @State private var lastCorrect = false

    enum Phase {
        case learn
        case quiz
        case done
    }

    var body: some View {
        VStack(spacing: 20) {
            switch phase {
            case .learn:
                learnPhase
            case .quiz:
                quizPhase
            case .done:
                donePhase
            }
        }
        .padding()
        .navigationBarBackButtonHidden(phase != .done)
        .toolbar {
            if phase != .done {
                ToolbarItem(placement: .cancellationAction) {
                    Button("退出") {
                        Task { await viewModel.endStudySession() }
                        onFinish()
                    }
                }
            }
        }
    }

    private var learnPhase: some View {
        Group {
            if session.currentLearnIndex < session.learnCharacters.count {
                let char = session.learnCharacters[session.currentLearnIndex]
                let mastery = viewModel.mastery(for: char.id)
                CharacterLearnCard(character: char, mastery: mastery)
                Button("记住了，继续") {
                    if session.currentLearnIndex + 1 < session.learnCharacters.count {
                        session.currentLearnIndex += 1
                    } else {
                        phase = .quiz
                    }
                }
                .buttonStyle(.borderedProminent)
            } else {
                Color.clear.onAppear { phase = .quiz }
            }
        }
    }

    private var quizPhase: some View {
        Group {
            if questionIndex < session.questions.count {
                let q = session.questions[questionIndex]
                VStack(spacing: 16) {
                    Text(q.type.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if q.type == .pinyin || q.type == .recognize {
                        Text(q.prompt)
                            .font(.system(size: 64))
                    } else {
                        Text(q.prompt)
                            .font(.title2)
                            .multilineTextAlignment(.center)
                    }

                    if q.type == .image {
                        Image(systemName: "photo")
                            .font(.system(size: 80))
                            .foregroundStyle(.teal)
                            .symbolRenderingMode(.hierarchical)
                    }

                    ForEach(Array(q.options.enumerated()), id: \.offset) { index, option in
                        Button {
                            guard selectedIndex == nil else { return }
                            selectedIndex = index
                            lastCorrect = index == q.correctIndex
                            showResult = true
                            Task {
                                await viewModel.submitAnswer(
                                    for: q.target.id,
                                    correct: lastCorrect
                                )
                            }
                        } label: {
                            Text(option)
                                .font(.title2)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(optionBackground(index: index, correct: q.correctIndex))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(selectedIndex != nil)
                    }

                    if showResult {
                        Text(lastCorrect ? "太棒了！⭐" : "再想想，已加入重点复习")
                            .font(.headline)
                            .foregroundStyle(lastCorrect ? .green : .orange)
                        Button("下一题") { advanceQuestion() }
                            .buttonStyle(.borderedProminent)
                    }

                    ProgressView(value: Double(questionIndex + 1), total: Double(session.questions.count))
                }
            } else {
                Color.clear.onAppear { phase = .done }
            }
        }
    }

    private func optionBackground(index: Int, correct: Int) -> Color {
        guard let selectedIndex, showResult else {
            return Color(.secondarySystemBackground)
        }
        if index == correct { return .green.opacity(0.3) }
        if index == selectedIndex { return .red.opacity(0.3) }
        return Color(.secondarySystemBackground)
    }

    private func advanceQuestion() {
        questionIndex += 1
        selectedIndex = nil
        showResult = false
        if questionIndex >= session.questions.count {
            phase = .done
        }
    }

    private var donePhase: some View {
        VStack(spacing: 16) {
            Text("🎉")
                .font(.system(size: 72))
            Text("今日学习完成！")
                .font(.title.bold())
            Text("获得星星 +\(session.questions.filter { _ in true }.count) 机会")
                .foregroundStyle(.secondary)
            Button("返回") {
                Task { await viewModel.endStudySession() }
                onFinish()
            }
            .buttonStyle(.borderedProminent)
        }
    }
}
