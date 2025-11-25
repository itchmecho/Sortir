import SwiftUI

// MARK: - Home View
struct HomeView: View {
    @State private var showWorkflowPicker = false
    @State private var showSettings = false
    @State private var selectedWorkflow: Workflow?
    @State private var showSwipeView = false

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.1),
                        Color.purple.opacity(0.1)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 32) {
                    Spacer()

                    // App icon/logo area
                    VStack(spacing: 16) {
                        Image(systemName: "photo.stack")
                            .font(.system(size: 70))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Text("Sortir")
                            .font(.largeTitle.bold())

                        Text("Swipe to organize your photos")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Main action buttons
                    VStack(spacing: 16) {
                        // Start sorting button
                        Button(action: { showWorkflowPicker = true }) {
                            HStack(spacing: 12) {
                                Image(systemName: "play.fill")
                                    .font(.headline)
                                Text("Start Sorting")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(14)
                        }

                        // Settings button
                        Button(action: { showSettings = true }) {
                            HStack(spacing: 12) {
                                Image(systemName: "gear")
                                    .font(.headline)
                                Text("Settings")
                                    .font(.headline)
                            }
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(.ultraThinMaterial)
                            .cornerRadius(14)
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer()
                        .frame(height: 60)
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showWorkflowPicker) {
            WorkflowListView { workflow in
                selectedWorkflow = workflow
                showWorkflowPicker = false
                showSwipeView = true
            }
        }
        .fullScreenCover(isPresented: $showSwipeView) {
            if let workflow = selectedWorkflow {
                SwipeSessionView(workflow: workflow)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
}

// MARK: - Swipe Session View (Full Screen)
struct SwipeSessionView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = SwipeViewModel()
    @State private var showSettings = false

    let workflow: Workflow

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.1),
                    Color.purple.opacity(0.1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            if viewModel.isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text(UIStrings.loadingPhotos)
                        .foregroundColor(.secondary)
                }
            } else if viewModel.photos.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text(UIStrings.noPhotosFound)
                        .font(.headline)

                    Button("Go Back") {
                        dismiss()
                    }
                    .padding(.top, 20)
                }
            } else if viewModel.isProcessing {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text(UIStrings.organizingPhotos)
                        .foregroundColor(.secondary)
                }
            } else if viewModel.currentIndex < viewModel.photos.count {
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .padding(10)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }

                        Spacer()

                        VStack {
                            Text(workflow.name)
                                .font(.headline)
                            Text("\(viewModel.currentIndex + 1) / \(viewModel.photos.count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Button(action: { showSettings = true }) {
                            Image(systemName: "gear")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .padding(10)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)

                    // Progress bar
                    ProgressView(
                        value: Double(viewModel.currentIndex),
                        total: Double(viewModel.photos.count)
                    )
                    .tint(.blue)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    Spacer()

                    // Photo card
                    ZStack {
                        if viewModel.currentIndex + 1 < viewModel.photos.count {
                            PhotoCardView(
                                photo: viewModel.photos[viewModel.currentIndex + 1],
                                offset: .zero,
                                rotation: 0,
                                cardOpacity: 0.5,
                                leftAction: workflow.leftAction,
                                rightAction: workflow.rightAction
                            )
                            .scaleEffect(0.95)
                        }

                        PhotoCardView(
                            photo: viewModel.photos[viewModel.currentIndex],
                            offset: viewModel.dragOffset,
                            rotation: viewModel.dragRotation,
                            cardOpacity: 1.0,
                            leftAction: workflow.leftAction,
                            rightAction: workflow.rightAction
                        )
                        .gesture(
                            DragGesture()
                                .onChanged { viewModel.onDragChanged($0) }
                                .onEnded { value in
                                    Task {
                                        await viewModel.onDragEnded(value)
                                    }
                                }
                        )
                    }
                    .padding(20)

                    Spacer()

                    // Action buttons - dynamic based on workflow
                    HStack(spacing: 20) {
                        // Left action button
                        Button(action: { viewModel.performSwipe(direction: .left) }) {
                            VStack(spacing: 8) {
                                Image(systemName: workflow.leftAction.icon)
                                    .font(.title2)
                                Text(workflow.leftAction.displayName)
                                    .font(.caption)
                                    .lineLimit(1)
                            }
                            .foregroundColor(workflow.leftAction.color)
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(workflow.leftAction.color.opacity(0.1))
                            .cornerRadius(14)
                        }

                        // Right action button
                        Button(action: { viewModel.performSwipe(direction: .right) }) {
                            VStack(spacing: 8) {
                                Image(systemName: workflow.rightAction.icon)
                                    .font(.title2)
                                Text(workflow.rightAction.displayName)
                                    .font(.caption)
                                    .lineLimit(1)
                            }
                            .foregroundColor(workflow.rightAction.color)
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(workflow.rightAction.color.opacity(0.1))
                            .cornerRadius(14)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            } else {
                // Session complete
                UnifiedSessionCompleteView(
                    leftCount: viewModel.leftActionCount,
                    rightCount: viewModel.rightActionCount,
                    leftAction: workflow.leftAction,
                    rightAction: workflow.rightAction,
                    onDone: { dismiss() }
                )
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("Dismiss") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .task {
            viewModel.workflow = workflow
            await viewModel.loadPhotos()
        }
    }
}

// MARK: - Original Swipe View (kept for compatibility)
struct SwipeView: View {
    @StateObject private var viewModel = SwipeViewModel()
    @State private var showSettings = false

    var body: some View {
        ZStack {
            if viewModel.isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading photos...")
                        .foregroundColor(.secondary)
                }
            } else if viewModel.photos.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("No photos found")
                        .font(.headline)
                }
            } else if viewModel.currentIndex < viewModel.photos.count {
                VStack(spacing: 20) {
                    // Header with settings button
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Organize Photos")
                                .font(.title2.bold())
                            Text("\(viewModel.currentIndex + 1) / \(viewModel.photos.count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button(action: { showSettings = true }) {
                            Image(systemName: "gear")
                                .font(.headline)
                                .foregroundColor(.blue)
                                .padding(10)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                    }
                    .padding(20)

                    // Progress bar
                    GeometryReader { _ in
                        ProgressView(
                            value: Double(viewModel.currentIndex),
                            total: Double(viewModel.photos.count)
                        )
                        .tint(.blue)
                    }
                    .frame(height: 4)
                    .padding(.horizontal, 20)

                    Spacer()

                    // Photo card with swipe
                    ZStack {
                        if viewModel.currentIndex + 1 < viewModel.photos.count {
                            PhotoCardView(
                                photo: viewModel.photos[viewModel.currentIndex + 1],
                                offset: .zero,
                                rotation: 0,
                                cardOpacity: 0.5
                            )
                            .scaleEffect(0.95)
                        }

                        PhotoCardView(
                            photo: viewModel.photos[viewModel.currentIndex],
                            offset: viewModel.dragOffset,
                            rotation: viewModel.dragRotation,
                            cardOpacity: 1.0
                        )
                        .gesture(
                            DragGesture()
                                .onChanged { viewModel.onDragChanged($0) }
                                .onEnded { value in
                                    Task {
                                        await viewModel.onDragEnded(value)
                                    }
                                }
                        )
                    }
                    .padding(20)

                    Spacer()

                    // Action buttons
                    HStack(spacing: 20) {
                        // Delete button
                        Button(action: {
                            viewModel.performSwipe(direction: .left)
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: "trash.fill")
                                    .font(.headline)
                                Text("Delete")
                                    .font(.caption)
                            }
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(.red.opacity(0.1))
                            .cornerRadius(10)
                        }

                        // Keep button
                        Button(action: {
                            viewModel.performSwipe(direction: .right)
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.headline)
                                Text("Keep")
                                    .font(.caption)
                            }
                            .foregroundColor(.green)
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(.green.opacity(0.1))
                            .cornerRadius(10)
                        }
                    }
                    .padding(20)
                }
            } else if viewModel.isProcessing {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Organizing your photos...")
                        .foregroundColor(.secondary)
                }
            } else {
                UnifiedSessionCompleteView(
                    leftCount: viewModel.deletedAssets.count,
                    rightCount: viewModel.keptAssets.count,
                    leftAction: .delete(),
                    rightAction: .keep(),
                    onDone: {
                        // Reset and go back
                    }
                )
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("Dismiss") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .task {
            await viewModel.loadPhotos()
        }
    }
}


#Preview {
    SwipeView()
}