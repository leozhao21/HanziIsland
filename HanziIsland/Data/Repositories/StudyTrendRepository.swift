import Foundation
import SwiftData

@MainActor
final class StudyTrendRepository {
    private let modelContext: ModelContext
    private let calendar = Calendar.current

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    static func startOfDay(_ date: Date = .now, calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: date)
    }

    func fetchOrCreateToday() throws -> DailyStudySnapshotEntity {
        let day = Self.startOfDay(calendar: calendar)
        let all = try modelContext.fetch(FetchDescriptor<DailyStudySnapshotEntity>())
        if let existing = all.first(where: { calendar.isDate($0.dayStart, inSameDayAs: day) }) {
            return existing
        }
        let entity = DailyStudySnapshotEntity(dayStart: day)
        modelContext.insert(entity)
        try modelContext.save()
        return entity
    }

    /// 记录一次答题
    func recordAnswer(
        characterId: String,
        correct: Bool,
        masteredCount: Int,
        learnedCount: Int,
        averageForgettingRate: Double,
        becameMastered: Bool
    ) throws {
        let snapshot = try fetchOrCreateToday()
        snapshot.questionsAnswered += 1
        if correct {
            snapshot.correctCount += 1
        } else {
            snapshot.wrongCount += 1
        }
        snapshot.cumulativeMastered = masteredCount
        snapshot.cumulativeLearned = learnedCount
        snapshot.averageForgettingRate = averageForgettingRate
        if becameMastered {
            snapshot.newMasteredCount += 1
        }
        try modelContext.save()
    }

    /// 学习会话开始时标记今日接触过的生字 id（去重计数）
    func recordCharactersStudied(ids: Set<String>) throws {
        guard !ids.isEmpty else { return }
        let snapshot = try fetchOrCreateToday()
        // 用 questions 侧推算：每次会话合并，以当日累计 unique 数存入 charactersStudied
        // 简化：会话结束时传入本次 unique 数并累加（同一天多次学习累加接触人次）
        snapshot.charactersStudied += ids.count
        try modelContext.save()
    }

    func fetchLastDays(_ days: Int) throws -> [DailyStudySnapshot] {
        guard days > 0 else { return [] }
        let end = Self.startOfDay()
        guard let start = calendar.date(byAdding: .day, value: -(days - 1), to: end) else {
            return []
        }

        let entities = try modelContext.fetch(FetchDescriptor<DailyStudySnapshotEntity>())

        return (0..<days).compactMap { offset -> DailyStudySnapshot? in
            guard let day = calendar.date(byAdding: .day, value: offset, to: start) else { return nil }
            let key = Self.startOfDay(day, calendar: calendar)
            if let e = entities.first(where: { calendar.isDate($0.dayStart, inSameDayAs: key) }) {
                return e.toModel()
            }
            return DailyStudySnapshot(
                dayStart: key,
                charactersStudied: 0,
                questionsAnswered: 0,
                correctCount: 0,
                wrongCount: 0,
                newMasteredCount: 0,
                cumulativeMastered: 0,
                cumulativeLearned: 0,
                averageForgettingRate: 0
            )
        }
    }

    func fetchToday() throws -> DailyStudySnapshot {
        let entity = try fetchOrCreateToday()
        return entity.toModel()
    }

    func chartData(days: Int = 14) throws -> StudyTrendChartData {
        let snapshots = try fetchLastDays(days)
        return StudyTrendChartData(
            dailyVolume: snapshots,
            masteredGrowth: snapshots,
            forgettingTrend: snapshots
        )
    }
}

private extension DailyStudySnapshotEntity {
    func toModel() -> DailyStudySnapshot {
        DailyStudySnapshot(
            dayStart: dayStart,
            charactersStudied: charactersStudied,
            questionsAnswered: questionsAnswered,
            correctCount: correctCount,
            wrongCount: wrongCount,
            newMasteredCount: newMasteredCount,
            cumulativeMastered: cumulativeMastered,
            cumulativeLearned: cumulativeLearned,
            averageForgettingRate: averageForgettingRate
        )
    }
}
