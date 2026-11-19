// Projet de cours — Théo BOREL et Lana SCHMITT.
// Dessine la piste, la zone cible et le curseur blanc.
import SwiftUI

struct RushTrack: View {
    let engine: GameEngine
    var compact = false
    var theme: RushTheme = .mint
    private var tint: Color {
        if engine.isFever { return .orange }
        return theme.color
    }

    var body: some View {
        // GeometryReader donne la taille disponible pour adapter le dessin.
        GeometryReader { geometry in
            // Le moteur utilise 0 à 1 ; on convertit ici en points d’écran.
            let width = max(1, geometry.size.width - 16)
            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.08))
                RoundedRectangle(cornerRadius: 12)
                    .fill(tint.opacity(0.22))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(tint, lineWidth: 2))
                    .frame(width: width * engine.targetWidth)
                    .offset(x: 8 + width * (engine.targetCenter - engine.targetWidth / 2))
                Capsule().fill(tint)
                    .frame(width: 3)
                    .offset(x: 8 + width * engine.targetCenter - 1.5)
                Capsule().fill(.white)
                    .frame(width: compact ? 6 : 8, height: compact ? 42 : 66)
                    .shadow(color: tint.opacity(0.8), radius: 10)
                    .offset(x: 8 + width * engine.position - (compact ? 3 : 4))
            }
        }
        .frame(height: compact ? 46 : 76)
        .accessibilityLabel("Piste de précision")
        .accessibilityValue("Curseur \(Int(engine.position * 100)) pour cent, cible \(Int(engine.targetCenter * 100)) pour cent")
    }
}
