// Projet de cours — Théo BOREL et Lana SCHMITT.
// Règles de connexion sans Firebase : on peut donc les tester avec swift test.
import Foundation
import CryptoKit

public enum AuthRules {
    // Firebase refuse les mots de passe de moins de 6 caractères.
    public static let minimumPasswordLength = 6

    // Retire les espaces autour et met en minuscules : « Lana@Mail.fr » = « lana@mail.fr ».
    public static func normalizedEmail(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    // Vérification simple avant d'appeler Firebase : un seul @ et un domaine avec un point.
    public static func isValidEmail(_ email: String) -> Bool {
        if email.contains(" ") { return false }
        let parts = email.split(separator: "@", omittingEmptySubsequences: false)
        if parts.count != 2 || parts[0].isEmpty { return false }
        let domain = parts[1]
        return domain.contains(".") && !domain.hasPrefix(".") && !domain.hasSuffix(".") && !domain.contains("..")
    }

    // Renvoie le message à afficher, ou nil si les champs sont corrects.
    public static func validate(email: String, password: String) -> String? {
        let cleanEmail = normalizedEmail(email)
        if cleanEmail.isEmpty { return "Saisis ton adresse email." }
        if !isValidEmail(cleanEmail) { return "Adresse email invalide." }
        if password.count < minimumPasswordLength {
            return "Le mot de passe doit contenir au moins \(minimumPasswordLength) caractères."
        }
        return nil
    }

    // Les erreurs Firebase Auth ont un numéro (AuthErrorCode). On les traduit pour le joueur.
    public static func message(forErrorCode code: Int) -> String {
        switch code {
        case 17004: return "Email ou mot de passe incorrect."
        case 17005: return "Ce compte a été désactivé."
        case 17006: return "Ce mode de connexion n’est pas activé dans la console Firebase."
        case 17007: return "Un compte existe déjà avec cet email. Connecte-toi."
        case 17008: return "Adresse email invalide."
        case 17009: return "Mot de passe incorrect."
        case 17010: return "Trop de tentatives. Réessaie dans quelques minutes."
        case 17011: return "Aucun compte avec cet email. Crée un compte."
        case 17012: return "Cet email est déjà relié à une autre méthode de connexion."
        case 17020: return "Pas de connexion Internet."
        case 17026: return "Mot de passe trop faible : au moins 6 caractères."
        default: return "La connexion a échoué (code \(code))."
        }
    }

    // Sign in with Apple : chaîne aléatoire à usage unique (le « nonce »).
    // SystemRandomNumberGenerator est un générateur sûr pour la cryptographie sur les appareils Apple.
    public static func randomNonce(length: Int = 32) -> String {
        let characters = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var generator = SystemRandomNumberGenerator()
        var nonce = ""
        for _ in 0..<max(length, 1) {
            nonce.append(characters.randomElement(using: &generator)!)
        }
        return nonce
    }

    // Apple reçoit le hash SHA-256 ; Firebase reçoit le nonce brut et recalcule ce hash pour comparer.
    public static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}
