import Foundation
import SwiftData

enum AppPersistence {
    static let legacyICloudSyncEnabledKey = "isICloudSyncEnabled"
    // Flip this to false when paid Apple Developer provisioning and CloudKit entitlements are restored.
    static let isICloudSyncArchived = true
    static let cloudKitContainerIdentifier = "iCloud.DJJAGBLUE.RoadToTheosis"

    static func makeModelContainer() -> ModelContainer {
        makeModelContainer(isICloudSyncEnabled: false)
    }

    static func makeModelContainer(isICloudSyncEnabled: Bool) -> ModelContainer {
        let schema = Schema([
            StoredLogEntry.self,
            StoredAppPreference.self
        ])
        let effectiveICloudSyncEnabled = isICloudSyncEnabled && !isICloudSyncArchived
        let configuration = ModelConfiguration(
            "RoadToTheosisStore",
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true,
            cloudKitDatabase: effectiveICloudSyncEnabled ? .private(cloudKitContainerIdentifier) : .none
        )

        do {
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {
            fatalError("Failed to create Road to Theosis model container: \(error)")
        }
    }
}
