import Foundation

public enum GamePhase: Equatable { case ready, playing, paused, gameOver }
public enum HitResult: Equatable { case ignored, good, perfect, shieldBroken, gameOver }

public struct GameEngine {
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
    public var position: Double {
        let value = travel.truncatingRemainder(dividingBy: 2)
        return value <= 1 ? value : 2 - value
    }
    public var targetCenter: Double {
        floor == 0 ? 0.5 : 0.25 + Double((floor * 37) % 51) / 100
    }
    public var targetWidth: Double { max(0.16, 0.34 - Double(floor) * 0.008) }
    public var speed: Double { min(1.65, 0.52 + Double(floor) * 0.035) }
    public var isFever: Bool { feverRemaining > 0 }
    public var multiplier: Int { 1 + min(combo / 3, 4) }

    public mutating func start() {
        self = GameEngine()
        phase = .playing
    }
    public mutating func pause() {
        if phase == .playing { phase = .paused }
    }
    public mutating func resume() {
        if phase == .paused { phase = .playing }
    }
    public mutating func advance(by delta: Double) {
        guard phase == .playing, delta.isFinite, delta > 0 else { return }
        elapsed += delta
        travel += delta * speed
        feverRemaining = max(0, feverRemaining - delta)
    }
    public mutating func tap() -> HitResult {
        guard phase == .playing, elapsed - lastTap >= 0.12 else { return .ignored }
        lastTap = elapsed
        let distance = abs(position - targetCenter)
        guard distance <= targetWidth / 2 + 1e-10 else {
            combo = 0
            feverRemaining = 0
            if shield {
                shield = false
                return .shieldBroken
            }
            phase = .gameOver
            return .gameOver
        }
        let perfect = distance <= targetWidth * 0.15 + 1e-10
        combo = perfect ? combo + 1 : 0
        if perfect && combo % 3 == 0 { feverRemaining = 5 }
        score += (perfect ? 3 : 1) * multiplier * (isFever ? 2 : 1)
        floor += 1
        travel = 0
        return perfect ? .perfect : .good
    }
}
