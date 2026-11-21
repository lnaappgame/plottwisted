import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../data/advent_data.dart';
import '../l10n/app_localizations.dart';
import '../models/joker.dart';
import '../services/advent_calendar.dart';
import '../services/app_settings.dart';
import '../services/game_state.dart';
import '../services/share_service.dart';
import '../services/sound_service.dart';
import '../services/streak_state.dart';
import '../theme/app_theme.dart';
import '../widgets/answer_row.dart';
import '../widgets/avatar_view.dart';
import '../widgets/joker_bar.dart';
import '../widgets/joker_fx.dart';
import '../widgets/joker_style.dart';
import '../widgets/letter_pool.dart';
import '../widgets/scifi_background.dart';

/// Couleurs du calendrier : rouge Noël et vert sapin sur une nuit d'hiver,
/// avec des touches d'or.
class _Xm {
  static const red = Color(0xFFD7262E);
  static const redSoft = Color(0xFF5A1A22);
  static const green = Color(0xFF2E8B57);
  static const gold = Color(0xFFF2C14E);
  static const bg = Color(0xFF07131F);
  static const panel = Color(0xFF10233A);
  static const panel2 = Color(0xFF173252);
  static const snow = Color(0xFFF3F1EA);
  static const muted = Color(0xFF9FB3C8);
  static const success = Color(0xFF7FC98F);
  static const button = Color(0xFFB71C24);
}

Widget _backButton(BuildContext context) => InkWell(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: _Xm.panel, borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.arrow_back, color: _Xm.gold, size: 18),
      ),
    );

String _caseLabel(AppLocalizations t, int day) => day == kAdventPitches.length ? t.advCaseBonus : t.advCaseNumber(day);

/// Le calendrier de l'Avent : la présentation (le Père Noël raconte), les
/// avatars à gagner, l'avancement et les 25 cases.
class AdventCalendarScreen extends StatelessWidget {
  const AdventCalendarScreen({super.key});

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 2)));
  }

  void _openCase(BuildContext context, int day) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => AdventCaseScreen(day: day)));
  }

  void _onCaseTap(BuildContext context, AdventCalendar advent, int day) {
    final t = AppLocalizations.of(context);
    if (advent.isSolved(day)) {
      showDialog(context: context, builder: (_) => _SolvedCaseDialog(day: day));
    } else if (advent.isPlayable(day)) {
      _openCase(context, day);
    } else if (advent.isOver) {
      _toast(context, t.advOver);
    } else {
      _toast(context, t.advCaseLocked(day));
    }
  }

  @override
  Widget build(BuildContext context) {
    final advent = context.watch<GameState>().advent;
    final settings = context.watch<AppSettings>();
    final t = AppLocalizations.of(context);
    final next = advent.suggestedDay;

    return SciFiScaffold(
      baseColor: _Xm.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Row(
              children: [
                _backButton(context),
                Expanded(
                  child: Text(t.advTitle,
                      textAlign: TextAlign.center, style: AppTextStyles.display(size: 26, color: _Xm.gold)),
                ),
                const SizedBox(width: 36),
              ],
            ),
            const SizedBox(height: 4),
            Text(t.advUntil, textAlign: TextAlign.center, style: AppTextStyles.body(size: 11, color: _Xm.muted)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_Xm.panel2, _Xm.panel]),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _Xm.green, width: 1.5),
              ),
              child: Column(
                children: [
                  const Text('🎅 🎄 🎁', style: TextStyle(fontSize: 26)),
                  const SizedBox(height: 8),
                  Text(t.advIntroTitle,
                      textAlign: TextAlign.center, style: AppTextStyles.display(size: 18, color: _Xm.red)),
                  const SizedBox(height: 10),
                  Text(t.advIntro,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body(size: 14, color: _Xm.snow)
                          .copyWith(height: 1.5, fontStyle: FontStyle.italic)),
                  const SizedBox(height: 10),
                  Text(t.advIntro2,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body(size: 14, weight: FontWeight.w700, color: _Xm.gold).copyWith(height: 1.4)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(t.advRules,
                textAlign: TextAlign.center, style: AppTextStyles.body(size: 11.5, color: _Xm.muted).copyWith(height: 1.4)),
            const SizedBox(height: 14),
            _SkinsCard(settings: settings),
            const SizedBox(height: 16),
            Text(t.advProgress(advent.solvedCount, advent.caseCount),
                key: const ValueKey('adventProgress'),
                textAlign: TextAlign.center,
                style: AppTextStyles.display(size: 16, color: _Xm.gold)),
            const SizedBox(height: 8),
            _ProgressBar(value: advent.solvedCount / advent.caseCount),
            const SizedBox(height: 14),
            if (!advent.isActive)
              _Banner(text: advent.isOver ? t.advOver : t.advNotYet)
            else if (advent.allSolved)
              _Banner(text: t.advAllDone)
            else if (advent.waitingForTomorrow)
              _Banner(text: t.advComeBack),
            GridView.count(
              crossAxisCount: 5,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                for (var day = 1; day <= advent.caseCount; day++)
                  _CaseTile(
                    key: ValueKey('adventCase$day'),
                    day: day,
                    advent: advent,
                    onTap: () => _onCaseTap(context, advent, day),
                  ),
              ],
            ),
            if (next != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                key: const ValueKey('adventPlay'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _Xm.button,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => _openCase(context, next),
                child: Text(t.advPlayDay(next), style: AppTextStyles.display(size: 20, color: _Xm.snow)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Une case du calendrier : trouvée (✓), jouable (celle du jour en or),
/// ou fermée (🔒).
class _CaseTile extends StatelessWidget {
  final int day;
  final AdventCalendar advent;
  final VoidCallback onTap;
  const _CaseTile({super.key, required this.day, required this.advent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final solved = advent.isSolved(day);
    final playable = advent.isPlayable(day);
    final today = advent.isToday(day) && advent.isActive;
    final bonus = day == advent.caseCount;
    final Color fill = solved ? _Xm.green.withValues(alpha: 0.35) : (playable ? _Xm.redSoft : _Xm.panel);
    final Color border = today ? _Xm.gold : (solved ? _Xm.green : (playable ? _Xm.red : _Xm.panel2));
    final mark = solved ? '✓' : (playable ? (bonus ? '🎄' : '🎁') : '🔒');
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border, width: today ? 2.5 : 1.2),
          boxShadow: today ? [BoxShadow(color: _Xm.gold.withValues(alpha: 0.45), blurRadius: 10)] : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$day',
                style: AppTextStyles.display(
                    size: 22, color: solved ? _Xm.success : (playable ? _Xm.snow : _Xm.muted.withValues(alpha: 0.6)))),
            Text(mark,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: solved ? _Xm.success : _Xm.muted,
                    height: 1.1)),
          ],
        ),
      ),
    );
  }
}

/// Une case déjà trouvée, touchée dans le calendrier : son film.
class _SolvedCaseDialog extends StatelessWidget {
  final int day;
  const _SolvedCaseDialog({required this.day});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final locale = context.read<AppSettings>().locale;
    final pitch = kAdventPitches[day - 1];
    return AlertDialog(
      backgroundColor: _Xm.panel2,
      title: Text(_caseLabel(t, day), textAlign: TextAlign.center, style: AppTextStyles.display(size: 20, color: _Xm.gold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(t.evtSolvedTitle, style: AppTextStyles.body(size: 12, color: _Xm.muted)),
          const SizedBox(height: 4),
          Text(pitch.titleFor(locale),
              key: const ValueKey('adventSolvedDialogTitle'),
              textAlign: TextAlign.center,
              style: AppTextStyles.display(size: 26, color: _Xm.snow)),
          Text(pitch.year, style: AppTextStyles.body(size: 13, color: _Xm.muted)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.commonClose, style: AppTextStyles.body(size: 13, weight: FontWeight.w700, color: _Xm.gold)),
        ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double value;
  const _ProgressBar({required this.value});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1).toDouble(),
        minHeight: 7,
        backgroundColor: _Xm.panel2,
        valueColor: const AlwaysStoppedAnimation(_Xm.red),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final String text;
  const _Banner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('adventBanner'),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _Xm.green.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _Xm.green),
      ),
      child: Text(text,
          textAlign: TextAlign.center, style: AppTextStyles.body(size: 13, weight: FontWeight.w700, color: _Xm.snow)),
    );
  }
}

class _SkinsCard extends StatelessWidget {
  final AppSettings settings;
  const _SkinsCard({required this.settings});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    Widget skin(String id, String label) {
      final unlocked = settings.isAvatarUnlocked(id);
      return Expanded(
        child: Column(
          children: [
            Opacity(
              opacity: unlocked ? 1 : 0.45,
              child: AvatarView(avatar: id, radius: 26, background: _Xm.panel2),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(unlocked ? Icons.check_circle : Icons.lock, size: 13, color: unlocked ? _Xm.success : _Xm.muted),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(label,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body(size: 10.5, color: unlocked ? _Xm.snow : _Xm.muted)),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      decoration: BoxDecoration(
        color: _Xm.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _Xm.red.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Text(t.evtSkinsTitle, style: AppTextStyles.display(size: 13, color: _Xm.gold)),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              skin(kSantaHatAvatar, t.advSkinHat),
              skin(kSnowHatAvatar, t.advSkinFinal),
            ],
          ),
        ],
      ),
    );
  }
}

/// Une case du calendrier, jouée comme dans le jeu principal : tuiles ou
/// clavier, Révéler / Éliminer / Révéler un mot, une pub pour un joker et
/// VALIDER. Après la victoire, « CASE SUIVANTE » mène à la case du jour ou
/// à la plus ancienne case manquée.
class AdventCaseScreen extends StatefulWidget {
  final int day;
  const AdventCaseScreen({super.key, required this.day});

  @override
  State<AdventCaseScreen> createState() => _AdventCaseScreenState();
}

class _AdventCaseScreenState extends State<AdventCaseScreen> {
  final JokerFx _fx = JokerFx();
  final ScrollController _scroll = ScrollController(keepScrollOffset: false);

  // Bonne réponse : le titre reste 1 s en vert avant l'écran de victoire.
  bool _revealing = false;
  bool _showResult = false;
  Timer? _revealTimer;
  bool _adBusy = false;

  /// Faux si la case demandée n'était pas jouable (pas encore ouverte, déjà
  /// trouvée, calendrier fermé) : l'écran le dit au lieu d'afficher une autre grille.
  bool _opened = false;

  AdventCalendar get _advent => context.read<GameState>().advent;

  @override
  void initState() {
    super.initState();
    _opened = _advent.open(widget.day, notify: false);
  }

  @override
  void dispose() {
    _revealTimer?.cancel();
    _scroll.dispose();
    _fx.dispose();
    super.dispose();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 2)));
  }

  void _onValidate() {
    final settings = context.read<AppSettings>();
    final sound = context.read<SoundService>();
    final t = AppLocalizations.of(context);
    if (settings.vibrationsOn) HapticFeedback.lightImpact();
    switch (_advent.validate()) {
      case 'incomplete':
        _toast(t.gameIncomplete);
      case 'wrong':
        if (settings.sfxOn) sound.playWrong();
        _toast(t.gameWrong);
      case 'solved':
        if (settings.sfxOn) sound.playCorrect();
        context.read<StreakState>().recordAction();
        setState(() => _revealing = true);
        _revealTimer?.cancel();
        _revealTimer = Timer(const Duration(seconds: 1), () {
          if (!mounted) return;
          setState(() {
            _revealing = false;
            _showResult = true;
          });
        });
    }
  }

  void _onNext() {
    if (!_showResult) return; // double-tap
    final next = _advent.suggestedDay;
    final joker = _advent.lastReward?.dayJoker;
    setState(() => _showResult = false);
    if (next == null || !_advent.open(next)) {
      Navigator.of(context).pop();
      return;
    }
    if (_scroll.hasClients) _scroll.jumpTo(0);
    // L'étoile du joker du jour rejoint la barre de jokers de la case suivante.
    if (joker != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fx.reward(grants: [RewardGrant(joker, 1)]);
      });
    }
  }

  Future<void> _onWatchAdForJoker() async {
    if (_adBusy) return;
    final game = context.read<GameState>();
    _adBusy = true;
    final earned = await game.adService.showRewardedAdForJoker();
    _adBusy = false;
    if (!mounted) return;
    if (earned) {
      _fx.reward(grants: [RewardGrant(_advent.grantAdJoker(), 1)]);
    } else {
      _toast(AppLocalizations.of(context).commonAdUnavailable);
    }
  }

  /// Titre d'un seul mot, la première fois : « Révéler un mot » n'y dévoile
  /// qu'un tiers des lettres, le joueur peut garder son joker.
  Future<bool> _confirmRevealWordNerf() async {
    final game = context.read<GameState>();
    final t = AppLocalizations.of(context);
    final use = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _Xm.panel2,
        title: Text(t.nerfRevealWordTitle,
            textAlign: TextAlign.center, style: AppTextStyles.display(size: 20, color: _Xm.gold)),
        content: Text(t.nerfRevealWordBody(_advent.revealWordNerfCount),
            textAlign: TextAlign.center, style: AppTextStyles.body(size: 14, color: _Xm.snow).copyWith(height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(t.commonCancel, style: AppTextStyles.body(size: 13, color: _Xm.muted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _Xm.button),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(t.nerfRevealWordUse, style: AppTextStyles.body(size: 14, weight: FontWeight.w700, color: _Xm.snow)),
          ),
        ],
      ),
    );
    game.markRevealWordNerfExplained();
    return use ?? false;
  }

  Future<void> _onJoker(JokerKind kind, Color color) async {
    final advent = _advent;
    final game = context.read<GameState>();
    switch (kind) {
      case JokerKind.reveal:
        final slot = advent.useRevealJoker();
        if (slot != null) _fx.beam(kind, color, ['slot:$slot']);
      case JokerKind.eliminate:
        final tiles = advent.useEliminateJoker();
        _fx.beam(kind, color, [for (final i in tiles) 'tile:$i']);
      case JokerKind.revealWord:
        if (advent.revealWordIsNerfed && !game.revealWordNerfExplained && !await _confirmRevealWordNerf()) return;
        if (!mounted) return;
        final slots = advent.useRevealWordJoker();
        _fx.beam(kind, color, [for (final i in slots) 'slot:$i']);
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    final advent = game.advent;
    final settings = context.watch<AppSettings>();
    final t = AppLocalizations.of(context);
    final locale = settings.locale;
    final day = _opened ? advent.loadedDay : null;

    if (day == null) {
      return SciFiScaffold(baseColor: _Xm.bg, body: SafeArea(child: _NoCaseView(advent: advent)));
    }

    final pitch = kAdventPitches[day - 1];
    final solvedHere = advent.isSolved(day);
    return SciFiScaffold(
      baseColor: _Xm.bg,
      body: SafeArea(
        child: Stack(
          children: [
            AbsorbPointer(
              absorbing: _revealing,
              child: SingleChildScrollView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        _backButton(context),
                        Expanded(
                          child: Text('🎄 ${_caseLabel(t, day)}',
                              key: const ValueKey('adventCaseTitle'),
                              textAlign: TextAlign.center,
                              style: AppTextStyles.display(size: 26, color: _Xm.gold)),
                        ),
                        const SizedBox(width: 36),
                      ],
                    ),
                    if (!solvedHere) ...[
                      const SizedBox(height: 6),
                      Text(advent.isToday(day) ? t.advOnTimeHint : t.advLateHint,
                          key: const ValueKey('adventCaseHint'),
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body(
                              size: 12,
                              weight: FontWeight.w700,
                              color: advent.isToday(day) ? _Xm.gold : _Xm.muted)),
                    ],
                    const SizedBox(height: 10),
                    Container(
                      key: const ValueKey('adventPitchCard'),
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_Xm.panel2, _Xm.panel]),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _Xm.red, width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.advSantaSays,
                              style: AppTextStyles.body(size: 11, weight: FontWeight.w700, color: _Xm.gold)
                                  .copyWith(letterSpacing: 1.2)),
                          const SizedBox(height: 8),
                          Text(pitch.pitchFor(locale),
                              style: AppTextStyles.body(size: 17, color: _Xm.snow).copyWith(height: 1.5)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    AnswerRow(grid: advent, fx: _fx, highlightSolved: _revealing || _showResult),
                    const SizedBox(height: 14),
                    LetterPool(grid: advent, fx: _fx),
                    const SizedBox(height: 14),
                    EventJokerBar(fx: _fx, game: game, onJoker: _onJoker, onWatchAd: _onWatchAdForJoker),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: advent.clearLastLetter,
                            child: Text(t.commonClear, style: AppTextStyles.display(size: 15, color: AppColors.gold)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            key: const ValueKey('adventValidate'),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.crimson),
                            onPressed: _onValidate,
                            child: Text(t.commonValidate, style: AppTextStyles.display(size: 15, color: _Xm.snow)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Positioned.fill(child: JokerFxLayer(fx: _fx)),
            if (_showResult)
              Positioned.fill(
                child: _ResultOverlay(
                  day: day,
                  locale: locale,
                  reward: advent.lastReward,
                  hasNext: advent.suggestedDay != null,
                  onNext: _onNext,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Case trouvée : le film, ce que le joueur gagne, puis la case suivante.
class _ResultOverlay extends StatelessWidget {
  final int day;
  final String locale;
  final AdventSolveReward? reward;
  final bool hasNext;
  final VoidCallback onNext;
  const _ResultOverlay(
      {required this.day, required this.locale, required this.reward, required this.hasNext, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final reward = this.reward;
    final pitch = kAdventPitches[day - 1];
    return Container(
      color: Colors.black.withValues(alpha: 0.72),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
          decoration: BoxDecoration(
            color: _Xm.panel2,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _Xm.gold, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(t.evtWellDone, textAlign: TextAlign.center, style: AppTextStyles.display(size: 24, color: _Xm.success)),
              const SizedBox(height: 10),
              Text(t.evtSolvedTitle, textAlign: TextAlign.center, style: AppTextStyles.body(size: 12, color: _Xm.muted)),
              const SizedBox(height: 4),
              Text(pitch.titleFor(locale),
                  key: const ValueKey('adventSolvedTitle'),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.display(size: 28, color: _Xm.gold)),
              Text(pitch.year, textAlign: TextAlign.center, style: AppTextStyles.body(size: 13, color: _Xm.muted)),
              if (reward != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _Xm.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _Xm.green),
                  ),
                  child: Column(
                    children: [
                      if (reward.dayJoker != null)
                        Text('${reward.dayJoker!.icon}  ${t.evtRewardJoker(jokerName(reward.dayJoker!, t))}',
                            key: const ValueKey('adventRewardJoker'),
                            textAlign: TextAlign.center,
                            style: AppTextStyles.body(size: 15, weight: FontWeight.w700, color: _Xm.snow))
                      else
                        Text(t.advLateHint,
                            key: const ValueKey('adventRewardLate'),
                            textAlign: TextAlign.center,
                            style: AppTextStyles.body(size: 12.5, color: _Xm.muted)),
                      if (reward.hatUnlocked) ...[
                        const SizedBox(height: 10),
                        const AvatarView(avatar: kSantaHatAvatar, radius: 30, background: _Xm.panel),
                        const SizedBox(height: 6),
                        Text(t.advAvatarUnlocked,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.body(size: 13, weight: FontWeight.w700, color: _Xm.gold)),
                      ],
                      if (reward.finalReward) ...[
                        const SizedBox(height: 10),
                        const AvatarView(avatar: kSnowHatAvatar, radius: 36, background: _Xm.panel),
                        const SizedBox(height: 6),
                        Text(t.advFinalReward,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.body(size: 13, weight: FontWeight.w700, color: _Xm.gold)),
                        const SizedBox(height: 4),
                        Text(kAdventFinalJokers.map((k) => k.icon).join(' '),
                            textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Builder(
                builder: (buttonContext) => OutlinedButton.icon(
                  key: const ValueKey('adventShare'),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: _Xm.gold)),
                  onPressed: () {
                    final advent = context.read<GameState>().advent;
                    ShareService.share(
                      buttonContext,
                      t.shareAdventText(
                          day,
                          ShareService.attemptGrid(advent.attemptRows),
                          ShareService.resultDetails(
                              ShareService.formatDuration(advent.lastSolveDuration.inSeconds), advent.jokersUsed,
                              skipped: false, noJoker: t.shareNoJoker, skippedLabel: t.shareSkipped),
                          ShareService.link(ShareService.sourceAdvent)),
                    );
                  },
                  icon: const Icon(Icons.share, size: 16, color: _Xm.gold),
                  label: Text(t.shareButton, style: AppTextStyles.body(size: 13, weight: FontWeight.w700, color: _Xm.gold)),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                key: const ValueKey('adventNext'),
                style: ElevatedButton.styleFrom(backgroundColor: _Xm.button),
                onPressed: hasNext ? onNext : () => Navigator.of(context).pop(),
                child: Text(hasNext ? t.advNext : t.advBackToCalendar,
                    style: AppTextStyles.display(size: 16, color: _Xm.snow)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// La case n'est pas (ou plus) jouable : pas encore ouverte, calendrier fermé.
class _NoCaseView extends StatelessWidget {
  final AdventCalendar advent;
  const _NoCaseView({required this.advent});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final text = advent.isOver
        ? t.advOver
        : (!advent.isActive ? t.advNotYet : (advent.allSolved ? t.advAllDone : t.advComeBack));
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [_backButton(context)]),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🎄', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 18),
                Text(text,
                    key: const ValueKey('adventNoCase'),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body(size: 16, weight: FontWeight.w700, color: _Xm.snow).copyWith(height: 1.4)),
                const SizedBox(height: 22),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _Xm.button),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(t.advBackToCalendar, style: AppTextStyles.display(size: 15, color: _Xm.snow)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
