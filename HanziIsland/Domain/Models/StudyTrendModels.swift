import Foundation

struct DailyStudySnapshot: Identifiable, Equatable {
    let dayStart: Date
    var charactersStudied: Int
    var questionsAnswered: Int
    var correctCount: Int
    var wrongCount: Int
    var newMasteredCount: Int
    var cumulativeMastered: Int
    var cumulativeLearned: Int
    var averageForgettingRate: Double

    var id: Date { dayStart }

    var accuracy: Double {
        guard questionsAnswered > 0 else { return 0 }
        return Double(correctCount) / Double(questionsAnswered)
    }
}

struct StudyTrendChartData: Equatable {
    let dailyVolume: [DailyStudySnapshot]
    let masteredGrowth: [DailyStudySnapshot]
    let forgettingTrend: [DailyStudySnapshot]
}
