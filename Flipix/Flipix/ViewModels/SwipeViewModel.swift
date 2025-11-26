import SwiftUI
import Photos
import UIKit

enum SwipeDirection {
    case left
    case right
}

// MARK: - Action History for Undo/Redo
struct SwipeAction {
    let photoId: String
    let direction: SwipeDirection
    let action: WorkflowAction
}

/// Manages the swipe session workflow for photo organization
///
/// SwipeViewModel handles:
/// - Loading and preloading photos from the device photo library
/// - Gesture recognition and swipe direction detection
/// - Processing swipes based on configured workflow actions
/// - Managing asset collections (keep, delete, favorite, move to album)
/// - Undo/redo functionality for in-session changes
/// - Applying changes to the Photos app upon session completion
/// - Haptic feedback for user actions
/// - CoreData persistence of session results
///
/// The view model is MainActor-bound to ensure all UI updates occur on the main thread.
/// It uses PHCachingImageManager for efficient memory management with large photo libraries.
@MainActor
class SwipeViewModel: ObservableObject {
    // MARK: - Published Properties (UI Bindings)

    /// The current set of photos loaded from the device
    @Published var photos: [PhotoAssetItem] = []
    /// Index of the photo currently being swiped
    @Published var currentIndex = 0
    /// Current drag translation during an active swipe gesture
    @Published var dragOffset: CGSize = .zero
    /// Current rotation applied to photo card during swipe
    @Published var dragRotation: Double = 0
    /// True while initial photo library is being fetched
    @Published var isLoading = true
    /// True while changes are being applied to Photos app
    @Published var isProcessing = false
    /// Error message if a Photo library operation fails
    @Published var errorMessage: String?
    /// True if there are actions to undo
    @Published var canUndo = false
    /// True if there are actions to redo
    @Published var canRedo = false
    /// True when showing delete confirmation dialog
    @Published var showDeleteConfirmation = false
    /// The delete action awaiting user confirmation
    @Published var pendingDeleteAction: WorkflowAction?

    // MARK: - Workflow Configuration

    /// The workflow defining left/right action types for this session
    var workflow: Workflow?

    // MARK: - Asset Collections

    /// Photos marked for the "right action" (typically keep/favorite)
    var keptAssets: [PHAsset] = []
    /// Photos marked for the "left action" (typically delete)
    var deletedAssets: [PHAsset] = []
    /// Photos marked as favorite
    var favoritedAssets: [PHAsset] = []
    /// Photos to move to specific albums, keyed by album ID
    var albumAssets: [String: [PHAsset]] = [:]

    // MARK: - Session Tracking

    /// Unique identifier for the current session
    var sessionId: UUID?

    // MARK: - Action Counters

    /// Total number of left swipes/actions performed
    var leftActionCount: Int = 0
    /// Total number of right swipes/actions performed
    var rightActionCount: Int = 0

    // MARK: - Private Properties

    /// Stack-based undo history; stores all user actions in order
    private var undoStack: [SwipeAction] = []
    /// Stack-based redo history; stores undone actions
    private var redoStack: [SwipeAction] = []

    /// Photos service for library access (injected for testability)
    private let photosService: PhotosService
    /// CoreData service for persistence (injected for testability)
    private let coreDataService: CoreDataService

    /// Haptic feedback for swipe completion
    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    /// Haptic feedback for threshold crossing
    private let selectionFeedback = UISelectionFeedbackGenerator()
    /// Haptic feedback for session completion or errors
    private let notificationFeedback = UINotificationFeedbackGenerator()

    // MARK: - Initialization

    /// Initializes the SwipeViewModel with optional dependency injection
    /// - Parameters:
    ///   - photosService: PhotosService instance (defaults to shared instance for production)
    ///   - coreDataService: CoreDataService instance (defaults to shared instance for production)
    init(
        photosService: PhotosService = PhotosService.shared,
        coreDataService: CoreDataService = CoreDataService.shared
    ) {
        self.photosService = photosService
        self.coreDataService = coreDataService
    }

    // MARK: - Lifecycle

    /// Loads all photos from the device library and initializes the session
    ///
    /// - Creates PhotoAssetItems for each photo without loading images yet
    /// - Starts a CoreData session record
    /// - Begins preloading and caching images for smooth scrolling
    func loadPhotos() async {
        isLoading = true
        let assets = photosService.fetchAllPhotos()

        // Create empty PhotoAssetItems without loading images yet
        var items: [PhotoAssetItem] = []
        for asset in assets {
            items.append(PhotoAssetItem(asset: asset))
        }

        await MainActor.run {
            self.photos = items
            self.isLoading = false

            if !items.isEmpty {
                self.sessionId = self.coreDataService.startSession(
                    totalPhotos: items.count,
                    workflowId: workflow?.id
                )

                // Update workflow last used
                if let workflowId = workflow?.id {
                    coreDataService.updateWorkflowLastUsed(id: workflowId)
                }

                // Start loading images for current and next photos
                self.preloadCurrentAndNextPhotos()
                // Start caching images around current position
                self.photosService.startCachingImages(around: assets, centerIndex: 0)
            }
        }
    }

    // Preload images for current and next photo
    private func preloadCurrentAndNextPhotos() {
        Task {
            if currentIndex < photos.count {
                // Load current photo
                if photos[currentIndex].image == nil {
                    let image = await photosService.loadImage(for: photos[currentIndex].asset)
                    await MainActor.run {
                        photos[currentIndex].image = image
                    }
                }

                // Load next photo
                if currentIndex + 1 < photos.count, photos[currentIndex + 1].image == nil {
                    let image = await photosService.loadImage(for: photos[currentIndex + 1].asset)
                    await MainActor.run {
                        photos[currentIndex + 1].image = image
                    }
                }
            }
        }
    }

    // MARK: - Gestures

    /// Responds to ongoing drag gesture movement
    /// - Updates card offset and rotation based on drag translation
    /// - Provides haptic feedback when user approaches swipe threshold
    func onDragChanged(_ value: DragGesture.Value) {
        dragOffset = value.translation
        dragRotation = Double(value.translation.width) * SwipeConstants.rotationMultiplier

        // Light haptic feedback when crossing threshold
        let distance = abs(value.translation.width)
        if distance > SwipeConstants.threshold - SwipeConstants.thresholdWindow && distance < SwipeConstants.threshold + SwipeConstants.thresholdWindow {
            selectionFeedback.selectionChanged()
        }
    }

    /// Responds to the end of a drag gesture
    /// - If swipe threshold is met, processes the swipe in the detected direction
    /// - Otherwise, animates the card back to center
    func onDragEnded(_ value: DragGesture.Value) async {
        let isSwipeComplete = abs(value.translation.width) >= SwipeConstants.threshold

        if isSwipeComplete {
            let direction: SwipeDirection = value.translation.width > 0 ? .right : .left
            // Strong haptic feedback on successful swipe
            impactFeedback.impactOccurred()
            processSwipe(direction: direction)
        } else {
            // Snap back
            withAnimation(.spring(response: SwipeConstants.springResponse, dampingFraction: SwipeConstants.springDamping)) {
                dragOffset = .zero
                dragRotation = 0
            }
        }
    }

    // MARK: - Button Actions

    /// Processes a swipe triggered by a button tap rather than gesture
    /// - Provides haptic feedback
    /// - Processes swipe through standard flow
    func performSwipe(direction: SwipeDirection) {
        // Haptic feedback for button tap
        impactFeedback.impactOccurred()
        processSwipe(direction: direction)
    }

    // MARK: - Swipe Processing
    private func processSwipe(direction: SwipeDirection) {
        let action = direction == .right ? workflow?.rightAction : workflow?.leftAction

        // Check if this is a delete action - show confirmation
        if let action = action, action.type == .delete {
            pendingDeleteAction = action
            showDeleteConfirmation = true
            // Don't proceed with the swipe until user confirms
            return
        }

        // Proceed with normal swipe processing
        completeSwipe(direction: direction)
    }

    func confirmDelete() {
        guard let currentAction = pendingDeleteAction else { return }

        let currentPhoto = photos[currentIndex]
        let leftIsDelete = workflow?.leftAction.type == .delete
        let direction: SwipeDirection = leftIsDelete == true ? .left : .right

        // Record action to undo stack
        let swipeAction = SwipeAction(photoId: currentPhoto.id, direction: direction, action: currentAction)
        undoStack.append(swipeAction)
        redoStack.removeAll()
        updateUndoRedoState()

        // Track count
        if direction == .left {
            leftActionCount += 1
        } else {
            rightActionCount += 1
        }

        // Save to CoreData
        if let sessionId = sessionId {
            coreDataService.saveResult(
                assetId: currentPhoto.id,
                direction: direction == .right ? "right" : "left",
                action: currentAction.type.rawValue,
                sessionId: sessionId
            )
        }

        // Add asset to delete collection
        deletedAssets.append(currentPhoto.asset)

        // Advance to next photo
        advanceToNextPhoto()

        // Clear confirmation state
        showDeleteConfirmation = false
        pendingDeleteAction = nil
    }

    func cancelDelete() {
        showDeleteConfirmation = false
        pendingDeleteAction = nil
        // Snap back animation is already handled
    }

    private func completeSwipe(direction: SwipeDirection) {
        let currentPhoto = photos[currentIndex]
        let action = direction == .right ? workflow?.rightAction : workflow?.leftAction

        // Record action to undo stack
        if let action = action {
            let swipeAction = SwipeAction(photoId: currentPhoto.id, direction: direction, action: action)
            undoStack.append(swipeAction)
            redoStack.removeAll()  // Clear redo when making new action
            updateUndoRedoState()
        }

        // Track count
        if direction == .left {
            leftActionCount += 1
        } else {
            rightActionCount += 1
        }

        // Save to CoreData
        if let sessionId = sessionId {
            coreDataService.saveResult(
                assetId: currentPhoto.id,
                direction: direction == .right ? "right" : "left",
                action: action?.type.rawValue ?? "unknown",
                sessionId: sessionId
            )
        }

        // Add asset to appropriate collection based on action type
        if let action = action {
            categorizeAsset(currentPhoto.asset, for: action)
        } else {
            // Fallback to legacy behavior if no workflow
            if direction == .right {
                keptAssets.append(currentPhoto.asset)
            } else {
                deletedAssets.append(currentPhoto.asset)
            }
        }

        // Advance to next photo
        advanceToNextPhoto()
    }

    private func advanceToNextPhoto() {
        // Advance to next photo
        if currentIndex < photos.count - 1 {
            currentIndex += 1
            dragOffset = .zero
            dragRotation = 0

            // Preload next images and manage cache
            preloadCurrentAndNextPhotos()
            let assets = photosService.fetchAllPhotos()
            photosService.startCachingImages(around: assets, centerIndex: currentIndex)
        } else {
            // Session complete
            currentIndex = photos.count
            finishSession()
        }
    }

    private func categorizeAsset(_ asset: PHAsset, for action: WorkflowAction) {
        switch action.type {
        case .keep:
            keptAssets.append(asset)
        case .delete:
            deletedAssets.append(asset)
        case .favorite:
            favoritedAssets.append(asset)
        case .moveToAlbum:
            if let albumId = action.albumId {
                if albumAssets[albumId] == nil {
                    albumAssets[albumId] = []
                }
                albumAssets[albumId]?.append(asset)
            }
        case .skip:
            // Do nothing - skip the photo
            break
        }
    }

    // MARK: - Session
    func finishSession() {
        Task {
            await finishSessionAsync()
        }
    }

    private func finishSessionAsync() async {
        // Mark session as ended in CoreData first
        if let sessionId = sessionId {
            coreDataService.endSession(sessionId: sessionId)
        }

        // Apply changes to Photos app and wait for completion
        await applyChangesToPhotosApp()

        // Clean up cache after session
        photosService.stopCachingAllImages()

        // Success haptic feedback
        notificationFeedback.notificationOccurred(.success)
    }

    // MARK: - Photos App Integration
    private func applyChangesToPhotosApp() async {
        await MainActor.run {
            self.isProcessing = true
            self.errorMessage = nil
        }

        do {
            // Handle "Keep" action - add to "Flipix Kept" album
            if !keptAssets.isEmpty {
                if let album = try await photosService.createKeepAlbum() {
                    try await photosService.moveToAlbum(assets: keptAssets, album: album)
                }
            }

            // Handle "Move to Album" actions - add to specific albums
            for (albumId, assets) in albumAssets {
                if !assets.isEmpty, let album = photosService.findAlbum(byId: albumId) {
                    try await photosService.moveToAlbum(assets: assets, album: album)
                }
            }

            // Handle "Favorite" action
            if !favoritedAssets.isEmpty {
                try await photosService.setFavorite(favoritedAssets, isFavorite: true)
            }

            // Handle "Delete" action - must be last since it removes photos
            if !deletedAssets.isEmpty {
                try await photosService.deleteAssets(deletedAssets)
            }

            // Success
            await MainActor.run {
                self.isProcessing = false
            }
        } catch {
            // Error haptic feedback
            notificationFeedback.notificationOccurred(.error)
            await MainActor.run {
                self.isProcessing = false
                self.errorMessage = "Error organizing photos: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Undo/Redo

    /// Reverts the most recent swipe action
    /// - Removes the action from undo stack and adds it to redo stack
    /// - Removes the affected asset from its collection
    /// - Decrements the action counter
    func undo() {
        guard !undoStack.isEmpty else { return }

        let lastAction = undoStack.removeLast()
        redoStack.append(lastAction)
        reverseAction(lastAction)
        updateUndoRedoState()
    }

    /// Reapplies the most recently undone swipe action
    /// - Removes the action from redo stack and adds it to undo stack
    /// - Re-adds the affected asset to its collection
    /// - Increments the action counter
    func redo() {
        guard !redoStack.isEmpty else { return }

        let action = redoStack.removeLast()
        undoStack.append(action)
        reapplyAction(action)
        updateUndoRedoState()
    }

    private func reverseAction(_ action: SwipeAction) {
        // Find the asset and remove it from the appropriate collection
        let asset = photos.first(where: { $0.id == action.photoId })?.asset

        switch action.action.type {
        case .keep:
            if let index = keptAssets.firstIndex(where: { $0.localIdentifier == asset?.localIdentifier }) {
                keptAssets.remove(at: index)
            }
        case .delete:
            if let index = deletedAssets.firstIndex(where: { $0.localIdentifier == asset?.localIdentifier }) {
                deletedAssets.remove(at: index)
            }
        case .favorite:
            if let index = favoritedAssets.firstIndex(where: { $0.localIdentifier == asset?.localIdentifier }) {
                favoritedAssets.remove(at: index)
            }
        case .moveToAlbum:
            if let albumId = action.action.albumId {
                if let index = albumAssets[albumId]?.firstIndex(where: { $0.localIdentifier == asset?.localIdentifier }) {
                    albumAssets[albumId]?.remove(at: index)
                }
            }
        case .skip:
            break
        }

        // Decrement action count based on direction
        if action.direction == .left {
            leftActionCount = max(0, leftActionCount - 1)
        } else {
            rightActionCount = max(0, rightActionCount - 1)
        }
    }

    private func reapplyAction(_ action: SwipeAction) {
        // Find the asset and re-add it to the appropriate collection
        if let asset = photos.first(where: { $0.id == action.photoId })?.asset {
            categorizeAsset(asset, for: action.action)

            // Increment action count based on direction
            if action.direction == .left {
                leftActionCount += 1
            } else {
                rightActionCount += 1
            }
        }
    }

    private func updateUndoRedoState() {
        canUndo = !undoStack.isEmpty
        canRedo = !redoStack.isEmpty
    }

    // MARK: - Summary Helpers

    var leftAction: WorkflowAction? {
        workflow?.leftAction
    }

    var rightAction: WorkflowAction? {
        workflow?.rightAction
    }
}
