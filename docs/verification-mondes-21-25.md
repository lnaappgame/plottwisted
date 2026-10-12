# Vérification des nouveaux mondes 21 à 25

Les anciens mondes 24, 32, 38, 43 et 47 du tableur bundle 10 sont devenus les mondes 21 à 25, **intégrés tels quels** (commit 5c8bf66). Rien n'est encore corrigé : valide ou modifie chaque ligne, et j'applique.

| Nouveau | Ancien | Thème |
|---|---|---|
| 21 | 24 | Séries cultes / Cult TV Shows |
| 22 | 32 | Fantastique & Magie / Fantasy & Magic |
| 23 | 38 | Père de... / Father of... |
| 24 | 43 | Animation |
| 25 | 47 | Sport / Sports |

## Ce qui est bon (vérifié automatiquement)

- Les 50 niveaux ont un titre, une année, un pitch, un indice et un texte de révélation, **en français et en anglais**.
- Chaque pitch contient bien ses deux noms, `{p1}` et `{p2}`, dans les deux langues.
- Aucun nom de départ vide, dans aucune langue.
- Les grilles de réponse se construisent toutes (chiffres de *42*, ponctuation de *MONSTERS, INC.*).
- Un joueur qui avait fini les 20 mondes se voit bien proposer les mondes 21 et 22.
- 221 tests passent.

## 1. Films déjà présents dans le jeu

**Quasi identiques : à remplacer** (même film, même angle, mêmes noms ou presque)

| Niveau | Film | Déjà en jeu | Remplaçant proposé |
|---|---|---|---|
| 21-1 | Blue Bloods | 11-10 (même famille Reagan) | **Dr House** : Gregory House (Hugh Laurie) et Lisa Cuddy (Lisa Edelstein) |
| 21-7 | NCIS | 11-3 (même pitch, mêmes noms Gibbs / Pauley Perrette) | **Grey's Anatomy** : Meredith Grey (Ellen Pompeo) et Derek Shepherd (Patrick Dempsey) |
| 25-2 | Le Stratège | 20-4 (même film, même nom rouge « Seth ») | **Raging Bull** : Jake LaMotta (Robert De Niro, rouge « Travis Bickle ») et Joey LaMotta (Joe Pesci, rouge « Harry (Maman, j'ai raté l'avion) ») |

Je rédigerai les pitchs, indices et révélations FR/EN de ces remplaçants si tu valides les films.

**Même film, autre angle : à garder ?** Le jeu en contient déjà (Titanic, Gladiator, Jurassic Park…).

| Niveau | Film | Déjà en jeu |
|---|---|---|
| 22-1 | Le Magicien d'Oz | 19-2 (monde « Mère de... ») |
| 23-3 | Hunger Games | 7-6 (Jennifer Lawrence en « Mystique ») |
| 23-4 | Les Infiltrés | 14-7 (Matt Damon / Leonardo DiCaprio) |
| 23-10 | Star Wars 5 | 4-3 (la réplique « Non, je suis ton père ») |
| 24-5 | Le Roi Lion | 18-4 (la réplique de Mufasa) |

## 2. Erreurs de fond (à corriger)

| Niveau | Film | Problème | Correction proposée |
|---|---|---|---|
| 21-4 | Modern Family | Mitchell est le **fils** de Jay, pas son gendre | « …aux côtés de {p2}, son fils au tempérament sensible » (EN : « his sensitive son ») |
| 22-3 | Big Fish | L'indice dit que le poisson a avalé son alliance « avant qu'il ne rencontre sa future femme » : impossible pour une alliance | « Selon lui, le jour de la naissance de son fils, il a attrapé un poisson géant en se servant de son alliance comme appât. » |
| 22-6 | Hook | La révélation dit que le film est un **préquel** : c'est une **suite** (Peter Pan adulte) | « Ce film imagine une suite au conte : Peter Pan a grandi et oublié qui il était. » |
| 22-10 | Harry Potter 2 | Ginny n'est **pas pétrifiée** : elle est enlevée dans la Chambre | « …une créature qui pétrifie les élèves de son école, avant que {p2} ne disparaisse dans la Chambre des secrets. » |
| 23-1 | Animal House | Donald Sutherland joue un **professeur**, pas le doyen | « …multiplie les frasques, sous l'œil amusé de {p2}, un professeur désabusé. » |
| 23-4 | Les Infiltrés | La taupe n'est pas dans l'équipe du capitaine, mais dans la police | « …sans savoir qu'une taupe, {p2}, se cache dans la police. » |
| 24-3 | La Reine des neiges | L'indice dit qu'elle blesse sa sœur pendant la cérémonie : à la cérémonie, elle dévoile ses pouvoirs (la blessure date de l'enfance) | « Le jour de son couronnement, elle dévoile malgré elle ses pouvoirs et s'enfuit, plongeant le royaume dans un hiver éternel. » |
| 24-9 | Zootopie | L'indice parle de **13** mammifères disparus : il y en a **14** | « quatorze » / « fourteen » |
| 25-4 | Creed | L'indice dit qu'il demande à la veuve de son père de l'entraîner : c'est **Rocky** qu'il sollicite (la veuve, Mary Anne, s'y oppose) | « Sans expérience officielle, il demande à l'ancien rival et ami de son père de l'entraîner, malgré ses réticences. » |
| 25-6 | Le Plus Beau des combats | La révélation parle de « sport **universitaire** » : c'est un **lycée** | « sport scolaire américain » |

## 3. Fautes de texte en français

| Niveau | Film | Actuellement | Correction |
|---|---|---|---|
| 24-3 | La Reine des neiges | « …sa sœur bien décidée à la retrouver. **pour la libérer, délivrer,** » (fin de phrase cassée) | « …sa sœur, bien décidée à la retrouver. » |
| 24-1 | Toy Story | « …les mènera vers l'infini et **au dela** » (pas de point) | « …vers l'infini et au-delà. » |
| 24-5 | Le Roi Lion | « son oncle jaloux et **fraticide** » (pas de point) | « fratricide. » |
| 24-7 | Moi, moche et méchant | point final manquant | ajouter le point |
| 22-9 | Stardust | « une étoile tombée du ciel {p2}. » | « une étoile tombée du ciel, {p2}. » |
| 22-6 | Hook | « la fée **clochette** » | « la fée Clochette » |
| 25-5 | Rasta Rockett | « recalé aux **jeux olympiques** » | « Jeux olympiques » |
| 23-1 | Animal House | nom vert « **Prof** Jennings » | « Professeur Jennings » / « Professor Jennings » |
| 23-4 | Les Infiltrés | nom vert français « **Captain** Queenan » | « Capitaine Queenan » |
| 24-10 | Monstres et Cie | « Jacques **Sullivent** » | « Jacques Sullivan » (nom de la VF) |
| 24-5 | Le Roi Lion | « Simon Gruber (Une **J**ournée en **E**nfer) » | « Une journée en enfer » |

## 4. Noms restés en français dans la version anglaise

| Niveau | Film (US) | Actuellement | Correction |
|---|---|---|---|
| 22-6 | Hook | Capitaine Crochet | Captain Hook |
| 22-8 | Maleficent | Aurore | Aurora |
| 23-10 | The Empire Strikes Back | Dark Vador | Darth Vader |
| 24-5 | The Lion King | Léo Bloom | Leo Bloom |
| 24-5 | The Lion King | Simon Gruber (Une Journée en Enfer) | Simon Gruber (Die Hard with a Vengeance) |
| 24-8 | Kung Fu Panda | Maître Shifu | Master Shifu |

## 5. Points de jeu (à ton choix)

- **Même indice deux fois dans un monde :** « Père de Kiefer Sutherland » en 23-1 et en 23-3. Le joueur qui a fait l'un a la réponse de l'autre. Je propose de changer le film de 23-1 (*Animal House*), par exemple pour un autre père célèbre.
- **Même nom rouge deux fois dans un monde :** « Jason Bourne » (Matt Damon) en 25-3 et en 25-8. Pour 25-3 (*Invictus*), je propose « Will Hunting » à la place.
- **Chaînes orange → rouge incohérentes :** en 24-5 (*Le Roi Lion*), le nom orange renvoie à Alfred (Michael Caine), mais le rouge à Simon Gruber. Proposé : rouge « Alfred Pennyworth (Batman v Superman) ». Même chose en 25-10 (*42*) : orange « Alden Ehrenreich » (Han Solo), rouge « Rick Deckard ». Proposé : rouge « Han Solo ».
- **Le monde 21 (Séries cultes)** ne démarre qu'avec des noms verts et bleus, sans aucun piège rouge, orange ou violet. Il sera donc très facile, même en « Extrême ». À enrichir de quelques noms rouges ?
- **Liens « Voir la fiche » :** ils manquent pour *Hook* et *Rasta Rockett*. Le bouton est alors simplement masqué, comme pour 30 niveaux actuels.

## À faire dans ton tableur

Dans ton tableur, ces 5 mondes sont encore après la ligne « LIMITE DU JEU », sous leurs anciens numéros. Une future régénération depuis le tableur les effacerait, comme cela est déjà arrivé aux noms anglais du monde 17. Il faut donc les remonter avant la ligne « LIMITE » et les renuméroter 21 à 25, ou me demander de te refaire le fichier à jour.
