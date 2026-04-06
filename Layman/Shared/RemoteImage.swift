import SwiftUI

struct RemoteImage: View {
    let url: URL?

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.opacity.animation(.easeOut(duration: 0.22)))

            case .empty:
                placeholder

            default:
                placeholder
            }
        }
        .clipped()
    }

    private var placeholder: some View {
        LinearGradient(
            colors: [LaymanTheme.peach, LaymanTheme.orange],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(
            Image(systemName: "newspaper.fill")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white.opacity(0.9))
        )
    }
}
