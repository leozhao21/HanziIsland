import Foundation
import SwiftData

/// 每日学习快照（家长中心趋势图持久化）
@Model
final class DailyStudySnapshotEntity {
    /// 当日 0 点（本地时区），用于唯一键
    @Attribute(.unique) var dayStart: Date
    var charactersStudied: Int
    var questionsAnswered: Int
    var correctCount: Int
    var wrongCount: Int
    var newMasteredCount: Int
    var cumulativeMastered: Int
    var cumulativeLearned: Int
    var averageForgettingRate: Double

    init(
        dayStart: Date,
        charactersStudied: Int = 0,
        questionsAnswered: Int = 0,
        correctCount: Int = 0,
        wrongCount: Int = 0,
        newMasteredCount: Int = 0,
        cumulativeMastered: Int = 0,
        cumulativeLearned: Int = 0,
        averageForgettingRate: Double = 0
    ) {
        self.dayStart = dayStart
        self.charactersStudied = charactersStudied
        self.questionsAnswered = questionsAnswered
        self.correctCount = correctCount
        self.wrongCount = wrongCount
        self.newMasteredCount = newMasteredCount
        self.cumulativeMastered = cumulativeMastered
        self.cumulativeLearned = cumulativeLearned
        self.averageForgettingRate = averageForgettingRate
    }
}
