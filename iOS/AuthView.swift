// Projet de cours — Théo BOREL et Lana SCHMITT.
// Écran de connexion : email, Google et Apple.
import SwiftUI
import AuthenticationServices
import GoogleSignInSwift

struct AuthView: View {
    // L'état de connexion vient du gestionnaire partagé.
    @ObservedObject var auth: AuthManager
    // Les champs restent locaux à cet écran.
    @State private var email = ""
    @State private var password = ""
    @FocusState private var focusedField: Field?

    private enum Field { case email, password }
    // Même couleur que le thème de départ du jeu.
    private let accent = RushTheme.mint.color

    var body: some View {
        ZStack {
            RushBackground()
            ScrollView {
                VStack(spacing: 22) {
                    VStack(spacing: 3) {
                        Text("PERFECT").font(.caption.bold()).tracking(6).foregroundStyle(.secondary)
                        Text("RUSH").font(.system(size: 44, weight: .black, design: .rounded)).italic()
                        Text("Connecte-toi pour jouer").font(.subheadline).foregroundStyle(.secondary)
                    }
                    .padding(.top, 30)

                    emailForm
                    separator
                    providerButtons

                    if auth.isLoading { ProgressView().tint(accent) }
                    if let message = auth.errorMessage {
                        Text(message)
                            .font(.footnote).foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .accessibilityIdentifier("authError")
                    }
                    Text("Ta progression (record, solde fictif, couleurs) est enregistrée dans ton compte.")
                        .font(.caption2).foregroundStyle(.secondary).multilineTextAlignment(.center)
                }
                .padding(24)
                .frame(maxWidth: 480)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .disabled(auth.isLoading || !auth.isConfigured)
    }

    private var emailForm: some View {
        VStack(spacing: 12) {
            TextField("Email", text: $email)
                .textContentType(.username)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($focusedField, equals: .email)
                .submitLabel(.next)
                .onSubmit { focusedField = .password }
                .accessibilityIdentifier("email")
                .padding(14).background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
            SecureField("Mot de passe (6 caractères minimum)", text: $password)
                .textContentType(.password)
                .focused($focusedField, equals: .password)
                .submitLabel(.go)
                .onSubmit { signIn() }
                .accessibilityIdentifier("password")
                .padding(14).background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
            Button(action: signIn) {
                Text("Se connecter").font(.headline)
                    .frame(maxWidth: .infinity).padding(.vertical, 15)
                    .foregroundStyle(.black).background(accent, in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("signIn")
            Button {
                focusedField = nil
                Task { await auth.createAccount(email: email, password: password) }
            } label: {
                Text("Créer un compte").font(.headline)
                    .frame(maxWidth: .infinity).padding(.vertical, 15)
                    .foregroundStyle(accent)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(accent, lineWidth: 1.5))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("createAccount")
        }
    }

    private var separator: some View {
        HStack {
            Rectangle().fill(.white.opacity(0.15)).frame(height: 1)
            Text("ou").font(.caption).foregroundStyle(.secondary)
            Rectangle().fill(.white.opacity(0.15)).frame(height: 1)
        }
    }

    private var providerButtons: some View {
        VStack(spacing: 12) {
            GoogleSignInButton(scheme: .dark, style: .wide) {
                Task { await auth.signInWithGoogle() }
            }
            .accessibilityLabel("Continuer avec Google")
            // Le bouton officiel Apple prépare la demande puis reçoit la réponse.
            SignInWithAppleButton(.continue) { request in
                auth.prepareAppleRequest(request)
            } onCompletion: { result in
                Task { await auth.completeApple(result) }
            }
            .signInWithAppleButtonStyle(.white)
            .frame(height: 50)
        }
    }

    private func signIn() {
        focusedField = nil
        Task { await auth.signIn(email: email, password: password) }
    }
}
