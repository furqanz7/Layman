import SwiftUI

struct CircleIconButton: View {
    @Environment(\.colorScheme) private var colorScheme
    let systemName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(colorScheme == .dark ? Color(.secondarySystemBackground) : Color.white.opacity(0.92))
                    .frame(width: 34, height: 34)

                Image(systemName: systemName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(LaymanTheme.text(colorScheme).opacity(0.75))
            }
        }
    }
}
