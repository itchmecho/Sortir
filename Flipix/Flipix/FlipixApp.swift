import SwiftUI

@main
struct FlipixApp: App {
    let coreDataService = CoreDataService.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, coreDataService.viewContext)
        }
    }
}
