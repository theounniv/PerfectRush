// Projet de cours — Théo BOREL et Lana SCHMITT.
// Vue racine : l'écran de connexion tant que personne n'est connecté, puis le jeu.
import SwiftUI

/// Vue racine de l'app iPhone : choisit l'écran à afficher selon la connexion.
struct ContentView: View {
    // Créé une seule fois et conservé pendant toute la vie de l'app.
    @StateObject private var auth = AuthManager()

    var body: some View {
        Group {
            if UITestMode.isActive {
                // Tests d'interface : on joue directement, sans Firebase ni réseau.
                PhoneGameView(auth: auth, uid: UITestMode.accountID,
                              defaults: UITestMode.defaults, cloudSync: false)
            } else if auth.isAuthenticated, let uid = auth.user?.uid {
                // .id recrée le jeu si un autre compte se connecte : chacun retrouve sa progression.
                PhoneGameView(auth: auth, uid: uid).id(uid)
            } else {
                AuthView(auth: auth)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: auth.isAuthenticated)
    }
}

// Activé par l'argument « -ui-testing » que passent les tests d'interface (PerfectRushUITests).
// Chaque lancement repart d'une progression vide, enregistrée à part des vraies données.
enum UITestMode {
    static let isActive = ProcessInfo.processInfo.arguments.contains("-ui-testing")
    static let accountID = "ui-tests"

    static let defaults: UserDefaults = {
        let suite = "PerfectRushUITests"
        let defaults = UserDefaults(suiteName: suite) ?? .standard
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }()
}
