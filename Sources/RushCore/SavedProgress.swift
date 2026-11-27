// Projet de cours — Théo BOREL et Lana SCHMITT.
// Progression d'un compte : ce qui est sauvegardé sur l'appareil et dans le cloud.
import Foundation

/// Tout ce qui appartient à un compte : record et portefeuille, avec la date de modification.
public struct SavedProgress: Codable, Equatable {
    public var best: Int
    public var rewards: RewardsProgress
    // Date de la dernière modification : sert à savoir quelle copie est la plus récente.
    public var updatedAt: Date

    public init(best: Int = 0, rewards: RewardsProgress = RewardsProgress(), updatedAt: Date = .distantPast) {
        self.best = best
        self.rewards = rewards
        self.updatedAt = updatedAt
    }

    // Choisit la progression à garder quand l'iPhone et le cloud ne sont pas d'accord.
    // Le portefeuille ne s'additionne pas (un achat le fait baisser) : on garde la copie la plus récente.
    // Le record, lui, ne peut que monter : on garde le meilleur des deux.
    public static func merge(local: SavedProgress, remote: SavedProgress) -> SavedProgress {
        var kept = remote
        if local.updatedAt > remote.updatedAt {
            kept = local
        }
        kept.best = max(local.best, remote.best)
        return kept
    }
}
