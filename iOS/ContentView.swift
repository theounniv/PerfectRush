// Projet de cours — Théo BOREL et Lana SCHMITT.
// Vue racine : l'écran de connexion tant que personne n'est connecté, puis le jeu.
import SwiftUI

struct ContentView: View {
    // Créé une seule fois et conservé pendant toute la vie de l'app.
    @StateObject private var auth = AuthManager()

    var body: some View {
        Group {
            if auth.isAuthenticated {
                PhoneGameView(auth: auth)
            } else {
                AuthView(auth: auth)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: auth.isAuthenticated)
    }
}
