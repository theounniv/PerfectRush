// Projet de cours — Théo BOREL et Lana SCHMITT.
// Écran de connexion par email et mot de passe.
import SwiftUI

struct AuthView: View {
    // L'état de connexion vient du gestionnaire partagé.
    @ObservedObject var auth: AuthManager
    // Les champs restent locaux à cet écran.
    @State private var email = ""
    @State private var password = ""
    @FocusState private var focusedField: Field?

    private enum Field { case email, password }
    private let accent = Color(red: 0.35, green: 0.95, blue: 0.75)

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.025, green: 0.04, blue: 0.09), .black],
                           startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 22) {
                    VStack(spacing: 3) {
                        Text("PERFECT").font(.caption.bold()).tracking(6).foregroundStyle(.secondary)
                        Text("RUSH").font(.system(size: 44, weight: .black, design: .rounded)).italic()
                        Text("Connecte-toi pour jouer").font(.subheadline).foregroundStyle(.secondary)
                    }
                    .padding(.top, 30)

                    emailForm

                    if auth.isLoading { ProgressView().tint(accent) }
                    if let message = auth.errorMessage {
                        Text(message)
                            .font(.footnote).foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .accessibilityLabel("Erreur : \(message)")
                    }
                    Text("Le portefeuille et les couleurs restent fictifs et enregistrés sur cet appareil.")
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
                .padding(14).background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
            SecureField("Mot de passe (6 caractères minimum)", text: $password)
                .textContentType(.password)
                .focused($focusedField, equals: .password)
                .submitLabel(.go)
                .onSubmit { signIn() }
                .padding(14).background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
            Button(action: signIn) {
                Text("Se connecter").font(.headline)
                    .frame(maxWidth: .infinity).padding(.vertical, 15)
                    .foregroundStyle(.black).background(accent, in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
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
        }
    }

    private func signIn() {
        focusedField = nil
        Task { await auth.signIn(email: email, password: password) }
    }
}
