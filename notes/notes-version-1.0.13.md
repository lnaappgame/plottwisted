# Version 1.0.13 : 35 mondes, dont « Enfants stars » (film + nom)

État au 12/11/2026, 0 h 45 (PT prime). Rien n'est commité, rien n'est construit : en attente du « go » de Damien.

- Android : 1.0.13 (code 19).
- iPhone : 1.0.13, build Codemagic « iOS — Release App Store (vraies pubs) » sur la branche main.

## Contenu

- **5 nouveaux mondes (31 à 35)** : Enfants stars, Pitch express, Le méchant raconte, Couples de cinéma, Tout frais. Le jeu passe à 35 mondes et 354 énigmes.
- **Monde 31 « Enfants stars » : il faut trouver le film ET le nom de l'enfant star.** La grille affiche le film, puis « + l'enfant star », puis le nom. Chaque mot se valide séparément, comme avant.
- **Joker « Révéler un mot »** : il ne se dépense plus sur un signe isolé (« : », « & »). Le défaut existait sur « P.S. : I LOVE YOU », « FAST & FURIOUS » et « LAW & ORDER ».
- **Déjà prévu dans la 1.0.13** (voir `preparation-1.0.13.md`) : pubs chargées à la demande, filtre du pseudo, conservation de 24 mois, consentement Analytics par finalité.

## Tests

308 tests verts, analyse sans erreur. Nouveaux fichiers : `test/extra_answer_test.dart`, `test/extra_answer_screen_test.dart`, plus 2 tests dans `test/new_worlds_test.dart`.
Vérifié en test : les 10 niveaux du monde 31 sur un écran de 320 x 568, en français et en anglais, dont la plus longue grille du jeu (Entretien avec un vampire + Kirsten Dunst, 34 lettres), jouée jusqu'à la révélation.

## Reste à faire

- [ ] Test sur le téléphone de test (monde 31, puis lancement de la version release avec journaux).
- [ ] « Go » de Damien, puis commit et push.
- [ ] AAB Android et build iPhone.
- [ ] Notes de version dans les deux consoles ; Damien clique « Envoyer pour examen » jeudi 12/11.
- [ ] Pages légales §2.4, §3 et §7 à publier avec la version.
- [ ] Classeur de la base : y reporter les mondes 31 à 35 (et mettre de côté les anciens mondes 32 et 37). D'ici là, ne pas relancer `tool/regenerate_from_xlsx.dart`.

## Notes de version (« Nouveautés »)

Sans emoji (App Store Connect les refuse). Moins de 500 caractères par langue.

**Français**

```
5 nouveaux mondes, 35 au total !
- Enfants stars : trouve le film ET le nom de l'enfant star.
- Pitch express : le film en 10 mots maximum.
- Le méchant raconte : c'est le méchant qui te résume le film.
- Couples de cinéma : deux acteurs, un autre film.
- Tout frais : les films sortis depuis 2020.
Et aussi : des pubs qui se chargent seulement quand il le faut, et un joker « Révéler un mot » plus juste.
```

**English**

```
5 new worlds, 35 in total!
- Child Stars: find the movie AND the child star's name.
- 10-Word Pitches: the movie in 10 words or less.
- The Villain's Version: the villain tells you the story.
- Screen Couples: two actors, another movie.
- Brand New: movies released since 2020.
Also: ads now load only when needed, and a fairer "Reveal a word" joker.
```
