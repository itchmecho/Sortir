import SwiftUI

enum SwipeAction: String {
    case keep
    case delete

    var displayName: String {
        switch self {
        case .keep: return "Keep"
        case .delete: return "Delete"
        }
    }

    var icon: String {
        switch self {
        case .keep: return "checkmark.circle.fill"
        case .delete: return "trash.fill"
        }
    }

    var color: Color {
        switch self {
        case .keep: return .green
        case .delete: return .red
        }
    }
}
