# Demande d'accès à la production — Google Play (brouillon du 18/10/2026)

Le bouton « Demander à publier en production » s'est débloqué le 18/10, après 14 jours de test fermé avec au moins 12 testeurs (piste « Version test », liste « beta test PT(ed) »).
D'après des guides tiers, Google examine la demande en général sous 7 jours ; Google ne donne pas de délai officiel.
Google vérifie que le test a été réel : des réponses précises passent mieux que des phrases génériques.

Le formulaire limite les réponses à 300 caractères : toutes les réponses ci-dessous font moins de 300 caractères, crochets compris.
Les passages entre [crochets] sont à compléter avant d'envoyer, en restant court.

---

## Partie 1 — À propos du test fermé

**Facilité de recruter des testeurs :** [à choisir : « Facile » ou « Neutre »]

**Engagement des testeurs pendant le test** (265 car.)

> Test fermé du [date] au 18/10/2026 avec [nombre] testeurs, dont 12 en continu depuis le 4/10. Ils ont joué au mode principal, au Défi du jour, à l'énigme de la semaine et au multijoueur, et ont installé les 5 mises à jour publiées pendant le test (versions 9 à 13).

**Résumé des retours et comment ils ont été recueillis** (257 car.)

> Retours reçus [par WhatsApp et de vive voix] et via Crashlytics : fonctions en ligne inactives sur les versions Play, progression restaurée puis perdue à la fermeture, clavier trop petit, coquilles dans les énigmes, envie de partager une énigme avec un ami.

## Partie 2 — À propos de l'application

**Audience visée** (193 car.)

> Grand public adulte et adolescent ([tranche d'âge de « Public cible »]), francophone et anglophone, amateur de cinéma, de séries et de quiz, qui cherche des parties courtes de quelques minutes.

**Spécificités du jeu / valeur pour les joueurs** (298 car.)

> Jeu de devinettes gratuit sur le cinéma et les séries : dans chaque résumé, les personnages portent des noms venus d'autres films, et le joueur retrouve le titre lettre par lettre. 25 mondes, 250+ énigmes, un Défi du jour, une énigme de la semaine et un mode multijoueur, en français et en anglais.

**Installations prévues la première année :** [à choisir, rester réaliste]

## Partie 3 — Préparation à la production

**Modifications apportées suite au test** (270 car.)

> Corrigé : Firebase sur les versions Play (classement, multijoueur), restauration de la progression, clavier agrandi de 33 %, jokers revus. Ajouté : 25 mondes avec coquilles corrigées, partage « Demander à un ami », lectures Firestore optimisées pour la montée en charge.

**Comment nous avons déterminé que l'application est prête** (275 car.)

> Chaque correctif a été vérifié sur la version de test installée depuis Google Play, puis la version de production a été lancée sur un vrai appareil. Les 228 tests automatisés passent, Crashlytics ne montre [aucun plantage] et les déclarations et la fiche Play sont complètes.
