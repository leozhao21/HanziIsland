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
    @State private var showExitConfirm = false
    enum Phase {
        case learn
        case quiz
        case done
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color("AccentGreen").opacity(0.12), Color(.systemBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

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
            .padding(20)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            if phase != .done {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showExitConfirm = true
                    } label: {
                        Text("🏠")
                            .font(.title2)
                    }
                }
                ToolbarItem(placement: .principal) {
                    phaseTitle
                }
            }
        }
        .confirmationDialog("要休息一下吗？", isPresented: $showExitConfirm) {
            Button("继续学", role: .cancel) {}
            Button("先休息", role: .destructive) {
                SpeechService.shared.stop()
                Task { await viewModel.endStudySession() }
                onFinish()
            }
        }
        .onDisappear {
            SpeechService.shared.stop()
        }
    }

    @ViewBuilder
    private var phaseTitle: some View {
        switch phase {
        case .learn:
            Text("认识新字")
                .font(.headline.bold())
        case .quiz:
            Text("第 \(questionIndex + 1) / \(session.questions.count) 题")
                .font(.headline.bold())
        case .done:
            EmptyView()
        }
    }

    private var learnPhase: some View {
        Group {
            if session.currentLearnIndex < session.learnCharacters.count {
                let char = session.learnCharacters[session.currentLearnIndex]
                let mastery = viewModel.mastery(for: char.id)
                ScrollView {
                    VStack(spacing: 20) {
                        CharacterLearnCard(character: char, mastery: mastery)
                    }
                }

                Button {
                    SpeechService.shared.stop()
                    Task {
                        await viewModel.markCharacterIntroduced(characterId: char.id)
                        if session.currentLearnIndex + 1 < session.learnCharacters.count {
                            session.currentLearnIndex += 1
                        } else {
                            phase = .quiz
                            // 进入答题后由首题 onAppear 播放听音，避免与题目语音互相打断
                        }
                    }
                } label: {
                    Label("我学会啦！", systemImage: "hand.thumbsup.fill")
                }
                .buttonStyle(KidPrimaryButtonStyle())
            } else {
                Color.clear.onAppear { phase = .quiz }
            }
        }
    }

    private var quizPhase: some View {
        Group {
            if questionIndex < session.questions.count {
                let q = session.questions[questionIndex]
                VStack(spacing: 20) {
                    quizPrompt(for: q)

                    VStack(spacing: 14) {
                        ForEach(Array(q.options.enumerated()), id: \.offset) { index, option in
                            KidOptionButton(
                                text: option,
                                fontSize: optionFontSize(for: q),
                                background: optionBackground(index: index, correct: q.correctIndex)
                            ) {
                                guard selectedIndex == nil else { return }
                                selectedIndex = index
                                lastCorrect = index == q.correctIndex
                                showResult = true
                                if lastCorrect {
                                    SpeechService.shared.speak("太棒了！")
                                } else {
                                    SpeechService.shared.speak("没关系，再试一次。")
                                }
                                Task {
                                    await viewModel.submitAnswer(
                                        for: q.target.id,
                                        correct: lastCorrect
                                    )
                                }
                            }
                            .disabled(selectedIndex != nil)
                        }
                    }

                    if showResult {
                        Text(lastCorrect ? "🌟 太棒了！" : "💪 下次一定行！")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                        Button {
                            SpeechService.shared.stop()
                            advanceQuestion()
                        } label: {
                            Text("继续 👉")
                        }
                        .buttonStyle(KidPrimaryButtonStyle(color: .orange))
                    }
                }
                .task(id: q.id) {
                    playQuizAudio(for: q)
                }
            } else {
                Color.clear.onAppear { phase = .done }
            }
        }
    }

    private func optionFontSize(for question: QuizQuestion) -> CGFloat {
        switch question.type {
        case .listenPick, .recognize: 44
        case .sentenceFill: 36
        }
    }

    @ViewBuilder
    private func quizPrompt(for question: QuizQuestion) -> some View {
        switch question.type {
        case .listenPick, .recognize:
            listenPickPrompt(for: question)
        case .sentenceFill:
            HStack(alignment: .center, spacing: 10) {
                Text(question.prompt)
                    .font(.system(size: 28, weight: .medium, design: .rounded))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                KidInlineAudioButton(iconSize: 30) {
                    SpeechService.shared.speakSentence(question.target)
                }
                .accessibilityLabel("听例句")
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
        }
    }

    private func listenPickPrompt(for question: QuizQuestion) -> some View {
        VStack(spacing: 16) {
            Text("👂 听一听，选出你听到的字")
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            KidInlineAudioButton(label: "再听一遍", iconSize: 36) {
                SpeechService.shared.speakCharacter(question.target)
            }
        }
    }

    private func playQuizAudio(for question: QuizQuestion) {
        switch question.type {
        case .listenPick, .recognize:
            SpeechService.shared.speakQuizListenChallenge(for: question.target)
        case .sentenceFill:
            SpeechService.shared.speakQuizSentence(question.target)
        }
    }

    private func optionBackground(index: Int, correct: Int) -> Color {
        let base = Color(.secondarySystemGroupedBackground)
        guard let selectedIndex, showResult else {
            return base
        }
        if index == correct { return .green.opacity(0.35) }
        if index == selectedIndex { return .red.opacity(0.3) }
        return base.opacity(0.55)
    }

    private func advanceQuestion() {
        questionIndex += 1
        selectedIndex = nil
        showResult = false
        if questionIndex >= session.questions.count {
            phase = .done
            SpeechService.shared.speak("太厉害了！今天的学习完成啦！")
        }
    }

    private var donePhase: some View {
        VStack(spacing: 24) {
            Text("🎉")
                .font(.system(size: 100))
            Text("太厉害啦！")
                .font(.system(size: 36, weight: .bold, design: .rounded))
            Text("⭐ +\(session.questions.count)")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(.orange)

            Button {
                Task { await viewModel.endStudySession() }
                onFinish()
            } label: {
                Text("回岛上看星星 🏝️")
            }
            .buttonStyle(KidPrimaryButtonStyle())
        }
        .padding(.top, 40)
    }
}
