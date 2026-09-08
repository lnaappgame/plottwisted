# Plot Twist(ed) — projet Flutter (v2, à jour)

Ce projet reprend **toute la mécanique et le contenu validés** dans le
prototype HTML : 255 devinettes (25 mondes + tutoriel guidé), 5 couleurs de
noms (vert/rouge/bleu/orange/violet), 5 jokers + le joker pub "Gagner un
joker", verrouillage de mots, cadence de pub, écrans d'accueil/paramètres/
boutique/instructions, mode clair.

## Démarrer le projet

1. Installe le [SDK Flutter](https://docs.flutter.dev/get-started/install), vérifie avec `flutter doctor`.
2. Depuis un dossier vide :
   ```
   flutter create cine_devinette
   cd cine_devinette
   # remplace le dossier lib/ généré par celui fourni ici
   # remplace pubspec.yaml par celui fourni ici
   ```
3. `flutter pub get`
4. `flutter run`

**Important** : je n'ai pas pu compiler ce code (pas de SDK Dart dans mon
environnement). Je l'ai relu ligne par ligne et corrigé deux bugs trouvés à
la relecture (transition tutoriel 0-4→0-5, span redondant dans le pitch),
mais une vraie compilation peut encore révéler des coquilles. Montre-moi les
erreurs de `flutter run` si besoin, je les corrige.

## Où ajouter du contenu

**Ne modifie jamais `lib/data/puzzles_data.dart` à la main** — il est généré
automatiquement depuis le tableau Excel maître. Pour ajouter des devinettes :
donne-moi le tableau à jour, je régénère ce fichier et te le renvoie.

## Ce qui est fonctionnel dans ce code

- Moteur complet : curseur de saisie, verrouillage par mot, ponctuation
  pré-remplie, chiffres à trouver (+2 leurres), 5 couleurs de noms
- 5 jokers (Révéler/Éliminer/Acteur/Personnage/Indice) + "Gagner un joker"
  (pub à récompense, 80% mineur / 20% majeur)
- Paliers de récompense (mineur niveau 5, majeur fin de monde, rotation)
- Pub forcée aux positions 3/5/8/10 + règle des 60 secondes
- Tutoriel guidé complet avec jokers obligatoires et garde-fou anti-blocage
- Écran de révélation avec film d'origine des noms rouge/orange
- Message de fin de contenu quand tout est terminé
- Écrans Accueil / Paramètres / Boutique / Instructions (légende des
  couleurs progressive) / mode clair

## Ce qui N'EST PAS encore fait (gaps connus, transparence totale)

- **Sauvegarde cloud** — la sauvegarde **locale** est faite (`shared_preferences`
  via `save_service.dart` + `GameState.toJson()`/`restore()`) : monde, niveau,
  jokers, paliers et retrait des pubs survivent à la fermeture de l'app. Il
  manque encore la synchronisation cloud (Google Play Games Services) pour
  suivre le joueur d'un appareil à l'autre.
- **AdMob en production** — `ad_service.dart` utilise déjà les vrais
  `InterstitialAd`/`RewardedAd` de `google_mobile_ads`, mais avec les ID de
  blocs d'annonces de **test** publics de Google. Avant publication : créer
  un compte AdMob, remplacer les ID de test dans `ad_service.dart`,
  `android/app/src/main/AndroidManifest.xml` et `ios/Runner/Info.plist` par
  les vrais, et ajouter la liste `SKAdNetworkIdentifiers` côté iOS.
- **Achats intégrés en production** — `purchase_service.dart` utilise déjà
  le vrai `in_app_purchase` (interroge le store, écoute les achats, applique
  les récompenses). Mais **aucun produit n'est configuré côté store** : sans
  compte Google Play Console / App Store Connect avec les ID produits
  suivants créés, la boutique reste marquée "indisponible" — c'est le
  comportement attendu, pas un bug. ID produits à créer (voir
  `lib/models/shop_item.dart` pour la liste centralisée, quantités/prix
  modifiables à un seul endroit) :
  - `remove_ads` (non consommable)
  - `jokers_pack_10` (consommable)
  - `jokers_pack_30_noads24h` (consommable)
  - `jokers_pack_100_noads` (consommable)
- **Avatars** : emojis d'archétypes pour l'instant (voir `app_settings.dart`),
  pas encore la version pixel-art dessinée.

## Prochaines étapes techniques (dans l'ordre logique)

1. Compte AdMob réel + remplacement des ID de test (voir ci-dessus)
2. Compte Google Play Console / App Store Connect + création des 4 produits
   listés ci-dessus (mêmes ID exacts que dans `shop_item.dart`)
3. Sauvegarde cloud (Google Play Games Services)
4. Icône, splash screen, assets de fiche store

## Comptes nécessaires pour publier

Voir le plan de route détaillé donné dans la conversation — comptes Google
Play (25 $) et Apple Developer (99 $/an), aucune société requise pour
l'inscription, mais un statut est nécessaire pour déclarer les revenus.
