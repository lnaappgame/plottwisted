# Monde « Enfants stars » : trouver le film ET le nom de l'enfant star

Décision de structure (PT prime, 11/11/2026), en réponse à PT créateur. Rien n'est codé : à faire avec la mise à jour des nouveaux mondes.

## Ce qu'on retient

Un champ optionnel dans la donnée (piste C), et une seule grille de réponse (mécanisme de la piste A). Pas de deuxième étape (piste B écartée : il faudrait un nouvel écran).

```dart
Puzzle(
  title: 'LÉON',
  titleUs: 'THE PROFESSIONAL',
  extraAnswer: 'NATALIE PORTMAN',
  extraAnswerUs: 'NATALIE PORTMAN',
  ...
)
```

- `title` reste le titre du film seul : l'écran de résultat, le partage, les liens Allociné / IMDb, la recherche de doublons et les statistiques ne changent pas.
- La grille de lettres est construite sur « titre · nom » quand `extraAnswer` est rempli. Le « · » est une case de ponctuation, déjà pré-remplie par le jeu. Chaque mot se verrouille séparément, comme aujourd'hui.
- Si `extraAnswer` est vide, rien ne change : les 304 énigmes actuelles ne sont pas touchées.

## Code à écrire (une quinzaine de lignes)

1. `lib/models/puzzle.dart` : champs `extraAnswer` et `extraAnswerUs` (vides par défaut), et `answerFor(locale)` qui renvoie le titre, ou « titre · nom ».
2. `lib/services/game_state.dart` : utiliser `answerFor` à la place de `titleFor` pour la grille (ligne 698) et pour la comparaison au changement de langue (ligne 69).
3. `loadPuzzle` : ne pas compter comme « mot » un groupe fait seulement de ponctuation. Sinon le joker « Révéler un mot » peut tomber sur le « · » et être dépensé pour rien. Ce défaut existe déjà aujourd'hui sur « P.S. : I LOVE YOU », « FAST & FURIOUS » et « LAW & ORDER » : la correction le règle aussi.
4. `tool/regenerate_from_xlsx.dart` et le classeur : deux colonnes de plus, sinon le champ disparaît à la prochaine régénération.
5. Tests : grille avec `extraAnswer`, validation mot par mot, le joker ne vise jamais le séparateur, changement de langue.

## Règles pour le contenu

- Film + nom : 29 lettres et chiffres au plus (espaces et ponctuation non comptés), en français ET en anglais. C'est la plus longue réponse déjà en ligne (« QUATRE MARIAGES ET UN ENTERREMENT »), donc la seule longueur vérifiée sur petit téléphone.
- Un seul nom par niveau, prénom + nom, écrit comme dans le champ `actor` du personnage.
- Dans le pitch, le nom de l'enfant ne démarre jamais en bleu, et le champ de sa couleur de départ doit être rempli (rouge : `decoy` + `decoyFilm`). S'il est vide, le jeu affiche le nom de l'acteur à la place, donc la réponse.
- Le joker « Acteur » révèle le nom de l'enfant star dans le pitch. C'est accepté : il coûte un joker majeur et le film reste à trouver.
- Le nom du monde doit dire la règle (par exemple « Enfants stars : le film + l'enfant star »).

## Niveaux proposés qui dépassent 29 (en français)

| Niveau | Film + nom | Lettres |
|---|---|---|
| 2 | E.T. l'extra-terrestre + Drew Barrymore | 30 |
| 4 | Entretien avec un vampire + Kirsten Dunst | 34 |
| 6 | L'Homme qui murmurait à l'oreille des chevaux + Scarlett Johansson | 54 |

Les 7 autres passent en français (18 à 29). En anglais, à vérifier : « What's Eating Gilbert Grape » + Leonardo DiCaprio fait 39, et Léon ne passe qu'avec le titre américain « The Professional ».

## Décisions de Damien sur les trois niveaux trop longs (11/11, vers 20 h 50)

- Niveau 2 : on garde le film avec son titre court. Réponse = « E.T. » + Drew Barrymore, 15 lettres.
- Niveau 4 : Entretien avec un vampire + Kirsten Dunst, gardé tel quel (34 lettres en français, 35 en anglais). Exception voulue : au moment de coder, vérifier l'affichage de cette grille sur petit téléphone et ajuster si besoin.
- Niveau 6 : L'Homme qui murmurait à l'oreille des chevaux, à remplacer. PT créateur propose des remplaçants.

Damien garde les 6 mondes pour la mise à jour.

## Accord final sur les 5 mondes (11/11, vers 21 h 05)

Damien : d'accord sur les doublons (« oui pas de soucis ») ; les nouveaux mondes seront les mondes 31 à 35 ; « je valide Saoirse Ronan » (n° 6 = Reviens-moi).

Ordre : 31 Enfants stars, 32 Pitch express, 33 Le méchant raconte, 34 Couples de cinéma, 35 Tout frais. Noël en réserve.

Corrections demandées à PT créateur sur son bloc (notes/maj-nouveaux-mondes/mondes-maj.dart.txt) :
- Enfants stars n° 4 : remettre Entretien avec un vampire + Kirsten Dunst (seule exception au-dessus de 29 lettres).
- Enfants stars n° 8 : Gilbert Grape + Leonardo DiCaprio en français, The Piano + Anna Paquin côté US.
- Pitch express n° 6 : Sister Act. Tout frais n° 5 : Bullet Train.
- Tout frais n° 7 : Avatar : la voie de l'eau à la place de The Batman (Batman 1989 est dans Le méchant raconte).
- Tout frais : niveaux 4 et 9 échangés (Free Guy / Wonka). Couples de cinéma : niveaux 7 et 9 échangés (Hot Fuzz / Murder Mystery).

Intégration prévue par PT prime pour la 1.0.14 du vendredi 20/11 ; la 1.0.13 du 13/11 ne change pas.
