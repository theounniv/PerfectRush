// Projet de cours — Théo BOREL et Lana SCHMITT.
// Fond commun aux écrans iPhone : connexion et jeu.
import SwiftUI

struct RushBackground: View {
    var body: some View {
        LinearGradient(colors: [Color(red: 0.025, green: 0.04, blue: 0.09), .black],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
    }
}
