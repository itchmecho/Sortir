import Photos
import UIKit

@MainActor
class PhotosService: ObservableObject {
    static let shared = PhotosService()

    @Published var authStatus: PHAuthorizationStatus = .notDetermined
    private let imageManager = PHImageManager.default()

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

    // MARK: - Fetching
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
            options.isNetworkAccessAllowed = false

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

    // MARK: - Album Operations
    func createKeepAlbum() async throws -> PHAssetCollection? {
        var album: PHAssetCollection?

        let _: Void = try await withCheckedThrowingContinuation { continuation in
            var placeholder: PHObjectPlaceholder?

            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: "Sortir Kept")
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
}
