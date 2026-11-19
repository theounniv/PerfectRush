// Projet de cours — Théo BOREL et Lana SCHMITT.
// Écran compact du jeu pour l'Apple Watch.
import SwiftUI
import Combine

struct WatchGameView: View {
    // SwiftUI conserve ce modèle pendant la vie de cet écran.
    @StateObject private var model = GameModel()
    @State private var showRewards = false
    // Permet de mettre en pause quand on quitte l’application.
    @Environment(\.scenePhase) private var scenePhase
    // Le Timer demande régulièrement de mettre à jour le curseur.
    private let clock = Timer.publish(every: 1.0 / 30, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack(spacing: 7) {
                HStack {
                    Text("\(model.engine.score)").font(.system(size: 32, weight: .black, design: .rounded))
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("ÉTAGE \(model.engine.floor)")
                        Text("RECORD \(model.best)").foregroundStyle(.secondary)
                    }.font(.system(size: 9, weight: .bold))
                }
                HStack {
                    Image(systemName: model.engine.shield ? "shield.fill" : "shield.slash")
                    Text(model.engine.isFever ? "FEVER !" : "×\(model.engine.multiplier)")
                    Spacer()
                    if model.engine.phase == .playing {
                        Button { model.pause() } label: { Image(systemName: "pause.fill") }
                            .buttonStyle(.plain).accessibilityLabel("Pause")
                    }
                }.font(.caption2).foregroundStyle(model.engine.isFever ? .orange : .mint)
                RushTrack(engine: model.engine, compact: true, theme: model.rewards.selectedTheme)
                Text(model.message).font(.system(size: 11, weight: .semibold)).lineLimit(1).minimumScaleFactor(0.7)
                action
                Button {
                    model.pause()
                    showRewards = true
                } label: {
                    VStack(spacing: 2) {
                        Text(RewardsProgress.money(model.rewards.balance) + " fictifs")
                            .font(.caption.bold()).contentTransition(.numericText())
                        Text("Défis & couleurs · sans retrait").font(.system(size: 9))
                    }
                }
                .buttonStyle(.bordered)
                .tint(model.rewards.selectedTheme.color)
                if model.engine.phase != .playing {
                    if model.engine.phase == .gameOver {
                        Text("Gains : " + RewardsProgress.money(model.runRewardCents) + " fictifs")
                            .font(.caption2)
                    }
                    Text("Vise la zone. Au centre : Perfect.\n3 Perfect = Fever.")
                        .font(.system(size: 10)).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    Toggle("Vibrations", isOn: $model.haptics).font(.caption2)
                }
            }
        }
        .navigationTitle("Perfect Rush")
        .onReceive(clock) { _ in model.frame() }
        .onChange(of: scenePhase) { _, phase in if phase != .active { model.pause() } }
        .sheet(isPresented: $showRewards) { RewardsView(model: model) }
    }
    // Le même bouton sert à jouer, toucher, reprendre ou rejouer.
    private var label: String {
        switch model.engine.phase {
        case .ready: return "Jouer"
        case .playing: return "TAP"
        case .paused: return "Reprendre"
        case .gameOver: return "Rejouer"
        }
    }
    private var action: some View {
        Button(label) {
            switch model.engine.phase {
            case .ready, .gameOver: model.start()
            case .playing: model.tap()
            case .paused: model.resume()
            }
        }
        .font(.headline)
        .tint(model.engine.isFever ? .orange : model.rewards.selectedTheme.color)
        .buttonStyle(.borderedProminent)
        .accessibilityHint("Valide la position du curseur")
    }
}
