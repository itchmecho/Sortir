import SwiftUI
import Photos

struct PhotoCardView: View {
    let photo: PhotoAssetItem
    let offset: CGSize
    let rotation: Double
    let cardOpacity: Double
    var leftAction: WorkflowAction = .delete()
    var rightAction: WorkflowAction = .keep()

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Photo image
                if let image = photo.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.gray.opacity(0.3))
                }

                // Swipe indicators overlay
                VStack {
                    HStack {
                        // Left action indicator
                        if offset.width < -30 {
                            VStack(spacing: 8) {
                                Image(systemName: leftAction.icon)
                                    .font(.system(size: 40))
                                Text(leftAction.displayName)
                                    .font(.caption)
                                    .lineLimit(1)
                            }
                            .foregroundColor(leftAction.color)
                            .opacity(Double(min(abs(offset.width) / 100, 1)))
                        }

                        Spacer()

                        // Right action indicator
                        if offset.width > 30 {
                            VStack(spacing: 8) {
                                Image(systemName: rightAction.icon)
                                    .font(.system(size: 40))
                                Text(rightAction.displayName)
                                    .font(.caption)
                                    .lineLimit(1)
                            }
                            .foregroundColor(rightAction.color)
                            .opacity(Double(min(offset.width / 100, 1)))
                        }
                    }
                    .padding(20)

                    Spacer()
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color(white: 1, opacity: 0.5), lineWidth: 2)
            )
        }
        .aspectRatio(3/4, contentMode: .fit)
        .shadow(color: Color(white: 0, opacity: 0.3), radius: 20, y: 10)
        .offset(offset)
        .rotationEffect(.degrees(rotation))
        .opacity(cardOpacity)
        .contentShape(RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    PhotoCardView(
        photo: PhotoAssetItem(asset: PHAsset()),
        offset: .zero,
        rotation: 0,
        cardOpacity: 1
    )
}
