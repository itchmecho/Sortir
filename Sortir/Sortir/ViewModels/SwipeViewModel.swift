import SwiftUI
import Photos

enum SwipeDirection {
    case left
    case right
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

    private let photosService = PhotosService.shared
    private let coreDataService = CoreDataService.shared

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
        dragRotation = Double(value.translation.width) * 0.05
    }

    func onDragEnded(_ value: DragGesture.Value) async {
        let threshold: CGFloat = 100
        let isSwipeComplete = abs(value.translation.width) >= threshold

        if isSwipeComplete {
            let direction: SwipeDirection = value.translation.width > 0 ? .right : .left
            processSwipe(direction: direction)
        } else {
            // Snap back
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                dragOffset = .zero
                dragRotation = 0
            }
        }
    }

    // MARK: - Button Actions
    func performSwipe(direction: SwipeDirection) {
        processSwipe(direction: direction)
    }

    // MARK: - Swipe Processing
    private func processSwipe(direction: SwipeDirection) {
        let currentPhoto = photos[currentIndex]
        let action = direction == .right ? workflow?.rightAction : workflow?.leftAction

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
            await MainActor.run {
                self.isProcessing = false
                self.errorMessage = "Error organizing photos: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Summary Helpers

    var leftAction: WorkflowAction? {
        workflow?.leftAction
    }

    var rightAction: WorkflowAction? {
        workflow?.rightAction
    }
}
