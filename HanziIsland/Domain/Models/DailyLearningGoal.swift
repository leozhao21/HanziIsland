import Foundation

/// 今日学习数量目标
struct DailyLearningGoal: Equatable {
    var targetCount: Int
    var followStudyMode: Bool

    static let minCount = 5
    static let maxCount = 50
    static let step = 5

    static let presets: [(label: String, value: Int)] = [
        ("轻松", 10),
        ("标准", 20),
        ("挑战", 30)
    ]

    static func recommended(for mode: StudyMode) -> Int {
        mode.newCharactersPerDay + mode.reviewCharactersPerDay + mode.randomCheckPerDay
    }

    func clamped() -> DailyLearningGoal {
        var copy = self
        copy.targetCount = min(Self.maxCount, max(Self.minCount, targetCount))
        return copy
    }
}

/// 今日学习进度
struct TodayLearningProgress: Equatable {
    let goal: Int
    let charactersStudied: Int
    let questionsAnswered: Int
    let correctCount: Int
    let newMasteredCount: Int

    var completedCount: Int { charactersStudied }

    var progress: Double {
        guard goal > 0 else { return 0 }
        return min(1, Double(completedCount) / Double(goal))
    }

    var isGoalMet: Bool { completedCount >= goal }

    var remaining: Int { max(0, goal - completedCount) }
}
