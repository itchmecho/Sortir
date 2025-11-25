import SwiftUI
import Photos

struct WorkflowSetupView: View {
    @Environment(\.dismiss) var dismiss

    let workflow: Workflow?
    let onSave: (Workflow) -> Void

    @State private var name: String = ""
    @State private var leftAction: WorkflowAction = .delete()
    @State private var rightAction: WorkflowAction = .keep()
    @State private var showLeftActionConfig = false
    @State private var showRightActionConfig = false

    private var isEditing: Bool { workflow != nil }

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

                ScrollView {
                    VStack(spacing: 24) {
                        // Workflow name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Workflow Name")
                                .font(.headline)

                            TextField("e.g., Vacation Triage", text: $name)
                                .textFieldStyle(.plain)
                                .padding(16)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        // Actions section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Swipe Actions")
                                .font(.headline)

                            // Left action
                            ActionConfigButton(
                                direction: "Left",
                                action: leftAction,
                                onTap: { showLeftActionConfig = true }
                            )

                            // Right action
                            ActionConfigButton(
                                direction: "Right",
                                action: rightAction,
                                onTap: { showRightActionConfig = true }
                            )
                        }

                        // Preview section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Preview")
                                .font(.headline)

                            WorkflowPreview(
                                leftAction: leftAction,
                                rightAction: rightAction
                            )
                        }

                        Spacer(minLength: 40)

                        // Save button
                        Button(action: saveWorkflow) {
                            Text(isEditing ? "Save Changes" : "Create Workflow")
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
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                        .opacity(name.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
                    }
                    .padding(20)
                }
            }
            .navigationTitle(isEditing ? "Edit Workflow" : "New Workflow")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            if let workflow = workflow {
                name = workflow.name
                leftAction = workflow.leftAction
                rightAction = workflow.rightAction
            }
        }
        .sheet(isPresented: $showLeftActionConfig) {
            ActionConfigView(
                action: leftAction,
                direction: "Left",
                onSave: { leftAction = $0 }
            )
        }
        .sheet(isPresented: $showRightActionConfig) {
            ActionConfigView(
                action: rightAction,
                direction: "Right",
                onSave: { rightAction = $0 }
            )
        }
    }

    private func saveWorkflow() {
        let newWorkflow = Workflow(
            id: workflow?.id ?? UUID(),
            name: name.trimmingCharacters(in: .whitespaces),
            leftAction: leftAction,
            rightAction: rightAction,
            createdAt: workflow?.createdAt ?? Date(),
            lastUsedAt: workflow?.lastUsedAt
        )
        onSave(newWorkflow)
        dismiss()
    }
}

// MARK: - Action Config Button

struct ActionConfigButton: View {
    let direction: String
    let action: WorkflowAction
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Direction indicator
                VStack(spacing: 4) {
                    Image(systemName: direction == "Left" ? "arrow.left.circle.fill" : "arrow.right.circle.fill")
                        .font(.title2)
                        .foregroundColor(direction == "Left" ? .orange : .blue)
                    Text(direction)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(width: 50)

                // Action details
                HStack(spacing: 12) {
                    Image(systemName: action.icon)
                        .font(.title3)
                        .foregroundColor(action.color)
                        .frame(width: 30)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(action.type.displayName)
                            .font(.headline)
                            .foregroundColor(.primary)

                        if action.type == .moveToAlbum, let albumName = action.albumName {
                            Text(albumName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .background(action.color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Workflow Preview

struct WorkflowPreview: View {
    let leftAction: WorkflowAction
    let rightAction: WorkflowAction

    var body: some View {
        HStack(spacing: 0) {
            // Left side
            VStack(spacing: 8) {
                Image(systemName: leftAction.icon)
                    .font(.title)
                    .foregroundColor(leftAction.color)
                Text(leftAction.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(leftAction.color.opacity(0.1))

            // Center divider with photo icon
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 60)

                Image(systemName: "photo")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }

            // Right side
            VStack(spacing: 8) {
                Image(systemName: rightAction.icon)
                    .font(.title)
                    .foregroundColor(rightAction.color)
                Text(rightAction.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(rightAction.color.opacity(0.1))
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    WorkflowSetupView(workflow: nil) { workflow in
        print("Saved: \(workflow.name)")
    }
}
