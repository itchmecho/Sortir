import SwiftUI
import Photos

struct AlbumPickerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedAlbumId: String?
    @Binding var selectedAlbumName: String?

    @State private var albums: [PHAssetCollection] = []
    @State private var showCreateAlbum = false
    @State private var newAlbumName = ""
    @State private var isCreatingAlbum = false
    @State private var searchText = ""

    private let photosService = PhotosService.shared

    private var filteredAlbums: [PHAssetCollection] {
        if searchText.isEmpty {
            return albums
        }
        return albums.filter {
            ($0.localizedTitle ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }

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

                VStack(spacing: 0) {
                    // Search bar
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search albums", text: $searchText)
                            .textFieldStyle(.plain)
                    }
                    .padding(12)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    if filteredAlbums.isEmpty && !searchText.isEmpty {
                        // No results
                        VStack(spacing: 16) {
                            Spacer()
                            Image(systemName: "folder.badge.questionmark")
                                .font(.system(size: 50))
                                .foregroundColor(.secondary)
                            Text("No albums found")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    } else if albums.isEmpty {
                        // No albums at all
                        VStack(spacing: 16) {
                            Spacer()
                            Image(systemName: "folder")
                                .font(.system(size: 50))
                                .foregroundColor(.secondary)
                            Text("No albums yet")
                                .font(.headline)
                            Text("Create your first album below")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    } else {
                        // Album list
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(filteredAlbums, id: \.localIdentifier) { album in
                                    AlbumRow(
                                        album: album,
                                        isSelected: selectedAlbumId == album.localIdentifier,
                                        onSelect: {
                                            selectAlbum(album)
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                        }
                    }

                    // Create new album button
                    Button(action: { showCreateAlbum = true }) {
                        HStack(spacing: 12) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                            Text("Create New Album")
                                .font(.headline)
                        }
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Select Album")
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
            loadAlbums()
        }
        .alert("Create Album", isPresented: $showCreateAlbum) {
            TextField("Album name", text: $newAlbumName)
            Button("Cancel", role: .cancel) {
                newAlbumName = ""
            }
            Button("Create") {
                createAlbum()
            }
            .disabled(newAlbumName.trimmingCharacters(in: .whitespaces).isEmpty)
        } message: {
            Text("Enter a name for your new album")
        }
    }

    private func loadAlbums() {
        albums = photosService.fetchUserAlbums()
    }

    private func selectAlbum(_ album: PHAssetCollection) {
        selectedAlbumId = album.localIdentifier
        selectedAlbumName = album.localizedTitle
        dismiss()
    }

    private func createAlbum() {
        let name = newAlbumName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }

        isCreatingAlbum = true

        Task {
            do {
                if let album = try await photosService.createAlbum(named: name) {
                    await MainActor.run {
                        selectAlbum(album)
                        newAlbumName = ""
                        isCreatingAlbum = false
                    }
                }
            } catch {
                print("Failed to create album: \(error)")
                await MainActor.run {
                    isCreatingAlbum = false
                }
            }
        }
    }
}

// MARK: - Album Row

struct AlbumRow: View {
    let album: PHAssetCollection
    let isSelected: Bool
    let onSelect: () -> Void

    @State private var thumbnailImage: UIImage?

    private let photosService = PhotosService.shared

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 14) {
                // Thumbnail
                ZStack {
                    if let image = thumbnailImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.secondary.opacity(0.2))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: "photo.on.rectangle")
                                    .foregroundColor(.secondary)
                            )
                    }
                }

                // Album info
                VStack(alignment: .leading, spacing: 4) {
                    Text(album.localizedTitle ?? "Untitled")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("\(album.estimatedAssetCount) photos")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
            }
            .padding(12)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue.opacity(0.5) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .task {
            await loadThumbnail()
        }
    }

    private func loadThumbnail() async {
        // Get first photo from album
        let options = PHFetchOptions()
        options.fetchLimit = 1
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        let assets = PHAsset.fetchAssets(in: album, options: options)
        guard let firstAsset = assets.firstObject else { return }

        thumbnailImage = await photosService.loadImage(for: firstAsset, targetSize: CGSize(width: 100, height: 100))
    }
}

#Preview {
    AlbumPickerView(
        selectedAlbumId: .constant(nil),
        selectedAlbumName: .constant(nil)
    )
}
