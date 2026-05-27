import Foundation

/// 汉字基础信息与配套资源（PRD 第二节）
struct HanziCharacter: Codable, Identifiable, Hashable {
    let id: String
    let character: String
    let pinyin: String
    let meaning: String
    let sentence: String
    let level: Int
    let imageName: String?
    let audioName: String?
    let strokeAnimationName: String?

    enum CodingKeys: String, CodingKey {
        case id, character, pinyin, meaning, sentence, level
        case imageName = "image"
        case audioName = "audio"
        case strokeAnimationName = "strokeAnimation"
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
