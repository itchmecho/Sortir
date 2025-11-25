import CoreData

class CoreDataService {
    static let shared = CoreDataService()

    let persistenceController = PersistenceController.shared

    var viewContext: NSManagedObjectContext {
        persistenceController.container.viewContext
    }

    // MARK: - Session Management
    func startSession(totalPhotos: Int) -> UUID {
        let context = viewContext
        let session = PhotoSessionEntity(context: context)
        let sessionId = UUID()
        session.id = sessionId
        session.startTime = Date()
        session.totalPhotos = Int32(totalPhotos)

        do {
            try context.save()
        } catch {
            print("Failed to start session: \(error)")
        }

        return sessionId
    }

    func saveResult(assetId: String, direction: String, action: String, sessionId: UUID) {
        let context = viewContext
        let result = WorkflowResultEntity(context: context)
        result.id = UUID()
        result.assetIdentifier = assetId
        result.swipeDirection = direction
        result.action = action
        result.sessionId = sessionId
        result.timestamp = Date()

        do {
            try context.save()
        } catch {
            print("Failed to save result: \(error)")
        }
    }

    func endSession(sessionId: UUID) {
        let context = viewContext
        let fetchRequest: NSFetchRequest<PhotoSessionEntity> = PhotoSessionEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", sessionId as CVarArg)

        do {
            if let session = try context.fetch(fetchRequest).first {
                session.endTime = Date()
                try context.save()
            }
        } catch {
            print("Failed to end session: \(error)")
        }
    }

    func clearAllData() {
        let context = viewContext
        let entityNames = persistenceController.container.managedObjectModel.entities.compactMap { $0.name }

        for entityName in entityNames {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

            do {
                try context.execute(deleteRequest)
            } catch {
                print("Failed to delete \(entityName): \(error)")
            }
        }

        do {
            try context.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }
}
