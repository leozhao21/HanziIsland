import Foundation

/// 记录答题结果：熟练度、间隔复习、题库回流
struct RecordAnswerUseCase {
    let srs = SpacedRepetitionService()

    func apply(
        progress: inout HanziWithProgress,
        correct: Bool,
        now: Date = .now
    ) {
        progress.memory.record(correct: correct)
        progress.mastery = MasteryLevel.adjusted(afterCorrect: correct, current: progress.mastery)

        if progress.mastery == .unlearned && correct {
            progress.mastery = .learning
        }

        let (nextDate, step) = srs.nextReviewDate(
            afterCorrect: correct,
            currentStep: progress.intervalStep,
            from: now
        )
        progress.nextReviewAt = nextDate
        progress.intervalStep = step

        if !correct {
            progress.inIntensiveReview = true
        } else if progress.mastery >= .good {
            progress.inIntensiveReview = false
        }
    }
}
