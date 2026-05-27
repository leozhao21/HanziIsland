import Foundation
import SwiftData

@Model
final class CharacterProgressEntity {
    @Attribute(.unique) var characterId: String
    var masteryRaw: Int
    var correctCount: Int
    var wrongCount: Int
    var nextReviewAt: Date?
    var intervalStep: Int
    var inIntensiveReview: Bool
    var lastStudiedAt: Date?

    init(
        characterId: String,
        masteryRaw: Int = 0,
        correctCount: Int = 0,
        wrongCount: Int = 0,
        nextReviewAt: Date? = nil,
        intervalStep: Int = 0,
        inIntensiveReview: Bool = false,
        lastStudiedAt: Date? = nil
    ) {
        self.characterId = characterId
        self.masteryRaw = masteryRaw
        self.correctCount = correctCount
        self.wrongCount = wrongCount
        self.nextReviewAt = nextReviewAt
        self.intervalStep = intervalStep
        self.inIntensiveReview = inIntensiveReview
        self.lastStudiedAt = lastStudiedAt
    }

    var mastery: MasteryLevel {
        get { MasteryLevel(rawValue: masteryRaw) ?? .unlearned }
        set { masteryRaw = newValue.rawValue }
    }

    func toProgress(with character: HanziCharacter) -> HanziWithProgress {
        HanziWithProgress(
            character: character,
            mastery: mastery,
            memory: MemoryScore(correctCount: correctCount, wrongCount: wrongCount),
            nextReviewAt: nextReviewAt,
            intervalStep: intervalStep,
            inIntensiveReview: inIntensiveReview
        )
    }

    func apply(from progress: HanziWithProgress) {
        mastery = progress.mastery
        correctCount = progress.memory.correctCount
        wrongCount = progress.memory.wrongCount
        nextReviewAt = progress.nextReviewAt
        intervalStep = progress.intervalStep
        inIntensiveReview = progress.inIntensiveReview
        lastStudiedAt = .now
    }
}
