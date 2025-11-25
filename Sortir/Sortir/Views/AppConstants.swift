import Foundation
import CoreGraphics
import UIKit

// MARK: - Swipe Configuration
/// Constants controlling swipe gesture behavior and feedback
struct SwipeConstants {
    /// Distance in points required to complete a swipe gesture
    static let threshold: CGFloat = 100

    /// Window around threshold where haptic feedback is triggered (threshold ± this value)
    static let thresholdWindow: CGFloat = 10

    /// Rotation multiplier for drag gesture visual feedback
    static let rotationMultiplier: Double = 0.05

    /// Distance threshold for showing swipe direction indicators
    static let indicatorVisibilityOffset: CGFloat = 30

    /// Spring animation response time for swipe animations
    static let springResponse: Double = 0.3

    /// Spring animation damping fraction for smooth motion
    static let springDamping: Double = 0.6
}

// MARK: - Image Cache Configuration
/// Constants for photo caching and image loading
struct CacheConstants {
    /// Size for thumbnail images shown during swipe session
    static let thumbnailSize = CGSize(width: 400, height: 600)

    /// Size for full resolution cached images
    static let cacheSize = CGSize(width: 800, height: 1200)

    /// Maximum number of photos to keep in memory cache
    static let maxCachedAssets = 20

    /// Number of photos to preload before current position
    static let cachePaddingBefore = 2

    /// Number of photos to preload after current position
    /// (maxCachedAssets - 3 to account for current + padding before)
    static let cachePaddingAfter = maxCachedAssets - 3

    /// Number of photos away from current to stop caching
    static let stopCachingBuffer = 5
}

// MARK: - Album Names
/// Constants for album naming
struct AlbumConstants {
    /// Default album name for photos the user chooses to keep
    static let defaultKeepAlbumName = "Sortir Kept"
}

// MARK: - UI Strings
/// User-facing strings for UI elements
struct UIStrings {
    /// Progress message shown while organizing photos after session
    static let organizingPhotos = "Organizing your photos..."

    /// Loading message shown when initially loading photo library
    static let loadingPhotos = "Loading photos..."

    /// Message shown when no photos are available
    static let noPhotosFound = "No photos found"
}

// MARK: - Timing Constants
/// Timing values for various operations
struct TimingConstants {
    /// Wait time for album creation operations to complete (in nanoseconds)
    /// Used to prevent race conditions when multiple album creation attempts occur
    static let albumCreationWaitTime: UInt64 = 100_000_000 // 100ms
}

// MARK: - App Version
/// Application version information
struct AppVersion {
    /// Current semantic version of the app
    static let current = "0.2.1"

    /// Current build number
    static let build = "1"

    /// Current development milestone
    static let milestone = "Milestone 3 P2"
}
