# Réponse à Apple — Guideline 2.1, Information Needed (15/10/2026)

Apple a mis la version 1.0.7 (build 17) en « Refusé » le 15/10 à 6 h 53. Ce n'est pas un bug : c'est la demande d'informations faite aux nouveaux comptes développeurs. Il faut **répondre dans App Store Connect avec la vidéo** et **recopier le même texte dans le champ « Remarques »** des informations pour l'examen.

La vidéo (point 1) doit être filmée sur un vrai iPhone, avec le dernier iOS, en commençant par le lancement de l'app.

## Texte à envoyer (anglais)

```
Hello, and thank you for reviewing Plot Twist(ed). Here is the requested information.

1. SCREEN RECORDING
Attached: a screen recording made on a physical iPhone running the latest iOS. It starts with the app launch (consent screens, App Tracking Transparency prompt), then shows a typical session: playing a level with jokers, the Daily Challenge, the Puzzle of the Week, Multiplayer, and the Shop with an In-App Purchase and "Restore purchases". The app has no account creation, no login and no user-generated content.

2. PURPOSE AND AUDIENCE
Plot Twist(ed) is a casual movie trivia word game, in English and French. Each level shows a short synopsis of a famous movie in which the character names are deliberately mixed up (an actor instead of the role, a character from another film...). The player deduces the movie and types its title letter by letter. It is aimed at anyone aged 4+ who enjoys movies and word puzzles, for short play sessions. It is free, with ads and optional In-App Purchases.

3. HOW TO ACCESS THE FEATURES
No account, no login and no setup: everything is available right after launch.
- On first launch: an ad consent form (Google UMP, shown where required), then a short explainer and the App Tracking Transparency prompt, then a 4-level tutorial.
- Home screen: PLAY (themed worlds of 10 levels), PUZZLE OF THE WEEK, DAILY CHALLENGE, MULTIPLAYER, Shop (bottom left), How to play (bottom right), Settings (gear icon, top right).
- In a level: tap letters (tiles or AZERTY/QWERTY keyboard, chosen in Settings) to fill the title, then SUBMIT. Jokers (reveal a letter, remove decoys, hint...) are under the grid.

4. EXTERNAL SERVICES
- Google Firebase: Authentication (anonymous ID per device, no personal account), Cloud Firestore (Puzzle of the Week leaderboard, multiplayer matching), Analytics (only with consent), Crashlytics (crash reports).
- Google AdMob, with Google's User Messaging Platform for consent; ads are non-personalized when tracking is declined.
- Apple StoreKit for In-App Purchases.
- Optional link "See the movie page" opening the movie's public page on IMDb (English) or AlloCine (French) in the browser.
No AI service, no payment processor other than Apple, no external login.

5. REGIONAL DIFFERENCES
The app works the same in all regions. The language (English or French) follows the device language and can be changed in Settings; the English version uses US movie titles. Prices follow the App Store region.

6. THIRD-PARTY MATERIAL
The game contains no third-party images, posters, logos, trailers, music or video. It only mentions movie titles and the names of characters and actors as factual references, in synopses written by us. The app is not affiliated with any studio.

7. IN-APP PURCHASES
The Shop opens from the "Shop" button on the home screen (also from the "Skip for good" button in a level when the player has none left). Products:
- Remove ads (non-consumable)
- 10 mixed jokers pack (consumable)
- 30 jokers + no ads pack (non-consumable)
- 100 jokers + no ads pack (non-consumable)
- 3 red jokers pack (consumable): each one unlocks an orange name hint
- "Skip for good" joker (consumable): solves the current level for the player
"Restore purchases" is at the bottom of the Shop. Jokers are used in levels; "Remove ads" stops forced ads (optional rewarded ads stay available).

Thank you!
```

## La vidéo : ce que ton ami doit filmer

Sur l'iPhone, avec le build de test (pubs de test), **pas le 17** :

1. Supprimer l'app si elle est installée, la réinstaller depuis TestFlight.
2. Centre de contrôle → **Enregistrement de l'écran** → attendre la fin du décompte.
3. **Lancer l'app** : écran de consentement, explication du suivi, demande de suivi d'Apple (répondre comme il veut), tutoriel (4 niveaux courts).
4. Accueil → **JOUER** : résoudre un niveau en utilisant un ou deux jokers.
5. Revenir à l'accueil → **Défi du jour** (quelques réponses), **Énigme de la semaine**, **Multijoueur** (lancer une partie quelques secondes).
6. **Boutique** : acheter un article (en TestFlight, c'est gratuit : compte de test Apple), montrer que les jokers arrivent, puis **Restaurer mes achats**.
7. Arrêter l'enregistrement (3 à 5 minutes suffisent). La vidéo est dans Photos : me l'envoyer (AirDrop, Google Drive, WeTransfer...).
