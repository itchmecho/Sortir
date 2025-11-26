import CoreData

class CoreDataService {
    static let shared = CoreDataService()

    let persistenceController = PersistenceController.shared

    var viewContext: NSManagedObjectContext {
        persistenceController.container.viewContext
    }

    // Create a background context for writes
    private var backgroundContext: NSManagedObjectContext {
        let context = persistenceController.container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }

    // MARK: - Workflow Management

    func fetchAllWorkflows() -> [Workflow] {
        let context = viewContext
        let fetchRequest: NSFetchRequest<WorkflowEntity> = WorkflowEntity.fetchRequest()
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "lastUsedAt", ascending: false),
            NSSortDescriptor(key: "createdAt", ascending: false)
        ]

        do {
            let entities = try context.fetch(fetchRequest)
            return entities.map { Workflow(from: $0) }
        } catch {
            print("Failed to fetch workflows: \(error)")
            return []
        }
    }

    func saveWorkflow(_ workflow: Workflow) {
        let context = viewContext

        // Check if workflow already exists
        let fetchRequest: NSFetchRequest<WorkflowEntity> = WorkflowEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", workflow.id as CVarArg)

        do {
            let existing = try context.fetch(fetchRequest).first
            let entity = existing ?? WorkflowEntity(context: context)

            entity.id = workflow.id
            entity.name = workflow.name
            entity.leftActionData = workflow.leftActionData
            entity.rightActionData = workflow.rightActionData
            entity.createdAt = workflow.createdAt
            entity.lastUsedAt = workflow.lastUsedAt

            try context.save()
        } catch {
            print("Failed to save workflow: \(error)")
        }
    }

    func deleteWorkflow(id: UUID) {
        let context = viewContext
        let fetchRequest: NSFetchRequest<WorkflowEntity> = WorkflowEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)

        do {
            if let entity = try context.fetch(fetchRequest).first {
                context.delete(entity)
                try context.save()
            }
        } catch {
            print("Failed to delete workflow: \(error)")
        }
    }

    func updateWorkflowLastUsed(id: UUID) {
        let context = viewContext
        let fetchRequest: NSFetchRequest<WorkflowEntity> = WorkflowEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)

        do {
            if let entity = try context.fetch(fetchRequest).first {
                entity.lastUsedAt = Date()
                try context.save()
            }
        } catch {
            print("Failed to update workflow lastUsedAt: \(error)")
        }
    }

    func createDefaultWorkflowIfNeeded() {
        let workflows = fetchAllWorkflows()
        if workflows.isEmpty {
            let quickSort = Workflow.quickSort()
            saveWorkflow(quickSort)
        }
    }

    // MARK: - Session Management
    func startSession(totalPhotos: Int, workflowId: UUID? = nil) -> UUID {
        let context = viewContext
        let session = PhotoSessionEntity(context: context)
        let sessionId = UUID()
        session.id = sessionId
        session.startTime = Date()
        session.totalPhotos = Int32(totalPhotos)
        session.workflowId = workflowId

        do {
            try context.save()
        } catch {
            print("Failed to start session: \(error)")
        }

        return sessionId
    }

    func saveResult(assetId: String, direction: String, action: String, sessionId: UUID) {
        let context = backgroundContext
        context.perform {
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
