# Mode "Multijoueur" — classement Elo asynchrone (parties fantômes)

Document de travail — explique la mécanique telle que définie jusqu'ici, liste
ce qui manque avant de pouvoir coder, et sert de base si tu veux en discuter
avec une autre session Claude.

## Résumé de l'idée

Un mode compétitif classé (Elo), mais **jamais en temps réel** : chaque partie
se joue contre l'enregistrement (temps de réponse) d'un vrai joueur ayant déjà
joué la même énigme, à un niveau Elo proche du tien au moment où lui-même l'a
jouée. Ni matchmaking live, ni serveur de jeu — juste de la lecture/écriture
dans Firestore (déjà en place pour L'énigme de la semaine et Défi du jour).
Seul le joueur qui lance la partie gagne ou perd des points ; le joueur dont
la partie sert de "fantôme" a déjà été crédité/débité au moment où IL a joué.

## Règles du jeu

- **Match** : au meilleur des 3 manches, victoire dès 2 points.
- **Manche** : 60 secondes max.
  - Le pitch se révèle lettre par lettre (comme L'énigme de la semaine), mais
    beaucoup plus vite : toutes les lettres doivent être visibles pile à
    35 secondes. Vitesse de révélation = 35s ÷ nombre de caractères
    alphanumériques du pitch (calculée automatiquement, pas besoin de la
    stocker dans le contenu).
  - Les 25 secondes restantes (35 → 60s) servent uniquement à finir de deviner
    la réponse — mais rien n'empêche de répondre plus tôt, dès qu'on a
    compris, comme dans le jeu principal.
- **Score de la manche** :
  - Le premier des deux (joueur ou fantôme) à trouver la bonne réponse gagne
    le point.
  - Si aucun des deux ne trouve en 60 secondes, **les deux gagnent le point**.
  - Un match peut donc se terminer nul à 2-2 après seulement 2 manches (si les
    deux manches sont "personne ne trouve").

## Système Elo

**Déjà décidé :**
- Valeur de départ : **2000**
- Plancher : **250** (jamais de score négatif)
- Plafond : **5000**
- Fourchette de recherche d'un fantôme : **± 50 points**, élargie par paliers
  de **50** si personne n'est trouvé dans la fourchette courante.

**K-factor — proposition inspirée du système Elo des échecs (FIDE)** :
les échecs utilisent un K variable selon l'expérience/niveau du joueur, pas
une valeur fixe pour tout le monde. Proposition adaptée à notre échelle
(2000 départ / 250 plancher / 5000 plafond) :
- **K = 40** pendant toute la phase de calibration (le classement doit
  converger vite vers le vrai niveau du joueur).
- **K = 20** en régime normal, pour la grande majorité des joueurs établis
  (équivalent du K "standard" FIDE).
- **K = 10** au-delà d'un seuil élevé (**4000+**) — stabilise le haut du
  classement.
- **K = 5** au-delà d'un seuil très élevé (**4500+**) — encore plus stable
  tout en haut de l'échelle.

**Implémenté tel quel** (`lib/services/elo_service.dart`, `kFactorFor`), y
compris un plancher : un delta qui arrondirait à 0 sur un écart Elo extrême
est forcé à ±1 (jamais un gain/perte nul hors match nul).

**Titres honorifiques (fournis, tranchés)** — 49 paliers tous les 100 points
(250 à 5000), le titre affiché est celui du seuil le plus haut atteint. Liste
complète dans `kTitresHonorifiques` (`lib/services/elo_service.dart`) — les 7
paliers les plus élevés (4400 à 5000) reprennent les 7 meilleurs titres de la
version précédente à 20 paliers.

## Temps fantôme de secours (résout le problème du "premier joueur")

**Révisé (2026-08-31) : la calibration n'est plus une notion "nouveau
joueur", elle est PAR ÉNIGME.** L'ancienne version (6 énigmes dédiées, tant
que le compteur personnel d'un joueur était < 6 ET qu'un compteur GLOBAL de
100 parties n'était pas atteint) posait un vrai problème une fois le
contenu étendu à 520 énigmes : la quasi-totalité du pool n'aurait jamais eu
de vrai enregistrement Firestore, et un joueur — nouveau ou expérimenté —
tombant dessus se serait retrouvé sans temps adversaire (filet de sécurité
existant à 45s, mais incohérent avec la calibration).

Nouvelle règle, appliquée à **chaque manche, pour l'énigme précisément
piochée ce tour-ci** (voir `_startRound()` dans `multiplayer_state.dart`) :
tant que CETTE énigme n'a pas encore **`kMultiplayerCalibrationMinRuns` = 10**
vraies parties enregistrées (compteur par énigme, `multiplayer_runs/{id}/runs`,
pas un total global), tout joueur qui la pioche — nouveau ou non — affronte
un temps fantôme fixe de **`kMultiplayerCalibrationFallbackSeconds` = 55s**,
présenté comme un adversaire normal (nom fixe "Néophilis"), sans vrai Elo
associé (K=40, comme l'ancienne "phase de calibration"). Une fois le seuil
franchi, cette énigme bascule en matchmaking réel pour tout le monde.

Le seuil de 10 (plutôt que les 100 imaginés initialement pour un total
global) est délibérément bas : avec 514 énigmes hors "cas triviaux" et une
pioche qui les fait tourner équitablement, un seuil élevé par énigme
prendrait des mois à être atteint pour la plupart du contenu — l'objectif
est juste d'éviter de se fier à un échantillon d'une ou deux parties.

La performance du joueur est **toujours** enregistrée (`recordRun`), même
sur une manche qui a elle-même utilisé le temps de secours — sinon une
énigme sous le seuil ne l'atteindrait jamais (chacun de ses tours
alimenterait le compteur sans jamais être exploité pour du vrai matching).

## Fantôme de match (tranché)

**Un fantôme différent par manche, indépendant.** Pour chaque manche, on
pioche une énigme du pool, puis on cherche indépendamment un enregistrement
Firestore pour CETTE énigme précise, proche de l'Elo du joueur — le
"fantôme" peut donc changer d'identité entre les manches d'un même match
(le joueur ne voit de toute façon jamais qui est en face). Chaque énigme
jouée par un vrai joueur s'enregistre comme une ligne indépendante, peu
importe dans quel match/quel ordre elle a été jouée à l'origine ; le
matching se fait manche par manche, pas au niveau du match entier.

**Filet de sécurité (tranché)** : si personne n'est trouvé dans la
fourchette ± 50, on élargit **en boucle par paliers de 50** (±100, ±150,
±200, ...) jusqu'à trouver une partie enregistrée pour cette énigme —
pas de plafond sur l'élargissement.

**Cas limite résolu** : cette boucle suppose qu'il existe *au moins un*
enregistrement réel pour cette énigme précise — ce n'est plus un problème
depuis le passage à la calibration par énigme ci-dessus : une énigme n'entre
JAMAIS dans cette recherche Firestore avant d'avoir déjà 10 vraies parties
enregistrées. Le filet de sécurité résiduel (`ghost == null` malgré le
seuil franchi, cas extrêmement rare) retombe simplement sur le même temps
fixe de 55s plutôt que de bloquer le joueur.

## Contenu (état actuel du jeu)

`lib/data/multiplayer_data.dart` contient désormais **520 énigmes**, toutes
dans le même pool (plus de distinction "calibration" au niveau du contenu
depuis le passage à la calibration par énigme, voir plus haut) — le contenu
initial (20 énigmes fournies via `cine_devinette_multijoueur.xlsx`) a depuis
été très largement étendu.

## Modèle de données (pour référence, côté code)

- **GameState joueur** (nouveau, ex. `MultiplayerState`) : `int eloRating`
  (persisté), `int matchesPlayed`, historique local optionnel.
- **Firestore** : chaque énigme jouée par un vrai joueur s'enregistre
  indépendamment — `multiplayer_runs/{enigmeId}/runs/{uid}` avec
  `{ eloAtTimeOfPlay, solveSeconds ou null si non trouvé, timestamp }`.
  Requête de matching (répétée à chaque manche, pour l'énigme piochée ce
  tour-ci) : `where('eloAtTimeOfPlay', >=, monElo-50).where('eloAtTimeOfPlay', <=, monElo+50)`,
  élargie par paliers de 50 si vide.
- Confiance au joueur (comme L'énigme de la semaine et Défi du jour) : pas de
  vérification serveur du temps de réponse.

## Faut-il purger les vieux enregistrements ? (réponse à ta question)

**Pas pour des raisons de coût ou de stockage** : chaque enregistrement est
minuscule (3 champs), Firestore reste largement dans le quota gratuit même
avec des dizaines de milliers de parties enregistrées par énigme (le
stockage total resterait de l'ordre de quelques Mo). Et une requête bornée
par `limit()` ne ralentit pas quand la collection grossit — Firestore
indexe correctement, chercher un match dans 50 ou 50 000 documents coûte
pareil.

**Et un enregistrement ne "périme" pas** : contrairement au classement
hebdomadaire de L'énigme de la semaine (où un vieux score n'a plus de sens
une fois la semaine finie), un temps de réponse à une énigme reste valable
indéfiniment — il ne devient pas "faux" avec le temps.

**Le vrai argument pour limiter, ce n'est pas l'âge, c'est la redondance** :
si une énigme très jouée accumule des milliers d'enregistrements autour du
même palier Elo, ils sont tous équivalents pour le matching (on n'en tire
qu'un seul à la fois) — les garder tous n'apporte rien, à part de la
variété (éviter de retomber sans cesse sur les mêmes fantômes). Si tu veux
limiter la croissance, je recommanderais plutôt un plafond du type "garder
au plus N enregistrements par énigme" (ex. 300-500), et **quand le plafond
est atteint, en supprimer un au hasard plutôt que le plus vieux** — l'âge
n'est pas le bon critère ici, la redondance l'est. Mais ce n'est pas urgent :
rien à faire avant d'avoir un vrai volume de joueurs (même raisonnement que
pour les coûts Firebase en général).

## Récapitulatif : état par rapport à ce document

Ce document décrivait la conception initiale du mode — **le mode est
aujourd'hui codé et publié**, avec quelques ajustements par rapport au plan
d'origine (K-factor à 4 paliers au lieu de 3, contenu étendu à 520 énigmes,
et surtout la calibration repensée par énigme plutôt que par joueur — voir
plus haut). Le plafond éventuel d'enregistrements Firestore par énigme (voir
section précédente) reste, lui, non implémenté — toujours pas urgent au
volume de joueurs actuel.

**Tranché et implémenté :**
- Fantôme différent par manche, indépendant (pas un seul fantôme pour tout le match).
- Temps fantôme de secours (55s) par énigme sous les 10 vraies parties enregistrées — plus de notion de "nouveau joueur" ni de compteur global.
- Filet de sécurité : élargissement en boucle par paliers de 50, sans plafond (le cas résiduel de la toute première fois qu'une énigme est piochée hors du temps de secours n'existe plus).
- Titres honorifiques : liste complète fournie (49 paliers, tous les 100 points).
- Contenu : 520 énigmes (voir section précédente).
