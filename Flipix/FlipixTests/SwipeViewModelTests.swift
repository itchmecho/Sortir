import XCTest
import Photos
@testable import Flipix

/// Tests for SwipeViewModel undo/redo functionality
/// This is the most critical and complex logic in the app
@MainActor
final class SwipeViewModelTests: XCTestCase {
    var viewModel: SwipeViewModel!
    var mockPhotosService: MockPhotosService!
    var mockCoreDataService: MockCoreDataService!

    override func setUp() {
        super.setUp()
        mockPhotosService = MockPhotosService()
        mockCoreDataService = MockCoreDataService()
        viewModel = SwipeViewModel(
            photosService: mockPhotosService,
            coreDataService: mockCoreDataService
        )
        viewModel.workflow = .testWorkflow()
    }

    override func tearDown() {
        viewModel = nil
        mockPhotosService = nil
        mockCoreDataService = nil
        super.tearDown()
    }

    // MARK: - Undo Tests

    /// Test that undo reverts a left swipe action
    func testUndoLeftSwipe() {
        // Create a test photo item with a unique ID
        let photoItem = PhotoAssetItem.testItem(id: "test-photo-1")
        viewModel.photos = [photoItem]
        viewModel.currentIndex = 0

        // Perform a left swipe (delete action) - requires confirmation
        viewModel.performSwipe(direction: .left)

        // Delete actions show confirmation dialog first
        XCTAssertTrue(viewModel.showDeleteConfirmation)
        viewModel.confirmDelete()

        // Verify the action was recorded
        XCTAssertEqual(viewModel.leftActionCount, 1)
        XCTAssertEqual(viewModel.deletedAssets.count, 1)
        XCTAssertTrue(viewModel.canUndo)
        XCTAssertFalse(viewModel.canRedo)

        // Undo the action
        viewModel.undo()

        // Verify action was reversed
        XCTAssertEqual(viewModel.leftActionCount, 0)
        XCTAssertEqual(viewModel.deletedAssets.count, 0)
        XCTAssertFalse(viewModel.canUndo)
        XCTAssertTrue(viewModel.canRedo)
    }

    /// Test that undo reverts a right swipe action
    func testUndoRightSwipe() {
        // Create a test photo item with a unique ID
        let photoItem = PhotoAssetItem.testItem(id: "test-photo-1")
        viewModel.photos = [photoItem]
        viewModel.currentIndex = 0

        // Perform a right swipe (keep action)
        viewModel.performSwipe(direction: .right)

        // Verify the action was recorded
        XCTAssertEqual(viewModel.rightActionCount, 1)
        XCTAssertEqual(viewModel.keptAssets.count, 1)
        XCTAssertTrue(viewModel.canUndo)

        // Undo the action
        viewModel.undo()

        // Verify action was reversed
        XCTAssertEqual(viewModel.rightActionCount, 0)
        XCTAssertEqual(viewModel.keptAssets.count, 0)
        XCTAssertFalse(viewModel.canUndo)
        XCTAssertTrue(viewModel.canRedo)
    }

    // MARK: - Redo Tests

    /// Test that redo reapplies an undone action
    func testRedoAfterUndo() {
        let photoItem = PhotoAssetItem.testItem(id: "test-photo-1")
        viewModel.photos = [photoItem]
        viewModel.currentIndex = 0

        // Perform action (delete requires confirmation)
        viewModel.performSwipe(direction: .left)
        viewModel.confirmDelete()
        let countAfterSwipe = viewModel.leftActionCount

        // Undo
        viewModel.undo()
        let countAfterUndo = viewModel.leftActionCount

        // Redo
        viewModel.redo()
        let countAfterRedo = viewModel.leftActionCount

        // Verify redo restored the state
        XCTAssertEqual(countAfterSwipe, 1)
        XCTAssertEqual(countAfterUndo, 0)
        XCTAssertEqual(countAfterRedo, 1)
        XCTAssertTrue(viewModel.canUndo)
        XCTAssertFalse(viewModel.canRedo)
    }

    // MARK: - Undo/Redo Stack Tests

    /// Test that new swipes clear the redo stack
    func testNewSwipeClearsRedoStack() {
        let photoItem1 = PhotoAssetItem.testItem(id: "test-photo-1")
        let photoItem2 = PhotoAssetItem.testItem(id: "test-photo-2")
        let photoItem3 = PhotoAssetItem.testItem(id: "test-photo-3")
        viewModel.photos = [photoItem1, photoItem2, photoItem3]
        viewModel.currentIndex = 0

        // Perform a right swipe (keep - no confirmation), then undo
        viewModel.performSwipe(direction: .right)
        XCTAssertEqual(viewModel.rightActionCount, 1)
        XCTAssertTrue(viewModel.canUndo)

        viewModel.undo()
        XCTAssertEqual(viewModel.rightActionCount, 0)
        XCTAssertTrue(viewModel.canRedo)

        // New action should clear redo stack
        // After undo, currentIndex was advanced by swipe but undo doesn't revert it
        // So we're now at index 1
        viewModel.performSwipe(direction: .right)

        // Redo should no longer be available (new action cleared it)
        XCTAssertFalse(viewModel.canRedo)
        XCTAssertEqual(viewModel.rightActionCount, 1)
    }

    /// Test that undo on empty stack does nothing
    func testUndoOnEmptyStackIsNoOp() {
        // Attempting to undo with empty stack should not crash
        viewModel.undo()

        // Verify no change
        XCTAssertEqual(viewModel.leftActionCount, 0)
        XCTAssertEqual(viewModel.rightActionCount, 0)
        XCTAssertFalse(viewModel.canUndo)
    }

    /// Test that redo on empty stack does nothing
    func testRedoOnEmptyStackIsNoOp() {
        // Attempting to redo with empty stack should not crash
        viewModel.redo()

        // Verify no change
        XCTAssertEqual(viewModel.leftActionCount, 0)
        XCTAssertEqual(viewModel.rightActionCount, 0)
        XCTAssertFalse(viewModel.canRedo)
    }

    // MARK: - Multiple Action Tests

    /// Test undo/redo with multiple sequential actions
    /// Uses right swipes (keep) to avoid delete confirmation dialog complexity
    func testMultipleUndoRedo() {
        let photoItem1 = PhotoAssetItem.testItem(id: "test-photo-1")
        let photoItem2 = PhotoAssetItem.testItem(id: "test-photo-2")
        let photoItem3 = PhotoAssetItem.testItem(id: "test-photo-3")
        let photoItem4 = PhotoAssetItem.testItem(id: "test-photo-4")
        viewModel.photos = [photoItem1, photoItem2, photoItem3, photoItem4]

        // Perform three right swipes (keep - no confirmation needed)
        viewModel.currentIndex = 0
        viewModel.performSwipe(direction: .right)  // Keep 1 - advances to index 1
        viewModel.performSwipe(direction: .right)  // Keep 2 - advances to index 2
        viewModel.performSwipe(direction: .right)  // Keep 3 - advances to index 3

        // Verify state
        XCTAssertEqual(viewModel.rightActionCount, 3)
        XCTAssertEqual(viewModel.keptAssets.count, 3)
        XCTAssertTrue(viewModel.canUndo)

        // Undo all three
        viewModel.undo()
        XCTAssertEqual(viewModel.rightActionCount, 2)
        viewModel.undo()
        XCTAssertEqual(viewModel.rightActionCount, 1)
        viewModel.undo()
        XCTAssertEqual(viewModel.rightActionCount, 0)

        // Verify all undone
        XCTAssertEqual(viewModel.rightActionCount, 0)
        XCTAssertEqual(viewModel.keptAssets.count, 0)
        XCTAssertFalse(viewModel.canUndo)
        XCTAssertTrue(viewModel.canRedo)

        // Redo all three
        viewModel.redo()
        XCTAssertEqual(viewModel.rightActionCount, 1)
        viewModel.redo()
        XCTAssertEqual(viewModel.rightActionCount, 2)
        viewModel.redo()
        XCTAssertEqual(viewModel.rightActionCount, 3)

        // Verify all redone
        XCTAssertEqual(viewModel.rightActionCount, 3)
        XCTAssertEqual(viewModel.keptAssets.count, 3)
        XCTAssertTrue(viewModel.canUndo)
        XCTAssertFalse(viewModel.canRedo)
    }
}
