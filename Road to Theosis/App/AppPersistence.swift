import Foundation
import SwiftData

enum AppPersistence {
    static let iCloudSyncEnabledKey = "isICloudSyncEnabled"
    static let cloudKitContainerIdentifier = "iCloud.devplaceholder.C1VP0G0X.RoadToTheosis"

    static func makeModelContainer() -> ModelContainer {
        makeModelContainer(isICloudSyncEnabled: UserDefaults.standard.bool(forKey: iCloudSyncEnabledKey))
    }

    static func makeModelContainer(isICloudSyncEnabled: Bool) -> ModelContainer {
        let schema = Schema([
            StoredLogEntry.self
        ])
        let configuration = ModelConfiguration(
            "RoadToTheosisStore",
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true,
            cloudKitDatabase: isICloudSyncEnabled ? .private(cloudKitContainerIdentifier) : .none
        )

        do {
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {
            fatalError("Failed to create Road to Theosis model container: \(error)")
        }
    }
}
