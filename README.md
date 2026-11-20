# Perfect Rush

Projet de cours — **Théo BOREL et Lana SCHMITT**.

Mini-jeu de précision en SwiftUI pour **iPhone et Apple Watch**. Deux apps autonomes et un moteur de règles commun. L’app iPhone demande une connexion Firebase (email, Google ou Apple) ; l’app Watch et les widgets restent sans compte.

## Sur ton Mac : installation de zéro

1. Ouvre Xcode et termine l’installation de ses composants. Ce projet cible iOS 17 et watchOS 10 ; **Xcode 16.3 minimum** (exigé par le SDK Firebase), une version récente compatible avec ton macOS est préférable.
2. Dans les réglages Xcode, installe un simulateur iOS et un simulateur watchOS si nécessaire.
3. Ouvre Terminal et exécute, ligne par ligne :

~~~bash
mkdir -p ~/Developer
cd ~/Developer
git clone https://github.com/theounniv/PerfectRush.git
cd PerfectRush
open PerfectRush.xcodeproj
~~~

Si GitHub demande de t’authentifier pour le dépôt privé, connecte-toi avec ton compte. Tu peux aussi utiliser Code > Download ZIP sur GitHub puis ouvrir PerfectRush.xcodeproj. Ne crée pas une nouvelle app vide et n’utilise pas le dossier de l’ancien TP.

## Jouer sur iPhone

1. En haut de Xcode, sélectionne le schéma **PerfectRush**.
2. Sélectionne un **simulateur iPhone** disponible, pas « Any iOS Device ».
3. Fais **⌘ B**, puis **⌘ R**.
4. Appuie sur Jouer, puis TAP quand le curseur blanc traverse la zone colorée.

## Jouer sur Apple Watch

1. Sélectionne le schéma **PerfectRushWatch**.
2. Choisis un **simulateur Apple Watch** disponible. Si la liste est vide, installe le runtime watchOS dans Xcode et crée une destination dans Window > Devices and Simulators.
3. Fais **⌘ B**, puis **⌘ R**.
4. Le bouton TAP est sous la piste. Un défilement est possible sur les petites tailles d’écran.
5. Le jeu Watch fonctionne seul : pas de transfert de scores avec l’iPhone. Les records et réglages restent locaux à chaque app.
6. Les vibrations se vérifient sur une vraie montre ; le simulateur ne les reproduit pas physiquement.

Les deux cibles sont indépendantes. Pour installer sur un appareil réel, sélectionne ton équipe dans Signing & Capabilities et utilise un identifiant de bundle unique si demandé. Le simulateur ne nécessite pas de compte développeur payant.

## Règles

- Toucher la zone donne un point de base et un étage.
- Le centre (30 % de la largeur totale de la zone) donne un Perfect et trois points de base.
- Le multiplicateur augmente tous les trois Perfect consécutifs, jusqu’à ×5.
- Trois Perfect consécutifs activent ou prolongent Fever à cinq secondes : points doublés, y compris sur le toucher déclencheur.
- Un toucher réussi hors du centre remet le combo à zéro.
- La première erreur brise le bouclier. La seconde termine la partie.
- Un raté remet le combo et Fever à zéro.
- Les appuis espacés de moins de 120 ms sont ignorés.
- La vitesse augmente et la cible rétrécit à chaque étage, avec des limites.
- Le bouton Pause et le passage hors premier plan figent la partie. La reprise est manuelle.

Le décor de tour indique la progression par cycles de six étages ; le compteur donne le total. Le jeu inclut les retours haptiques, un portefeuille fictif, des défis permanents et une boutique de couleurs. Pas de musique, de sons, de notifications, de publicités ni de paiement.

## Tests

44 tests unitaires couvrent les règles partagées, l’économie fictive, les règles de connexion et la synchronisation de la progression, dont les régressions sur les limites de cible, le redémarrage, la pause, l’expiration de Fever, les doubles appuis et les pas de temps invalides.

### Dans Xcode

Sélectionne **PerfectRush**, puis **⌘ U**. Ouvre le navigateur de tests avec **⌘ 6**. Le schéma Watch lance l’app Watch ; les règles partagées sont testées via la cible iOS ou le package Swift.

### Dans Terminal sur Mac

~~~bash
cd ~/Developer/PerfectRush
swift test
~~~

Le package teste le moteur seul sans SwiftUI et sans simulateur.

### Vérifications manuelles iPhone ET Watch

- Démarrer, réussir un toucher, vérifier score et étage.
- Réussir trois Perfect et vérifier Fever, puis son expiration.
- Rater une fois : le bouclier disparaît, la partie continue.
- Rater une deuxième fois : écran de fin et bouton Rejouer.
- Rejouer : score et étage à zéro, bouclier restauré.
- Mettre en pause : le curseur s’arrête ; reprendre sans saut de temps.
- Quitter puis revenir : la partie reste en pause.
- Relancer l’application : le record persiste.
- Essayer la plus petite et une grande Apple Watch ; vérifier lisibilité et accès au bouton.
- Activer Réduire les animations sur iPhone et vérifier que l’animation décorative est retirée.

## Structure

- Sources/RushCore/GameEngine.swift : règles déterministes, indépendantes de l’interface.
- Sources/RushCore/AuthRules.swift : vérification des champs, messages d’erreur et nonce Apple, testables sans Firebase.
- Sources/RushCore/SavedProgress.swift : progression d’un compte et choix entre la copie de l’iPhone et celle du cloud.
- iOS/AuthManager.swift, AuthView.swift, ContentView.swift : authentification Firebase de l’app iPhone.
- iOS/ProgressSync.swift : envoi et lecture de la progression du compte dans Firestore.
- Shared/GameModel.swift : état observable, temps réel, sauvegarde du record et vibrations.
- Shared/RushTrack.swift : piste commune et curseur.
- iOS/ : app et écran iPhone.
- Watch/ : app autonome et écran compact Apple Watch.
- Tests/RushCoreTests/ : suite de tests.
- PerfectRush.xcodeproj : projet Xcode et schémas partagés.
- tools/generate-project.cjs : génération reproductible du projet ; Node n’est pas nécessaire pour l’ouvrir ou jouer.

## Sauvegarder des changements

~~~bash
git status
git diff
git add Package.swift firestore.rules Sources Shared iOS Watch Widgets Tests PerfectRush.xcodeproj tools
git commit -m "Améliore Perfect Rush"
git push
~~~

## État de validation

Les résultats de compilation et des tests sont consultables dans l’onglet Actions du dépôt. Le contrôle construit les deux applications et leurs widgets puis exécute les tests des règles partagées. Il ne remplace pas les essais manuels : ajout à l’accueil, toucher du widget, lisibilité, sensations de jeu et vibrations.

## Références

- SwiftUI : https://developer.apple.com/documentation/swiftui
- Cycle de vie et scenePhase : https://developer.apple.com/documentation/swiftui/scenephase
- Tests XCTest : https://developer.apple.com/documentation/xctest

Projet créé de zéro, distinct du TP CoursProductivite.

## Widgets d’accueil

Un même fichier Swift simple définit les deux widgets. Ce sont des raccourcis : ils ouvrent le jeu sans recommencer une partie. Le widget ne montre pas de faux score et ne fait pas tourner une partie en arrière-plan. Aucun App Group ni partage de données à configurer.

### iPhone : petit ou moyen widget

1. Compile et lance **PerfectRush** une fois sur le simulateur avec ⌘ R.
2. Reviens à l’accueil du simulateur (menu Device > Home, ou ⌘ ⇧ H).
3. Fais un appui long sur une zone vide et utilise le bouton d’ajout de widgets (selon la version iOS : + ou Modifier > Ajouter un widget).
4. Recherche **Perfect Rush**, choisis le petit ou le moyen format et ajoute-le.
5. Touche le widget : l’application doit s’ouvrir.

### Apple Watch : Smart Stack et complication

1. Compile et lance **PerfectRushWatch** une fois.
2. Reviens au cadran. Ouvre la Smart Stack avec la Digital Crown ou un balayage vers le haut.
3. Fais un appui long pour modifier la pile, puis ajoute le widget **Perfect Rush**.
4. Touche-le : le jeu doit s’ouvrir.
5. Pour une complication de cadran, choisis un cadran possédant un emplacement circulaire ou rectangulaire compatible, puis sélectionne Perfect Rush dans cet emplacement.

La Watch ne possède pas de widgets à placer parmi la grille d’icônes comme sur iPhone : on utilise la Smart Stack ou une complication. Si le widget n’apparaît pas, vérifie que tu as relancé l’app après la mise à jour et que le runtime du simulateur est compatible.

## Lire le code quand on débute

1. **GameEngine.swift** : variables, conditions if, points et règle du bouclier. Les calculs de mouvement sont commentés.
2. **GameEngineTests.swift** : une méthode par comportement à vérifier. XCTAssertEqual compare le résultat obtenu au résultat attendu.
3. **GameModel.swift** : transforme les résultats en messages, sauvegarde le record et déclenche les vibrations.
4. **PhoneGameView.swift / WatchGameView.swift** : affichage SwiftUI. VStack place les vues verticalement ; HStack horizontalement ; ZStack les superpose.
5. **RushTrack.swift** : convertit la position entre 0 et 1 en coordonnées sur l’écran.
6. **PerfectRushWidget.swift** : le fournisseur prépare une entrée datée, puis SwiftUI dessine le raccourci.

Les règles sont séparées du dessin pour pouvoir les tester. Les calculs de points utilisent des if explicites ; il n’y a pas de bibliothèque externe. public autorise le package de tests à lire une valeur ; private(set) lui interdit de la modifier directement. mutating indique qu’une méthode modifie une struct.

Le dossier tools concerne seulement la configuration Xcode : vous n’avez pas besoin de l’utiliser pour lancer ou modifier le jeu. Les mêmes règles servent à l’iPhone et à la Watch, sans recopier le moteur.

## Récompenses et portefeuille fictif

Tous les montants affichés sont fictifs : **aucun paiement, aucun gain réel et aucun retrait possible**. Les prix sont stockés en centimes entiers pour éviter les arrondis.

| Action | Crédit fictif |
|---|---|
| Réussir un étage | 0,10 € |
| Réussir un Perfect | +0,25 € en plus des 0,10 € de l’étage |
| Défi : 5 Perfect au total | +1,00 €, une seule fois |
| Défi : 20 étages au total | +2,00 €, une seule fois |
| Défi : déclencher Fever | +1,50 €, une seule fois |

Les gains sont sauvegardés après chaque réussite : pas besoin de finir ou de rejouer pour les conserver. Le bilan de partie inclut les bonus des défis débloqués. Rater ne retire rien du portefeuille. Le mode Fever double les points de score, pas la monnaie fictive de base.

Ouvre **Défis & couleurs** pour voir les objectifs et la boutique. Ouvrir cet écran met la partie en pause ; la reprise reste manuelle. Sur Watch, le bouton sous TAP ouvre le même écran avec défilement.

| Couleur | Prix fictif |
|---|---|
| Menthe | Déjà disponible |
| Néon violet | 2,00 € |
| Or solaire | 5,00 € |
| Glacier | 9,00 € |

Un achat débite une seule fois le prix, débloque et équipe la couleur. Rechoisir une couleur possédée est gratuit. Une couleur ne change ni le score ni les règles : pendant Fever, la piste devient orange, puis retrouve la couleur choisie.

La progression est locale à chaque appareil et peut disparaître si l’app est désinstallée. Le widget reste un raccourci sans affichage de solde : pas de partage de portefeuille à configurer.

### Code à lire

- Sources/RushCore/RewardsProgress.swift : montants, défis, couleurs et achat ; conditions if et tableaux simples.
- Shared/GameModel.swift : crédit après un toucher accepté et sauvegarde dans UserDefaults.
- Shared/RewardsView.swift : écran de boutique commun aux deux plateformes.
- Tests/RushCoreTests/RewardsProgressTests.swift : 12 tests sur les crédits, les bonus uniques, les achats, la sauvegarde et le formatage.

### Essais manuels supplémentaires

1. Réussir un toucher : le solde augmente de 0,10 € fictif (0,35 € pour un Perfect).
2. Débloquer un défi : son bonus apparaît dans le montant reçu et n’est plus versé aux parties suivantes.
3. Ouvrir la boutique : la partie se met en pause.
4. Vérifier qu’un achat trop cher est désactivé ; gagner assez puis acheter une couleur.
5. Rechoisir cette couleur : aucun deuxième débit.
6. Revenir au jeu et reprendre : la piste et les boutons utilisent la couleur équipée.
7. Relancer l’app : solde, défis et couleurs sont conservés.
8. Vérifier ces étapes sur iPhone et Watch, dont une petite taille d’écran.
9. Vérifier le libellé du solde fictif et l’option Réduire les animations sur iPhone.

Pour mettre à jour la copie sur le Mac : enregistrer ses changements éventuels, puis exécuter git pull dans le dossier PerfectRush et rouvrir le projet.

## Authentification Firebase (iPhone)

L’app iPhone affiche d’abord un écran de connexion. Trois méthodes : **email et mot de passe**, **Google** et **Apple**. Une fois connecté, le jeu s’ouvre ; le compte et le bouton **Se déconnecter** sont en bas de l’écran. La connexion est mémorisée par Firebase : relancer l’app ne la redemande pas.

L’app Watch et les widgets ne changent pas : ils restent jouables sans compte, avec une progression locale.

### Progression liée au compte

Sur iPhone, le **record, le portefeuille fictif, les défis et les couleurs** appartiennent au compte connecté :

- Chaque compte a sa propre copie sur l’iPhone : deux comptes sur le même téléphone ont chacun leur progression.
- La progression est aussi enregistrée dans **Firestore**, document `players/{uid}` : se connecter sur un autre iPhone la retrouve.
- L’envoi a lieu 2 secondes après le dernier gain, après un achat, à la pause, au passage en arrière-plan et avant la déconnexion. Sans réseau, on continue de jouer : Firestore garde les envois en attente.
- À l’ouverture du jeu, l’app compare la copie de l’iPhone et celle du cloud : la plus récente gagne pour le portefeuille, les défis et les couleurs ; le record garde la meilleure valeur des deux.
- La progression jouée avant l’ajout des comptes est donnée au **premier compte** qui se connecte sur l’iPhone.
- Le réglage Vibrations reste propre à l’appareil.

Sous le compte, en bas du jeu, une ligne indique l’état : « Progression liée au compte », « Sauvegarde… » ou « Hors ligne ».

### Ce qui est déjà fait dans le projet

- Paquets Swift : `FirebaseCore`, `FirebaseAuth` et `FirebaseFirestore` (firebase-ios-sdk 12.x), `GoogleSignIn` et `GoogleSignInSwift` (GoogleSignIn-iOS 9.x). Xcode les télécharge à la première ouverture : patiente jusqu’à la fin de « Resolving Package Graph ».
- `Other Linker Flags = -ObjC` et la capacité **Sign in with Apple** (`iOS/PerfectRush.entitlements`).
- Une phase de build **Firebase : configuration** copie `iOS/GoogleService-Info.plist` dans l’app et ajoute automatiquement l’URL Scheme `REVERSED_CLIENT_ID` pour Google. Rien à saisir dans l’onglet Info.
- `FirebaseApp.configure()` dans `PerfectRushApp.init()` et `onOpenURL` pour le retour de Google.

Le projet Xcode est généré par `tools/generate-project.cjs` : une modification faite à la main dans les réglages de cible serait perdue à la prochaine génération. Les réglages Firebase sont donc écrits dans ce script.

### À faire une fois dans la console Firebase

1. Sur https://console.firebase.google.com, crée un projet (Google Analytics inutile), puis ajoute une app **iOS** avec le Bundle Identifier **`fr.theounniv.perfectrush`** (exactement celui de Xcode ; si tu le changes pour installer sur ton iPhone, utilise le nouveau partout).
2. **Authentication > Sign-in method** : active **Email/Password**, **Google** et **Apple**.
3. **Firestore Database > Créer une base de données** (mode production, région proche, par exemple `eur3`). Dans l’onglet **Règles**, colle le contenu du fichier [`firestore.rules`](firestore.rules) puis **Publier** : chaque joueur ne peut lire et écrire que sa propre progression.
4. Télécharge **après** l’activation de Google le fichier `GoogleService-Info.plist` et place-le exactement ici : **`iOS/GoogleService-Info.plist`** (nom exact, pas de « (2) »). Inutile de le glisser dans Xcode ni de cocher une cible : la phase de build s’en charge. Ce fichier contient des identifiants publics ; on peut le committer pour que les deux membres du groupe l’aient.
5. Pour Apple (compte Apple Developer Program payant requis) : sur developer.apple.com, active Sign in with Apple pour l’identifiant `fr.theounniv.perfectrush`, crée un Service ID et une clé, puis dans Firebase > Apple renseigne Service ID, Team ID, Key ID, clé privée. URL de retour : `https://VOTRE_PROJECT_ID.firebaseapp.com/__/auth/handler`. Dans Xcode, choisis ton équipe dans Signing & Capabilities.

Sans `GoogleService-Info.plist`, l’app se lance quand même et l’écran de connexion indique le fichier manquant (un avertissement apparaît aussi dans le build).

Sans compte développeur payant : Email et Google fonctionnent sur simulateur. Pour installer sur un iPhone avec un compte gratuit, retire temporairement la capacité Sign in with Apple, refusée par les équipes personnelles.

### Essais manuels

1. **Email** : créer un compte (mot de passe ≥ 6 caractères), se déconnecter, se reconnecter. Tester un mauvais mot de passe et un email déjà utilisé : message en français.
2. **Google** : bouton Google, choisir un compte, vérifier l’email affiché en bas du jeu.
3. **Apple** : bouton Apple, autoriser. Sur simulateur, il faut être connecté à un identifiant Apple dans Réglages ; sinon tester sur un iPhone réel.
4. **Déconnexion** : la partie se met en pause et l’écran de connexion revient immédiatement.
5. Relancer l’app connectée : le jeu s’ouvre directement.
6. Fermer la fenêtre Google ou Apple sans choisir : aucun message d’erreur.
7. **Progression** : gagner quelques centimes fictifs avec le compte A, se déconnecter, se connecter avec le compte B : solde à zéro. Revenir sur A : le solde est retrouvé.
8. Avec A, acheter une couleur puis vérifier dans la console Firebase (Firestore > `players`) que le document de A est à jour.
9. Supprimer l’app, la réinstaller, se reconnecter avec A : record, solde et couleurs reviennent.
10. Mode Avion : jouer, revenir en ligne, mettre en pause : la ligne d’état repasse à « Progression liée au compte ».

En cas d’échec, lis le message complet dans la console Xcode (ligne « Erreur d’authentification »). Causes fréquentes : fournisseur non activé dans Firebase, Bundle Identifier différent, ancien `GoogleService-Info.plist` sans `CLIENT_ID`.
