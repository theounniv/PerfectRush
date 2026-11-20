// Projet de cours — Théo BOREL et Lana SCHMITT.
// Tests du choix entre la progression de l'iPhone et celle du compte.
import XCTest
#if canImport(RushCore)
@testable import RushCore
#else
@testable import PerfectRush
#endif

final class SavedProgressTests: XCTestCase {
    private func wallet(hits: Int) -> RewardsProgress {
        var rewards = RewardsProgress()
        for _ in 0..<hits { _ = rewards.recordHit(.good, isFever: false) }
        return rewards
    }

    func testNewerCloudProgressReplacesOldPhoneCopy() {
        let phone = SavedProgress(best: 10, rewards: wallet(hits: 1), updatedAt: Date(timeIntervalSince1970: 100))
        let cloud = SavedProgress(best: 5, rewards: wallet(hits: 4), updatedAt: Date(timeIntervalSince1970: 200))
        let kept = SavedProgress.merge(local: phone, remote: cloud)
        XCTAssertEqual(kept.rewards, cloud.rewards)
        XCTAssertEqual(kept.updatedAt, cloud.updatedAt)
        // Le record n'est jamais perdu.
        XCTAssertEqual(kept.best, 10)
    }

    func testNewerPhoneProgressIsKept() {
        let phone = SavedProgress(best: 3, rewards: wallet(hits: 6), updatedAt: Date(timeIntervalSince1970: 300))
        let cloud = SavedProgress(best: 8, rewards: wallet(hits: 2), updatedAt: Date(timeIntervalSince1970: 200))
        let kept = SavedProgress.merge(local: phone, remote: cloud)
        XCTAssertEqual(kept.rewards, phone.rewards)
        XCTAssertEqual(kept.best, 8)
    }

    func testFreshAccountOnNewPhoneTakesCloudProgress() {
        // Un compte jamais ouvert sur cet iPhone a une copie vide datée de .distantPast.
        let cloud = SavedProgress(best: 12, rewards: wallet(hits: 3), updatedAt: Date())
        XCTAssertEqual(SavedProgress.merge(local: SavedProgress(), remote: cloud), cloud)
    }

    func testProgressSurvivesEncoding() throws {
        let progress = SavedProgress(best: 7, rewards: wallet(hits: 5), updatedAt: Date(timeIntervalSince1970: 1_000))
        let data = try JSONEncoder().encode(progress)
        XCTAssertEqual(try JSONDecoder().decode(SavedProgress.self, from: data), progress)
    }
}
