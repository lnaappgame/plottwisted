import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr')
  ];

  /// Nom de l'application
  ///
  /// In fr, this message translates to:
  /// **'Plot Twist(ed)'**
  String get appTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'PARAMÈTRES'**
  String get settingsTitle;

  /// No description provided for @settingsLightMode.
  ///
  /// In fr, this message translates to:
  /// **'🌗 Mode clair'**
  String get settingsLightMode;

  /// No description provided for @settingsSfx.
  ///
  /// In fr, this message translates to:
  /// **'🔊 Effets sonores'**
  String get settingsSfx;

  /// No description provided for @settingsVibrations.
  ///
  /// In fr, this message translates to:
  /// **'📳 Vibrations'**
  String get settingsVibrations;

  /// No description provided for @settingsColorblind.
  ///
  /// In fr, this message translates to:
  /// **'👁️ Mode daltonien'**
  String get settingsColorblind;

  /// No description provided for @settingsDyslexic.
  ///
  /// In fr, this message translates to:
  /// **'📖 Mode dyslexique'**
  String get settingsDyslexic;

  /// No description provided for @settingsTextSize.
  ///
  /// In fr, this message translates to:
  /// **'🔎 Taille des caractères'**
  String get settingsTextSize;

  /// No description provided for @settingsTextSizeSmall.
  ///
  /// In fr, this message translates to:
  /// **'Petit'**
  String get settingsTextSizeSmall;

  /// No description provided for @settingsTextSizeLarge.
  ///
  /// In fr, this message translates to:
  /// **'Grand'**
  String get settingsTextSizeLarge;

  /// No description provided for @settingsLanguage.
  ///
  /// In fr, this message translates to:
  /// **'🌐 Langue'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageFrench.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get settingsLanguageFrench;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In fr, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsAdPrivacy.
  ///
  /// In fr, this message translates to:
  /// **'🔒 Options de confidentialité des pubs'**
  String get settingsAdPrivacy;

  /// No description provided for @settingsCgu.
  ///
  /// In fr, this message translates to:
  /// **'Conditions générales d\'utilisation'**
  String get settingsCgu;

  /// No description provided for @settingsPrivacyPolicy.
  ///
  /// In fr, this message translates to:
  /// **'Politique de confidentialité'**
  String get settingsPrivacyPolicy;

  /// No description provided for @settingsResetSave.
  ///
  /// In fr, this message translates to:
  /// **'🗑️ RÉINITIALISER LA SAUVEGARDE'**
  String get settingsResetSave;

  /// No description provided for @settingsClose.
  ///
  /// In fr, this message translates to:
  /// **'FERMER'**
  String get settingsClose;

  /// No description provided for @settingsAccountLinked.
  ///
  /// In fr, this message translates to:
  /// **'✅ Compte lié : {email}'**
  String settingsAccountLinked(String email);

  /// No description provided for @settingsAccountLocalOnly.
  ///
  /// In fr, this message translates to:
  /// **'☁️ Progression sauvegardée uniquement sur cet appareil'**
  String get settingsAccountLocalOnly;

  /// No description provided for @settingsSaveWithGoogle.
  ///
  /// In fr, this message translates to:
  /// **'🔗 Sauvegarder avec Google'**
  String get settingsSaveWithGoogle;

  /// No description provided for @settingsSaveNow.
  ///
  /// In fr, this message translates to:
  /// **'🔄 Sauvegarder maintenant'**
  String get settingsSaveNow;

  /// No description provided for @settingsGoogleLinkedSnack.
  ///
  /// In fr, this message translates to:
  /// **'✅ Compte Google lié. Ta progression est sauvegardée.'**
  String get settingsGoogleLinkedSnack;

  /// No description provided for @settingsGoogleLinkedNoBackupSnack.
  ///
  /// In fr, this message translates to:
  /// **'Compte Google lié, mais aucune sauvegarde trouvée.'**
  String get settingsGoogleLinkedNoBackupSnack;

  /// No description provided for @settingsGoogleErrorSnack.
  ///
  /// In fr, this message translates to:
  /// **'⚠️ Échec de la connexion. Réessaie plus tard.'**
  String get settingsGoogleErrorSnack;

  /// No description provided for @settingsBackupUpToDateSnack.
  ///
  /// In fr, this message translates to:
  /// **'✅ Sauvegarde à jour.'**
  String get settingsBackupUpToDateSnack;

  /// No description provided for @settingsBackupFailedSnack.
  ///
  /// In fr, this message translates to:
  /// **'⚠️ Échec de la sauvegarde. Réessaie plus tard.'**
  String get settingsBackupFailedSnack;

  /// No description provided for @settingsRestoreTitle.
  ///
  /// In fr, this message translates to:
  /// **'☁️ Progression restaurée'**
  String get settingsRestoreTitle;

  /// No description provided for @settingsRestoreBody.
  ///
  /// In fr, this message translates to:
  /// **'Ta sauvegarde a été retrouvée ! Ferme complètement l\'application puis rouvre-la pour la voir apparaître.'**
  String get settingsRestoreBody;

  /// No description provided for @settingsUnderstood.
  ///
  /// In fr, this message translates to:
  /// **'COMPRIS'**
  String get settingsUnderstood;

  /// No description provided for @settingsNoPrivacyNeeded.
  ///
  /// In fr, this message translates to:
  /// **'Rien à configurer pour votre région.'**
  String get settingsNoPrivacyNeeded;

  /// No description provided for @settingsResetConfirm1Title.
  ///
  /// In fr, this message translates to:
  /// **'⚠️ Réinitialiser la sauvegarde ?'**
  String get settingsResetConfirm1Title;

  /// No description provided for @settingsResetConfirm1Body.
  ///
  /// In fr, this message translates to:
  /// **'Toute ta progression (mondes, niveaux, jokers) sera perdue.'**
  String get settingsResetConfirm1Body;

  /// No description provided for @settingsResetConfirm1Cta.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get settingsResetConfirm1Cta;

  /// No description provided for @settingsCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get settingsCancel;

  /// No description provided for @settingsResetConfirm2Title.
  ///
  /// In fr, this message translates to:
  /// **'⚠️ Es-tu bien sûr(e) ?'**
  String get settingsResetConfirm2Title;

  /// No description provided for @settingsResetConfirm2Body.
  ///
  /// In fr, this message translates to:
  /// **'Cette action est définitive : la sauvegarde sera supprimée et le jeu reprendra de zéro.'**
  String get settingsResetConfirm2Body;

  /// No description provided for @settingsResetConfirm2Cta.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser'**
  String get settingsResetConfirm2Cta;

  /// No description provided for @commonRulesTitle.
  ///
  /// In fr, this message translates to:
  /// **'RÈGLES DU JEU'**
  String get commonRulesTitle;

  /// No description provided for @commonClose.
  ///
  /// In fr, this message translates to:
  /// **'FERMER'**
  String get commonClose;

  /// No description provided for @commonLoading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement…'**
  String get commonLoading;

  /// No description provided for @commonAdUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Pub indisponible pour le moment, réessaie plus tard.'**
  String get commonAdUnavailable;

  /// No description provided for @commonClear.
  ///
  /// In fr, this message translates to:
  /// **'EFFACER'**
  String get commonClear;

  /// No description provided for @commonValidate.
  ///
  /// In fr, this message translates to:
  /// **'VALIDER'**
  String get commonValidate;

  /// No description provided for @commonDayAbbr.
  ///
  /// In fr, this message translates to:
  /// **'j'**
  String get commonDayAbbr;

  /// No description provided for @defiTitle.
  ///
  /// In fr, this message translates to:
  /// **'DÉFI DU JOUR'**
  String get defiTitle;

  /// No description provided for @defiRule1.
  ///
  /// In fr, this message translates to:
  /// **'Un thème (\"commun\") différent chaque jour, le même pour tous les joueurs.'**
  String get defiRule1;

  /// No description provided for @defiRule2.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les cases-réponses sont visibles dès le départ. Un indice dédié s\'affiche pour chacune, une seule fois, dans un ordre fixe.'**
  String get defiRule2;

  /// No description provided for @defiRule3.
  ///
  /// In fr, this message translates to:
  /// **'Tape la case qui correspond à l\'indice affiché.'**
  String get defiRule3;

  /// No description provided for @defiRule4.
  ///
  /// In fr, this message translates to:
  /// **'Bonne réponse : la case disparaît, indice suivant. Mauvaise réponse : +5 secondes de pénalité, la case reste, indice suivant quand même.'**
  String get defiRule4;

  /// No description provided for @defiRule5.
  ///
  /// In fr, this message translates to:
  /// **'Le chrono tourne du premier \"Commencer\" jusqu\'au dernier indice.'**
  String get defiRule5;

  /// No description provided for @defiRule6.
  ///
  /// In fr, this message translates to:
  /// **'Une pub permet de rejouer le même défi (pour battre ton record) ou de tenter un autre commun jamais joué.'**
  String get defiRule6;

  /// No description provided for @defiCasesInfo.
  ///
  /// In fr, this message translates to:
  /// **'{count} cases-réponses, {count} indices — tape la bonne case pour chaque indice.'**
  String defiCasesInfo(int count);

  /// No description provided for @defiBestTime.
  ///
  /// In fr, this message translates to:
  /// **'⏱️ Ton meilleur temps : {time}'**
  String defiBestTime(String time);

  /// No description provided for @defiStart.
  ///
  /// In fr, this message translates to:
  /// **'COMMENCER'**
  String get defiStart;

  /// No description provided for @defiCompleted.
  ///
  /// In fr, this message translates to:
  /// **'🎉 DÉFI TERMINÉ !'**
  String get defiCompleted;

  /// No description provided for @defiBonusLabel.
  ///
  /// In fr, this message translates to:
  /// **'Défi bonus'**
  String get defiBonusLabel;

  /// No description provided for @defiTimeReal.
  ///
  /// In fr, this message translates to:
  /// **'Temps réel'**
  String get defiTimeReal;

  /// No description provided for @defiTimePenalties.
  ///
  /// In fr, this message translates to:
  /// **'Pénalités'**
  String get defiTimePenalties;

  /// No description provided for @defiTimeTotal.
  ///
  /// In fr, this message translates to:
  /// **'Temps total'**
  String get defiTimeTotal;

  /// No description provided for @defiNewRecord.
  ///
  /// In fr, this message translates to:
  /// **'🏆 Nouveau record personnel !'**
  String get defiNewRecord;

  /// No description provided for @defiBestTimeResult.
  ///
  /// In fr, this message translates to:
  /// **'⏱️ Meilleur temps : {time}'**
  String defiBestTimeResult(String time);

  /// No description provided for @defiWatchAdReplay.
  ///
  /// In fr, this message translates to:
  /// **'🎬 Regarder une pub pour rejouer'**
  String get defiWatchAdReplay;

  /// No description provided for @defiWatchAdBonus.
  ///
  /// In fr, this message translates to:
  /// **'🎬 Regarder une pub pour un autre défi'**
  String get defiWatchAdBonus;

  /// No description provided for @defiMoreComing.
  ///
  /// In fr, this message translates to:
  /// **'De nouvelles énigmes arrivent très vite'**
  String get defiMoreComing;

  /// No description provided for @defiBackHome.
  ///
  /// In fr, this message translates to:
  /// **'RETOUR À L\'ACCUEIL'**
  String get defiBackHome;

  /// No description provided for @enigmeIncomplete.
  ///
  /// In fr, this message translates to:
  /// **'Complète toutes les lettres avant de valider.'**
  String get enigmeIncomplete;

  /// No description provided for @enigmeNoAttempts.
  ///
  /// In fr, this message translates to:
  /// **'Plus de tentatives pour aujourd\'hui — reviens demain ou regarde une pub.'**
  String get enigmeNoAttempts;

  /// No description provided for @enigmeWrong.
  ///
  /// In fr, this message translates to:
  /// **'Ce n\'est pas ça — {n} tentative(s) restante(s) aujourd\'hui.'**
  String enigmeWrong(int n);

  /// No description provided for @enigmeAdLetterEarned.
  ///
  /// In fr, this message translates to:
  /// **'+1 lettre révélée !'**
  String get enigmeAdLetterEarned;

  /// No description provided for @enigmeAdAttemptEarned.
  ///
  /// In fr, this message translates to:
  /// **'+1 tentative pour aujourd\'hui !'**
  String get enigmeAdAttemptEarned;

  /// No description provided for @enigmeRule1.
  ///
  /// In fr, this message translates to:
  /// **'Une nouvelle énigme chaque semaine (lundi 00h00 GMT à dimanche 23h59 GMT), la même pour tous les joueurs.'**
  String get enigmeRule1;

  /// No description provided for @enigmeRule2.
  ///
  /// In fr, this message translates to:
  /// **'Le texte se révèle 1 lettre par heure, dans un ordre mélangé (pas celui du texte) — impossible de repérer où commencent ou finissent les mots avant de les avoir révélés.'**
  String get enigmeRule2;

  /// No description provided for @enigmeRule3.
  ///
  /// In fr, this message translates to:
  /// **'Devine le sujet (film, acteur ou personnage) avec les tuiles de lettres, comme dans le jeu principal.'**
  String get enigmeRule3;

  /// No description provided for @enigmeRule4.
  ///
  /// In fr, this message translates to:
  /// **'1 tentative gratuite par jour, plus jusqu\'à 5 en regardant une pub (1 tentative par pub).'**
  String get enigmeRule4;

  /// No description provided for @enigmeRule5.
  ///
  /// In fr, this message translates to:
  /// **'Une autre pub révèle 1 lettre de plus, jusqu\'à 5 fois par jour — indépendamment des tentatives.'**
  String get enigmeRule5;

  /// No description provided for @enigmeRule6.
  ///
  /// In fr, this message translates to:
  /// **'Aucun joker n\'est utilisable pendant l\'énigme.'**
  String get enigmeRule6;

  /// No description provided for @enigmeRewardsHeader.
  ///
  /// In fr, this message translates to:
  /// **'RÉCOMPENSES SELON LE JOUR'**
  String get enigmeRewardsHeader;

  /// No description provided for @enigmeRewardDayLabel.
  ///
  /// In fr, this message translates to:
  /// **'Jour {n}'**
  String enigmeRewardDayLabel(int n);

  /// No description provided for @enigmeReward1.
  ///
  /// In fr, this message translates to:
  /// **'1 joker de chaque type'**
  String get enigmeReward1;

  /// No description provided for @enigmeReward2.
  ///
  /// In fr, this message translates to:
  /// **'2 majeurs + 2 mineurs'**
  String get enigmeReward2;

  /// No description provided for @enigmeReward3.
  ///
  /// In fr, this message translates to:
  /// **'2 majeurs + 1 mineur'**
  String get enigmeReward3;

  /// No description provided for @enigmeReward4.
  ///
  /// In fr, this message translates to:
  /// **'1 majeur + 2 mineurs'**
  String get enigmeReward4;

  /// No description provided for @enigmeReward5.
  ///
  /// In fr, this message translates to:
  /// **'1 majeur'**
  String get enigmeReward5;

  /// No description provided for @enigmeReward6.
  ///
  /// In fr, this message translates to:
  /// **'2 mineurs'**
  String get enigmeReward6;

  /// No description provided for @enigmeReward7.
  ///
  /// In fr, this message translates to:
  /// **'1 mineur'**
  String get enigmeReward7;

  /// No description provided for @enigmeHistoryTitle.
  ///
  /// In fr, this message translates to:
  /// **'HISTORIQUE'**
  String get enigmeHistoryTitle;

  /// No description provided for @enigmeHistoryExplain.
  ///
  /// In fr, this message translates to:
  /// **'Le classement d\'une semaine repart à zéro dès le lundi suivant, mais tes résultats restent ici.'**
  String get enigmeHistoryExplain;

  /// No description provided for @enigmeBestRanking.
  ///
  /// In fr, this message translates to:
  /// **'🏆 Meilleur classement'**
  String get enigmeBestRanking;

  /// No description provided for @enigmeBestTimeLabel.
  ///
  /// In fr, this message translates to:
  /// **'⏱️ Meilleur temps'**
  String get enigmeBestTimeLabel;

  /// No description provided for @enigmeNoneSolved.
  ///
  /// In fr, this message translates to:
  /// **'Aucune énigme résolue pour l\'instant.'**
  String get enigmeNoneSolved;

  /// No description provided for @enigmeTitle.
  ///
  /// In fr, this message translates to:
  /// **'L\'ÉNIGME DE LA SEMAINE'**
  String get enigmeTitle;

  /// No description provided for @enigmeDayOf7.
  ///
  /// In fr, this message translates to:
  /// **'Jour {n} / 7'**
  String enigmeDayOf7(int n);

  /// No description provided for @enigmeYear.
  ///
  /// In fr, this message translates to:
  /// **'Année : {value}'**
  String enigmeYear(String value);

  /// No description provided for @enigmeAge.
  ///
  /// In fr, this message translates to:
  /// **'Âge : {value}'**
  String enigmeAge(String value);

  /// No description provided for @enigmeNextLetterIn.
  ///
  /// In fr, this message translates to:
  /// **'Prochaine lettre dévoilée dans {countdown}'**
  String enigmeNextLetterIn(String countdown);

  /// No description provided for @enigmeAttemptsLeft.
  ///
  /// In fr, this message translates to:
  /// **'{n} tentative(s) restante(s) aujourd\'hui'**
  String enigmeAttemptsLeft(int n);

  /// No description provided for @enigmeWatchAdLetter.
  ///
  /// In fr, this message translates to:
  /// **'🎬 Regarder une pub (+1 lettre)'**
  String get enigmeWatchAdLetter;

  /// No description provided for @enigmeWatchAdAttempt.
  ///
  /// In fr, this message translates to:
  /// **'🎬 Pub (+1 tentative)'**
  String get enigmeWatchAdAttempt;

  /// No description provided for @enigmeComeBackTomorrow.
  ///
  /// In fr, this message translates to:
  /// **'Reviens demain'**
  String get enigmeComeBackTomorrow;

  /// No description provided for @enigmeTopTenSnack.
  ///
  /// In fr, this message translates to:
  /// **'🔴 Top 10% mondial ! +1 Joker Rouge'**
  String get enigmeTopTenSnack;

  /// No description provided for @enigmeSolvedTitle.
  ///
  /// In fr, this message translates to:
  /// **'🎉 RÉSOLU !'**
  String get enigmeSolvedTitle;

  /// No description provided for @enigmeFoundIn.
  ///
  /// In fr, this message translates to:
  /// **'Trouvé en {time} (jour {day})'**
  String enigmeFoundIn(String time, int day);

  /// No description provided for @enigmeRewardLabel.
  ///
  /// In fr, this message translates to:
  /// **'Récompense : {labels}'**
  String enigmeRewardLabel(String labels);

  /// No description provided for @enigmeRankCalculating.
  ///
  /// In fr, this message translates to:
  /// **'🏆 Calcul du classement…'**
  String get enigmeRankCalculating;

  /// No description provided for @enigmeRankUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'🏆 Classement indisponible pour le moment'**
  String get enigmeRankUnavailable;

  /// No description provided for @enigmeRankingLine.
  ///
  /// In fr, this message translates to:
  /// **'{rank} sur {total} joueur(s)'**
  String enigmeRankingLine(String rank, int total);

  /// No description provided for @enigmeRankUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Classement indisponible'**
  String get enigmeRankUnknown;

  /// No description provided for @enigmeWeekOf.
  ///
  /// In fr, this message translates to:
  /// **'Semaine du {weekId} · jour {day} · {duration}'**
  String enigmeWeekOf(String weekId, int day, String duration);

  /// No description provided for @gameIncomplete.
  ///
  /// In fr, this message translates to:
  /// **'Remplis toutes les cases avant de valider (même au hasard) !'**
  String get gameIncomplete;

  /// No description provided for @gameWrong.
  ///
  /// In fr, this message translates to:
  /// **'Pas tout à fait... les mots corrects restent acquis !'**
  String get gameWrong;

  /// No description provided for @colorOrange.
  ///
  /// In fr, this message translates to:
  /// **'orange'**
  String get colorOrange;

  /// No description provided for @colorRed.
  ///
  /// In fr, this message translates to:
  /// **'rouge'**
  String get colorRed;

  /// No description provided for @colorPurple.
  ///
  /// In fr, this message translates to:
  /// **'violet'**
  String get colorPurple;

  /// No description provided for @gameOrangeIntro1.
  ///
  /// In fr, this message translates to:
  /// **'Les acteurs surlignés en '**
  String get gameOrangeIntro1;

  /// No description provided for @gameOrangeIntro2.
  ///
  /// In fr, this message translates to:
  /// **' ont joué un même rôle que l\'acteur à trouver (Ben Affleck a joué Batman, tout comme Christian Bale, Michael Keaton, George Clooney, etc...). Un nom orange ne peut pas être révélé directement : il faut d\'abord le faire passer en '**
  String get gameOrangeIntro2;

  /// No description provided for @gameOrangeIntro3.
  ///
  /// In fr, this message translates to:
  /// **' avec un Joker Rouge, puis utiliser les jokers Acteur/Personnage comme d\'habitude. Le Joker Rouge s\'obtient via une pub garantie (une fois par niveau concerné), en terminant dans le top 10% mondial de L\'énigme de la semaine, ou en boutique.'**
  String get gameOrangeIntro3;

  /// No description provided for @gameVioletIntro1.
  ///
  /// In fr, this message translates to:
  /// **'Si un nom est surligné en '**
  String get gameVioletIntro1;

  /// No description provided for @gameVioletIntro2.
  ///
  /// In fr, this message translates to:
  /// **', il s\'agit d\'un lien de parenté ou de proximité avec l\'acteur ou le personnage. Exemple : \"Le valet de Batman\" = Alfred = Michael Caine ou Andy Serkis, etc...'**
  String get gameVioletIntro2;

  /// No description provided for @gameTutorial1.
  ///
  /// In fr, this message translates to:
  /// **'Devine le nom du film à partir du texte suivant. Le nom affiché en 🟢 vert est le vrai personnage de ce film.'**
  String get gameTutorial1;

  /// No description provided for @gameTutorial2.
  ///
  /// In fr, this message translates to:
  /// **'Cette fois, le premier nom est en 🔵 bleu : c\'est le nom du véritable acteur qui a joué ce rôle. Le second nom reste en 🟢 vert : c\'est le vrai personnage de ce film.'**
  String get gameTutorial2;

  /// No description provided for @gameTutorial3.
  ///
  /// In fr, this message translates to:
  /// **'Cette fois, le premier nom est en 🔴 rouge : ce n\'est pas le bon personnage pour ce film, mais un rôle que le même acteur a joué ailleurs. Le nom en 🟢 vert reste le vrai personnage de ce film.'**
  String get gameTutorial3;

  /// No description provided for @gameDirectorLabel.
  ///
  /// In fr, this message translates to:
  /// **'🎬 LE RÉALISATEUR'**
  String get gameDirectorLabel;

  /// No description provided for @gameUnderstood.
  ///
  /// In fr, this message translates to:
  /// **'COMPRIS !'**
  String get gameUnderstood;

  /// No description provided for @gameJokerWon.
  ///
  /// In fr, this message translates to:
  /// **'JOKER GAGNÉ'**
  String get gameJokerWon;

  /// No description provided for @gameMinorBonusOffer.
  ///
  /// In fr, this message translates to:
  /// **'3 essais sans trouver... regarder une courte pub pour gagner un joker ?'**
  String get gameMinorBonusOffer;

  /// No description provided for @gameWatchAd.
  ///
  /// In fr, this message translates to:
  /// **'▶ Regarder la pub'**
  String get gameWatchAd;

  /// No description provided for @gameNoThanks.
  ///
  /// In fr, this message translates to:
  /// **'Non merci'**
  String get gameNoThanks;

  /// No description provided for @gameSkipLater.
  ///
  /// In fr, this message translates to:
  /// **'Passer, j\'y reviendrai'**
  String get gameSkipLater;

  /// No description provided for @gameSkipLastLevel.
  ///
  /// In fr, this message translates to:
  /// **'C\'est le dernier niveau de ce monde : il ne peut pas être gardé pour plus tard.'**
  String get gameSkipLastLevel;

  /// No description provided for @gameSkipForGood.
  ///
  /// In fr, this message translates to:
  /// **'Passer définitivement'**
  String get gameSkipForGood;

  /// No description provided for @gameSkipForGoodConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser 1 joker « Passer définitivement » ? Le niveau sera résolu et sa réponse révélée.'**
  String get gameSkipForGoodConfirm;

  /// No description provided for @gameSkipForGoodUse.
  ///
  /// In fr, this message translates to:
  /// **'UTILISER'**
  String get gameSkipForGoodUse;

  /// No description provided for @commonCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get commonCancel;

  /// No description provided for @gameJokerEarnedToast.
  ///
  /// In fr, this message translates to:
  /// **'🎁 Joker gagné : {label} !'**
  String gameJokerEarnedToast(String label);

  /// No description provided for @gameTutorialFinalTransition.
  ///
  /// In fr, this message translates to:
  /// **'Cher cinéphile, tu m\'as l\'air prêt à rentrer sur le plateau, voyons si tu as bien retenu ton texte...'**
  String get gameTutorialFinalTransition;

  /// No description provided for @gameTutorialComplete.
  ///
  /// In fr, this message translates to:
  /// **'Fin du tutoriel, maintenant à toi de jouer. Caméra, moteur..... Action !'**
  String get gameTutorialComplete;

  /// No description provided for @gameWorldCompleteBoth.
  ///
  /// In fr, this message translates to:
  /// **'🏆 Monde {world} terminé — Jokers gagnés : {major} + {minor} !'**
  String gameWorldCompleteBoth(String world, String major, String minor);

  /// No description provided for @gameWorldCompleteMajor.
  ///
  /// In fr, this message translates to:
  /// **'🏆 Monde {world} terminé — Joker gagné : {major} !'**
  String gameWorldCompleteMajor(String world, String major);

  /// No description provided for @gameAllContentComplete.
  ///
  /// In fr, this message translates to:
  /// **'Cher cinéphile, de nouveaux niveaux arrivent très vite.'**
  String get gameAllContentComplete;

  /// No description provided for @gameTutorialCategory.
  ///
  /// In fr, this message translates to:
  /// **'Tutoriel'**
  String get gameTutorialCategory;

  /// No description provided for @homeStreakDays.
  ///
  /// In fr, this message translates to:
  /// **'📅 {days} JOURS D\'AFFILÉE !'**
  String homeStreakDays(int days);

  /// No description provided for @homeStreakReward3.
  ///
  /// In fr, this message translates to:
  /// **'+1 indice 💡'**
  String get homeStreakReward3;

  /// No description provided for @homeStreakReward7.
  ///
  /// In fr, this message translates to:
  /// **'+1 joker rouge 🔴'**
  String get homeStreakReward7;

  /// No description provided for @homeStreakReward14.
  ///
  /// In fr, this message translates to:
  /// **'+1 de chaque joker classique'**
  String get homeStreakReward14;

  /// No description provided for @homeStreakReward28.
  ///
  /// In fr, this message translates to:
  /// **'Cycle complet ! +3 jokers rouges et +3 de chaque joker classique'**
  String get homeStreakReward28;

  /// No description provided for @homeGreat.
  ///
  /// In fr, this message translates to:
  /// **'SUPER !'**
  String get homeGreat;

  /// No description provided for @homePlay.
  ///
  /// In fr, this message translates to:
  /// **'JOUER'**
  String get homePlay;

  /// No description provided for @homeWeeklyPuzzle.
  ///
  /// In fr, this message translates to:
  /// **'🧩 L\'ÉNIGME DE LA SEMAINE'**
  String get homeWeeklyPuzzle;

  /// No description provided for @homeDailyChallenge.
  ///
  /// In fr, this message translates to:
  /// **'🎯 DÉFI DU JOUR'**
  String get homeDailyChallenge;

  /// No description provided for @homeMultiplayer.
  ///
  /// In fr, this message translates to:
  /// **'⚔️ MULTIJOUEUR'**
  String get homeMultiplayer;

  /// No description provided for @homeShop.
  ///
  /// In fr, this message translates to:
  /// **'🛒 Boutique'**
  String get homeShop;

  /// No description provided for @homeHelp.
  ///
  /// In fr, this message translates to:
  /// **'❓ Aide'**
  String get homeHelp;

  /// No description provided for @homeTagline.
  ///
  /// In fr, this message translates to:
  /// **'RETROUVE LE FILM DERRIÈRE LE PITCH'**
  String get homeTagline;

  /// No description provided for @homeChooseAvatar.
  ///
  /// In fr, this message translates to:
  /// **'CHOISIS TON AVATAR'**
  String get homeChooseAvatar;

  /// No description provided for @homeYourId.
  ///
  /// In fr, this message translates to:
  /// **'TON IDENTIFIANT'**
  String get homeYourId;

  /// No description provided for @homeYourNickname.
  ///
  /// In fr, this message translates to:
  /// **'Ton pseudo'**
  String get homeYourNickname;

  /// No description provided for @jokerReveal.
  ///
  /// In fr, this message translates to:
  /// **'RÉVÉLER'**
  String get jokerReveal;

  /// No description provided for @jokerEliminate.
  ///
  /// In fr, this message translates to:
  /// **'ÉLIMINER'**
  String get jokerEliminate;

  /// No description provided for @jokerActor.
  ///
  /// In fr, this message translates to:
  /// **'ACTEUR'**
  String get jokerActor;

  /// No description provided for @jokerCharacter.
  ///
  /// In fr, this message translates to:
  /// **'PERSONNAGE'**
  String get jokerCharacter;

  /// No description provided for @jokerHint.
  ///
  /// In fr, this message translates to:
  /// **'INDICE'**
  String get jokerHint;

  /// No description provided for @jokerRevealWord.
  ///
  /// In fr, this message translates to:
  /// **'RÉVÉLER UN MOT'**
  String get jokerRevealWord;

  /// No description provided for @jokerRedCharacter.
  ///
  /// In fr, this message translates to:
  /// **'PERSONNAGE (ROUGE)'**
  String get jokerRedCharacter;

  /// No description provided for @jokerWinOne.
  ///
  /// In fr, this message translates to:
  /// **'GAGNER UN JOKER'**
  String get jokerWinOne;

  /// No description provided for @jokerHintUsedSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'utilisé · 🎬'**
  String get jokerHintUsedSubtitle;

  /// No description provided for @jokerLockedSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'verrouillé'**
  String get jokerLockedSubtitle;

  /// No description provided for @jokerAdUnlockSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'🎬 pub → joker'**
  String get jokerAdUnlockSubtitle;

  /// No description provided for @jokerRedLockedToast.
  ///
  /// In fr, this message translates to:
  /// **'Plus de joker rouge pour aujourd\'hui sur ce niveau — obtiens-en via le top 10% mondial de L\'énigme de la semaine ou dans la boutique.'**
  String get jokerRedLockedToast;

  /// No description provided for @pitchDifferentColorHint.
  ///
  /// In fr, this message translates to:
  /// **'Touche un nom dont la couleur est différente du joker choisi.'**
  String get pitchDifferentColorHint;

  /// No description provided for @resultInFilm.
  ///
  /// In fr, this message translates to:
  /// **', dans {film}'**
  String resultInFilm(String film);

  /// No description provided for @resultSeeFilmSheet.
  ///
  /// In fr, this message translates to:
  /// **'Voir la fiche du film'**
  String get resultSeeFilmSheet;

  /// No description provided for @resultNextFilm.
  ///
  /// In fr, this message translates to:
  /// **'SUIVANT'**
  String get resultNextFilm;

  /// No description provided for @worldComplete.
  ///
  /// In fr, this message translates to:
  /// **'MONDE TERMINÉ !'**
  String get worldComplete;

  /// No description provided for @worldChooseNext.
  ///
  /// In fr, this message translates to:
  /// **'Choisis le prochain monde'**
  String get worldChooseNext;

  /// No description provided for @worldNumber.
  ///
  /// In fr, this message translates to:
  /// **'MONDE {n}'**
  String worldNumber(int n);

  /// No description provided for @worldStartHint.
  ///
  /// In fr, this message translates to:
  /// **'Indice de départ : les {count} prochaines devinettes appartiennent à cette catégorie.'**
  String worldStartHint(int count);

  /// No description provided for @instructionsTitle.
  ///
  /// In fr, this message translates to:
  /// **'COMMENT JOUER'**
  String get instructionsTitle;

  /// No description provided for @instructionsIntro.
  ///
  /// In fr, this message translates to:
  /// **'Devine le titre du film à partir d\'un pitch dont les personnages sont désignés par des noms \"masqués\". Utilise les jokers pour t\'aider, puis reconstitue le titre lettre par lettre.'**
  String get instructionsIntro;

  /// No description provided for @instructionsColorsHeader.
  ///
  /// In fr, this message translates to:
  /// **'SIGNIFICATION DES COULEURS'**
  String get instructionsColorsHeader;

  /// No description provided for @instrColorGreen.
  ///
  /// In fr, this message translates to:
  /// **'Vert'**
  String get instrColorGreen;

  /// No description provided for @instrColorRed.
  ///
  /// In fr, this message translates to:
  /// **'Rouge'**
  String get instrColorRed;

  /// No description provided for @instrColorBlue.
  ///
  /// In fr, this message translates to:
  /// **'Bleu'**
  String get instrColorBlue;

  /// No description provided for @instrColorOrange.
  ///
  /// In fr, this message translates to:
  /// **'Orange'**
  String get instrColorOrange;

  /// No description provided for @instrColorViolet.
  ///
  /// In fr, this message translates to:
  /// **'Violet'**
  String get instrColorViolet;

  /// No description provided for @instructionsLegendGreen.
  ///
  /// In fr, this message translates to:
  /// **'Le vrai nom du personnage dans ce film.'**
  String get instructionsLegendGreen;

  /// No description provided for @instructionsLegendRed.
  ///
  /// In fr, this message translates to:
  /// **'Un personnage d\'un AUTRE film joué par le même acteur — un piège.'**
  String get instructionsLegendRed;

  /// No description provided for @instructionsLegendBlue.
  ///
  /// In fr, this message translates to:
  /// **'Le nom du véritable acteur.'**
  String get instructionsLegendBlue;

  /// No description provided for @instructionsLegendOrange.
  ///
  /// In fr, this message translates to:
  /// **'Un AUTRE acteur ayant joué le même rôle ailleurs — ne peut pas être révélé directement, il faut d\'abord le faire passer en rouge avec un Joker Rouge.'**
  String get instructionsLegendOrange;

  /// No description provided for @instructionsLegendViolet.
  ///
  /// In fr, this message translates to:
  /// **'Un lien de parenté ou de proximité avec l\'acteur ou le personnage.'**
  String get instructionsLegendViolet;

  /// No description provided for @instructionsJokersHeader.
  ///
  /// In fr, this message translates to:
  /// **'LES JOKERS'**
  String get instructionsJokersHeader;

  /// No description provided for @instructionsMinorHeader.
  ///
  /// In fr, this message translates to:
  /// **'Mineurs'**
  String get instructionsMinorHeader;

  /// No description provided for @instructionsMajorHeader.
  ///
  /// In fr, this message translates to:
  /// **'Majeurs'**
  String get instructionsMajorHeader;

  /// No description provided for @instructionsSpecialHeader.
  ///
  /// In fr, this message translates to:
  /// **'Spécial'**
  String get instructionsSpecialHeader;

  /// No description provided for @instrJokerRevealLabel.
  ///
  /// In fr, this message translates to:
  /// **'Révéler'**
  String get instrJokerRevealLabel;

  /// No description provided for @instrJokerRevealDesc.
  ///
  /// In fr, this message translates to:
  /// **'Révèle une lettre au hasard dans la grille de réponse.'**
  String get instrJokerRevealDesc;

  /// No description provided for @instrJokerEliminateLabel.
  ///
  /// In fr, this message translates to:
  /// **'Éliminer'**
  String get instrJokerEliminateLabel;

  /// No description provided for @instrJokerEliminateDesc.
  ///
  /// In fr, this message translates to:
  /// **'Retire 3 lettres leurres (fausses) de la réserve de lettres.'**
  String get instrJokerEliminateDesc;

  /// No description provided for @instrJokerCharacterLabel.
  ///
  /// In fr, this message translates to:
  /// **'Personnage'**
  String get instrJokerCharacterLabel;

  /// No description provided for @instrJokerCharacterDesc.
  ///
  /// In fr, this message translates to:
  /// **'Affiche le vrai nom du personnage à la place d\'un nom masqué.'**
  String get instrJokerCharacterDesc;

  /// No description provided for @instrJokerActorLabel.
  ///
  /// In fr, this message translates to:
  /// **'Acteur'**
  String get instrJokerActorLabel;

  /// No description provided for @instrJokerActorDesc.
  ///
  /// In fr, this message translates to:
  /// **'Affiche le nom du véritable acteur à la place d\'un nom masqué.'**
  String get instrJokerActorDesc;

  /// No description provided for @instrJokerHintLabel.
  ///
  /// In fr, this message translates to:
  /// **'Indice'**
  String get instrJokerHintLabel;

  /// No description provided for @instrJokerHintDesc.
  ///
  /// In fr, this message translates to:
  /// **'Révèle un indice supplémentaire sur le film, affiché sous le pitch.'**
  String get instrJokerHintDesc;

  /// No description provided for @instrJokerRevealWordLabel.
  ///
  /// In fr, this message translates to:
  /// **'Révéler un mot'**
  String get instrJokerRevealWordLabel;

  /// No description provided for @instrJokerRevealWordDesc.
  ///
  /// In fr, this message translates to:
  /// **'Révèle un mot entier de la réponse (ou un tiers des lettres si le titre n\'a qu\'un seul mot).'**
  String get instrJokerRevealWordDesc;

  /// No description provided for @instrJokerRedLabel.
  ///
  /// In fr, this message translates to:
  /// **'Personnage (rouge)'**
  String get instrJokerRedLabel;

  /// No description provided for @instrJokerRedDesc.
  ///
  /// In fr, this message translates to:
  /// **'Fait passer un nom orange en rouge (les jokers Acteur/Personnage prennent ensuite le relais normalement). N\'apparaît que sur les énigmes avec un nom orange. S\'obtient de 3 façons : une pub garantie (une fois par niveau concerné), le top 10% mondial de L\'énigme de la semaine, ou la boutique.'**
  String get instrJokerRedDesc;

  /// No description provided for @streakCalendarTitle.
  ///
  /// In fr, this message translates to:
  /// **'📅 CALENDRIER DE SÉRIE'**
  String get streakCalendarTitle;

  /// No description provided for @streakCalendarSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'{streak} jour(s) d\'affilée — jour {jour} sur {total}'**
  String streakCalendarSubtitle(int streak, int jour, int total);

  /// No description provided for @streakCalendarEventLine.
  ///
  /// In fr, this message translates to:
  /// **'{emoji} Jour {day} — {label} ({date}) : bonus supplémentaire !'**
  String streakCalendarEventLine(
      String emoji, int day, String label, String date);

  /// No description provided for @streakLegendMinor.
  ///
  /// In fr, this message translates to:
  /// **'Bonus mineur — 1 joker Indice'**
  String get streakLegendMinor;

  /// No description provided for @streakLegendMajor.
  ///
  /// In fr, this message translates to:
  /// **'Bonus majeur — jours {days}'**
  String streakLegendMajor(String days);

  /// No description provided for @streakLegendCycle.
  ///
  /// In fr, this message translates to:
  /// **'Cycle complet — jour {n}, bonus majeur ×3'**
  String streakLegendCycle(int n);

  /// No description provided for @streakLegendEvent.
  ///
  /// In fr, this message translates to:
  /// **'Grand événement du cinéma — bonus en plus de celui du jour'**
  String get streakLegendEvent;

  /// No description provided for @mpTitle.
  ///
  /// In fr, this message translates to:
  /// **'MULTIJOUEUR'**
  String get mpTitle;

  /// No description provided for @mpAdMatchEarned.
  ///
  /// In fr, this message translates to:
  /// **'+1 partie pour aujourd\'hui !'**
  String get mpAdMatchEarned;

  /// No description provided for @mpHistoryLastMatches.
  ///
  /// In fr, this message translates to:
  /// **'Les {n} derniers matchs.'**
  String mpHistoryLastMatches(int n);

  /// No description provided for @mpNoMatchYet.
  ///
  /// In fr, this message translates to:
  /// **'Aucun match joué pour l\'instant.'**
  String get mpNoMatchYet;

  /// No description provided for @mpRule1.
  ///
  /// In fr, this message translates to:
  /// **'Match au meilleur des 3 manches (victoire dès 2 points), 45 à 75 secondes par manche selon la longueur de la réponse.'**
  String get mpRule1;

  /// No description provided for @mpRule2.
  ///
  /// In fr, this message translates to:
  /// **'L\'indice se révèle lettre par lettre, toutes les lettres visibles pile à 35 secondes.'**
  String get mpRule2;

  /// No description provided for @mpRule3.
  ///
  /// In fr, this message translates to:
  /// **'Le premier des deux à trouver la bonne réponse gagne la manche. Si personne ne trouve à temps, vous gagnez tous les deux le point.'**
  String get mpRule3;

  /// No description provided for @mpRule4.
  ///
  /// In fr, this message translates to:
  /// **'Un match peut donc finir nul (2-2 en seulement 2 manches).'**
  String get mpRule4;

  /// No description provided for @mpRule5.
  ///
  /// In fr, this message translates to:
  /// **'Ton classement Elo évolue à la fin de chaque match.'**
  String get mpRule5;

  /// No description provided for @mpRule6.
  ///
  /// In fr, this message translates to:
  /// **'5 parties par jour, se réinitialise à 0h00 GMT.'**
  String get mpRule6;

  /// No description provided for @mpYourRank.
  ///
  /// In fr, this message translates to:
  /// **'Votre rang'**
  String get mpYourRank;

  /// No description provided for @mpTopPercent.
  ///
  /// In fr, this message translates to:
  /// **'Vous êtes dans le top {pct} % mondial'**
  String mpTopPercent(String pct);

  /// No description provided for @mpChallengePlayer.
  ///
  /// In fr, this message translates to:
  /// **'⚔️ AFFRONTER UN JOUEUR'**
  String get mpChallengePlayer;

  /// No description provided for @mpWatchAdForMatch.
  ///
  /// In fr, this message translates to:
  /// **'🎬 Regarder une pub pour +1 partie ({watched}/{max})'**
  String mpWatchAdForMatch(int watched, int max);

  /// No description provided for @mpComeBackTomorrow.
  ///
  /// In fr, this message translates to:
  /// **'Reviens demain pour de nouvelles parties !'**
  String get mpComeBackTomorrow;

  /// No description provided for @mpMatchesLeft.
  ///
  /// In fr, this message translates to:
  /// **'{n} partie(s) restante(s) aujourd\'hui'**
  String mpMatchesLeft(int n);

  /// No description provided for @mpQuotaReached.
  ///
  /// In fr, this message translates to:
  /// **'Quota du jour atteint'**
  String get mpQuotaReached;

  /// No description provided for @mpHistoryButton.
  ///
  /// In fr, this message translates to:
  /// **'📜 HISTORIQUE'**
  String get mpHistoryButton;

  /// No description provided for @mpWin.
  ///
  /// In fr, this message translates to:
  /// **'Victoire'**
  String get mpWin;

  /// No description provided for @mpLoss.
  ///
  /// In fr, this message translates to:
  /// **'Défaite'**
  String get mpLoss;

  /// No description provided for @mpDraw.
  ///
  /// In fr, this message translates to:
  /// **'Nul'**
  String get mpDraw;

  /// No description provided for @mpRoundLabel.
  ///
  /// In fr, this message translates to:
  /// **'MANCHE'**
  String get mpRoundLabel;

  /// No description provided for @mpTimeLabel.
  ///
  /// In fr, this message translates to:
  /// **'TEMPS'**
  String get mpTimeLabel;

  /// No description provided for @mpYou.
  ///
  /// In fr, this message translates to:
  /// **'Vous'**
  String get mpYou;

  /// No description provided for @mpOpponentFallback.
  ///
  /// In fr, this message translates to:
  /// **'Adversaire'**
  String get mpOpponentFallback;

  /// No description provided for @mpRoundsWon.
  ///
  /// In fr, this message translates to:
  /// **'🏅 {n} manche(s)'**
  String mpRoundsWon(int n);

  /// No description provided for @mpRoundWon.
  ///
  /// In fr, this message translates to:
  /// **'🎉 Manche gagnée !'**
  String get mpRoundWon;

  /// No description provided for @mpRoundLost.
  ///
  /// In fr, this message translates to:
  /// **'😔 Ton adversaire a trouvé le premier.'**
  String get mpRoundLost;

  /// No description provided for @mpRoundTie.
  ///
  /// In fr, this message translates to:
  /// **'🤝 Personne n\'a trouvé — vous gagnez tous les deux le point.'**
  String get mpRoundTie;

  /// No description provided for @mpMatchWin.
  ///
  /// In fr, this message translates to:
  /// **'🏆 VICTOIRE'**
  String get mpMatchWin;

  /// No description provided for @mpMatchLoss.
  ///
  /// In fr, this message translates to:
  /// **'😔 DÉFAITE'**
  String get mpMatchLoss;

  /// No description provided for @mpMatchDraw.
  ///
  /// In fr, this message translates to:
  /// **'🤝 MATCH NUL'**
  String get mpMatchDraw;

  /// No description provided for @mpNewTitle.
  ///
  /// In fr, this message translates to:
  /// **'✨ Nouveau titre !'**
  String get mpNewTitle;

  /// No description provided for @mpReplay.
  ///
  /// In fr, this message translates to:
  /// **'REJOUER'**
  String get mpReplay;

  /// No description provided for @mpQuotaReachedFull.
  ///
  /// In fr, this message translates to:
  /// **'Quota du jour atteint — reviens demain !'**
  String get mpQuotaReachedFull;

  /// No description provided for @shopTitle.
  ///
  /// In fr, this message translates to:
  /// **'BOUTIQUE'**
  String get shopTitle;

  /// No description provided for @shopUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Boutique indisponible pour le moment.'**
  String get shopUnavailable;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
