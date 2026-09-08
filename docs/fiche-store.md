# Fiche store — Plot Twist(ed)

Brouillon prêt à copier-coller dans Google Play Console (et à adapter pour l'App Store si besoin). Les limites de caractères indiquées sont celles de Google Play.

## Nom de l'application (30 caractères max)

**Plot Twist(ed)**

## Description courte (80 caractères max)

Affichée sous le titre dans les résultats de recherche.

> Devine le film derrière le pitch. Puzzle ciné quotidien, seul ou en duel.

(74 caractères)

Variante plus orientée mots-clés :

> Quiz cinéma : devine le film à partir du pitch. Défis quotidiens, duels.

(74 caractères)

## Description complète (4000 caractères max)

```
🎬 RETROUVE LE FILM DERRIÈRE LE PITCH

Plot Twist(ed) te donne le résumé d'un film, brouillé par des noms
d'acteurs et de personnages piégeux — à toi de reconstituer le titre
lettre par lettre.

Simple à comprendre, difficile à lâcher : chaque pitch cache un piège.
Un nom en bleu ? C'est l'acteur. En vert ? Le vrai personnage. En rouge
ou en orange ? Attention, ce n'est pas si simple...

🧩 DES MODES POUR CHAQUE ENVIE
• Mode Histoire — des dizaines de films organisés par thème, du plus
  facile au plus retors
• Défi du jour — une énigme éclair chronométrée, un seul essai
• L'énigme de la semaine — un défi commun à tous les joueurs, avec
  classement
• Multijoueur — affronte un autre joueur sur le même pitch et gagne la
  course au titre

🃏 DES JOKERS POUR T'AIDER
Révèle une lettre, élimine des intrus, découvre l'acteur ou le
personnage, ou récupère un indice sur le film — à utiliser au bon
moment.

🔥 REVIENS CHAQUE JOUR
Construis ta série de jours joués et débloque des récompenses aux
paliers (indices, jokers).

🏆 GRIMPE LE CLASSEMENT
En multijoueur, chaque victoire fait progresser ton rang, du stagiaire
sur le tournage jusqu'au fauteuil de réalisateur.

Aucune connaissance encyclopédique requise : Plot Twist(ed) se joue à
l'instinct, à la déduction, et un peu de culture ciné. Blockbusters,
classiques, films cultes... tous les univers y passent.

Télécharge Plot Twist(ed) et retrouve le plaisir de dire "Ah mais oui,
bien sûr !"
```

(1076 caractères — large marge sous la limite de 4000, volontairement concis pour rester lisible)

## Mots-clés à tisser dans le texte (Google Play n'a pas de champ dédié, contrairement à l'App Store)

Déjà présents ci-dessus : *quiz cinéma, devine le film, pitch, acteurs, personnages, défi quotidien, multijoueur, classement*.

À garder sous le coude si tu veux varier une future mise à jour de la fiche : *jeu de lettres, blockbusters, films cultes, culture cinéma, énigme, casse-tête ciné*.

## Classification d'âge

Le questionnaire IARC (dans Play Console → Contenu de l'app → Classification du contenu) doit être rempli par toi directement — je ne peux pas le soumettre à ta place. Mais voici comment répondre honnêtement vu ce que fait l'app aujourd'hui :

- **Violence, contenu sexuel, langage grossier, thèmes contrôlés (drogue/alcool/jeu d'argent réel)** : aucun — répondre "Non" partout. Les pitchs de films peuvent mentionner des thèmes adultes de façon indirecte (ex. un film de guerre), mais l'app ne les *représente* pas.
- **Achats intégrés** : Oui (jokers, cosmétiques) — à cocher.
- **Publicités** : Oui (bannières/récompensées via AdMob) — à cocher, avec la case "publicités basées sur les centres d'intérêt" si tu actives le ciblage (dépend de ton consentement UMP, déjà en place dans l'app).
- **Interaction entre utilisateurs** : le mode multijoueur compare des scores/temps mais n'a pas de chat ni d'échange de contenu libre entre joueurs — généralement classé "non" ou "limité" selon la formulation exacte du questionnaire cette année-là.
- **Partage de localisation** : non, l'app ne demande pas la position.

Avec ce profil, tu devrais atterrir sur l'équivalent de **PEGI 3 / ESRB Everyone** — adapté à tous les âges, avec les mentions standard "achats intégrés" et "publicités".

**Confirmé : classification "Tout public" retenue.**

## Icône

Déjà prête : `assets/icon/icon.png`, 1024×1024, déjà déclinée pour Android et iOS via `flutter_launcher_icons`. Rien à refaire.

## Captures d'écran

5 captures prises en direct sur l'appareil de test (accueil, intro de monde, gameplay, défi du jour, multijoueur) — envoyées séparément. La capture gameplay montre volontairement un pitch avec deux noms en rouge (niveau 0-4, *Seven*) pour illustrer ce mécanisme dès la fiche store. Prends-en 2-3 de plus si tu veux varier (la boutique, un mode daltonien) avant l'envoi définitif à la Play Console.

## Vidéo de présentation

Premier jet fait (25s, enregistré en direct via `adb shell screenrecord`) : pitch du niveau 0-4 avec les deux noms rouges bien visibles, réponse assemblée, validation, puis écran de révélation. Envoyée séparément — à revoir/retourner si tu veux une version plus longue avec l'accueil, d'autres modes (défi, multijoueur), ou un montage plus travaillé.
