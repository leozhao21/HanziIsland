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
        quizGenerator.generateMixedSession(characters: characters, count: count)
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
}
