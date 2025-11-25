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

                    Button("Go Back") {
                        dismiss()
                    }
                    .padding(.top, 20)
                }
            } else if viewModel.isProcessing {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Organizing your photos...")
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
                WorkflowSessionCompleteView(
                    workflow: workflow,
                    leftCount: viewModel.leftActionCount,
                    rightCount: viewModel.rightActionCount,
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
                SessionCompleteView(
                    kept: viewModel.keptAssets.count,
                    deleted: viewModel.deletedAssets.count,
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

struct SessionCompleteView: View {
    let kept: Int
    let deleted: Int
    let onDone: () -> Void

    private var total: Int { kept + deleted }

    private var cheekyMessage: (title: String, subtitle: String) {
        let ratio = total > 0 ? Double(deleted) / Double(total) : 0

        if deleted == 0 {
            return ("Sentimental, huh?", "You kept everything. No judgment... okay, maybe a little.")
        } else if kept == 0 {
            return ("Scorched Earth!", "You deleted everything. Ruthless. We respect it.")
        } else if ratio > 0.8 {
            return ("Marie Kondo Mode", "Those photos did NOT spark joy.")
        } else if ratio > 0.5 {
            return ("Balanced, as all things should be", "Thanos would be proud of your decisiveness.")
        } else if ratio < 0.2 {
            return ("The Collector", "Keeping the memories alive! All of them. Every. Single. One.")
        } else {
            let messages = [
                ("Nice work!", "Your camera roll thanks you."),
                ("Swipe game strong!", "That was satisfying, wasn't it?"),
                ("All done!", "Time well spent. Probably."),
                ("Photos: Sorted", "You're basically a professional organizer now."),
                ("Boom. Done.", "Your storage space sends its regards.")
            ]
            return messages.randomElement() ?? messages[0]
        }
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Fun icon based on results
            Image(systemName: deleted > kept ? "flame.fill" : "heart.fill")
                .font(.system(size: 70))
                .foregroundStyle(
                    LinearGradient(
                        colors: deleted > kept ? [.orange, .red] : [.pink, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 8) {
                Text(cheekyMessage.title)
                    .font(.title.bold())
                    .multilineTextAlignment(.center)

                Text(cheekyMessage.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // Stats card
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Kept")
                    Spacer()
                    Text("\(kept)")
                        .font(.title3.bold())
                }

                Divider()

                HStack {
                    Image(systemName: "trash.fill")
                        .foregroundColor(.red)
                    Text("Deleted")
                    Spacer()
                    Text("\(deleted)")
                        .font(.title3.bold())
                }

                Divider()

                HStack {
                    Image(systemName: "photo.stack")
                        .foregroundColor(.blue)
                    Text("Total sorted")
                    Spacer()
                    Text("\(total)")
                        .font(.title3.bold())
                }
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .padding(.horizontal, 20)

            Spacer()

            Button(action: onDone) {
                Text("Back to Home")
                    .font(.headline)
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
            .padding(.horizontal, 20)

            Spacer()
                .frame(height: 40)
        }
    }
}

// MARK: - Workflow Session Complete View
struct WorkflowSessionCompleteView: View {
    let workflow: Workflow
    let leftCount: Int
    let rightCount: Int
    let onDone: () -> Void

    private var total: Int { leftCount + rightCount }

    private var cheekyMessage: (title: String, subtitle: String) {
        // Check for specific action types to customize messages
        let leftType = workflow.leftAction.type
        let rightType = workflow.rightAction.type

        // If one is delete, check deletion ratio
        if leftType == .delete || rightType == .delete {
            let deleteCount = leftType == .delete ? leftCount : rightCount
            let keepCount = leftType == .delete ? rightCount : leftCount

            if deleteCount == 0 {
                return ("Sentimental, huh?", "You kept everything. No judgment... okay, maybe a little.")
            } else if keepCount == 0 {
                return ("Scorched Earth!", "You deleted everything. Ruthless. We respect it.")
            }

            let deleteRatio = total > 0 ? Double(deleteCount) / Double(total) : 0
            if deleteRatio > 0.8 {
                return ("Marie Kondo Mode", "Those photos did NOT spark joy.")
            } else if deleteRatio < 0.2 {
                return ("The Collector", "Keeping the memories alive! All of them.")
            }
        }

        // If sorting into albums
        if leftType == .moveToAlbum || rightType == .moveToAlbum {
            return ("Organized!", "Your albums are looking fresh.")
        }

        // If favoriting
        if leftType == .favorite || rightType == .favorite {
            let favoriteCount = leftType == .favorite ? leftCount : rightCount
            if favoriteCount > total / 2 {
                return ("Favorites Overload!", "You really love your photos.")
            }
        }

        // Generic messages
        let messages = [
            ("Nice work!", "Your camera roll thanks you."),
            ("Swipe game strong!", "That was satisfying, wasn't it?"),
            ("All done!", "Time well spent. Probably."),
            ("Photos: Sorted", "You're basically a professional organizer now."),
            ("Boom. Done.", "Your storage space sends its regards.")
        ]
        return messages.randomElement() ?? messages[0]
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Fun icon
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 70))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 8) {
                Text(cheekyMessage.title)
                    .font(.title.bold())
                    .multilineTextAlignment(.center)

                Text(cheekyMessage.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // Stats card - dynamic based on workflow
            VStack(spacing: 12) {
                // Left action stats
                HStack {
                    Image(systemName: workflow.leftAction.icon)
                        .foregroundColor(workflow.leftAction.color)
                    Text(workflow.leftAction.displayName)
                    Spacer()
                    Text("\(leftCount)")
                        .font(.title3.bold())
                }

                Divider()

                // Right action stats
                HStack {
                    Image(systemName: workflow.rightAction.icon)
                        .foregroundColor(workflow.rightAction.color)
                    Text(workflow.rightAction.displayName)
                    Spacer()
                    Text("\(rightCount)")
                        .font(.title3.bold())
                }

                Divider()

                // Total
                HStack {
                    Image(systemName: "photo.stack")
                        .foregroundColor(.blue)
                    Text("Total sorted")
                    Spacer()
                    Text("\(total)")
                        .font(.title3.bold())
                }
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .padding(.horizontal, 20)

            Spacer()

            Button(action: onDone) {
                Text("Back to Home")
                    .font(.headline)
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
            .padding(.horizontal, 20)

            Spacer()
                .frame(height: 40)
        }
    }
}

#Preview {
    SwipeView()
}