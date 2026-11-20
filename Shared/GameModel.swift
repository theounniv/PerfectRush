// Projet de cours — Théo BOREL et Lana SCHMITT.
// Le modèle relie les règles du jeu à l'écran et sauvegarde le record.
import Foundation
import Combine

#if os(iOS)
import UIKit
#elseif os(watchOS)
import WatchKit
#endif

// Les changements de l'interface sont réalisés sur l'acteur principal.
@MainActor
final class GameModel: ObservableObject {
    // @Published prévient SwiftUI lorsqu'une valeur affichée change.
    @Published private(set) var engine = GameEngine()
    @Published private(set) var best: Int
    @Published private(set) var message = "Vise le centre"
    @Published private(set) var rewards: RewardsProgress
    @Published private(set) var runRewardCents = 0
    @Published private(set) var lastRewardCents = 0
    @Published private(set) var shopMessage = "Les couleurs ne changent pas la difficulté."

    @Published var haptics: Bool {
        didSet {
            defaults.set(haptics, forKey: "haptics")
        }
    }

    // Appelé après chaque changement de progression : l'iPhone l'envoie alors au compte.
    var onProgressSaved: ((SavedProgress) -> Void)?

    // UserDefaults conserve les petites données après la fermeture de l'app.
    private let defaults: UserDefaults
    // Préfixe des clés : chaque compte a sa propre progression sur l'iPhone. Vide sur la Watch.
    private let keyPrefix: String
    private var updatedAt: Date
    private var lastFrame: TimeInterval?

    // accountID est l'identifiant Firebase (uid) ; nil pour la Watch, qui joue sans compte.
    init(defaults: UserDefaults = .standard, accountID: String? = nil) {
        self.defaults = defaults
        let prefix = accountID.map { "account.\($0)." } ?? ""
        keyPrefix = prefix
        if accountID != nil {
            Self.adoptDeviceProgress(defaults, prefix: prefix)
        }
        best = defaults.integer(forKey: prefix + "best")
        // Les vibrations sont un réglage de l'appareil, communes à tous les comptes.
        haptics = defaults.object(forKey: "haptics") as? Bool ?? true
        updatedAt = defaults.object(forKey: prefix + "progress-date") as? Date ?? .distantPast
        // JSONEncoder/Decoder sauvegardent toute la progression en une seule donnée.
        if let data = defaults.data(forKey: prefix + "rewards-v1"),
           let saved = try? JSONDecoder().decode(RewardsProgress.self, from: data) {
            rewards = saved
        } else {
            rewards = RewardsProgress()
        }
    }

    // La progression faite avant l'ajout des comptes est donnée au premier compte connecté,
    // puis retirée pour qu'un autre compte ne la récupère pas aussi.
    private static func adoptDeviceProgress(_ defaults: UserDefaults, prefix: String) {
        if defaults.object(forKey: prefix + "best") != nil || defaults.object(forKey: prefix + "rewards-v1") != nil {
            return
        }
        for key in ["best", "rewards-v1"] {
            if let value = defaults.object(forKey: key) {
                defaults.set(value, forKey: prefix + key)
                defaults.removeObject(forKey: key)
            }
        }
    }

    // Toute la progression du compte en une seule valeur, prête à être envoyée.
    var savedProgress: SavedProgress {
        SavedProgress(best: best, rewards: rewards, updatedAt: updatedAt)
    }

    // Remplace la progression par celle du cloud, sans la renvoyer aussitôt.
    func replaceProgress(_ progress: SavedProgress) {
        best = progress.best
        rewards = progress.rewards
        updatedAt = progress.updatedAt
        defaults.set(best, forKey: keyPrefix + "best")
        saveRewards()
        defaults.set(updatedAt, forKey: keyPrefix + "progress-date")
    }

    // Note la date du changement puis prévient le compte.
    private func progressChanged() {
        updatedAt = Date()
        defaults.set(updatedAt, forKey: keyPrefix + "progress-date")
        onProgressSaved?(savedProgress)
    }

    func start() {
        engine.start()
        message = "Vise le centre"
        runRewardCents = 0
        lastRewardCents = 0
        lastFrame = nil
    }

    // Le Timer de l'écran appelle cette méthode régulièrement.
    func frame() {
        if engine.phase != .playing {
            lastFrame = nil
            return
        }

        // Cette horloge mesure une durée ; changer l'heure du téléphone
        // ne change donc pas la vitesse du jeu.
        let now = ProcessInfo.processInfo.systemUptime
        if let previous = lastFrame {
            engine.advance(by: now - previous)
        }
        lastFrame = now
    }

    func tap() {
        let result = engine.tap()
        if result == .ignored {
            return
        }

        updateMessage(for: result)
        lastRewardCents = rewards.recordHit(result, isFever: engine.isFever)
        runRewardCents += lastRewardCents
        var changed = false
        if lastRewardCents > 0 {
            saveRewards()
            changed = true
        }
        if saveBestScore() {
            changed = true
        }
        if changed {
            progressChanged()
        }
        playHaptic(for: result)
    }

    private func updateMessage(for result: HitResult) {
        switch result {
        case .perfect:
            if engine.isFever {
                message = "FEVER · PERFECT !"
            } else {
                message = "PERFECT !"
            }
        case .good:
            message = "Bien joué !"
        case .shieldBroken:
            message = "Bouclier brisé !"
        case .gameOver:
            message = "Partie terminée"
        case .ignored:
            break
        }
    }

    // Renvoie vrai si un nouveau record a été enregistré.
    private func saveBestScore() -> Bool {
        if engine.score > best {
            best = engine.score
            defaults.set(best, forKey: keyPrefix + "best")
            return true
        }
        return false
    }

    // Même sans finir la partie, les gains déjà obtenus sont conservés.
    private func saveRewards() {
        if let data = try? JSONEncoder().encode(rewards) {
            defaults.set(data, forKey: keyPrefix + "rewards-v1")
        }
    }

    func buyTheme(_ theme: RushTheme) {
        let result = rewards.buyOrSelect(theme)
        switch result {
        case .purchased:
            shopMessage = theme.name + " débloquée avec ton solde fictif !"
        case .selected:
            shopMessage = theme.name + " équipée."
        case .insufficientFunds:
            shopMessage = "Solde fictif insuffisant. Aucun montant débité."
            return
        }
        saveRewards()
        progressChanged()
    }

    // iPhone et Apple Watch utilisent des API différentes pour vibrer.
    private func playHaptic(for result: HitResult) {
        if !haptics {
            return
        }
        let isMistake = result == .shieldBroken || result == .gameOver

        #if os(iOS)
        let feedback = UINotificationFeedbackGenerator()
        if isMistake {
            feedback.notificationOccurred(.warning)
        } else {
            feedback.notificationOccurred(.success)
        }
        #elseif os(watchOS)
        if isMistake {
            WKInterfaceDevice.current().play(.failure)
        } else {
            WKInterfaceDevice.current().play(.click)
        }
        #endif
    }

    func pause() {
        engine.pause()
        lastFrame = nil
    }

    func resume() {
        engine.resume()
        // Oublier l'ancienne image évite un saut du curseur après la pause.
        lastFrame = nil
    }
}
