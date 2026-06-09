import SwiftUI

enum LearnedListFilter: String, CaseIterable, Identifiable {
    case all
    case mastered
    case inProgress
    case intensive

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "全部"
        case .mastered: return "学会的"
        case .inProgress: return "还在练"
        case .intensive: return "要多练"
        }
    }
}

/// 已学 Tab：展示测过的汉字，儿童向大卡片列表
struct LearnedTabView: View {
    @Bindable var viewModel: AppViewModel
    @State private var filter: LearnedListFilter = .all
    @State private var selectedItem: HanziWithProgress?
    @State private var session: LearnSession?

    private var stats: LearnedTabStats { viewModel.learnedTabStats }
    private var items: [HanziWithProgress] { viewModel.filteredLearnedCharacters(filter: filter) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    header
                    statsRow
                    filterPicker
                    characterList
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .padding(.bottom, 24)
            }
            .background(backgroundGradient)
            .navigationDestination(item: $selectedItem) { item in
                LearnedCharacterDetailView(
                    viewModel: viewModel,
                    item: item,
                    onRetest: { character in
                        session = viewModel.makeCharacterQuizSession(character: character)
                    }
                )
            }
            .fullScreenCover(item: $session) { active in
                NavigationStack {
                    QuizSessionView(viewModel: viewModel, session: active) {
                        session = nil
                        viewModel.reloadTodayProgress()
                    }
                }
            }
        }
        .onAppear {
            SpeechService.shared.speak("这里是你学过的字，看看你学会了多少吧。")
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color.blue.opacity(0.12),
                Color("AccentGreen").opacity(0.08),
                Color(.systemBackground)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text("📚")
                .font(.system(size: 56))
            Text("我已学过的字")
                .font(.system(size: 32, weight: .bold, design: .rounded))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            statButton(
                emoji: "🌟",
                count: stats.mastered,
                label: "完全掌握",
                filter: .mastered
            )
            statButton(
                emoji: "💪",
                count: stats.inProgress,
                label: "还在练",
                filter: .inProgress
            )
            statButton(
                emoji: "🔥",
                count: stats.intensive,
                label: "要多练",
                filter: .intensive
            )
        }
    }

    private func statButton(emoji: String, count: Int, label: String, filter target: LearnedListFilter) -> some View {
        Button {
            filter = target
        } label: {
            VStack(spacing: 6) {
                Text(emoji)
                    .font(.title2)
                Text("\(count)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text(label)
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                filter == target
                    ? Color("AccentGreen").opacity(0.18)
                    : Color(.secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 18)
            )
        }
        .buttonStyle(.plain)
    }

    private var filterPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(LearnedListFilter.allCases) { option in
                    Button {
                        filter = option
                    } label: {
                        Text(option.title)
                            .font(.subheadline.bold())
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                filter == option
                                    ? Color("AccentGreen")
                                    : Color(.secondarySystemGroupedBackground),
                                in: Capsule()
                            )
                            .foregroundStyle(filter == option ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private var characterList: some View {
        if items.isEmpty {
            emptyState
        } else {
            LazyVStack(spacing: 12) {
                ForEach(items) { item in
                    Button {
                        selectedItem = item
                    } label: {
                        LearnedCharacterRow(item: item)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Text(filter == .all ? "📭" : "🔍")
                .font(.system(size: 64))
            Text(emptyMessage)
                .font(.title3.bold())
                .multilineTextAlignment(.center)
            if filter == .all {
                Text("去「玩」里点大按钮，开始学汉字吧 🚀")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .padding(.horizontal, 12)
    }

    private var emptyMessage: String {
        switch filter {
        case .all:
            return "还没有测过的字"
        case .mastered:
            return "还没有完全掌握的字"
        case .inProgress:
            return "没有正在练习的字"
        case .intensive:
            return "太棒了，没有要多练的字"
        }
    }
}

private struct LearnedCharacterRow: View {
    let item: HanziWithProgress

    var body: some View {
        HStack(spacing: 16) {
            Text(item.character.character)
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .frame(width: 64)

            VStack(alignment: .leading, spacing: 6) {
                Text(item.character.pinyin)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text(item.character.sentence)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 4) {
                Text(statusEmoji)
                    .font(.title2)
                Text(item.mastery.title)
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
    }

    private var statusEmoji: String {
        if item.mastery >= .mastered { return "🌟" }
        if item.inIntensiveReview { return "🔥" }
        return "💪"
    }
}

struct LearnedCharacterDetailView: View {
    @Bindable var viewModel: AppViewModel
    let item: HanziWithProgress
    let onRetest: (HanziCharacter) -> Void

    private var liveItem: HanziWithProgress {
        viewModel.progress(for: item.character.id) ?? item
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                CharacterLearnCard(character: liveItem.character, mastery: liveItem.mastery)

                statsCard

                Button {
                    SpeechService.shared.stop()
                    onRetest(liveItem.character)
                } label: {
                    Label("再测一次", systemImage: "arrow.clockwise.circle.fill")
                }
                .buttonStyle(KidPrimaryButtonStyle(color: .orange))
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(liveItem.character.character)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var statsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("掌握程度")
                    .font(.headline)
                Spacer()
                Text(liveItem.mastery.title)
                    .font(.headline)
                    .foregroundStyle(Color("AccentGreen"))
            }

            ProgressView(value: Double(liveItem.mastery.rawValue), total: 5)
                .tint(Color("AccentGreen"))
                .scaleEffect(x: 1, y: 2, anchor: .center)

            Text("答对 \(liveItem.memory.correctCount) 次 · 答错 \(liveItem.memory.wrongCount) 次")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let nextReview = liveItem.nextReviewAt {
                Text("下次复习：\(nextReview.formatted(.relative(presentation: .named)))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if liveItem.inIntensiveReview {
                Label("在重点复习库里，多练几次吧", systemImage: "flame.fill")
                    .font(.subheadline.bold())
                    .foregroundStyle(.orange)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
    }
}
