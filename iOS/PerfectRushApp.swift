// Projet de cours — Théo BOREL et Lana SCHMITT.
// Point d'entrée de l'application iPhone.
import SwiftUI

@main
struct PerfectRushApp: App {
    var body: some Scene {
        WindowGroup { PhoneGameView().preferredColorScheme(.dark) }
    }
}
