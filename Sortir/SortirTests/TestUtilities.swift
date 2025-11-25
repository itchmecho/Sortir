import Foundation
import Photos
@testable import Sortir

/// Mock implementation of PhotosService for testing
class MockPhotosService: PhotosService {
    /// Allows tests to control photo library data
    var mockPhotos: [PHAsset] = []
    /// Tracks authorization requests for verification
    var authorizationRequested = false

    /// Override to return mock photos
    override func fetchAllPhotos() -> [PHAsset] {
        return mockPhotos
    }

    /// Track authorization requests
    override func requestAuthorization() async -> Bool {
        authorizationRequested = true
        return true
    }
}

/// Mock implementation of CoreDataService for testing
class MockCoreDataService: CoreDataService {
    /// Tracks session start calls for verification
    var sessionStarted = false
    /// Tracks saved results for verification
    var savedResults: [(assetId: String, direction: String, action: String)] = []
    /// Mock session ID to return
    var mockSessionId = UUID()

    /// Track session start
    override func startSession(totalPhotos: Int, workflowId: UUID?) -> UUID? {
        sessionStarted = true
        return mockSessionId
    }

    /// Track results
    override func saveResult(assetId: String, direction: String, action: String, sessionId: UUID) {
        savedResults.append((assetId, direction, action))
    }
}

/// Test helper for creating workflows
extension Workflow {
    /// Creates a test workflow with standard delete/keep actions
    static func testWorkflow() -> Workflow {
        return Workflow(
            id: UUID(),
            name: "Test Workflow",
            leftAction: .delete(),
            rightAction: .keep(),
            createdDate: Date(),
            lastUsedDate: Date()
        )
    }
}

/// Test helper for creating workflow actions
extension WorkflowAction {
    /// Creates a delete action for testing
    static func delete() -> WorkflowAction {
        return WorkflowAction(
            type: .delete,
            displayName: "Delete",
            icon: "trash.fill",
            color: .red
        )
    }

    /// Creates a keep action for testing
    static func keep() -> WorkflowAction {
        return WorkflowAction(
            type: .keep,
            displayName: "Keep",
            icon: "checkmark.circle.fill",
            color: .green
        )
    }
}
