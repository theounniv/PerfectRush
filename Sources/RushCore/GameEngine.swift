// Projet de cours — Théo BOREL et Lana SCHMITT.
// Ce fichier contient uniquement les règles : il ne dessine aucun écran.
import Foundation

// Les quatre états possibles d'une partie.
public enum GamePhase: Equatable {
    case ready
    case playing
    case paused
    case gameOver
}

// Le résultat d'un appui sur le bouton TAP.
public enum HitResult: Equatable {
    case ignored
    case good
    case perfect
    case shieldBroken
    case gameOver
}

public struct GameEngine {
    // L'écran peut lire ces valeurs ; seul le moteur peut les modifier.
    public private(set) var phase: GamePhase = .ready
    public private(set) var score = 0
    public private(set) var floor = 0
    public private(set) var combo = 0
    public private(set) var shield = true
    public private(set) var elapsed: Double = 0
    public private(set) var feverRemaining: Double = 0

    private var travel: Double = 0
    private var lastTap: Double = -.infinity

    public init() {}

    // La piste va de 0 à 1. Après 1, le curseur revient vers 0.
    public var position: Double {
        let value = travel.truncatingRemainder(dividingBy: 2)
        if value <= 1 {
            return value
        }
        return 2 - value
    }

    // Le premier objectif est au milieu. Les suivants changent selon l'étage.
    // Le modulo (%) garde le centre entre 0,25 et 0,75.
    public var targetCenter: Double {
        if floor == 0 {
            return 0.5
        }
        let offset = Double((floor * 37) % 51) / 100
        return 0.25 + offset
    }

    // La cible rétrécit, mais garde une largeur minimale.
    public var targetWidth: Double {
        return max(0.16, 0.34 - Double(floor) * 0.008)
    }

    // La vitesse augmente sans dépasser la limite prévue.
    public var speed: Double {
        return min(1.65, 0.52 + Double(floor) * 0.035)
    }

    public var isFever: Bool {
        return feverRemaining > 0
    }

    public var multiplier: Int {
        return 1 + min(combo / 3, 4)
    }

    // Recréer le moteur remet toutes les valeurs à zéro.
    public mutating func start() {
        self = GameEngine()
        phase = .playing
    }

    public mutating func pause() {
        if phase == .playing {
            phase = .paused
        }
    }

    public mutating func resume() {
        if phase == .paused {
            phase = .playing
        }
    }

    // delta est le nombre de secondes écoulées depuis la dernière image.
    public mutating func advance(by delta: Double) {
        if phase != .playing || !delta.isFinite || delta <= 0 {
            return
        }

        elapsed += delta
        travel += delta * speed
        feverRemaining = max(0, feverRemaining - delta)
    }

    public mutating func tap() -> HitResult {
        // On ignore les appuis hors partie et les doubles appuis trop rapides.
        if phase != .playing || elapsed - lastTap < 0.12 {
            return .ignored
        }
        lastTap = elapsed

        let distance = abs(position - targetCenter)
        // Une petite marge évite les erreurs d'arrondi sur le bord exact.
        let roundingMargin = 0.0000000001
        let isInsideTarget = distance <= targetWidth / 2 + roundingMargin

        if !isInsideTarget {
            combo = 0
            feverRemaining = 0

            if shield {
                shield = false
                return .shieldBroken
            }

            phase = .gameOver
            return .gameOver
        }

        let isPerfect = distance <= targetWidth * 0.15 + roundingMargin
        var points = 1

        if isPerfect {
            combo += 1
            points = 3
            // Chaque série de trois Perfect relance Fever pour cinq secondes.
            if combo % 3 == 0 {
                feverRemaining = 5
            }
        } else {
            combo = 0
        }

        points *= multiplier
        if isFever {
            points *= 2
        }

        score += points
        floor += 1
        travel = 0

        if isPerfect {
            return .perfect
        }
        return .good
    }
}
