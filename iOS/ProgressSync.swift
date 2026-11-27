// Projet de cours — Théo BOREL et Lana SCHMITT.
// Relie la progression au compte : un document Firestore par joueur, players/{uid}.
import Foundation
import Combine
import FirebaseFirestore

/// Synchronise la progression du compte avec Firestore (document players/{uid}).
/// Le modèle ne connaît pas Firestore : il prévient seulement quand sa progression change.
@MainActor
final class ProgressSync: ObservableObject {
    // Petit texte affiché sous le compte pour savoir où en est la sauvegarde.
    @Published private(set) var status = "Synchronisation…"

    // nil quand le cloud est désactivé (tests d'interface) : la progression reste sur l'iPhone.
    private let document: DocumentReference?
    private weak var model: GameModel?
    // Vrai seulement après avoir lu le cloud : sinon on risquerait d'écraser
    // une progression plus récente faite sur un autre iPhone.
    private var isReady = false
    private var isDownloading = false
    private var pendingUpload: Task<Void, Never>?

    init(uid: String, cloudSync: Bool = true) {
        if cloudSync {
            document = Firestore.firestore().collection("players").document(uid)
        } else {
            document = nil
            status = "Mode test : progression gardée sur l’iPhone"
        }
    }

    // Appelé à l'ouverture du jeu : on compare l'iPhone et le cloud, puis on garde la bonne version.
    func attach(_ model: GameModel) async {
        guard document != nil else { return }
        self.model = model
        model.onProgressSaved = { [weak self] _ in self?.scheduleUpload() }
        await download()
    }

    /// Lit la copie du cloud, la compare à celle de l'iPhone et garde la bonne version.
    private func download() async {
        guard let document, let model, !isDownloading else { return }
        isDownloading = true
        defer { isDownloading = false }
        do {
            let snapshot = try await document.getDocument()
            let local = model.savedProgress
            if snapshot.exists {
                let remote = try snapshot.data(as: SavedProgress.self)
                let kept = SavedProgress.merge(local: local, remote: remote)
                if kept != local { model.replaceProgress(kept) }
                isReady = true
                if kept != remote { upload(kept) } else { status = "Progression liée au compte" }
            } else {
                // Premier lancement de ce compte : la progression de l'iPhone devient celle du compte.
                isReady = true
                upload(local)
            }
        } catch {
            status = "Hors ligne : progression gardée sur l’iPhone"
            print("Lecture de la progression impossible :", error)
        }
    }

    // Un toucher réussi change la progression : on attend 2 s de calme pour grouper les envois.
    private func scheduleUpload() {
        pendingUpload?.cancel()
        pendingUpload = Task { [weak self] in
            try? await Task.sleep(for: .seconds(2))
            if Task.isCancelled { return }
            await self?.flush()
        }
    }

    // Envoie tout de suite : pause, passage en arrière-plan ou déconnexion.
    func flush() async {
        guard document != nil else { return }
        pendingUpload?.cancel()
        pendingUpload = nil
        if !isReady {
            await download()
            return
        }
        if let model { upload(model.savedProgress) }
    }

    /// Écrit la progression dans Firestore et met à jour la ligne d'état.
    private func upload(_ progress: SavedProgress) {
        guard let document else { return }
        status = "Sauvegarde…"
        do {
            // Firestore garde l'envoi en file d'attente si le réseau manque.
            try document.setData(from: progress) { [weak self] error in
                Task { @MainActor in
                    if let error {
                        self?.status = "Sauvegarde du compte échouée"
                        print("Envoi de la progression impossible :", error)
                    } else {
                        self?.status = "Progression liée au compte"
                    }
                }
            }
        } catch {
            status = "Sauvegarde du compte échouée"
            print("Encodage de la progression impossible :", error)
        }
    }
}
