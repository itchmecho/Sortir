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

@MainActor
class SwipeViewModel: ObservableObject {
    @Published var photos: [PhotoAssetItem] = []
    @Published var currentIndex = 0
    @Published var dragOffset: CGSize = .zero
    @Published var dragRotation: Double = 0
    @Published var isLoading = true
    @Published var isProcessing = false
    @Published var errorMessage: String?
    @Published var canUndo = false
    @Published var canRedo = false
    @Published var showDeleteConfirmation = false
    @Published var pendingDeleteAction: WorkflowAction?

    // Workflow
    var workflow: Workflow?

    // Assets grouped by action type
    var keptAssets: [PHAsset] = []
    var deletedAssets: [PHAsset] = []
    var favoritedAssets: [PHAsset] = []
    var albumAssets: [String: [PHAsset]] = [:] // albumId -> assets

    // Session tracking
    var sessionId: UUID?

    // Action counts for summary
    var leftActionCount: Int = 0
    var rightActionCount: Int = 0

    // Undo/Redo history
    private var undoStack: [SwipeAction] = []
    private var redoStack: [SwipeAction] = []

    private let photosService = PhotosService.shared
    private let coreDataService = CoreDataService.shared

    // Haptic feedback generators
    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let notificationFeedback = UINotificationFeedbackGenerator()

    // MARK: - Lifecycle
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
    func onDragChanged(_ value: DragGesture.Value) {
        dragOffset = value.translation
        dragRotation = Double(value.translation.width) * SwipeConstants.rotationMultiplier

        // Light haptic feedback when crossing threshold
        let distance = abs(value.translation.width)
        if distance > SwipeConstants.threshold - SwipeConstants.thresholdWindow && distance < SwipeConstants.threshold + SwipeConstants.thresholdWindow {
            selectionFeedback.selectionChanged()
        }
    }

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
            // Handle "Keep" action - add to "Sortir Kept" album
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

    func undo() {
        guard !undoStack.isEmpty else { return }

        let lastAction = undoStack.removeLast()
        redoStack.append(lastAction)
        reverseAction(lastAction)
        updateUndoRedoState()
    }

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
