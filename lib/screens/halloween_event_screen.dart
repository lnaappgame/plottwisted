import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../data/halloween_event_data.dart';
import '../l10n/app_localizations.dart';
import '../services/app_settings.dart';
import '../services/game_state.dart';
import '../services/halloween_event.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_view.dart';
import '../widgets/joker_style.dart';
import '../widgets/letter_keyboard.dart';
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
  static const red = Color(0xFFE0566E);
}

String _levelLabel(AppLocalizations t, int q) => [t.evtLevel1, t.evtLevel2, t.evtLevel3, t.evtLevel4][q];

/// L'event Halloween : la liste des 10 films mystère.
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
    final game = context.watch<GameState>();
    final event = game.halloween;
    final settings = context.watch<AppSettings>();
    final t = AppLocalizations.of(context);
    final locale = settings.locale;

    return SciFiScaffold(
      baseColor: _Hw.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Row(
              children: [
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: _Hw.panel, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.arrow_back, color: _Hw.pumpkinBright, size: 18),
                  ),
                ),
                Expanded(
                  child: Text(t.evtTitle,
                      textAlign: TextAlign.center, style: AppTextStyles.display(size: 26, color: _Hw.pumpkinBright)),
                ),
                const SizedBox(width: 36),
              ],
            ),
            const SizedBox(height: 4),
            Text(t.evtUntil, textAlign: TextAlign.center, style: AppTextStyles.body(size: 11, color: _Hw.muted)),
            const SizedBox(height: 12),
            Text(t.evtIntro,
                textAlign: TextAlign.center,
                style: AppTextStyles.body(size: 13, color: _Hw.cream).copyWith(height: 1.45)),
            const SizedBox(height: 14),
            _SkinsCard(settings: settings),
            const SizedBox(height: 14),
            Text(t.evtProgress(event.solvedCount, event.filmCount),
                textAlign: TextAlign.center, style: AppTextStyles.display(size: 16, color: _Hw.pumpkin)),
            const SizedBox(height: 10),
            if (!event.isActive)
              _Banner(text: t.evtOver)
            else if (event.allSolved)
              _Banner(text: t.evtAllDone)
            else if (event.waitingForTomorrow)
              _Banner(text: t.evtComeBack),
            for (var i = 0; i < event.filmCount; i++)
              _FilmCard(
                index: i,
                event: event,
                locale: locale,
                onTap: event.isActive && event.isAvailable(i)
                    ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => EventFilmScreen(index: i)))
                    : null,
              ),
          ],
        ),
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
      margin: const EdgeInsets.only(bottom: 10),
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

class _FilmCard extends StatelessWidget {
  final int index;
  final HalloweenEvent event;
  final String locale;
  final VoidCallback? onTap;
  const _FilmCard({required this.index, required this.event, required this.locale, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final p = event.progressOf(index);
    final available = event.isAvailable(index);
    final String status;
    Color statusColor = _Hw.muted;
    if (p.solved) {
      status = '${kHalloweenFilms[index].titleFor(locale)} (${kHalloweenFilms[index].year})';
      statusColor = _Hw.green;
    } else if (!available) {
      status = t.evtLockedDays(event.daysUntilAvailable(index));
    } else if (event.questionsDone(index)) {
      status = t.evtFindFilm;
      statusColor = _Hw.pumpkinBright;
    } else if (event.answeredCount(index) > 0) {
      status = t.evtInProgress(event.answeredCount(index) + 1);
      statusColor = _Hw.pumpkinBright;
    } else {
      status = t.evtToPlay;
      statusColor = _Hw.cream;
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        key: ValueKey('eventFilm$index'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: available ? _Hw.panel2 : _Hw.panel.withOpacity(0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: p.solved ? _Hw.green.withOpacity(0.6) : (available ? _Hw.pumpkin.withOpacity(0.55) : _Hw.panel2)),
          ),
          child: Row(
            children: [
              Text(p.solved ? '🎃' : (available ? '🎬' : '🔒'), style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.evtFilmNumber(index + 1), style: AppTextStyles.display(size: 15, color: _Hw.pumpkinBright)),
                    const SizedBox(height: 2),
                    Text(status, style: AppTextStyles.body(size: 12, weight: FontWeight.w600, color: statusColor)),
                  ],
                ),
              ),
              if (p.solved && event.perfect(index)) const Text('⭐', style: TextStyle(fontSize: 14)),
              if (onTap != null && !p.solved) const Icon(Icons.chevron_right, color: _Hw.pumpkinBright),
            ],
          ),
        ),
      ),
    );
  }
}

/// Un film de l'event : les 4 questions, puis les indices et la grille du titre.
class EventFilmScreen extends StatefulWidget {
  final int index;
  const EventFilmScreen({super.key, required this.index});

  @override
  State<EventFilmScreen> createState() => _EventFilmScreenState();
}

class _EventFilmScreenState extends State<EventFilmScreen> {
  // Réponse touchée pour la question affichée : couleurs juste/faux montrées
  // un instant avant de passer à la suivante.
  int? _picked;
  Timer? _next;
  bool _adBusy = false;

  HalloweenEvent get _event => context.read<GameState>().halloween;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final event = _event;
      if (event.questionsDone(widget.index) && !event.progressOf(widget.index).solved) {
        event.startGuess(widget.index);
      }
    });
  }

  @override
  void dispose() {
    _next?.cancel();
    super.dispose();
  }

  int get _currentQuestion => _event.answeredCount(widget.index);

  void _onChoice(int choice) {
    if (_picked != null) return;
    final settings = context.read<AppSettings>();
    final q = _currentQuestion;
    final right = _event.answer(widget.index, q, choice);
    if (settings.vibrationsOn) HapticFeedback.lightImpact();
    if (settings.sfxOn) {
      final sound = context.read<SoundService>();
      right ? sound.playCorrect() : sound.playWrong();
    }
    setState(() => _picked = choice);
    _next = Timer(const Duration(milliseconds: 1100), () {
      if (!mounted) return;
      setState(() => _picked = null);
      if (_event.questionsDone(widget.index)) _event.startGuess(widget.index);
    });
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 2)));
  }

  Future<void> _revealClueWithAd() async {
    if (_adBusy) return;
    final game = context.read<GameState>();
    setState(() => _adBusy = true);
    final earned = await game.adService.showRewardedAdForJoker();
    if (!mounted) return;
    setState(() => _adBusy = false);
    if (earned) {
      game.halloween.revealClue(widget.index);
    } else {
      _toast(AppLocalizations.of(context).commonAdUnavailable);
    }
  }

  void _validate() {
    final t = AppLocalizations.of(context);
    final settings = context.read<AppSettings>();
    final result = _event.validate();
    switch (result) {
      case 'incomplete':
        _toast(t.gameIncomplete);
      case 'wrong':
        if (settings.sfxOn) context.read<SoundService>().playWrong();
        _toast(t.evtWrong);
      case 'solved':
        if (settings.sfxOn) context.read<SoundService>().playCorrect();
        setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    final event = game.halloween;
    final t = AppLocalizations.of(context);
    final locale = context.watch<AppSettings>().locale;
    final film = kHalloweenFilms[widget.index];
    final p = event.progressOf(widget.index);
    final questionsDone = event.questionsDone(widget.index) && _picked == null;

    Widget body;
    if (p.solved) {
      body = _SolvedView(index: widget.index, locale: locale, reward: event.lastReward);
    } else if (!questionsDone) {
      body = _questionView(film, locale, t);
    } else {
      body = _guessView(event, locale, t);
    }

    return SciFiScaffold(
      baseColor: _Hw.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(color: _Hw.panel, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.arrow_back, color: _Hw.pumpkinBright, size: 18),
                    ),
                  ),
                  Expanded(
                    child: Text('🎃 ${t.evtFilmNumber(widget.index + 1)}',
                        textAlign: TextAlign.center, style: AppTextStyles.display(size: 24, color: _Hw.pumpkinBright)),
                  ),
                  const SizedBox(width: 36),
                ],
              ),
              const SizedBox(height: 14),
              body,
            ],
          ),
        ),
      ),
    );
  }

  Widget _questionView(EventFilm film, String locale, AppLocalizations t) {
    final event = _event;
    final q = _picked != null ? _currentQuestion - 1 : _currentQuestion;
    final question = film.questions[q];
    final choices = question.choicesFor(locale);
    final order = event.choiceOrder(widget.index, q);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var k = 0; k < 4; k++)
              Container(
                width: 34,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: k < q
                      ? (event.answeredRight(widget.index, k) ? _Hw.green : _Hw.red)
                      : (k == q ? _Hw.pumpkin : _Hw.panel2),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Text('${t.evtQuestion(q + 1)}  ·  ${_levelLabel(t, q)}',
            textAlign: TextAlign.center, style: AppTextStyles.display(size: 14, color: _Hw.pumpkin)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _Hw.panel2,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _Hw.violet),
          ),
          child: Text(question.questionFor(locale),
              textAlign: TextAlign.center,
              style: AppTextStyles.body(size: 17, weight: FontWeight.w600, color: _Hw.cream).copyWith(height: 1.4)),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.6,
          children: [
            for (final choice in order)
              _ChoiceButton(
                key: ValueKey('eventChoice$choice'),
                label: choices[choice],
                state: _picked == null
                    ? _ChoiceState.idle
                    : choice == 0
                        ? _ChoiceState.right
                        : (choice == _picked ? _ChoiceState.wrong : _ChoiceState.dim),
                onTap: () => _onChoice(choice),
              ),
          ],
        ),
      ],
    );
  }

  Widget _guessView(HalloweenEvent event, String locale, AppLocalizations t) {
    final hidden = event.hiddenClueCount(widget.index);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CluesCard(index: widget.index, event: event, locale: locale),
        if (hidden > 0) ...[
          const SizedBox(height: 10),
          OutlinedButton(
            key: const ValueKey('eventRevealClue'),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: _Hw.pumpkinBright)),
            onPressed: _adBusy ? null : _revealClueWithAd,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.play_circle_fill, color: _Hw.pumpkinBright, size: 18),
                const SizedBox(width: 8),
                Text(t.evtRevealClue(hidden),
                    style: AppTextStyles.body(size: 13, weight: FontWeight.w700, color: _Hw.pumpkinBright)),
              ],
            ),
          ),
        ],
        const SizedBox(height: 18),
        Text(t.evtFindTitle, textAlign: TextAlign.center, style: AppTextStyles.display(size: 16, color: _Hw.pumpkin)),
        const SizedBox(height: 10),
        _EventAnswerRow(event: event),
        const SizedBox(height: 14),
        _EventLetterPool(event: event),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: event.clearGuess,
                style: OutlinedButton.styleFrom(side: const BorderSide(color: _Hw.pumpkin)),
                child: Text(t.commonClear, style: AppTextStyles.display(size: 15, color: _Hw.pumpkin)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                key: const ValueKey('eventValidate'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB4561A)),
                onPressed: _validate,
                child: Text(t.commonValidate, style: AppTextStyles.display(size: 15, color: _Hw.cream)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

enum _ChoiceState { idle, right, wrong, dim }

class _ChoiceButton extends StatelessWidget {
  final String label;
  final _ChoiceState state;
  final VoidCallback onTap;
  const _ChoiceButton({super.key, required this.label, required this.state, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final (bg, border, text) = switch (state) {
      _ChoiceState.idle => (_Hw.panel, _Hw.pumpkin.withOpacity(0.5), _Hw.cream),
      _ChoiceState.right => (_Hw.green.withOpacity(0.25), _Hw.green, _Hw.cream),
      _ChoiceState.wrong => (_Hw.red.withOpacity(0.25), _Hw.red, _Hw.cream),
      _ChoiceState.dim => (_Hw.panel, _Hw.panel2, _Hw.muted),
    };
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: state == _ChoiceState.idle ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: 1.5),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body(size: 13.5, weight: FontWeight.w700, color: text)),
        ),
      ),
    );
  }
}

/// À la place du pitch : les bonnes réponses en vert (les indices), les
/// questions ratées en rouge (indice caché, sauf s'il a été dévoilé par pub).
class _CluesCard extends StatelessWidget {
  final int index;
  final HalloweenEvent event;
  final String locale;
  const _CluesCard({required this.index, required this.event, required this.locale});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final film = kHalloweenFilms[index];
    final p = event.progressOf(index);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_Hw.panel2, _Hw.panel]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _Hw.pumpkin, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.evtCluesTitle, style: AppTextStyles.display(size: 14, color: _Hw.pumpkin)),
          const SizedBox(height: 8),
          for (var q = 0; q < 4; q++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.answeredRight(index, q) ? '✅' : (p.adRevealed.contains(q) ? '🔓' : '❌'),
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: event.clueFound(index, q)
                        ? Text(film.questions[q].answerFor(locale),
                            key: ValueKey('eventClue$q'),
                            style: AppTextStyles.body(size: 16, weight: FontWeight.w700, color: _Hw.green))
                        : Text(film.questions[q].questionFor(locale),
                            key: ValueKey('eventMissed$q'),
                            style: AppTextStyles.body(size: 13, color: _Hw.red).copyWith(height: 1.35)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 6),
          Text(t.evtCluesHint, style: AppTextStyles.body(size: 10.5, color: _Hw.muted)),
        ],
      ),
    );
  }
}

class _EventAnswerRow extends StatelessWidget {
  final HalloweenEvent event;
  const _EventAnswerRow({required this.event});

  @override
  Widget build(BuildContext context) {
    final words = <List<Widget>>[];
    var current = <Widget>[];
    for (var i = 0; i < event.slots.length; i++) {
      final slot = event.slots[i];
      if (slot.isSpace) {
        if (current.isNotEmpty) words.add(current);
        current = [];
        continue;
      }
      if (slot.isAuto) {
        current.add(_Blank(text: slot.char, auto: true));
        continue;
      }
      final tileId = event.guess[i];
      final letter = tileId != null ? event.pool[tileId].letter : null;
      current.add(GestureDetector(
        onTap: () => event.onBlankTap(i),
        child: _Blank(text: letter ?? '_', filled: letter != null, cursor: i == event.cursorIndex),
      ));
    }
    if (current.isNotEmpty) words.add(current);
    return LayoutBuilder(
      builder: (context, constraints) => Wrap(
        alignment: WrapAlignment.center,
        spacing: 14,
        runSpacing: 10,
        children: [
          for (final w in words)
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth),
              child: FittedBox(fit: BoxFit.scaleDown, child: Row(mainAxisSize: MainAxisSize.min, children: w)),
            ),
        ],
      ),
    );
  }
}

class _Blank extends StatelessWidget {
  final String text;
  final bool cursor;
  final bool filled;
  final bool auto;
  const _Blank({required this.text, this.cursor = false, this.filled = false, this.auto = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 38,
      margin: const EdgeInsets.only(right: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: cursor ? _Hw.pumpkin.withOpacity(0.22) : null,
        border: Border(bottom: BorderSide(color: auto ? _Hw.muted : _Hw.pumpkin, width: 3)),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      ),
      child: Text(text,
          style: AppTextStyles.tile(size: 19, color: filled || auto ? _Hw.pumpkinBright : Colors.transparent)),
    );
  }
}

class _EventLetterPool extends StatelessWidget {
  final HalloweenEvent event;
  const _EventLetterPool({required this.event});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    if (settings.inputMode != 'tiles') {
      return LetterKeyboard(
        pool: event.pool,
        layout: settings.inputMode,
        colors: AppColors(false),
        onTap: event.onLetterTap,
      );
    }
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final tile in event.pool)
          GestureDetector(
            onTap: tile.used ? null : () => event.onLetterTap(tile),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: tile.used ? 0 : 1,
              child: Container(
                width: 38,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _Hw.panel,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _Hw.pumpkin.withOpacity(0.45)),
                ),
                child: Text(tile.letter, style: AppTextStyles.tile(size: 17, color: _Hw.cream)),
              ),
            ),
          ),
      ],
    );
  }
}

/// Film trouvé : titre, indices, et ce que le joueur vient de gagner.
class _SolvedView extends StatelessWidget {
  final int index;
  final String locale;
  final EventSolveReward? reward;
  const _SolvedView({required this.index, required this.locale, required this.reward});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final event = context.watch<GameState>().halloween;
    final film = kHalloweenFilms[index];
    // Le gain n'est montré que juste après la victoire (pas en revenant voir
    // un film déjà trouvé).
    final fresh = reward != null && event.guessingFilm == index;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t.evtSolvedTitle, textAlign: TextAlign.center, style: AppTextStyles.display(size: 16, color: _Hw.pumpkin)),
        const SizedBox(height: 6),
        Text(film.titleFor(locale),
            key: const ValueKey('eventSolvedTitle'),
            textAlign: TextAlign.center,
            style: AppTextStyles.display(size: 30, color: _Hw.pumpkinBright)),
        Text(film.year, textAlign: TextAlign.center, style: AppTextStyles.body(size: 13, color: _Hw.muted)),
        const SizedBox(height: 14),
        _CluesCard(index: index, event: event, locale: locale),
        if (fresh) ...[
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
                Text('${reward!.joker.icon}  ${t.evtRewardJoker(jokerName(reward!.joker, t))}',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body(size: 15, weight: FontWeight.w700, color: _Hw.cream)),
                if (event.perfect(index))
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(t.evtRewardPerfect,
                        textAlign: TextAlign.center, style: AppTextStyles.body(size: 12, color: _Hw.pumpkinBright)),
                  ),
                if (reward!.pumpkinUnlocked) ...[
                  const SizedBox(height: 12),
                  const AvatarView(avatar: kPumpkinAvatar, radius: 30, background: _Hw.panel2),
                  const SizedBox(height: 6),
                  Text(t.evtAvatarUnlocked,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body(size: 13, weight: FontWeight.w700, color: _Hw.pumpkinBright)),
                ],
                if (reward!.finalReward) ...[
                  const SizedBox(height: 12),
                  const AvatarView(avatar: kFirePumpkinAvatar, radius: 36, background: _Hw.panel2),
                  const SizedBox(height: 6),
                  Text(t.evtFinalReward,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body(size: 13, weight: FontWeight.w700, color: _Hw.pumpkinBright)),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        ElevatedButton(
          key: const ValueKey('eventContinue'),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB4561A)),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.evtContinue, style: AppTextStyles.display(size: 15, color: _Hw.cream)),
        ),
      ],
    );
  }
}
