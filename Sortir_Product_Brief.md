# **SORTIR** — Photo Workflow Organization App
## Product Brief & Technical Specification

---

## **Product Overview**

**Name:** Sortir  
**Platform:** iOS/iPadOS (MVP); groundwork for macOS, Windows future expansion  
**Core Mechanic:** Swipe-based photo workflow organizer—users configure left/right gestures, then rapidly organize photo library selections into albums or deletion queues.

**Value Proposition:** Transform photo library organization from tedious folder navigation into a fluid, engaging experience. Perfect for post-shoot curation, album consolidation, or seasonal cleanup.

---

## **User Flow**

1. **Workflow Setup:** User selects a photo source (library, album, or date range)
2. **Configure Gestures:** "Left = Keep, Right = Delete" or "Left = Camping Album, Right = Cute Boyfriend Album"
3. **Swipe Session:** Rapid gesture-based triage through photos
4. **Results:** Photos organized into albums or marked for deletion
5. **Sequential Workflows:** Output from one workflow becomes input for the next (e.g., first pass: Keep/Delete; second pass: categorize keepers)

---

## **Core Features**

### **1. Apple Photos Integration (Native PhotoKit)**
- **Read Access:** Direct access to Photos library, albums, and smart albums via `PHPhotoLibrary`
- **Live Updates:** Reflect library changes in real-time
- **Album Creation & Management:** Create new albums from swipe results using `PHAssetCollectionChangeRequest`
- **Write Back:** Save organized photos to new/existing albums
- **Permissions:** Graceful handling of photo library permissions flow

### **2. Workflow Engine**
- **Configurable Gestures:** User-defined left/right actions
  - Actions: Keep, Delete, Move to Album A, Move to Album B, Flag, Custom destination
- **Persistent Workflows:** Save and reuse workflows (e.g., "Camping Trip Triage")
- **Sequential Chaining:** Organize output of one workflow as input to next
- **Undo/Redo:** Per-photo action reversal during active session
- **Progress Tracking:** Visual indicators of completion per session

### **3. Data Architecture (Local-First, Sync-Ready)**
- **Metadata Layer:** Separate from actual photo storage
  - Tracks: Photo ID (PHAsset) → Workflow results → Album destinations
  - Enables future device-to-device sync without re-storing photos
- **CoreData Database:** Persistent storage of workflows, results, and history
- **Sync Groundwork:** Settings structure for future Mac app sync endpoints and cloud integration (iCloud, Google Photos)

### **4. Design System — iOS 16+ Liquid Glass Aesthetic**
- **Framework:** SwiftUI (native, leverages iOS 16+ glassmorphism features)
- **Visual Language:**
  - Frosted glass cards (`.glass` material + depth)
  - Soft shadows, blurred backgrounds
  - Haptic feedback on swipes (UIImpactFeedback)
  - Smooth transitions and animations
- **Gesture Feedback:**
  - Left/right swipe previews (card tilts, opacity fade)
  - Haptic pulses on gesture commitment
  - Satisfying "pop" animations on action completion
- **Settings Menu:**
  - Robust configuration panel (gesture customization, album management, import/export)
  - Premium feature placeholders (see below)

### **5. Security**
- **On-Device Processing:** All photos remain on device; no cloud upload in v1
- **Privacy-First:** Minimal permissions; no analytics or telemetry
- **User Ownership:** No data collection; users retain full control of photo organization

---

## **Native Apple Libraries to Use**

| Feature | Framework | Notes |
|---------|-----------|-------|
| **Photo Access & Organization** | `PhotosUI`, `Photos` | PHAsset, PHPhotoLibrary, PHAssetCollection, PHAssetCollectionChangeRequest |
| **UI & Interaction** | `SwiftUI` | Native gesture handling, glassmorphism support (iOS 16+) |
| **Persistent Storage** | `CoreData` | Workflow definitions, metadata, history |
| **Haptic Feedback** | `UIKit` (feedback) | UIImpactFeedbackGenerator, UISelectionFeedbackGenerator |
| **Gesture Recognition** | `SwiftUI` Gestures | `.gesture()` modifiers for swipe detection |
| **File/Export** | `UniformTypeIdentifiers` | Future export workflows as .sortir files |
| **Settings/Preferences** | `@AppStorage` / `UserDefaults` | Simple local user preferences |
| **macOS Compatibility (Future)** | `AppKit` + `SwiftUI` | Cross-platform data models in Swift |
| **Sync Groundwork (Future)** | `CloudKit` or custom API | Comments flagging integration points |

---

## **MVP Scope (Phase 1)**

**Minimum Viable Product:**
1. Photo library read (all photos, single album, or date range selection)
2. Single workflow with left/right gesture configuration
3. Swipe UI with glass aesthetic and haptic feedback
4. Create album and write swipe results back to Photos app
5. Basic settings menu (gesture mapping, privacy info)
6. Undo within session

**NOT in Phase 1:**
- Cloud sync
- Premium features
- Multi-device sync
- Advanced filters or AI suggestions

---

## **Future-Ready Groundwork**

### **Device Sync (macOS Native App)**
- Metadata model designed to sync without re-storing photos
- Settings page structure for macOS app pairing
- CloudKit integration hooks (commented, ready for implementation)

### **Cloud Integration**
- Architecture comments flagging where iCloud Photos or Google Photos APIs could plug in
- Settings page sections for future cloud service configuration

### **Premium Features (Phase 2+)**
- **AI Photo Suggestions:** Smart categorization hints based on visual similarity
- **Batch Metadata:** Add tags, descriptions, or ratings to multiple photos
- **Smart Albums:** Dynamic collections based on criteria (e.g., "all photos from last month")
- **Workflow Templates:** Pre-built workflows (e.g., "Post-Vacation Cleanup," "Monthly Review")
- **Export Workflows:** Share workflows with other users as `.sortir` files
- **Advanced Gesture Options:** Custom swipe directions or multi-finger gestures
- **Photo Comparison:** Side-by-side view of similar photos for easier triage

---

## **Technical Considerations**

### **Photo Access Performance**
- PHAsset requests are asynchronous; lazy-load thumbnails to avoid UI blocking
- Use `PHCachingImageManager` for efficient thumbnail rendering during swipe sessions

### **Permissions Flow**
- Request `.readWrite` access to Photos library
- Handle limited library access gracefully (users may limit to specific albums)
- Provide clear explanation for permission request

### **Album Write Logic**
- Batch write operations to Photos app (PHAssetCollectionChangeRequest blocks)
- Handle edge cases: album already exists, photos already in destination, deletion conflicts

### **Storage Considerations**
- Metadata stored in CoreData, not in Photos app
- Keep workflow history lightweight (prune old results after X days or sessions)
- Allow user to export/backup workflow history if needed

---

## **Design Research Requirements**

1. **iOS 16+ Glassmorphism Patterns:** Research Apple's design system for frosted glass, blur effects, and depth
2. **Swipe Gesture Conventions:** Tinder-like swipe feedback patterns; haptic design standards
3. **Photo App Integration Best Practices:** Study Apple Photos UX for album management, selection flows
4. **Premium Feature Positioning:** Competitor analysis (Adobe Lightroom, Google Photos, Snapseed) for premium tier ideas

---

## **Success Metrics (Aspirational)**
- Swipe session feels fluid and addictive (under 500ms per gesture + feedback)
- Users save 10+ minutes per photo shoot during curation (vs. manual folder organization)
- Liquid glass aesthetic is distinctive and premium-feeling
- Settings menu is self-explanatory; users don't need tutorials for core workflow

---

## **Next Steps for Claude Code**

1. **Clarify PhotosUI limitations:** Does `.photoPicker` + `PHPhotoLibrary` give sufficient direct access, or do we need lower-level asset enumeration?
2. **Design tokens:** Document exact blur, opacity, and color values for liquid glass theme (create design system doc)
3. **Gesture detection:** Finalize swipe threshold, velocity, and angle tolerances (iOS conventions)
4. **CoreData schema:** Define tables for Workflows, Results, History, and Settings
5. **Prototype priority:** Photo library read → swipe UI → album write (test Photos app integration end-to-end first)
