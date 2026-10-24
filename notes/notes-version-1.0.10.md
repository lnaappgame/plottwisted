# Version 1.0.10 — l'event Halloween

- Android : 1.0.10 (code 16), bundle `build/app/outputs/bundle/release/plottwisted-1.0.10+16.aab` (vraies pubs, copie dans Téléchargements).
- iPhone : 1.0.10, build Codemagic « iOS — Release App Store (vraies pubs) » sur la branche main.

## Contenu

- **Event Halloween** (jusqu'au 8 novembre) : 30 films d'horreur et d'Halloween racontés du point de vue de leur méchant, à trouver comme dans le jeu principal (sans noms colorés ; jokers Révéler, Éliminer et Révéler un mot). 10 pitchs le premier jour, puis 2 par jour. Avatars à gagner : Tête de citrouille et Citrouille en feu. La version « questions » est gardée sur la branche `halloween-enigmes`.
- **La bobine du jour** : un tour gratuit par jour pour gagner des jokers, et un relancement avec une pub.
- Plus de pub forcée quand un niveau a pris plus de 60 secondes.
- « Passer, j'y reviendrai » garde les jokers déjà joués sur le niveau.
- Toucher un nom coloré rappelle ce que veut dire sa couleur.
- Le conseil « tuiles ou clavier » reste affiché au moins 3 secondes.

## Notes de version (« Nouveautés »)

**Français (App Store et Google Play)**

> 🎃 Event Halloween jusqu'au 8 novembre : 30 films d'horreur racontés par leur méchant, et des avatars citrouille à gagner ! Nouveau : la bobine du jour, un tour gratuit chaque jour pour gagner des jokers. Moins de pubs, et tes jokers restent sur un niveau passé.

**Anglais (App Store et les 4 fiches anglaises de Google Play)**

> 🎃 Halloween event until November 8: 30 horror movies told by their villain, and pumpkin avatars to win! New: the daily reel, a free spin every day to win jokers. Fewer ads, and your jokers stay on a skipped level.

**Bloc prêt à coller dans Google Play**

```
<fr-FR>
🎃 Event Halloween jusqu'au 8 novembre : 30 films d'horreur racontés par leur méchant, et des avatars citrouille à gagner ! Nouveau : la bobine du jour, un tour gratuit chaque jour pour gagner des jokers. Moins de pubs, et tes jokers restent sur un niveau passé.
</fr-FR>
<en-US>
🎃 Halloween event until November 8: 30 horror movies told by their villain, and pumpkin avatars to win! New: the daily reel, a free spin every day to win jokers. Fewer ads, and your jokers stay on a skipped level.
</en-US>
<en-GB>
🎃 Halloween event until November 8: 30 horror movies told by their villain, and pumpkin avatars to win! New: the daily reel, a free spin every day to win jokers. Fewer ads, and your jokers stay on a skipped level.
</en-GB>
<en-CA>
🎃 Halloween event until November 8: 30 horror movies told by their villain, and pumpkin avatars to win! New: the daily reel, a free spin every day to win jokers. Fewer ads, and your jokers stay on a skipped level.
</en-CA>
<en-AU>
🎃 Halloween event until November 8: 30 horror movies told by their villain, and pumpkin avatars to win! New: the daily reel, a free spin every day to win jokers. Fewer ads, and your jokers stay on a skipped level.
</en-AU>
```

## Avant d'envoyer en examen

1. Relire les 30 pitchs : `lib/data/halloween_pitches_data.dart`.
2. Android : la version de test « PT test » (installée à côté de la vraie) a été vérifiée sur le téléphone pour la bobine, l'info-bulle et le conseil clavier ; l'event (30 pitchs) est à tester par Damien sur « PT test » (installé le 24/10 à 22:00).
3. Google Play : Production → Créer une version → importer le .aab → coller les nouveautés → envoyer en examen.
4. iPhone : le build arrive dans App Store Connect ; créer la version 1.0.10, y attacher le build, coller les nouveautés, soumettre.
