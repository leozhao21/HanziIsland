import Foundation

/// 间隔复习（PRD 第五节，参考 Anki）
struct SpacedRepetitionService {
    static let intervalsInDays = [1, 3, 7, 15, 30]

    func nextReviewDate(afterCorrect: Bool, currentStep: Int, from date: Date = .now) -> (date: Date, step: Int) {
        if afterCorrect {
            let step = min(currentStep + 1, Self.intervalsInDays.count - 1)
            let days = Self.intervalsInDays[step]
            return (Calendar.current.date(byAdding: .day, value: days, to: date) ?? date, step)
        } else {
            let days = Self.intervalsInDays[0]
            return (Calendar.current.date(byAdding: .day, value: days, to: date) ?? date, 0)
        }
    }

    func isDue(nextReviewAt: Date?, now: Date = .now) -> Bool {
        guard let nextReviewAt else { return true }
        return nextReviewAt <= now
    }
}
