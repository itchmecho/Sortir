import SwiftUI
import Photos

struct ActionConfigView: View {
    @Environment(\.dismiss) var dismiss

    let action: WorkflowAction
    let direction: String
    let onSave: (WorkflowAction) -> Void

    @State private var selectedType: ActionType = .keep
    @State private var selectedAlbumId: String?
    @State private var selectedAlbumName: String?
    @State private var showAlbumPicker = false

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
                        // Direction indicator
                        HStack(spacing: 12) {
                            Image(systemName: direction == "Left" ? "arrow.left.circle.fill" : "arrow.right.circle.fill")
                                .font(.largeTitle)
                                .foregroundColor(direction == "Left" ? .orange : .blue)

                            VStack(alignment: .leading) {
                                Text("Swipe \(direction)")
                                    .font(.title2.bold())
                                Text("Choose what happens")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()
                        }
                        .padding(.bottom, 8)

                        // Action type selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Action")
                                .font(.headline)

                            ForEach(ActionType.allCases, id: \.self) { type in
                                ActionTypeRow(
                                    type: type,
                                    isSelected: selectedType == type,
                                    albumName: type == .moveToAlbum ? selectedAlbumName : nil,
                                    onSelect: {
                                        selectedType = type
                                        if type == .moveToAlbum && selectedAlbumId == nil {
                                            showAlbumPicker = true
                                        }
                                    },
                                    onChangeAlbum: type == .moveToAlbum ? { showAlbumPicker = true } : nil
                                )
                            }
                        }

                        Spacer(minLength: 40)

                        // Save button
                        Button(action: saveAction) {
                            Text("Save")
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
                        .disabled(selectedType == .moveToAlbum && selectedAlbumId == nil)
                        .opacity(selectedType == .moveToAlbum && selectedAlbumId == nil ? 0.5 : 1)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Configure Action")
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
            selectedType = action.type
            selectedAlbumId = action.albumId
            selectedAlbumName = action.albumName
        }
        .sheet(isPresented: $showAlbumPicker) {
            AlbumPickerView(
                selectedAlbumId: $selectedAlbumId,
                selectedAlbumName: $selectedAlbumName
            )
        }
    }

    private func saveAction() {
        let newAction: WorkflowAction
        switch selectedType {
        case .keep:
            newAction = .keep()
        case .delete:
            newAction = .delete()
        case .favorite:
            newAction = .favorite()
        case .skip:
            newAction = .skip()
        case .moveToAlbum:
            if let albumId = selectedAlbumId, let albumName = selectedAlbumName {
                newAction = .moveToAlbum(id: albumId, name: albumName)
            } else {
                return
            }
        }
        onSave(newAction)
        dismiss()
    }
}

// MARK: - Action Type Row

struct ActionTypeRow: View {
    let type: ActionType
    let isSelected: Bool
    let albumName: String?
    let onSelect: () -> Void
    let onChangeAlbum: (() -> Void)?

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? type.color : Color.secondary.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(type.color)
                            .frame(width: 14, height: 14)
                    }
                }

                // Icon
                Image(systemName: type.icon)
                    .font(.title3)
                    .foregroundColor(type.color)
                    .frame(width: 30)

                // Label
                VStack(alignment: .leading, spacing: 2) {
                    Text(type.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(descriptionFor(type))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Album selector for moveToAlbum
                if type == .moveToAlbum && isSelected {
                    Button(action: { onChangeAlbum?() }) {
                        HStack(spacing: 4) {
                            Text(albumName ?? "Select Album")
                                .font(.subheadline)
                                .foregroundColor(albumName != nil ? .primary : .blue)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .padding(16)
            .background(isSelected ? type.color.opacity(0.1) : Color.clear)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? type.color.opacity(0.5) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private func descriptionFor(_ type: ActionType) -> String {
        switch type {
        case .keep: return "Add to Flipix Kept album"
        case .delete: return "Move to Recently Deleted"
        case .moveToAlbum: return "Add to a specific album"
        case .favorite: return "Mark as favorite"
        case .skip: return "Skip without any action"
        }
    }
}

#Preview {
    ActionConfigView(
        action: .keep(),
        direction: "Right"
    ) { action in
        print("Saved: \(action.type)")
    }
}
