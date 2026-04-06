import AuthenticationServices
import CryptoKit
import SwiftUI

struct AuthView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @State private var email = ""
    @State private var password = ""
    @State private var isLogin = true
    @State private var errorMessage: String?
    @State private var isSubmitting = false
    @State private var appleCoordinator = AppleSignInCoordinator()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(isLogin ? "Welcome back" : "Create account")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(LaymanTheme.text(colorScheme))

                    Text("Business, tech and startups in plain English.")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(LaymanTheme.text(colorScheme).opacity(0.65))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 16) {
                    AuthField(title: "Email", text: $email, keyboardType: .emailAddress)
                    AuthField(title: "Password", text: $password, isSecure: true)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    Haptics.impact(.medium)
                    Task { await submit() }
                } label: {
                    HStack(spacing: 8) {
                        if isSubmitting {
                            ProgressView().tint(.white)
                        }
                        Text(isLogin ? "Log In" : "Sign Up")
                    }
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(LaymanTheme.actionFill)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                }
                .disabled(isSubmitting)
                .buttonStyle(.plain)

                SignInWithAppleButton(.continue) { request in
                    appleCoordinator.prepare(request: request)
                } onCompletion: { result in
                    Task {
                        await handleAppleSignIn(result)
                    }
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .frame(maxWidth: .infinity)

                Button(isLogin ? "Need an account? Sign up" : "Already have an account? Log in") {
                    Haptics.selection()
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                        isLogin.toggle()
                        errorMessage = nil
                    }
                }
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(LaymanTheme.accent)
                .frame(maxWidth: .infinity, alignment: .center)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(.horizontal, 22)
            .padding(.top, 24)
            .padding(.bottom, 32)
            .frame(minHeight: UIScreen.main.bounds.height - 80, alignment: .top)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(LaymanTheme.background(colorScheme))
        .ignoresSafeArea(.container, edges: .bottom)
    }

    private func submit() async {
        guard email.contains("@"), password.count >= 6 else {
            errorMessage = "Use a valid email and a password with at least 6 characters."
            return
        }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            if isLogin {
                try await appState.signIn(email: email, password: password)
            } else {
                try await appState.signUp(email: email, password: password)
            }
            errorMessage = nil
            Haptics.success()
        } catch {
            errorMessage = error.localizedDescription
            Haptics.error()
        }
    }

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) async {
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let token = try appleCoordinator.handle(result: result)
            try await appState.signInWithApple(idToken: token, nonce: appleCoordinator.rawNonce)
            errorMessage = nil
            Haptics.success()
        } catch {
            errorMessage = error.localizedDescription
            Haptics.error()
        }
    }
}

private struct AuthField: View {
    let title: String
    @Binding var text: String
    var isSecure = false
    var keyboardType: UIKeyboardType = .default
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(LaymanTheme.text(colorScheme).opacity(0.62))

            Group {
                if isSecure {
                    SecureField(title, text: $text)
                } else {
                    TextField(title, text: $text)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(keyboardType)
                }
            }
            .font(.system(size: 17, weight: .medium, design: .rounded))
            .foregroundStyle(LaymanTheme.text(colorScheme))
            .tint(LaymanTheme.accent)
            .padding(18)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
    }
}

private struct AppleSignInCoordinator {
    fileprivate var rawNonce = ""

    mutating func prepare(request: ASAuthorizationAppleIDRequest) {
        let nonce = Self.randomNonce()
        rawNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = Self.sha256(nonce)
    }

    func handle(result: Result<ASAuthorization, Error>) throws -> String {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let token = String(data: tokenData, encoding: .utf8) else {
                throw APIError.server("Apple Sign In did not return a usable identity token.")
            }
            return token
        case .failure(let error):
            throw error
        }
    }

    private static func sha256(_ input: String) -> String {
        let digest = SHA256.hash(data: Data(input.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private static func randomNonce(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length

        while remaining > 0 {
            let bytes: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                let status = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if status != errSecSuccess {
                    fatalError("Unable to generate nonce.")
                }
                return random
            }

            bytes.forEach { byte in
                if remaining == 0 { return }
                if byte < charset.count {
                    result.append(charset[Int(byte)])
                    remaining -= 1
                }
            }
        }

        return result
    }
}
