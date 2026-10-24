import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../data/halloween_pitches_data.dart';
import '../l10n/app_localizations.dart';
import '../models/joker.dart';
import '../services/app_settings.dart';
import '../services/game_state.dart';
import '../services/halloween_event.dart';
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

/// Couleurs de l'event : orange citrouille sur violet nuit.
class _Hw {
  static const pumpkin = Color(0xFFF28C28);
  static const pumpkinBright = Color(0xFFFFB347);
  static const violet = Color(0xFF7B47A8);
  static const bg = Color(0xFF0D0912);
  static const panel = Color(0xFF1B1326);
  static const panel2 = Color(0xFF251A33);
  static const cream = Color(0xFFECE3D2);
  static const muted = Color(0xFFA996B8);
  static const green = Color(0xFF7FB37F);
  static const button = Color(0xFFB4561A);
}

Widget _backButton(BuildContext context) => InkWell(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: _Hw.panel, borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.arrow_back, color: _Hw.pumpkinBright, size: 18),
      ),
    );

/// L'event Halloween : la présentation (le point de vue des méchants), les
/// avatars à gagner et l'avancement, puis « JOUER ».
class HalloweenEventScreen extends StatefulWidget {
  const HalloweenEventScreen({super.key});

  @override
  State<HalloweenEventScreen> createState() => _HalloweenEventScreenState();
}

class _HalloweenEventScreenState extends State<HalloweenEventScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<GameState>().halloween.markVisited();
    });
  }

  @override
  Widget build(BuildContext context) {
    final event = context.watch<GameState>().halloween;
    final settings = context.watch<AppSettings>();
    final t = AppLocalizations.of(context);
    final canPlay = event.isActive && event.currentPitch != null;

    return SciFiScaffold(
      baseColor: _Hw.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Row(
              children: [
                _backButton(context),
                Expanded(
                  child: Text(t.evtTitle,
                      textAlign: TextAlign.center, style: AppTextStyles.display(size: 26, color: _Hw.pumpkinBright)),
                ),
                const SizedBox(width: 36),
              ],
            ),
            const SizedBox(height: 4),
            Text(t.evtUntil, textAlign: TextAlign.center, style: AppTextStyles.body(size: 11, color: _Hw.muted)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_Hw.panel2, _Hw.panel]),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _Hw.violet, width: 1.5),
              ),
              child: Column(
                children: [
                  const Text('🧛 🎃 🦇', style: TextStyle(fontSize: 26)),
                  const SizedBox(height: 8),
                  Text(t.evtIntroTitle,
                      textAlign: TextAlign.center, style: AppTextStyles.display(size: 18, color: _Hw.pumpkin)),
                  const SizedBox(height: 10),
                  Text(t.evtIntro,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body(size: 14, color: _Hw.cream)
                          .copyWith(height: 1.5, fontStyle: FontStyle.italic)),
                  const SizedBox(height: 10),
                  Text(t.evtIntro2,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body(size: 14, weight: FontWeight.w700, color: _Hw.pumpkinBright)
                          .copyWith(height: 1.4)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(t.evtRules,
                textAlign: TextAlign.center, style: AppTextStyles.body(size: 11.5, color: _Hw.muted).copyWith(height: 1.4)),
            const SizedBox(height: 14),
            _SkinsCard(settings: settings),
            const SizedBox(height: 16),
            Text(t.evtProgress(event.solvedCount, event.pitchCount),
                key: const ValueKey('eventProgress'),
                textAlign: TextAlign.center,
                style: AppTextStyles.display(size: 16, color: _Hw.pumpkin)),
            const SizedBox(height: 8),
            _ProgressBar(value: event.solvedCount / event.pitchCount),
            const SizedBox(height: 14),
            if (!event.isActive)
              _Banner(text: t.evtOver)
            else if (event.allSolved)
              _Banner(text: t.evtAllDone)
            else if (event.waitingForTomorrow)
              _Banner(text: t.evtComeBack),
            if (canPlay)
              ElevatedButton(
                key: const ValueKey('eventPlay'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _Hw.button,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () =>
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EventPitchScreen())),
                child: Text(t.evtPlay, style: AppTextStyles.display(size: 20, color: _Hw.cream)),
              ),
          ],
        ),
      ),
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
        backgroundColor: _Hw.panel2,
        valueColor: const AlwaysStoppedAnimation(_Hw.pumpkin),
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _Hw.violet.withOpacity(0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _Hw.violet),
      ),
      child: Text(text,
          textAlign: TextAlign.center, style: AppTextStyles.body(size: 13, weight: FontWeight.w700, color: _Hw.cream)),
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
              child: AvatarView(avatar: id, radius: 26, background: _Hw.panel2),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(unlocked ? Icons.check_circle : Icons.lock, size: 13, color: unlocked ? _Hw.green : _Hw.muted),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(label,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body(size: 10.5, color: unlocked ? _Hw.cream : _Hw.muted)),
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
        color: _Hw.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _Hw.pumpkin.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Text(t.evtSkinsTitle, style: AppTextStyles.display(size: 13, color: _Hw.pumpkin)),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              skin(kPumpkinAvatar, t.evtSkinPumpkin),
              skin(kFirePumpkinAvatar, t.evtSkinFire),
            ],
          ),
        ],
      ),
    );
  }
}

/// Les pitchs de l'event, l'un après l'autre, comme dans le jeu principal :
/// tuiles ou clavier, Révéler / Éliminer / Révéler un mot, une pub pour un
/// joker, VALIDER et « Passer, j'y reviendrai ».
class EventPitchScreen extends StatefulWidget {
  const EventPitchScreen({super.key});

  @override
  State<EventPitchScreen> createState() => _EventPitchScreenState();
}

class _EventPitchScreenState extends State<EventPitchScreen> {
  final JokerFx _fx = JokerFx();
  final ScrollController _scroll = ScrollController(keepScrollOffset: false);

  // Bonne réponse : le titre reste 1 s en vert avant l'écran de victoire.
  bool _revealing = false;
  bool _showResult = false;
  Timer? _revealTimer;
  bool _adBusy = false;

  HalloweenEvent get _event => context.read<GameState>().halloween;

  @override
  void initState() {
    super.initState();
    _event.loadCurrent(notify: false);
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

  void _scrollToTop() {
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _onValidate() {
    final settings = context.read<AppSettings>();
    final sound = context.read<SoundService>();
    final t = AppLocalizations.of(context);
    if (settings.vibrationsOn) HapticFeedback.lightImpact();
    switch (_event.validate()) {
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
    final joker = _event.lastReward?.joker;
    setState(() => _showResult = false);
    _event.loadCurrent();
    _scrollToTop();
    // L'étoile du joker gagné rejoint la barre de jokers du pitch suivant.
    if (joker != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fx.reward(grants: [RewardGrant(joker, 1)]);
      });
    }
  }

  void _onSkip() {
    if (!_event.skipCurrent()) {
      _toast(AppLocalizations.of(context).evtSkipLast);
      return;
    }
    _scrollToTop();
  }

  Future<void> _onWatchAdForJoker() async {
    if (_adBusy) return;
    final game = context.read<GameState>();
    _adBusy = true;
    final earned = await game.adService.showRewardedAdForJoker();
    _adBusy = false;
    if (!mounted) return;
    if (earned) {
      _fx.reward(grants: [RewardGrant(_event.grantAdJoker(), 1)]);
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
        backgroundColor: _Hw.panel2,
        title: Text(t.nerfRevealWordTitle,
            textAlign: TextAlign.center, style: AppTextStyles.display(size: 20, color: _Hw.pumpkinBright)),
        content: Text(t.nerfRevealWordBody(_event.revealWordNerfCount),
            textAlign: TextAlign.center, style: AppTextStyles.body(size: 14, color: _Hw.cream).copyWith(height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(t.commonCancel, style: AppTextStyles.body(size: 13, color: _Hw.muted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _Hw.button),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(t.nerfRevealWordUse, style: AppTextStyles.body(size: 14, weight: FontWeight.w700, color: _Hw.cream)),
          ),
        ],
      ),
    );
    game.markRevealWordNerfExplained();
    return use ?? false;
  }

  Future<void> _onJoker(JokerKind kind, Color color) async {
    final event = _event;
    final game = context.read<GameState>();
    switch (kind) {
      case JokerKind.reveal:
        final slot = event.useRevealJoker();
        if (slot != null) _fx.beam(kind, color, ['slot:$slot']);
      case JokerKind.eliminate:
        final tiles = event.useEliminateJoker();
        _fx.beam(kind, color, [for (final i in tiles) 'tile:$i']);
      case JokerKind.revealWord:
        if (event.revealWordIsNerfed && !game.revealWordNerfExplained && !await _confirmRevealWordNerf()) return;
        if (!mounted) return;
        final slots = event.useRevealWordJoker();
        _fx.beam(kind, color, [for (final i in slots) 'slot:$i']);
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    final event = game.halloween;
    final settings = context.watch<AppSettings>();
    final t = AppLocalizations.of(context);
    final locale = settings.locale;
    final index = event.loadedPitch;

    if (index == null) {
      return SciFiScaffold(baseColor: _Hw.bg, body: SafeArea(child: _NoPitchView(event: event)));
    }

    final pitch = kHalloweenPitches[index];
    final number = (event.solvedCount + (_showResult ? 0 : 1)).clamp(1, event.pitchCount).toInt();
    return SciFiScaffold(
      baseColor: _Hw.bg,
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
                          child: Text('🎃 HALLOWEEN',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.display(size: 26, color: _Hw.pumpkinBright)),
                        ),
                        const SizedBox(width: 36),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(t.evtPitchNumber(number, event.pitchCount),
                            key: const ValueKey('eventPitchNumber'),
                            style: AppTextStyles.display(size: 15, color: _Hw.pumpkin)),
                        const SizedBox(width: 12),
                        Expanded(child: _ProgressBar(value: event.solvedCount / event.pitchCount)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      key: const ValueKey('eventPitchCard'),
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_Hw.panel2, _Hw.panel]),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _Hw.pumpkin, width: 1.5),
                      ),
                      child: Text(pitch.pitchFor(locale),
                          style: AppTextStyles.body(size: 17, color: _Hw.cream).copyWith(height: 1.5)),
                    ),
                    const SizedBox(height: 16),
                    AnswerRow(grid: event, fx: _fx, highlightSolved: _revealing || _showResult),
                    const SizedBox(height: 14),
                    LetterPool(grid: event, fx: _fx),
                    const SizedBox(height: 14),
                    _EventJokerBar(
                      fx: _fx,
                      game: game,
                      onJoker: _onJoker,
                      onWatchAd: _onWatchAdForJoker,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: event.clearLastLetter,
                            child: Text(t.commonClear, style: AppTextStyles.display(size: 15, color: AppColors.gold)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            key: const ValueKey('eventValidate'),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.crimson),
                            onPressed: _onValidate,
                            child: Text(t.commonValidate, style: AppTextStyles.display(size: 15, color: _Hw.cream)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      key: const ValueKey('eventSkip'),
                      onPressed: _onSkip,
                      child: Text(t.gameSkipLater,
                          style: AppTextStyles.body(size: 12, weight: FontWeight.w700, color: AppColors.gold)),
                    ),
                  ],
                ),
              ),
            ),
            Positioned.fill(child: JokerFxLayer(fx: _fx)),
            if (_showResult)
              Positioned.fill(
                child: _ResultOverlay(
                  pitch: pitch,
                  locale: locale,
                  reward: event.lastReward,
                  hasNext: event.currentPitch != null,
                  onNext: _onNext,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Révéler, Éliminer et Révéler un mot (stock du jeu principal), et la pub
/// « Gagner un joker ».
class _EventJokerBar extends StatelessWidget {
  final JokerFx fx;
  final GameState game;
  final void Function(JokerKind kind, Color color) onJoker;
  final VoidCallback onWatchAd;
  const _EventJokerBar({required this.fx, required this.game, required this.onJoker, required this.onWatchAd});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final colors = AppColors(settings.isLightTheme, colorblind: settings.colorblindMode);
    final t = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: fx,
      builder: (context, _) => Column(
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 12,
            children: [
              for (final kind in kEventJokers)
                Builder(builder: (context) {
                  final shown = (game.countOf(kind) - fx.pending(kind)).clamp(0, 999).toInt();
                  final color = jokerColor(kind, colors);
                  return JokerButton(
                    key: fx.key('joker:${kind.name}'),
                    label: jokerName(kind, t),
                    icon: kind.icon,
                    count: shown,
                    color: color,
                    colors: colors,
                    active: false,
                    disabled: false,
                    tappable: shown > 0,
                    subtitle: null,
                    onTap: () => onJoker(kind, color),
                  );
                }),
            ],
          ),
          const SizedBox(height: 10),
          WinJokerButton(key: const ValueKey('eventWinJoker'), label: t.jokerWinOne, colors: colors, onTap: onWatchAd),
        ],
      ),
    );
  }
}

/// Pitch trouvé : le film, ce que le joueur gagne, puis le pitch suivant.
class _ResultOverlay extends StatelessWidget {
  final EventPitch pitch;
  final String locale;
  final EventSolveReward? reward;
  final bool hasNext;
  final VoidCallback onNext;
  const _ResultOverlay(
      {required this.pitch, required this.locale, required this.reward, required this.hasNext, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final reward = this.reward;
    return Container(
      color: Colors.black.withOpacity(0.72),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
          decoration: BoxDecoration(
            color: _Hw.panel2,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _Hw.pumpkin, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(t.evtWellDone, textAlign: TextAlign.center, style: AppTextStyles.display(size: 24, color: _Hw.green)),
              const SizedBox(height: 10),
              Text(t.evtSolvedTitle, textAlign: TextAlign.center, style: AppTextStyles.body(size: 12, color: _Hw.muted)),
              const SizedBox(height: 4),
              Text(pitch.titleFor(locale),
                  key: const ValueKey('eventSolvedTitle'),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.display(size: 28, color: _Hw.pumpkinBright)),
              Text(pitch.year, textAlign: TextAlign.center, style: AppTextStyles.body(size: 13, color: _Hw.muted)),
              if (reward != null && (reward.joker != null || reward.pumpkinUnlocked || reward.finalReward)) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _Hw.violet.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _Hw.violet),
                  ),
                  child: Column(
                    children: [
                      if (reward.joker != null)
                        Text('${reward.joker!.icon}  ${t.evtRewardJoker(jokerName(reward.joker!, t))}',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.body(size: 15, weight: FontWeight.w700, color: _Hw.cream)),
                      if (reward.pumpkinUnlocked) ...[
                        const SizedBox(height: 10),
                        const AvatarView(avatar: kPumpkinAvatar, radius: 30, background: _Hw.panel),
                        const SizedBox(height: 6),
                        Text(t.evtAvatarUnlocked,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.body(size: 13, weight: FontWeight.w700, color: _Hw.pumpkinBright)),
                      ],
                      if (reward.finalReward) ...[
                        const SizedBox(height: 10),
                        const AvatarView(avatar: kFirePumpkinAvatar, radius: 36, background: _Hw.panel),
                        const SizedBox(height: 6),
                        Text(t.evtFinalReward,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.body(size: 13, weight: FontWeight.w700, color: _Hw.pumpkinBright)),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              ElevatedButton(
                key: const ValueKey('eventNext'),
                style: ElevatedButton.styleFrom(backgroundColor: _Hw.button),
                onPressed: hasNext ? onNext : () => Navigator.of(context).pop(),
                child: Text(hasNext ? t.evtNext : t.evtBackToEvent,
                    style: AppTextStyles.display(size: 16, color: _Hw.cream)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Plus de pitch à jouer aujourd'hui (ou plus du tout).
class _NoPitchView extends StatelessWidget {
  final HalloweenEvent event;
  const _NoPitchView({required this.event});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final text = !event.isActive ? t.evtOver : (event.allSolved ? t.evtAllDone : t.evtComeBack);
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
                const Text('🎃', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 18),
                Text(text,
                    key: const ValueKey('eventNoPitch'),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body(size: 16, weight: FontWeight.w700, color: _Hw.cream).copyWith(height: 1.4)),
                const SizedBox(height: 22),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _Hw.button),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(t.evtBackToEvent, style: AppTextStyles.display(size: 15, color: _Hw.cream)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
