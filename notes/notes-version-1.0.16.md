# Version 1.0.16 : calendrier de l'Avent + protection contre les clics en rafale

Prévue le vendredi 27/11/2026. Créée le 20/11 par PT prime : le correctif du préchargement des pubs est sorti seul en 1.0.15, et le Noël prévu en 1.0.15 passe ici.

## Contenu prévu

- **Calendrier de l'Avent ciné** : voir `event-noel-calendrier-avent-2026.md` et `event-noel-pitchs-2026.md` (pitchs à valider par Damien).
- **Protection contre les clics en rafale** (oui de Damien le 20/11 : « mets la protection dans la version du 27/11 ») :
  - après 3 clics sur des pubs dans la même journée, le joueur ne voit plus de pub plein écran (interstitielle) jusqu'au lendemain ;
  - la vidéo avec récompense reste disponible, puisque c'est le joueur qui la demande ;
  - le compteur est gardé d'un lancement à l'autre (sinon il suffit de relancer le jeu) et repart à zéro chaque jour ;
  - à brancher sur `FullScreenContentCallback.onAdClicked` dans `lib/services/ad_service.dart` ;
  - pourquoi : le 16/11, 170 clics pour 110 interstitielles affichées en France sur Android (`releves-cowork-2026-11-20.md`) ; un clic en rafale met en danger le compte AdMob commun à tous les jeux.
- **In-App Event Apple et contenu promotionnel Google Play** pour le calendrier de l'Avent (idée du plan de Cowork).
- **Pub croisée « Nos autres jeux »** (`studio/pub-croisee-spec.md`), prévue à l'origine pour la 1.0.15.

## À relever une semaine après la sortie

- Taux de clics de l'interstitielle Android en France, jour par jour.
- Nombre de joueurs qui atteignent le plafond de 3 clics.

## Mesure et premier lancement (ajouté le 20/11, validé par Damien : « parfait »)
- Étapes du premier lancement en `tutorial_step` {step, step_name} : intro vue, accueil, JOUER, choix du tutoriel, énigme affichée, 1re lettre, 1re réussite ; plus `level_start`, et l'abandon d'un niveau.
- Mise en attente des événements avant la réponse au consentement (règle du studio, comme le Clos : en mémoire, 200 au plus, envoyés après l'accord, effacés après un refus).
- Liste complète des `SKAdNetworkItems` d'AdMob dans `ios/Runner/Info.plist` (seul l'identifiant de Google y est aujourd'hui) : reprendre exactement les 50 identifiants de Faisceau (commit 411fa45, source developers.google.com/admob/ios/3p-skadnetworks, mise à jour du 30/01/2026), pour que tous les jeux restent identiques.
- Premier lancement allégé (à confirmer avec le plan commun Cowork + PT prime) : directement dans la 1re énigme, consentement après la 1re réussite, jokers cachés au début.
- Test Google Ads iPhone FR à 5 €/j : 7 jours sur la 1.0.15, puis 7 jours sur la 1.0.16, pour avoir un avant/après sur le même trafic.
- Demande de note (Damien, 20/11, précisé à 22 h 30) : ajouter la fin du niveau 1-5 comme moment de demande, en plus des 3 jours de suite et de l'énigme trouvée du premier coup ; 2 demandes au plus par installation, jamais pendant le tutoriel.
- Consentement après la 1re réussite, version du Jardin (0.6.3, 20/11) à reprendre : au lancement, mise à jour UMP sans fenêtre et lecture du statut. Si le statut est notRequired (hors RGPD) ou obtained (déjà répondu) : mesure et pubs tout de suite. Sinon : formulaire après la 1re réussite, à la 1re vidéo demandée, ou au plus tard 3 min après le lancement. Erreurs UMP dans Crashlytics (non fatales), pas d'événement `ump_error`.
- Petite icône des notifications Android : aujourd'hui un rond blanc dans le volet (« Défi du jour »), parce que c'est l'icône en couleur du jeu. La remplacer par une silhouette blanche (vecteur dans `res/drawable`, gardé en release par `res/raw/keep.xml`). Modèle : Jardin 02010f2, `ic_stat_graine.xml`.

## Notes de version proposées (pour les joueurs seulement, règle de Damien du 21/11)
Sans emoji, moins de 500 caractères. Aucun réglage interne (pubs, mesures, consentement, protection anti-clics).

**Français**
```
Nouveau : le calendrier de l'Avent ciné ! Du 1er au 25 décembre, ouvre une case chaque jour : le Père Noël raconte un film de Noël, à toi de le retrouver parmi 4 titres. Attention, 3 sont des pièges !
Les rappels du défi du jour arrivent plus à l'heure.
Corrections et petites améliorations.
```

**English (US)**
```
New: the movie Advent calendar! From December 1 to 25, open a door every day: Santa tells you about a Christmas movie, and you pick it out of 4 titles. Careful, 3 of them are traps!
Daily challenge reminders now arrive closer to their time.
Bug fixes and small improvements.
```

## Build (26/11, PT prime)

- Avent passé en QCM à pièges (demande de Damien du 26/11 au matin) : commits 83bd763, 2633662, 3b2bf17 du worktree agent-a82ad22… (498 tests verts).
- Commit de build : 00ac0b1 (= 3b2bf17 + date de test `ADVENT_TEST_DATE`, sans effet en production). Les builds de 3b2bf17 sont rangés dans `build/pt-1.0.16/ancien-3b2bf17/`.
- AAB de production (REAL_ADS) : `build/pt-1.0.16/plottwisted-1.0.16-22-00ac0b1.aab`, SHA-256 765ba631…c3bd6951, construit à 09 h 49.
- APK release avec vraies pubs (même commit) : `plottwisted-1.0.16-22-00ac0b1.apk` : NE PAS installer sur nos téléphones (clics AdMob).
- APK release avec pubs de test, Avent réglé au 5 décembre : `plottwisted-1.0.16-22-00ac0b1-PUBS-TEST-5DEC.apk`, installé sur le OnePlus le 26/11 à 09 h 52 (lancement sans plantage, bouton « Calendrier de l'Avent » avec 5 cases à l'accueil).

## Reste à faire

- [ ] Test de Damien sur le OnePlus : Avent en QCM (cases 1 à 5 jouables grâce à la date de test), achats de jokers (livré puis consommé, mode avion), défi du jour, premier lancement.
- [ ] Fusionner la branche du worktree dans main, pousser, build iOS Codemagic « Release App Store (vraies pubs) ».
- [ ] Envoi aux deux stores le 27/11 au plus tard (case du 1er décembre).
