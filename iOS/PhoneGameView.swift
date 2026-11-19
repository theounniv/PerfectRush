import SwiftUI
import Combine

struct PhoneGameView: View {
    @StateObject private var model = GameModel()
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let clock = Timer.publish(every: 1.0 / 60, on: .main, in: .common).autoconnect()
    private var accent: Color { model.engine.isFever ? .orange : .mint }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(colors: [Color(red: 0.025, green: 0.04, blue: 0.09), .black],
                               startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        header
                        HStack {
                            Label("RECORD \(model.best)", systemImage: "trophy.fill")
                            Spacer()
                            Label(model.engine.shield ? "PRÊT" : "BRISÉ",
                                  systemImage: model.engine.shield ? "shield.fill" : "shield.slash")
                        }
                        .font(.caption.bold()).foregroundStyle(.white.opacity(0.65))
                        VStack(spacing: 2) {
                            Text("ÉTAGE \(model.engine.floor)").font(.caption.monospaced().bold()).foregroundStyle(accent)
                            Text("\(model.engine.score)")
                                .font(.system(size: 82, weight: .black, design: .rounded))
                                .contentTransition(.numericText())
                            Text("POINTS").font(.caption.bold()).tracking(5).foregroundStyle(.secondary)
                        }
                        tower
                        VStack(spacing: 20) {
                            HStack {
                                Text(model.message).font(.headline)
                                Spacer()
                                Text("×\(model.engine.multiplier)").font(.title2.monospaced().bold()).foregroundStyle(accent)
                            }
                            RushTrack(engine: model.engine)
                            if model.engine.isFever {
                                ProgressView(value: model.engine.feverRemaining, total: 5).tint(.orange)
                            }
                            Text("Touche quand le curseur blanc traverse la cible.\nLe centre donne un Perfect.")
                                .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
                        }
                        .padding(22).background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 26))
                        controls
                        Toggle("Vibrations", isOn: $model.haptics).font(.caption).tint(accent)
                        Text("3 Perfect = Fever · 1 bouclier par partie")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                    .padding(24)
                    .frame(maxWidth: 560)
                    .frame(maxWidth: .infinity, minHeight: geometry.size.height)
                }
            }
        }
        .onReceive(clock) { _ in model.frame() }
        .onChange(of: scenePhase) { _, phase in if phase != .active { model.pause() } }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("PERFECT").font(.caption.bold()).tracking(6).foregroundStyle(.secondary)
                Text("RUSH").font(.system(size: 36, weight: .black, design: .rounded)).italic()
            }
            Spacer()
            if model.engine.phase == .playing {
                Button { model.pause() } label: {
                    Image(systemName: "pause.fill").padding(14).background(.white.opacity(0.08), in: Circle())
                }.accessibilityLabel("Mettre en pause").tint(.white)
            }
        }
    }
    private var tower: some View {
        VStack(spacing: 5) {
            ForEach((0..<6).reversed(), id: \.self) { index in
                RoundedRectangle(cornerRadius: 5)
                    .fill(index < model.engine.floor % 6 ? accent : .white.opacity(0.07))
                    .frame(width: CGFloat(95 + index * 20), height: 10)
            }
        }
        .animation(reduceMotion ? nil : .spring(response: 0.25), value: model.engine.floor)
        .accessibilityHidden(true)
    }
    @ViewBuilder private var controls: some View {
        switch model.engine.phase {
        case .ready:
            primary("JOUER", icon: "play.fill") { model.start() }
        case .playing:
            primary("TAP", icon: "hand.tap.fill") { model.tap() }
        case .paused:
            Text("EN PAUSE").font(.headline)
            primary("REPRENDRE", icon: "play.fill") { model.resume() }
        case .gameOver:
            Text("Partie terminée · \(model.engine.floor) étages").font(.headline)
            primary("REJOUER", icon: "arrow.clockwise") { model.start() }
        }
    }
    private func primary(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon).font(.title3.bold()).tracking(2)
                .frame(maxWidth: .infinity).padding(.vertical, 22)
                .foregroundStyle(.black).background(accent, in: RoundedRectangle(cornerRadius: 22))
        }.buttonStyle(.plain)
    }
}
