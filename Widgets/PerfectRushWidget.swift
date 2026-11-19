// Projet de cours — Théo BOREL et Lana SCHMITT.
// Un widget est un raccourci : le jeu s'exécute dans l'application.
import SwiftUI
import WidgetKit

// WidgetKit demande une entrée datée, même pour un contenu fixe.
struct RushEntry: TimelineEntry {
    let date: Date
}

// Le fournisseur donne les données à afficher dans la galerie et sur l'accueil.
struct RushProvider: TimelineProvider {
    func placeholder(in context: Context) -> RushEntry {
        return RushEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (RushEntry) -> Void) {
        completion(RushEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RushEntry>) -> Void) {
        let entry = RushEntry(date: Date())
        // Pas de données en direct : aucun rafraîchissement périodique nécessaire.
        completion(Timeline(entries: [entry], policy: .never))
    }
}

struct RushWidgetView: View {
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            if family == .accessoryCircular {
                VStack(spacing: 2) {
                    Image(systemName: "bolt.fill")
                    Text("RUSH").font(.system(size: 10, weight: .black))
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Label("PERFECT RUSH", systemImage: "bolt.fill")
                        .font(.headline)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                    Text("Vise le centre.")
                        .font(.caption)
                    Label("Jouer", systemImage: "play.fill")
                        .font(.caption.bold())
                        .foregroundStyle(.mint)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        // Un toucher ouvre l'app associée, sans effacer une partie en cours.
        .widgetURL(URL(string: "perfectrush://open"))
        .containerBackground(for: .widget) {
            Color(red: 0.025, green: 0.04, blue: 0.09)
        }
        .accessibilityLabel("Perfect Rush. Toucher pour ouvrir le jeu.")
    }
}

@main
struct PerfectRushWidget: Widget {
    let kind = "PerfectRushLauncher"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RushProvider()) { _ in
            RushWidgetView()
        }
        .configurationDisplayName("Perfect Rush")
        .description("Ouvre ton jeu de précision.")
        #if os(watchOS)
        // Rectangle : Smart Stack et certains cadrans. Cercle : complication.
        .supportedFamilies([.accessoryRectangular, .accessoryCircular])
        #else
        .supportedFamilies([.systemSmall, .systemMedium])
        #endif
    }
}
