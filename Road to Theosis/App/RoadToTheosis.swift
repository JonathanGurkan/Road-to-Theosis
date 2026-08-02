import SwiftData
import SwiftUI

@main
struct RoadToTheosis: App {
    private let modelContainer = AppPersistence.makeModelContainer()

    var body: some Scene {
        WindowGroup {
            AppShellView()
        }
        .modelContainer(modelContainer)
    }
}
