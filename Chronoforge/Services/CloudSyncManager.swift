import Foundation
import CloudKit

class CloudSyncManager {
    static let shared = CloudSyncManager()

    private let container = CKContainer.default()
    private let recordType = "PlayerSave"
    private let recordID = CKRecord.ID(recordName: "chronoforge_save")

    var iCloudAvailable: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }

    func uploadSave(_ player: PlayerState) async throws {
        guard iCloudAvailable else { return }

        let database = container.privateCloudDatabase

        let record: CKRecord
        do {
            record = try await database.record(for: recordID)
        } catch {
            record = CKRecord(recordType: recordType, recordID: recordID)
        }

        let data = try JSONEncoder().encode(player)
        record["saveData"] = data as CKRecordValue
        record["lastModified"] = Date() as CKRecordValue
        record["version"] = 1 as CKRecordValue

        try await database.save(record)
    }

    func downloadSave() async throws -> PlayerState? {
        guard iCloudAvailable else { return nil }

        let database = container.privateCloudDatabase

        do {
            let record = try await database.record(for: recordID)
            guard let data = record["saveData"] as? Data else { return nil }
            return try JSONDecoder().decode(PlayerState.self, from: data)
        } catch {
            return nil
        }
    }

    func resolveConflict(local: PlayerState, remote: PlayerState) -> PlayerState {
        // Use whichever save has more lifetime TE earned (more progressed)
        if local.totalLifetimeTEEarned >= remote.totalLifetimeTEEarned {
            return local
        }
        return remote
    }
}
