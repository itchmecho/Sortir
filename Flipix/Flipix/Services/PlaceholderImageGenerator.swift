//
//  PlaceholderImageGenerator.swift
//  Flipix
//
//  Created by Claude Code on 11/26/24.
//

import SwiftUI
import CoreGraphics

/// Generates beautiful placeholder images for first-time users
/// These showcase the swipe UI before users add their own photos
struct PlaceholderImageGenerator {

    /// Create a vibrant gradient landscape (warm sunset)
    static func generateWarmSunset() -> UIImage {
        let size = CGSize(width: 1200, height: 900)

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            // Sky gradient - warm sunset colors
            let colors = [
                UIColor(red: 1.0, green: 0.4, blue: 0.2, alpha: 1.0).cgColor,  // Warm orange
                UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0).cgColor,  // Golden
                UIColor(red: 1.0, green: 0.8, blue: 0.3, alpha: 1.0).cgColor,  // Light golden
                UIColor(red: 0.9, green: 0.7, blue: 0.5, alpha: 1.0).cgColor   // Peachy
            ]
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: [0, 0.33, 0.66, 1])!

            // Draw sky gradient from top to bottom
            context.cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: size.width / 2, y: 0),
                end: CGPoint(x: size.width / 2, y: size.height * 0.6),
                options: []
            )

            // Water/ground reflection with complementary colors
            let waterColors = [
                UIColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 0.8).cgColor,
                UIColor(red: 0.15, green: 0.35, blue: 0.55, alpha: 0.8).cgColor
            ]
            let waterGradient = CGGradient(colorsSpace: colorSpace, colors: waterColors as CFArray, locations: [0, 1])!

            context.cgContext.drawLinearGradient(
                waterGradient,
                start: CGPoint(x: size.width / 2, y: size.height * 0.6),
                end: CGPoint(x: size.width / 2, y: size.height),
                options: []
            )

            // Add some circular light elements (bokeh effect)
            context.cgContext.setFillColor(UIColor(red: 1.0, green: 0.7, blue: 0.3, alpha: 0.3).cgColor)
            for _ in 0..<5 {
                let randomX = CGFloat.random(in: 0...size.width)
                let randomY = CGFloat.random(in: 0...(size.height * 0.6))
                let radius = CGFloat.random(in: 40...100)
                context.cgContext.fillEllipse(in: CGRect(x: randomX - radius / 2, y: randomY - radius / 2, width: radius, height: radius))
            }
        }
    }

    /// Create a cool modern gradient with geometric elements
    static func generateCoolModern() -> UIImage {
        let size = CGSize(width: 1200, height: 900)

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            // Deep blue to purple gradient
            let colors = [
                UIColor(red: 0.1, green: 0.3, blue: 0.8, alpha: 1.0).cgColor,  // Deep blue
                UIColor(red: 0.2, green: 0.4, blue: 0.9, alpha: 1.0).cgColor,  // Mid blue
                UIColor(red: 0.4, green: 0.2, blue: 0.8, alpha: 1.0).cgColor,  // Purple
                UIColor(red: 0.6, green: 0.1, blue: 0.7, alpha: 1.0).cgColor   // Deep purple
            ]
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: [0, 0.33, 0.66, 1])!

            context.cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: size.width, y: size.height),
                options: []
            )

            // Add semi-transparent geometric shapes (squares/rectangles)
            context.cgContext.setStrokeColor(UIColor.white.withAlphaComponent(0.2).cgColor)
            context.cgContext.setLineWidth(3)

            // Draw some abstract rectangles
            let rects = [
                CGRect(x: 100, y: 150, width: 250, height: 250),
                CGRect(x: 600, y: 300, width: 300, height: 200),
                CGRect(x: 250, y: 550, width: 400, height: 250)
            ]

            for rect in rects {
                context.cgContext.stroke(rect)
            }

            // Add glowing circles
            context.cgContext.setFillColor(UIColor(red: 0.3, green: 0.8, blue: 1.0, alpha: 0.15).cgColor)
            context.cgContext.fillEllipse(in: CGRect(x: 800, y: 100, width: 300, height: 300))
            context.cgContext.fillEllipse(in: CGRect(x: 150, y: 400, width: 200, height: 200))
        }
    }

    /// Create a vibrant nature-inspired gradient with warm earth tones
    static func generateWarmNature() -> UIImage {
        let size = CGSize(width: 1200, height: 900)

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            // Earth tone gradient - warm greens to oranges
            let colors = [
                UIColor(red: 0.3, green: 0.6, blue: 0.2, alpha: 1.0).cgColor,  // Forest green
                UIColor(red: 0.6, green: 0.5, blue: 0.2, alpha: 1.0).cgColor,  // Olive
                UIColor(red: 0.8, green: 0.5, blue: 0.2, alpha: 1.0).cgColor,  // Warm brown
                UIColor(red: 0.9, green: 0.6, blue: 0.3, alpha: 1.0).cgColor   // Burnt orange
            ]
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: [0, 0.33, 0.66, 1])!

            context.cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: size.width, y: size.height),
                options: []
            )

            // Add organic flowing shapes
            context.cgContext.setFillColor(UIColor(red: 0.2, green: 0.4, blue: 0.1, alpha: 0.3).cgColor)

            // Draw some organic blob shapes using arcs
            var path = UIBezierPath()
            path.addArc(withCenter: CGPoint(x: 200, y: 200), radius: 150, startAngle: 0, endAngle: .pi * 2, clockwise: true)
            context.cgContext.addPath(path.cgPath)
            context.cgContext.fillPath()

            path = UIBezierPath()
            path.addArc(withCenter: CGPoint(x: 900, y: 600), radius: 200, startAngle: 0, endAngle: .pi * 2, clockwise: true)
            context.cgContext.addPath(path.cgPath)
            context.cgContext.fillPath()

            // Add light rays effect with semi-transparent lines
            context.cgContext.setStrokeColor(UIColor.white.withAlphaComponent(0.15).cgColor)
            context.cgContext.setLineWidth(4)
            for i in 0..<8 {
                let angle = CGFloat(i) * .pi / 4
                let startX = size.width / 2
                let startY = size.height / 2
                let endX = startX + cos(angle) * 500
                let endY = startY + sin(angle) * 500
                context.cgContext.move(to: CGPoint(x: startX, y: startY))
                context.cgContext.addLine(to: CGPoint(x: endX, y: endY))
            }
            context.cgContext.strokePath()
        }
    }

    /// Create a cool minimalista gradient with contrasting colors
    static func generateMinimalistica() -> UIImage {
        let size = CGSize(width: 1200, height: 900)

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            // Teal to coral gradient - modern and clean
            let colors = [
                UIColor(red: 0.1, green: 0.7, blue: 0.8, alpha: 1.0).cgColor,  // Teal
                UIColor(red: 0.2, green: 0.6, blue: 0.7, alpha: 1.0).cgColor,  // Mid teal
                UIColor(red: 0.8, green: 0.4, blue: 0.4, alpha: 1.0).cgColor,  // Coral
                UIColor(red: 0.9, green: 0.3, blue: 0.3, alpha: 1.0).cgColor   // Coral-red
            ]
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: [0, 0.33, 0.66, 1])!

            context.cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: size.height),
                end: CGPoint(x: size.width, y: 0),
                options: []
            )

            // Add minimal geometric lines and shapes
            context.cgContext.setStrokeColor(UIColor.white.withAlphaComponent(0.3).cgColor)
            context.cgContext.setLineWidth(2)

            // Horizontal lines
            for i in 0..<6 {
                let y = CGFloat(i) * (size.height / 5)
                context.cgContext.move(to: CGPoint(x: 0, y: y))
                context.cgContext.addLine(to: CGPoint(x: size.width, y: y))
            }

            // Vertical lines
            for i in 0..<8 {
                let x = CGFloat(i) * (size.width / 7)
                context.cgContext.move(to: CGPoint(x: x, y: 0))
                context.cgContext.addLine(to: CGPoint(x: x, y: size.height))
            }
            context.cgContext.strokePath()

            // Add some accent squares
            context.cgContext.setFillColor(UIColor.white.withAlphaComponent(0.2).cgColor)
            context.cgContext.fill(CGRect(x: 200, y: 250, width: 150, height: 150))
            context.cgContext.fill(CGRect(x: 900, y: 500, width: 200, height: 200))
        }
    }

    /// Get all placeholder images in order
    static func getAllPlaceholders() -> [UIImage] {
        return [
            generateWarmSunset(),
            generateCoolModern(),
            generateWarmNature(),
            generateMinimalistica()
        ]
    }
}
