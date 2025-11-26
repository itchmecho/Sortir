import Foundation

/// Generates cheeky completion messages based on swipe session results
struct SessionMessageGenerator {
    /// Generates a message tuple with title and subtitle based on session results
    /// - Parameters:
    ///   - leftCount: Number of items with left action
    ///   - rightCount: Number of items with right action
    ///   - leftAction: WorkflowAction for left swipe
    ///   - rightAction: WorkflowAction for right swipe
    /// - Returns: Tuple of (title, subtitle) for display
    static func generateMessage(
        leftCount: Int,
        rightCount: Int,
        leftAction: WorkflowAction,
        rightAction: WorkflowAction
    ) -> (title: String, subtitle: String) {
        let total = leftCount + rightCount
        let leftType = leftAction.type
        let rightType = rightAction.type

        // Check for delete ratio patterns
        if leftType == .delete || rightType == .delete {
            let deleteCount = leftType == .delete ? leftCount : rightCount
            let keepCount = leftType == .delete ? rightCount : leftCount

            if deleteCount == 0 {
                return ("Sentimental, huh?", "You kept everything. No judgment... okay, maybe a little.")
            } else if keepCount == 0 {
                return ("Scorched Earth!", "You deleted everything. Ruthless. We respect it.")
            }

            let deleteRatio = total > 0 ? Double(deleteCount) / Double(total) : 0
            if deleteRatio > 0.8 {
                return ("Marie Kondo Mode", "Those photos did NOT spark joy.")
            } else if deleteRatio > 0.5 {
                return ("Balanced, as all things should be", "Thanos would be proud of your decisiveness.")
            } else if deleteRatio < 0.2 {
                return ("The Collector", "Keeping the memories alive! All of them. Every. Single. One.")
            }
        }

        // If sorting into albums
        if leftType == .moveToAlbum || rightType == .moveToAlbum {
            return ("Organized!", "Your albums are looking fresh.")
        }

        // If favoriting
        if leftType == .favorite || rightType == .favorite {
            let favoriteCount = leftType == .favorite ? leftCount : rightCount
            if favoriteCount > total / 2 {
                return ("Favorites Overload!", "You really love your photos.")
            }
        }

        // Generic messages - used when no specific pattern matches
        let messages = [
            ("Nice work!", "Your camera roll thanks you."),
            ("Swipe game strong!", "That was satisfying, wasn't it?"),
            ("All done!", "Time well spent. Probably."),
            ("Photos: Sorted", "You're basically a professional organizer now."),
            ("Boom. Done.", "Your storage space sends its regards.")
        ]
        return messages.randomElement() ?? messages[0]
    }
}
