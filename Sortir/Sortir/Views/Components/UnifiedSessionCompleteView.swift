import SwiftUI

/// Unified session completion view that works with any workflow configuration
/// Displays completion messages, stats, and action counts based on the workflow actions
struct UnifiedSessionCompleteView: View {
    let leftCount: Int
    let rightCount: Int
    let leftAction: WorkflowAction
    let rightAction: WorkflowAction
    let onDone: () -> Void

    private var total: Int { leftCount + rightCount }

    private var cheekyMessage: (title: String, subtitle: String) {
        SessionMessageGenerator.generateMessage(
            leftCount: leftCount,
            rightCount: rightCount,
            leftAction: leftAction,
            rightAction: rightAction
        )
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon based on action types
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

            // Dynamic stats card using workflow action properties
            VStack(spacing: 12) {
                // Left action stats
                HStack {
                    Image(systemName: leftAction.icon)
                        .foregroundColor(leftAction.color)
                    Text(leftAction.displayName)
                    Spacer()
                    Text("\(leftCount)")
                        .font(.title3.bold())
                }

                Divider()

                // Right action stats
                HStack {
                    Image(systemName: rightAction.icon)
                        .foregroundColor(rightAction.color)
                    Text(rightAction.displayName)
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
    UnifiedSessionCompleteView(
        leftCount: 15,
        rightCount: 5,
        leftAction: .delete(),
        rightAction: .keep(),
        onDone: {}
    )
}
