//
//  DebugDataGenerator.swift
//  Flipix
//
//  Created by Claude Code on 11/26/24.
//

import Foundation
import UIKit
import Photos
import os.log

/// Generates test data for debugging and QA
/// Creates random synthetic photos with realistic metadata for testing swipe workflows
actor DebugDataGenerator {

    static let shared = DebugDataGenerator()

    private let logger = Logger(subsystem: "com.flipix.app", category: "DebugDataGenerator")

    /// Generate random test photos with varied metadata
    func generateTestPhotos(count: Int = 10) async throws {
        logger.info("Generating \(count) test photos")

        for i in 0..<count {
            // Generate a random colored image
            let image = generateRandomTestImage()

            guard let imageData = image.jpegData(compressionQuality: 0.85) else {
                logger.warning("Failed to convert test image \(i) to JPEG")
                continue
            }

            do {
                try await savePhotoToLibrary(imageData: imageData, filename: "test_photo_\(i + 1).jpg")
                logger.info("Generated test photo \(i + 1)/\(count)")
            } catch {
                logger.error("Failed to generate test photo \(i + 1): \(error.localizedDescription, privacy: .public)")
            }
        }

        logger.info("Test photo generation complete")
    }

    // MARK: - Private Helpers

    private func generateRandomTestImage() -> UIImage {
        let size = CGSize(width: 1200, height: 900)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            // Random gradient colors
            let colors = [
                UIColor(red: CGFloat.random(in: 0...1), green: CGFloat.random(in: 0...1), blue: CGFloat.random(in: 0...1), alpha: 1.0),
                UIColor(red: CGFloat.random(in: 0...1), green: CGFloat.random(in: 0...1), blue: CGFloat.random(in: 0...1), alpha: 1.0)
            ]

            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors.map { $0.cgColor } as CFArray, locations: [0, 1])!

            context.cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: size.width, y: size.height),
                options: []
            )

            // Add some random shapes
            context.cgContext.setFillColor(UIColor.white.withAlphaComponent(0.2).cgColor)
            for _ in 0..<5 {
                let rect = CGRect(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: 0...size.height),
                    width: CGFloat.random(in: 100...300),
                    height: CGFloat.random(in: 100...300)
                )
                context.cgContext.fillEllipse(in: rect)
            }
        }
    }

    private func savePhotoToLibrary(imageData: Data, filename: String) async throws {
        let _: Void = try await withCheckedThrowingContinuation { continuation in
            PHPhotoLibrary.shared().performChanges({
                let creationRequest = PHAssetCreationRequest.forAsset()
                creationRequest.addResource(with: .photo, data: imageData, options: nil)
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
