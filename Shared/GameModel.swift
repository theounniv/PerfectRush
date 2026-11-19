import Foundation
import Combine
#if os(iOS)
import UIKit
#elseif os(watchOS)
import WatchKit
#endif

@MainActor
final class GameModel: ObservableObject {
    @Published private(set) var engine = GameEngine()
    @Published private(set) var best: Int
    @Published private(set) var message = "Vise le centre"
    @Published private(set) var feedbackID = 0
    @Published var haptics: Bool {
        didSet { defaults.set(haptics, forKey: "haptics") }
    }
    private let defaults: UserDefaults
    private var lastFrame: TimeInterval?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        best = defaults.integer(forKey: "best")
        haptics = defaults.object(forKey: "haptics") as? Bool ?? true
    }
    func start() {
        engine.start()
        message = "Vise le centre"
        lastFrame = nil
    }
    func frame() {
        let now = ProcessInfo.processInfo.systemUptime
        defer { lastFrame = engine.phase == .playing ? now : nil }
        guard engine.phase == .playing, let previous = lastFrame else { return }
        engine.advance(by: now - previous)
    }
    func tap() {
        let result = engine.tap()
        guard result != .ignored else { return }
        switch result {
        case .perfect: message = engine.isFever ? "FEVER · PERFECT !" : "PERFECT !"
        case .good: message = "Bien joué !"
        case .shieldBroken: message = "Bouclier brisé !"
        case .gameOver: message = "Partie terminée"
        case .ignored: break
        }
        if engine.score > best {
            best = engine.score
            defaults.set(best, forKey: "best")
        }
        feedbackID += 1
        guard haptics else { return }
        #if os(iOS)
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(result == .shieldBroken || result == .gameOver ? .warning : .success)
        #elseif os(watchOS)
        WKInterfaceDevice.current().play(result == .shieldBroken || result == .gameOver ? .failure : .click)
        #endif
    }
    func pause() { engine.pause(); lastFrame = nil }
    func resume() { engine.resume(); lastFrame = nil }
}
