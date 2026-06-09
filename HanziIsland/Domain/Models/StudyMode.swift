import Foundation

/// 家长设置的学习模式（PRD 第三节）
enum StudyMode: String, Codable, CaseIterable, Identifiable {
    case simple
    case standard
    case advanced

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .simple: return "简单模式"
        case .standard: return "标准模式"
        case .advanced: return "进阶模式"
        }
    }

    var newCharactersPerDay: Int {
        switch self {
        case .simple: return 3
        case .standard: return 5
        case .advanced: return 10
        }
    }

    var reviewCharactersPerDay: Int { 10 }
    var randomCheckPerDay: Int { 5 }

    /// 简单模式不出听音题，降低对拼音/听辨的要求
    var quizTypes: [QuizType] {
        switch self {
        case .simple:
            return [.recognize, .sentenceFill]
        case .standard, .advanced:
            return QuizType.allCases
        }
    }
}
