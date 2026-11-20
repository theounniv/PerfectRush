// Projet de cours — Théo BOREL et Lana SCHMITT.
// Point d'entrée de l'application iPhone.
import SwiftUI
import FirebaseCore

@main
struct PerfectRushApp: App {
    init() {
        // Firebase est configuré une seule fois, au lancement, avant toute connexion.
        // Sans GoogleService-Info.plist, on ne l'appelle pas pour éviter un plantage.
        if FirebaseApp.app() == nil,
           Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
            FirebaseApp.configure()
        }
    }

    var body: some Scene {
        WindowGroup { PhoneGameView().preferredColorScheme(.dark) }
    }
}
