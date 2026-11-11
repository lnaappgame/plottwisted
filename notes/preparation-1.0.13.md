# Préparation de la 1.0.13 : état au 09/11/2026, 2 h 30 (PT prime)

Rien n'est commité. Tout est en local sur `main` (copie de travail) et attend le « go » de Damien.

## Fait et testé (293 tests verts, analyse propre sur lib/ et test/)

1. **Pubs chargées à la demande**, fini le préchargement (08/11).
   Fichiers : `lib/services/ad_service.dart`, `game_state.dart` (`prepareForcedAd`) et `main.dart` (`enableAds`). Test : `test/ad_lazy_loading_test.dart`.
   Effet attendu : le taux d'affichage AdMob passe de 45 % à environ 90 %. Les demandes inutiles disparaissent, avec le même nombre d'impressions.
2. **Filtre basique du pseudo.** Un pseudo jugé inacceptable n'est jamais montré aux adversaires : il part sous « Cinéphile » / « Cinephile ». Sont visés les insultes FR/EN (y compris écrites en leet, accentuées ou masquées), les liens, les e-mails et les numéros de téléphone. Le joueur garde son pseudo chez lui.
   Fichiers : `lib/services/nickname_filter.dart`, branché dans `multiplayer_state.dart` (`recordRun`). Test : `test/nickname_filter_test.dart`. Les vrais pseudos passent : Constance, Faucon, Technique, député, Hitchcock, Moby Dick, Scunthorpe, R2D2, Agent 007.
3. **Conservation de 24 mois.** Chaque écriture en ligne porte désormais `expireAt` (maintenant + 730 jours) : scores de l'énigme de la semaine, manches Multijoueur, Elo.
   Fichiers : `lib/services/data_retention.dart`, `leaderboard_service.dart`, `multiplayer_matchmaking_service.dart`. Les règles Firestore restent inchangées : les anciennes versions de l'appli continuent d'écrire sans ce champ, sans erreur.
4. **Consentement Analytics par finalité (TCF).** Pour un joueur soumis au RGPD, Analytics n'est activé que s'il a accepté les finalités 1 (stockage) ET 8 (mesure du contenu) dans la fenêtre UMP. Avant, Analytics s'allumait dès que la fenêtre avait été répondue, même en cas de refus. Hors RGPD, rien ne change. Le réglage est réappliqué à la fermeture de « Options de confidentialité des pubs ».
   Fichiers : `lib/services/tcf_consent.dart`, `main.dart`, `ad_service.dart`, `pubspec.yaml` (`shared_preferences_android` en dépendance directe, déjà présent en dépendance indirecte). Test : `test/tcf_consent_test.dart`.
   Crashlytics reste toujours actif (intérêt légitime, inchangé).

## À faire avant la sortie

- [x] **Test réel de la version release, le 10/11 à 8 h 25, sur le OnePlus** (installation neuve, journaux Analytics en mode verbeux) :
  - « Refuser » dans la fenêtre RGPD → `Setting app measurement enabled (FE): false`, puis `Event not sent since app measurement is disabled`.
  - Réglages → Options de confidentialité → « Autoriser » → `enabled (FE): true`, et la session démarre.
  - Réglages → « Refuser » à nouveau → `false`. Le retrait marche aussi.
  - Aucun plantage. L'appli a ensuite été désinstallée du téléphone de test, et les propriétés de débogage remises à zéro.
  - Pseudo grossier : **pas testé en réel**, parce que ça aurait déposé une fausse manche dans le vivier de fantômes des vrais joueurs. Les 5 tests unitaires le couvrent.
- [x] **Règle TTL Firestore** : les 3 politiques sur `expireAt` (`scores`, `runs`, `multiplayer_players`) ont été créées par Damien le 09/11. Elles sont actives (« Diffusion »).
- [x] `android/gradle.properties` mis à la charte v1.5 le 10/11 : `-Xmx3G` au lieu de 8G, et `idletimeout` à 5 min.
- [ ] **Documents anciens sans `expireAt`** (depuis octobre 2026) : un script ponctuel de complément, à passer avant octobre 2028. Rien d'urgent.
- [x] **Pages légales** : les 8 corrections du 05/11 sont EN LIGNE depuis le commit 35f062a (vérifié le 10/11). OK de Damien le 10/11 pour la suite.
- [ ] **§2.4, §3 et §7 (FR + EN) rédigés en local le 10/11, non commités** : Analytics soumis au consentement UE/EEE/RU/Suisse (finalités 1 + 8), Crashlytics et App Check en intérêt légitime, retrait via « Options de confidentialité des pubs ». **À publier le jour où la 1.0.13 est en ligne**, pas avant, sinon la politique décrit ce que l'appli ne fait pas encore.
- [ ] **Sécurité des données (Play) et étiquettes App Store** : déclarer le pseudo comme « identifiant utilisateur, visible des autres joueurs ».
- [ ] Notes de version (sans emoji, ASC les refuse), puis numéros de build.
