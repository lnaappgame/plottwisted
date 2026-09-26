# Politique de confidentialité — Plot Twist(ed)

*Dernière mise à jour : [à compléter à la publication]*

> **Brouillon de travail — non relu par un juriste.** Version corrigée pour refléter fidèlement les traitements de données réellement effectués par l'application, y compris la sauvegarde cloud liée à un compte Google et les services Firebase (classements, mesure d'audience, diagnostic technique), absents de la version précédente. À faire valider par un professionnel du droit avant publication sur les stores.

## 1. Éditeur de l'application

L'application mobile **Plot Twist(ed)** est éditée par :

**LNA App**
12 montée du Château, 13650 Meyrargues, France
SIRET : 790 346 076 00025
Numéro de TVA intracommunautaire : FR 19790346076
Contact : lna.app.game@gmail.com

## 2. Quelles données sont traitées ?

### 2.1 Données de jeu locales (par défaut)

Plot Twist(ed) ne demande ni compte, ni nom, ni adresse e-mail pour jouer. Par défaut, ta progression (mondes débloqués, jokers, paramètres d'affichage et d'accessibilité, avatar choisi, identifiant de joueur généré automatiquement de type « Cinéphile #123456 ») est enregistrée **uniquement sur ton appareil** (mémoire locale de l'application) et n'est transmise à aucun serveur, sauf si tu actives toi-même l'une des fonctionnalités décrites aux points 2.2 et 2.3 ci-dessous. Si tu désinstalles l'application ou utilises la fonction « Réinitialiser la sauvegarde », ces données locales sont supprimées de ton appareil.

### 2.2 Sauvegarde et restauration liées à un compte Google (optionnel)

Si tu choisis d'activer le bouton « Sauvegarder avec Google » dans les réglages, l'application utilise les services **Firebase Authentication** et **Firebase Firestore** (fournis par Google) de la façon suivante :

- Chaque installation de l'application se voit attribuer, dès son premier lancement, un identifiant technique anonyme (compte Firebase « anonyme »), sans intervention de ta part.
- En activant la sauvegarde Google, cet identifiant anonyme est lié à ton compte Google via le service **Google Sign-In**. Dans ce cadre, Google nous transmet ton **adresse e-mail** associée à ce compte, à la seule fin de reconnaître ce compte si tu te reconnectes plus tard depuis un autre appareil (pour te proposer de restaurer ta progression). Cette adresse e-mail n'est ni affichée à d'autres joueurs, ni utilisée à des fins de communication ou de marketing par LNA App.
- L'ensemble de tes données de jeu locales (progression, paramètres, avatar, identifiant de joueur) est alors copié sur les serveurs **Firestore** de Google, dans un document technique associé à cet identifiant, afin de pouvoir être restauré sur un autre appareil ou après une réinstallation.

Cette fonctionnalité est strictement optionnelle : si tu ne l'actives jamais, aucune de ces données n'est transmise et seul le fonctionnement décrit au point 2.1 s'applique.

### 2.3 Classements en ligne et Multijoueur (Firestore)

Les modes **L'énigme de la semaine** et **Multijoueur** reposent sur un classement ou une comparaison de performances communs à plusieurs joueurs, ce qui suppose de transmettre certaines données à nos serveurs **Firebase Firestore**, associées uniquement à l'identifiant technique anonyme mentionné au point 2.2 (jamais à ton nom ou ton adresse e-mail, y compris si tu as par ailleurs lié un compte Google) :

- pour L'énigme de la semaine : ton temps de résolution, le jour de résolution, et ton classement relatif aux autres joueurs de la semaine en cours ;
- pour le Multijoueur : le résultat de chaque manche jouée (temps, victoire ou défaite), utilisé pour établir le temps de référence proposé aux autres joueurs et pour calculer ton classement (« Elo »).

Ces deux fonctionnalités nécessitent une connexion Internet active. Les classements hebdomadaires passés ne sont pas automatiquement supprimés de nos serveurs après leur remplacement par la semaine suivante ; ils cessent simplement d'être affichés activement dans l'application (voir point 6).

### 2.4 Mesure d'audience et diagnostic technique (Firebase Analytics et Crashlytics)

L'application utilise **Firebase Analytics** pour mesurer l'usage général de l'application (par exemple : quel mode de jeu est lancé, un niveau terminé, une publicité visionnée, un achat effectué) et **Firebase Crashlytics** pour recevoir un rapport technique automatique en cas de plantage de l'application (type d'erreur, état technique de l'application au moment de l'incident). Ces outils, fournis par Google, collectent des données techniques sur ton appareil (modèle, version du système d'exploitation, identifiant d'installation) mais ne visent pas à t'identifier personnellement.

### 2.5 Publicités (Google AdMob)

L'application affiche des publicités (vidéos récompensées et publicités entre les niveaux) fournies par **Google AdMob**. Pour servir, mesurer et personnaliser ces publicités, Google peut collecter des données techniques sur ton appareil : identifiant publicitaire (AAID sur Android, IDFA sur iOS — ce dernier n'étant accessible qu'après ton autorisation explicite via la fenêtre de suivi imposée par Apple, « App Tracking Transparency »), adresse IP approximative, informations sur l'appareil et interactions avec les publicités.

LNA App ne reçoit ni ne stocke ces données elle-même : elles sont traitées directement par Google, selon sa propre politique de confidentialité, consultable ici : https://policies.google.com/privacy

Un dispositif de recueil du consentement (Google User Messaging Platform) est présenté aux utilisateurs situés dans l'Espace économique européen avant l'affichage de toute publicité personnalisée, conformément au RGPD.

### 2.6 Achats intégrés (Google Play / App Store)

Plot Twist(ed) propose des achats intégrés facultatifs (packs de jokers, retrait des publicités — liste complète dans les CGU). Ces achats sont intégralement gérés par **Google Play** ou l'**App Store d'Apple** : LNA App ne voit et ne conserve à aucun moment tes informations de paiement (numéro de carte, etc.). Seule la confirmation qu'un achat a été effectué est transmise à l'application, pour débloquer le contenu correspondant.

### 2.7 Polices de caractères (Google Fonts)

L'application charge certaines polices de caractères depuis les serveurs de Google au premier lancement. Cet appel technique ne transmet aucune donnée personnelle au-delà de ce qui est strictement nécessaire à la livraison du fichier de police (adresse IP, traitée directement par Google).

### 2.8 Ce que nous ne faisons pas

LNA App ne vend aucune donnée à des tiers, n'exploite aucun outil de mesure ou de ciblage publicitaire en dehors de ceux listés ci-dessus (Google AdMob, Firebase), n'utilise les données décrites aux points 2.2 à 2.4 à aucune autre fin que celle pour laquelle elles ont été collectées, et n'a pas accès à tes contacts, photos, localisation précise ou autres données de ton appareil non mentionnées dans cette politique.

## 3. Base légale et finalités

- Le fonctionnement du jeu et la sauvegarde locale (point 2.1) reposent sur l'exécution du service demandé par l'utilisateur.
- La sauvegarde/restauration liée à un compte Google (point 2.2) et les classements en ligne (point 2.3) reposent sur l'exécution du service que tu demandes explicitement en activant ces fonctionnalités optionnelles.
- La mesure d'audience et le diagnostic technique (point 2.4) reposent sur l'intérêt légitime de LNA App à comprendre l'usage de l'application et à corriger les dysfonctionnements techniques ; tu peux t'y opposer dans les limites décrites au point 7.
- Les publicités personnalisées (point 2.5) reposent sur ton **consentement**, recueilli via le dispositif mentionné à ce point ; tu peux le refuser sans perdre l'accès au jeu (des publicités non personnalisées pourront alors être affichées).
- Les achats intégrés (point 2.6) reposent sur l'exécution du contrat conclu au moment de l'achat.

## 4. Destinataires des données

Les destinataires des données décrites ci-dessus sont : **Google** (au titre de Firebase — Authentication, Firestore, Analytics, Crashlytics ; d'AdMob pour la publicité ; de Google Play pour les achats et la connexion Google Sign-In) et **Apple** (App Store, pour les achats sur iOS), chacun dans le cadre strict des services décrits ci-dessus. Aucune donnée n'est vendue ni transmise à d'autres tiers.

## 5. Transferts hors Union européenne

Google et Apple peuvent traiter certaines données, notamment celles liées à Firebase et à AdMob, en dehors de l'Union européenne (en particulier aux États-Unis). Ces transferts s'appuient sur les garanties prévues par ces sociétés (clauses contractuelles types de la Commission européenne notamment). Voir leurs politiques de confidentialité respectives pour plus de détails : https://policies.google.com/privacy pour Google, https://www.apple.com/legal/privacy/fr/ pour Apple.

## 6. Durée de conservation

- Les données de jeu locales (point 2.1) sont conservées sur ton appareil tant que tu ne désinstalles pas l'application ou ne les réinitialises pas manuellement.
- Les données de sauvegarde liées à un compte Google (point 2.2) sont conservées jusqu'à ce que tu en demandes la suppression (voir point 7) ou que tu supprimes toi-même la liaison à ton compte Google.
- Les résultats de classement (point 2.3) sont conservés au-delà de la semaine ou de la période à laquelle ils se rapportent ; les périodes passées ne sont plus affichées activement dans l'application mais peuvent rester archivées sur nos serveurs.
- Les données de mesure d'audience et de diagnostic (point 2.4) sont conservées selon les durées par défaut de Firebase Analytics et Crashlytics, généralement de l'ordre de plusieurs mois.
- Les données traitées par Google dans le cadre d'AdMob ou de Google Play sont conservées selon les durées définies par Google.

## 7. Tes droits

Conformément au RGPD, tu disposes d'un droit d'accès, de rectification, d'effacement, de limitation, d'opposition et de portabilité sur les données te concernant. Ces droits s'exercent :

- pour les données de jeu locales (point 2.1) : directement depuis l'application (Paramètres → Réinitialiser la sauvegarde) ou en désinstallant l'application ;
- pour les données de sauvegarde ou de classement liées à Firebase (points 2.2 et 2.3) : en nous contactant à l'adresse indiquée au point 11, en précisant l'identifiant de joueur affiché dans l'application (par exemple « Cinéphile #123456 ») ou l'adresse e-mail du compte Google lié, afin que nous puissions localiser et supprimer les données correspondantes ;
- pour les données traitées par Google ou Apple (AdMob, Play, App Store, mesure d'audience) : directement auprès de ces sociétés, via leurs outils de gestion des données publicitaires/de compte respectifs.

Tu peux également nous contacter à l'adresse du point 11 pour toute question, et tu disposes du droit d'introduire une réclamation auprès de la CNIL (www.cnil.fr).

## 8. Mineurs

Plot Twist(ed) n'est pas spécifiquement destinée à un public de moins de 13 ans et ne collecte pas sciemment de données personnelles auprès d'enfants en dehors des traitements techniques décrits ci-dessus, communs à l'ensemble des utilisateurs.

## 9. Sécurité

Les données de jeu stockées uniquement en local (point 2.1) ne présentent pas de risque de fuite côté serveur, puisqu'elles ne quittent pas ton appareil. Les données que tu choisis de transmettre à nos serveurs (sauvegarde Google, classements) sont hébergées sur l'infrastructure Firebase de Google et bénéficient des mesures de sécurité mises en œuvre par Google pour ce service ; l'accès à ces données par LNA App est limité à ce qui est nécessaire au fonctionnement des fonctionnalités décrites dans cette politique.

## 10. Modification de cette politique

Cette politique de confidentialité peut être mise à jour, notamment lors de l'ajout de nouveaux modes de jeu ou de nouveaux traitements de données. La date de dernière mise à jour figure en haut de ce document.

## 11. Contact

Pour toute question relative à cette politique de confidentialité, ou pour exercer l'un des droits mentionnés au point 7 : lna.app.game@gmail.com — LNA App, 12 montée du Château, 13650 Meyrargues, France.
