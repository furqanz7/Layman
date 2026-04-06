import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Profile")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(LaymanTheme.text(colorScheme))

            VStack(alignment: .leading, spacing: 12) {
                Text(appState.session?.email ?? "No email")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(LaymanTheme.text(colorScheme))

                Text("Signed in to keep saved stories synced.")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(LaymanTheme.text(colorScheme).opacity(0.62))
            }
            .padding(20)
            .background(LaymanTheme.card(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            Button {
                appState.signOut()
            } label: {
                Text("Sign Out")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(LaymanTheme.actionFill)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(20)
        .background(LaymanTheme.background(colorScheme).ignoresSafeArea())
    }
}
