// Projet de cours — Théo BOREL et Lana SCHMITT.
// Économie fictive : les montants sont des centimes entiers, jamais des euros réels.
import Foundation

/// Couleurs de la boutique. rawValue sert à la sauvegarde et aux identifiants des tests d'interface.
public enum RushTheme: String, CaseIterable, Codable {
    case mint, violet, gold, ice

    /// Nom affiché dans la boutique.
    public var name: String {
        switch self {
        case .mint: return "Menthe"
        case .violet: return "Néon violet"
        case .gold: return "Or solaire"
        case .ice: return "Glacier"
        }
    }

    /// Prix en centimes fictifs (200 = 2,00 €).
    public var price: Int {
        switch self {
        case .mint: return 0
        case .violet: return 200
        case .gold: return 500
        case .ice: return 900
        }
    }
}

/// Ce qui s'est passé quand le joueur touche une couleur dans la boutique.
public enum PurchaseResult: Equatable {
    case purchased, selected, insufficientFunds
}

/// Défis permanents : ils avancent sur plusieurs parties et rapportent un bonus une seule fois.
public enum RushChallenge: String, CaseIterable, Codable {
    case fivePerfects, twentyFloors, firstFever

    public var title: String {
        switch self {
        case .fivePerfects: return "Réussir 5 Perfect au total"
        case .twentyFloors: return "Atteindre 20 étages au total"
        case .firstFever: return "Déclencher un premier Fever"
        }
    }

    /// Valeur à atteindre pour réussir le défi.
    public var goal: Int {
        switch self {
        case .fivePerfects: return 5
        case .twentyFloors: return 20
        case .firstFever: return 1
        }
    }

    /// Bonus en centimes fictifs versé à la réussite.
    public var reward: Int {
        switch self {
        case .fivePerfects: return 100
        case .twentyFloors: return 200
        case .firstFever: return 150
        }
    }
}

/// Portefeuille fictif du joueur : solde, compteurs des défis et couleurs possédées.
/// Codable permet de l'enregistrer d'un bloc (UserDefaults et Firestore).
public struct RewardsProgress: Codable, Equatable {
    public private(set) var balance = 0
    public private(set) var totalFloors = 0
    public private(set) var totalPerfects = 0
    public private(set) var hasTriggeredFever = false
    public private(set) var ownedThemes: [RushTheme] = [.mint]
    public private(set) var selectedTheme: RushTheme = .mint
    public private(set) var completedChallenges: [RushChallenge] = []

    public init() {}

    // Exemple : 135 centimes devient « 1,35 € ». Aucun calcul avec des décimales.
    public static func money(_ cents: Int) -> String {
        let remainder = String(format: "%02d", cents % 100)
        return "\(cents / 100),\(remainder) €"
    }

    /// Avancement d'un défi, plafonné à son objectif pour l'affichage de la barre.
    public func progress(for challenge: RushChallenge) -> Int {
        switch challenge {
        case .fivePerfects: return min(totalPerfects, challenge.goal)
        case .twentyFloors: return min(totalFloors, challenge.goal)
        case .firstFever: return hasTriggeredFever ? 1 : 0
        }
    }

    // Cette méthode est appelée une seule fois par appui accepté par le moteur.
    // Elle renvoie le montant gagné, bonus de défi inclus.
    public mutating func recordHit(_ result: HitResult, isFever: Bool) -> Int {
        if result != .good && result != .perfect {
            return 0
        }

        totalFloors += 1
        var earned = 10
        if result == .perfect {
            totalPerfects += 1
            earned += 25
        }
        if isFever {
            hasTriggeredFever = true
        }

        // Un défi permanent est récompensé une seule fois, sans délai à respecter.
        for challenge in RushChallenge.allCases {
            if progress(for: challenge) == challenge.goal && !completedChallenges.contains(challenge) {
                earned += challenge.reward
                completedChallenges.append(challenge)
            }
        }

        balance += earned
        return earned
    }

    /// Équipe une couleur déjà possédée, ou l'achète si le solde suffit.
    /// Un achat refusé ne change rien : ni débit, ni couleur.
    public mutating func buyOrSelect(_ theme: RushTheme) -> PurchaseResult {
        if ownedThemes.contains(theme) {
            selectedTheme = theme
            return .selected
        }
        if balance < theme.price {
            return .insufficientFunds
        }

        // On vérifie d'abord le prix, puis on débite une seule fois.
        balance -= theme.price
        ownedThemes.append(theme)
        selectedTheme = theme
        return .purchased
    }
}
