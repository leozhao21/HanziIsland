import Foundation
import SwiftData

@MainActor
final class UserProfileRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchOrCreate() throws -> UserProfileEntity {
        let descriptor = FetchDescriptor<UserProfileEntity>()
        if let existing = try modelContext.fetch(descriptor).first {
            return existing
        }
        let profile = UserProfileEntity()
        modelContext.insert(profile)
        try modelContext.save()
        return profile
    }

    func addStars(_ count: Int) throws -> UserProfileEntity {
        let profile = try fetchOrCreate()
        profile.starCount += count
        try modelContext.save()
        return profile
    }

    func unlockIsland(id: String) throws -> Bool {
        let profile = try fetchOrCreate()
        guard !profile.unlockedIslandIds.contains(id) else { return false }
        profile.unlockedIslandIds.append(id)
        try modelContext.save()
        return true
    }

    func recordWeeklyMastered(characterId: String) throws {
        let profile = try fetchOrCreate()
        if !profile.weeklyMasteredIds.contains(characterId) {
            profile.weeklyMasteredIds.append(characterId)
        }
        try modelContext.save()
    }
}
