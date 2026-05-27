import Foundation
import SwiftData

enum AppModelContainer {
    private static let storeName = "HanziIsland"

    static let schema = Schema([
        CharacterProgressEntity.self,
        UserProfileEntity.self,
        DailyStudySnapshotEntity.self
    ])

    enum MakeError: LocalizedError {
        case persistentStoreFailed(underlying: Error)
        case inMemoryFallbackFailed(underlying: Error)

        var errorDescription: String? {
            switch self {
            case .persistentStoreFailed(let error):
                return "无法打开本地数据库：\(error.localizedDescription)"
            case .inMemoryFallbackFailed(let error):
                return "无法创建内存数据库：\(error.localizedDescription)"
            }
        }
    }

    static func make() -> Result<ModelContainer, MakeError> {
        let configuration = ModelConfiguration(
            storeName,
            schema: schema,
            isStoredInMemoryOnly: false
        )

        if let container = try? ModelContainer(for: schema, configurations: [configuration]) {
            return .success(container)
        }

        removePersistentStoreFiles()

        if let container = try? ModelContainer(for: schema, configurations: [configuration]) {
            return .success(container)
        }

        let memoryConfig = ModelConfiguration(
            "HanziIslandMemory",
            schema: schema,
            isStoredInMemoryOnly: true
        )
        do {
            return .success(try ModelContainer(for: schema, configurations: [memoryConfig]))
        } catch {
            return .failure(.inMemoryFallbackFailed(underlying: error))
        }
    }

    private static func removePersistentStoreFiles() {
        let fileManager = FileManager.default
        guard let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return
        }
        for name in [
            "\(storeName).store", "\(storeName).store-shm", "\(storeName).store-wal",
            "default.store", "default.store-shm", "default.store-wal"
        ] {
            try? fileManager.removeItem(at: appSupport.appendingPathComponent(name))
        }
    }
}
