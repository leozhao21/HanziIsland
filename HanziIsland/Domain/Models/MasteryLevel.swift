import Foundation

/// 汉字熟练度等级（PRD 第四节）
enum MasteryLevel: Int, Codable, CaseIterable, Comparable, Hashable {
    case unlearned = 0
    case learning = 1
    case familiar = 2
    case good = 3
    case proficient = 4
    case mastered = 5

    var title: String {
        switch self {
        case .unlearned: return "未学习"
        case .learning: return "学习中"
        case .familiar: return "初步认识"
        case .good: return "基本掌握"
        case .proficient: return "熟练"
        case .mastered: return "完全掌握"
        }
    }

    static func < (lhs: MasteryLevel, rhs: MasteryLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// 答对 +1，答错 -2，最低 0
    static func adjusted(afterCorrect: Bool, current: MasteryLevel) -> MasteryLevel {
        let delta = afterCorrect ? 1 : -2
        let raw = max(0, min(5, current.rawValue + delta))
        return MasteryLevel(rawValue: raw) ?? .unlearned
    }
}
