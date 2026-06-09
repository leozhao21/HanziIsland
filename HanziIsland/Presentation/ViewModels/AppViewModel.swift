import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class AppViewModel {
    var catalog: [HanziCharacter] = []
    private var catalogById: [String: HanziCharacter] = [:]
    /// 仅保存已有学习记录的字（稀疏表，避免启动时创建 1900 条）
    var progressMap: [String: HanziWithProgress] = [:]
    var dailyPlan: DailyTaskPlan?
    var studyMode: StudyMode = .standard
    var dailyLearningGoal: DailyLearningGoal = DailyLearningGoal(
        targetCount: DailyLearningGoal.recommended(for: .standard),
        followStudyMode: true
    )
    var todayProgress: TodayLearningProgress = TodayLearningProgress(
        goal: 20,
        charactersStudied: 0,
        questionsAnswered: 0,
        correctCount: 0,
        newMasteredCount: 0
    )
    var starCount: Int = 0
    var unlockedIslands: [String] = []
    var isLoaded = false
    var loadError: String?
    var loadStatus: String = "正在启动…"
    var studyTrend: StudyTrendChartData = StudyTrendChartData(
        dailyVolume: [],
        masteredGrowth: [],
        forgettingTrend: []
    )

    private var modelContext: ModelContext?
    private var sessionStudiedCharacterIds: Set<String> = []
    private let catalogRepo = CharacterCatalogRepository()
    private let dailyTaskService = DailyTaskService()
    private let quizGenerator = QuizGeneratorService()
    private let recordAnswer = RecordAnswerUseCase()
    private let parentStats = ParentStatsUseCase()

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func load() async {
        guard let modelContext else {
            loadError = "数据库未初始化"
            return
        }

        loadError = nil

        do {
            loadStatus = "正在加载字库…"
            try catalogRepo.load()
            catalog = catalogRepo.characters
            catalogById = Dictionary(uniqueKeysWithValues: catalog.map { ($0.id, $0) })

            loadStatus = "正在读取学习记录…"
            let progressRepo = ProgressRepository(modelContext: modelContext, catalog: catalogRepo)
            let profileRepo = UserProfileRepository(modelContext: modelContext)
            progressMap = try progressRepo.fetchAllProgress()

            loadStatus = "正在准备今日任务…"
            let profile = try profileRepo.fetchOrCreate()
            studyMode = profile.studyMode
            migrateDailyGoalIfNeeded(profile: profile)
            try modelContext.save()

            dailyLearningGoal = DailyLearningGoal(
                targetCount: profile.dailyLearningGoal,
                followStudyMode: profile.followStudyModeGoal
            )
            starCount = profile.starCount
            unlockedIslands = profile.unlockedIslandIds

            refreshDailyPlan()
            reloadTodayProgress()

            isLoaded = true
            loadStatus = "完成"

            // 趋势图不阻塞首屏
            Task { @MainActor in
                reloadStudyTrend()
            }
        } catch {
            loadError = error.localizedDescription
            loadStatus = "加载失败"
            isLoaded = false
        }
    }

    func progress(for characterId: String) -> HanziWithProgress? {
        if let existing = progressMap[characterId] {
            return existing
        }
        guard let character = catalogById[characterId] else { return nil }
        return HanziWithProgress(
            character: character,
            mastery: .unlearned,
            memory: .zero,
            nextReviewAt: nil,
            intervalStep: 0,
            inIntensiveReview: false
        )
    }

    func mastery(for characterId: String) -> MasteryLevel {
        progress(for: characterId)?.mastery ?? .unlearned
    }

    func reloadStudyTrend() {
        guard let modelContext else { return }
        studyTrend = (try? StudyTrendRepository(modelContext: modelContext).chartData(days: 14))
            ?? StudyTrendChartData(dailyVolume: [], masteredGrowth: [], forgettingTrend: [])
    }

    func reloadTodayProgress() {
        guard let modelContext else { return }
        let snapshot = (try? StudyTrendRepository(modelContext: modelContext).fetchToday())
        todayProgress = TodayLearningProgress(
            goal: dailyLearningGoal.targetCount,
            charactersStudied: snapshot?.charactersStudied ?? 0,
            questionsAnswered: snapshot?.questionsAnswered ?? 0,
            correctCount: snapshot?.correctCount ?? 0,
            newMasteredCount: snapshot?.newMasteredCount ?? 0
        )
    }

    var recommendedDailyGoal: Int {
        DailyLearningGoal.recommended(for: studyMode)
    }

    func updateDailyLearningGoal(targetCount: Int) {
        var goal = dailyLearningGoal
        goal.targetCount = targetCount
        goal.followStudyMode = false
        applyDailyLearningGoal(goal)
    }

    func setFollowStudyModeGoal(_ enabled: Bool) {
        var goal = dailyLearningGoal
        goal.followStudyMode = enabled
        if enabled {
            goal.targetCount = recommendedDailyGoal
        }
        applyDailyLearningGoal(goal)
    }

    func applyRecommendedDailyGoal() {
        var goal = dailyLearningGoal
        goal.targetCount = recommendedDailyGoal
        goal.followStudyMode = true
        applyDailyLearningGoal(goal)
    }

    private func applyDailyLearningGoal(_ goal: DailyLearningGoal) {
        let clamped = goal.clamped()
        dailyLearningGoal = clamped
        guard let modelContext else { return }
        do {
            let profile = try UserProfileRepository(modelContext: modelContext).fetchOrCreate()
            profile.dailyLearningGoal = clamped.targetCount
            profile.followStudyModeGoal = clamped.followStudyMode
            try modelContext.save()
            reloadTodayProgress()
        } catch {
            loadError = error.localizedDescription
        }
    }

    private func migrateDailyGoalIfNeeded(profile: UserProfileEntity) {
        if profile.dailyLearningGoal < DailyLearningGoal.minCount {
            profile.dailyLearningGoal = DailyLearningGoal.recommended(for: profile.studyMode)
            profile.followStudyModeGoal = true
        }
    }

    func beginStudySession(characterIds: [String]) {
        sessionStudiedCharacterIds.formUnion(characterIds)
    }

    func endStudySession() async {
        guard let modelContext, !sessionStudiedCharacterIds.isEmpty else { return }
        do {
            try StudyTrendRepository(modelContext: modelContext)
                .recordCharactersStudied(ids: sessionStudiedCharacterIds)
            sessionStudiedCharacterIds.removeAll()
            reloadStudyTrend()
            reloadTodayProgress()
        } catch {
            loadError = error.localizedDescription
        }
    }

    private var averageForgettingRate: Double {
        let active = progressMap.values.filter { $0.mastery >= .learning }
        guard !active.isEmpty else { return 0 }
        return active.map(\.memory.forgettingRate).reduce(0, +) / Double(active.count)
    }

    private var learnedCount: Int {
        progressMap.values.filter { $0.mastery >= .learning }.count
    }

    func refreshDailyPlan() {
        dailyPlan = dailyTaskService.buildPlan(
            mode: studyMode,
            catalog: catalog,
            progress: progressMap
        )
    }

    func updateStudyMode(_ mode: StudyMode) {
        studyMode = mode
        guard let modelContext else { return }
        do {
            let profile = try UserProfileRepository(modelContext: modelContext).fetchOrCreate()
            profile.studyMode = mode
            if dailyLearningGoal.followStudyMode {
                profile.dailyLearningGoal = DailyLearningGoal.recommended(for: mode)
                profile.followStudyModeGoal = true
                dailyLearningGoal.targetCount = profile.dailyLearningGoal
            }
            try modelContext.save()
            refreshDailyPlan()
            reloadTodayProgress()
        } catch {
            loadError = error.localizedDescription
        }
    }

    func makeQuizSession(characters: [HanziCharacter], count: Int) -> [QuizQuestion] {
        quizGenerator.generateMixedSession(
            characters: characters,
            count: count,
            types: studyMode.quizTypes
        )
    }

    /// 儿童首页「开始学汉字」
    func makeDailyLearnSession() -> LearnSession? {
        guard let plan = dailyPlan, plan.totalCount > 0 else { return nil }
        let all = plan.newCharacters + plan.reviewCharacters + plan.randomCheckCharacters
        let questions = makeQuizSession(characters: all, count: min(all.count, 10))
        beginStudySession(characterIds: all.map(\.id))
        return LearnSession(questions: questions, learnCharacters: plan.newCharacters)
    }

    /// 儿童首页「再练错题」
    func makeIntensiveReviewSession() -> LearnSession? {
        let chars = intensiveReviewCharacters
        guard !chars.isEmpty else { return nil }
        let questions = makeQuizSession(characters: chars, count: min(chars.count, 10))
        beginStudySession(characterIds: chars.map(\.id))
        return LearnSession(questions: questions, learnCharacters: [])
    }

    /// 答错后进入重点复习库的字，按遗忘率从高到低
    var intensiveReviewCharacters: [HanziCharacter] {
        progressMap.values
            .filter { $0.inIntensiveReview }
            .sorted { $0.memory.forgettingRate > $1.memory.forgettingRate }
            .map(\.character)
    }

    func submitAnswer(for characterId: String, correct: Bool) async {
        guard let modelContext else { return }
        guard var item = progress(for: characterId) else { return }

        let previousMastery = item.mastery
        recordAnswer.apply(progress: &item, correct: correct)
        progressMap[characterId] = item

        do {
            let progressRepo = ProgressRepository(modelContext: modelContext, catalog: catalogRepo)
            try progressRepo.save(item)

            if item.mastery >= .mastered && previousMastery < .mastered {
                try UserProfileRepository(modelContext: modelContext)
                    .recordWeeklyMastered(characterId: characterId)
            }

            if correct {
                let profile = try UserProfileRepository(modelContext: modelContext).addStars(1)
                starCount = profile.starCount
            }

            try StudyTrendRepository(modelContext: modelContext).recordAnswer(
                characterId: characterId,
                correct: correct,
                masteredCount: masteredCount,
                learnedCount: learnedCount,
                averageForgettingRate: averageForgettingRate,
                becameMastered: item.mastery >= .mastered && previousMastery < .mastered
            )
            reloadStudyTrend()
            reloadTodayProgress()
            refreshDailyPlan()
        } catch {
            loadError = error.localizedDescription
        }
    }

    func unlockIsland(_ theme: IslandTheme) async -> Bool {
        guard starCount >= theme.starCost,
              !unlockedIslands.contains(theme.id),
              let modelContext else { return false }

        do {
            let profile = try UserProfileRepository(modelContext: modelContext).fetchOrCreate()
            guard profile.starCount >= theme.starCost else { return false }
            profile.starCount -= theme.starCost
            profile.unlockedIslandIds.append(theme.id)
            try modelContext.save()
            starCount = profile.starCount
            unlockedIslands = profile.unlockedIslandIds
            return true
        } catch {
            loadError = error.localizedDescription
            return false
        }
    }

    var parentDashboard: ParentDashboardStats {
        guard let modelContext else {
            return parentStats.compute(catalog: catalog, progress: progressMap, weeklyMasteredIds: [])
        }
        let weeklyIds = (try? UserProfileRepository(modelContext: modelContext)
            .fetchOrCreate().weeklyMasteredIds) ?? []
        return parentStats.compute(
            catalog: catalog,
            progress: progressMap,
            weeklyMasteredIds: weeklyIds
        )
    }

    var masteredCount: Int {
        progressMap.values.filter { $0.mastery >= .mastered }.count
    }

    var earnedBadges: [MasteryBadge] {
        MasteryBadge.earned(masteredCount: masteredCount)
    }

    // MARK: - 已学 Tab

    /// 至少答过一次检测题的字（不含仅「认识新字」阶段）
    var quizzedCharacters: [HanziWithProgress] {
        progressMap.values.filter { $0.memory.correctCount + $0.memory.wrongCount > 0 }
    }

    var learnedTabStats: LearnedTabStats {
        let quizzed = quizzedCharacters
        return LearnedTabStats(
            mastered: quizzed.filter { $0.mastery >= .mastered }.count,
            inProgress: quizzed.filter {
                $0.mastery >= .learning && $0.mastery < .mastered && !$0.inIntensiveReview
            }.count,
            intensive: quizzed.filter(\.inIntensiveReview).count
        )
    }

    func filteredLearnedCharacters(filter: LearnedListFilter) -> [HanziWithProgress] {
        let base = quizzedCharacters
        let filtered: [HanziWithProgress]
        switch filter {
        case .all:
            filtered = base
        case .mastered:
            filtered = base.filter { $0.mastery >= .mastered }
        case .inProgress:
            filtered = base.filter {
                $0.mastery >= .learning && $0.mastery < .mastered && !$0.inIntensiveReview
            }
        case .intensive:
            filtered = base.filter(\.inIntensiveReview)
        }
        return filtered.sorted { lhs, rhs in
            if lhs.mastery != rhs.mastery { return lhs.mastery > rhs.mastery }
            return lhs.character.pinyin.localizedStandardCompare(rhs.character.pinyin) == .orderedAscending
        }
    }

    /// 单字再测：跳过认识新字，直接进入检测
    func makeCharacterQuizSession(character: HanziCharacter) -> LearnSession {
        let questions = makeQuizSession(characters: [character], count: 3)
        beginStudySession(characterIds: [character.id])
        return LearnSession(questions: questions, learnCharacters: [])
    }
}

struct LearnedTabStats: Equatable {
    let mastered: Int
    let inProgress: Int
    let intensive: Int
}
