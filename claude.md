# Sortir - Claude Project Guidelines

**See workspace communication & development guidelines**: [../CLAUDE.md](../CLAUDE.md) and [../CLAUDE-GUIDELINES.md](../CLAUDE-GUIDELINES.md)

This file contains project-specific information. General guidelines are documented in the workspace root.

## Project Overview

**Sortir** is a swipe-based photo workflow organization app for iOS/iPadOS. Users configure left/right gestures, then rapidly organize photo library selections into albums or deletion queues. The app transforms tedious photo library organization into a fluid, engaging experience perfect for post-shoot curation, album consolidation, and seasonal cleanup.

**Full technical specification:** [Sortir_Product_Brief.md](Sortir_Product_Brief.md)

## Key Features

- **Apple Photos Integration** - Direct native access to Photos library via PhotosUI/Photos frameworks with real-time synchronization
- **Configurable Workflow Engine** - User-defined left/right gesture actions (Keep, Delete, Move to Album, Flag, etc.)
- **Swipe Session UI** - Liquid glass aesthetic with haptic feedback and satisfying gesture animations
- **Album Management** - Create and write swipe results to new/existing albums in Photos app
- **Sequential Workflows** - Chain workflows together (e.g., first pass: Keep/Delete; second pass: categorize keepers)
- **Undo/Redo** - Per-photo action reversal during active session
- **Local-First Architecture** - On-device processing with CoreData persistence; no cloud upload in v1

## Technology Stack

- **Language:** Swift (iOS 16+)
- **UI Framework:** SwiftUI (native glassmorphism support)
- **Photo Access:** PhotosUI, Photos (PHAsset, PHPhotoLibrary, PHAssetCollection)
- **Persistent Storage:** CoreData (workflows, metadata, history)
- **Haptic Feedback:** UIKit (UIImpactFeedbackGenerator, UISelectionFeedbackGenerator)
- **Gesture Recognition:** SwiftUI Gestures API
- **Preferences:** @AppStorage / UserDefaults

## File Structure

```
Sortir/
├── Sortir_Product_Brief.md          # Full technical specification
├── claude.md                          # This file
├── [iOS Project Root]/
│   ├── Models/
│   │   ├── Workflow.swift
│   │   ├── WorkflowResult.swift
│   │   └── Settings.swift
│   ├── Views/
│   │   ├── SwipeSessionView.swift
│   │   ├── WorkflowSetupView.swift
│   │   ├── SettingsView.swift
│   │   └── Components/
│   ├── Services/
│   │   ├── PhotosService.swift
│   │   ├── WorkflowService.swift
│   │   └── CoreDataService.swift
│   └── Assets/
```

## Important Notes

- **MVP Scope (Phase 1):** Photo library read, single workflow with left/right gestures, swipe UI with glass aesthetic, album creation, basic settings, undo within session
- **Privacy-First:** All photos remain on-device; no cloud upload or analytics in v1
- **Performance Critical:** PHAsset requests are async; use PHCachingImageManager for efficient thumbnail rendering during swipe sessions
- **Permissions:** Request `.readWrite` access to Photos library; handle limited library access gracefully
- **Design System:** iOS 16+ liquid glass aesthetic with frosted glass cards, soft shadows, and blurred backgrounds

## Common Development Tasks

### Running the App

```bash
xcodebuild -scheme Sortir -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Testing

```bash
xcodebuild test -scheme Sortir -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Core Development Areas

1. **Photo Library Integration** - Test PHPhotoLibrary read access and PHAssetCollectionChangeRequest write operations
2. **Swipe Gesture Detection** - Finalize swipe threshold, velocity, and angle tolerances
3. **CoreData Schema** - Define tables for Workflows, Results, History, and Settings
4. **Glass UI Component** - Implement reusable frosted glass card component with SwiftUI
5. **Album Write Logic** - Handle batch operations and edge cases (duplicate albums, existing photos)

## Key Technical Decisions

- **Photos Access:** Use native PhotoKit for direct library access (not photo picker alone)
- **Gesture Feedback:** Haptic pulses with tilt/opacity preview during swipe
- **Data Storage:** Metadata in CoreData, separate from photo storage (enables future sync without re-storing photos)
- **Glass Aesthetic:** SwiftUI `.glass` material + depth + soft shadows (iOS 16+)

## Future-Ready Groundwork

- **Device Sync:** Architecture designed for macOS app pairing via CloudKit
- **Cloud Integration:** Settings page structure for future iCloud/Google Photos APIs
- **Premium Features:** AI suggestions, batch metadata, smart albums, workflow templates, export as .sortir files

## Additional Resources

- [Sortir Product Brief](Sortir_Product_Brief.md)
- Apple PhotosUI Documentation
- SwiftUI Glassmorphism Patterns (iOS 16+)

## Versioning Strategy

**IMPORTANT**: Always increment version numbers when making changes:

### App Version
- Located in Xcode: General > Version
- Format: MAJOR.MINOR.PATCH (e.g., 0.1.0)
- Increment when completing a milestone or significant feature

### Build Number
- Located in Xcode: General > Build
- Increment every time you make changes
- Used for TestFlight and App Store builds

### In Code
- Update `let version = "0.1.0"` in relevant files
- Document changes in commit messages

**When to increment:**
- PATCH: Bug fixes, small tweaks
- MINOR: New features (each Milestone)
- MAJOR: Breaking changes or major releases

Example commit message:
```
Implement liquid glass UI - bump to v0.1.0 (build 1)
```
