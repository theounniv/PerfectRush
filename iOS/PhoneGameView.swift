// Projet de cours — Théo BOREL et Lana SCHMITT.
// Écran iPhone : on lit le modèle et les boutons appellent ses méthodes.
import SwiftUI
import Combine

struct PhoneGameView: View {
    // Compte connecté, fourni par ContentView.
    @ObservedObject var auth: AuthManager
    // SwiftUI conserve ce modèle pendant la vie de cet écran.
    @StateObject private var model: GameModel

    // Le modèle est créé pour le compte connecté (uid Firebase) : chacun a sa progression.
    init(auth: AuthManager, uid: String) {
        _auth = ObservedObject(wrappedValue: auth)
        _model = StateObject(wrappedValue: GameModel(accountID: uid))
    }
    @State private var showRewards = false
    // Permet de mettre en pause quand on quitte l’application.
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    // Le Timer demande régulièrement de mettre à jour le curseur.
    private let clock = Timer.publish(every: 1.0 / 60, on: .main, in: .common).autoconnect()
    private var accent: Color {
        if model.engine.isFever { return .orange }
        return model.rewards.selectedTheme.color
    }

    var body: some View {
        // GeometryReader donne la taille disponible pour adapter le dessin.
        GeometryReader { geometry in
            ZStack {
                LinearGradient(colors: [Color(red: 0.025, green: 0.04, blue: 0.09), .black],
                               startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        header
                        wallet
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
                            RushTrack(engine: model.engine, theme: model.rewards.selectedTheme)
                            if model.lastRewardCents > 0 {
                                Text("+" + RewardsProgress.money(model.lastRewardCents) + " fictifs")
                                    .font(.headline).foregroundStyle(accent)
                                    .contentTransition(.numericText())
                            }
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
                        account
                    }
                    .padding(24)
                    .frame(maxWidth: 560)
                    .frame(maxWidth: .infinity, minHeight: geometry.size.height)
                }
            }
        }
        .onReceive(clock) { _ in model.frame() }
        .onChange(of: scenePhase) { _, phase in if phase != .active { model.pause() } }
        .sheet(isPresented: $showRewards) { RewardsView(model: model) }
    }

    // Le solde reste clairement fictif, y compris pendant les animations.
    private var wallet: some View {
        Button {
            model.pause()
            showRewards = true
        } label: {
            HStack {
                Image(systemName: "sparkles")
                VStack(alignment: .leading, spacing: 3) {
                    Text(RewardsProgress.money(model.rewards.balance))
                        .font(.title2.bold()).contentTransition(.numericText())
                    Text("Solde fictif · aucun retrait possible").font(.caption2)
                }
                Spacer()
                Label("Défis & couleurs", systemImage: "paintpalette.fill").font(.caption.bold())
            }
            .padding(16)
            .foregroundStyle(accent)
            .background(accent.opacity(0.1), in: RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.25), value: model.rewards.balance)
    }

    // Compte connecté et déconnexion : la partie est mise en pause avant de quitter.
    private var account: some View {
        HStack(spacing: 12) {
            Label(auth.accountLabel, systemImage: "person.crop.circle.fill")
                .lineLimit(1).truncationMode(.middle)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Se déconnecter") {
                model.pause()
                auth.signOut()
            }
            .tint(accent)
        }
        .font(.caption)
        .padding(14)
        .background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 16))
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
    // Décor uniquement : les vraies règles restent dans GameEngine.
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
    // Chaque état de partie propose le bon bouton.
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
            Text("Gains conservés : " + RewardsProgress.money(model.runRewardCents) + " fictifs")
                .font(.subheadline).foregroundStyle(accent)
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
