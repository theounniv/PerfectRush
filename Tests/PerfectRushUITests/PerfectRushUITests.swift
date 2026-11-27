// Projet de cours — Théo BOREL et Lana SCHMITT.
// Tests d'interface : ils lancent l'app iPhone et touchent les boutons comme un joueur.
// L'argument « -ui-testing » ouvre directement le jeu, sans Firebase et avec une progression vide.
import XCTest

final class PerfectRushUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    private func launchGame() {
        app.launchArguments = ["-ui-testing"]
        app.launch()
        XCTAssertTrue(app.buttons["play"].waitForExistence(timeout: 10), "Le bouton JOUER doit s’afficher")
    }

    // MARK: Jeu

    func testNewPlayerStartsWithEmptyProgress() {
        launchGame()
        XCTAssertEqual(app.staticTexts["bestScore"].label, "RECORD 0")
        XCTAssertEqual(app.staticTexts["shield"].label, "PRÊT")
        XCTAssertTrue(app.buttons["wallet"].label.contains("0,00 €"))
        XCTAssertFalse(app.buttons["pause"].exists, "Pas de pause avant le début de la partie")
    }

    func testPlayShowsTapAndPauseButtons() {
        launchGame()
        app.buttons["play"].tap()

        XCTAssertTrue(app.buttons["tap"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["pause"].exists)
        XCTAssertFalse(app.buttons["play"].exists)
    }

    func testPauseFreezesGameUntilResume() {
        launchGame()
        app.buttons["play"].tap()
        app.buttons["pause"].tap()

        XCTAssertTrue(app.staticTexts["pausedLabel"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["tap"].exists, "TAP disparaît pendant la pause")

        app.buttons["resume"].tap()
        XCTAssertTrue(app.buttons["tap"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.staticTexts["pausedLabel"].exists)
    }

    // MARK: Boutique

    func testShopPausesGameAndLocksExpensiveColors() {
        launchGame()
        app.buttons["play"].tap()
        app.buttons["wallet"].tap()

        XCTAssertTrue(app.staticTexts["shopTitle"].waitForExistence(timeout: 3))
        // Solde à 0 € : les couleurs payantes ne peuvent pas être achetées.
        XCTAssertFalse(app.buttons["theme-violet"].isEnabled)
        XCTAssertFalse(app.buttons["theme-ice"].isEnabled)
        XCTAssertTrue(app.buttons["theme-mint"].isEnabled)

        app.buttons["closeShop"].tap()
        // Ouvrir la boutique a mis la partie en pause : la reprise reste manuelle.
        XCTAssertTrue(app.buttons["resume"].waitForExistence(timeout: 3))
    }

    // MARK: Réglages

    func testVibrationsCanBeTurnedOff() {
        launchGame()
        let toggle = app.switches["haptics"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 3))
        XCTAssertEqual(toggle.value as? String, "1")

        // On touche l'interrupteur lui-même, à droite de la ligne.
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
        XCTAssertEqual(toggle.value as? String, "0")
    }

    func testTestModeDoesNotUseTheCloud() {
        launchGame()
        XCTAssertEqual(app.staticTexts["syncStatus"].label, "Mode test : progression gardée sur l’iPhone")
    }

    // MARK: Connexion

    // Lancement normal : l'écran de connexion vérifie les champs avant d'appeler Firebase.
    func testSignInRejectsInvalidEmail() throws {
        app.launch()
        let email = app.textFields["email"]
        guard email.waitForExistence(timeout: 10) else {
            throw XCTSkip("Un compte est déjà connecté sur ce simulateur.")
        }
        try XCTSkipUnless(email.isEnabled, "Firebase n’est pas configuré (iOS/GoogleService-Info.plist absent).")

        email.tap()
        email.typeText("joueur")
        let password = app.secureTextFields["password"]
        password.tap()
        password.typeText("123456")
        app.buttons["signIn"].tap()

        let error = app.staticTexts["authError"]
        XCTAssertTrue(error.waitForExistence(timeout: 3))
        XCTAssertEqual(error.label, "Adresse email invalide.")
    }
}
