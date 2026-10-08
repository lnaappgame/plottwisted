// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Plot Twist(ed)';

  @override
  String get settingsTitle => 'PARAMÈTRES';

  @override
  String get settingsLightMode => '🌗 Mode clair';

  @override
  String get settingsSfx => '🔊 Effets sonores';

  @override
  String get settingsVibrations => '📳 Vibrations';

  @override
  String get settingsColorblind => '👁️ Mode daltonien';

  @override
  String get settingsDyslexic => '📖 Mode dyslexique';

  @override
  String get settingsTextSize => '🔎 Taille des caractères';

  @override
  String get settingsTextSizeSmall => 'Petit';

  @override
  String get settingsTextSizeLarge => 'Grand';

  @override
  String get settingsLanguage => '🌐 Langue';

  @override
  String get settingsLanguageFrench => 'Français';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsAdPrivacy => '🔒 Options de confidentialité des pubs';

  @override
  String get settingsCgu => 'Conditions générales d\'utilisation';

  @override
  String get settingsPrivacyPolicy => 'Politique de confidentialité';

  @override
  String get settingsResetSave => '🗑️ RÉINITIALISER LA SAUVEGARDE';

  @override
  String get settingsClose => 'FERMER';

  @override
  String settingsAccountLinked(String email) {
    return '✅ Compte lié : $email';
  }

  @override
  String get settingsAccountLocalOnly =>
      '☁️ Progression sauvegardée uniquement sur cet appareil';

  @override
  String get settingsSaveWithGoogle => '🔗 Sauvegarder avec Google';

  @override
  String get settingsSaveNow => '🔄 Sauvegarder maintenant';

  @override
  String get settingsGoogleLinkedSnack =>
      '✅ Compte Google lié. Ta progression est sauvegardée.';

  @override
  String get settingsGoogleLinkedNoBackupSnack =>
      'Compte Google lié, mais aucune sauvegarde trouvée.';

  @override
  String get settingsGoogleErrorSnack =>
      '⚠️ Échec de la connexion. Réessaie plus tard.';

  @override
  String get settingsBackupUpToDateSnack => '✅ Sauvegarde à jour.';

  @override
  String get settingsBackupFailedSnack =>
      '⚠️ Échec de la sauvegarde. Réessaie plus tard.';

  @override
  String get settingsRestoreTitle => '☁️ Progression restaurée';

  @override
  String get settingsRestoreBody =>
      'Ta sauvegarde a été retrouvée ! Ferme complètement l\'application puis rouvre-la pour la voir apparaître.';

  @override
  String get settingsUnderstood => 'COMPRIS';

  @override
  String get settingsNoPrivacyNeeded => 'Rien à configurer pour votre région.';

  @override
  String get settingsResetConfirm1Title => '⚠️ Réinitialiser la sauvegarde ?';

  @override
  String get settingsResetConfirm1Body =>
      'Toute ta progression (mondes, niveaux, jokers) sera perdue.';

  @override
  String get settingsResetConfirm1Cta => 'Continuer';

  @override
  String get settingsCancel => 'Annuler';

  @override
  String get settingsResetConfirm2Title => '⚠️ Es-tu bien sûr(e) ?';

  @override
  String get settingsResetConfirm2Body =>
      'Cette action est définitive : la sauvegarde sera supprimée et le jeu reprendra de zéro.';

  @override
  String get settingsResetConfirm2Cta => 'Réinitialiser';

  @override
  String get commonRulesTitle => 'RÈGLES DU JEU';

  @override
  String get commonClose => 'FERMER';

  @override
  String get commonLoading => 'Chargement…';

  @override
  String get commonAdUnavailable =>
      'Pub indisponible pour le moment, réessaie plus tard.';

  @override
  String get commonClear => 'EFFACER';

  @override
  String get commonValidate => 'VALIDER';

  @override
  String get commonDayAbbr => 'j';

  @override
  String get defiTitle => 'DÉFI DU JOUR';

  @override
  String get defiRule1 =>
      'Un thème (\"commun\") différent chaque jour, le même pour tous les joueurs.';

  @override
  String get defiRule2 =>
      'Toutes les cases-réponses sont visibles dès le départ. Un indice dédié s\'affiche pour chacune, une seule fois, dans un ordre fixe.';

  @override
  String get defiRule3 => 'Tape la case qui correspond à l\'indice affiché.';

  @override
  String get defiRule4 =>
      'Bonne réponse : la case disparaît, indice suivant. Mauvaise réponse : +5 secondes de pénalité, la case reste, indice suivant quand même.';

  @override
  String get defiRule5 =>
      'Le chrono tourne du premier \"Commencer\" jusqu\'au dernier indice.';

  @override
  String get defiRule6 =>
      'Une pub permet de rejouer le même défi (pour battre ton record) ou de tenter un autre commun jamais joué.';

  @override
  String get defiRule7 =>
      'Bonus de jokers à ta première partie d\'un commun : sans faute = 1 joker mineur ; moins de 30 s (pénalités comprises) = 1 mineur, ou moins de 20 s = 1 majeur à la place.';

  @override
  String get defiRewardPerfect => 'Sans faute';

  @override
  String get defiRewardUnder30 => 'Moins de 30 s';

  @override
  String get defiRewardUnder20 => 'Moins de 20 s';

  @override
  String get defiRewardsReplay =>
      'Pas de bonus de jokers en rejouant un commun déjà joué.';

  @override
  String defiCasesInfo(int count) {
    return '$count cases-réponses, $count indices — tape la bonne case pour chaque indice.';
  }

  @override
  String defiBestTime(String time) {
    return '⏱️ Ton meilleur temps : $time';
  }

  @override
  String get defiStart => 'COMMENCER';

  @override
  String get defiCompleted => '🎉 DÉFI TERMINÉ !';

  @override
  String get defiBonusLabel => 'Défi bonus';

  @override
  String get defiTimeReal => 'Temps réel';

  @override
  String get defiTimePenalties => 'Pénalités';

  @override
  String get defiTimeTotal => 'Temps total';

  @override
  String get defiNewRecord => '🏆 Nouveau record personnel !';

  @override
  String defiBestTimeResult(String time) {
    return '⏱️ Meilleur temps : $time';
  }

  @override
  String get defiWatchAdReplay => '🎬 Regarder une pub pour rejouer';

  @override
  String get defiWatchAdBonus => '🎬 Regarder une pub pour un autre défi';

  @override
  String get defiMoreComing => 'De nouvelles énigmes arrivent très vite';

  @override
  String get defiBackHome => 'RETOUR À L\'ACCUEIL';

  @override
  String get enigmeIncomplete =>
      'Complète toutes les lettres avant de valider.';

  @override
  String get enigmeNoAttempts =>
      'Plus de tentatives pour aujourd\'hui — reviens demain ou regarde une pub.';

  @override
  String enigmeWrong(int n) {
    return 'Ce n\'est pas ça — $n tentative(s) restante(s) aujourd\'hui.';
  }

  @override
  String get enigmeAdLetterEarned => '+1 lettre révélée !';

  @override
  String get enigmeAdAttemptEarned => '+1 tentative pour aujourd\'hui !';

  @override
  String get enigmeRule1 =>
      'Une nouvelle énigme chaque semaine (lundi 00h00 GMT à dimanche 23h59 GMT), la même pour tous les joueurs.';

  @override
  String get enigmeRule2 =>
      'Le texte se révèle 1 lettre par heure, dans un ordre mélangé (pas celui du texte) — impossible de repérer où commencent ou finissent les mots avant de les avoir révélés.';

  @override
  String get enigmeRule3 =>
      'Devine le sujet (film, acteur ou personnage) avec les tuiles de lettres, comme dans le jeu principal.';

  @override
  String get enigmeRule4 =>
      '1 tentative gratuite par jour, plus jusqu\'à 5 en regardant une pub (1 tentative par pub).';

  @override
  String get enigmeRule5 =>
      'Une autre pub révèle 1 lettre de plus, jusqu\'à 5 fois par jour — indépendamment des tentatives.';

  @override
  String get enigmeRule6 => 'Aucun joker n\'est utilisable pendant l\'énigme.';

  @override
  String get enigmeRewardsHeader => 'RÉCOMPENSES SELON LE JOUR';

  @override
  String enigmeRewardDayLabel(int n) {
    return 'Jour $n';
  }

  @override
  String get enigmeReward1 => '1 joker de chaque type';

  @override
  String get enigmeReward2 => '2 majeurs + 2 mineurs';

  @override
  String get enigmeReward3 => '2 majeurs + 1 mineur';

  @override
  String get enigmeReward4 => '1 majeur + 2 mineurs';

  @override
  String get enigmeReward5 => '1 majeur';

  @override
  String get enigmeReward6 => '2 mineurs';

  @override
  String get enigmeReward7 => '1 mineur';

  @override
  String get enigmeHistoryTitle => 'HISTORIQUE';

  @override
  String get enigmeHistoryExplain =>
      'Le classement d\'une semaine repart à zéro dès le lundi suivant, mais tes résultats restent ici.';

  @override
  String get enigmeBestRanking => '🏆 Meilleur classement';

  @override
  String get enigmeBestTimeLabel => '⏱️ Meilleur temps';

  @override
  String get enigmeNoneSolved => 'Aucune énigme résolue pour l\'instant.';

  @override
  String get enigmeTitle => 'L\'ÉNIGME DE LA SEMAINE';

  @override
  String get enigmeZoom => 'Agrandir';

  @override
  String enigmeDayOf7(int n) {
    return 'Jour $n / 7';
  }

  @override
  String enigmeYear(String value) {
    return 'Année : $value';
  }

  @override
  String enigmeAge(String value) {
    return 'Âge : $value';
  }

  @override
  String enigmeNextLetterIn(String countdown) {
    return 'Prochaine lettre dévoilée dans $countdown';
  }

  @override
  String enigmeAttemptsLeft(int n) {
    return '$n tentative(s) restante(s) aujourd\'hui';
  }

  @override
  String get enigmeWatchAdLetter => '🎬 Regarder une pub (+1 lettre)';

  @override
  String get enigmeWatchAdAttempt => '🎬 Pub (+1 tentative)';

  @override
  String get enigmeComeBackTomorrow => 'Reviens demain';

  @override
  String get enigmeTopTenSnack => '🔴 Top 10% mondial ! +1 Joker Rouge';

  @override
  String get enigmeSolvedTitle => '🎉 RÉSOLU !';

  @override
  String enigmeFoundIn(String time, int day) {
    return 'Trouvé en $time (jour $day)';
  }

  @override
  String enigmeRewardLabel(String labels) {
    return 'Récompense : $labels';
  }

  @override
  String get enigmeRankCalculating => '🏆 Calcul du classement…';

  @override
  String get enigmeRankUnavailable =>
      '🏆 Classement indisponible pour le moment';

  @override
  String enigmeRankingLine(String rank, int total) {
    return '$rank sur $total joueur(s)';
  }

  @override
  String get enigmeRankUnknown => 'Classement indisponible';

  @override
  String enigmeWeekOf(String weekId, int day, String duration) {
    return 'Semaine du $weekId · jour $day · $duration';
  }

  @override
  String get gameIncomplete =>
      'Remplis toutes les cases avant de valider (même au hasard) !';

  @override
  String get gameWrong =>
      'Pas tout à fait... les mots corrects restent acquis !';

  @override
  String get colorOrange => 'orange';

  @override
  String get colorRed => 'rouge';

  @override
  String get colorPurple => 'violet';

  @override
  String get gameOrangeIntro1 => 'Les acteurs surlignés en ';

  @override
  String get gameOrangeIntro2 =>
      ' ont joué un même rôle que l\'acteur à trouver (Ben Affleck a joué Batman, tout comme Christian Bale, Michael Keaton, George Clooney, etc...). Un nom orange ne peut pas être révélé directement : il faut d\'abord le faire passer en ';

  @override
  String get gameOrangeIntro3 =>
      ' avec un Joker Rouge, puis utiliser les jokers Acteur/Personnage comme d\'habitude. Le Joker Rouge s\'obtient via une pub garantie (une fois par niveau concerné), en terminant dans le top 10% mondial de L\'énigme de la semaine, ou en boutique.';

  @override
  String get gameVioletIntro1 => 'Si un nom est surligné en ';

  @override
  String get gameVioletIntro2 =>
      ', il s\'agit d\'un lien de parenté ou de proximité avec l\'acteur ou le personnage. Exemple : \"Le valet de Batman\" = Alfred = Michael Caine ou Andy Serkis, etc...';

  @override
  String get gameTutorial1 =>
      'Devine le nom du film à partir du texte suivant. Le nom affiché en 🟢 vert est le vrai personnage de ce film.';

  @override
  String get gameTutorial2 =>
      'Cette fois, le premier nom est en 🔵 bleu : c\'est le nom du véritable acteur qui a joué ce rôle. Le second nom reste en 🟢 vert : c\'est le vrai personnage de ce film.';

  @override
  String get gameTutorial3 =>
      'Cette fois, le premier nom est en 🔴 rouge : ce n\'est pas le bon personnage pour ce film, mais un rôle que le même acteur a joué ailleurs. Le nom en 🟢 vert reste le vrai personnage de ce film.';

  @override
  String get gameDirectorLabel => '🎬 LE RÉALISATEUR';

  @override
  String get gameUnderstood => 'COMPRIS !';

  @override
  String get gameJokerWon => 'JOKER GAGNÉ';

  @override
  String get gameJokersWon => 'JOKERS GAGNÉS';

  @override
  String gameWorldDone(String world) {
    return '🏆 Monde $world terminé !';
  }

  @override
  String get gameMinorBonusOffer =>
      '3 essais sans trouver... regarder une courte pub pour gagner un joker ?';

  @override
  String get gameWatchAd => '▶ Regarder la pub';

  @override
  String get gameNoThanks => 'Non merci';

  @override
  String get gameSkipLater => 'Passer, j\'y reviendrai';

  @override
  String get gameSkipLastLevel =>
      'C\'est le dernier niveau de ce monde : il ne peut pas être gardé pour plus tard.';

  @override
  String get gameSkipForGood => 'Passer définitivement';

  @override
  String get gameSkipForGoodConfirm =>
      'Utiliser 1 joker « Passer définitivement » ? Le niveau sera résolu et sa réponse révélée.';

  @override
  String get gameSkipForGoodUse => 'UTILISER';

  @override
  String get commonCancel => 'Annuler';

  @override
  String get gameTutorialFinalTransition =>
      'Cher cinéphile, tu m\'as l\'air prêt à rentrer sur le plateau, voyons si tu as bien retenu ton texte...';

  @override
  String get gameTutorialComplete =>
      'Fin du tutoriel, maintenant à toi de jouer. Caméra, moteur..... Action !';

  @override
  String gameWorldCompleteBoth(String world, String major, String minor) {
    return '🏆 Monde $world terminé — Jokers gagnés : $major + $minor !';
  }

  @override
  String gameWorldCompleteMajor(String world, String major) {
    return '🏆 Monde $world terminé — Joker gagné : $major !';
  }

  @override
  String get gameAllContentComplete =>
      'Cher cinéphile, de nouveaux niveaux arrivent très vite.';

  @override
  String get gameTutorialCategory => 'Tutoriel';

  @override
  String homeStreakDays(int days) {
    return '📅 $days JOURS D\'AFFILÉE !';
  }

  @override
  String get homeStreakReward3 => '+1 indice 💡';

  @override
  String get homeStreakReward7 => '+1 joker rouge 🔴';

  @override
  String get homeStreakReward14 => '+1 de chaque joker classique';

  @override
  String get homeStreakReward28 =>
      'Cycle complet ! +3 jokers rouges et +3 de chaque joker classique';

  @override
  String get homeGreat => 'SUPER !';

  @override
  String get homePlay => 'JOUER';

  @override
  String get homeWeeklyPuzzle => '🧩 L\'ÉNIGME DE LA SEMAINE';

  @override
  String get homeDailyChallenge => '🎯 DÉFI DU JOUR';

  @override
  String get homeMultiplayer => '⚔️ MULTIJOUEUR';

  @override
  String get homeShop => '🛒 Boutique';

  @override
  String get homeHelp => '❓ Comment jouer';

  @override
  String get homeTagline => 'RETROUVE LE FILM DERRIÈRE LE PITCH';

  @override
  String get homeChooseAvatar => 'CHOISIS TON AVATAR';

  @override
  String get homeYourId => 'TON IDENTIFIANT';

  @override
  String get homeYourNickname => 'Ton pseudo';

  @override
  String get jokerReveal => 'RÉVÉLER';

  @override
  String get jokerEliminate => 'ÉLIMINER';

  @override
  String get jokerActor => 'ACTEUR';

  @override
  String get jokerCharacter => 'PERSONNAGE';

  @override
  String get jokerHint => 'INDICE';

  @override
  String get jokerRevealWord => 'RÉVÉLER UN MOT';

  @override
  String get jokerRedCharacter => 'PERSONNAGE (ROUGE)';

  @override
  String get jokerWinOne => 'GAGNER UN JOKER';

  @override
  String get jokerLockedSubtitle => 'verrouillé';

  @override
  String get jokerAdUnlockSubtitle => '🎬 pub → joker';

  @override
  String get jokerHintUsedSubtitle => 'utilisé · 🎬';

  @override
  String get jokerRedLockedToast =>
      'Plus de joker rouge pour aujourd\'hui sur ce niveau — obtiens-en via le top 10% mondial de L\'énigme de la semaine ou dans la boutique.';

  @override
  String get pitchDifferentColorHint =>
      'Touche un nom dont la couleur est différente du joker choisi.';

  @override
  String resultInFilm(String film) {
    return ', dans $film';
  }

  @override
  String get resultSeeFilmSheet => 'Voir la fiche du film';

  @override
  String get resultNextFilm => 'SUIVANT';

  @override
  String get worldComplete => 'MONDE TERMINÉ !';

  @override
  String get worldChooseNext => 'Choisis le prochain monde';

  @override
  String worldNumber(int n) {
    return 'MONDE $n';
  }

  @override
  String worldStartHint(int count) {
    return 'Indice de départ : les $count prochaines devinettes appartiennent à cette catégorie.';
  }

  @override
  String get instructionsTitle => 'COMMENT JOUER';

  @override
  String get instructionsIntro =>
      'Devine le titre du film à partir d\'un pitch dont les personnages sont désignés par des noms \"masqués\". Utilise les jokers pour t\'aider, puis reconstitue le titre lettre par lettre.';

  @override
  String get instructionsColorsHeader => 'SIGNIFICATION DES COULEURS';

  @override
  String get instrColorGreen => 'Vert';

  @override
  String get instrColorRed => 'Rouge';

  @override
  String get instrColorBlue => 'Bleu';

  @override
  String get instrColorOrange => 'Orange';

  @override
  String get instrColorViolet => 'Violet';

  @override
  String get instructionsLegendGreen =>
      'Le vrai nom du personnage dans ce film.';

  @override
  String get instructionsLegendRed =>
      'Un personnage d\'un AUTRE film joué par le même acteur — un piège.';

  @override
  String get instructionsLegendBlue => 'Le nom du véritable acteur.';

  @override
  String get instructionsLegendOrange =>
      'Un AUTRE acteur ayant joué le même rôle ailleurs — ne peut pas être révélé directement, il faut d\'abord le faire passer en rouge avec un Joker Rouge.';

  @override
  String get instructionsLegendViolet =>
      'Un lien de parenté ou de proximité avec l\'acteur ou le personnage.';

  @override
  String get instructionsJokersHeader => 'LES JOKERS';

  @override
  String get instructionsMinorHeader => 'Mineurs';

  @override
  String get instructionsMajorHeader => 'Majeurs';

  @override
  String get instructionsSpecialHeader => 'Spécial';

  @override
  String get instrJokerRevealLabel => 'Révéler';

  @override
  String get instrJokerRevealDesc =>
      'Révèle une lettre au hasard dans la grille de réponse.';

  @override
  String get instrJokerEliminateLabel => 'Éliminer';

  @override
  String get instrJokerEliminateDesc =>
      'Retire 3 lettres leurres (fausses) de la réserve de lettres.';

  @override
  String get instrJokerCharacterLabel => 'Personnage';

  @override
  String get instrJokerCharacterDesc =>
      'Affiche le vrai nom du personnage à la place d\'un nom masqué.';

  @override
  String get instrJokerActorLabel => 'Acteur';

  @override
  String get instrJokerActorDesc =>
      'Affiche le nom du véritable acteur à la place d\'un nom masqué.';

  @override
  String get instrJokerHintLabel => 'Indice';

  @override
  String get instrJokerHintDesc =>
      'Révèle un indice supplémentaire sur le film, affiché sous le pitch.';

  @override
  String get instrJokerRevealWordLabel => 'Révéler un mot';

  @override
  String get instrJokerRevealWordDesc =>
      'Révèle un mot entier de la réponse (ou un tiers des lettres si le titre n\'a qu\'un seul mot).';

  @override
  String get instrJokerRedLabel => 'Personnage (rouge)';

  @override
  String get instrJokerRedDesc =>
      'Fait passer un nom orange en rouge (les jokers Acteur/Personnage prennent ensuite le relais normalement). N\'apparaît que sur les énigmes avec un nom orange. S\'obtient de 3 façons : une pub garantie (une fois par niveau concerné), le top 10% mondial de L\'énigme de la semaine, ou la boutique.';

  @override
  String get instrJokerSkipLabel => 'Passer définitivement';

  @override
  String get instrJokerSkipDesc =>
      'Résout le niveau en cours et révèle sa réponse. S\'obtient en boutique.';

  @override
  String get instructionsTabJokers => 'Jokers';

  @override
  String get instructionsTabModes => 'Modes de jeu';

  @override
  String get instructionsEarnHeader => 'OBTENIR DES JOKERS';

  @override
  String get instrEarnAd =>
      '« Gagner un joker » : une pub = un joker au hasard, mineur le plus souvent. Un joker que tu possèdes déjà en 5 exemplaires ou plus sort deux fois moins souvent.';

  @override
  String get instrEarnLevels =>
      'Jeu principal : un joker mineur au niveau 5 de chaque monde, puis un mineur et un majeur à la fin du monde.';

  @override
  String get instrEarnModes =>
      'L\'énigme de la semaine (plus tu trouves tôt, plus tu gagnes) et le Défi du jour (sans faute et chrono rapide) en rapportent aussi.';

  @override
  String get instrEarnShop => 'La boutique propose des packs de jokers.';

  @override
  String get instrEarnEmpty =>
      'Un joker à 0 reste affiché, éteint, jusqu\'à ce que tu en regagnes un.';

  @override
  String get instrModeMainTitle => '🎬 Jeu principal';

  @override
  String get instrModeMainDesc =>
      'Retrouve le film à partir de son pitch, où les personnages sont désignés par des noms de couleur. Reconstitue le titre avec les lettres proposées. Chaque monde compte 10 niveaux, de Facile à Extrême ; un niveau peut être gardé pour plus tard.';

  @override
  String get instrModeEnigmeTitle => '🧩 L\'énigme de la semaine';

  @override
  String get instrModeEnigmeDesc =>
      'Une énigme par semaine, la même pour tous. Le texte se dévoile d\'une lettre par heure : devine le sujet (film, acteur ou personnage) le plus tôt possible, avec une tentative gratuite par jour. Plus tu trouves tôt, plus la récompense en jokers est grande ; le top 10 % mondial gagne un joker rouge.';

  @override
  String get instrModeDefiTitle => '🎯 Défi du jour';

  @override
  String get instrModeDefiDesc =>
      'Un thème par jour (un « commun ») et toutes ses réponses affichées. Pour chaque indice, touche la bonne réponse le plus vite possible : chaque erreur ajoute 5 secondes. Un sans-faute et un chrono rapide rapportent des jokers.';

  @override
  String get instrModeMpTitle => '⚔️ Multijoueur';

  @override
  String get instrModeMpDesc =>
      'Affronte un adversaire de ton niveau en 3 manches : le premier à trouver la réponse marque le point. Ton classement Elo évolue à chaque match ; 5 parties par jour.';

  @override
  String get streakCalendarTitle => '📅 CALENDRIER DE SÉRIE';

  @override
  String streakCalendarSubtitle(int streak, int jour, int total) {
    return '$streak jour(s) d\'affilée — jour $jour sur $total';
  }

  @override
  String streakCalendarEventLine(
      String emoji, int day, String label, String date) {
    return '$emoji Jour $day — $label ($date) : bonus supplémentaire !';
  }

  @override
  String get streakLegendMinor => 'Bonus mineur — 1 joker Indice';

  @override
  String streakLegendMajor(String days) {
    return 'Bonus majeur — jours $days';
  }

  @override
  String streakLegendCycle(int n) {
    return 'Cycle complet — jour $n, bonus majeur ×3';
  }

  @override
  String get streakLegendEvent =>
      'Grand événement du cinéma — bonus en plus de celui du jour';

  @override
  String get mpTitle => 'MULTIJOUEUR';

  @override
  String get mpAdMatchEarned => '+1 partie pour aujourd\'hui !';

  @override
  String mpHistoryLastMatches(int n) {
    return 'Les $n derniers matchs.';
  }

  @override
  String get mpNoMatchYet => 'Aucun match joué pour l\'instant.';

  @override
  String get mpRule1 =>
      'Match au meilleur des 3 manches (victoire dès 2 points), 45 à 75 secondes par manche selon la longueur de la réponse.';

  @override
  String get mpRule2 =>
      'L\'indice se révèle lettre par lettre, toutes les lettres visibles pile à 35 secondes.';

  @override
  String get mpRule3 =>
      'Le premier des deux à trouver la bonne réponse gagne la manche. Si personne ne trouve à temps, vous gagnez tous les deux le point.';

  @override
  String get mpRule4 =>
      'Un match peut donc finir nul (2-2 en seulement 2 manches).';

  @override
  String get mpRule5 => 'Ton classement Elo évolue à la fin de chaque match.';

  @override
  String get mpRule6 => '5 parties par jour, se réinitialise à 0h00 GMT.';

  @override
  String get mpYourRank => 'Votre rang';

  @override
  String mpTopPercent(String pct) {
    return 'Vous êtes dans le top $pct % mondial';
  }

  @override
  String get mpChallengePlayer => '⚔️ AFFRONTER UN JOUEUR';

  @override
  String mpWatchAdForMatch(int watched, int max) {
    return '🎬 Regarder une pub pour +1 partie ($watched/$max)';
  }

  @override
  String get mpComeBackTomorrow => 'Reviens demain pour de nouvelles parties !';

  @override
  String mpMatchesLeft(int n) {
    return '$n partie(s) restante(s) aujourd\'hui';
  }

  @override
  String get mpQuotaReached => 'Quota du jour atteint';

  @override
  String get mpHistoryButton => '📜 HISTORIQUE';

  @override
  String get mpWin => 'Victoire';

  @override
  String get mpLoss => 'Défaite';

  @override
  String get mpDraw => 'Nul';

  @override
  String get mpRoundLabel => 'MANCHE';

  @override
  String get mpTimeLabel => 'TEMPS';

  @override
  String get mpYou => 'Vous';

  @override
  String get mpOpponentFallback => 'Adversaire';

  @override
  String mpRoundsWon(int n) {
    return '🏅 $n manche(s)';
  }

  @override
  String get mpRoundWon => '🎉 Manche gagnée !';

  @override
  String get mpRoundLost => '😔 Ton adversaire a trouvé le premier.';

  @override
  String get mpRoundTie =>
      '🤝 Personne n\'a trouvé — vous gagnez tous les deux le point.';

  @override
  String get mpMatchWin => '🏆 VICTOIRE';

  @override
  String get mpMatchLoss => '😔 DÉFAITE';

  @override
  String get mpMatchDraw => '🤝 MATCH NUL';

  @override
  String get mpNewTitle => '✨ Nouveau titre !';

  @override
  String get mpReplay => 'REJOUER';

  @override
  String get mpQuotaReachedFull => 'Quota du jour atteint — reviens demain !';

  @override
  String get shopTitle => 'BOUTIQUE';

  @override
  String get shopUnavailable => 'Boutique indisponible pour le moment.';

  @override
  String get shopRestore => 'Restaurer mes achats';

  @override
  String get shopRestoreDone =>
      'Vérification lancée : si tu avais acheté le retrait des pubs, il est rétabli.';
}
