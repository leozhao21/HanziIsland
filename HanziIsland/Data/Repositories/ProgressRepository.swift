import Foundation
import SwiftData

@MainActor
final class ProgressRepository {
    private let modelContext: ModelContext
    private let catalog: CharacterCatalogRepository

    init(modelContext: ModelContext, catalog: CharacterCatalogRepository) {
        self.modelContext = modelContext
        self.catalog = catalog
    }

    func fetchAllProgress() throws -> [String: HanziWithProgress] {
        let descriptor = FetchDescriptor<CharacterProgressEntity>()
        let entities = try modelContext.fetch(descriptor)
        var map: [String: HanziWithProgress] = [:]

        for entity in entities {
            guard let char = catalog.character(id: entity.characterId) else { continue }
            map[entity.characterId] = entity.toProgress(with: char)
        }
        return map
    }

    func save(_ progress: HanziWithProgress) throws {
        let id = progress.character.id
        var descriptor = FetchDescriptor<CharacterProgressEntity>(
            predicate: #Predicate { $0.characterId == id }
        )
        descriptor.fetchLimit = 1

        if let existing = try modelContext.fetch(descriptor).first {
            existing.apply(from: progress)
        } else {
            let entity = CharacterProgressEntity(characterId: id)
            entity.apply(from: progress)
            modelContext.insert(entity)
        }
        try modelContext.save()
    }

    /// 批量补齐进度记录（一次查询 + 批量插入，避免逐字 fetch 卡死启动）
    func ensureProgressExists(for characterIds: [String]) throws {
        let existing = try modelContext.fetch(FetchDescriptor<CharacterProgressEntity>())
        let existingIds = Set(existing.map(\.characterId))
        let missing = characterIds.filter { existingIds.contains($0) == false && catalog.character(id: $0) != nil }
        guard !missing.isEmpty else { return }

        for id in missing {
            modelContext.insert(CharacterProgressEntity(characterId: id))
        }
        try modelContext.save()
    }
}
