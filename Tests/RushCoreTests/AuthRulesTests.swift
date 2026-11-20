// Projet de cours — Théo BOREL et Lana SCHMITT.
// Tests des règles de connexion : aucun appel réseau, aucun compte Firebase nécessaire.
import XCTest
#if canImport(RushCore)
@testable import RushCore
#else
@testable import PerfectRush
#endif

final class AuthRulesTests: XCTestCase {
    func testEmailIsTrimmedAndLowercased() {
        XCTAssertEqual(AuthRules.normalizedEmail("  Lana@Exemple.FR \n"), "lana@exemple.fr")
    }

    func testValidEmailsAreAccepted() {
        XCTAssertTrue(AuthRules.isValidEmail("joueur@exemple.fr"))
        XCTAssertTrue(AuthRules.isValidEmail("theo.borel+rush@iut.univ.fr"))
    }

    func testInvalidEmailsAreRejected() {
        for email in ["", "joueur", "@exemple.fr", "joueur@", "joueur@exemple", "a@b@c.fr",
                      "joueur@.fr", "joueur@exemple.", "joueur@exemple..fr", "jou eur@exemple.fr"] {
            XCTAssertFalse(AuthRules.isValidEmail(email), email)
        }
    }

    func testValidationMessages() {
        XCTAssertEqual(AuthRules.validate(email: "  ", password: "secret"), "Saisis ton adresse email.")
        XCTAssertEqual(AuthRules.validate(email: "joueur", password: "secret"), "Adresse email invalide.")
        XCTAssertEqual(AuthRules.validate(email: "joueur@exemple.fr", password: "12345"),
                       "Le mot de passe doit contenir au moins 6 caractères.")
        XCTAssertNil(AuthRules.validate(email: " Joueur@Exemple.fr ", password: "123456"))
    }

    func testFirebaseErrorCodesAreTranslated() {
        XCTAssertEqual(AuthRules.message(forErrorCode: 17007), "Un compte existe déjà avec cet email. Connecte-toi.")
        XCTAssertEqual(AuthRules.message(forErrorCode: 17020), "Pas de connexion Internet.")
        XCTAssertEqual(AuthRules.message(forErrorCode: 42), "La connexion a échoué (code 42).")
    }

    func testNonceHasRequestedLengthAndSafeCharacters() {
        let allowed = Set("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = AuthRules.randomNonce(length: 48)
        XCTAssertEqual(nonce.count, 48)
        XCTAssertTrue(nonce.allSatisfy { allowed.contains($0) })
        XCTAssertEqual(AuthRules.randomNonce().count, 32)
    }

    func testNoncesAreDifferentEachTime() {
        XCTAssertNotEqual(AuthRules.randomNonce(), AuthRules.randomNonce())
    }

    func testSha256MatchesKnownValue() {
        // Valeur de référence du standard SHA-256 pour « abc ».
        XCTAssertEqual(AuthRules.sha256("abc"),
                       "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
    }
}
