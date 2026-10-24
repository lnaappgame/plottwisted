# Version 1.0.10 — l'event Halloween

- Android : 1.0.10 (code 16), `plottwisted-1.0.10+16.aab` dans Téléchargements (vraies pubs).
- iPhone : 1.0.10, build Codemagic « iOS — Release App Store (vraies pubs) » sur la branche main.

## Contenu

- **Event Halloween** (jusqu'au 8 novembre) : 30 films d'horreur et d'Halloween racontés du point de vue de leur méchant, à trouver comme dans le jeu principal (sans noms colorés ; jokers Révéler, Éliminer et Révéler un mot). 10 pitchs le premier jour, puis 2 par jour. Avatars à gagner : Tête de citrouille et Citrouille en feu. La version « questions » est gardée sur la branche `halloween-enigmes`.
- **La bobine du jour** : un tour gratuit par jour pour gagner des jokers, et un relancement avec une pub.
- Plus de pub forcée quand un niveau a pris plus de 60 secondes.
- « Passer, j'y reviendrai » garde les jokers déjà joués sur le niveau.
- Toucher un nom coloré rappelle ce que veut dire sa couleur.
- Le conseil « tuiles ou clavier » reste affiché au moins 3 secondes.

## Notes de version (« Nouveautés »)

Moins de 500 caractères par langue (limite de Google Play) : 385 en français, 332 en anglais.

**Français (App Store et Google Play)**

```
🎃 Event Halloween jusqu'au 8 novembre : 30 films d'horreur racontés du point de vue de leur méchant. Retrouve-les tous et gagne les avatars Tête de citrouille et Citrouille en feu !
🎞️ Nouveau : la bobine du jour, un tour gratuit chaque jour pour gagner des jokers.
✨ Moins de pubs, tes jokers restent sur un niveau passé, et toucher un nom coloré rappelle ce que veut dire sa couleur.
```

**Anglais (App Store et les 4 fiches anglaises de Google Play)**

```
🎃 Halloween event until November 8: 30 horror movies told from their villain's point of view. Find them all to win the Pumpkin head and Flaming pumpkin avatars!
🎞️ New: the daily reel, a free spin every day to win jokers.
✨ Fewer ads, your jokers stay on a skipped level, and tapping a colored name reminds you what its color means.
```

**Bloc prêt à coller dans Google Play**

```
<fr-FR>
🎃 Event Halloween jusqu'au 8 novembre : 30 films d'horreur racontés du point de vue de leur méchant. Retrouve-les tous et gagne les avatars Tête de citrouille et Citrouille en feu !
🎞️ Nouveau : la bobine du jour, un tour gratuit chaque jour pour gagner des jokers.
✨ Moins de pubs, tes jokers restent sur un niveau passé, et toucher un nom coloré rappelle ce que veut dire sa couleur.
</fr-FR>
<en-US>
🎃 Halloween event until November 8: 30 horror movies told from their villain's point of view. Find them all to win the Pumpkin head and Flaming pumpkin avatars!
🎞️ New: the daily reel, a free spin every day to win jokers.
✨ Fewer ads, your jokers stay on a skipped level, and tapping a colored name reminds you what its color means.
</en-US>
<en-GB>
🎃 Halloween event until November 8: 30 horror movies told from their villain's point of view. Find them all to win the Pumpkin head and Flaming pumpkin avatars!
🎞️ New: the daily reel, a free spin every day to win jokers.
✨ Fewer ads, your jokers stay on a skipped level, and tapping a colored name reminds you what its color means.
</en-GB>
<en-CA>
🎃 Halloween event until November 8: 30 horror movies told from their villain's point of view. Find them all to win the Pumpkin head and Flaming pumpkin avatars!
🎞️ New: the daily reel, a free spin every day to win jokers.
✨ Fewer ads, your jokers stay on a skipped level, and tapping a colored name reminds you what its color means.
</en-CA>
<en-AU>
🎃 Halloween event until November 8: 30 horror movies told from their villain's point of view. Find them all to win the Pumpkin head and Flaming pumpkin avatars!
🎞️ New: the daily reel, a free spin every day to win jokers.
✨ Fewer ads, your jokers stay on a skipped level, and tapping a colored name reminds you what its color means.
</en-AU>
```

## Avant d'envoyer en examen

1. Google Play : Production → Créer une version → importer le .aab → coller le bloc ci-dessus → envoyer en examen. Si la 1.0.9 (code 15) est encore en examen, la 1.0.10 la remplace (elle contient déjà ses changements).
2. iPhone : le build arrive dans App Store Connect ; créer la version 1.0.10, y attacher le build, coller les nouveautés FR et EN, soumettre.
