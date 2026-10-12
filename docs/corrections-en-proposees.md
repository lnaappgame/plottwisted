# Corrections proposées — version anglaise + 1 bug français (mondes 1 à 20)

Scan automatique des 200 niveaux dans les deux langues, puis relecture des 200 pitchs anglais. **Rien n'est modifié dans la base** : valide ou corrige chaque ligne, et j'applique.

## 1. Noms vides en anglais (monde 17) — filet de sécurité déjà en place

Ces 5 noms de départ n'ont pas de version anglaise : un joueur américain voyait « «» » dans le pitch. **Depuis le commit e0ea10a, un nom vide part en bleu (l'acteur)**, donc plus de trou. Mais le niveau devient plus facile : mieux vaut un vrai nom.

| Niveau | Film (US) | Nom vide | Proposition (à vérifier) |
|---|---|---|---|
| 17-4 | Shall We Dance? | p2, rouge (autre rôle de Tamiyo Kusakari) | aucune idée sûre : elle a très peu tourné. Garder le bleu ? |
| 17-6 | Instructions Not Included | p1, rouge (autre rôle d'Eugenio Derbez) | « Mr. V (CODA) » |
| 17-6 | Instructions Not Included | p2, rouge (autre rôle de Loreto Peralta) | enfant actrice, peu connue : garder le bleu ? |
| 17-10 | Crocodile Dundee | p1, orange (autre acteur du même rôle) | personne d'autre n'a joué Dundee : passer en rouge « Lightning Jack » ? (la couleur de départ est commune au FR) |
| 17-10 | Crocodile Dundee | p2, rouge (autre rôle de Linda Kozlowski) | « Rose Garner (Almost an Angel) » |

## 2. Bug dans la version française

| Niveau | Film | Problème | Proposé |
|---|---|---|---|
| **17-4** | **Le Dîner de cons** | le nom rouge de p2 est « François Pignon », c'est-à-dire **le vrai personnage** : le pitch donne la réponse en rouge | un autre rôle de Jacques Villeret : **« La Denrée »** (l'extraterrestre de *La Soupe aux choux*) |

## 3. Noms restés en français dans la version anglaise

Ce sont surtout les noms **verts** (le vrai personnage, affiché avec le joker Personnage et sur l'écran de révélation).

| Niveau | Film (US) | Actuellement | Proposé |
|---|---|---|---|
| 1-1 | Gladiator | Maximus **Décimus** Meridius | Maximus **Decimus** Meridius |
| 1-2 | The Matrix | Thomas A. Anderson **alias Néo** | Thomas A. Anderson**, aka Neo** |
| 1-4 | Fight Club | **Le Narrateur** | **The Narrator** |
| 1-8 | Independence Day | **Capitaine** Steven Hiller | **Captain** Steven Hiller |
| 2-10 | The Dark Knight | **Le Joker** | **The Joker** |
| 3-10 | The Terminator | **Le Terminator** / T-800 | **The Terminator** / T-800 |
| 4-1 | 300 | **Gérard** Butler (bleu) | **Gerard** Butler |
| 7-8 | The Chronicles of Narnia | **La Sorcière Blanche** | **The White Witch** |
| 9-4 | Rise of the Planet of the Apes | **César** | **Caesar** |
| 12-5 | Night at the Museum | **Théodore** Roosevelt | **Theodore** Roosevelt |
| 13-2 | Terminator 2 | **Le** T-800 | **The** T-800 |
| 13-10 | Rise of the Planet of the Apes | **César** | **Caesar** |
| 15-1 | Saving Private Ryan | **Capitaine** John Miller | **Captain** John Miller |
| 15-5 | Apocalypse Now | **Capitaine** Willard | **Captain** Willard |
| 18-3 | Independence Day | **Le Président** Whitmore | **President** Whitmore |
| 18-6 | The Dark Knight | **Le Joker** | **The Joker** |
| 18-7 | The Terminator | **Le Terminator** | **The Terminator** |
| 19-1 | Star Wars 8 | **Général** Leia | **General** Leia |
| 19-2 | The Wizard of Oz | **L'Épouvantail** | **The Scarecrow** |
| 19-3 | Private Benjamin | **Capitaine** Lewis | **Captain** Lewis |

*(4-1 : « Gérard Butler » est aussi écrit avec un accent en français, alors que l'acteur s'appelle Gerard Butler.)*

## 4. Points de texte anglais (facultatif)

| Niveau | Film | Remarque | Proposé |
|---|---|---|---|
| 4-6 | Taxi Driver | le nom orange anglais est « José Garcia », un acteur français inconnu du public américain | un nom parlant aux Américains, ou garder le nom FR seulement |
| 9-2 | King Kong | … where a giant creature awaits**, and** falls for her. | … where a giant creature awaits them**, one that** falls for her. |
