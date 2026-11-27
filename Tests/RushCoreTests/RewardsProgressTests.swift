// Projet de cours — Théo BOREL et Lana SCHMITT.
// Ces tests utilisent des centimes fictifs et ne réalisent aucun paiement.
// Chaque test prépare un portefeuille, réalise une action (gain, achat, défi) puis vérifie le solde.
import XCTest
#if canImport(RushCore)
@testable import RushCore
#else
@testable import PerfectRush
#endif

final class RewardsProgressTests: XCTestCase {
    func testNewWalletIsEmptyWithMintTheme() {
        let progress = RewardsProgress()
        XCTAssertEqual(progress.balance, 0)
        XCTAssertEqual(progress.ownedThemes, [.mint])
        XCTAssertEqual(progress.selectedTheme, .mint)
    }

    func testGoodHitEarnsTenCents() {
        var progress = RewardsProgress()
        XCTAssertEqual(progress.recordHit(.good, isFever: false), 10)
        XCTAssertEqual(progress.balance, 10)
        XCTAssertEqual(progress.totalFloors, 1)
    }

    func testPerfectEarnsThirtyFiveCents() {
        var progress = RewardsProgress()
        XCTAssertEqual(progress.recordHit(.perfect, isFever: false), 35)
        XCTAssertEqual(progress.totalPerfects, 1)
    }

    func testMissesAndIgnoredTapsEarnNothing() {
        var progress = RewardsProgress()
        for result in [HitResult.ignored, .shieldBroken, .gameOver] {
            XCTAssertEqual(progress.recordHit(result, isFever: true), 0)
        }
        XCTAssertEqual(progress.balance, 0)
        XCTAssertFalse(progress.hasTriggeredFever)
        XCTAssertEqual(progress.totalFloors, 0)
    }

    func testPerfectChallengePaysOnlyOnce() {
        var progress = RewardsProgress()
        for _ in 0..<5 { _ = progress.recordHit(.perfect, isFever: false) }
        XCTAssertEqual(progress.balance, 275)
        XCTAssertTrue(progress.completedChallenges.contains(.fivePerfects))
        XCTAssertEqual(progress.recordHit(.perfect, isFever: false), 35)
        XCTAssertEqual(progress.progress(for: .fivePerfects), 5)
    }

    func testFloorChallengePaysOnlyOnce() {
        var progress = RewardsProgress()
        for _ in 0..<20 { _ = progress.recordHit(.good, isFever: false) }
        XCTAssertEqual(progress.balance, 400)
        XCTAssertEqual(progress.recordHit(.good, isFever: false), 10)
    }

    func testFeverChallengePaysOnlyOnce() {
        var progress = RewardsProgress()
        XCTAssertEqual(progress.recordHit(.perfect, isFever: true), 185)
        XCTAssertEqual(progress.recordHit(.perfect, isFever: true), 35)
        XCTAssertTrue(progress.completedChallenges.contains(.firstFever))
    }

    func testPurchaseDebitsPriceAndEquipsTheme() {
        var progress = RewardsProgress()
        for _ in 0..<5 { _ = progress.recordHit(.perfect, isFever: false) }
        XCTAssertEqual(progress.buyOrSelect(.violet), .purchased)
        XCTAssertEqual(progress.balance, 75)
        XCTAssertEqual(progress.selectedTheme, .violet)
        XCTAssertTrue(progress.ownedThemes.contains(.violet))
    }

    func testOwnedThemeIsNeverChargedAgain() {
        var progress = RewardsProgress()
        for _ in 0..<5 { _ = progress.recordHit(.perfect, isFever: false) }
        _ = progress.buyOrSelect(.violet)
        let balance = progress.balance
        XCTAssertEqual(progress.buyOrSelect(.violet), .selected)
        XCTAssertEqual(progress.buyOrSelect(.mint), .selected)
        XCTAssertEqual(progress.balance, balance)
        XCTAssertEqual(progress.ownedThemes.count, 2)
    }

    func testInsufficientFundsLeaveWalletUnchanged() {
        var progress = RewardsProgress()
        _ = progress.recordHit(.good, isFever: false)
        XCTAssertEqual(progress.buyOrSelect(.gold), .insufficientFunds)
        XCTAssertEqual(progress.balance, 10)
        XCTAssertEqual(progress.selectedTheme, .mint)
        XCTAssertEqual(progress.ownedThemes, [.mint])
    }

    func testSaveAndRestorePreservePurchasesAndChallenges() throws {
        var progress = RewardsProgress()
        for _ in 0..<5 { _ = progress.recordHit(.perfect, isFever: false) }
        _ = progress.buyOrSelect(.violet)
        let data = try JSONEncoder().encode(progress)
        var restored = try JSONDecoder().decode(RewardsProgress.self, from: data)
        XCTAssertEqual(restored.balance, 75)
        XCTAssertEqual(restored.selectedTheme, .violet)
        XCTAssertTrue(restored.completedChallenges.contains(.fivePerfects))
        XCTAssertEqual(restored.recordHit(.perfect, isFever: false), 35)
        XCTAssertEqual(restored.buyOrSelect(.violet), .selected)
    }

    func testMoneyUsesExactCentsAndFrenchSeparator() {
        XCTAssertEqual(RewardsProgress.money(0), "0,00 €")
        XCTAssertEqual(RewardsProgress.money(10), "0,10 €")
        XCTAssertEqual(RewardsProgress.money(135), "1,35 €")
    }
}
