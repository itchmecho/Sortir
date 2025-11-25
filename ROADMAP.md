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

### 🎯 Milestone 2: Configurable Workflows (v0.2) - ~4 hours
Let users customize their swipe actions and save reusable workflows.

---

### 🎨 Milestone 3: Polish & Power Features (v0.3) - ~6 hours
Undo, haptic feedback, progress tracking, advanced photo selection.

---

### 🚀 Milestone 4: Advanced Features (v0.4) - Future
Sequential workflows, AI suggestions, iCloud sync.

---

## 🛠️ Tech Stack (Milestone 1)
- Swift (iOS 15+)
- SwiftUI with `.ultraThinMaterial` glass effect
- Photos framework (PHAsset, PHPhotoLibrary)
- CoreData (WorkflowResult, PhotoSession entities)
- DragGesture + Spring animations

---

For detailed implementation steps, see the work in progress files.
