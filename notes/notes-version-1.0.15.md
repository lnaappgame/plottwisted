# Version 1.0.15 : préchargement des pubs rétabli

État au 20/11/2026 (PT prime). Décision de Damien le 20/11 : « on va remettre le préchargement d'une pub de chaque (reward et interstitiel) dans pt », puis « maintenant » pour la sortie, sans attendre le calendrier de l'Avent du 27/11 (qui passe en 1.0.16).

- Android : 1.0.15 (code 21), `flutter build appbundle --release --dart-define=REAL_ADS=true`.
- iPhone : 1.0.15, Codemagic « iOS — Release App Store (vraies pubs) » sur main.
- 320 tests verts.

## Contenu

- **Pubs préchargées** (`lib/services/ad_service.dart`) : une interstitielle et une pub à récompense sont chargées au lancement, puis rechargées après chaque affichage.
- **Plus aucune attente** : une pub n'est montrée que si elle est déjà prête. La 1.0.13 attendait jusqu'à 3 s l'interstitielle et 8 s la pub à récompense, écran de jeu visible dessous.
- Si la pub à récompense n'est pas prête, le joueur voit « pub indisponible » et peut retoucher le bouton quelques secondes après (comme avant la 1.0.13).
- Filet gardé : au début d'un niveau qui déclenchera une interstitielle, le jeu en redemande une si aucune n'est prête.

## Pourquoi

Relevé AdMob du 20/11 (`releves-cowork-2026-11-20.md`) : taux de clics anormal sur l'interstitielle Android en France. Les compléments montrent que le pic vient surtout de deux journées de clics en rafale (16 et 18/11), pas de la version. Le préchargement reste une précaution : aucune pub ne peut plus surgir en retard sous le doigt du joueur.

## Notes de version (« Nouveautés »)

Sans emoji (App Store Connect les refuse). Moins de 500 caractères par langue.

**Français**

```
Amélioration :
- Les publicités sont préparées à l'avance : plus de pub qui surgit en retard pendant la partie, et la vidéo pour gagner un joker démarre tout de suite.
```

**English**

```
Improvement:
- Ads are now prepared in advance: no more ad popping up late while you play, and the video to earn a joker starts right away.
```

**Bloc prêt à coller dans Google Play**

```
<fr-FR>
Amélioration :
- Les publicités sont préparées à l'avance : plus de pub qui surgit en retard pendant la partie, et la vidéo pour gagner un joker démarre tout de suite.
</fr-FR>
<en-US>
Improvement:
- Ads are now prepared in advance: no more ad popping up late while you play, and the video to earn a joker starts right away.
</en-US>
```

## Reste à faire

- [ ] Test du build release sur le OnePlus (lancement, pub à récompense prête tout de suite).
- [ ] Play : AAB glissé par Damien, notes, envoi en examen, publication.
- [ ] ASC : build Codemagic, version 1.0.15, envoi en examen, publication.
- [ ] Relever le taux de clics et le taux d'affichage AdMob une semaine après la sortie.
