import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [LaymanTheme.peach, LaymanTheme.orange],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack {
                
                // TOP — Logo
                Text("Layman")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(LaymanTheme.text(colorScheme))
                    .padding(.top, 40)

                Spacer()

                // CENTER — Slogan
                (
                    Text("Business,\ntech & startups\n")
                    + Text("made simple")
                        .foregroundStyle(LaymanTheme.accent)
                )
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .lineSpacing(2)

                Spacer()

                // BOTTOM — Swipe
                SwipeToStartControl(offset: $dragOffset) {
                    appState.completeWelcome()
                }
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 42)
        }
    }
}

private struct SwipeToStartControl: View {
    @Binding var offset: CGFloat
    let action: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let knobSize: CGFloat = 56
            let maxOffset = width - knobSize - 12

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .fill(LaymanTheme.accent.opacity(0.88))
                    .overlay(
                        RoundedRectangle(cornerRadius: 36, style: .continuous)
                            .stroke(.white.opacity(0.22), lineWidth: 1)
                    )

                Text("Swipe to get started")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.92))
                    .frame(maxWidth: .infinity)

                Circle()
                    .fill(Color.white.opacity(0.92))
                    .frame(width: knobSize, height: knobSize)
                    .overlay(
                        Image(systemName: "arrow.right")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(LaymanTheme.accent)
                    )
                    .offset(x: 6 + offset)
                    .animation(.easeInOut(duration: 0.15), value: offset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                offset = min(max(0, value.translation.width), maxOffset)
                            }
                            .onEnded { _ in
                                if offset > maxOffset * 0.78 {
                                    action()
                                }
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                                    offset = 0
                                }
                            }
                    )
            }
        }
        .frame(height: 64)
    }
}

