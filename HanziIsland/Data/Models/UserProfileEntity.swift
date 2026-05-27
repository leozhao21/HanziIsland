import Foundation
import SwiftData

@Model
final class UserProfileEntity {
    var starCount: Int
    var studyModeRaw: String
    var unlockedIslandIds: [String]
    var weeklyMasteredIds: [String]
    var lastDailyTaskDate: Date?
    /// 每日学习汉字数量目标
    var dailyLearningGoal: Int = 20
    /// 目标是否随学习模式自动调整
    var followStudyModeGoal: Bool = true

    init(
        starCount: Int = 0,
        studyModeRaw: String = StudyMode.standard.rawValue,
        unlockedIslandIds: [String] = [],
        weeklyMasteredIds: [String] = [],
        lastDailyTaskDate: Date? = nil,
        dailyLearningGoal: Int = DailyLearningGoal.recommended(for: .standard),
        followStudyModeGoal: Bool = true
    ) {
        self.starCount = starCount
        self.studyModeRaw = studyModeRaw
        self.unlockedIslandIds = unlockedIslandIds
        self.weeklyMasteredIds = weeklyMasteredIds
        self.lastDailyTaskDate = lastDailyTaskDate
        self.dailyLearningGoal = dailyLearningGoal
        self.followStudyModeGoal = followStudyModeGoal
    }

    var studyMode: StudyMode {
        get { StudyMode(rawValue: studyModeRaw) ?? .standard }
        set { studyModeRaw = newValue.rawValue }
    }
}
