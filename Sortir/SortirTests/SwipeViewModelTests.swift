import XCTest
import Photos
@testable import Sortir

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
        // Create a mock asset
        let photoItem = PhotoAssetItem(asset: PHAsset())
        viewModel.photos = [photoItem]
        viewModel.currentIndex = 0

        // Perform a left swipe (delete action)
        viewModel.performSwipe(direction: .left)

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
        // Create a mock asset
        let photoItem = PhotoAssetItem(asset: PHAsset())
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
        let photoItem = PhotoAssetItem(asset: PHAsset())
        viewModel.photos = [photoItem]
        viewModel.currentIndex = 0

        // Perform action
        viewModel.performSwipe(direction: .left)
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
        let photoItem1 = PhotoAssetItem(asset: PHAsset())
        let photoItem2 = PhotoAssetItem(asset: PHAsset())
        viewModel.photos = [photoItem1, photoItem2]
        viewModel.currentIndex = 0

        // Perform, undo, then perform a new action
        viewModel.performSwipe(direction: .left)
        viewModel.undo()
        XCTAssertTrue(viewModel.canRedo)

        // New action should clear redo stack
        viewModel.currentIndex = 1  // Move to next item to test
        viewModel.performSwipe(direction: .right)

        // Redo should no longer be available
        XCTAssertFalse(viewModel.canRedo)
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
    func testMultipleUndoRedo() {
        let photoItem1 = PhotoAssetItem(asset: PHAsset())
        let photoItem2 = PhotoAssetItem(asset: PHAsset())
        let photoItem3 = PhotoAssetItem(asset: PHAsset())
        viewModel.photos = [photoItem1, photoItem2, photoItem3]

        // Perform three actions
        viewModel.currentIndex = 0
        viewModel.performSwipe(direction: .left)  // Delete 1
        viewModel.currentIndex = 1
        viewModel.performSwipe(direction: .right)  // Keep 1
        viewModel.currentIndex = 2
        viewModel.performSwipe(direction: .left)  // Delete 1

        // Verify state
        XCTAssertEqual(viewModel.leftActionCount, 2)
        XCTAssertEqual(viewModel.rightActionCount, 1)

        // Undo all three
        viewModel.undo()
        viewModel.undo()
        viewModel.undo()

        // Verify all undone
        XCTAssertEqual(viewModel.leftActionCount, 0)
        XCTAssertEqual(viewModel.rightActionCount, 0)

        // Redo all three
        viewModel.redo()
        viewModel.redo()
        viewModel.redo()

        // Verify all redone
        XCTAssertEqual(viewModel.leftActionCount, 2)
        XCTAssertEqual(viewModel.rightActionCount, 1)
    }
}
