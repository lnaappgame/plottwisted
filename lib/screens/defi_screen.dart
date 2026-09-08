import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/defi.dart';
import '../services/app_settings.dart';
import '../services/defi_state.dart';
import '../services/game_state.dart';
import '../theme/app_theme.dart';

String _formatDuration(int seconds) {
  final minutes = seconds ~/ 60;
  final secs = seconds % 60;
  return minutes > 0 ? '${minutes}min ${secs.toString().padLeft(2, '0')}s' : '${secs}s';
}

class DefiScreen extends StatefulWidget {
  const DefiScreen({super.key});

  @override
  State<DefiScreen> createState() => _DefiScreenState();
}

class _DefiScreenState extends State<DefiScreen> {
  Timer? _ticker;
  int _countdown = 0; // 0 = pas de décompte en cours
  bool _busyAd = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DefiState>().ensureFresh(context.read<AppSettings>().firstLaunchDay);
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _onCommencer(Defi defi, {required bool bonus}) {
    setState(() => _countdown = 3);
    context.read<DefiState>().startDefi(defi, bonus: bonus);
    Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _countdown--);
      if (_countdown <= 0) t.cancel();
    });
  }

  Future<void> _onWatchAdReplay(Defi defi, {required bool bonus}) async {
    if (_busyAd) return;
    setState(() => _busyAd = true);
    final adService = context.read<GameState>().adService;
    final earned = await adService.showRewardedAdForJoker();
    if (!mounted) return;
    setState(() => _busyAd = false);
    if (earned) {
      _onCommencer(defi, bonus: bonus);
    } else {
      _toast(AppLocalizations.of(context).commonAdUnavailable);
    }
  }

  Future<void> _onWatchAdBonus() async {
    if (_busyAd) return;
    final defiState = context.read<DefiState>();
    final bonus = defiState.piocherBonus();
    if (bonus == null) return;
    setState(() => _busyAd = true);
    final adService = context.read<GameState>().adService;
    final earned = await adService.showRewardedAdForJoker();
    if (!mounted) return;
    setState(() => _busyAd = false);
    if (earned) {
      _onCommencer(bonus, bonus: true);
    } else {
      _toast(AppLocalizations.of(context).commonAdUnavailable);
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 2)));
  }

  void _showRules(AppColors colors) {
    final t = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: colors.bgPanel2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.commonRulesTitle, textAlign: TextAlign.center, style: AppTextStyles.display(size: 20)),
                  const SizedBox(height: 16),
                  _RuleLine(t.defiRule1, colors),
                  _RuleLine(t.defiRule2, colors),
                  _RuleLine(t.defiRule3, colors),
                  _RuleLine(t.defiRule4, colors),
                  _RuleLine(t.defiRule5, colors),
                  _RuleLine(t.defiRule6, colors),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.crimson),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(t.commonClose, style: AppTextStyles.display(size: 15, color: colors.cream)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final colors = AppColors(settings.isLightTheme, colorblind: settings.colorblindMode);
    final defiState = context.watch<DefiState>();

    return Scaffold(
      backgroundColor: colors.bgDeep,
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
                      decoration: BoxDecoration(color: colors.bgPanel, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.arrow_back, color: AppColors.goldBright, size: 18),
                    ),
                  ),
                  Expanded(
                    child: Text(AppLocalizations.of(context).defiTitle, textAlign: TextAlign.center, style: AppTextStyles.display(size: 20)),
                  ),
                  InkWell(
                    onTap: () => _showRules(colors),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(color: colors.bgPanel, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.help_outline, color: AppColors.goldBright, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (_countdown > 0)
                _CountdownView(count: _countdown, colors: colors)
              else if (defiState.activeDefi == null)
                _IntroView(defiState: defiState, colors: colors, onCommencer: () => _onCommencer(defiState.defiDuJour, bonus: false))
              else if (!defiState.solved)
                _PlayingView(defiState: defiState, colors: colors)
              else
                _ResultView(
                  defiState: defiState,
                  colors: colors,
                  busy: _busyAd,
                  onReplaySame: () => _onWatchAdReplay(defiState.activeDefi!, bonus: defiState.isBonus),
                  onBonus: defiState.peutPiocherBonus ? _onWatchAdBonus : null,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountdownView extends StatelessWidget {
  final int count;
  final AppColors colors;
  const _CountdownView({required this.count, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Text('$count', style: AppTextStyles.display(size: 72, color: AppColors.goldBright)),
      ),
    );
  }
}

class _IntroView extends StatelessWidget {
  final DefiState defiState;
  final AppColors colors;
  final VoidCallback onCommencer;
  const _IntroView({required this.defiState, required this.colors, required this.onCommencer});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final locale = context.watch<AppSettings>().locale;
    final defi = defiState.defiDuJour;
    final best = defiState.bestTimeFor(defi.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.center,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.gold.withOpacity(0.4)),
            ),
            child: Text(defi.typeLabelFor(locale).toUpperCase(),
                style: AppTextStyles.body(size: 12, weight: FontWeight.w700, color: AppColors.goldBright)),
          ),
        ),
        const SizedBox(height: 14),
        Text(defi.communFor(locale), textAlign: TextAlign.center, style: AppTextStyles.display(size: 30)),
        const SizedBox(height: 10),
        Text(defi.consigneFor(locale), textAlign: TextAlign.center, style: AppTextStyles.body(size: 14, color: colors.cream).copyWith(height: 1.5)),
        const SizedBox(height: 10),
        Text(t.defiCasesInfo(defi.cases.length),
            textAlign: TextAlign.center, style: AppTextStyles.body(size: 12, color: colors.muted)),
        if (best != null) ...[
          const SizedBox(height: 10),
          Text(t.defiBestTime(_formatDuration(best)),
              textAlign: TextAlign.center, style: AppTextStyles.body(size: 13, weight: FontWeight.w700, color: AppColors.goldBright)),
        ],
        const SizedBox(height: 26),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.crimson, padding: const EdgeInsets.symmetric(vertical: 14)),
          onPressed: onCommencer,
          child: Text(t.defiStart, style: AppTextStyles.display(size: 18, color: colors.cream)),
        ),
      ],
    );
  }
}

class _PlayingView extends StatelessWidget {
  final DefiState defiState;
  final AppColors colors;
  const _PlayingView({required this.defiState, required this.colors});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<AppSettings>().locale;
    final defi = defiState.activeDefi!;
    final elapsed = DateTime.now().difference(defiState.startTime!).inSeconds;
    final indice = defiState.indiceActuel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('⏱️ ${_formatDuration(elapsed)}', style: AppTextStyles.body(size: 14, weight: FontWeight.w700, color: colors.cream)),
            if (defiState.penaltySeconds > 0)
              Text('+${defiState.penaltySeconds}s', style: AppTextStyles.body(size: 14, weight: FontWeight.w700, color: AppColors.crimsonBright)),
          ],
        ),
        const SizedBox(height: 10),
        Text(defi.communFor(locale), textAlign: TextAlign.center,
            style: AppTextStyles.display(size: 22, color: AppColors.goldBright)),
        const SizedBox(height: 12),
        if (indice != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [colors.bgPanel2, colors.bgPanel]),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.gold.withOpacity(0.35)),
            ),
            child: Text(indice.indiceFor(locale), style: AppTextStyles.body(size: 15, color: colors.cream).copyWith(height: 1.6)),
          ),
        const SizedBox(height: 18),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: defiState.displayOrder.map((idx) {
            return _CaseButton(
              key: ValueKey(idx),
              reponse: defi.cases[idx].reponseFor(locale),
              colors: colors,
              hidden: defiState.isCaseHidden(idx),
              isTapped: defiState.feedbackCaseIndex == idx,
              tappedCorrect: defiState.feedbackCaseIndex == idx ? defiState.feedbackCorrect : null,
              isRevealing: defiState.revealCaseIndex == idx,
              onTap: () => context.read<DefiState>().onCaseTapped(idx),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Une case-réponse, avec son retour visuel après un tap : flash vert (bonne
/// réponse tapée) ou rouge (mauvaise réponse tapée), ou clignotement doré↔
/// vert quand elle est la vraie bonne réponse révélée suite à une erreur
/// ailleurs. Disparaît (fondu) une fois que [DefiState] la marque masquée.
class _CaseButton extends StatefulWidget {
  final String reponse;
  final AppColors colors;
  final bool hidden;
  final bool isTapped;
  final bool? tappedCorrect;
  final bool isRevealing;
  final VoidCallback onTap;
  const _CaseButton({
    super.key,
    required this.reponse,
    required this.colors,
    required this.hidden,
    required this.isTapped,
    required this.tappedCorrect,
    required this.isRevealing,
    required this.onTap,
  });

  @override
  State<_CaseButton> createState() => _CaseButtonState();
}

class _CaseButtonState extends State<_CaseButton> with SingleTickerProviderStateMixin {
  late final AnimationController _blink;

  @override
  void initState() {
    super.initState();
    _blink = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    if (widget.isRevealing) _blink.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _CaseButton old) {
    super.didUpdateWidget(old);
    if (widget.isRevealing && !_blink.isAnimating) {
      _blink.repeat(reverse: true);
    } else if (!widget.isRevealing && _blink.isAnimating) {
      _blink.stop();
      _blink.value = 0;
    }
  }

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: widget.isTapped
            ? (widget.tappedCorrect == true ? AppColors.green.withOpacity(0.35) : AppColors.crimson.withOpacity(0.35))
            : null,
        border: Border.all(
          color: widget.isTapped
              ? (widget.tappedCorrect == true ? AppColors.greenBright : AppColors.crimsonBright)
              : AppColors.gold,
          width: 1.5,
        ),
      ),
      child: Text(widget.reponse, style: AppTextStyles.body(size: 13, weight: FontWeight.w700, color: colors.cream)),
    );

    if (widget.isRevealing) {
      content = AnimatedBuilder(
        animation: _blink,
        builder: (context, child) {
          final t = _blink.value;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Color.lerp(Colors.transparent, AppColors.green.withOpacity(0.35), t),
              border: Border.all(color: Color.lerp(AppColors.gold, AppColors.greenBright, t)!, width: 1.5),
            ),
            child: Text(widget.reponse, style: AppTextStyles.body(size: 13, weight: FontWeight.w700, color: colors.cream)),
          );
        },
      );
    }

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: widget.hidden ? 0 : 1,
      child: IgnorePointer(
        ignoring: widget.hidden,
        child: GestureDetector(onTap: widget.onTap, child: content),
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  final DefiState defiState;
  final AppColors colors;
  final bool busy;
  final VoidCallback onReplaySame;
  final VoidCallback? onBonus;
  const _ResultView({
    required this.defiState,
    required this.colors,
    required this.busy,
    required this.onReplaySame,
    required this.onBonus,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final locale = context.watch<AppSettings>().locale;
    final defi = defiState.activeDefi!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t.defiCompleted, textAlign: TextAlign.center, style: AppTextStyles.display(size: 22, color: AppColors.goldBright)),
        const SizedBox(height: 6),
        Text(defi.communFor(locale), textAlign: TextAlign.center, style: AppTextStyles.body(size: 15, weight: FontWeight.w700, color: colors.cream)),
        if (defiState.isBonus) ...[
          const SizedBox(height: 4),
          Text(t.defiBonusLabel, textAlign: TextAlign.center, style: AppTextStyles.body(size: 11, color: colors.muted)),
        ],
        const SizedBox(height: 18),
        _TimeRow(t.defiTimeReal, _formatDuration(defiState.realSeconds!), AppColors.greenBright, colors),
        _TimeRow(t.defiTimePenalties, '+${defiState.penaltySeconds}s', AppColors.crimsonBright, colors),
        const Divider(height: 24),
        _TimeRow(t.defiTimeTotal, _formatDuration(defiState.totalSeconds!), AppColors.goldBright, colors, bold: true),
        const SizedBox(height: 12),
        Text(
          defiState.isNewBest == true ? t.defiNewRecord : t.defiBestTimeResult(_formatDuration(defiState.bestTimeFor(defi.id)!)),
          textAlign: TextAlign.center,
          style: AppTextStyles.body(size: 13, weight: FontWeight.w700, color: AppColors.goldBright),
        ),
        const SizedBox(height: 22),
        OutlinedButton(
          onPressed: busy ? null : onReplaySame,
          style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.gold)),
          child: Text(
            busy ? t.commonLoading : t.defiWatchAdReplay,
            style: AppTextStyles.body(size: 13, weight: FontWeight.w700, color: AppColors.gold),
          ),
        ),
        const SizedBox(height: 10),
        if (onBonus != null)
          OutlinedButton(
            onPressed: busy ? null : onBonus,
            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.gold)),
            child: Text(
              busy ? t.commonLoading : t.defiWatchAdBonus,
              style: AppTextStyles.body(size: 13, weight: FontWeight.w700, color: AppColors.gold),
            ),
          )
        else
          Text(t.defiMoreComing,
              textAlign: TextAlign.center, style: AppTextStyles.body(size: 12, color: colors.muted)),
        const SizedBox(height: 10),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.crimson),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.defiBackHome, style: AppTextStyles.display(size: 15, color: colors.cream)),
        ),
      ],
    );
  }
}

class _TimeRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final AppColors colors;
  final bool bold;
  const _TimeRow(this.label, this.value, this.valueColor, this.colors, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body(size: bold ? 15 : 13, weight: bold ? FontWeight.w700 : FontWeight.w400, color: colors.cream)),
          Text(value, style: AppTextStyles.body(size: bold ? 15 : 13, weight: FontWeight.w700, color: valueColor)),
        ],
      ),
    );
  }
}

class _RuleLine extends StatelessWidget {
  final String text;
  final AppColors colors;
  const _RuleLine(this.text, this.colors);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: AppTextStyles.body(size: 13, color: AppColors.gold)),
          Expanded(child: Text(text, style: AppTextStyles.body(size: 13, color: colors.cream).copyWith(height: 1.4))),
        ],
      ),
    );
  }
}
