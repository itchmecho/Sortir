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
    @Published var errorMessage: String?

    var keptAssets: [PHAsset] = []
    var deletedAssets: [PHAsset] = []
    var sessionId: UUID?

    private let photosService = PhotosService.shared
    private let coreDataService = CoreDataService.shared

    // MARK: - Lifecycle
    func loadPhotos() async {
        isLoading = true
        let assets = photosService.fetchAllPhotos()

        var items: [PhotoAssetItem] = []
        for asset in assets {
            var item = PhotoAssetItem(asset: asset)
            item.image = await photosService.loadImage(for: asset)
            items.append(item)
        }

        await MainActor.run {
            self.photos = items
            self.isLoading = false

            if !items.isEmpty {
                self.sessionId = self.coreDataService.startSession(totalPhotos: items.count)
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
            let direction = value.translation.width > 0 ? "right" : "left"
            let action = direction == "right" ? "keep" : "delete"

            if let sessionId = sessionId {
                let currentPhoto = photos[currentIndex]
                coreDataService.saveResult(
                    assetId: currentPhoto.id,
                    direction: direction,
                    action: action,
                    sessionId: sessionId
                )
            }

            if direction == "right" {
                keptAssets.append(photos[currentIndex].asset)
            } else {
                deletedAssets.append(photos[currentIndex].asset)
            }

            // Advance to next photo
            if currentIndex < photos.count - 1 {
                currentIndex += 1
                dragOffset = .zero
                dragRotation = 0
            } else {
                // Session complete - move past last photo to trigger completion view
                currentIndex = photos.count
                finishSession()
            }
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
        let directionString = direction == .right ? "right" : "left"
        let action = direction == .right ? "keep" : "delete"

        if let sessionId = sessionId {
            let currentPhoto = photos[currentIndex]
            coreDataService.saveResult(
                assetId: currentPhoto.id,
                direction: directionString,
                action: action,
                sessionId: sessionId
            )
        }

        if direction == .right {
            keptAssets.append(photos[currentIndex].asset)
        } else {
            deletedAssets.append(photos[currentIndex].asset)
        }

        // Advance to next photo
        if currentIndex < photos.count - 1 {
            currentIndex += 1
            dragOffset = .zero
            dragRotation = 0
        } else {
            // Session complete - move past last photo to trigger completion view
            currentIndex = photos.count
            finishSession()
        }
    }

    // MARK: - Session
    func finishSession() {
        if let sessionId = sessionId {
            coreDataService.endSession(sessionId: sessionId)
        }

        Task {
            await applyChangesToPhotosApp()
        }
    }

    // MARK: - Photos App Integration
    private func applyChangesToPhotosApp() async {
        do {
            // Create or find "Sortir Kept" album
            if let album = try await photosService.createKeepAlbum() {
                // Add kept photos
                if !keptAssets.isEmpty {
                    try await photosService.moveToAlbum(assets: keptAssets, album: album)
                }
            }

            // Delete marked photos
            if !deletedAssets.isEmpty {
                try await photosService.deleteAssets(deletedAssets)
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Error organizing photos: \(error.localizedDescription)"
            }
        }
    }
}
