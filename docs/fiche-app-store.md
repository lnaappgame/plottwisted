# Fiche App Store — Plot Twist(ed)

À copier-coller dans App Store Connect → Plot Twist(ed) → version iOS 1.0 (onglet « Distribution »). Les limites de caractères sont celles d'Apple. Ajoute la langue **Anglais (États-Unis)** en plus du français (menu de langue en haut à droite de la fiche).

## Textes — Français

**Nom (30)** : `Plot Twist(ed)`

**Sous-titre (30)** : `Devine le film du pitch` (23)

**Texte promotionnel (170)** — modifiable à tout moment sans nouvelle version :

```
Des pitchs de films piégés, des noms trompeurs, un titre à retrouver lettre par lettre. Sauras-tu déjouer le plot twist ?
```

**Mots-clés (100, séparés par des virgules, sans espace)** — inutile d'y remettre « film » ou « pitch », déjà dans le nom et le sous-titre :

```
quiz,cinéma,devinette,acteur,énigme,culture,blockbuster,trivia,ciné,mots,lettres,casse-tête
```

**Description (4000)** — sans emojis : App Store Connect les refuse (« caractères non autorisés ») :

```
RETROUVE LE FILM DERRIÈRE LE PITCH

Plot Twist(ed) te donne le résumé d'un film... mais les noms des personnages sont piégés : un acteur à la place du rôle, un autre personnage, un nom trompeur. À toi de reconstituer le titre, lettre par lettre.

Simple à comprendre, difficile à lâcher : chaque couleur de nom cache une règle. En bleu ? C'est l'acteur. En vert ? Le vrai personnage. En rouge, orange ou violet ? Méfie-toi...

QUATRE FAÇONS DE JOUER
• Les mondes — des centaines de films classés par thème (blockbusters, classiques, films cultes...), du niveau facile à l'extrême
• Le Défi du jour — un thème, 7 indices, 7 acteurs : associe chaque indice au bon nom, le plus vite possible
• L'énigme de la semaine — la même énigme pour tous les joueurs, une nouvelle lettre dévoilée régulièrement, et un classement mondial
• Multijoueur — affronte un autre joueur sur le même pitch et grimpe dans le classement

DES JOKERS POUR T'AIDER
Révèle une lettre, élimine des intrus, démasque l'acteur ou le personnage, obtiens un indice ou un mot entier — à utiliser au bon moment.

Aucune connaissance encyclopédique requise : Plot Twist(ed) se joue à l'instinct, à la déduction, et avec un peu de culture ciné.

Télécharge Plot Twist(ed) et retrouve le plaisir de dire « Ah mais oui, bien sûr ! »
```

## Textes — Anglais (États-Unis)

**Name (30)** : `Plot Twist(ed)`

**Subtitle (30)** : `Guess the movie from the pitch` (30)

**Promotional text (170)** :

```
Tricky movie pitches, misleading names, and a title to rebuild letter by letter. Can you see through the plot twist?
```

**Keywords (100)** :

```
trivia,quiz,cinema,actor,riddle,puzzle,word,letters,blockbuster,hollywood,brain,duel,guessing
```

**Description (4000)** — sans emojis : App Store Connect les refuse (« caractères non autorisés ») :

```
FIND THE MOVIE BEHIND THE PITCH

Plot Twist(ed) gives you a movie's synopsis... but the character names are booby-trapped: an actor instead of the role, another character, a misleading name. Your job: rebuild the title, letter by letter.

Easy to learn, hard to put down: every name color hides a rule. Blue? That's the actor. Green? The real character. Red, orange or purple? Watch out...

FOUR WAYS TO PLAY
• Worlds — hundreds of movies grouped by theme (blockbusters, classics, cult films...), from easy to extreme
• Daily Challenge — one theme, 7 clues, 7 actors: match each clue to the right name, as fast as you can
• Puzzle of the Week — the same puzzle for every player, a new letter revealed over time, and a worldwide ranking
• Multiplayer — face another player on the same pitch and climb the ranks

JOKERS TO HELP YOU
Reveal a letter, remove decoys, unmask the actor or the character, get a hint or a whole word — use them at the right moment.

No encyclopedic knowledge needed: Plot Twist(ed) is all about instinct, deduction and a bit of movie culture.

Download Plot Twist(ed) and enjoy that "Oh, of course!" moment.
```

## Réglages de la fiche

| Champ | Valeur |
|---|---|
| Catégorie principale | Jeux → Quiz (Trivia) |
| Catégorie secondaire | Jeux → Mots (Word) |
| URL d'assistance | `https://lnaappgame.github.io/plottwisted/` |
| URL marketing | (facultatif, laisser vide) |
| URL de la politique de confidentialité | `https://lnaappgame.github.io/plottwisted/#conf` |
| Copyright | `2026 Damien Ellena` |
| Classification par âge | Répondre « Aucun / Non » partout (pas de violence, pas de contenu adulte, pas d'accès web libre, pas de jeux d'argent, pas de chat entre joueurs) → **4+** attendu. Les publicités et achats intégrés ne changent pas l'âge. |
| Prix de l'app | Gratuit (les achats intégrés sont à part) |

## Informations pour l'examen d'Apple (App Review)

- **Compte de démonstration** : décocher « Connexion requise » — le jeu se joue entièrement sans compte.
- **Coordonnées** : ton nom, ton téléphone au format international (`+33 6 xx xx xx xx`, sans le 0), `lna.app.game@gmail.com`.
- **Notes** (en anglais) :

```
No account is needed: the whole game is playable right away. Google Sign-In (Settings) is optional and only backs up progress to the cloud.
In-app purchases are in the Shop (home screen): jokers and ad removal. "Restore purchases" is at the bottom of the Shop.
Ads are served by Google AdMob. The App Tracking Transparency prompt is shown after a short explainer screen, and ads keep working (non-personalized) if tracking is declined.
```

## Confidentialité de l'app (questionnaire « App Privacy »)

App Store Connect → Plot Twist(ed) → Confidentialité de l'app → **« Oui, nous collectons des données »**. Puis, pour chaque type ci-dessous : les finalités cochées, **liées à l'utilisateur** ou non, **utilisées pour le suivi** (« tracking ») ou non. Ces réponses découlent de ce que l'app utilise réellement : Firebase (classements, multijoueur, Analytics avec consentement, Crashlytics), AdMob, connexion Google facultative.

| Type de données (catégorie Apple) | Finalités | Liées à l'utilisateur | Suivi |
|---|---|---|---|
| Coordonnées → Adresse e-mail *(seulement si connexion Google)* | Fonctionnalités de l'app | Oui | Non |
| Identifiants → Identifiant utilisateur *(identifiant de joueur, pseudo)* | Fonctionnalités de l'app, Analyses | Oui | Non |
| Identifiants → Identifiant de l'appareil *(IDFA, si le joueur autorise le suivi)* | Publicité tierce, Analyses | Non | **Oui** |
| Contenu utilisateur → Contenu de jeu *(scores, temps des classements et du multijoueur)* | Fonctionnalités de l'app | Oui | Non |
| Données d'utilisation → Interactions avec le produit *(Analytics, avec consentement)* | Analyses | Non | Non |
| Données d'utilisation → Données publicitaires *(AdMob)* | Publicité tierce | Non | **Oui** |
| Achats → Historique d'achats *(achats intégrés)* | Analyses, Fonctionnalités de l'app | Non | Non |
| Localisation → Localisation approximative *(déduite de l'adresse IP par AdMob)* | Publicité tierce | Non | **Oui** |
| Diagnostics → Données de plantage, Données de performance, Autres données de diagnostic *(Crashlytics, SDK Google)* | Fonctionnalités de l'app, Analyses | Non | Non |

Rien d'autre n'est collecté : pas de nom réel, de téléphone, de contacts, de photos, de santé, de position précise ni de messages.

## Captures d'écran

Format exigé : **iPhone 6,9 pouces**, 1290 × 2796 (portrait), 3 à 10 captures. Elles seront faites sur l'iPhone d'un ami pendant le test TestFlight, puis remises au bon format.
