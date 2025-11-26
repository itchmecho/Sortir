import Foundation
import Photos
@testable import Flipix

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

    /// Override caching to be no-op in tests
    override func startCachingImages(around assets: [PHAsset], centerIndex: Int) {
        // No-op for testing
    }

    /// Override stop caching to be no-op in tests
    override func stopCachingAllImages() {
        // No-op for testing
    }
}

/// Extension to create testable PhotoAssetItem with a unique mock ID
extension PhotoAssetItem {
    /// Creates a test photo item with a unique identifier
    /// Use this instead of PHAsset() which cannot be instantiated directly
    static func testItem(id: String = UUID().uuidString) -> PhotoAssetItem {
        // Use the test initializer that accepts a custom id
        return PhotoAssetItem(testId: id, asset: PHAsset())
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
    override func startSession(totalPhotos: Int, workflowId: UUID? = nil) -> UUID {
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
            createdAt: Date(),
            lastUsedAt: Date()
        )
    }
}

// Note: WorkflowAction already has .delete() and .keep() static methods in the main codebase
