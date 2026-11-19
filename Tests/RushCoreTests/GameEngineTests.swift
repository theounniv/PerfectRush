// Projet de cours — Théo BOREL et Lana SCHMITT.
// Tests du moteur : préparer une partie, agir, vérifier le résultat.
import XCTest
#if canImport(RushCore)
@testable import RushCore
#else
@testable import PerfectRush
#endif

final class GameEngineTests: XCTestCase {
    // Aide des tests : avancer exactement au centre de la cible.
    // inout permet à cette fonction de modifier la partie passée en argument.
    private func perfect(_ game: inout GameEngine) {
        game.advance(by: game.targetCenter / game.speed)
        XCTAssertEqual(game.tap(), .perfect)
    }

    func testInitialStateIsReady() {
        let game = GameEngine()
        XCTAssertEqual(game.phase, .ready)
        XCTAssertEqual(game.score, 0)
        XCTAssertTrue(game.shield)
    }
    func testStartBeginsPlaying() {
        var game = GameEngine()
        game.start()
        XCTAssertEqual(game.phase, .playing)
    }
    func testReadyIgnoresTimeAndTap() {
        var game = GameEngine()
        game.advance(by: 1)
        XCTAssertEqual(game.position, 0)
        XCTAssertEqual(game.tap(), .ignored)
    }
    func testCursorMovesUsingElapsedTime() {
        var game = GameEngine()
        game.start()
        game.advance(by: 0.5)
        XCTAssertEqual(game.position, 0.26, accuracy: 0.000001)
    }
    func testCursorReflectsAtEndOfTrack() {
        var game = GameEngine()
        game.start()
        game.advance(by: 1.5 / game.speed)
        XCTAssertEqual(game.position, 0.5, accuracy: 0.000001)
    }
    func testPerfectAddsThreePointsAndOneFloor() {
        var game = GameEngine()
        game.start()
        perfect(&game)
        XCTAssertEqual(game.score, 3)
        XCTAssertEqual(game.floor, 1)
        XCTAssertEqual(game.combo, 1)
    }
    func testTargetBoundaryCountsAsGoodHit() {
        var game = GameEngine()
        game.start()
        game.advance(by: (game.targetCenter - game.targetWidth / 2) / game.speed)
        XCTAssertEqual(game.tap(), .good)
        XCTAssertEqual(game.score, 1)
    }
    func testFirstMissConsumesShield() {
        var game = GameEngine()
        game.start()
        XCTAssertEqual(game.tap(), .shieldBroken)
        XCTAssertFalse(game.shield)
        XCTAssertEqual(game.phase, .playing)
    }
    func testSecondMissEndsGame() {
        var game = GameEngine()
        game.start()
        _ = game.tap()
        game.advance(by: 0.2)
        XCTAssertEqual(game.tap(), .gameOver)
        XCTAssertEqual(game.phase, .gameOver)
    }
    func testRapidSecondTapIsIgnored() {
        var game = GameEngine()
        game.start()
        _ = game.tap()
        XCTAssertEqual(game.tap(), .ignored)
        XCTAssertEqual(game.phase, .playing)
    }
    func testThreePerfectsTriggerFiveSecondFever() {
        var game = GameEngine()
        game.start()
        for _ in 0..<3 { perfect(&game) }
        XCTAssertTrue(game.isFever)
        XCTAssertEqual(game.feverRemaining, 5)
        XCTAssertEqual(game.score, 18)
    }
    func testFeverExpires() {
        var game = GameEngine()
        game.start()
        for _ in 0..<3 { perfect(&game) }
        game.advance(by: 5)
        XCTAssertFalse(game.isFever)
        XCTAssertEqual(game.feverRemaining, 0)
    }
    func testMissResetsComboAndFever() {
        var game = GameEngine()
        game.start()
        for _ in 0..<3 { perfect(&game) }
        game.advance(by: 0.2)
        XCTAssertEqual(game.tap(), .shieldBroken)
        XCTAssertEqual(game.combo, 0)
        XCTAssertFalse(game.isFever)
    }
    func testPauseFreezesTimeAndIgnoresTap() {
        var game = GameEngine()
        game.start()
        game.advance(by: 0.2)
        let position = game.position
        game.pause()
        game.advance(by: 30)
        XCTAssertEqual(game.position, position)
        XCTAssertEqual(game.tap(), .ignored)
    }
    func testResumeContinuesPlaying() {
        var game = GameEngine()
        game.start()
        game.pause()
        game.resume()
        game.advance(by: 0.5)
        XCTAssertEqual(game.phase, .playing)
        XCTAssertEqual(game.position, 0.26, accuracy: 0.000001)
    }
    func testRestartResetsAllRunState() {
        var game = GameEngine()
        game.start()
        perfect(&game)
        game.advance(by: 0.2)
        _ = game.tap()
        game.start()
        XCTAssertEqual(game.score, 0)
        XCTAssertEqual(game.floor, 0)
        XCTAssertEqual(game.combo, 0)
        XCTAssertTrue(game.shield)
        XCTAssertEqual(game.elapsed, 0)
        XCTAssertEqual(game.position, 0)
    }
    func testDifficultyHasSafeBoundsAfterManyFloors() {
        var game = GameEngine()
        game.start()
        for _ in 0..<100 { perfect(&game) }
        XCTAssertEqual(game.targetWidth, 0.16)
        XCTAssertEqual(game.speed, 1.65)
        XCTAssertGreaterThanOrEqual(game.targetCenter - game.targetWidth / 2, 0)
        XCTAssertLessThanOrEqual(game.targetCenter + game.targetWidth / 2, 1)
    }
    func testInvalidDeltasDoNotChangeState() {
        var game = GameEngine()
        game.start()
        for delta in [-1, Double.nan, Double.infinity, 0] { game.advance(by: delta) }
        XCTAssertEqual(game.elapsed, 0)
        XCTAssertEqual(game.position, 0)
    }
    func testFramePartitionDoesNotChangePositionAtConstantSpeed() {
        var first = GameEngine()
        first.start()
        var second = first
        first.advance(by: 1)
        for _ in 0..<100 { second.advance(by: 0.01) }
        XCTAssertEqual(first.position, second.position, accuracy: 0.000001)
    }
    func testGameOverIgnoresFurtherInput() {
        var game = GameEngine()
        game.start()
        _ = game.tap()
        game.advance(by: 0.2)
        _ = game.tap()
        let position = game.position
        game.advance(by: 10)
        XCTAssertEqual(game.tap(), .ignored)
        XCTAssertEqual(game.position, position)
    }
}
