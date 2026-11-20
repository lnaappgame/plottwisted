# PT v2bis : test web auprès des testeurs (état au 18/11/2026, ~23 h 30)

Décision de Damien (18/11) : « on va le faire tester par ma base test et on va voir » ; test **web d'abord** (accord donné : « vas-y »), avec **50 à 60 films** pour que le test ait de la durée de vie. Damien n'est « toujours pas fan » : ce sont les avis des testeurs qui trancheront.

## Fait

- Concept : `concept-v2bis.md`. Chiffres de départ : `point-zero.md`. Étude : `etude-marche.md`.
- Maquette jouable (15 films) : `proposition-v6.html`, publiée sur https://claude.ai/artifact/XGpnXVYMaffM1YwCfD1m87 (source : scratchpad `refonte-plot-twisted.html`, assemblé depuis `refonte-pt2-v4.html` + `v5-page.txt` + `v5-js.txt`).
- **Contenu du test : `contenu-test-v2bis.json`** : 60 films = 6 salles de 10 (mondes 1, 2, 3, 12, 13, 24), deux séances de 5 par salle (la première = les plus accessibles). Par film : titre affiché, autres titres acceptés, 3 faux titres (le premier = film piège), anecdote + étiquette du bandeau, 10 vrai ou faux, 38 questions bonus « d'où vient le nom en rouge », film d'origine des noms rouges. Vérifié par script : 60 films, tous présents dans la base, 0 anomalie.

## Reste à faire

1. **Export des données** : un script Dart (dans `tool/`, sur le modèle de celui qui produit `docs/jouer/enigmes.json`) qui fusionne la base (pitch, noms, couleurs initiales, indice, liens, valeur « violet ») et `contenu-test-v2bis.json` en un `films.json`.
2. **La page de test** : partir de `proposition-v6.html` et
   - charger `films.json` au lieu des 15 films en dur ; 6 salles ouvertes (2 au départ, les autres en jouant) ;
   - gérer la 5e couleur, violet (un proche de l'acteur) : Aquaman l'utilise ;
   - séance du jour = 5 films tirés des 60 selon la date, les mêmes pour tous (limite connue : un film déjà trouvé en salle peut y revenir) ;
   - garder la partie dans le navigateur (localStorage), jour réel au lieu du bouton « Passer au lendemain » ;
   - retirer les encarts de maquette (ambiances au choix, notes), garder « pub ici » en simple mention ;
   - une question d'avis à la fin de la première séance et dans le menu (note sur 5 + texte libre) ;
   - compteurs anonymes : séance commencée, séance finie, retour un autre jour (Firestore du projet PT, règles en création seule comme `retours_testeurs`, ou à défaut un simple formulaire) ; pas de donnée personnelle, mention dans la page.
3. **Mise en ligne** : `docs/v2/` du dépôt cine-devinette (GitHub Pages → `https://lnaappgame.github.io/plottwisted/v2/`), `noindex`, non liée depuis le site. Commit + push de cine-devinette.
4. **Annonce** dans le groupe Facebook des testeurs (accord de Damien à redemander pour ce post précis, avec une image) et lien dans les discussions Messenger.
5. **Lecture des retours** après 3 et 7 jours ; puis décision : appli Flutter + test fermé store, ou arrêt.

## À relire par Damien

- Les 60 anecdotes et les faux titres (`contenu-test-v2bis.json`).
- Coquilles vues dans la base : Pacific Rim « Arthur Pandaragon » (Pendragon) ; Limitless « Eddie Mora » (Morra) ; Star Wars « quarante ans d'écart » (une trentaine) ; Terminator 2 « deux Oscars » (quatre).
- Noms piégés trop longs ou qui contiennent le titre du film d'origine (« la méchante dans Divergente », « Le scientifique dans Event Horizon », « Celui qui se fait tuer bêtement dans Zombieland »…).

## 20/11 : grille du jour

Deuxième format ajouté à la page de test (`docs/v2/index.html`, seul fichier modifié ; `films.json` inchangé). **Ni commit ni push** : à vérifier à l'œil par PT prime avant mise en ligne.

### Ce que voit le joueur

- **Accueil** : une deuxième carte « La grille du jour » sous la séance du jour, avec son état : à jouer, en cours (films trouvés et coups), terminée en N coups (« Revoir mon bilan »). Rien n'a été retiré.
- **Écran de la grille** : 5 lignes. Chaque ligne = « Film n », le pitch piégé (noms en couleur, en lecture seule : pas de joker ici) et le titre en cases. Lettres cachées ; espaces, chiffres et ponctuation visibles ; un bloc par mot, les mots ne se coupent pas. Les accents sont ignorés (E dévoile É et È, affichés avec leur accent).
- **Clavier A-Z** collé en bas de l'écran (7 colonnes, touches de 42 px). Une lettre se dévoile dans les 5 titres à la fois. Une lettre jouée est désactivée : verte si elle est dans au moins un titre, barrée et estompée sinon. Sur ordinateur, les touches du clavier physique jouent aussi.
- **Proposer un titre** : toucher une ligne ouvre le champ de saisie et le bouton « Valider » (le clavier A-Z s'efface pendant ce temps pour laisser la place au clavier du téléphone ; « Revenir aux lettres » ou un nouveau toucher referme). Même comparaison que la séance (`matches()` : fautes de frappe tolérées, titres acceptés compris).
- **Fin** : bilan avec les coups, le temps, l'appréciation, les 5 films (et comment chacun a été trouvé) et « Copier mon résultat », par exemple : `Plot Twisted, grille du jour n° 12 : 5 films en 9 coups, 2 min 10 s` (aucun titre dedans).
- Une grille finie ne se rejoue pas le même jour : on revoit son bilan. La partie en cours est gardée (reprise après fermeture, coups, lettres et temps compris).

### Règles

| Geste | Coût |
|---|---|
| Une lettre (présente ou non) | 1 coup |
| Bon titre proposé | 0 coup, la ligne se dévoile |
| Mauvais titre proposé | 2 coups (toast + message sous le champ) |
| « Révéler ce film » (lien discret dans la ligne ouverte) | 5 coups |
| Ligne dont toutes les lettres sont dévoilées | comptée comme trouvée |

Appréciation selon les coups : **0 à 6** « Chef-d'œuvre », **7 à 12** « Grand film », **13 à 18** « Bonne séance », **19 et plus** « Séance de rattrapage ». Repère : sur les 12 grilles de la boucle, finir uniquement aux lettres coûte 16 à 20 coups sans aucune lettre absente (donc plutôt 20 à 26 en vrai) ; reconnaître 3 films sur 5 au pitch et s'aider de quelques lettres en coûte 5 ou 6.

Chronomètre : temps de jeu actif seulement (écran de la grille affiché, onglet visible). Il s'arrête quand l'onglet est caché ou qu'on quitte la grille.

La grille est indépendante du reste : elle ne donne ni étoiles ni jokers, ne touche pas à la cinémathèque ni à la série.

### Tirage

Même ordre fixe des 60 films que la séance du jour (mélange `mulberry(20261119)`). La séance prend le bloc de 5 du jour ; la grille prend le bloc situé **une demi-boucle plus loin** (30 films). Donc : les mêmes 5 films pour tous, jamais ceux de la séance du même jour, 12 jours sans redite, et un film passe d'un format à l'autre à 6 jours d'écart (la grille du jour J reprend les 5 films de la séance de J-6). Numéro de la grille = numéro du jour du test (n° 1 = 19/11). Exemple, 20/11 (n° 2) : Aquaman, Toy Story, Matrix, SuperGrave, Le Roi Lion.

### Historique des retours (rien n'est envoyé)

Dans la sauvegarde locale (même clé `pt2-test-v1`), deux champs nouveaux :

- `grille` : la grille du jour en cours ou finie (`n`, `films`, `letters`, `st` par ligne : 1 titre, 2 lettres, 3 révélé, `coups`, `ms`, `done`).
- `hist` : par numéro de jour du test, `{s, g, p, a, o, gc}` : séance du jour (`s`) et grille (`g`) à 1 = commencée, 2 = finie ; `p` = le premier des deux formats ouvert ce jour-là (`s` ou `g`) ; `a` = une autre séance commencée ; `o` = nombre d'autres séances finies (salles, première séance, bonus) ; `gc` = coups de la grille finie. Un jour présent dans `hist` = une visite.

L'avis copié par le testeur se termine par deux lignes, par exemple :

```
Jours : J2 séance finie + grille finie en 9 coups (grille d’abord) ; J4 visite seule ; J7 séance commencée + grille commencée (séance d’abord)
Retours : 3 jours différents sur 6 (du J2 au J7)
```

À savoir pour lire ces lignes :

- « sur 6 » = nombre de jours entre la première visite connue et le jour de l'avis.
- « d'abord » ne compte que les deux entrées de l'accueil (séance du jour, grille du jour). La toute première séance, imposée au premier lancement, apparaît comme « séance en salle ».
- Sauvegardes d'avant le 20/11 : elles continuent de marcher ; on n'y connaît que le dernier jour de visite, reporté dans l'historique (avec « séance finie » si elle l'était). Les jours plus anciens restent dans le compteur « N jours de jeu » de la ligne d'avant.
- « Recommencer à zéro » efface la partie (grille du jour comprise) mais **garde l'historique** des jours : c'est lui qui mesure les retours.
- Biais possible : la séance du jour est affichée au-dessus de la grille, elle a donc plus de chances d'être ouverte en premier.

### Limites connues

- Aucun essai dans un navigateur n'a été fait par l'auteur du code (consigne) : la logique a été rejouée hors navigateur (script, DOM simulé), la mise en page reste à vérifier à l'œil à 360 px.
- Le clavier collé en bas occupe environ 230 px : sur un petit téléphone on voit une ligne et demie à la fois, il faut faire défiler les pitchs.
- Les 5 films de la grille sont les 5 d'une séance du jour passée ou à venir (6 jours d'écart) : avec 60 films, un joueur assidu les aura déjà croisés.
- Un titre juste tapé dans la mauvaise ligne coûte 2 coups, comme n'importe quelle erreur.
