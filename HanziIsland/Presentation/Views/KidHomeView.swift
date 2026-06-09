import SwiftUI

/// 儿童主界面：大按钮、少文字、直达学习
struct KidHomeView: View {
    @Bindable var viewModel: AppViewModel
    @State private var session: LearnSession?
    @State private var showParentHub = false
    @State private var parentUnlocked = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ScrollView {
                VStack(spacing: 28) {
                    header
                    todayProgressCard
                    startButton
                    if !viewModel.intensiveReviewCharacters.isEmpty {
                        retryButton
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }

            parentEntryButton
                .padding(.trailing, 20)
                .padding(.top, 8)
        }
        .background(
            LinearGradient(
                colors: [
                    Color("AccentGreen").opacity(0.25),
                    Color.orange.opacity(0.12),
                    Color(.systemBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .fullScreenCover(item: $session) { active in
            NavigationStack {
                QuizSessionView(viewModel: viewModel, session: active) {
                    session = nil
                    viewModel.reloadTodayProgress()
                }
            }
        }
        .sheet(isPresented: $showParentHub) {
            if parentUnlocked {
                ParentHubView(viewModel: viewModel)
            } else {
                ParentGateView { parentUnlocked = true }
            }
        }
        .onAppear {
            viewModel.reloadTodayProgress()
            SpeechService.shared.speak(
                "你好！欢迎来到识字岛。点下面的大按钮，开始学汉字吧！"
            )
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            Text("🏝️")
                .font(.system(size: 72))
            Text("识字岛")
                .font(.system(size: 40, weight: .bold, design: .rounded))
            HStack(spacing: 8) {
                Text("⭐")
                    .font(.title)
                Text("\(viewModel.starCount)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.orange)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 24)
    }

    private var todayProgressCard: some View {
        let progress = viewModel.todayProgress
        return VStack(spacing: 12) {
            if progress.isGoalMet {
                Text("🎉 今天太棒啦！")
                    .font(.title2.bold())
            } else {
                Text("今天已学 \(progress.completedCount) 个字")
                    .font(.title3.bold())
            }
            ProgressView(value: progress.progress)
                .tint(Color("AccentGreen"))
                .scaleEffect(x: 1, y: 2.5, anchor: .center)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 24))
    }

    private var startButton: some View {
        Button {
            SpeechService.shared.stop()
            session = viewModel.makeDailyLearnSession()
        } label: {
            HStack(spacing: 12) {
                Text("🚀")
                    .font(.system(size: 36))
                Text("开始学汉字")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
            .background(
                LinearGradient(
                    colors: [Color("AccentGreen"), Color.green],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: RoundedRectangle(cornerRadius: 28)
            )
            .shadow(color: Color("AccentGreen").opacity(0.35), radius: 12, y: 6)
        }
        .disabled(viewModel.dailyPlan == nil || (viewModel.dailyPlan?.totalCount ?? 0) == 0)
    }

    private var retryButton: some View {
        Button {
            SpeechService.shared.stop()
            session = viewModel.makeIntensiveReviewSession()
        } label: {
            HStack(spacing: 10) {
                Text("💪")
                    .font(.title)
                Text("再练一遍错题")
                    .font(.title3.bold())
            }
            .foregroundStyle(.orange)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color.orange.opacity(0.15), in: RoundedRectangle(cornerRadius: 24))
        }
    }

    private var parentEntryButton: some View {
        Button {
            parentUnlocked = false
            showParentHub = true
        } label: {
            Image(systemName: "person.crop.circle")
                .font(.title3)
                .foregroundStyle(.secondary.opacity(0.6))
                .padding(12)
        }
        .accessibilityLabel("家长入口")
    }
}
