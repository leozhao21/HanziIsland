import Foundation

/// 汉字基础信息与配套资源（PRD 第二节）
struct HanziCharacter: Codable, Identifiable, Hashable {
    let id: String
    let character: String
    let pinyin: String
    let meaning: String
    let sentence: String
    let level: Int
    let audioName: String?
    let strokeAnimationName: String?
    /// 组成该字的偏旁/部件（如 ["日", "月"]）
    let components: [String]?
    /// 儿童向拆解讲解
    let decomposeHint: String?
    /// 字源类型：象形、会意、形声
    let evolutionType: String?
    /// 儿童向汉字演变/字源讲解
    let evolutionHint: String?

    enum CodingKeys: String, CodingKey {
        case id, character, pinyin, meaning, sentence, level
        case audioName = "audio"
        case strokeAnimationName = "strokeAnimation"
        case components
        case decomposeHint
        case evolutionType
        case evolutionHint
    }

    var hasDecomposition: Bool {
        guard let decomposeHint else { return false }
        return !decomposeHint.isEmpty
    }

    var hasEvolution: Bool {
        guard let evolutionHint else { return false }
        return !evolutionHint.isEmpty
    }

    var showsComponentBreakdown: Bool {
        guard let components else { return false }
        return !components.isEmpty
    }

    /// 是否展示「组成」区块（有拆解讲解或部件数据即可）
    var showsCompositionSection: Bool {
        hasDecomposition || showsComponentBreakdown
    }
}

/// 带学习进度的汉字视图模型
struct HanziWithProgress: Identifiable, Hashable {
    let character: HanziCharacter
    var mastery: MasteryLevel
    var memory: MemoryScore
    var nextReviewAt: Date?
    var intervalStep: Int
    var inIntensiveReview: Bool

    var id: String { character.id }

    var reviewPool: ReviewPool {
        if mastery == .mastered && !inIntensiveReview { return .mastered }
        if inIntensiveReview || mastery.rawValue <= 2 { return .intensive }
        return .review
    }
}

enum ReviewPool: String, CaseIterable {
    case mastered = "掌握库"
    case review = "复习库"
    case intensive = "重点复习库"
}
