import Foundation

/// 检测题型（PRD 第六节）
enum QuizType: String, CaseIterable, Identifiable {
    case recognize
    case listenPick
    case sentenceFill

    var id: String { rawValue }

    var title: String {
        switch self {
        case .recognize: return "认字"
        case .listenPick: return "听音选字"
        case .sentenceFill: return "例句填空"
        }
    }
}

struct QuizQuestion: Identifiable {
    let id: UUID
    let type: QuizType
    let target: HanziCharacter
    let prompt: String
    let options: [String]
    let correctIndex: Int
    let sentenceTemplate: String?

    init(
        id: UUID = UUID(),
        type: QuizType,
        target: HanziCharacter,
        prompt: String,
        options: [String],
        correctIndex: Int,
        sentenceTemplate: String? = nil
    ) {
        self.id = id
        self.type = type
        self.target = target
        self.prompt = prompt
        self.options = options
        self.correctIndex = correctIndex
        self.sentenceTemplate = sentenceTemplate
    }
}

struct QuizResult {
    let question: QuizQuestion
    let selectedIndex: Int
    let isCorrect: Bool
}
