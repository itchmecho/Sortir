import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Flipix")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Log error instead of crashing - app can still function without persistence
                print("CoreData Store Error: \(error.localizedDescription)")
                if let reasons = error.userInfo["NSDebugDescription"] as? [String] {
                    print("Reasons: \(reasons)")
                }
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
