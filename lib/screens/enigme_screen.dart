import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../data/enigmes_data.dart';
import '../models/enigme.dart';
import '../models/joker.dart';
import '../services/app_settings.dart';
import '../services/enigme_service.dart';
import '../services/enigme_state.dart';
import '../services/game_state.dart';
import '../services/leaderboard_service.dart';
import '../services/streak_state.dart';
import '../theme/app_theme.dart';
import '../widgets/joker_style.dart';
import '../widgets/letter_keyboard.dart';
import '../widgets/scifi_background.dart';

String _formatCountdown(Duration d) {
  final minutes = d.inMinutes;
  final seconds = d.inSeconds % 60;
  return '${minutes}min ${seconds.toString().padLeft(2, '0')}sec';
}

String _formatDuration(BuildContext context, int seconds) {
  final d = Duration(seconds: seconds);
  final jours = d.inDays;
  final heures = d.inHours % 24;
  final minutes = d.inMinutes % 60;
  final parts = <String>[];
  if (jours > 0) parts.add('$jours ${AppLocalizations.of(context).commonDayAbbr}');
  parts.add('${heures}h');
  parts.add('${minutes}min');
  return parts.join(' ');
}

/// Suffixe ordinal pour un classement ("3e"/"3rd") — seule pièce de ce
/// module qui varie structurellement selon la langue (règle grammaticale,
/// pas un simple mot à traduire), donc calculée ici plutôt que via l'ARB.
String _ordinal(BuildContext context, int rang) {
  if (AppLocalizations.of(context).localeName == 'en') {
    if (rang % 100 >= 11 && rang % 100 <= 13) return '${rang}th';
    switch (rang % 10) {
      case 1:
        return '${rang}st';
      case 2:
        return '${rang}nd';
      case 3:
        return '${rang}rd';
      default:
        return '${rang}th';
    }
  }
  return '$rang${rang == 1 ? 'er' : 'e'}';
}

String _formatClassement(BuildContext context, int rang, int total) =>
    AppLocalizations.of(context).enigmeRankingLine(_ordinal(context, rang), total);

/// Classement suivi du « top X % » quand il y a au moins deux joueurs.
String _formatClassementPct(BuildContext context, int rang, int total) {
  final base = _formatClassement(context, rang, total);
  if (total < 2) return base;
  return '$base · ${AppLocalizations.of(context).enigmeHistoryTop(EnigmeState.topPercent(rang, total))}';
}

/// Barème de jokers selon le jour de résolution (1 à 7).
String _rewardText(AppLocalizations t, int day) => switch (day) {
      1 => t.enigmeReward1,
      2 => t.enigmeReward2,
      3 => t.enigmeReward3,
      4 => t.enigmeReward4,
      5 => t.enigmeReward5,
      6 => t.enigmeReward6,
      _ => t.enigmeReward7,
    };

/// Gros pop-up du bilan de la semaine écoulée, à la première entrée de la
/// semaine suivante : classement final et jokers remis, ou la réponse si le
/// joueur ne l'a pas trouvée.
class _BilanDialog extends StatelessWidget {
  final EnigmeBilan bilan;
  final LeaderboardResult? result;
  final List<JokerKind> gagnes;
  final String sujet;
  final AppColors colors;
  const _BilanDialog(
      {required this.bilan, required this.result, required this.gagnes, required this.sujet, required this.colors});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final result = this.result;
    final trouve = bilan.solved && result != null;
    return Dialog(
      backgroundColor: colors.bgPanel2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppColors.gold.withOpacity(0.6), width: 1.5),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(t.enigmeBilanTitle,
                    textAlign: TextAlign.center, style: AppTextStyles.display(size: 24, color: AppColors.goldBright)),
                const SizedBox(height: 16),
                if (trouve) ...[
                  Text(sujet,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body(size: 16, weight: FontWeight.w700, color: colors.cream)),
                  const SizedBox(height: 12),
                  Text(t.enigmeBilanCongrats(_formatClassement(context, result.rang, result.total)),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body(size: 15, color: colors.cream).copyWith(height: 1.4)),
                  const SizedBox(height: 6),
                  Text(
                    result.total >= 2
                        ? t.enigmeBilanTop(EnigmeState.topPercent(result.rang, result.total))
                        : t.enigmeBilanOnlyOne,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body(size: 15, weight: FontWeight.w700, color: AppColors.goldBright)
                        .copyWith(height: 1.4),
                  ),
                  const SizedBox(height: 18),
                  Text(t.gameJokersWon,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body(size: 11, weight: FontWeight.w700, color: AppColors.gold)
                          .copyWith(letterSpacing: 2)),
                  const SizedBox(height: 8),
                  if (gagnes.isEmpty)
                    Text(t.enigmeBilanAlreadyGranted,
                        textAlign: TextAlign.center, style: AppTextStyles.body(size: 12, color: colors.muted))
                  else
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final kind in gagnes) _JokerChip(kind: kind, colors: colors),
                      ],
                    ),
                ] else ...[
                  Text(t.enigmeBilanMissed,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body(size: 15, color: colors.cream).copyWith(height: 1.4)),
                  const SizedBox(height: 10),
                  Text(sujet,
                      textAlign: TextAlign.center, style: AppTextStyles.display(size: 22, color: AppColors.goldBright)),
                  const SizedBox(height: 12),
                  Text(t.enigmeBilanMissedNext,
                      textAlign: TextAlign.center, style: AppTextStyles.body(size: 13, color: colors.muted)),
                ],
                const SizedBox(height: 22),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.crimson),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(trouve ? t.homeGreat : t.gameUnderstood,
                      style: AppTextStyles.display(size: 15, color: colors.cream)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _JokerChip extends StatelessWidget {
  final JokerKind kind;
  final AppColors colors;
  const _JokerChip({required this.kind, required this.colors});

  @override
  Widget build(BuildContext context) {
    final accent = jokerColor(kind, colors);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withOpacity(0.85), width: 1.2),
      ),
      child: Text('${kind.icon} ${jokerName(kind, AppLocalizations.of(context))}',
          style: AppTextStyles.body(size: 12, weight: FontWeight.w700, color: accent)),
    );
  }
}

class EnigmeScreen extends StatefulWidget {
  const EnigmeScreen({super.key});

  @override
  State<EnigmeScreen> createState() => _EnigmeScreenState();
}

class _EnigmeScreenState extends State<EnigmeScreen> {
  Timer? _ticker;
  bool _busyAdLettre = false;
  bool _busyAdTentative = false;
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EnigmeState>().ensureFresh();
      _maybeShowBilan();
    });
    // Le texte se révèle avec le temps et le compte à rebours affiche les
    // secondes : on rafraîchit l'affichage chaque seconde.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _onValider() async {
    final t = AppLocalizations.of(context);
    final enigmeState = context.read<EnigmeState>();
    final result = enigmeState.valider();
    if (!mounted) return;
    switch (result) {
      case 'incomplete':
        _toast(t.enigmeIncomplete);
        break;
      case 'no-attempts':
        _toast(t.enigmeNoAttempts);
        break;
      case 'wrong':
        _toast(t.enigmeWrong(enigmeState.tentativesRestantes));
        break;
      case 'solved':
        // Les jokers sont remis au bilan de la semaine suivante ; le score
        // part depuis le panneau « résolu » (voir _SolvedPanel).
        context.read<StreakState>().recordAction();
        break;
    }
  }

  // ─── Bilan de la semaine précédente (première entrée de la semaine) ───
  bool _bilanEnCours = false;

  Future<void> _maybeShowBilan() async {
    final enigmeState = context.read<EnigmeState>();
    final bilan = enigmeState.pendingBilan;
    if (bilan == null || _bilanEnCours) return;
    _bilanEnCours = true;
    final leaderboard = context.read<LeaderboardService>();
    LeaderboardResult? result;
    if (bilan.solved && bilan.solveSeconds != null) {
      if (!bilan.scoreSubmitted) {
        final ok = await leaderboard.submitScore(
            weekId: bilan.weekId, solveSeconds: bilan.solveSeconds!, solvedDay: bilan.solvedDay ?? 7);
        if (ok) enigmeState.markBilanScoreSubmitted();
      }
      result = await leaderboard.fetchRank(weekId: bilan.weekId, solveSeconds: bilan.solveSeconds!);
      // Hors ligne : pas de classement final, le bilan attend la prochaine visite.
      if (result == null || !mounted) {
        _bilanEnCours = false;
        return;
      }
    }
    if (!mounted) return;

    // Jokers remis maintenant, une seule fois (completeBilan efface le bilan
    // et sauvegarde aussitôt).
    final game = context.read<GameState>();
    final gagnes = <JokerKind>[];
    if (bilan.solved && result != null) {
      if (!bilan.rewardsAlreadyGranted) {
        for (final label in appliquerRecompenseEnigme(EnigmeState.rewardDayFor(bilan.solvedDay), game)) {
          if (JokerKind.fromLabel(label) case final kind?) gagnes.add(kind);
        }
      }
      if (EnigmeState.isTopTen(result.rang, result.total) && !bilan.redJokerAlreadyGranted) {
        game.grantJokers(redJoker: 1);
        gagnes.add(JokerKind.red);
      }
    }
    enigmeState.completeBilan(rang: result?.rang, total: result?.total);
    game.flushSave();

    final settings = context.read<AppSettings>();
    final colors = AppColors(settings.isLightTheme, colorblind: settings.colorblindMode);
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _BilanDialog(
        bilan: bilan,
        result: result,
        gagnes: gagnes,
        sujet: kEnigmes[bilan.enigmeIndex.clamp(0, kEnigmes.length - 1)].sujetFor(enigmeState.locale),
        colors: colors,
      ),
    );
    _bilanEnCours = false;
  }

  Future<void> _onWatchAdLettre() async {
    if (_busyAdLettre) return;
    setState(() => _busyAdLettre = true);
    final game = context.read<GameState>();
    final earned = await game.adService.showRewardedAdForJoker();
    if (!mounted) return;
    setState(() => _busyAdLettre = false);
    if (earned) {
      context.read<EnigmeState>().onAdLettreRewarded();
      _toast(AppLocalizations.of(context).enigmeAdLetterEarned);
    }
  }

  Future<void> _onWatchAdTentative() async {
    if (_busyAdTentative) return;
    setState(() => _busyAdTentative = true);
    final game = context.read<GameState>();
    final earned = await game.adService.showRewardedAdForJoker();
    if (!mounted) return;
    setState(() => _busyAdTentative = false);
    if (earned) {
      context.read<EnigmeState>().onAdTentativeRewarded();
      _toast(AppLocalizations.of(context).enigmeAdAttemptEarned);
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
                  _RuleLine(t.enigmeRule1, colors),
                  _RuleLine(t.enigmeRule2, colors),
                  _RuleLine(t.enigmeRule3, colors),
                  _RuleLine(t.enigmeRule4, colors),
                  _RuleLine(t.enigmeRule5, colors),
                  _RuleLine(t.enigmeRule6, colors),
                  const SizedBox(height: 14),
                  Text(t.enigmeRewardsHeader,
                      style: AppTextStyles.body(size: 12, weight: FontWeight.w700, color: AppColors.gold)),
                  const SizedBox(height: 8),
                  _RewardLine(t.enigmeRewardDayLabel(1), t.enigmeReward1, colors),
                  _RewardLine(t.enigmeRewardDayLabel(2), t.enigmeReward2, colors),
                  _RewardLine(t.enigmeRewardDayLabel(3), t.enigmeReward3, colors),
                  _RewardLine(t.enigmeRewardDayLabel(4), t.enigmeReward4, colors),
                  _RewardLine(t.enigmeRewardDayLabel(5), t.enigmeReward5, colors),
                  _RewardLine(t.enigmeRewardDayLabel(6), t.enigmeReward6, colors),
                  _RewardLine(t.enigmeRewardDayLabel(7), t.enigmeReward7, colors),
                  const SizedBox(height: 8),
                  Text(t.enigmeRewardsWhen,
                      style: AppTextStyles.body(size: 12, color: colors.muted).copyWith(height: 1.4)),
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

  void _showHistorique(AppColors colors) {
    final t = AppLocalizations.of(context);
    final enigmeState = context.read<EnigmeState>();
    final historique = enigmeState.historique;
    final meilleurClassement = enigmeState.meilleurClassement;
    final meilleurTemps = enigmeState.meilleurTemps;
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
                  Text(t.enigmeHistoryTitle, textAlign: TextAlign.center, style: AppTextStyles.display(size: 20)),
                  const SizedBox(height: 4),
                  Text(t.enigmeHistoryExplain,
                      style: AppTextStyles.body(size: 11, color: colors.muted).copyWith(height: 1.4)),
                  const SizedBox(height: 16),
                  if (meilleurClassement != null || meilleurTemps != null) ...[
                    if (meilleurClassement != null)
                      _HistoriqueBest(
                        t.enigmeBestRanking,
                        '${_formatClassementPct(context, meilleurClassement.rang!, meilleurClassement.total!)} — ${meilleurClassement.sujet}',
                        colors,
                      ),
                    if (meilleurTemps != null)
                      _HistoriqueBest(
                        t.enigmeBestTimeLabel,
                        '${_formatDuration(context, meilleurTemps.solveSeconds)} — ${meilleurTemps.sujet}',
                        colors,
                      ),
                    const SizedBox(height: 12),
                    Divider(color: colors.muted.withOpacity(0.3)),
                    const SizedBox(height: 8),
                  ],
                  if (historique.isEmpty)
                    Text(t.enigmeNoneSolved, style: AppTextStyles.body(size: 13, color: colors.muted))
                  else
                    for (final e in historique) _HistoriqueRow(entry: e, colors: colors),
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
    final t = AppLocalizations.of(context);
    final settings = context.watch<AppSettings>();
    final colors = AppColors(settings.isLightTheme, colorblind: settings.colorblindMode);
    final enigmeState = context.watch<EnigmeState>();
    final enigme = enigmeState.enigme;

    if (_zoomed) {
      return Scaffold(
        backgroundColor: colors.bgDeep,
        body: SafeArea(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _zoomed = false),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  enigmeState.texteRevele,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body(size: 26, color: colors.cream).copyWith(height: 1.7),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final countdown = enigmeState.tempsAvantProchaineLettre;

    return SciFiScaffold(
      baseColor: colors.bgDeep,
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
                    child: Column(
                      children: [
                        Text(t.enigmeTitle, textAlign: TextAlign.center, style: AppTextStyles.display(size: 20)),
                        Text(t.enigmeDayOf7(enigmeState.jourEnCours.clamp(1, 7)),
                            style: AppTextStyles.body(size: 11, color: colors.muted)),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => _showHistorique(colors),
                    child: Container(
                      width: 36,
                      height: 36,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(color: colors.bgPanel, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.history, color: AppColors.goldBright, size: 18),
                    ),
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
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.gold.withOpacity(0.4)),
                  ),
                  child: Text(enigme.categorieLabelFor(enigmeState.locale).toUpperCase(),
                      style: AppTextStyles.body(size: 12, weight: FontWeight.w700, color: AppColors.goldBright)),
                ),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () => setState(() => _zoomed = true),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [colors.bgPanel2, colors.bgPanel]),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.gold.withOpacity(0.35)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(enigmeState.texteRevele,
                          style: AppTextStyles.body(size: 15, color: colors.cream).copyWith(height: 1.6)),
                      if (enigmeState.badgeRevele != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            enigme.categorie.name == 'film'
                                ? t.enigmeYear('${enigmeState.badgeRevele}')
                                : t.enigmeAge('${enigmeState.badgeRevele}'),
                            style: AppTextStyles.body(size: 12, weight: FontWeight.w700, color: AppColors.goldBright),
                          ),
                        ),
                      ],
                      // Indique que toucher le pitch l'agrandit (tout le cadre reste touchable).
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.zoom_in, size: 15, color: colors.muted),
                              const SizedBox(width: 3),
                              Text(t.enigmeZoom,
                                  style: AppTextStyles.body(size: 12, color: colors.muted)
                                      .copyWith(fontStyle: FontStyle.italic)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (countdown > Duration.zero) ...[
                const SizedBox(height: 8),
                Text(t.enigmeNextLetterIn(_formatCountdown(countdown)),
                    textAlign: TextAlign.center, style: AppTextStyles.body(size: 11, color: colors.muted)),
              ],
              const SizedBox(height: 18),
              if (enigmeState.solved)
                _SolvedPanel(colors: colors)
              else ...[
                _EnigmeAnswerRow(colors: colors),
                const SizedBox(height: 18),
                _EnigmeLetterPool(colors: colors),
                const SizedBox(height: 14),
                Text(t.enigmeAttemptsLeft(enigmeState.tentativesRestantes),
                    textAlign: TextAlign.center, style: AppTextStyles.body(size: 12, color: colors.muted)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.read<EnigmeState>().clearGuess(),
                        child: Text(t.commonClear,
                            style: AppTextStyles.body(size: 13, weight: FontWeight.w700, color: colors.muted)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: _buildActionButton(enigmeState, colors)),
                  ],
                ),
                if (enigmeState.peutRegarderPubLettre) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _busyAdLettre ? null : _onWatchAdLettre,
                      child: Text(
                        _busyAdLettre ? t.commonLoading : t.enigmeWatchAdLetter,
                        style: AppTextStyles.body(size: 12, weight: FontWeight.w700, color: AppColors.gold),
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Emplacement du bouton "VALIDER" : remplacé par le bouton pub "+1
  /// tentative" dès que le joueur n'a plus de tentative disponible
  /// aujourd'hui (qu'elle soit gratuite ou déjà gagnée via pub) — jusqu'à
  /// épuisement des 5 pubs quotidiennes, où seul un message reste affiché.
  Widget _buildActionButton(EnigmeState enigmeState, AppColors colors) {
    final t = AppLocalizations.of(context);
    if (enigmeState.tentativesRestantes > 0) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.crimson),
        onPressed: _onValider,
        child: Text(t.commonValidate, style: AppTextStyles.display(size: 15, color: colors.cream)),
      );
    }
    if (enigmeState.peutRegarderPubTentative) {
      return OutlinedButton(
        onPressed: _busyAdTentative ? null : _onWatchAdTentative,
        style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.gold)),
        child: Text(
          _busyAdTentative ? t.commonLoading : t.enigmeWatchAdAttempt,
          style: AppTextStyles.body(size: 12, weight: FontWeight.w700, color: AppColors.gold),
        ),
      );
    }
    return ElevatedButton(
      onPressed: null,
      child: Text(t.enigmeComeBackTomorrow,
          style: AppTextStyles.body(size: 12, weight: FontWeight.w700, color: colors.muted)),
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

class _RewardLine extends StatelessWidget {
  final String jour;
  final String recompense;
  final AppColors colors;
  const _RewardLine(this.jour, this.recompense, this.colors);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
              width: 60,
              child: Text(jour,
                  style: AppTextStyles.body(size: 12, weight: FontWeight.w700, color: AppColors.goldBright))),
          Expanded(child: Text(recompense, style: AppTextStyles.body(size: 12, color: colors.cream))),
        ],
      ),
    );
  }
}

class _SolvedPanel extends StatefulWidget {
  final AppColors colors;
  const _SolvedPanel({required this.colors});

  @override
  State<_SolvedPanel> createState() => _SolvedPanelState();
}

class _SolvedPanelState extends State<_SolvedPanel> {
  Future<LeaderboardResult?>? _rangFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Une seule requête, même si le parent se reconstruit chaque seconde
    // (compte à rebours) : le résultat ne change pas une fois calculé.
    _rangFuture ??= _fetchRang();
  }

  /// Envoie d'abord le score s'il n'est pas encore parti (hors ligne au
  /// moment de la résolution, par exemple), puis lit le classement provisoire.
  /// Le joker rouge du top 10 % est remis au bilan, sur le classement final.
  Future<LeaderboardResult?> _fetchRang() async {
    final enigmeState = context.read<EnigmeState>();
    final leaderboard = context.read<LeaderboardService>();
    final weekStart = enigmeState.currentWeekStart;
    final seconds = enigmeState.solveSeconds;
    if (weekStart == null || seconds == null) return null;
    final weekId = weekIdFor(weekStart);
    if (!enigmeState.scoreSubmitted) {
      final ok = await leaderboard.submitScore(
          weekId: weekId, solveSeconds: seconds, solvedDay: enigmeState.solvedDay ?? 7);
      if (ok) enigmeState.markScoreSubmitted();
    }
    final result = await leaderboard.fetchRank(weekId: weekId, solveSeconds: seconds);
    if (result != null) enigmeState.recordRang(rang: result.rang, total: result.total);
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colors = widget.colors;
    final enigmeState = context.watch<EnigmeState>();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.gold.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gold.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.enigmeSolvedTitle,
              textAlign: TextAlign.center, style: AppTextStyles.display(size: 22, color: AppColors.goldBright)),
          const SizedBox(height: 8),
          Text(enigmeState.enigme.sujetFor(enigmeState.locale),
              textAlign: TextAlign.center,
              style: AppTextStyles.body(size: 16, weight: FontWeight.w700, color: colors.cream)),
          const SizedBox(height: 10),
          if (enigmeState.solveSeconds != null)
            Text(t.enigmeFoundIn(_formatDuration(context, enigmeState.solveSeconds!), enigmeState.solvedDay!),
                textAlign: TextAlign.center, style: AppTextStyles.body(size: 12, color: colors.muted)),
          const SizedBox(height: 12),
          Text(
              // Résolue avec une ancienne version : jokers déjà remis.
              enigmeState.rewardLabels.isNotEmpty
                  ? t.enigmeRewardLabel(
                      enigmeState.rewardLabels.map((l) => jokerLabelFor(l, enigmeState.locale)).join(', '))
                  : t.enigmeRewardNextWeek(_rewardText(t, EnigmeState.rewardDayFor(enigmeState.solvedDay))),
              textAlign: TextAlign.center,
              style: AppTextStyles.body(size: 12, color: AppColors.goldBright)),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: colors.muted.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: FutureBuilder<LeaderboardResult?>(
              future: _rangFuture,
              builder: (context, snapshot) {
                String texte;
                if (snapshot.connectionState != ConnectionState.done) {
                  texte = t.enigmeRankCalculating;
                } else if (snapshot.data == null) {
                  texte = t.enigmeRankUnavailable;
                } else {
                  final r = snapshot.data!;
                  texte = '🏆 ${_formatClassement(context, r.rang, r.total)}';
                }
                return Text(texte,
                    textAlign: TextAlign.center, style: AppTextStyles.body(size: 12, color: colors.muted));
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Grille de tuiles pour le sujet à deviner — même mécanique que
/// [AnswerRow] du jeu principal (mots groupés dans un Wrap, réduction
/// automatique des mots trop longs), mais reliée à [EnigmeState].
class _EnigmeAnswerRow extends StatelessWidget {
  final AppColors colors;
  const _EnigmeAnswerRow({required this.colors});

  @override
  Widget build(BuildContext context) {
    final enigmeState = context.watch<EnigmeState>();
    final wordWidgets = <Widget>[];
    final wordTileCounts = <int>[];
    List<Widget> currentWord = [];

    void flushWord() {
      if (currentWord.isNotEmpty) {
        wordWidgets.add(Row(mainAxisSize: MainAxisSize.min, children: currentWord));
        wordTileCounts.add(currentWord.length);
        currentWord = [];
      }
    }

    for (var i = 0; i < enigmeState.slots.length; i++) {
      final slot = enigmeState.slots[i];
      if (slot.isSpace) {
        flushWord();
        continue;
      }
      if (slot.isAuto) {
        currentWord.add(_EnigmeBlank(text: slot.char, colors: colors, auto: true));
        continue;
      }
      final tileId = enigmeState.guess[i];
      final letter = tileId != null ? enigmeState.pool[tileId].letter : null;
      currentWord.add(GestureDetector(
        onTap: () => context.read<EnigmeState>().onBlankTap(i),
        child: _EnigmeBlank(
          text: letter ?? '_',
          colors: colors,
          cursor: i == enigmeState.cursorIndex,
          filled: letter != null,
        ),
      ));
    }
    flushWord();

    return LayoutBuilder(
      builder: (context, constraints) {
        const tileSpan = 36.0;
        return Wrap(
          alignment: WrapAlignment.center,
          spacing: 14,
          runSpacing: 10,
          children: [
            for (var w = 0; w < wordWidgets.length; w++)
              if (wordTileCounts[w] * tileSpan > constraints.maxWidth)
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                  child: FittedBox(fit: BoxFit.scaleDown, child: wordWidgets[w]),
                )
              else
                wordWidgets[w],
          ],
        );
      },
    );
  }
}

class _EnigmeBlank extends StatelessWidget {
  final String text;
  final AppColors colors;
  final bool cursor;
  final bool filled;
  final bool auto;
  const _EnigmeBlank(
      {required this.text, required this.colors, this.cursor = false, this.filled = false, this.auto = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 38,
      margin: const EdgeInsets.only(right: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: cursor ? AppColors.gold.withOpacity(0.22) : null,
        border: Border(bottom: BorderSide(color: auto ? colors.muted : AppColors.gold, width: 3)),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      ),
      child: Text(text,
          style: AppTextStyles.tile(size: 19, color: filled || auto ? AppColors.goldBright : Colors.transparent)),
    );
  }
}

class _EnigmeLetterPool extends StatelessWidget {
  final AppColors colors;
  const _EnigmeLetterPool({required this.colors});

  @override
  Widget build(BuildContext context) {
    final enigmeState = context.watch<EnigmeState>();
    final inputMode = context.select<AppSettings, String>((s) => s.inputMode);
    if (inputMode != 'tiles') {
      return LetterKeyboard(
        pool: enigmeState.pool,
        layout: inputMode,
        colors: colors,
        onTap: (tile) => context.read<EnigmeState>().onLetterTap(tile),
      );
    }
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: enigmeState.pool.map((tile) {
        return GestureDetector(
          onTap: tile.used ? null : () => context.read<EnigmeState>().onLetterTap(tile),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: tile.used ? 0 : 1,
            child: Container(
              width: 38,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.bgPanel,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.gold.withOpacity(0.35)),
              ),
              child: Text(tile.letter, style: AppTextStyles.tile(size: 17, color: colors.cream)),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _HistoriqueBest extends StatelessWidget {
  final String label;
  final String value;
  final AppColors colors;
  const _HistoriqueBest(this.label, this.value, this.colors);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.body(size: 12, weight: FontWeight.w700, color: AppColors.gold)),
          Text(value, style: AppTextStyles.body(size: 13, color: colors.cream)),
        ],
      ),
    );
  }
}

class _HistoriqueRow extends StatelessWidget {
  final EnigmeHistoryEntry entry;
  final AppColors colors;
  const _HistoriqueRow({required this.entry, required this.colors});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final classement = entry.rang != null && entry.total != null
        ? _formatClassementPct(context, entry.rang!, entry.total!)
        : t.enigmeRankUnknown;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.sujet, style: AppTextStyles.body(size: 13, weight: FontWeight.w700, color: colors.cream)),
                Text(t.enigmeWeekOf(entry.weekId, entry.solvedDay, _formatDuration(context, entry.solveSeconds)),
                    style: AppTextStyles.body(size: 11, color: colors.muted)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(classement,
              textAlign: TextAlign.right,
              style: AppTextStyles.body(size: 12, weight: FontWeight.w700, color: AppColors.goldBright)),
        ],
      ),
    );
  }
}
