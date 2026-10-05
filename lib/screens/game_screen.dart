import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../data/puzzles_data.dart';
import '../l10n/app_localizations.dart';
import '../models/puzzle.dart';
import '../services/app_settings.dart';
import '../services/game_state.dart';
import '../services/sound_service.dart';
import '../services/streak_state.dart';
import '../theme/app_theme.dart';
import '../widgets/answer_row.dart';
import '../widgets/clapper_transition.dart';
import '../widgets/joker_bar.dart';
import '../widgets/letter_pool.dart';
import '../widgets/mini_popup.dart';
import '../widgets/pitch_card.dart';
import '../widgets/result_overlay.dart';
import '../widgets/world_intro_overlay.dart';
import 'shop_screen.dart';

class _MiniPopupSpec {
  final String text;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String secondaryLabel;
  final VoidCallback onSecondary;
  _MiniPopupSpec({
    required this.text,
    required this.primaryLabel,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
  });
}

class GameScreen extends StatefulWidget {
  final VoidCallback onBackToMenu;
  const GameScreen({super.key, required this.onBackToMenu});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // null = pas d'écran de monde affiché ; sinon 1 numéro (monde imposé,
  // COMMENCER) ou 2 numéros (choix du prochain monde).
  late List<int>? _pendingWorldChoice;
  bool _showResult = false;
  _MiniPopupSpec? _miniPopup;

  // Bonne réponse : le titre reste 1 s en surbrillance verte avant la
  // révélation (saisie bloquée pendant ce temps).
  bool _revealingAnswer = false;
  Timer? _revealTimer;

  @override
  void initState() {
    super.initState();
    final game = context.read<GameState>();
    _pendingWorldChoice = game.puzzleLoaded ? null : [game.currentWorld.number];
  }

  @override
  void dispose() {
    _revealTimer?.cancel();
    super.dispose();
  }

  /// Confirme l'écran de monde imposé (COMMENCER) ou le choix fait par le
  /// joueur, puis charge le premier puzzle du monde retenu.
  void _resolveWorldChoice(int chosenWorld) {
    // Un double-tap rapide sur une carte de choix (avant que le setState
    // ci-dessous ne fasse disparaître l'écran) appellerait chooseNextWorld()
    // deux fois de suite pour un seul choix réel, désynchronisant la
    // réserve/frontière de mondes — on l'ignore explicitement.
    if (!mounted || _pendingWorldChoice == null) return;
    final game = context.read<GameState>();
    // En mode "choix" (2 options), il faut appliquer le choix ; en mode
    // "imposé" (1 seule option), le monde a déjà été entré par l'appelant.
    if (_pendingWorldChoice!.length > 1) {
      game.chooseNextWorld(chosenWorld);
    }
    setState(() => _pendingWorldChoice = null);
    _loadWithTutorialCheck();
  }

  void _loadWithTutorialCheck() {
    context.read<GameState>().loadPuzzle();
    setState(() {});
    _checkIntroDialogsAfterLoad();
  }

  /// Popups d'explication (orange/violet/tutoriel numéroté) à afficher une
  /// fois le nouveau puzzle déjà chargé — séparé de [_loadWithTutorialCheck]
  /// pour que la transition tutoriel 0-3→0-4 puisse charger le puzzle AVANT
  /// d'afficher son dialogue (sans quoi l'en-tête montrait déjà "Monde 0-4"
  /// pendant que le pitch/la grille affichés dessous restaient ceux de
  /// l'ancien niveau, le temps que la popup soit fermée) sans le recharger
  /// une seconde fois à la fermeture de cette popup.
  void _checkIntroDialogsAfterLoad() {
    final game = context.read<GameState>();
    final t = AppLocalizations.of(context);
    // Explication à la première rencontre d'un nom orange/violet en partie
    // (indépendant du tutoriel guidé, peut survenir à tout moment du jeu).
    if (game.consumeOrangeIntroPending()) {
      _showTutorialDialog('', richSpans: [
        TextSpan(text: t.gameOrangeIntro1),
        TextSpan(
            text: t.colorOrange, style: const TextStyle(color: AppColors.orangeBright, fontWeight: FontWeight.w600)),
        TextSpan(text: t.gameOrangeIntro2),
        TextSpan(text: t.colorRed, style: const TextStyle(color: AppColors.crimsonBright, fontWeight: FontWeight.w600)),
        TextSpan(text: t.gameOrangeIntro3),
      ]);
      return;
    }
    if (game.consumeVioletIntroPending()) {
      _showTutorialDialog('', richSpans: [
        TextSpan(text: t.gameVioletIntro1),
        TextSpan(
            text: t.colorPurple, style: const TextStyle(color: AppColors.violetBright, fontWeight: FontWeight.w600)),
        TextSpan(text: t.gameVioletIntro2),
      ]);
      return;
    }

    if (game.inTutorial) {
      switch (game.currentLevelNumber) {
        case 1:
          _showTutorialDialog(t.gameTutorial1);
          break;
        case 2:
          _showTutorialDialog(t.gameTutorial2);
          break;
        case 3:
          _showTutorialDialog(t.gameTutorial3);
          break;
      }
    }
  }

  void _showTutorialDialog(String message, {VoidCallback? onClose, List<InlineSpan>? richSpans}) {
    final colors = AppColors(context.read<AppSettings>().isLightTheme);
    final t = AppLocalizations.of(context);
    final textStyle = AppTextStyles.body(size: 14, color: colors.cream).copyWith(height: 1.5);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: colors.bgPanel2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(t.gameDirectorLabel,
                  style: AppTextStyles.body(size: 11, weight: FontWeight.w700, color: AppColors.gold)),
              const SizedBox(height: 10),
              richSpans != null
                  ? RichText(text: TextSpan(style: textStyle, children: richSpans))
                  : Text(message, style: textStyle),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.crimson),
                  onPressed: () {
                    Navigator.of(context).pop();
                    onClose?.call();
                  },
                  child: Text(t.gameUnderstood, style: AppTextStyles.display(size: 15, color: colors.cream)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  static String _jokerIcon(String label) {
    switch (label) {
      case 'Révéler':
        return '💡';
      case 'Éliminer':
        return '✂️';
      case 'Acteur':
        return '🔵';
      case 'Personnage':
        return '🟢';
      case 'Personnage (rouge)':
        return '🔴';
      case 'Indice':
        return '🎬';
      case 'Révéler un mot':
        return '📖';
      default:
        return '🎁';
    }
  }

  /// Encart affiché après le visionnage d'une pub à récompense, annonçant
  /// le joker gagné.
  void _showJokerWonDialog(String label) {
    final colors = AppColors(context.read<AppSettings>().isLightTheme);
    final t = AppLocalizations.of(context);
    final displayLabel = jokerLabelFor(label, context.read<AppSettings>().locale);
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: colors.bgPanel2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_jokerIcon(label), style: const TextStyle(fontSize: 40)),
              const SizedBox(height: 10),
              Text(t.gameJokerWon,
                  style: AppTextStyles.body(size: 11, weight: FontWeight.w700, color: AppColors.gold)
                      .copyWith(letterSpacing: 2)),
              const SizedBox(height: 6),
              Text(displayLabel, textAlign: TextAlign.center, style: AppTextStyles.display(size: 22)),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.crimson),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('OK', style: AppTextStyles.display(size: 15, color: colors.cream)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Pub : AdMob affiche sa propre interface plein écran, on ne bloque
  // jamais rien nous-mêmes — on attend juste que le SDK ait terminé. ───
  Future<void> _onWatchAdForJoker() async {
    final game = context.read<GameState>();
    if (game.inTutorial) return;
    final earned = await game.adService.showRewardedAdForJoker();
    if (!mounted) return;
    if (earned) {
      final label = game.grantWeightedRandomJoker();
      _showJokerWonDialog(label);
    } else {
      _toast(AppLocalizations.of(context).commonAdUnavailable);
    }
  }

  /// Pub garantie (100% de chances) pour 1 joker rouge — limitée à une fois
  /// par niveau concerné (voir [GameState.peutRegarderPubJokerRouge]).
  Future<void> _onWatchAdForRedJoker() async {
    final game = context.read<GameState>();
    if (game.inTutorial || !game.peutRegarderPubJokerRouge) return;
    final earned = await game.adService.showRewardedAdForJoker();
    if (!mounted) return;
    if (earned) {
      game.grantRedJokerFromAd();
      _showJokerWonDialog('Personnage (rouge)');
    } else {
      _toast(AppLocalizations.of(context).commonAdUnavailable);
    }
  }

  // ─── Mini-popup (3 échecs) ───
  void _offerAdForMinorBonus() {
    final t = AppLocalizations.of(context);
    setState(() {
      _miniPopup = _MiniPopupSpec(
        text: t.gameMinorBonusOffer,
        primaryLabel: t.gameWatchAd,
        onPrimary: () {
          setState(() => _miniPopup = null);
          _watchAdForMinorBonus();
        },
        secondaryLabel: t.gameNoThanks,
        onSecondary: () => setState(() => _miniPopup = null),
      );
    });
  }

  Future<void> _watchAdForMinorBonus() async {
    final game = context.read<GameState>();
    final earned = await game.adService.showRewardedAdForJoker();
    if (!mounted) return;
    if (earned) {
      final label = game.grantWeightedRandomJoker();
      _showJokerWonDialog(label);
    }
  }

  // ─── Passer le niveau ───
  void _onPostponeLevel() {
    final game = context.read<GameState>();
    if (!game.canPostponeLevel) {
      _toast(AppLocalizations.of(context).gameSkipLastLevel);
      return;
    }
    game.skipCurrentLevel();
    setState(() {});
    _checkIntroDialogsAfterLoad();
  }

  /// Joker "Passer définitivement" : renvoie vers la boutique s'il n'y en a
  /// plus en stock, sinon demande confirmation (achat payant) avant de
  /// résoudre le niveau comme une bonne réponse.
  Future<void> _onSkipForGood() async {
    final game = context.read<GameState>();
    if (game.skipJokerCount <= 0) {
      showDialog(context: context, builder: (_) => const ShopScreen());
      return;
    }
    final colors = AppColors(context.read<AppSettings>().isLightTheme);
    final t = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colors.bgPanel2,
        content: Text(t.gameSkipForGoodConfirm,
            style: AppTextStyles.body(size: 14, color: colors.cream).copyWith(height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(t.commonCancel, style: AppTextStyles.body(size: 13, color: colors.muted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.crimson),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(t.gameSkipForGoodUse, style: AppTextStyles.display(size: 15, color: colors.cream)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    if (game.solveWithSkipJoker()) _showSolvedThenReveal();
  }

  /// Bonne réponse (trouvée ou via joker) : son, série du jour, puis 1 s de
  /// surbrillance verte du titre avant l'écran de révélation.
  void _showSolvedThenReveal() {
    final settings = context.read<AppSettings>();
    if (settings.sfxOn) context.read<SoundService>().playCorrect();
    context.read<StreakState>().recordAction();
    setState(() => _revealingAnswer = true);
    _revealTimer?.cancel();
    _revealTimer = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _revealingAnswer = false;
        _showResult = true;
      });
    });
  }

  void _onValidate() {
    final game = context.read<GameState>();
    final settings = context.read<AppSettings>();
    final sound = context.read<SoundService>();
    final t = AppLocalizations.of(context);
    if (settings.vibrationsOn) HapticFeedback.lightImpact();
    final result = game.validate();
    switch (result) {
      case 'incomplete':
        _toast(t.gameIncomplete);
        break;
      case 'wrong':
        if (settings.sfxOn) sound.playWrong();
        _toast(t.gameWrong);
        if (!game.inTutorial && game.failStreak >= 3 && _miniPopup == null) {
          game.failStreak = 0;
          _offerAdForMinorBonus();
        }
        break;
      case 'solved':
        _showSolvedThenReveal();
        break;
    }
  }

  Future<void> _onNextLevel() async {
    // Double-tap guard, même principe que _resolveWorldChoice ci-dessus :
    // sans lui, un double-tap sur "FILM SUIVANT" appelle deux fois
    // advanceAfterSolve(), qui retire deux niveaux de la file au lieu d'un
    // (RangeError si c'était le dernier niveau du monde).
    if (!_showResult) return;
    final game = context.read<GameState>();
    final t = AppLocalizations.of(context);
    setState(() => _showResult = false);

    final wasTutorial = game.inTutorial;
    final mustAd = game.mustShowForcedAd;

    final status = game.advanceAfterSolve();

    if (game.pendingMinorJokerLabel != null) {
      _toast(t.gameJokerEarnedToast(jokerLabelFor(game.pendingMinorJokerLabel!, game.locale)));
      game.pendingMinorJokerLabel = null;
    }

    if (wasTutorial && status == 'tutorial-final-transition') {
      // Charge déjà le niveau 0-4 avant d'afficher le dialogue, pour que le
      // pitch/la grille dessous correspondent à l'en-tête ("Monde 0-4") dès
      // l'apparition de la popup plutôt que de montrer encore le niveau 0-3
      // jusqu'à sa fermeture.
      game.loadPuzzle();
      setState(() {});
      _showTutorialDialog(
        t.gameTutorialFinalTransition,
        onClose: _checkIntroDialogsAfterLoad,
      );
      return;
    }
    if (wasTutorial && status == 'tutorial-complete') {
      _showTutorialDialog(
        t.gameTutorialComplete,
        onClose: () {
          game.enterWorld(1);
          setState(() => _pendingWorldChoice = [1]);
        },
      );
      return;
    }

    if (mustAd) {
      await game.adService.showForcedAd();
      if (!mounted) return;
    }

    if (status.startsWith('world-choice') || status.startsWith('all-content-complete')) {
      final parts = status.split(':');
      final worldNumber = parts.length > 1 ? parts[1] : '';
      final majorLabel = parts.length > 2 ? parts[2] : '';
      final minorLabel = parts.length > 3 ? parts[3] : '';
      if (majorLabel.isNotEmpty && minorLabel.isNotEmpty) {
        _toast(t.gameWorldCompleteBoth(
            worldNumber, jokerLabelFor(majorLabel, game.locale), jokerLabelFor(minorLabel, game.locale)));
      } else if (majorLabel.isNotEmpty) {
        _toast(t.gameWorldCompleteMajor(worldNumber, jokerLabelFor(majorLabel, game.locale)));
      }
    }
    if (status.startsWith('all-content-complete')) {
      // Pas de pop-up : la reconstruction déclenchée par setState() plus haut
      // affiche la page dédiée (voir build(), gate sur shouldShowComingSoonPage).
      return;
    }
    if (status.startsWith('world-choice')) {
      setState(() => _pendingWorldChoice = game.worldChoiceOptions);
      return;
    }
    _loadWithTutorialCheck();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    final settings = context.watch<AppSettings>();
    final colors = AppColors(settings.isLightTheme, colorblind: settings.colorblindMode);

    if (game.shouldShowComingSoonPage) {
      final t = AppLocalizations.of(context);
      return Scaffold(
        backgroundColor: colors.bgDeep,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: widget.onBackToMenu,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: colors.bgPanel, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.menu, color: AppColors.goldBright, size: 18),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🎬', style: TextStyle(fontSize: 56)),
                        const SizedBox(height: 24),
                        Text(t.gameAllContentComplete,
                            textAlign: TextAlign.center, style: AppTextStyles.display(size: 22, color: colors.cream)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_pendingWorldChoice != null) {
      final worlds = _pendingWorldChoice!.map((n) {
        return n == 0
            ? GameWorld(
                number: 0, categoryLabel: AppLocalizations.of(context).gameTutorialCategory, puzzles: kTutorialPuzzles)
            : kWorlds.firstWhere((w) => w.number == n);
      }).toList();
      return Scaffold(
        body: WorldIntroOverlay(
          worlds: worlds,
          colors: colors,
          onChoose: (n) => ClapperTransition.play(context, () => _resolveWorldChoice(n)),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            AbsorbPointer(
              absorbing: _revealingAnswer,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: widget.onBackToMenu,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(color: colors.bgPanel, borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.menu, color: AppColors.goldBright, size: 18),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text('PLOT TWIST(ED)', style: AppTextStyles.display(size: 28)),
                              RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: AppTextStyles.body(size: 11, color: colors.muted),
                                  children: [
                                    TextSpan(
                                        text:
                                            '${game.levelTitleFor(game.locale)} · ${game.currentWorld.categoryLabelFor(game.locale)} · '),
                                    TextSpan(
                                      text: game.difficultyLabelFor(game.locale),
                                      style: TextStyle(
                                          color: colors.forDifficultyLabel(game.difficultyLabel),
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 36),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const PitchCard(),
                    const SizedBox(height: 18),
                    AnswerRow(highlightSolved: _revealingAnswer),
                    const SizedBox(height: 18),
                    const LetterPool(),
                    const SizedBox(height: 18),
                    JokerBar(
                      onToast: _toast,
                      onWatchAdForJoker: _onWatchAdForJoker,
                      onWatchAdForRedJoker: _onWatchAdForRedJoker,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => game.clearLastLetter(),
                            child: Text(AppLocalizations.of(context).commonClear,
                                style: AppTextStyles.display(size: 15, color: AppColors.gold)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.crimson),
                            onPressed: _onValidate,
                            child: Text(AppLocalizations.of(context).commonValidate,
                                style: AppTextStyles.display(size: 15, color: colors.cream)),
                          ),
                        ),
                      ],
                    ),
                    if (!game.inTutorial) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _onPostponeLevel,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(AppLocalizations.of(context).gameSkipLater,
                                    style:
                                        AppTextStyles.body(size: 12, weight: FontWeight.w700, color: AppColors.gold)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _onSkipForGood,
                              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.goldBright)),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '⏭️ ${AppLocalizations.of(context).gameSkipForGood}'
                                  '${game.skipJokerCount > 0 ? ' (${game.skipJokerCount})' : ' 🛒'}',
                                  style: AppTextStyles.body(
                                      size: 12, weight: FontWeight.w700, color: AppColors.goldBright),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (_showResult) Positioned.fill(child: ResultOverlay(onNext: _onNextLevel)),
            if (_miniPopup != null)
              MiniPopup(
                text: _miniPopup!.text,
                primaryLabel: _miniPopup!.primaryLabel,
                onPrimary: _miniPopup!.onPrimary,
                secondaryLabel: _miniPopup!.secondaryLabel,
                onSecondary: _miniPopup!.onSecondary,
                colors: colors,
              ),
          ],
        ),
      ),
    );
  }
}
