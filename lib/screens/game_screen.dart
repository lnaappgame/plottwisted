import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../data/puzzles_data.dart';
import '../l10n/app_localizations.dart';
import '../models/joker.dart';
import '../models/puzzle.dart';
import '../services/app_settings.dart';
import '../services/game_state.dart';
import '../services/sound_service.dart';
import '../services/streak_state.dart';
import '../theme/app_theme.dart';
import '../widgets/answer_row.dart';
import '../widgets/clapper_transition.dart';
import '../widgets/joker_bar.dart';
import '../widgets/joker_fx.dart';
import '../widgets/joker_style.dart';
import '../widgets/letter_pool.dart';
import '../widgets/mini_popup.dart';
import '../widgets/pitch_card.dart';
import '../widgets/result_overlay.dart';
import '../widgets/world_intro_overlay.dart';
import '../widgets/scifi_background.dart';
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

  // keepScrollOffset à false : un nouveau niveau repart toujours en haut,
  // même quand le plateau est reconstruit après l'écran de choix de monde.
  final ScrollController _scroll = ScrollController(keepScrollOffset: false);
  final JokerFx _fx = JokerFx();

  // Jokers gagnés en fin de niveau ou de monde, montrés une fois le niveau
  // suivant affiché (leur étoile doit pouvoir rejoindre la barre de jokers).
  ({String? eyebrow, List<RewardGrant> grants})? _queuedReward;

  @override
  void initState() {
    super.initState();
    final game = context.read<GameState>();
    if (game.hasPendingSolve && game.puzzleLoaded) {
      // Niveau déjà trouvé, quitté avant « SUIVANT » (accueil ou app
      // fermée) : on rouvre sa révélation plutôt que de le faire refaire.
      _pendingWorldChoice = null;
      _showResult = true;
      return;
    }
    if (!game.puzzleLoaded && game.remainingLevels.isEmpty) {
      // Quitté sur l'écran de fin de monde, avant d'avoir choisi la suite :
      // on y revient, au lieu de recharger le dernier niveau déjà résolu.
      if (game.inTutorial) {
        game.enterWorld(1);
      } else if (game.worldChoiceOptions.isNotEmpty) {
        _pendingWorldChoice = game.worldChoiceOptions;
        return;
      }
    }
    _pendingWorldChoice = game.puzzleLoaded ? null : [game.currentWorld.number];
  }

  @override
  void dispose() {
    _revealTimer?.cancel();
    _scroll.dispose();
    _fx.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _flushQueuedReward() {
    final reward = _queuedReward;
    if (reward == null || !mounted) return;
    _queuedReward = null;
    _fx.reward(eyebrow: reward.eyebrow, grants: reward.grants);
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
    // En mode "choix", il faut appliquer le choix — y compris quand il ne
    // reste qu'un seul monde à proposer (monde terminé, file vide). En mode
    // "imposé" (COMMENCER), le monde a déjà été entré par l'appelant.
    if (_pendingWorldChoice!.length > 1 || game.remainingLevels.isEmpty) {
      game.chooseNextWorld(chosenWorld);
    }
    setState(() => _pendingWorldChoice = null);
    _loadWithTutorialCheck();
  }

  void _loadWithTutorialCheck() {
    context.read<GameState>().loadPuzzle();
    setState(() {});
    _scrollToTop();
    _checkIntroDialogsAfterLoad(then: _flushQueuedReward);
  }

  /// Popups d'explication (orange/violet/tutoriel numéroté) à afficher une
  /// fois le nouveau puzzle déjà chargé — séparé de [_loadWithTutorialCheck]
  /// pour que la transition tutoriel 0-3→0-4 puisse charger le puzzle AVANT
  /// d'afficher son dialogue (sans quoi l'en-tête montrait déjà "Monde 0-4"
  /// pendant que le pitch/la grille affichés dessous restaient ceux de
  /// l'ancien niveau, le temps que la popup soit fermée) sans le recharger
  /// une seconde fois à la fermeture de cette popup. [then] est appelé
  /// une fois l'éventuelle popup fermée (ou tout de suite s'il n'y en a pas).
  void _checkIntroDialogsAfterLoad({VoidCallback? then}) {
    final game = context.read<GameState>();
    final t = AppLocalizations.of(context);
    // Explication à la première rencontre d'un nom orange/violet en partie
    // (indépendant du tutoriel guidé, peut survenir à tout moment du jeu).
    if (game.consumeOrangeIntroPending()) {
      _showTutorialDialog('',
          richSpans: [
            TextSpan(text: t.gameOrangeIntro1),
            TextSpan(
                text: t.colorOrange,
                style: const TextStyle(color: AppColors.orangeBright, fontWeight: FontWeight.w600)),
            TextSpan(text: t.gameOrangeIntro2),
            TextSpan(
                text: t.colorRed, style: const TextStyle(color: AppColors.crimsonBright, fontWeight: FontWeight.w600)),
            TextSpan(text: t.gameOrangeIntro3),
          ],
          onClose: then);
      return;
    }
    if (game.consumeVioletIntroPending()) {
      _showTutorialDialog('',
          richSpans: [
            TextSpan(text: t.gameVioletIntro1),
            TextSpan(
                text: t.colorPurple,
                style: const TextStyle(color: AppColors.violetBright, fontWeight: FontWeight.w600)),
            TextSpan(text: t.gameVioletIntro2),
          ],
          onClose: then);
      return;
    }

    if (game.inTutorial) {
      switch (game.currentLevelNumber) {
        case 1:
          _showTutorialDialog(t.gameTutorial1, onClose: then);
          return;
        case 2:
          _showTutorialDialog(t.gameTutorial2, onClose: then);
          return;
        case 3:
          _showTutorialDialog(t.gameTutorial3, onClose: then);
          return;
      }
    }
    if (then != null) WidgetsBinding.instance.addPostFrameCallback((_) => then());
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

  // ─── Joker épuisé : pub pour ce joker précis, ou boutique ───
  Future<void> _onRequestJoker(JokerKind kind) async {
    final game = context.read<GameState>();
    final settings = context.read<AppSettings>();
    final colors = AppColors(settings.isLightTheme, colorblind: settings.colorblindMode);
    final t = AppLocalizations.of(context);
    final accent = jokerColor(kind, colors);
    final canAd = game.canWatchAdFor(kind);
    final choice = await showDialog<String>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: colors.bgPanel2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: accent.withOpacity(0.6)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${kind.icon} ${jokerName(kind, t)}',
                  textAlign: TextAlign.center, style: AppTextStyles.display(size: 20, color: accent)),
              const SizedBox(height: 10),
              Text(
                canAd ? t.jokerEmptyBody(kind.adReward) : t.jokerRedLockedToast,
                textAlign: TextAlign.center,
                style: AppTextStyles.body(size: 14, color: colors.cream).copyWith(height: 1.5),
              ),
              const SizedBox(height: 18),
              if (canAd) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.crimson),
                    onPressed: () => Navigator.of(dialogContext).pop('ad'),
                    child: Text(t.jokerWatchAdFor(kind.adReward),
                        style: AppTextStyles.body(size: 14, weight: FontWeight.w700, color: colors.cream)),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(dialogContext).pop('shop'),
                  child: Text(t.jokerGoShop,
                      style: AppTextStyles.body(size: 14, weight: FontWeight.w700, color: AppColors.gold)),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(t.commonCancel, style: AppTextStyles.body(size: 13, color: colors.muted)),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
    if (choice == 'shop') {
      showDialog(context: context, builder: (_) => const ShopScreen());
    } else if (choice == 'ad') {
      // AdMob affiche sa propre interface plein écran : on attend juste la fin.
      final earned = await game.adService.showRewardedAdForJoker();
      if (!mounted) return;
      final granted = earned ? game.grantJokerFromAd(kind) : 0;
      if (granted > 0) {
        _fx.reward(grants: [RewardGrant(kind, granted)]);
      } else {
        _toast(t.commonAdUnavailable);
      }
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
      final kind = JokerKind.fromLabel(game.grantWeightedRandomJoker());
      if (kind != null) _fx.reward(grants: [RewardGrant(kind, 1)]);
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
    _scrollToTop();
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

    final minorKind = game.pendingMinorJokerLabel == null ? null : JokerKind.fromLabel(game.pendingMinorJokerLabel!);
    game.pendingMinorJokerLabel = null;
    if (minorKind != null) _queuedReward = (eyebrow: null, grants: [RewardGrant(minorKind, 1)]);

    if (wasTutorial && status == 'tutorial-final-transition') {
      // Charge déjà le niveau 0-4 avant d'afficher le dialogue, pour que le
      // pitch/la grille dessous correspondent à l'en-tête ("Monde 0-4") dès
      // l'apparition de la popup plutôt que de montrer encore le niveau 0-3
      // jusqu'à sa fermeture.
      game.loadPuzzle();
      setState(() {});
      _scrollToTop();
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
      if (status.startsWith('all-content-complete')) {
        // Plus de plateau de jeu ensuite (page "prochainement") : pas
        // d'étoile possible, on garde le message simple.
        if (majorLabel.isNotEmpty && minorLabel.isNotEmpty) {
          _toast(t.gameWorldCompleteBoth(
              worldNumber, jokerLabelFor(majorLabel, game.locale), jokerLabelFor(minorLabel, game.locale)));
        } else if (majorLabel.isNotEmpty) {
          _toast(t.gameWorldCompleteMajor(worldNumber, jokerLabelFor(majorLabel, game.locale)));
        }
      } else {
        final grants = [
          for (final label in [majorLabel, minorLabel])
            if (JokerKind.fromLabel(label) case final kind?) RewardGrant(kind, 1),
        ];
        if (grants.isNotEmpty) _queuedReward = (eyebrow: t.gameWorldDone(worldNumber), grants: grants);
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
      return SciFiScaffold(
        baseColor: colors.bgDeep,
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
      return SciFiScaffold(
        baseColor: colors.bgDeep,
        body: WorldIntroOverlay(
          worlds: worlds,
          colors: colors,
          onChoose: (n) => ClapperTransition.play(context, () => _resolveWorldChoice(n)),
        ),
      );
    }

    return SciFiScaffold(
      baseColor: colors.bgDeep,
      body: SafeArea(
        child: Stack(
          children: [
            AbsorbPointer(
              absorbing: _revealingAnswer,
              child: SingleChildScrollView(
                controller: _scroll,
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
                    PitchCard(fx: _fx),
                    const SizedBox(height: 18),
                    AnswerRow(highlightSolved: _revealingAnswer, fx: _fx),
                    const SizedBox(height: 18),
                    LetterPool(fx: _fx),
                    const SizedBox(height: 18),
                    JokerBar(
                      fx: _fx,
                      onRequestJoker: _onRequestJoker,
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
            Positioned.fill(child: JokerFxLayer(fx: _fx)),
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
