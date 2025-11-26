import SwiftUI

struct WorkflowListView: View {
    @Environment(\.dismiss) var dismiss
    @State private var workflows: [Workflow] = []
    @State private var showCreateWorkflow = false
    @State private var selectedWorkflow: Workflow?
    @State private var workflowToEdit: Workflow?

    let onSelectWorkflow: (Workflow) -> Void

    private let coreDataService = CoreDataService.shared

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
                    VStack(spacing: 16) {
                        // Header
                        VStack(spacing: 8) {
                            Text("Choose a Workflow")
                                .font(.title2.bold())
                            Text("Select how you want to organize your photos")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 8)

                        // Workflow cards
                        ForEach(workflows) { workflow in
                            WorkflowCard(
                                workflow: workflow,
                                onSelect: {
                                    selectedWorkflow = workflow
                                    onSelectWorkflow(workflow)
                                },
                                onEdit: {
                                    workflowToEdit = workflow
                                },
                                onDelete: {
                                    deleteWorkflow(workflow)
                                }
                            )
                        }

                        // Create new workflow button
                        Button(action: { showCreateWorkflow = true }) {
                            HStack(spacing: 12) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                Text("Create New Workflow")
                                    .font(.headline)
                            }
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(20)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(
                                        style: StrokeStyle(lineWidth: 2, dash: [8])
                                    )
                                    .foregroundColor(.blue.opacity(0.3))
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
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
            loadWorkflows()
        }
        .sheet(isPresented: $showCreateWorkflow) {
            WorkflowSetupView(
                workflow: nil,
                onSave: { newWorkflow in
                    coreDataService.saveWorkflow(newWorkflow)
                    loadWorkflows()
                }
            )
        }
        .sheet(item: $workflowToEdit) { workflow in
            WorkflowSetupView(
                workflow: workflow,
                onSave: { updatedWorkflow in
                    coreDataService.saveWorkflow(updatedWorkflow)
                    loadWorkflows()
                }
            )
        }
    }

    private func loadWorkflows() {
        coreDataService.createDefaultWorkflowIfNeeded()
        workflows = coreDataService.fetchAllWorkflows()
    }

    private func deleteWorkflow(_ workflow: Workflow) {
        coreDataService.deleteWorkflow(id: workflow.id)
        loadWorkflows()
    }
}

// MARK: - Workflow Card

struct WorkflowCard: View {
    let workflow: Workflow
    let onSelect: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var showDeleteConfirmation = false

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                // Header row
                HStack {
                    Text(workflow.name)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()

                    // Edit/Delete menu
                    Menu {
                        Button(action: onEdit) {
                            Label("Edit", systemImage: "pencil")
                        }
                        Button(role: .destructive, action: { showDeleteConfirmation = true }) {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }

                // Action preview
                HStack(spacing: 20) {
                    // Left action
                    ActionPreview(
                        direction: "Left",
                        action: workflow.leftAction
                    )

                    // Right action
                    ActionPreview(
                        direction: "Right",
                        action: workflow.rightAction
                    )
                }

                // Last used info
                if let lastUsed = workflow.lastUsedAt {
                    Text("Last used \(lastUsed.formatted(.relative(presentation: .named)))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.3), .white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .confirmationDialog(
            "Delete Workflow",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete \"\(workflow.name)\"?")
        }
    }
}

// MARK: - Action Preview

struct ActionPreview: View {
    let direction: String
    let action: WorkflowAction

    var body: some View {
        HStack(spacing: 8) {
            // Direction arrow
            Image(systemName: direction == "Left" ? "arrow.left" : "arrow.right")
                .font(.caption.bold())
                .foregroundColor(.secondary)

            // Action icon
            Image(systemName: action.icon)
                .font(.subheadline)
                .foregroundColor(action.color)

            // Action name
            Text(action.displayName)
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(action.color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    WorkflowListView { workflow in
        print("Selected: \(workflow.name)")
    }
}
