// Projet de cours — Théo BOREL et Lana SCHMITT.
// Toute la logique Firebase est ici : les vues observent seulement l'état publié.
import Foundation
import Combine
import FirebaseCore
import FirebaseAuth

@MainActor
final class AuthManager: ObservableObject {
    // L'utilisateur Firebase connecté (ou nil).
    @Published private(set) var user: User?
    // Vrai si la connexion a réussi.
    @Published private(set) var isAuthenticated = false
    // Le dernier message d'erreur à afficher.
    @Published var errorMessage: String?
    // Empêche de lancer deux connexions en même temps.
    @Published private(set) var isLoading = false

    // Faux si GoogleService-Info.plist manque : l'écran l'explique au lieu de planter.
    let isConfigured: Bool
    private var listener: AuthStateDidChangeListenerHandle?

    init() {
        isConfigured = FirebaseApp.app() != nil
        guard isConfigured else {
            errorMessage = "Firebase n’est pas configuré : ajoute iOS/GoogleService-Info.plist (voir README)."
            return
        }
        apply(Auth.auth().currentUser)
        // Firebase prévient à chaque connexion ou déconnexion, même au relancement de l'app.
        listener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in self?.apply(user) }
        }
    }

    // Texte affiché dans le jeu ; un compte Apple peut ne pas partager son email.
    var accountLabel: String {
        user?.email ?? user?.displayName ?? "Compte connecté"
    }

    // MARK: Email et mot de passe

    func signIn(email: String, password: String) async {
        guard let cleanEmail = checkFields(email: email, password: password) else { return }
        await perform { _ = try await Auth.auth().signIn(withEmail: cleanEmail, password: password) }
    }

    func createAccount(email: String, password: String) async {
        guard let cleanEmail = checkFields(email: email, password: password) else { return }
        await perform { _ = try await Auth.auth().createUser(withEmail: cleanEmail, password: password) }
    }

    // MARK: Déconnexion

    func signOut() {
        guard isConfigured else { return }
        do {
            try Auth.auth().signOut()
            apply(nil)
        } catch {
            errorMessage = "Déconnexion impossible : \(error.localizedDescription)"
        }
    }

    // MARK: Outils internes

    private func apply(_ user: User?) {
        self.user = user
        isAuthenticated = user != nil
        if user != nil { errorMessage = nil }
    }

    private func checkFields(email: String, password: String) -> String? {
        if let problem = AuthRules.validate(email: email, password: password) {
            errorMessage = problem
            return nil
        }
        return AuthRules.normalizedEmail(email)
    }

    // Lance une connexion, affiche le chargement et traduit l'erreur éventuelle.
    private func perform(_ work: () async throws -> Void) async {
        guard isConfigured, !isLoading else { return }
        isLoading = true
        errorMessage = nil
        do {
            try await work()
        } catch {
            report(error)
        }
        isLoading = false
    }

    private func report(_ error: Error) {
        let nsError = error as NSError
        if nsError.domain == AuthErrorDomain {
            errorMessage = AuthRules.message(forErrorCode: nsError.code)
        } else {
            errorMessage = nsError.localizedDescription
        }
        // Le message complet reste lisible dans la console Xcode pour le dépannage.
        print("Erreur d’authentification :", nsError)
    }
}
