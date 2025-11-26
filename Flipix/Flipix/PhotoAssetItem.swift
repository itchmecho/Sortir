import Photos
import UIKit

class PhotoAssetItem: Identifiable {
    let id: String
    let asset: PHAsset
    var image: UIImage?

    init(asset: PHAsset) {
        self.id = asset.localIdentifier
        self.asset = asset
        self.image = nil
    }

    /// Test-only initializer that allows setting a custom ID
    /// This is needed because PHAsset cannot be instantiated directly in tests
    init(testId: String, asset: PHAsset) {
        self.id = testId
        self.asset = asset
        self.image = nil
    }
}
