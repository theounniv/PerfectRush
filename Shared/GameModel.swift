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

    @Published var haptics: Bool {
        didSet {
            defaults.set(haptics, forKey: "haptics")
        }
    }

    // UserDefaults conserve les petites données après la fermeture de l'app.
    private let defaults: UserDefaults
    private var lastFrame: TimeInterval?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        best = defaults.integer(forKey: "best")
        haptics = defaults.object(forKey: "haptics") as? Bool ?? true
    }

    func start() {
        engine.start()
        message = "Vise le centre"
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
        saveBestScore()
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

    private func saveBestScore() {
        if engine.score > best {
            best = engine.score
            defaults.set(best, forKey: "best")
        }
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
