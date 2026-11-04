# Version 1.0.12 : nouvelle icône et accueil jaune

- Android : 1.0.12 (code 18), `plottwisted-1.0.12+18.aab` dans Téléchargements (vraies pubs).
- iPhone : 1.0.12, build Codemagic « iOS — Release App Store (vraies pubs) » sur la branche main.
- Mise à jour du vendredi 06/11 (test « MAJ + week-end », voir `notes/stats/maj-vendredi.csv`).

## Contenu

- **Nouvelle icône (L14)** : une loupe sur une pellicule, point d'interrogation rouge, fond jaune. Sources SVG dans `tool/icon/`, rendu par `tool/icon/render.ps1`, puis `dart run flutter_launcher_icons`. Sur Android, icône adaptative (fond jaune séparé) et version monochrome pour les icônes à thème.
- **Écran d'accueil jaune « Affiche »** : réglage `posterHome` (Paramètres → « 🎞️ Accueil jaune »). Activé pour une nouvelle installation, désactivé pour une sauvegarde existante : les joueurs actuels gardent l'accueil sombre tant qu'ils ne l'activent pas.
- Rien d'autre : pas de changement de contenu. Les doublons Grey's Anatomy / Dr House (mondes 21 et 26) et La Momie (9-8 et 27-3) attendent toujours une décision.

## Fiches (à faire en même temps)

- App Store : nom « Plot Twisted: Movie Quiz » / « Plot Twisted : Quiz Cinéma », sous-titre EN « Movie trivia where names lie », FR « Devine le film aux noms piégés ». Captures 1 à 3 : `captures-stores/vitrine-G/app-store-1290x2796-{en,fr}` (et 1206x2622).
- Google Play : captures 1 à 3 `captures-stores/vitrine-G/play-store-1080x2160-{en,fr}`, icône 512 `captures-stores/vitrine-G/play-icon-512.png`.

## Notes de version (« Nouveautés »)

Moins de 500 caractères par langue (limite de Google Play).

**Français (Google Play)**

```
🎬 Nouvelle icône : une loupe sur la pellicule, pour repérer le jeu d'un coup d'œil.
🟡 Nouvel écran d'accueil jaune, façon affiche de cinéma. Active-le dans Paramètres (« Accueil jaune »).
```

**Français (App Store, sans émoji : App Store Connect les refuse)**

```
Nouvelle icône : une loupe sur la pellicule, pour repérer le jeu d'un coup d'œil.
Nouvel écran d'accueil jaune, façon affiche de cinéma. Active-le dans Paramètres (« Accueil jaune »).
```

**Anglais (Google Play)**

```
🎬 New icon: a magnifying glass over a film strip, easy to spot on your home screen.
🟡 New yellow home screen, movie-poster style. Turn it on in Settings ("Yellow home screen").
```

**Anglais (App Store, sans émoji)**

```
New icon: a magnifying glass over a film strip, easy to spot on your home screen.
New yellow home screen, movie-poster style. Turn it on in Settings ("Yellow home screen").
```

**Bloc prêt à coller dans Google Play**

```
<fr-FR>
🎬 Nouvelle icône : une loupe sur la pellicule, pour repérer le jeu d'un coup d'œil.
🟡 Nouvel écran d'accueil jaune, façon affiche de cinéma. Active-le dans Paramètres (« Accueil jaune »).
</fr-FR>
<en-US>
🎬 New icon: a magnifying glass over a film strip, easy to spot on your home screen.
🟡 New yellow home screen, movie-poster style. Turn it on in Settings ("Yellow home screen").
</en-US>
<en-GB>
🎬 New icon: a magnifying glass over a film strip, easy to spot on your home screen.
🟡 New yellow home screen, movie-poster style. Turn it on in Settings ("Yellow home screen").
</en-GB>
<en-CA>
🎬 New icon: a magnifying glass over a film strip, easy to spot on your home screen.
🟡 New yellow home screen, movie-poster style. Turn it on in Settings ("Yellow home screen").
</en-CA>
<en-AU>
🎬 New icon: a magnifying glass over a film strip, easy to spot on your home screen.
🟡 New yellow home screen, movie-poster style. Turn it on in Settings ("Yellow home screen").
</en-AU>
```

## Avant d'envoyer en examen

1. **Google Play** : Production → Créer une version → importer le .aab → coller le bloc → envoyer en examen. La publication gérée est activée : cliquer « Publier » le vendredi soir.
2. **iPhone** : le build arrive dans App Store Connect. Créer la version 1.0.12, attacher le build, coller les nouveautés FR et EN sans émoji, changer le nom et le sous-titre, remplacer les captures 1 à 3. Soumettre en **publication manuelle**, puis « Publier » le vendredi soir.
3. Les contrats Apple sont tous acceptés (04/11).
