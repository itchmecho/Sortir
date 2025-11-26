//
//  PlaceholderPhotoSeeder.swift
//  Flipix
//
//  Created by Claude Code on 11/26/24.
//

import Foundation
import UIKit
import Photos
import os.log

/// Manages seeding placeholder photos on first launch
/// These showcase the swipe UI before users add their own photos
actor PlaceholderPhotoSeeder {

    static let shared = PlaceholderPhotoSeeder()

    private let logger = Logger(subsystem: "com.flipix.app", category: "PlaceholderSeeder")
    private let seededKey = "hasSeededPlaceholders"

    /// Check if placeholder photos have already been seeded
    func hasAlreadySeeded() -> Bool {
        UserDefaults.standard.bool(forKey: seededKey)
    }

    /// Seed placeholder photos on first launch
    /// Only runs once per app install
    func seedPlaceholdersIfNeeded() async throws {
        guard !hasAlreadySeeded() else {
            logger.debug("Placeholders already seeded, skipping")
            return
        }

        logger.info("Seeding placeholder photos for first launch")

        // Get placeholder images
        let images = PlaceholderImageGenerator.getAllPlaceholders()
        let placeholderNames = ["Sunset Landscape", "Modern Abstract", "Nature Vibes", "Minimalist Design"]

        var successCount = 0
        var failureCount = 0

        // Import each placeholder
        for (index, image) in images.enumerated() {
            let name = placeholderNames[index]

            // Convert image to data
            guard let imageData = image.jpegData(compressionQuality: 0.85) else {
                logger.warning("Failed to convert placeholder image to JPEG: \(name)")
                failureCount += 1
                continue
            }

            do {
                try await savePhotoToLibrary(imageData: imageData, filename: "\(name).jpg")
                logger.info("Successfully seeded placeholder: \(name)")
                successCount += 1

            } catch {
                logger.error("Failed to seed placeholder \(name): \(error.localizedDescription, privacy: .public)")
                failureCount += 1
            }
        }

        // Mark as seeded only if we had at least some success
        if successCount > 0 {
            UserDefaults.standard.set(true, forKey: seededKey)
            logger.info("Placeholder seeding complete: \(successCount) succeeded, \(failureCount) failed")
        } else if failureCount > 0 {
            throw NSError(domain: "PlaceholderSeeding", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to seed any placeholder photos"])
        }
    }

    /// Reset the seeding flag (for development/testing)
    func resetSeeding() {
        UserDefaults.standard.removeObject(forKey: seededKey)
        logger.info("Placeholder seeding flag reset")
    }

    // MARK: - Private Helpers

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
