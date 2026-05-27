import Foundation

/// 每日任务分配（PRD 第三节）
struct DailyTaskPlan: Equatable {
    let newCharacters: [HanziCharacter]
    let reviewCharacters: [HanziCharacter]
    let randomCheckCharacters: [HanziCharacter]

    var totalCount: Int {
        newCharacters.count + reviewCharacters.count + randomCheckCharacters.count
    }
}

struct DailyTaskService {
    func buildPlan(
        mode: StudyMode,
        catalog: [HanziCharacter],
        progress: [String: HanziWithProgress],
        now: Date = .now
    ) -> DailyTaskPlan {
        let srs = SpacedRepetitionService()

        let unlearned = catalog.filter { progress[$0.id]?.mastery == .unlearned || progress[$0.id] == nil }
        let newChars = Array(unlearned.prefix(mode.newCharactersPerDay))

        let dueForReview = catalog.filter { item in
            guard let p = progress[item.id], p.mastery != .unlearned else { return false }
            return srs.isDue(nextReviewAt: p.nextReviewAt, now: now) || p.inIntensiveReview
        }

        let sortedByForgetting = dueForReview.sorted { lhs, rhs in
            let lRate = progress[lhs.id]?.memory.forgettingRate ?? 0
            let rRate = progress[rhs.id]?.memory.forgettingRate ?? 0
            if lRate != rRate { return lRate > rRate }
            let lIntensive = progress[lhs.id]?.inIntensiveReview ?? false
            let rIntensive = progress[rhs.id]?.inIntensiveReview ?? false
            return lIntensive && !rIntensive
        }

        let review = Array(sortedByForgetting.prefix(mode.reviewCharactersPerDay))

        let masteredOrLearning = catalog.filter {
            guard let p = progress[$0.id] else { return false }
            return p.mastery >= .familiar
        }
        let randomCheck = Array(masteredOrLearning.shuffled().prefix(mode.randomCheckPerDay))

        return DailyTaskPlan(
            newCharacters: newChars,
            reviewCharacters: review,
            randomCheckCharacters: randomCheck
        )
    }
}
