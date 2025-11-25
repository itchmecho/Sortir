import SwiftUI

struct PresentationDetentsModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content.presentationDetents([.medium, .large])
        } else {
            content
        }
    }
}

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.05),
                        Color.purple.opacity(0.05)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("Settings")
                            .font(.title2.bold())
                        Spacer()
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .padding(10)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                    }
                    .padding(20)

                    ScrollView {
                        VStack(spacing: 16) {
                            // App Info Section
                            GlassCard {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: "info.circle")
                                            .foregroundColor(.blue)
                                        Text("About")
                                            .font(.headline)
                                        Spacer()
                                    }

                                    Divider()

                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text("App Version")
                                                .foregroundColor(.secondary)
                                            Spacer()
                                            Text("0.1.0")
                                                .monospacedDigit()
                                                .font(.caption)
                                        }

                                        HStack {
                                            Text("Build")
                                                .foregroundColor(.secondary)
                                            Spacer()
                                            Text("1")
                                                .monospacedDigit()
                                                .font(.caption)
                                        }
                                    }
                                }
                            }

                            // Debug Section
                            GlassCard {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: "wrench.and.screwdriver")
                                            .foregroundColor(.orange)
                                        Text("Debug Tools")
                                            .font(.headline)
                                        Spacer()
                                    }

                                    Divider()

                                    VStack(spacing: 12) {
                                        Button(action: {
                                            viewModel.clearAllData()
                                        }) {
                                            HStack {
                                                Image(systemName: "trash")
                                                    .foregroundColor(.red)
                                                Text("Clear All Data")
                                                    .foregroundColor(.red)
                                                Spacer()
                                            }
                                            .padding(12)
                                            .background(.red.opacity(0.1))
                                            .cornerRadius(8)
                                        }

                                        if !viewModel.clearMessage.isEmpty {
                                            HStack {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.green)
                                                Text(viewModel.clearMessage)
                                                    .font(.caption)
                                                    .foregroundColor(.green)
                                            }
                                            .padding(10)
                                            .background(.green.opacity(0.1))
                                            .cornerRadius(8)
                                            .transition(.scale.combined(with: .opacity))
                                        }
                                    }
                                }
                            }

                            // Privacy Section
                            GlassCard {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: "lock")
                                            .foregroundColor(.blue)
                                        Text("Privacy")
                                            .font(.headline)
                                        Spacer()
                                    }

                                    Divider()

                                    Text("All photos remain on your device. No data is shared or uploaded to the cloud.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .modifier(PresentationDetentsModifier())
    }
}

#Preview {
    SettingsView()
}
