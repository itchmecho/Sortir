import Photos
import UIKit

@MainActor
class PhotosService: ObservableObject {
    static let shared = PhotosService()

    @Published var authStatus: PHAuthorizationStatus = .notDetermined
    private let imageManager = PHCachingImageManager()

    // Cache configuration
    private let thumbnailSize = CGSize(width: 400, height: 600)
    private let cacheSize = CGSize(width: 800, height: 1200)
    private let maxCachedAssets = 20

    // MARK: - Permissions
    func requestAuthorization() async -> Bool {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        await MainActor.run {
            self.authStatus = status
        }
        return status == .authorized || status == .limited
    }

    func checkAuthStatus() {
        authStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    // MARK: - Album Fetching
    func fetchUserAlbums() -> [PHAssetCollection] {
        var albums: [PHAssetCollection] = []

        // Fetch user-created albums
        let userAlbums = PHAssetCollection.fetchAssetCollections(
            with: .album,
            subtype: .albumRegular,
            options: nil
        )
        userAlbums.enumerateObjects { collection, _, _ in
            albums.append(collection)
        }

        // Sort by title
        albums.sort { ($0.localizedTitle ?? "") < ($1.localizedTitle ?? "") }

        return albums
    }

    func findAlbum(byId localIdentifier: String) -> PHAssetCollection? {
        let result = PHAssetCollection.fetchAssetCollections(
            withLocalIdentifiers: [localIdentifier],
            options: nil
        )
        return result.firstObject
    }

    func findOrCreateAlbum(named title: String) async throws -> PHAssetCollection? {
        // First check if album already exists
        let existingAlbums = PHAssetCollection.fetchAssetCollections(
            with: .album,
            subtype: .albumRegular,
            options: nil
        )

        var existingAlbum: PHAssetCollection?
        existingAlbums.enumerateObjects { collection, _, stop in
            if collection.localizedTitle == title {
                existingAlbum = collection
                stop.pointee = true
            }
        }

        if let existing = existingAlbum {
            return existing
        }

        // Create new album
        return try await createAlbum(named: title)
    }

    func createAlbum(named title: String) async throws -> PHAssetCollection? {
        var album: PHAssetCollection?

        let _: Void = try await withCheckedThrowingContinuation { continuation in
            var placeholder: PHObjectPlaceholder?

            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: title)
                placeholder = request.placeholderForCreatedAssetCollection
            }) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let localId = placeholder?.localIdentifier else {
                    continuation.resume(returning: ())
                    return
                }

                let result = PHAssetCollection.fetchAssetCollections(
                    withLocalIdentifiers: [localId],
                    options: nil
                )
                album = result.firstObject
                continuation.resume(returning: ())
            }
        }

        return album
    }

    // MARK: - Photo Fetching
    func fetchAllPhotos() -> [PHAsset] {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)

        let fetchResult = PHAsset.fetchAssets(with: options)
        var assets: [PHAsset] = []
        fetchResult.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }
        return assets
    }

    // MARK: - Image Loading
    func loadImage(for asset: PHAsset, targetSize: CGSize = CGSize(width: 400, height: 600)) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.isSynchronous = false
            options.isNetworkAccessAllowed = true  // Allow iCloud Photo Library sync
            options.deliveryMode = .opportunistic  // Load quickly even if low-res first

            self.imageManager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options
            ) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }

    // Start caching images around current index
    func startCachingImages(around assets: [PHAsset], centerIndex: Int) {
        let startIndex = max(0, centerIndex - 2)
        let endIndex = min(assets.count - 1, centerIndex + maxCachedAssets - 3)

        let assetsToCache = Array(assets[startIndex...endIndex])
        imageManager.startCachingImages(
            for: assetsToCache,
            targetSize: cacheSize,
            contentMode: .aspectFill,
            options: nil
        )
    }

    // Stop caching images outside the window
    func stopCachingImages(around assets: [PHAsset], centerIndex: Int) {
        let startIndex = max(0, centerIndex - 5)
        let endIndex = min(assets.count - 1, centerIndex + maxCachedAssets + 5)

        var imagesToStop: [PHAsset] = []
        // Add assets before start index
        if startIndex > 0 {
            imagesToStop.append(contentsOf: assets[0..<startIndex])
        }
        // Add assets after end index
        if endIndex + 1 < assets.count {
            imagesToStop.append(contentsOf: assets[(endIndex + 1)..<assets.count])
        }

        imageManager.stopCachingImages(
            for: imagesToStop,
            targetSize: cacheSize,
            contentMode: .aspectFill,
            options: nil
        )
    }

    // Clear all cached images
    func stopCachingAllImages() {
        imageManager.stopCachingImagesForAllAssets()
    }

    // MARK: - Album Operations
    func createKeepAlbum() async throws -> PHAssetCollection? {
        return try await findOrCreateAlbum(named: "Sortir Kept")
    }

    func moveToAlbum(assets: [PHAsset], album: PHAssetCollection) async throws {
        let _: Void = try await withCheckedThrowingContinuation { continuation in
            PHPhotoLibrary.shared().performChanges({
                let albumChangeRequest = PHAssetCollectionChangeRequest(for: album)
                albumChangeRequest?.addAssets(assets as NSArray)
            }) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    func deleteAssets(_ assets: [PHAsset]) async throws {
        let _: Void = try await withCheckedThrowingContinuation { continuation in
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.deleteAssets(assets as NSArray)
            }) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    func setFavorite(_ assets: [PHAsset], isFavorite: Bool = true) async throws {
        let _: Void = try await withCheckedThrowingContinuation { continuation in
            PHPhotoLibrary.shared().performChanges({
                for asset in assets {
                    let request = PHAssetChangeRequest(for: asset)
                    request.isFavorite = isFavorite
                }
            }) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
}
