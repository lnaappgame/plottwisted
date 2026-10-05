// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Plot Twist(ed)';

  @override
  String get settingsTitle => 'SETTINGS';

  @override
  String get settingsLightMode => '🌗 Light mode';

  @override
  String get settingsSfx => '🔊 Sound effects';

  @override
  String get settingsVibrations => '📳 Vibrations';

  @override
  String get settingsColorblind => '👁️ Colorblind mode';

  @override
  String get settingsDyslexic => '📖 Dyslexia-friendly mode';

  @override
  String get settingsTextSize => '🔎 Text size';

  @override
  String get settingsTextSizeSmall => 'Small';

  @override
  String get settingsTextSizeLarge => 'Large';

  @override
  String get settingsLanguage => '🌐 Language';

  @override
  String get settingsLanguageFrench => 'Français';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsAdPrivacy => '🔒 Ad privacy options';

  @override
  String get settingsCgu => 'Terms of Use';

  @override
  String get settingsPrivacyPolicy => 'Privacy Policy';

  @override
  String get settingsResetSave => '🗑️ RESET SAVE DATA';

  @override
  String get settingsClose => 'CLOSE';

  @override
  String settingsAccountLinked(String email) {
    return '✅ Account linked: $email';
  }

  @override
  String get settingsAccountLocalOnly =>
      '☁️ Progress saved only on this device';

  @override
  String get settingsSaveWithGoogle => '🔗 Save with Google';

  @override
  String get settingsSaveNow => '🔄 Save now';

  @override
  String get settingsGoogleLinkedSnack =>
      '✅ Google account linked. Your progress is saved.';

  @override
  String get settingsGoogleLinkedNoBackupSnack =>
      'Google account linked, but no backup found.';

  @override
  String get settingsGoogleErrorSnack =>
      '⚠️ Connection failed. Try again later.';

  @override
  String get settingsBackupUpToDateSnack => '✅ Backup up to date.';

  @override
  String get settingsBackupFailedSnack => '⚠️ Backup failed. Try again later.';

  @override
  String get settingsRestoreTitle => '☁️ Progress restored';

  @override
  String get settingsRestoreBody =>
      'Your backup was found! Fully close the app then reopen it to see it appear.';

  @override
  String get settingsUnderstood => 'GOT IT';

  @override
  String get settingsNoPrivacyNeeded => 'Nothing to configure for your region.';

  @override
  String get settingsResetConfirm1Title => '⚠️ Reset save data?';

  @override
  String get settingsResetConfirm1Body =>
      'All your progress (worlds, levels, jokers) will be lost.';

  @override
  String get settingsResetConfirm1Cta => 'Continue';

  @override
  String get settingsCancel => 'Cancel';

  @override
  String get settingsResetConfirm2Title => '⚠️ Are you sure?';

  @override
  String get settingsResetConfirm2Body =>
      'This action is permanent: the save will be deleted and the game will start over.';

  @override
  String get settingsResetConfirm2Cta => 'Reset';

  @override
  String get commonRulesTitle => 'GAME RULES';

  @override
  String get commonClose => 'CLOSE';

  @override
  String get commonLoading => 'Loading…';

  @override
  String get commonAdUnavailable =>
      'Ad unavailable right now, try again later.';

  @override
  String get commonClear => 'CLEAR';

  @override
  String get commonValidate => 'SUBMIT';

  @override
  String get commonDayAbbr => 'd';

  @override
  String get defiTitle => 'DAILY CHALLENGE';

  @override
  String get defiRule1 =>
      'A different theme (\"topic\") every day, the same for every player.';

  @override
  String get defiRule2 =>
      'All the answer tiles are visible from the start. A dedicated clue is shown for each one, once, in a fixed order.';

  @override
  String get defiRule3 => 'Tap the tile that matches the clue shown.';

  @override
  String get defiRule4 =>
      'Correct answer: the tile disappears, next clue. Wrong answer: +5 seconds penalty, the tile stays, next clue anyway.';

  @override
  String get defiRule5 =>
      'The clock runs from the first \"Start\" until the last clue.';

  @override
  String get defiRule6 =>
      'An ad lets you replay the same challenge (to beat your record) or try another topic you\'ve never played.';

  @override
  String defiCasesInfo(int count) {
    return '$count answer tiles, $count clues — tap the tile that matches the clue shown.';
  }

  @override
  String defiBestTime(String time) {
    return '⏱️ Your best time: $time';
  }

  @override
  String get defiStart => 'START';

  @override
  String get defiCompleted => '🎉 CHALLENGE COMPLETE!';

  @override
  String get defiBonusLabel => 'Bonus challenge';

  @override
  String get defiTimeReal => 'Actual time';

  @override
  String get defiTimePenalties => 'Penalties';

  @override
  String get defiTimeTotal => 'Total time';

  @override
  String get defiNewRecord => '🏆 New personal record!';

  @override
  String defiBestTimeResult(String time) {
    return '⏱️ Best time: $time';
  }

  @override
  String get defiWatchAdReplay => '🎬 Watch an ad to replay';

  @override
  String get defiWatchAdBonus => '🎬 Watch an ad for another challenge';

  @override
  String get defiMoreComing => 'New puzzles are coming very soon';

  @override
  String get defiBackHome => 'BACK TO HOME';

  @override
  String get enigmeIncomplete => 'Fill in every letter before submitting.';

  @override
  String get enigmeNoAttempts =>
      'No more attempts for today — come back tomorrow or watch an ad.';

  @override
  String enigmeWrong(int n) {
    return 'That\'s not it — $n attempt(s) left today.';
  }

  @override
  String get enigmeAdLetterEarned => '+1 letter revealed!';

  @override
  String get enigmeAdAttemptEarned => '+1 attempt for today!';

  @override
  String get enigmeRule1 =>
      'A new puzzle every week (Monday 00:00 GMT to Sunday 23:59 GMT), the same for every player.';

  @override
  String get enigmeRule2 =>
      'The text is revealed 1 letter per hour, in a shuffled order (not the text\'s own order) — impossible to spot where words start or end before revealing them.';

  @override
  String get enigmeRule3 =>
      'Guess the subject (film, actor or character) with the letter tiles, just like the main game.';

  @override
  String get enigmeRule4 =>
      '1 free attempt per day, plus up to 5 more by watching an ad (1 attempt per ad).';

  @override
  String get enigmeRule5 =>
      'Another ad reveals 1 more letter, up to 5 times per day — independent of attempts.';

  @override
  String get enigmeRule6 => 'No joker can be used during the puzzle.';

  @override
  String get enigmeRewardsHeader => 'REWARDS BY DAY';

  @override
  String enigmeRewardDayLabel(int n) {
    return 'Day $n';
  }

  @override
  String get enigmeReward1 => '1 joker of each type';

  @override
  String get enigmeReward2 => '2 major + 2 minor';

  @override
  String get enigmeReward3 => '2 major + 1 minor';

  @override
  String get enigmeReward4 => '1 major + 2 minor';

  @override
  String get enigmeReward5 => '1 major';

  @override
  String get enigmeReward6 => '2 minor';

  @override
  String get enigmeReward7 => '1 minor';

  @override
  String get enigmeHistoryTitle => 'HISTORY';

  @override
  String get enigmeHistoryExplain =>
      'A week\'s ranking resets to zero the following Monday, but your results stay here.';

  @override
  String get enigmeBestRanking => '🏆 Best ranking';

  @override
  String get enigmeBestTimeLabel => '⏱️ Best time';

  @override
  String get enigmeNoneSolved => 'No puzzle solved yet.';

  @override
  String get enigmeTitle => 'WEEKLY PUZZLE';

  @override
  String enigmeDayOf7(int n) {
    return 'Day $n / 7';
  }

  @override
  String enigmeYear(String value) {
    return 'Year: $value';
  }

  @override
  String enigmeAge(String value) {
    return 'Age: $value';
  }

  @override
  String enigmeNextLetterIn(String countdown) {
    return 'Next letter revealed in $countdown';
  }

  @override
  String enigmeAttemptsLeft(int n) {
    return '$n attempt(s) left today';
  }

  @override
  String get enigmeWatchAdLetter => '🎬 Watch an ad (+1 letter)';

  @override
  String get enigmeWatchAdAttempt => '🎬 Ad (+1 attempt)';

  @override
  String get enigmeComeBackTomorrow => 'Come back tomorrow';

  @override
  String get enigmeTopTenSnack => '🔴 Global top 10%! +1 Red Joker';

  @override
  String get enigmeSolvedTitle => '🎉 SOLVED!';

  @override
  String enigmeFoundIn(String time, int day) {
    return 'Found in $time (day $day)';
  }

  @override
  String enigmeRewardLabel(String labels) {
    return 'Reward: $labels';
  }

  @override
  String get enigmeRankCalculating => '🏆 Calculating ranking…';

  @override
  String get enigmeRankUnavailable => '🏆 Ranking unavailable right now';

  @override
  String enigmeRankingLine(String rank, int total) {
    return '$rank of $total player(s)';
  }

  @override
  String get enigmeRankUnknown => 'Ranking unavailable';

  @override
  String enigmeWeekOf(String weekId, int day, String duration) {
    return 'Week of $weekId · day $day · $duration';
  }

  @override
  String get gameIncomplete =>
      'Fill in every tile before submitting (even a guess)!';

  @override
  String get gameWrong => 'Not quite... the correct words stay locked in!';

  @override
  String get colorOrange => 'orange';

  @override
  String get colorRed => 'red';

  @override
  String get colorPurple => 'purple';

  @override
  String get gameOrangeIntro1 => 'Actors highlighted in ';

  @override
  String get gameOrangeIntro2 =>
      ' played the same role as the actor you\'re looking for (Ben Affleck played Batman, just like Christian Bale, Michael Keaton, George Clooney, etc...). An orange name can\'t be revealed directly: you first need to turn it ';

  @override
  String get gameOrangeIntro3 =>
      ' using a Red Joker, then use the Actor/Character jokers as usual. The Red Joker is earned via a guaranteed ad (once per level concerned), by finishing in the global top 10% of the weekly puzzle, or in the shop.';

  @override
  String get gameVioletIntro1 => 'If a name is highlighted in ';

  @override
  String get gameVioletIntro2 =>
      ', it\'s a family or close relationship with the actor or character. Example: \"Batman\'s butler\" = Alfred = Michael Caine or Andy Serkis, etc...';

  @override
  String get gameTutorial1 =>
      'Guess the name of the film from the text below. The name shown in 🟢 green is the real character in this film.';

  @override
  String get gameTutorial2 =>
      'This time, the first name is in 🔵 blue: it\'s the name of the real actor who played this role. The second name stays 🟢 green: it\'s the real character in this film.';

  @override
  String get gameTutorial3 =>
      'This time, the first name is in 🔴 red: it\'s not the right character for this film, but a role the same actor played elsewhere. The name in 🟢 green stays the real character in this film.';

  @override
  String get gameDirectorLabel => '🎬 THE DIRECTOR';

  @override
  String get gameUnderstood => 'GOT IT!';

  @override
  String get gameJokerWon => 'JOKER WON';

  @override
  String get gameMinorBonusOffer =>
      '3 tries without finding it... watch a short ad to win a joker?';

  @override
  String get gameWatchAd => '▶ Watch the ad';

  @override
  String get gameNoThanks => 'No thanks';

  @override
  String get gameSkipLater => 'Skip, come back later';

  @override
  String get gameSkipLastLevel =>
      'This is the last level of this world, so it can\'t be saved for later.';

  @override
  String get gameSkipForGood => 'Skip for good';

  @override
  String get gameSkipForGoodConfirm =>
      'Use 1 \"Skip for good\" joker? The level will be solved and its answer revealed.';

  @override
  String get gameSkipForGoodUse => 'USE';

  @override
  String get commonCancel => 'Cancel';

  @override
  String gameJokerEarnedToast(String label) {
    return '🎁 Joker won: $label!';
  }

  @override
  String get gameTutorialFinalTransition =>
      'Dear film buff, you look ready to step onto the set — let\'s see if you\'ve learned your lines...';

  @override
  String get gameTutorialComplete =>
      'End of tutorial, now it\'s your turn to play. Camera, rolling..... Action!';

  @override
  String gameWorldCompleteBoth(String world, String major, String minor) {
    return '🏆 World $world complete — Jokers won: $major + $minor!';
  }

  @override
  String gameWorldCompleteMajor(String world, String major) {
    return '🏆 World $world complete — Joker won: $major!';
  }

  @override
  String get gameAllContentComplete =>
      'Dear cinephile, new levels are coming very soon.';

  @override
  String get gameTutorialCategory => 'Tutorial';

  @override
  String homeStreakDays(int days) {
    return '📅 $days DAY STREAK!';
  }

  @override
  String get homeStreakReward3 => '+1 hint 💡';

  @override
  String get homeStreakReward7 => '+1 red joker 🔴';

  @override
  String get homeStreakReward14 => '+1 of each classic joker';

  @override
  String get homeStreakReward28 =>
      'Full cycle! +3 red jokers and +3 of each classic joker';

  @override
  String get homeGreat => 'AWESOME!';

  @override
  String get homePlay => 'PLAY';

  @override
  String get homeWeeklyPuzzle => '🧩 WEEKLY PUZZLE';

  @override
  String get homeDailyChallenge => '🎯 DAILY CHALLENGE';

  @override
  String get homeMultiplayer => '⚔️ MULTIPLAYER';

  @override
  String get homeShop => '🛒 Shop';

  @override
  String get homeHelp => '❓ Help';

  @override
  String get homeTagline => 'GUESS THE FILM BEHIND THE PITCH';

  @override
  String get homeChooseAvatar => 'CHOOSE YOUR AVATAR';

  @override
  String get homeYourId => 'YOUR ID';

  @override
  String get homeYourNickname => 'Your nickname';

  @override
  String get jokerReveal => 'REVEAL';

  @override
  String get jokerEliminate => 'ELIMINATE';

  @override
  String get jokerActor => 'ACTOR';

  @override
  String get jokerCharacter => 'CHARACTER';

  @override
  String get jokerHint => 'HINT';

  @override
  String get jokerRevealWord => 'REVEAL A WORD';

  @override
  String get jokerRedCharacter => 'CHARACTER (RED)';

  @override
  String get jokerWinOne => 'WIN A JOKER';

  @override
  String get jokerHintUsedSubtitle => 'used · 🎬';

  @override
  String get jokerLockedSubtitle => 'locked';

  @override
  String get jokerAdUnlockSubtitle => '🎬 ad → joker';

  @override
  String get jokerRedLockedToast =>
      'No more red jokers for today on this level — earn one via the weekly puzzle\'s global top 10%, or in the shop.';

  @override
  String get pitchDifferentColorHint =>
      'Tap a name whose color is different from the joker you selected.';

  @override
  String resultInFilm(String film) {
    return ', in $film';
  }

  @override
  String get resultSeeFilmSheet => 'See the film page';

  @override
  String get resultNextFilm => 'NEXT';

  @override
  String get worldComplete => 'WORLD COMPLETE!';

  @override
  String get worldChooseNext => 'Choose the next world';

  @override
  String worldNumber(int n) {
    return 'WORLD $n';
  }

  @override
  String worldStartHint(int count) {
    return 'Starting hint: the next $count puzzles belong to this category.';
  }

  @override
  String get instructionsTitle => 'HOW TO PLAY';

  @override
  String get instructionsIntro =>
      'Guess the film\'s title from a pitch where the characters are given \"masked\" names. Use the jokers to help you, then rebuild the title letter by letter.';

  @override
  String get instructionsColorsHeader => 'WHAT THE COLORS MEAN';

  @override
  String get instrColorGreen => 'Green';

  @override
  String get instrColorRed => 'Red';

  @override
  String get instrColorBlue => 'Blue';

  @override
  String get instrColorOrange => 'Orange';

  @override
  String get instrColorViolet => 'Purple';

  @override
  String get instructionsLegendGreen =>
      'The real name of the character in this film.';

  @override
  String get instructionsLegendRed =>
      'A character from an OTHER film played by the same actor — a trap.';

  @override
  String get instructionsLegendBlue => 'The name of the real actor.';

  @override
  String get instructionsLegendOrange =>
      'ANOTHER actor who played the same role elsewhere — can\'t be revealed directly, you first need to turn it red with a Red Joker.';

  @override
  String get instructionsLegendViolet =>
      'A family or close relationship with the actor or character.';

  @override
  String get instructionsJokersHeader => 'THE JOKERS';

  @override
  String get instructionsMinorHeader => 'Minor';

  @override
  String get instructionsMajorHeader => 'Major';

  @override
  String get instructionsSpecialHeader => 'Special';

  @override
  String get instrJokerRevealLabel => 'Reveal';

  @override
  String get instrJokerRevealDesc =>
      'Reveals a random letter in the answer grid.';

  @override
  String get instrJokerEliminateLabel => 'Eliminate';

  @override
  String get instrJokerEliminateDesc =>
      'Removes 3 decoy (fake) letters from the letter pool.';

  @override
  String get instrJokerCharacterLabel => 'Character';

  @override
  String get instrJokerCharacterDesc =>
      'Reveals the real character name in place of a hidden name.';

  @override
  String get instrJokerActorLabel => 'Actor';

  @override
  String get instrJokerActorDesc =>
      'Reveals the real actor\'s name in place of a hidden name.';

  @override
  String get instrJokerHintLabel => 'Hint';

  @override
  String get instrJokerHintDesc =>
      'Reveals an extra clue about the film, shown below the pitch.';

  @override
  String get instrJokerRevealWordLabel => 'Reveal a word';

  @override
  String get instrJokerRevealWordDesc =>
      'Reveals a whole word of the answer (or a third of the letters if the title is a single word).';

  @override
  String get instrJokerRedLabel => 'Character (red)';

  @override
  String get instrJokerRedDesc =>
      'Turns an orange name red (the Actor/Character jokers then take over normally). Only appears on puzzles with an orange name. Obtained 3 ways: a guaranteed ad (once per level concerned), the weekly puzzle\'s global top 10%, or the shop.';

  @override
  String get streakCalendarTitle => '📅 STREAK CALENDAR';

  @override
  String streakCalendarSubtitle(int streak, int jour, int total) {
    return '$streak day(s) in a row — day $jour of $total';
  }

  @override
  String streakCalendarEventLine(
      String emoji, int day, String label, String date) {
    return '$emoji Day $day — $label ($date): extra bonus!';
  }

  @override
  String get streakLegendMinor => 'Minor bonus — 1 Hint joker';

  @override
  String streakLegendMajor(String days) {
    return 'Major bonus — days $days';
  }

  @override
  String streakLegendCycle(int n) {
    return 'Full cycle — day $n, major bonus ×3';
  }

  @override
  String get streakLegendEvent =>
      'Major film industry event — bonus on top of the day\'s own';

  @override
  String get mpTitle => 'MULTIPLAYER';

  @override
  String get mpAdMatchEarned => '+1 game for today!';

  @override
  String mpHistoryLastMatches(int n) {
    return 'The last $n matches.';
  }

  @override
  String get mpNoMatchYet => 'No match played yet.';

  @override
  String get mpRule1 =>
      'Best of 3 rounds (win at 2 points), 45 to 75 seconds per round depending on the answer\'s length.';

  @override
  String get mpRule2 =>
      'The clue is revealed letter by letter, all letters visible right at 35 seconds.';

  @override
  String get mpRule3 =>
      'Whoever finds the right answer first wins the round. If neither of you finds it in time, you both win the point.';

  @override
  String get mpRule4 =>
      'So a match can end in a tie (2-2 after just 2 rounds).';

  @override
  String get mpRule5 => 'Your Elo rating changes at the end of each match.';

  @override
  String get mpRule6 => '5 games per day, resets at 00:00 GMT.';

  @override
  String get mpYourRank => 'Your rank';

  @override
  String mpTopPercent(String pct) {
    return 'You\'re in the global top $pct%';
  }

  @override
  String get mpChallengePlayer => '⚔️ CHALLENGE A PLAYER';

  @override
  String mpWatchAdForMatch(int watched, int max) {
    return '🎬 Watch an ad for +1 game ($watched/$max)';
  }

  @override
  String get mpComeBackTomorrow => 'Come back tomorrow for more games!';

  @override
  String mpMatchesLeft(int n) {
    return '$n game(s) left today';
  }

  @override
  String get mpQuotaReached => 'Daily quota reached';

  @override
  String get mpHistoryButton => '📜 HISTORY';

  @override
  String get mpWin => 'Win';

  @override
  String get mpLoss => 'Loss';

  @override
  String get mpDraw => 'Tie';

  @override
  String get mpRoundLabel => 'ROUND';

  @override
  String get mpTimeLabel => 'TIME';

  @override
  String get mpYou => 'You';

  @override
  String get mpOpponentFallback => 'Opponent';

  @override
  String mpRoundsWon(int n) {
    return '🏅 $n round(s)';
  }

  @override
  String get mpRoundWon => '🎉 Round won!';

  @override
  String get mpRoundLost => '😔 Your opponent found it first.';

  @override
  String get mpRoundTie => '🤝 Nobody found it — you both win the point.';

  @override
  String get mpMatchWin => '🏆 VICTORY';

  @override
  String get mpMatchLoss => '😔 DEFEAT';

  @override
  String get mpMatchDraw => '🤝 TIE MATCH';

  @override
  String get mpNewTitle => '✨ New title!';

  @override
  String get mpReplay => 'REPLAY';

  @override
  String get mpQuotaReachedFull => 'Daily quota reached — come back tomorrow!';

  @override
  String get shopTitle => 'SHOP';

  @override
  String get shopUnavailable => 'Shop unavailable right now.';
}
