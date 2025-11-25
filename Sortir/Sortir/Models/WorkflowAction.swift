import SwiftUI

// MARK: - Action Type Enum

enum ActionType: String, Codable, CaseIterable {
    case keep           // Add to "kept" album (default destination)
    case delete         // Mark for deletion
    case moveToAlbum    // Move to specific user-selected album
    case favorite       // Add to favorites
    case skip           // Skip without action

    var displayName: String {
        switch self {
        case .keep: return "Keep"
        case .delete: return "Delete"
        case .moveToAlbum: return "Move to Album"
        case .favorite: return "Favorite"
        case .skip: return "Skip"
        }
    }

    var icon: String {
        switch self {
        case .keep: return "checkmark.circle.fill"
        case .delete: return "trash.fill"
        case .moveToAlbum: return "folder.fill"
        case .favorite: return "heart.fill"
        case .skip: return "forward.fill"
        }
    }

    var color: Color {
        switch self {
        case .keep: return .green
        case .delete: return .red
        case .moveToAlbum: return .blue
        case .favorite: return .pink
        case .skip: return .gray
        }
    }

    var requiresAlbum: Bool {
        self == .moveToAlbum
    }
}

// MARK: - Workflow Action (Codable)

struct WorkflowAction: Codable, Equatable {
    let type: ActionType
    let albumId: String?      // PHAssetCollection localIdentifier (for moveToAlbum)
    let albumName: String?    // Display name for the album

    // Computed properties for display
    var displayName: String {
        if type == .moveToAlbum, let name = albumName {
            return name
        }
        return type.displayName
    }

    var icon: String {
        type.icon
    }

    var color: Color {
        type.color
    }

    // Convenience initializers
    static func keep() -> WorkflowAction {
        WorkflowAction(type: .keep, albumId: nil, albumName: nil)
    }

    static func delete() -> WorkflowAction {
        WorkflowAction(type: .delete, albumId: nil, albumName: nil)
    }

    static func favorite() -> WorkflowAction {
        WorkflowAction(type: .favorite, albumId: nil, albumName: nil)
    }

    static func skip() -> WorkflowAction {
        WorkflowAction(type: .skip, albumId: nil, albumName: nil)
    }

    static func moveToAlbum(id: String, name: String) -> WorkflowAction {
        WorkflowAction(type: .moveToAlbum, albumId: id, albumName: name)
    }
}

// MARK: - Workflow Model (Swift struct for use in views)

struct Workflow: Identifiable, Equatable {
    let id: UUID
    var name: String
    var leftAction: WorkflowAction
    var rightAction: WorkflowAction
    var createdAt: Date
    var lastUsedAt: Date?

    // Default "Quick Sort" workflow
    static func quickSort() -> Workflow {
        Workflow(
            id: UUID(),
            name: "Quick Sort",
            leftAction: .delete(),
            rightAction: .keep(),
            createdAt: Date(),
            lastUsedAt: nil
        )
    }

    // Encode actions for CoreData storage
    var leftActionData: Data? {
        try? JSONEncoder().encode(leftAction)
    }

    var rightActionData: Data? {
        try? JSONEncoder().encode(rightAction)
    }

    // Initialize from CoreData entity
    init(from entity: WorkflowEntity) {
        self.id = entity.id ?? UUID()
        self.name = entity.name ?? "Untitled"
        self.createdAt = entity.createdAt ?? Date()
        self.lastUsedAt = entity.lastUsedAt

        // Decode left action
        if let data = entity.leftActionData {
            self.leftAction = (try? JSONDecoder().decode(WorkflowAction.self, from: data)) ?? .delete()
        } else {
            self.leftAction = .delete()
        }

        // Decode right action
        if let data = entity.rightActionData {
            self.rightAction = (try? JSONDecoder().decode(WorkflowAction.self, from: data)) ?? .keep()
        } else {
            self.rightAction = .keep()
        }
    }

    // Standard initializer
    init(id: UUID, name: String, leftAction: WorkflowAction, rightAction: WorkflowAction, createdAt: Date, lastUsedAt: Date?) {
        self.id = id
        self.name = name
        self.leftAction = leftAction
        self.rightAction = rightAction
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
    }
}
