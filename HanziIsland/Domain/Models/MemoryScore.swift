import Foundation

/// 遗忘指数（PRD 第七节）
struct MemoryScore: Codable, Equatable, Hashable {
    var correctCount: Int
    var wrongCount: Int

    var forgettingRate: Double {
        let total = correctCount + wrongCount
        guard total > 0 else { return 0 }
        return Double(wrongCount) / Double(total)
    }

    mutating func record(correct: Bool) {
        if correct {
            correctCount += 1
        } else {
            wrongCount += 1
        }
    }

    static let zero = MemoryScore(correctCount: 0, wrongCount: 0)
}
