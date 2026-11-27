# Perfect Rush

Projet de cours — **Théo BOREL et Lana SCHMITT**.

Mini-jeu de précision en SwiftUI pour **iPhone et Apple Watch**, avec des widgets d’accueil. Le joueur touche l’écran quand le curseur traverse la cible ; la difficulté augmente à chaque étage. Sur iPhone, le joueur se connecte (email, Google ou Apple) et sa progression est enregistrée dans son compte Firebase.

## Sommaire

1. [Démarrage rapide](#démarrage-rapide)
2. [Règles du jeu](#règles-du-jeu)
3. [Portefeuille fictif, défis et couleurs](#portefeuille-fictif-défis-et-couleurs)
4. [Compte et progression](#compte-et-progression)
5. [Widgets](#widgets)
6. [Architecture](#architecture)
7. [Tests](#tests)
8. [Configurer Firebase](#configurer-firebase)
9. [Dépannage](#dépannage)
10. [Travailler sur le projet](#travailler-sur-le-projet)

## Démarrage rapide

### Prérequis

- Un Mac avec **Xcode 16.3 ou plus récent** (exigé par le SDK Firebase). Le projet cible iOS 17 et watchOS 10.
- Un simulateur iPhone et, pour la Watch, un simulateur Apple Watch (Xcode > Settings > Components).
- Une connexion Internet : à la première ouverture, Xcode télécharge Firebase et Google Sign-In.

### 1. Récupérer le projet

~~~bash
mkdir -p ~/Developer
cd ~/Developer
git clone https://github.com/theounniv/PerfectRush.git
cd PerfectRush
open PerfectRush.xcodeproj
~~~

Attends la fin de **« Resolving Package Graph »** en haut de la fenêtre Xcode (quelques minutes la première fois).

### 2. Vérifier la configuration Firebase

La connexion utilise le fichier **`iOS/GoogleService-Info.plist`**, fourni par l’équipe dans le dépôt. Vérifie qu’il est présent :

~~~bash
ls iOS/GoogleService-Info.plist
~~~

S’il manque, l’app se lance mais l’écran de connexion affiche « Firebase n’est pas configuré ». Demande le fichier à l’équipe ou crée ton propre projet Firebase (voir [Configurer Firebase](#configurer-firebase)). Les tests, eux, fonctionnent sans ce fichier.

### 3. Lancer l’app iPhone

1. En haut de Xcode, choisis le schéma **PerfectRush** et un **simulateur iPhone** (pas « Any iOS Device »).
2. Fais **⌘ R**.
3. Sur l’écran de connexion, saisis un email et un mot de passe d’au moins 6 caractères, puis touche **Créer un compte**. Tu peux aussi utiliser **Google**.
4. Le jeu s’ouvre : touche **JOUER**, puis **TAP** quand le curseur blanc traverse la zone colorée.

La connexion est mémorisée : au prochain lancement, le jeu s’ouvre directement. Le bouton **Se déconnecter** est en bas de l’écran de jeu.

### 4. Lancer l’app Apple Watch

1. Choisis le schéma **PerfectRushWatch** et un **simulateur Apple Watch**. Si la liste est vide, installe le runtime watchOS puis crée une destination dans Window > Devices and Simulators.
2. Fais **⌘ R**. L’app Watch se joue sans compte ; le bouton TAP est sous la piste.

### 5. Lancer les tests

Schéma **PerfectRush**, puis **⌘ U**. Détails dans [Tests](#tests).

### Sur un vrai appareil

Sélectionne ton équipe dans **Signing & Capabilities** pour chaque cible. **Sign in with Apple** demande un compte Apple Developer Program payant : avec un compte gratuit, retire cette capacité de la cible PerfectRush pour installer l’app (email et Google restent disponibles). Le simulateur ne demande pas de compte développeur.

## Règles du jeu

- Toucher la zone donne un point de base et un étage.
- Le centre (30 % de la largeur de la zone) donne un **Perfect** et trois points de base.
- Le multiplicateur augmente tous les trois Perfect consécutifs, jusqu’à ×5.
- Trois Perfect consécutifs activent ou prolongent **Fever** pendant cinq secondes : points doublés, y compris sur le toucher déclencheur.
- Un toucher réussi hors du centre remet le combo à zéro.
- La première erreur brise le **bouclier**, la seconde termine la partie. Un raté remet le combo et Fever à zéro.
- Les appuis espacés de moins de 120 ms sont ignorés.
- La vitesse augmente et la cible rétrécit à chaque étage, avec des limites.
- Le bouton Pause et le passage hors premier plan figent la partie. La reprise est manuelle.

Le décor de tour indique la progression par cycles de six étages ; le compteur donne le total. Le jeu inclut des retours haptiques (désactivables). Pas de musique, de sons, de notifications, de publicités ni de paiement.

## Portefeuille fictif, défis et couleurs

Tous les montants sont fictifs : **aucun paiement, aucun gain réel et aucun retrait possible**. Les prix sont stockés en centimes entiers pour éviter les arrondis.

| Action | Crédit fictif |
|---|---|
| Réussir un étage | 0,10 € |
| Réussir un Perfect | +0,25 € en plus des 0,10 € de l’étage |
| Défi : 5 Perfect au total | +1,00 €, une seule fois |
| Défi : 20 étages au total | +2,00 €, une seule fois |
| Défi : déclencher Fever | +1,50 €, une seule fois |

| Couleur | Prix fictif |
|---|---|
| Menthe | Déjà disponible |
| Néon violet | 2,00 € |
| Or solaire | 5,00 € |
| Glacier | 9,00 € |

- Les gains sont sauvegardés après chaque réussite ; rater ne retire rien. Fever double les points de score, pas la monnaie fictive.
- **Défis & couleurs** ouvre la boutique et met la partie en pause. Sur Watch, le bouton sous TAP ouvre le même écran.
- Un achat débite une seule fois le prix, débloque et équipe la couleur. Rechoisir une couleur possédée est gratuit. Une couleur ne change ni le score ni les règles ; pendant Fever, la piste devient orange.

## Compte et progression

Sur **iPhone**, le record, le portefeuille fictif, les défis et les couleurs appartiennent au compte connecté :

- Chaque compte a sa propre copie sur l’iPhone : deux comptes sur le même téléphone ont chacun leur progression.
- La progression est aussi enregistrée dans **Firestore** (document `players/{uid}`) : on la retrouve sur un autre iPhone ou après une réinstallation.
- L’envoi a lieu 2 secondes après le dernier gain, après un achat, à la pause, au passage en arrière-plan et avant la déconnexion. Sans réseau, on continue de jouer : Firestore garde les envois en attente.
- À l’ouverture du jeu, l’app compare la copie de l’iPhone et celle du cloud : la plus récente gagne pour le portefeuille, les défis et les couleurs ; le record garde la meilleure valeur des deux.
- La progression jouée avant l’ajout des comptes revient au **premier compte** connecté sur l’iPhone.
- Sous le compte, une ligne indique l’état : « Progression liée au compte », « Sauvegarde… » ou « Hors ligne ».

Sur **Apple Watch**, la progression reste locale à la montre, sans compte. Le réglage Vibrations est propre à chaque appareil.

## Widgets

Les widgets sont des raccourcis : ils ouvrent le jeu sans recommencer une partie et n’affichent ni score ni solde.

**iPhone (petit ou moyen format)**

1. Lance **PerfectRush** une fois avec ⌘ R, puis reviens à l’accueil du simulateur (⌘ ⇧ H).
2. Appui long sur une zone vide, bouton d’ajout de widgets, recherche **Perfect Rush**.
3. Ajoute le widget puis touche-le : l’app s’ouvre.

**Apple Watch (Smart Stack et complication)**

1. Lance **PerfectRushWatch** une fois, puis reviens au cadran.
2. Ouvre la Smart Stack (Digital Crown ou balayage vers le haut), appui long, ajoute **Perfect Rush**.
3. Pour une complication, choisis un cadran avec un emplacement circulaire ou rectangulaire compatible.

## Architecture

Le projet sépare les **règles** (testables sans interface), le **modèle** (état et sauvegarde) et les **vues** SwiftUI.

~~~
Sources/RushCore/       Règles pures, sans SwiftUI ni Firebase (package Swift testé par swift test)
  GameEngine.swift        Moteur du jeu : curseur, cible, points, bouclier, Fever, pause
  RewardsProgress.swift   Portefeuille fictif, défis et achats de couleurs
  SavedProgress.swift     Progression d’un compte et choix entre l’iPhone et le cloud
  AuthRules.swift         Vérification des champs, messages d’erreur, nonce Apple
Shared/                 Code commun iPhone et Watch
  GameModel.swift         État observable, temps réel, sauvegarde par compte, vibrations
  RushTrack.swift         Dessin de la piste et du curseur
  RewardsView.swift       Écran Défis & couleurs
iOS/                    App iPhone
  PerfectRushApp.swift    Point d’entrée, initialisation de Firebase
  ContentView.swift       Choix entre connexion et jeu, mode tests d’interface
  AuthManager.swift       Connexion email, Google, Apple et déconnexion (Firebase Auth)
  AuthView.swift          Écran de connexion
  ProgressSync.swift      Synchronisation de la progression avec Firestore
  PhoneGameView.swift     Écran de jeu
  RushBackground.swift    Fond commun des écrans
Watch/                  App Apple Watch autonome
Widgets/                Widgets iPhone et Watch (un seul fichier)
Tests/
  RushCoreTests/          Tests unitaires des règles
  PerfectRushTests/       Tests unitaires du modèle de l’app
  PerfectRushUITests/     Tests d’interface de l’app iPhone
firestore.rules         Règles de sécurité Firestore
tools/generate-project.cjs  Génération reproductible du projet Xcode
~~~

Principes :

- Les vues ne contiennent pas de règles : elles lisent le modèle et appellent ses méthodes.
- `GameEngine` et `RewardsProgress` sont des `struct` : `private(set)` empêche l’interface de modifier une valeur directement, `mutating` signale une méthode qui modifie la structure.
- Toute la logique Firebase est isolée dans `AuthManager` et `ProgressSync` ; ce qui peut être testé sans réseau est dans `RushCore`.
- iPhone et Watch partagent le même moteur et le même modèle, sans copie de code.

## Tests

| Suite | Où | Nombre | Ce qui est vérifié |
|---|---|---|---|
| `RushCoreTests` | Xcode et `swift test` | 44 | Règles du jeu (dont limites de cible, pause, Fever, doubles appuis, pas de temps invalides), portefeuille, connexion, fusion iPhone/cloud |
| `PerfectRushTests` | Xcode | 6 | Sauvegarde séparée par compte, reprise de l’ancienne progression, envois vers le compte |
| `PerfectRushUITests` | Xcode | 7 | Écran de départ, partie, pause et reprise, boutique, vibrations, mode test, erreur de connexion |

### Dans Xcode

Schéma **PerfectRush**, simulateur iPhone, puis **⌘ U**. Le navigateur de tests (**⌘ 6**) permet de lancer une suite ou un test seul.

Les tests d’interface lancent l’app avec l’argument `-ui-testing` : le jeu s’ouvre directement, sans connexion ni Firestore, avec une progression vide enregistrée à part. Le test de l’écran de connexion est ignoré automatiquement si `GoogleService-Info.plist` est absent ou si un compte est déjà connecté sur le simulateur.

### Dans le Terminal

~~~bash
cd ~/Developer/PerfectRush
swift test
~~~

`swift test` vérifie les règles seules, sans simulateur. Pour toutes les suites, remplace le nom du simulateur par un de ceux listés par `xcrun simctl list devices available` :

~~~bash
xcodebuild test -project PerfectRush.xcodeproj -scheme PerfectRush \
  -destination 'platform=iOS Simulator,name=iPhone 16'
~~~

### Intégration continue

À chaque push, GitHub Actions (onglet **Actions**) exécute `swift test` puis compile l’app iPhone, ses tests et l’app Watch.

### Vérifications manuelles

**Jeu (iPhone et Watch)**

1. Démarrer, réussir un toucher : score et étage augmentent, le solde gagne 0,10 € (0,35 € pour un Perfect).
2. Trois Perfect : Fever s’active puis expire.
3. Rater une fois : le bouclier se brise, la partie continue. Rater encore : écran de fin et bouton Rejouer.
4. Pause : le curseur s’arrête ; la reprise se fait sans saut. Quitter puis revenir : la partie reste en pause.
5. Boutique : un achat trop cher est désactivé ; acheter une couleur puis la rechoisir ne débite qu’une fois.
6. Relancer l’app : record, solde, défis et couleurs sont conservés.
7. Tester la plus petite et une grande Apple Watch, et l’option Réduire les animations sur iPhone.

**Connexion et compte (iPhone)**

1. Email : créer un compte, se déconnecter, se reconnecter. Un mauvais mot de passe ou un email déjà utilisé affiche un message en français.
2. Google : choisir un compte ; son email s’affiche en bas du jeu.
3. Apple : autoriser (identifiant Apple connecté dans les Réglages du simulateur, ou iPhone réel).
4. Fermer la fenêtre Google ou Apple sans choisir : aucun message d’erreur.
5. Gagner des centimes avec le compte A, se connecter avec B : solde à zéro. Revenir sur A : solde retrouvé.
6. Supprimer et réinstaller l’app, se reconnecter avec A : la progression revient depuis Firestore.

## Configurer Firebase

À faire une seule fois pour un nouveau projet Firebase. Le projet Xcode contient déjà les paquets (`FirebaseCore`, `FirebaseAuth`, `FirebaseFirestore`, `GoogleSignIn`, `GoogleSignInSwift`), le flag `-ObjC`, la capacité Sign in with Apple et l’initialisation de Firebase.

1. Sur https://console.firebase.google.com, crée un projet, puis ajoute une app **iOS** avec le Bundle Identifier **`fr.theounniv.perfectrush`**. Dans l’assistant, ignore les étapes « Add Firebase SDK » et « Add initialization code » : c’est déjà fait.
2. **Authentication > Sign-in method** : active **Email/Password**, **Google** et **Apple**.
3. **Firestore Database > Créer une base de données** (mode production). Dans l’onglet **Règles**, colle le contenu de [`firestore.rules`](firestore.rules) puis **Publier** : chaque joueur ne lit et n’écrit que sa propre progression.
4. **Après** l’activation de Google, télécharge `GoogleService-Info.plist` (Paramètres du projet > Général) et place-le exactement dans **`iOS/GoogleService-Info.plist`**. Inutile de le glisser dans Xcode : la phase de build **Firebase : configuration** le copie dans l’app et ajoute l’URL Scheme Google (`REVERSED_CLIENT_ID`).
5. Pour Apple (compte Apple Developer payant) : choisis ton équipe dans Signing & Capabilities. Pour une app iOS seule, activer Apple dans Firebase suffit en général.

`GoogleService-Info.plist` ne contient que des identifiants publics : il peut être commité. La sécurité des données repose sur les règles Firestore.

## Dépannage

| Symptôme | Solution |
|---|---|
| « Firebase n’est pas configuré » | `iOS/GoogleService-Info.plist` absent ou mal nommé (pas de « (1) »). Puis ⌘ ⇧ K et ⌘ R. |
| « Google n’est pas configuré » | Le fichier a été téléchargé avant l’activation de Google : retélécharge-le. |
| « Ce mode de connexion n’est pas activé » | Active le fournisseur dans Authentication > Sign-in method. |
| « Hors ligne » ou « Sauvegarde du compte échouée » | Base Firestore non créée ou règles non publiées. |
| Erreurs « Unable to find module dependency » | File > Packages > Reset Package Caches, puis Resolve Package Versions. |
| Signature refusée sur un iPhone | Choisis ton équipe ; avec un compte gratuit, retire la capacité Sign in with Apple. |

Le message complet de chaque erreur de connexion est écrit dans la console Xcode (ligne « Erreur d’authentification »).

## Travailler sur le projet

Le projet Xcode est **généré** par `tools/generate-project.cjs` : un réglage modifié à la main dans Xcode serait perdu à la prochaine génération. Pour ajouter un fichier, une cible ou un réglage, modifie ce script puis lance `node tools/generate-project.cjs`. Node n’est pas nécessaire pour ouvrir le projet ou jouer.

~~~bash
git pull
git status
git add <fichiers modifiés>
git commit -m "Verbe à l’indicatif + ce qui change"
git push
~~~

Les messages de commit décrivent le changement au présent (« Ajoute… », « Corrige… »), une étape par commit.

### Références

- SwiftUI : https://developer.apple.com/documentation/swiftui
- Tests XCTest et tests d’interface : https://developer.apple.com/documentation/xctest
- Firebase Authentication iOS : https://firebase.google.com/docs/auth/ios/start
- Cloud Firestore : https://firebase.google.com/docs/firestore
