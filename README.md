# Perfect Rush

Projet de cours — **Théo BOREL et Lana SCHMITT**.

Mini-jeu de précision en SwiftUI pour **iPhone et Apple Watch**. Deux apps autonomes, un moteur de règles commun, aucun compte ni serveur.

## Sur ton Mac : installation de zéro

1. Ouvre Xcode et termine l’installation de ses composants. Ce projet cible iOS 17 et watchOS 10 ; Xcode 15 minimum, une version récente compatible avec ton macOS est préférable.
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

Le décor de tour indique la progression par cycles de six étages ; le compteur donne le total. Le jeu inclut les retours haptiques, mais pas encore de musique, de sons, de boutique ou de cosmétiques à débloquer. Pas de notifications, de publicités ni de paiement.

## Tests

20 tests unitaires couvrent les règles partagées, dont les régressions sur les limites de cible, le redémarrage, la pause, l’expiration de Fever, les doubles appuis et les pas de temps invalides.

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
git add Sources Shared iOS Watch Widgets Tests PerfectRush.xcodeproj
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
