import Foundation

struct ParentDashboardStats: Equatable {
    let totalLearned: Int
    let trulyMastered: Int
    let inReview: Int
    let easyToForget: Int
    let weeklyNewMastered: [HanziCharacter]
    let weeklyMasteredCount: Int
}

struct ParentStatsUseCase {
    func compute(
        catalog: [HanziCharacter],
        progress: [String: HanziWithProgress],
        weeklyMasteredIds: [String]
    ) -> ParentDashboardStats {
        let learned = progress.values.filter { $0.mastery >= .learning }.count
        let mastered = progress.values.filter { $0.mastery >= .mastered }.count
        let inReview = progress.values.filter {
            $0.mastery >= .familiar && $0.mastery < .mastered
        }.count
        let forgetful = progress.values.filter { $0.memory.forgettingRate > 0.4 }.count

        let weeklyChars = weeklyMasteredIds.compactMap { id in
            catalog.first { $0.id == id }
        }

        return ParentDashboardStats(
            totalLearned: learned,
            trulyMastered: mastered,
            inReview: inReview,
            easyToForget: forgetful,
            weeklyNewMastered: weeklyChars,
            weeklyMasteredCount: weeklyChars.count
        )
    }
}
