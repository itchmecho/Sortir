import Photos
import UIKit

struct PhotoAssetItem: Identifiable {
    let id: String
    let asset: PHAsset
    var image: UIImage?

    init(asset: PHAsset) {
        self.id = asset.localIdentifier
        self.asset = asset
        self.image = nil
    }
}
