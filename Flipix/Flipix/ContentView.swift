import SwiftUI
import Photos

struct ContentView: View {
    @StateObject private var photosService = PhotosService.shared
    @State private var showPermissionError = false

    var body: some View {
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

            Group {
                switch photosService.authStatus {
                case .authorized, .limited:
                    HomeView()

                case .denied, .restricted:
                    PermissionDeniedView()

                case .notDetermined:
                    PermissionRequestView()

                @unknown default:
                    PermissionRequestView()
                }
            }
        }
        .onAppear {
            photosService.checkAuthStatus()
        }
    }
}

// MARK: - Permission Views

struct PermissionRequestView: View {
    @StateObject private var photosService = PhotosService.shared

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            VStack(spacing: 12) {
                Text("Access Your Photos")
                    .font(.title2.bold())

                Text("Flipix needs permission to read and organize your photo library.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            Button(action: {
                Task {
                    let granted = await photosService.requestAuthorization()
                    if granted {
                        photosService.checkAuthStatus()
                    }
                }
            }) {
                Text("Grant Permission")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(.blue)
                    .cornerRadius(10)
            }

            Spacer()
        }
        .padding(20)
    }
}

struct PermissionDeniedView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "photo.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(.red)

            VStack(spacing: 12) {
                Text("Permission Denied")
                    .font(.title2.bold())

                Text("Please enable photo library access in Settings to use Flipix.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            Button(action: {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }) {
                Text("Open Settings")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(.blue)
                    .cornerRadius(10)
            }

            Spacer()
        }
        .padding(20)
    }
}

#Preview {
    ContentView()
}
