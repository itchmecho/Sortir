# Sortir - Product Roadmap & Implementation Plan

## Vision

Transform photo library organization from tedious folder navigation into a fluid, engaging swipe-based experience. Perfect for post-shoot curation, album consolidation, and seasonal cleanup.

**Target**: iOS 15+, iPadOS 15+
**Architecture**: MVVM with Service Layer
**Privacy**: On-device processing, no cloud upload
**Design Philosophy**: Liquid glass aesthetic from day one

---

## 📋 Product Roadmap

### ✅ Milestone 1: Working Prototype (v0.1) - ~4 hours
**Goal**: Prove the core swipe mechanic works with beautiful UI + data persistence

**Features**:
- ✨ Liquid glass UI aesthetic (frosted cards, blur effects)
- 📸 Photo library read access (all photos)
- 👈👉 Swipe gestures: Left = Delete, Right = Keep
- 📁 Create "Sortir Kept" album automatically
- 🎨 Smooth animations and visual feedback
- ✅ End-of-session album creation
- 💾 **CoreData persistence** (save session results)
- ⚙️ **Basic settings menu** with debug option to clear all data

---

### ✅ Milestone 2: Configurable Workflows (v0.2) - COMPLETE
**Goal**: Let users customize their swipe actions and save reusable workflows

**Features**:
- 🔧 **Workflow Engine** - Create, save, edit, delete custom workflows
- ⚡ **Action Types**: Keep, Delete, Move to Album, Favorite, Skip
- 📁 **Album Picker** - Select existing albums or create new ones
- 🎨 **Dynamic UI** - Icons and colors update based on workflow actions
- 💾 **WorkflowEntity** in CoreData for persistence
- 🏠 **Workflow Selection** - Choose workflow before starting session
- ✨ **Default "Quick Sort"** workflow created on first launch
- 📊 **Dynamic Session Summary** - Shows results based on selected actions

**New Files**:
- `Models/WorkflowAction.swift` - ActionType enum + Codable structs
- `Views/WorkflowListView.swift` - List and manage saved workflows
- `Views/WorkflowSetupView.swift` - Create/edit workflow configuration
- `Views/ActionConfigView.swift` - Configure individual swipe actions
- `Views/AlbumPickerView.swift` - Select or create destination albums

---

### ✅ Milestone 3: Critical Bug Fixes & Core Optimization (v0.2.1) - COMPLETE
**Status**: All P0 issues fixed, ready for P1 improvements and user testing

**Critical Issues (P0 - ✅ FIXED)**:
1. ✅ **Memory Crash on Large Libraries**
   - Implemented lazy loading with PHCachingImageManager
   - Only 15-20 photos in memory at a time
   - Images loaded on-demand as user swipes
   - Preload current and next photos for smooth UX
   - Cache properly cleaned up after session
   - Ready to test with 1000+ photo libraries

2. ✅ **HomeView Compilation**
   - HomeView properly organized in SwipeView.swift
   - ContentView correctly references it
   - No import issues

3. ✅ **Duplicate Model Definitions**
   - Removed legacy SwipeAction.swift file
   - All swipe actions consolidated to ActionType enum
   - Xcode project cleaned up (removed duplicate references)

4. ✅ **Race Condition in Session Completion**
   - Wrapped finishSession() in async Task properly
   - Added isProcessing state tracking
   - Shows "Organizing photos..." progress UI
   - Ensures data consistency before dismissing
   - Proper error handling and alerts

5. ✅ **Comprehensive Error Handling**
   - Added error alerts on session completion failures
   - User-facing error messages for Photos library operations
   - Error state tracked in @Published errorMessage

**Additional P0 Fixes**:
- ✅ **iCloud Photo Library**: Set networkAccessAllowed = true + opportunistic delivery mode
- ✅ **CoreData Threading**: Use background contexts for write operations (saveResult)
- ✅ **Xcode Project**: Fixed duplicate file references in project.pbxproj

**Build Status**: ✅ Successfully builds for iOS 15+ (iPhone 17 Simulator tested)

**High Priority Issues (P1 - Next iteration)**:
- Implement Undo/Redo functionality (per spec requirement)
- Add haptic feedback on swipe threshold and completion
- Remove fatalError from PersistenceController production code
- Implement photo deletion confirmation dialog
- Fix album creation race condition (handle duplicate albums atomically)

**Code Quality Issues (P2 - Nice to Have)**:
- Add haptic feedback with UIImpactFeedbackGenerator
- Add unit tests for business logic
- Add documentation comments for public APIs
- Extract hard-coded strings to constants
- Replace magic numbers with named constants
- Refactor duplicate views (SessionCompleteView & WorkflowSessionCompleteView)
- Improve MVVM separation (some views directly call services)
- Consider dependency injection instead of singleton pattern

---

### 🎨 Milestone 3: Polish & Power Features (v0.3) - ~6 hours
Undo, haptic feedback, progress tracking, advanced photo selection.

---

### 🚀 Milestone 4: Advanced Features (v0.4) - Future
Sequential workflows, AI suggestions, iCloud sync.

---

## 📊 Code Review Summary (v0.2 State)

**Overall Quality**: B+ (Good with critical issues)

**Build Status**: ✅ Builds successfully (3 warnings)

### Critical Findings

**Memory & Performance**:
- ❌ App will crash on large photo libraries (1000+ photos)
- ❌ All photos + images loaded into memory at session start
- ❌ No lazy loading or caching strategy implemented
- ❌ PhotoAssetItem retains full-resolution UIImage indefinitely

**Architecture Issues**:
- ❌ HomeView compilation/import issue
- ❌ Duplicate enum definitions (SwipeAction vs ActionType)
- ❌ Race condition in async session completion
- ❌ No error handling UI (silent failures only)
- ❌ CoreData operations on main thread

**Missing Features**:
- ❌ Undo/Redo functionality (spec required)
- ❌ Haptic feedback not implemented
- ❌ Progress tracking never updated in UI
- ❌ Photo deletion confirmation missing

**Well-Implemented**:
- ✅ Glass UI aesthetic (excellent)
- ✅ Workflow system design (clean and extensible)
- ✅ Permission handling (user-friendly)
- ✅ Gesture recognition (smooth)
- ✅ CoreData schema (well-normalized)
- ✅ MVVM architecture (mostly followed)
- ✅ Modern async/await patterns
- ✅ Photo library integration (PhotoKit usage)

### Estimated Effort
- **P0 Fixes**: 8-16 hours
- **P1 Improvements**: 4-8 hours
- **P2 Enhancements**: 4-6 hours

### Production Readiness
**Current**: Beta - NOT production ready (memory issues will crash app)
**After P0 Fixes**: Ready for v0.3 feature work
**After P1 Fixes**: Ready for user testing

---

## 🛠️ Tech Stack (Milestone 1)
- Swift (iOS 15+)
- SwiftUI with `.ultraThinMaterial` glass effect
- Photos framework (PHAsset, PHPhotoLibrary)
- CoreData (WorkflowResult, PhotoSession entities)
- DragGesture + Spring animations

---

For detailed implementation steps, see the work in progress files.
