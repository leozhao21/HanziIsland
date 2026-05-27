import Foundation

/// 从 Bundle JSON 加载分级字库（PRD 第十一节）
final class CharacterCatalogRepository {
    private(set) var characters: [HanziCharacter] = []

    func load() throws {
        var merged: [HanziCharacter] = []
        let decoder = JSONDecoder()

        for level in 1...4 {
            let name = "characters_level\(level)"
            guard let url = Bundle.main.url(forResource: name, withExtension: "json") else {
                throw CatalogError.missingResource(name)
            }
            let data = try Data(contentsOf: url)
            let batch = try decoder.decode([HanziCharacter].self, from: data)
            merged.append(contentsOf: batch)
        }

        // 按 id 去重，保留首次出现（低级别优先）
        var seen = Set<String>()
        characters = merged.filter { char in
            guard !seen.contains(char.id) else { return false }
            seen.insert(char.id)
            return true
        }
    }

    func characters(level: Int) -> [HanziCharacter] {
        characters.filter { $0.level == level }
    }

    func character(id: String) -> HanziCharacter? {
        characters.first { $0.id == id }
    }

    enum CatalogError: Error, LocalizedError {
        case missingResource(String)

        var errorDescription: String? {
            switch self {
            case .missingResource(let name):
                return "找不到字库文件：\(name).json"
            }
        }
    }
}
