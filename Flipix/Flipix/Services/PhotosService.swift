import Photos
import UIKit

/// Manages all interactions with the device's Photos library
///
/// PhotosService provides:
/// - Authorization request and status tracking for Photos library access
/// - Photo and album fetching from the user's library
/// - Efficient image loading and caching with PHCachingImageManager
/// - Album creation and modification
/// - Asset operations (move to album, delete, favorite)
///
/// This service is MainActor-bound to ensure Photos framework calls occur on the main thread.
/// It handles iCloud Photo Library synchronization and respects device permissions.
@MainActor
class PhotosService: ObservableObject {
    static let shared = PhotosService()

    /// Current authorization status for Photos library access
    @Published var authStatus: PHAuthorizationStatus = .notDetermined
    /// Image manager for efficient caching during photo browsing
    private let imageManager = PHCachingImageManager()

    /// Lock for atomic album creation to prevent duplicate album creation
    private var albumCreationLock = NSLock()
    /// Set of album names currently being created (for race condition prevention)
    private var creatingAlbumNames = Set<String>()

    // MARK: - Permissions

    /// Requests user authorization for reading and writing Photos library
    /// - Returns: true if authorization is granted or limited access is available
    func requestAuthorization() async -> Bool {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        await MainActor.run {
            self.authStatus = status
        }
        return status == .authorized || status == .limited
    }

    /// Updates authStatus by querying current Photos library authorization
    func checkAuthStatus() {
        authStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    // MARK: - Album Fetching

    /// Fetches all user-created albums from the Photos library
    /// - Returns: Array of albums sorted alphabetically by title
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

    /// Finds a specific album by its local identifier
    /// - Parameter localIdentifier: The album's local identifier string
    /// - Returns: The album if found, nil otherwise
    func findAlbum(byId localIdentifier: String) -> PHAssetCollection? {
        let result = PHAssetCollection.fetchAssetCollections(
            withLocalIdentifiers: [localIdentifier],
            options: nil
        )
        return result.firstObject
    }

    /// Finds an existing album or creates a new one with the specified title
    /// - Uses NSLock for thread-safe atomic creation
    /// - Parameter title: The album name
    /// - Returns: The existing or newly created album
    /// - Throws: PhotoKit error if creation fails
    func findOrCreateAlbum(named title: String) async throws -> PHAssetCollection? {
        // Use a lock to ensure atomic album creation
        albumCreationLock.lock()
        defer { albumCreationLock.unlock() }

        // Check if already creating this album (prevents duplicate creations)
        if creatingAlbumNames.contains(title) {
            // Wait for the other creation to finish, then return it
            albumCreationLock.unlock()
            // Give the other operation time to complete
            try? await Task.sleep(nanoseconds: TimingConstants.albumCreationWaitTime)
            albumCreationLock.lock()
        }

        // Check if album already exists
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

        // Mark that we're creating this album
        creatingAlbumNames.insert(title)
        defer { creatingAlbumNames.remove(title) }

        // Create new album
        albumCreationLock.unlock()
        let album = try await createAlbum(named: title)
        return album
    }

    // Create album - internal use, called from findOrCreateAlbum
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

    /// Fetches all photos from the device photo library
    /// - Returns: Array of PHAsset objects sorted by creation date (newest first)
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

    /// Loads a single image from a photo asset
    /// - Supports iCloud Photo Library with network access
    /// - Uses opportunistic delivery for quick loading
    /// - Parameter asset: The PHAsset to load
    /// - Parameter targetSize: Image size (defaults to thumbnail size)
    /// - Returns: The loaded UIImage or nil if loading fails
    func loadImage(for asset: PHAsset, targetSize: CGSize = CacheConstants.thumbnailSize) async -> UIImage? {
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

    // MARK: - Image Caching

    /// Starts caching images around a specified position for smooth scrolling
    /// - Parameter assets: Array of all PHAsset objects
    /// - Parameter centerIndex: Index to center the cache window around
    func startCachingImages(around assets: [PHAsset], centerIndex: Int) {
        let startIndex = max(0, centerIndex - CacheConstants.cachePaddingBefore)
        let endIndex = min(assets.count - 1, centerIndex + CacheConstants.cachePaddingAfter)

        let assetsToCache = Array(assets[startIndex...endIndex])
        imageManager.startCachingImages(
            for: assetsToCache,
            targetSize: CacheConstants.cacheSize,
            contentMode: .aspectFill,
            options: nil
        )
    }

    // Stop caching images outside the window
    func stopCachingImages(around assets: [PHAsset], centerIndex: Int) {
        let startIndex = max(0, centerIndex - CacheConstants.stopCachingBuffer)
        let endIndex = min(assets.count - 1, centerIndex + CacheConstants.maxCachedAssets + CacheConstants.stopCachingBuffer)

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
            targetSize: CacheConstants.cacheSize,
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
        return try await findOrCreateAlbum(named: AlbumConstants.defaultKeepAlbumName)
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
