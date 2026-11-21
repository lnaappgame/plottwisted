# Classement global sur l'avancée — PT 1.0.16

Demandé par Damien le 21/11/2026 (idée d'un testeur). Codé dans le worktree
`agent-a82ad22c656f72e51` (branche `worktree-agent-a82ad22c656f72e51`), **non
commité**, sans build. Le calendrier de l'Avent n'est pas touché (aucun fichier
de l'Avent modifié ; ses tests passent).

## Ce que voit le joueur

- **Accueil** : un bouton trophée à côté du profil (avatar + pseudo), en haut à
  gauche. Visible **seulement si l'interrupteur à distance est allumé**. Pas de
  hauteur en plus sur l'accueil (vérifié en 320×568).
- **Écran « CLASSEMENT »** (« Les joueurs en français, classés par niveaux
  résolus » / « Players in English… ») :
  - en haut, le **top 50** : `123   Bobdu13   16-3` (rang, pseudo, monde-niveau) ;
    les ex aequo ont le même rang (1, 1, 3…) ;
  - en bas, **toujours visible** : « TA PLACE », « 123e sur 4 567 » (« #123 of
    4,567 » en anglais), les **3 joueurs juste au-dessus** puis la ligne du
    joueur en surbrillance ;
  - non inscrit : sa ligne s'affiche quand même (« Toi », avec la place qu'il
    aurait, compté dans le total) + « Tu n'apparais pas dans le classement :
    cette place, toi seul la vois » + bouton « APPARAÎTRE DANS LE CLASSEMENT » ;
  - inscrit : « Changer de pseudo » et « Me retirer » ;
  - aucun niveau résolu : « Résous ton premier niveau pour entrer dans le
    classement » ;
  - hors ligne : « Classement indisponible pour le moment » + « RÉESSAYER ».
- **Première ouverture** : la fenêtre « APPARAÎTRE DANS LE CLASSEMENT ? » s'ouvre
  une fois (« Ton pseudo et ton avancée seront visibles par tous les joueurs.
  C'est facultatif, et tu peux te retirer quand tu veux. »), pseudo prérempli et
  modifiable, boutons « APPARAÎTRE » / « Pas maintenant ».
- **Pseudo refusé** par `isNicknameAcceptable` : « Ce pseudo n'est pas accepté.
  Choisis-en un autre (pas d'insulte, de lien ni de numéro). » Rien ne part.
- **Retrait** : confirmation, puis le document est supprimé des deux classements
  (« C'est fait : tu n'apparais plus dans le classement. »). Hors ligne, la
  suppression est retentée au lancement suivant et à l'ouverture suivante.
- **Réglages** : un joueur inscrit a toujours la ligne « Me retirer du
  classement » (même confirmation, même suppression dans les deux langues),
  **y compris quand l'interrupteur est éteint** (droit à l'effacement). Jamais
  inscrit : rien ne s'affiche, interrupteur allumé ou non.

## Un seul pseudo

- Le pseudo du classement est **« Ton pseudo » de l'accueil**
  (`AppSettings.playerId`, « #123456 » tiré au hasard à l'installation), celui
  que le joueur connaît et que la politique de confidentialité décrit.
- La fenêtre du classement le **préremplit** ; s'il n'a jamais été personnalisé
  (« #123456 »), elle préremplit « Cinéphile » (« Cinephile » en anglais).
- Le changer dans cette fenêtre change aussi celui de l'accueil : une seule
  valeur. Exception : accepter « Cinéphile » tel quel quand l'identifiant
  n'a jamais été personnalisé laisse « #123456 » à l'accueil (le pseudo
  publié est alors « Cinéphile »). Si l'envoi échoue, rien ne change.
- Le changer depuis l'accueil (inscrit) : le classement le prend **à la
  prochaine écriture** (niveau suivant résolu), sans écriture en plus. Il passe
  toujours par `isNicknameAcceptable` : refusé (ou jamais personnalisé), c'est
  « Cinéphile » qui part. Sur l'écran du classement, la ligne du joueur montre
  déjà son pseudo actuel.
- Le Multijoueur n'est pas touché (voir points ouverts).

## Calcul du score et du « monde-niveau »

La progression de PT **n'est pas linéaire** : après chaque monde, le joueur
choisit entre deux mondes (l'autre reste en réserve), et un niveau peut être
laissé de côté (« Passer, j'y reviendrai »). `worldIndex-currentLevelNumber` ne
dit donc pas l'avancée réelle (un joueur peut être dans le monde 28 en réserve
alors qu'il a fini le 30, ou au niveau 7 avec 2 niveaux faits).

**Score = nombre de niveaux résolus, hors tutoriel** (`progressScore` dans
`lib/services/progress_leaderboard.dart`) :

- chaque monde de `worldsPlayedHistory` autre que le monde en cours compte pour
  tous ses niveaux (on ne quitte un monde qu'après l'avoir fini) ;
- monde en cours : `niveaux du monde − remainingLevels.length`, **+1** si le
  niveau vient d'être trouvé et que « SUIVANT » n'a pas encore été touché
  (`hasPendingSolve` : il est encore dans `remainingLevels`) ;
- tutoriel = 0 ; monde inconnu de cette version = 0 ; plafond 600.

**Monde-niveau = position du dernier niveau résolu si les mondes avaient été
joués dans l'ordre**, 10 niveaux par monde (tous les mondes en ont 10, vérifié
par un test) : `((score − 1) ÷ 10) + 1` - `((score − 1) mod 10) + 1`.
153 → « 16-3 » (15 mondes finis + 3 niveaux du suivant), 150 → « 15-10 ».

Pourquoi : calculé depuis le score seul, il suit toujours l'ordre du classement
(un joueur au-dessus n'affiche jamais un monde-niveau plus petit), deux joueurs à
égalité affichent la même chose, et un seul champ (`score`) suffit en ligne.
La légende sous le top 50 l'explique : « À droite, l'avancée : 16-3 veut dire
15 mondes finis et 3 niveaux du suivant. »

## Modèle de données (Firestore)

| Chemin | Champs | Écrit par |
|---|---|---|
| `progress_leaderboard_fr/{uid}` | `pseudo` (string 1-20), `score` (int 1-600), `updatedAt` (heure serveur), `expireAt` (timestamp, +24 mois) | le joueur, son propre document |
| `progress_leaderboard_en/{uid}` | idem | idem |
| `app_config/public` | `progressLeaderboardEnabled` (booléen) | console uniquement |

- `{uid}` = UID anonyme Firebase (déjà utilisé par les autres classements).
- Langue du classement = langue du jeu (`fr`, tout le reste = `fr` ; `en`).
  Si le joueur change de langue, son document est supprimé de l'ancien
  classement et recréé dans le nouveau au prochain envoi.
- **Requêtes à l'ouverture de l'écran** (jamais en continu) :
  `orderBy(score desc).limit(50)`, `count()` (total),
  `where(score > mon score).count()` (rang), `where(score > mon score)
  .orderBy(score).limit(3)` (les 3 au-dessus), et au plus 3 `count()` de plus
  pour le rang de ces 3-là s'ils ne sont pas dans le top 50 ; + 1 lecture de son
  propre document pour un non-inscrit (reprise après réinstallation). Environ
  55 à 60 lectures par ouverture. **Aucun index composite** : l'index simple sur
  `score` créé d'office par Firestore suffit.
- **Écritures** : `set` du document complet à la résolution d'un niveau, au plus
  une toutes les 60 s et seulement si le score a monté (sinon un seul envoi
  différé part à la fin des 60 s) ; rattrapage au lancement ; à l'ouverture de
  l'écran si le score a monté. Changement de pseudo = même score réécrit.
- **Interrupteur** : 1 lecture serveur au lancement (après Firebase et App
  Check), valeur gardée en cache local. Absent, illisible ou hors ligne sans
  cache = désactivé : aucun bouton, aucune écriture (seul un retrait déjà
  demandé est encore envoyé : l'effacement passe avant l'interrupteur).
- **État local** : clé SharedPreferences `cine_devinette_progress_leaderboard_v1`
  (participation, dernier score envoyé, heure du dernier envoi, langue du
  document, retrait en attente, proposition déjà faite, interrupteur en cache).
  Le pseudo n'y est pas : c'est `playerId`, dans les réglages (donc dans la
  sauvegarde Google). Volontairement hors sauvegarde cloud ; un document
  retrouvé en ligne (réinstallation avec compte Google lié) est repris à
  l'ouverture.

## Règles à coller dans la console

Console Firebase → Firestore Database → Règles : coller **tout le fichier
`firestore.rules`** du worktree (il garde les règles existantes à l'identique et
ajoute le bloc ci-dessous juste avant les deux dernières accolades), puis
« Publier ».

```
    // ─── Classement sur l'avancée (1.0.16) ───
    // Un classement par langue de contenu (deux collections, pour ne pas
    // avoir besoin d'index composite) ; un document par joueur volontaire,
    // identifié par son UID anonyme Firebase :
    //   { pseudo: string 1-20, score: int 1-600 (niveaux résolus),
    //     updatedAt: heure du serveur, expireAt: date de suppression (TTL) }
    // Vérifié contre lib/services/progress_leaderboard_firestore.dart.

    // Document valide : seulement les 4 champs attendus, tous présents.
    // updatedAt doit être l'heure du serveur (FieldValue.serverTimestamp()) ;
    // expireAt = 24 mois après l'écriture (data_retention.dart), borné ici
    // entre 1 jour et 3 ans pour qu'il ne puisse ni manquer ni être repoussé
    // indéfiniment.
    function isValidProgressEntry(data) {
      return data.keys().hasOnly(['pseudo', 'score', 'updatedAt', 'expireAt'])
          && data.keys().hasAll(['pseudo', 'score', 'updatedAt', 'expireAt'])
          && data.pseudo is string
          && data.pseudo.size() >= 1
          && data.pseudo.size() <= 20
          && data.score is int
          && data.score >= 1
          && data.score <= 600
          && data.updatedAt == request.time
          && data.expireAt is timestamp
          && data.expireAt > request.time + duration.value(1, 'd')
          && data.expireAt < request.time + duration.value(1100, 'd');
    }

    // Lecture publique (top 50, rang et total par count()). Création et mise
    // à jour seulement de SON document, avec un score qui ne descend jamais
    // (un changement de pseudo garde le même score). Suppression de son
    // propre document permise : c'est le retrait du joueur (droit à
    // l'effacement).
    match /progress_leaderboard_fr/{uid} {
      allow read: if true;
      allow create: if request.auth != null
                    && request.auth.uid == uid
                    && isValidProgressEntry(request.resource.data);
      allow update: if request.auth != null
                    && request.auth.uid == uid
                    && isValidProgressEntry(request.resource.data)
                    && request.resource.data.score >= resource.data.score;
      allow delete: if request.auth != null && request.auth.uid == uid;
    }

    match /progress_leaderboard_en/{uid} {
      allow read: if true;
      allow create: if request.auth != null
                    && request.auth.uid == uid
                    && isValidProgressEntry(request.resource.data);
      allow update: if request.auth != null
                    && request.auth.uid == uid
                    && isValidProgressEntry(request.resource.data)
                    && request.resource.data.score >= resource.data.score;
      allow delete: if request.auth != null && request.auth.uid == uid;
    }

    // Réglages publics du jeu, dont l'interrupteur du classement sur
    // l'avancée (app_config/public, champ booléen
    // progressLeaderboardEnabled). Lus par tous au lancement ; modifiés
    // seulement depuis la console Firebase (qui ignore ces règles).
    match /app_config/{doc} {
      allow read: if true;
      allow write: if false;
    }
```

Conseil : avant « Publier », tester dans le simulateur de règles de la console
(1) une création de `progress_leaderboard_fr/<uid>` authentifiée avec
`{pseudo: "Bob", score: 3, updatedAt: request.time, expireAt: +730 j}` → permis ;
(2) la même avec `score: 2` sur un document à 3 → refusé ; (3) une lecture non
authentifiée de `app_config/public` → permise.

## Console : à faire (dans cet ordre)

1. **Règles** : publier `firestore.rules` (ci-dessus).
2. **Interrupteur** : Firestore → Démarrer une collection `app_config` →
   document `public` → champ `progressLeaderboardEnabled`, type **boolean**,
   valeur `false` pour publier la 1.0.16 éteinte, puis `true` le jour voulu.
   Sans ce document, le classement reste invisible (c'est voulu).
   Attention au type : la chaîne `"true"` ne l'allume pas.
3. **TTL** (durée de conservation) : Firestore → TTL → ajouter une règle sur le
   groupe de collections `progress_leaderboard_fr`, champ `expireAt`, puis la
   même pour `progress_leaderboard_en`.
4. **Index** : rien à créer (index simple sur `score`, automatique). Si la
   console affiche un jour un lien « créer l'index » dans les journaux, le suivre.
5. **GA4** (facultatif, pour lire les rapports) : déclarer en dimensions
   personnalisées (portée événement) `rank_bucket` et `joined`.

Éteindre en cas de souci : passer `progressLeaderboardEnabled` à `false`. Les
joueurs qui ont déjà lu `true` le gardent en cache jusqu'à leur lancement
suivant (la lecture se fait à chaque lancement).

## Mesure (GA4)

- `leaderboard_open {rank_bucket, joined}` — à chaque ouverture de l'écran ;
  `rank_bucket` ∈ `top10`, `top50`, `top100`, `top1000`, `more`, `none` (aucun
  niveau résolu), `offline` (classement indisponible) ; `joined` = 1 si le
  joueur apparaît. Jamais le rang exact ni le pseudo.
- `leaderboard_join` — première inscription (pas les changements de pseudo).
- `leaderboard_leave` — retrait.
- Aucun nom réservé (vérifié par un test avec `AnalyticsService.isReservedName`).
  Comme les autres événements, ils attendent la réponse au consentement.

## Politique de confidentialité — paragraphes à ajouter

À placer au point 2.3 « Classements en ligne et Multijoueur » de
`docs/index.html` (et sa version anglaise), avec une ligne au point 6 et au
point 7.

**FR — point 2.3 (nouvelle puce)**

> pour le **classement des joueurs** (facultatif) : seulement si tu choisis d'y
> apparaître, ton **pseudo** (celui de ton profil, sur l'écran d'accueil) et
> ton **avancée** (nombre de niveaux résolus, affiché sous la forme
> « monde-niveau ») sont envoyés à nos serveurs et **visibles par tous les
> joueurs** de l'application. Rien n'est envoyé tant que tu ne l'as pas choisi,
> et tu peux consulter le classement sans y apparaître. Tu peux changer de
> pseudo ou **te retirer à tout moment**, depuis l'écran du classement ou les
> Réglages (« Me retirer du classement ») : ton pseudo et ton avancée sont
> alors effacés de nos serveurs. N'y mets ni ton vrai nom ni aucune
> information personnelle.

**FR — point 6 (nouvelle puce)**

> Le pseudo et l'avancée du classement des joueurs (point 2.3) sont conservés
> tant que tu y apparais, et au plus **24 mois** après ta dernière progression ;
> ils sont supprimés dès que tu te retires du classement.

**FR — point 7 (nouvelle puce)**

> pour le classement des joueurs (point 2.3) : directement depuis l'écran du
> classement (« Me retirer ») ou les Réglages (« Me retirer du classement »),
> ce qui efface ton pseudo et ton avancée.

**EN — section 2.3 (new bullet)**

> for the **player leaderboard** (optional): only if you choose to appear on
> it, your **nickname** (the one in your profile, on the home screen) and your
> **progress** (number of levels solved, shown as "world-level") are sent to
> our servers and are **visible to all players** of the app. Nothing is sent
> until you choose to join, and you can view the leaderboard without appearing
> on it. You can change your nickname or **leave at any time**, from the
> leaderboard screen or the Settings ("Leave the leaderboard"): your nickname
> and progress are then erased from our servers. Don't use your real name or
> any personal information.

**EN — section 6 (new bullet)**

> The nickname and progress shown on the player leaderboard (section 2.3) are
> kept for as long as you appear on it, and for at most **24 months** after your
> last progress; they are deleted as soon as you leave the leaderboard.

**EN — section 7 (new bullet)**

> for the player leaderboard (section 2.3): directly from the leaderboard screen
> ("Leave") or the Settings ("Leave the leaderboard"), which erases your
> nickname and progress.

À voir aussi : CGU art. 9 (« Fonctionnalités en ligne : classements et
multijoueur ») pourrait mentionner ce classement ; l'art. 7 sur les pseudos
s'applique déjà.

## Fichiers touchés

Nouveaux :
- `lib/services/progress_leaderboard.dart` — logique pure (score, monde-niveau,
  décision d'écriture, interrupteur, pseudo, rangs) + service `ProgressLeaderboard`.
- `lib/services/progress_leaderboard_firestore.dart` — accès Firestore.
- `lib/screens/progress_leaderboard_screen.dart` — écran + fenêtre du pseudo.
- `test/progress_leaderboard_test.dart` — 48 tests.
- `notes/classement-progression-1.0.16.md` — ce fichier.

Modifiés :
- `lib/main.dart` — création du service, état local lu avant l'affichage,
  `startup()` après Firebase/App Check (non attendu), fourniture facultative
  (`ProgressLeaderboard?`), branchement `gameState.onLevelSolved`, pseudo lu
  dans `appSettings.playerId` et rendu par `appSettings.setPlayerId`.
- `lib/services/game_state.dart` — seulement un rappel `onLevelSolved` appelé
  dans `_markSolved()` (bonne réponse ou joker « Passer définitivement »).
- `lib/screens/home_screen.dart` — bouton trophée à côté du profil (+ libellé
  d'accessibilité sur `_IconButton`).
- `lib/services/analytics_service.dart` — 3 événements.
- `lib/services/save_service.dart` — clé locale du classement.
- `lib/l10n/app_fr.arb`, `lib/l10n/app_en.arb` (+ fichiers générés par
  `flutter gen-l10n`) — 33 textes `lb*` (dont `lbSettingsLeave`).
- `lib/screens/settings_screen.dart` — ligne « Me retirer du classement »
  (inscrit seulement, même interrupteur éteint).
- `firestore.rules` — bloc ajouté, règles existantes intactes.

Non touchés : tout le code de l'Avent, `pubspec.yaml` (aucune dépendance
ajoutée, pas de Remote Config), les fichiers `*generated_plugin_registrant*` et
`.claude/settings.local.json` (déjà modifiés avant, laissés tels quels).

## Vérifications

Le 21/11/2026 vers 23 h 30, dans le worktree :

- `flutter gen-l10n` : OK (les `.arb` restent du JSON valide, sauts de ligne
  écrits `\n`).
- Retouches de PT prime (21/11 vers 23 h 40 : retrait dans les Réglages,
  pseudo unique) : tests du classement + `widget_test` +
  `settings_cloud_backup_test` = **51 verts** ; suite complète relancée
  (2e passe ci-dessous).
- `flutter analyze` sur les 4 nouveaux fichiers : **No issues found**.
  `flutter analyze lib test` : **0 erreur, 0 avertissement** (2 114 « info »
  déjà présentes : `withOpacity`, `annotate_overrides`…). `flutter analyze` sur
  tout le projet : les seules erreurs sont, comme avant, dans
  `tool/export_xlsx.dart` (paquet `excel` absent des dépendances).
- `flutter test` (suite complète, 1re passe) : **429 tests, tous verts** (389
  avant + 40 nouveaux), dont tous ceux de l'Avent (`advent_calendar_test.dart`).
- Suite complète (2e passe, après les retouches, 21/11 vers 23 h 45) :
  **437 tests, tous verts** (389 avant + 48 du classement), Avent compris.
- Nouveaux tests (`test/progress_leaderboard_test.dart`, 48 au total) :
  - score : tutoriel, monde en cours, niveau trouvé avant « SUIVANT », mondes
    choisis hors ordre, monde fini, monde inconnu, plafond, vraie `GameState`,
    10 niveaux par monde ;
  - monde-niveau (1 → 1-1, 10 → 1-10, 11 → 2-1, 150 → 15-10, 153 → 16-3) ;
  - écritures : décision pure (60 s, score qui monte, horloge qui recule),
    deux niveaux en 10 s = 1 écriture puis 1 après 60 s, score qui ne monte pas,
    rattrapage au lancement, non-inscrit, changement de langue ;
  - interrupteur : absent / champ absent / `"true"` en texte / `1` = éteint,
    hors ligne sans cache = éteint sans écriture ni inscription, cache gardé,
    document absent qui éteint malgré le cache, extinction à distance ;
  - pseudo : filtre et longueur 1-20, pseudo refusé (rien ne part), filet
    d'affichage ; pseudo unique : prérempli depuis l'accueil ou « Cinéphile »,
    jamais « #123456 » publié, pseudo choisi = pseudo de l'accueil,
    « Cinéphile » accepté qui garde « #123456 », changement depuis l'accueil
    publié à l'écriture suivante sans écriture en plus (et « Cinéphile » s'il
    est refusé), inscription échouée qui ne touche pas l'accueil ;
  - Réglages, interrupteur éteint : « Me retirer du classement » visible et
    efficace pour un inscrit (suppression dans les deux langues), absent pour
    un joueur jamais inscrit ; retrait du service possible interrupteur éteint ;
  - rangs ex aequo (1, 1, 3, 4, 4, 6), tranches de mesure, noms non réservés ;
  - participation : inscription/retrait (suppression dans les 2 classements),
    retrait hors ligne retenté, inscription à 0 niveau, inscription hors ligne,
    changement de pseudo, reprise d'un document après réinstallation, totaux ;
  - écrans (faux serveur, sans réseau) : top 50 + 3 au-dessus + « 123e sur
    4 567 » (FR), « #123 of 4,567 » en 320×568 sans débordement (EN), première
    ouverture avec pseudo refusé puis « Pas maintenant », trophée de l'accueil
    seulement si l'interrupteur est allumé (320×568, sans débordement).

## Points ouverts

1. **Multijoueur à aligner dans la 1.0.17** : le classement utilise désormais
   « Ton pseudo » de l'accueil (`playerId`), mais le **nom envoyé au
   Multijoueur reste « Cinéphile »** (`settings.playerName`, qui n'a aucun
   champ de saisie), alors que la politique de confidentialité dit que ce
   pseudo se modifie depuis l'accueil. Non touché ce soir (demande de PT
   prime) : faire envoyer `playerId` (filtré, « Cinéphile » si jamais
   personnalisé) au Multijoueur dans la 1.0.17.
2. **Brief : « 30 mondes en anglais »** : dans le code actuel, les 35 mondes
   existent dans les deux langues (mêmes mondes, mêmes niveaux, réponses
   traduites). Les deux classements séparés restent utiles (réponses
   différentes, communautés différentes) mais comparent la même progression.
3. **Remise à zéro de la progression** (Paramètres) : le score publié ne
   descend jamais (règle validée) ; le joueur garde son ancien score jusqu'à
   le dépasser. Pour repartir de zéro au classement : « Me retirer » puis
   « Apparaître ».
4. **Interrupteur éteint** : plus de trophée ni d'écran, mais un inscrit garde
   « Me retirer du classement » dans les Réglages. Les documents des autres
   restent (et expirent après 24 mois). Un joueur qui a réinstallé l'appli
   (participation inconnue du téléphone) ne voit pas cette ligne tant que
   l'écran n'a pas repris son document : il passe alors par l'e-mail (point 7
   de la politique). Si on éteint durablement, envisager de vider les collections.
4 bis. **Pseudo changé depuis l'accueil** : publié seulement à l'écriture
   suivante (niveau suivant résolu). Un inscrit qui ne joue plus garde son
   ancien pseudo en ligne ; « Changer de pseudo » dans le classement l'envoie
   tout de suite.
5. **Changement d'identifiant Firebase** (connexion Google qui remplace l'UID
   anonyme par un autre) : l'ancien document ne peut plus être supprimé depuis
   le téléphone ; il expire au bout de 24 mois. Cas rare.
6. **Total pour un non-inscrit** : « 123e sur 4 567 » compte le joueur dans le
   total (place qu'il aurait). Les ex aequo d'un non-inscrit partagent son rang.
7. **Coût** : ~55-60 lectures par ouverture de l'écran, 1 lecture par lancement
   (interrupteur), au plus 1 écriture par minute de jeu pour un inscrit. Sur
   Blaze, quelques centimes même à plusieurs milliers d'ouvertures par jour. Si
   besoin, réduire le top à 20 (constante `kProgressTopCount`).
8. **Bornes de `expireAt`** dans les règles (1 jour à 3 ans) : un téléphone dont
   l'horloge est faussée de plus d'un an verrait ses envois refusés (avalés,
   sans gêne pour le jeu).
9. Pas testé sur un vrai téléphone ni contre le vrai Firestore (pas de build
   demandé) : à vérifier sur le OnePlus avec l'interrupteur à `true` (document de
   test), notamment la première lecture des règles et du `count()`.
