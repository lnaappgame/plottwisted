# Version 1.0.9 — la même sur iPhone et Android

- Android : 1.0.9 (code 15), bundle `build/app/outputs/bundle/release/plottwisted-1.0.9+15.aab` (copie dans Téléchargements).
- iPhone : 1.0.9, build Codemagic « iOS — Release App Store (vraies pubs) » lancé le 20/10 sur le commit 55bdd83.

## Contenu

- Partage dans le jeu (déjà dans l'Android 1.0.8, nouveau sur iPhone) : bouton « Partager » sur la révélation d'un niveau, la fin du Défi du jour, l'énigme de la semaine résolue et la fin d'un match multijoueur ; « Demander à un ami » sous le pitch ; « Inviter des amis » dans les Paramètres.
- Lectures Firestore allégées pour le multijoueur et le classement (déjà dans l'Android 1.0.8).
- Paramètres : les liens CGU et confidentialité ouvrent la page anglaise quand le jeu est en anglais.
- Tablette : toute l'interface est agrandie au lieu d'une colonne de téléphone au milieu de l'écran.
- Firebase App Check en mode surveillance (rien n'est bloqué).

## Notes de version (« Nouveautés »)

**Français (App Store et Google Play)**

> Nouveau : partage tes résultats et demande de l'aide à un ami sur une énigme, sans jamais dévoiler la réponse. Mise en page agrandie sur tablette, pages légales en anglais et améliorations de stabilité.

**Anglais (App Store et les 4 fiches anglaises de Google Play)**

> New: share your results and ask a friend for help on a puzzle, without ever giving away the answer. Bigger layout on tablets, English legal pages and stability improvements.

**Bloc prêt à coller dans Google Play**

```
<fr-FR>
Nouveau : partage tes résultats et demande de l'aide à un ami sur une énigme, sans jamais dévoiler la réponse. Mise en page agrandie sur tablette, pages légales en anglais et améliorations de stabilité.
</fr-FR>
<en-US>
New: share your results and ask a friend for help on a puzzle, without ever giving away the answer. Bigger layout on tablets, English legal pages and stability improvements.
</en-US>
<en-GB>
New: share your results and ask a friend for help on a puzzle, without ever giving away the answer. Bigger layout on tablets, English legal pages and stability improvements.
</en-GB>
<en-CA>
New: share your results and ask a friend for help on a puzzle, without ever giving away the answer. Bigger layout on tablets, English legal pages and stability improvements.
</en-CA>
<en-AU>
New: share your results and ask a friend for help on a puzzle, without ever giving away the answer. Bigger layout on tablets, English legal pages and stability improvements.
</en-AU>
```

## Avant d'envoyer en examen

1. Android : installer l'APK de production (vraies pubs) sur le téléphone, le lancer, vérifier qu'il ne plante pas, que le partage s'ouvre et que les liens légaux marchent. Ne jamais toucher aux pubs (déclarer d'abord le téléphone comme appareil de test dans AdMob).
2. iPhone : le build arrive dans App Store Connect (TestFlight) ; créer la version 1.0.9, y attacher le build, coller les nouveautés, et changer l'adresse anglaise de confidentialité (`https://lnaappgame.github.io/plottwisted/en/#privacy`) si App Store Connect le permet avec la nouvelle version.
