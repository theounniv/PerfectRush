import SwiftUI
import Combine

struct WatchGameView: View {
    @StateObject private var model = GameModel()
    @Environment(\.scenePhase) private var scenePhase
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
                RushTrack(engine: model.engine, compact: true)
                Text(model.message).font(.system(size: 11, weight: .semibold)).lineLimit(1).minimumScaleFactor(0.7)
                action
                if model.engine.phase != .playing {
                    Text("Vise la zone. Au centre : Perfect.\n3 Perfect = Fever.")
                        .font(.system(size: 10)).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    Toggle("Vibrations", isOn: $model.haptics).font(.caption2)
                }
            }
        }
        .navigationTitle("Perfect Rush")
        .onReceive(clock) { _ in model.frame() }
        .onChange(of: scenePhase) { _, phase in if phase != .active { model.pause() } }
    }
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
        .tint(model.engine.isFever ? .orange : .mint)
        .buttonStyle(.borderedProminent)
        .accessibilityHint("Valide la position du curseur")
    }
}
