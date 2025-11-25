import SwiftUI

@main
struct SortirApp: App {
    let coreDataService = CoreDataService.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, coreDataService.viewContext)
        }
    }
}
