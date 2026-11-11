# Mise à jour « nouveaux mondes » : doublons avec les mondes 31 à 50 de la base

Contrôle fait par PT prime le 11/11/2026 (titres FR et US), entre les 5 mondes proposés et le classeur
`exports/Base-de-donnees-PlotTwisted-2026-10-31.xlsx`.

## Ce qu'il faut savoir

- Le jeu en ligne contient 30 mondes. Le classeur en contient 50 : les mondes 31 à 50 (200 niveaux) sont écrits en français et en anglais, mais placés après la ligne LIMITE, donc pas encore en jeu.
- `lib/data/puzzles_data.dart` ne montre que les 30 mondes en jeu : un contrôle de doublon fait sur ce seul fichier rate les 200 autres niveaux.
- Liste complète pour les contrôles : `notes/base-titres-tous-mondes-2026-10-31.tsv`.
- Détail des mondes 32 et 37 : `notes/base-mondes-32-et-37-complets.md`.

## Les 20 mondes en attente

31 Comédie musicale · 32 Blockbusters récents · 33 Horreur · 34 Tiré d'un livre · 35 Oscar du meilleur acteur ·
36 Qui a sa série · 37 Graine de star · 38 Thrillers français · 39 Petit budget, gros succès · 40 Musique d'anthologie ·
41 Espionnage · 42 Répliques cultes 3 · 43 Cinéma français culte · 44 Les suites (bien notées) · 45 Oscar de la meilleure actrice ·
46 Teen série · 47 Guerre & Histoire 2 · 48 Oscarisés · 49 Biopics & Musique · 50 Biopic 2

## Doublons trouvés (18 films sur 50, plus 2 avec le jeu en ligne)

| Nouveau monde | Film | Déjà dans |
|---|---|---|
| Enfants stars | Léon | monde 37, monde 43 |
| Enfants stars | E.T. l'extra-terrestre | monde 37 |
| Enfants stars | La Famille Addams | monde 37 |
| Enfants stars | Entretien avec un vampire | monde 37 |
| Enfants stars | L'Empire du soleil | monde 37 |
| Pitch express | Forrest Gump | mondes 42, 48 |
| Pitch express | Le Parrain | mondes 40, 42, 48 |
| Pitch express | Le Grand Bleu | monde 43 |
| Pitch express | Mamma Mia ! | monde 49 |
| Pitch express | Amélie Poulain | EN JEU (titre US d'Intouchables, monde 17), monde 43 |
| Pitch express | La La Land | monde 31 |
| Le méchant raconte | Misery | monde 45 |
| Le méchant raconte | Dune | mondes 32, 34 |
| Le méchant raconte | Les Gardiens de la Galaxie | monde 32 |
| Tout frais | Barbie | monde 32 |
| Tout frais | Oppenheimer | mondes 32, 48 |
| Tout frais | Top Gun : Maverick | monde 32 |
| Tout frais | Spider-Man : No Way Home | EN JEU (monde 7, titre FR « Spider-Man 3 ») |

Couples de cinéma : aucun doublon.

Remplaçants proposés par PT créateur et déjà pris : Le Sixième Sens (37), La Leçon de piano (37), Rain Man (35), Grease (49), Elvis (49).
Remplaçants libres : Reviens-moi, Virgin Suicides, Bullet Train.

## Proposition de PT prime (à confirmer par Damien)

1. Les nouveaux mondes passent devant.
2. « Enfants stars » remplace le monde 37 « Graine de star » et « Tout frais » remplace le monde 32 « Blockbusters récents » : même idée. Ces deux anciens mondes sont mis de côté (pas effacés), leurs films non repris vont en réserve :
   monde 37 : I Am Sam, Super 8, Freaky Friday, La Leçon de piano, Le Sixième Sens ;
   monde 32 : Avatar : la voie de l'eau, Once Upon a Time... in Hollywood, Mission Impossible - Dead Reckoning, À couteaux tirés, Tenet.
3. Les autres films en commun sont remplacés plus tard dans les anciens mondes (31, 34, 43, 45, 48, 49), au moment de leur sortie.
4. Seuls les deux doublons avec le jeu en ligne se corrigent maintenant : Amélie Poulain (remplaçant à trouver) et Spider-Man : No Way Home (→ Bullet Train).
