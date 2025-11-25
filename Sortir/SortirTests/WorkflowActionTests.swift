import XCTest
@testable import Sortir

/// Tests for WorkflowAction model and ActionType enum
@MainActor
final class WorkflowActionTests: XCTestCase {

    // MARK: - ActionType Tests

    /// Test that delete action has correct properties
    func testDeleteActionProperties() {
        let action = WorkflowAction.delete()
        XCTAssertEqual(action.type, .delete)
        XCTAssertEqual(action.displayName, "Delete")
        XCTAssertEqual(action.icon, "trash.fill")
        XCTAssertEqual(action.color, .red)
    }

    /// Test that keep action has correct properties
    func testKeepActionProperties() {
        let action = WorkflowAction.keep()
        XCTAssertEqual(action.type, .keep)
        XCTAssertEqual(action.displayName, "Keep")
        XCTAssertEqual(action.icon, "checkmark.circle.fill")
        XCTAssertEqual(action.color, .green)
    }

    // MARK: - Workflow Tests

    /// Test creating a test workflow
    func testCreateTestWorkflow() {
        let workflow = Workflow.testWorkflow()
        XCTAssertEqual(workflow.name, "Test Workflow")
        XCTAssertEqual(workflow.leftAction.type, .delete)
        XCTAssertEqual(workflow.rightAction.type, .keep)
    }

    /// Test workflow ID is unique
    func testWorkflowUniqueId() {
        let workflow1 = Workflow.testWorkflow()
        let workflow2 = Workflow.testWorkflow()
        XCTAssertNotEqual(workflow1.id, workflow2.id)
    }

    // MARK: - SwipeDirection Tests

    /// Test SwipeDirection enum values
    func testSwipeDirectionValues() {
        let left = SwipeDirection.left
        let right = SwipeDirection.right

        // Verify they are distinct
        switch left {
        case .left:
            XCTAssert(true)
        case .right:
            XCTFail("Expected .left")
        }

        switch right {
        case .right:
            XCTAssert(true)
        case .left:
            XCTFail("Expected .right")
        }
    }
}
