// Projet de cours — Théo BOREL et Lana SCHMITT.
// La boutique dépense uniquement la monnaie fictive du jeu.
import SwiftUI

// La même couleur est utilisée par la piste, les boutons et les aperçus.
extension RushTheme {
    var color: Color {
        switch self {
        case .mint: return .mint
        case .violet: return Color(red: 0.72, green: 0.48, blue: 1)
        case .gold: return .yellow
        case .ice: return .cyan
        }
    }
}

/// Écran Défis & couleurs, commun à l'iPhone et à la Watch : solde, boutique et défis.
struct RewardsView: View {
    // @ObservedObject lit le modèle existant : on ne crée pas un deuxième portefeuille.
    @ObservedObject var model: GameModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("TON PORTEFEUILLE").font(.caption.bold()).accessibilityIdentifier("shopTitle")
                Text(RewardsProgress.money(model.rewards.balance))
                    .font(.largeTitle.bold()).minimumScaleFactor(0.6)
                Text("Solde fictif — aucun retrait possible")
                    .font(.caption).foregroundStyle(.secondary)
                Text("0,10 € fictif par étage + 0,25 € par Perfect.")
                    .font(.caption)

                Text("TES COULEURS").font(.headline)
                ForEach(RushTheme.allCases, id: \.self) { theme in
                    themeButton(theme)
                }
                Text(model.shopMessage).font(.caption).foregroundStyle(.secondary)

                Text("DÉFIS PERMANENTS").font(.headline)
                ForEach(RushChallenge.allCases, id: \.self) { challenge in
                    challengeCard(challenge)
                }
                Text("Les défis progressent sur plusieurs parties. Chaque bonus est versé une seule fois.")
                    .font(.caption).foregroundStyle(.secondary)
                Button("Retour au jeu") { dismiss() }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("closeShop")
            }
            .padding()
        }
    }

    /// Une ligne de la boutique : équipée, possédée (à choisir) ou verrouillée avec son prix.
    /// Le bouton est désactivé quand le solde ne suffit pas.
    private func themeButton(_ theme: RushTheme) -> some View {
        let owned = model.rewards.ownedThemes.contains(theme)
        let selected = model.rewards.selectedTheme == theme
        return Button {
            model.buyTheme(theme)
        } label: {
            HStack {
                Circle().fill(theme.color).frame(width: 18, height: 18)
                VStack(alignment: .leading) {
                    Text(theme.name).font(.headline)
                    if selected {
                        Text("Équipée").font(.caption)
                    } else if owned {
                        Text("Choisir").font(.caption)
                    } else {
                        Text(RewardsProgress.money(theme.price) + " fictifs").font(.caption)
                    }
                }
                Spacer()
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                } else if !owned {
                    Image(systemName: "lock.fill")
                }
            }
            .padding(8)
        }
        .buttonStyle(.bordered)
        .tint(theme.color)
        .disabled(!owned && model.rewards.balance < theme.price)
        .accessibilityIdentifier("theme-" + theme.rawValue)
    }

    /// Carte d'un défi : barre d'avancement, puis « Bonus reçu » une fois réussi.
    private func challengeCard(_ challenge: RushChallenge) -> some View {
        let progress = model.rewards.progress(for: challenge)
        let completed = model.rewards.completedChallenges.contains(challenge)
        return VStack(alignment: .leading, spacing: 6) {
            Text(challenge.title).font(.caption.bold())
            ProgressView(value: Double(progress), total: Double(challenge.goal))
            if completed {
                Label("Bonus reçu", systemImage: "checkmark.circle.fill")
                    .font(.caption).foregroundStyle(.mint)
            } else {
                Text("\(progress)/\(challenge.goal) · +" + RewardsProgress.money(challenge.reward) + " fictifs")
                    .font(.caption)
            }
        }
        .padding(10)
        .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
    }
}
