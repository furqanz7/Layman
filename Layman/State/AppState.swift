import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published var session: UserSession?
    @Published var hasCompletedWelcome = UserDefaults.standard.bool(forKey: "hasCompletedWelcome")
    @Published var isBootstrapping = true

    private let authService = AuthService()

    func bootstrap() async {
        guard isBootstrapping else { return }
        if let storedSession = authService.restoreSession() {
            session = (try? await authService.refreshSession(storedSession)) ?? storedSession
        }
        isBootstrapping = false
    }

    func completeWelcome() {
        hasCompletedWelcome = true
        UserDefaults.standard.set(true, forKey: "hasCompletedWelcome")
    }

    func signIn(email: String, password: String) async throws {
        session = try await authService.signIn(email: email, password: password)
        Haptics.success()
    }

    func signUp(email: String, password: String) async throws {
        session = try await authService.signUp(email: email, password: password)
        Haptics.success()
    }

    func signInWithApple(idToken: String, nonce: String) async throws {
        session = try await authService.signInWithApple(idToken: idToken, nonce: nonce)
        Haptics.success()
    }

    func signOut() {
        authService.signOut()
        Haptics.selection()
        session = nil
    }
}
