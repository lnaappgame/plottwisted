import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../services/app_settings.dart';
import '../services/nickname_filter.dart';
import '../services/progress_leaderboard.dart';
import '../theme/app_theme.dart';
import '../widgets/scifi_background.dart';

/// Demande confirmation puis retire le joueur du classement (son document
/// est supprimé dans les deux langues), avec le message « C'est fait ».
/// Utilisé par l'écran du classement et par les Réglages, où la ligne reste
/// accessible même interrupteur éteint. Vrai si le joueur s'est retiré.
Future<bool> confirmAndLeaveProgressLeaderboard(BuildContext context) async {
  final settings = context.read<AppSettings>();
  final colors = AppColors(settings.isLightTheme, colorblind: settings.colorblindMode);
  final t = AppLocalizations.of(context);
  final lb = context.read<ProgressLeaderboard>();
  final messenger = ScaffoldMessenger.maybeOf(context);
  final yes = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: colors.bgPanel2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.lbLeaveTitle, textAlign: TextAlign.center, style: AppTextStyles.display(size: 18)),
            const SizedBox(height: 12),
            Text(t.lbLeaveText,
                textAlign: TextAlign.center,
                style: AppTextStyles.body(size: 14, color: colors.cream).copyWith(height: 1.5)),
            const SizedBox(height: 18),
            ElevatedButton(
              key: const ValueKey('lbLeaveConfirm'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.crimson),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(t.lbLeaveConfirm, style: AppTextStyles.display(size: 15, color: colors.cream)),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(t.commonCancel,
                  style: AppTextStyles.body(size: 13, weight: FontWeight.w700, color: AppColors.gold)),
            ),
          ],
        ),
      ),
    ),
  );
  if (yes != true) return false;
  await lb.leave();
  messenger?.showSnackBar(SnackBar(content: Text(t.lbLeft), duration: const Duration(seconds: 2)));
  return true;
}

/// Classement global sur l'avancée (1.0.16) : le top 50, puis, toujours
/// visible en bas, la place du joueur avec les 3 joueurs juste au-dessus.
/// Lu une seule fois à l'ouverture (et sur « Réessayer »), jamais en continu.
class ProgressLeaderboardScreen extends StatefulWidget {
  const ProgressLeaderboardScreen({super.key});

  @override
  State<ProgressLeaderboardScreen> createState() => _ProgressLeaderboardScreenState();
}

class _ProgressLeaderboardScreenState extends State<ProgressLeaderboardScreen> {
  ProgressBoardView? _view;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load(offerJoin: true));
  }

  Future<void> _load({bool offerJoin = false}) async {
    final lb = context.read<ProgressLeaderboard>();
    setState(() => _loading = true);
    final view = await lb.loadBoard();
    if (!mounted) return;
    setState(() {
      _view = view;
      _loading = false;
    });
    // Première ouverture : on propose d'apparaître (une seule fois).
    if (offerJoin && view != null && !lb.participating && !lb.introSeen) {
      lb.markIntroSeen();
      await _editPseudo();
    }
  }

  Future<void> _editPseudo() async {
    final lb = context.read<ProgressLeaderboard>();
    final settings = context.read<AppSettings>();
    final wasJoined = lb.participating;
    // Un seul pseudo : « Ton pseudo » de l'accueil, ou « Cinéphile » s'il n'a
    // jamais été personnalisé.
    final initial = suggestedProgressPseudo(playerId: settings.playerId, locale: settings.locale);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => ProgressPseudoDialog(initial: initial, rename: wasJoined),
    );
    if (ok != true || !mounted) return;
    if (!wasJoined) _toast(AppLocalizations.of(context).lbJoined);
    await _load();
  }

  Future<void> _confirmLeave() async {
    final left = await confirmAndLeaveProgressLeaderboard(context);
    if (!left || !mounted) return;
    await _load();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 2)));
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final colors = AppColors(settings.isLightTheme, colorblind: settings.colorblindMode);
    final t = AppLocalizations.of(context);
    final view = _view;

    Widget content;
    if (_loading && view == null) {
      content = const Center(child: CircularProgressIndicator(color: AppColors.goldBright));
    } else if (view == null) {
      content = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(t.lbOffline,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body(size: 14, color: colors.cream).copyWith(height: 1.5)),
              const SizedBox(height: 16),
              OutlinedButton(
                key: const ValueKey('lbRetry'),
                onPressed: _loading ? null : () => _load(offerJoin: true),
                child: Text(t.lbRetry,
                    style: AppTextStyles.body(size: 13, weight: FontWeight.w700, color: AppColors.goldBright)),
              ),
            ],
          ),
        ),
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              key: const ValueKey('lbTopList'),
              padding: const EdgeInsets.fromLTRB(0, 4, 0, 12),
              children: [
                Text(t.lbTop,
                    style: AppTextStyles.body(size: 11, weight: FontWeight.w700, color: AppColors.gold)
                        .copyWith(letterSpacing: 2)),
                const SizedBox(height: 6),
                if (view.top.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(t.lbEmpty,
                        textAlign: TextAlign.center, style: AppTextStyles.body(size: 14, color: colors.muted)),
                  )
                else
                  for (final r in view.top)
                    _RankRow(
                        rank: r.rank, pseudo: r.pseudo, worldLevel: r.worldLevel, highlight: r.isMe, colors: colors),
                const SizedBox(height: 10),
                Text(t.lbLegend, style: AppTextStyles.body(size: 11, color: colors.muted).copyWith(height: 1.4)),
              ],
            ),
          ),
          _MyPlacePanel(
            view: view,
            colors: colors,
            busy: _loading,
            onJoin: _editPseudo,
            onRename: _editPseudo,
            onLeave: _confirmLeave,
          ),
        ],
      );
    }

    return SciFiScaffold(
      baseColor: colors.bgDeep,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
                    child: Text(t.lbTitle, textAlign: TextAlign.center, style: AppTextStyles.display(size: 20)),
                  ),
                  const SizedBox(width: 36),
                ],
              ),
              const SizedBox(height: 6),
              Text(t.lbSubtitle, textAlign: TextAlign.center, style: AppTextStyles.body(size: 12, color: colors.muted)),
              const SizedBox(height: 12),
              Expanded(child: content),
            ],
          ),
        ),
      ),
    );
  }
}

/// Une ligne « 123  Bobdu13  16-3 ».
class _RankRow extends StatelessWidget {
  final int rank;
  final String pseudo;
  final String worldLevel;
  final bool highlight;
  final bool dim;
  final AppColors colors;
  const _RankRow({
    super.key,
    required this.rank,
    required this.pseudo,
    required this.worldLevel,
    required this.highlight,
    required this.colors,
    this.dim = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = highlight ? AppColors.goldBright : (dim ? colors.muted : colors.cream);
    final weight = highlight ? FontWeight.w800 : FontWeight.w600;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: highlight ? AppColors.gold.withValues(alpha: 0.18) : colors.bgPanel.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(8),
        border: highlight ? Border.all(color: AppColors.gold.withValues(alpha: 0.8)) : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 46,
            child: Text(rank > 0 ? '$rank' : '–',
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: AppTextStyles.body(size: 13, weight: FontWeight.w800, color: textColor)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(pseudo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body(size: 13, weight: weight, color: textColor)),
          ),
          const SizedBox(width: 8),
          Text(worldLevel, style: AppTextStyles.body(size: 13, weight: FontWeight.w700, color: textColor)),
        ],
      ),
    );
  }
}

/// La place du joueur, toujours visible : les 3 joueurs juste au-dessus,
/// sa ligne, « 123e sur 4 567 », et les actions (apparaître, pseudo, retrait).
class _MyPlacePanel extends StatelessWidget {
  final ProgressBoardView view;
  final AppColors colors;
  final bool busy;
  final VoidCallback onJoin;
  final VoidCallback onRename;
  final VoidCallback onLeave;
  const _MyPlacePanel({
    required this.view,
    required this.colors,
    required this.busy,
    required this.onJoin,
    required this.onRename,
    required this.onLeave,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final lb = context.watch<ProgressLeaderboard>();
    final rank = view.myRank;
    // Inscrit : son pseudo (celui de l'accueil, passé au filtre) ; sinon « Toi ».
    final myName = view.joined ? lb.pseudo : t.lbYou;
    return ConstrainedBox(
      // Jamais plus de la moitié de l'écran : le top 50 reste lisible.
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.5),
      child: Container(
        key: const ValueKey('lbMyPlace'),
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
        decoration: BoxDecoration(
          color: colors.bgPanel2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(t.lbYourPlace,
                      style: AppTextStyles.body(size: 11, weight: FontWeight.w700, color: AppColors.gold)
                          .copyWith(letterSpacing: 2)),
                  const Spacer(),
                  if (rank != null)
                    Flexible(
                      child: Text(t.lbRankOf(rank, view.total),
                          key: const ValueKey('lbRankOf'),
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.display(size: 16, color: AppColors.goldBright)),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              if (rank == null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(view.joined ? t.lbWaitingFirstLevel : t.lbNoScore,
                      textAlign: TextAlign.center, style: AppTextStyles.body(size: 13, color: colors.cream)),
                )
              else ...[
                for (final r in view.above)
                  _RankRow(
                      rank: r.rank, pseudo: r.pseudo, worldLevel: r.worldLevel, highlight: false, dim: true, colors: colors),
                _RankRow(
                    key: const ValueKey('lbMyRow'),
                    rank: rank,
                    pseudo: myName,
                    worldLevel: worldLevelLabel(view.myScore),
                    highlight: true,
                    colors: colors),
              ],
              if (!view.joined) ...[
                if (rank != null) ...[
                  const SizedBox(height: 6),
                  Text(t.lbNotJoined,
                      textAlign: TextAlign.center, style: AppTextStyles.body(size: 11, color: colors.muted)),
                ],
                const SizedBox(height: 8),
                ElevatedButton(
                  key: const ValueKey('lbJoinButton'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.crimson,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: busy ? null : onJoin,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(t.lbJoinButton, style: AppTextStyles.display(size: 15, color: colors.cream)),
                  ),
                ),
              ] else
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        key: const ValueKey('lbRename'),
                        onPressed: busy ? null : onRename,
                        child: Text(t.lbChangeName,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.body(size: 12, weight: FontWeight.w700, color: AppColors.goldBright)),
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        key: const ValueKey('lbLeave'),
                        onPressed: busy ? null : onLeave,
                        child: Text(t.lbLeave,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.body(size: 12, weight: FontWeight.w700, color: colors.muted)),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Choix du pseudo : à la première ouverture (« Apparaître dans le
/// classement ? »), avec le bouton « Apparaître », ou pour le changer.
/// Se ferme avec `true` une fois le pseudo publié.
class ProgressPseudoDialog extends StatefulWidget {
  final String initial;
  final bool rename;
  const ProgressPseudoDialog({super.key, required this.initial, required this.rename});

  @override
  State<ProgressPseudoDialog> createState() => _ProgressPseudoDialogState();
}

class _ProgressPseudoDialogState extends State<ProgressPseudoDialog> {
  late final TextEditingController _controller = TextEditingController(text: widget.initial)
    ..selection = TextSelection(baseOffset: 0, extentOffset: widget.initial.length);
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final t = AppLocalizations.of(context);
    final p = _controller.text.trim();
    if (p.isEmpty) {
      setState(() => _error = t.lbPseudoEmpty);
      return;
    }
    if (!isNicknameAcceptable(p) || !isProgressPseudoValid(p)) {
      setState(() => _error = t.lbPseudoRefused);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await context.read<ProgressLeaderboard>().join(p);
    if (!mounted) return;
    switch (result) {
      case ProgressJoinResult.ok:
        Navigator.of(context).pop(true);
      case ProgressJoinResult.refused:
        setState(() {
          _busy = false;
          _error = t.lbPseudoRefused;
        });
      case ProgressJoinResult.failed:
        setState(() {
          _busy = false;
          _error = t.lbFailed;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final colors = AppColors(settings.isLightTheme, colorblind: settings.colorblindMode);
    final t = AppLocalizations.of(context);
    return Dialog(
      backgroundColor: colors.bgPanel2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.rename ? t.lbRenameTitle : t.lbJoinTitle,
                textAlign: TextAlign.center, style: AppTextStyles.display(size: 18)),
            if (!widget.rename) ...[
              const SizedBox(height: 12),
              Text(t.lbJoinText,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body(size: 14, color: colors.cream).copyWith(height: 1.5)),
            ],
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('lbPseudoField'),
              controller: _controller,
              maxLength: kProgressPseudoMaxLength,
              textAlign: TextAlign.center,
              enabled: !_busy,
              style: AppTextStyles.body(size: 15, weight: FontWeight.w700, color: colors.cream),
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: colors.bgPanel,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                hintText: t.homeYourNickname,
              ),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              onSubmitted: (_) => unawaited(_submit()),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!,
                  key: const ValueKey('lbPseudoError'),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body(size: 12, weight: FontWeight.w700, color: AppColors.redBright)),
            ],
            const SizedBox(height: 18),
            ElevatedButton(
              key: const ValueKey('lbPseudoConfirm'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.crimson),
              onPressed: _busy ? null : _submit,
              child: Text(widget.rename ? t.lbSave : t.lbJoinConfirm,
                  style: AppTextStyles.display(size: 15, color: colors.cream)),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              key: const ValueKey('lbPseudoCancel'),
              onPressed: _busy ? null : () => Navigator.of(context).pop(false),
              child: Text(widget.rename ? t.commonCancel : t.lbNotNow,
                  style: AppTextStyles.body(size: 13, weight: FontWeight.w700, color: AppColors.gold)),
            ),
          ],
        ),
      ),
    );
  }
}
