import Foundation

/// 掌握字数奖励（PRD 第八节）
struct MasteryBadge: Identifiable, Equatable {
    let threshold: Int
    let emoji: String
    let title: String

    var id: Int { threshold }

    static let all: [MasteryBadge] = [
        MasteryBadge(threshold: 50, emoji: "🌱", title: "识字小苗"),
        MasteryBadge(threshold: 100, emoji: "🌿", title: "阅读新手"),
        MasteryBadge(threshold: 300, emoji: "🌳", title: "阅读达人"),
        MasteryBadge(threshold: 500, emoji: "📚", title: "阅读小博士"),
        MasteryBadge(threshold: 1000, emoji: "🏆", title: "汉字大师")
    ]

    static func earned(masteredCount: Int) -> [MasteryBadge] {
        all.filter { masteredCount >= $0.threshold }
    }

    static func next(after masteredCount: Int) -> MasteryBadge? {
        all.first { masteredCount < $0.threshold }
    }
}

/// 成长岛解锁项（PRD 第九节）
struct IslandTheme: Identifiable, Equatable {
    let id: String
    let name: String
    let starCost: Int
    let emoji: String

    static let catalog: [IslandTheme] = [
        IslandTheme(id: "zoo", name: "动物园", starCost: 20, emoji: "🦁"),
        IslandTheme(id: "ocean", name: "海底世界", starCost: 40, emoji: "🐠"),
        IslandTheme(id: "dino", name: "恐龙乐园", starCost: 60, emoji: "🦕"),
        IslandTheme(id: "space", name: "宇宙基地", starCost: 100, emoji: "🚀")
    ]
}
