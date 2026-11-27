// Projet de cours — Théo BOREL et Lana SCHMITT.
// Tests du modèle de l'app : sauvegarde par compte et envoi de la progression.
// GameModel dépend de SwiftUI : ces tests tournent dans Xcode (⌘ U), pas avec swift test.
import XCTest
@testable import PerfectRush

@MainActor
final class GameModelTests: XCTestCase {
    private var suiteName = ""
    private var defaults: UserDefaults!

    // Chaque test utilise des UserDefaults neufs pour ne pas toucher aux vraies données.
    override func setUp() {
        super.setUp()
        suiteName = "GameModelTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    private func wallet(hits: Int) -> RewardsProgress {
        var rewards = RewardsProgress()
        for _ in 0..<hits { _ = rewards.recordHit(.good, isFever: false) }
        return rewards
    }

    func testEachAccountKeepsItsOwnProgress() {
        let first = GameModel(defaults: defaults, accountID: "A")
        first.replaceProgress(SavedProgress(best: 12, rewards: wallet(hits: 3), updatedAt: Date()))

        let second = GameModel(defaults: defaults, accountID: "B")
        XCTAssertEqual(second.best, 0)
        XCTAssertEqual(second.rewards.balance, 0)

        let firstAgain = GameModel(defaults: defaults, accountID: "A")
        XCTAssertEqual(firstAgain.best, 12)
        XCTAssertEqual(firstAgain.rewards.balance, 30)
    }

    func testFirstAccountAdoptsProgressFromBeforeAccounts() {
        defaults.set(7, forKey: "best")

        XCTAssertEqual(GameModel(defaults: defaults, accountID: "A").best, 7)
        // L'ancienne progression est retirée : un deuxième compte ne la récupère pas.
        XCTAssertNil(defaults.object(forKey: "best"))
        XCTAssertEqual(GameModel(defaults: defaults, accountID: "B").best, 0)
    }

    func testWatchWithoutAccountKeepsOriginalKeys() {
        defaults.set(5, forKey: "best")

        XCTAssertEqual(GameModel(defaults: defaults).best, 5)
        XCTAssertEqual(defaults.integer(forKey: "best"), 5)
    }

    func testRefusedPurchaseIsNotSentToAccount() {
        let model = GameModel(defaults: defaults, accountID: "A")
        var sent = 0
        model.onProgressSaved = { _ in sent += 1 }

        model.buyTheme(.violet)

        XCTAssertEqual(sent, 0)
        XCTAssertEqual(model.shopMessage, "Solde fictif insuffisant. Aucun montant débité.")
    }

    func testChoosingOwnedColorIsSentToAccount() {
        let model = GameModel(defaults: defaults, accountID: "A")
        var received: SavedProgress?
        model.onProgressSaved = { received = $0 }

        model.buyTheme(.mint)

        XCTAssertEqual(received?.rewards.selectedTheme, .mint)
        XCTAssertNotEqual(received?.updatedAt, .distantPast)
    }

    func testCloudProgressIsSavedButNotSentBack() {
        let model = GameModel(defaults: defaults, accountID: "A")
        var sent = 0
        model.onProgressSaved = { _ in sent += 1 }
        let cloud = SavedProgress(best: 20, rewards: wallet(hits: 5), updatedAt: Date(timeIntervalSince1970: 500))

        model.replaceProgress(cloud)

        XCTAssertEqual(sent, 0)
        XCTAssertEqual(model.savedProgress, cloud)
        XCTAssertEqual(GameModel(defaults: defaults, accountID: "A").savedProgress, cloud)
    }
}
