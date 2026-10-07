import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/multiplayer.dart';
import '../services/app_settings.dart';
import '../services/elo_service.dart';
import '../services/game_state.dart';
import '../services/multiplayer_state.dart';
import '../theme/app_theme.dart';
import '../widgets/scifi_background.dart';

class MultiplayerScreen extends StatefulWidget {
  const MultiplayerScreen({super.key});

  @override
  State<MultiplayerScreen> createState() => _MultiplayerScreenState();
}

class _MultiplayerScreenState extends State<MultiplayerScreen> {
  Timer? _ticker;
  bool _busyAdMatch = false;

  @override
  void initState() {
    super.initState();
    // Synchrone (pas de postFrameCallback) pour que le tout premier build
    // reflète déjà l'accueil — sinon un match déjà terminé s'afficherait une
    // frame avant de basculer sur l'intro.
    final mp = context.read<MultiplayerState>();
    mp.returnToIntro();
    mp.ensureFreshDay();
    mp.refreshTopPercent();
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted) return;
      context.read<MultiplayerState>().tick();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _onWatchAdMatch() async {
    if (_busyAdMatch) return;
    setState(() => _busyAdMatch = true);
    final game = context.read<GameState>();
    // Capturés avant le await : si l'écran est démonté pendant que la pub
    // joue (le joueur quitte, l'app passe en arrière-plan...), la
    // récompense ne doit jamais être perdue simplement parce que `mounted`
    // est devenu faux — seuls les appels d'UI (setState/toast) doivent
    // dépendre de `mounted`.
    final mp = context.read<MultiplayerState>();
    final earned = await game.adService.showRewardedAdForJoker();
    if (earned) mp.onAdMatchRewarded();
    if (!mounted) return;
    setState(() => _busyAdMatch = false);
    if (earned) _toast(AppLocalizations.of(context).mpAdMatchEarned);
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 2)));
  }

  void _showHistorique(AppColors colors) {
    final historique = context.read<MultiplayerState>().historique;
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
                  Text(t.enigmeHistoryTitle, textAlign: TextAlign.center, style: AppTextStyles.display(size: 20)),
                  const SizedBox(height: 4),
                  Text(t.mpHistoryLastMatches(kMultiplayerHistoriqueMax),
                      style: AppTextStyles.body(size: 11, color: colors.muted)),
                  const SizedBox(height: 16),
                  if (historique.isEmpty)
                    Text(t.mpNoMatchYet, style: AppTextStyles.body(size: 13, color: colors.muted))
                  else
                    for (final e in historique) _HistoriqueMatchRow(entry: e, colors: colors),
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
                  _RuleLine(t.mpRule1, colors),
                  _RuleLine(t.mpRule2, colors),
                  _RuleLine(t.mpRule3, colors),
                  _RuleLine(t.mpRule4, colors),
                  _RuleLine(t.mpRule5, colors),
                  _RuleLine(t.mpRule6, colors),
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
    final mp = context.watch<MultiplayerState>();

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
                    child: Text(AppLocalizations.of(context).mpTitle, textAlign: TextAlign.center, style: AppTextStyles.display(size: 20)),
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
              if (!mp.matchActive && !mp.matchOver)
                _IntroView(
                  mp: mp,
                  colors: colors,
                  onCommencer: () => mp.startMatch(playerName: settings.displayPlayerName),
                  onWatchAdMatch: _onWatchAdMatch,
                  busyAdMatch: _busyAdMatch,
                  onShowHistorique: () => _showHistorique(colors),
                )
              else if (mp.matchOver)
                _ResultView(
                  mp: mp,
                  colors: colors,
                  onRejouer: () => mp.startMatch(playerName: settings.displayPlayerName),
                  onWatchAdMatch: _onWatchAdMatch,
                  busyAdMatch: _busyAdMatch,
                )
              else if (mp.showRoundResult)
                _RoundResultView(mp: mp, colors: colors)
              else
                _PlayingView(mp: mp, colors: colors),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntroView extends StatelessWidget {
  final MultiplayerState mp;
  final AppColors colors;
  final VoidCallback onCommencer;
  final VoidCallback onWatchAdMatch;
  final bool busyAdMatch;
  final VoidCallback onShowHistorique;
  const _IntroView({
    required this.mp,
    required this.colors,
    required this.onCommencer,
    required this.onWatchAdMatch,
    required this.busyAdMatch,
    required this.onShowHistorique,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final topPercent = mp.topPercent;
    final matchesRestantes = mp.matchesRestantes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Text('${mp.eloRating}', textAlign: TextAlign.center, style: AppTextStyles.display(size: 56, color: AppColors.goldBright)),
        const SizedBox(height: 6),
        Text(t.mpYourRank, textAlign: TextAlign.center, style: AppTextStyles.body(size: 11, color: colors.muted)),
        Text(mp.titreActuel, textAlign: TextAlign.center,
            style: AppTextStyles.body(size: 14, weight: FontWeight.w700, color: colors.cream)),
        if (topPercent != null) ...[
          const SizedBox(height: 8),
          Text(
            t.mpTopPercent(topPercent < 10 ? topPercent.toStringAsFixed(1) : topPercent.round().toString()),
            textAlign: TextAlign.center,
            style: AppTextStyles.body(size: 12, weight: FontWeight.w700, color: AppColors.gold),
          ),
        ],
        const SizedBox(height: 26),
        if (matchesRestantes > 0)
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.crimson, padding: const EdgeInsets.symmetric(vertical: 14)),
            onPressed: onCommencer,
            child: Text(t.mpChallengePlayer, style: AppTextStyles.display(size: 16, color: colors.cream)),
          )
        else if (mp.peutRegarderPubMatch)
          OutlinedButton(
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            onPressed: busyAdMatch ? null : onWatchAdMatch,
            child: busyAdMatch
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold))
                : Text(
                    t.mpWatchAdForMatch(mp.adsWatchedForMatchesToday, kMultiplayerAdsMaxParJour),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body(size: 13, weight: FontWeight.w700, color: AppColors.goldBright),
                  ),
          )
        else
          Text(t.mpComeBackTomorrow, textAlign: TextAlign.center,
              style: AppTextStyles.body(size: 13, color: colors.muted)),
        const SizedBox(height: 8),
        Text(
          matchesRestantes > 0 ? t.mpMatchesLeft(matchesRestantes) : t.mpQuotaReached,
          textAlign: TextAlign.center,
          style: AppTextStyles.body(size: 11, color: colors.muted),
        ),
        const SizedBox(height: 20),
        OutlinedButton(
          onPressed: onShowHistorique,
          child: Text(t.mpHistoryButton, style: AppTextStyles.body(size: 13, weight: FontWeight.w700, color: AppColors.gold)),
        ),
      ],
    );
  }
}

class _HistoriqueMatchRow extends StatelessWidget {
  final MultiplayerMatchHistoryEntry entry;
  final AppColors colors;
  const _HistoriqueMatchRow({required this.entry, required this.colors});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final (icone, libelle) = switch (entry.resultat) {
      'victoire' => ('🏆', t.mpWin),
      'defaite' => ('😔', t.mpLoss),
      _ => ('🤝', t.mpDraw),
    };
    final delta = entry.delta;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(icone, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(libelle, style: AppTextStyles.body(size: 14, weight: FontWeight.w700, color: colors.cream)),
          ),
          Text('${entry.eloAvant} → ${entry.eloApres}', style: AppTextStyles.body(size: 12, color: colors.muted)),
          const SizedBox(width: 8),
          Text(delta >= 0 ? '+$delta' : '$delta',
              style: AppTextStyles.body(size: 13, weight: FontWeight.w700,
                  color: delta >= 0 ? AppColors.greenBright : AppColors.crimsonBright)),
        ],
      ),
    );
  }
}

class _PlayingView extends StatelessWidget {
  final MultiplayerState mp;
  final AppColors colors;
  const _PlayingView({required this.mp, required this.colors});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final restant = (mp.roundMaxSeconds - mp.tempsEcoule.inMilliseconds / 1000).clamp(0, mp.roundMaxSeconds);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DuelHeader(
          mp: mp,
          colors: colors,
          avatarJoueur: settings.avatar,
          eloJoueur: mp.eloRating.toDouble(),
          eloAdversaire: mp.eloAdversaireActuel ?? mp.eloRating.toDouble(),
        ),
        const SizedBox(height: 12),
        if (mp.currentEnigme != null)
          Align(
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.gold.withOpacity(0.4)),
              ),
              child: Text(mp.currentEnigme!.typeLabelFor(mp.locale).toUpperCase(),
                  style: AppTextStyles.body(size: 12, weight: FontWeight.w700, color: AppColors.goldBright)),
            ),
          ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _InfoBox(label: AppLocalizations.of(context).mpRoundLabel, value: '${mp.roundIndex + 1}', colors: colors),
            _InfoBox(
              label: AppLocalizations.of(context).mpTimeLabel,
              value: '${restant.toStringAsFixed(1)}s',
              colors: colors,
              valueColor: restant <= 10 ? AppColors.crimsonBright : colors.cream,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [colors.bgPanel2, colors.bgPanel]),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.gold.withOpacity(0.35)),
          ),
          child: Text(mp.pitchRevele, style: AppTextStyles.body(size: 15, color: colors.cream).copyWith(height: 1.6)),
        ),
        const SizedBox(height: 18),
        _AnswerRow(mp: mp, colors: colors),
        const SizedBox(height: 18),
        _LetterPool(mp: mp, colors: colors),
      ],
    );
  }
}

/// Bandeau "duel" en tête d'écran : avatar + nom + nombre de manches gagnées
/// de chaque côté, séparés par une barre de comparaison Elo dont le point de
/// partage est proportionnel aux deux classements (plus le classement d'un
/// camp est haut, plus sa portion de la barre est grande).
class _DuelHeader extends StatelessWidget {
  final MultiplayerState mp;
  final AppColors colors;
  final String avatarJoueur;
  final double eloJoueur;
  final double eloAdversaire;
  const _DuelHeader({
    required this.mp,
    required this.colors,
    required this.avatarJoueur,
    required this.eloJoueur,
    required this.eloAdversaire,
  });

  @override
  Widget build(BuildContext context) {
    final total = eloJoueur + eloAdversaire;
    // Bornée pour qu'aucun des deux camps ne disparaisse visuellement de la
    // barre, même face à un très gros écart de classement.
    final fractionJoueur = total <= 0 ? 0.5 : (eloJoueur / total).clamp(0.12, 0.88);
    final partsJoueur = (fractionJoueur * 1000).round().clamp(1, 999);
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _DuelSide(
                avatar: avatarJoueur,
                avatarBg: AppColors.gold,
                nom: AppLocalizations.of(context).mpYou,
                manches: mp.playerScore,
                colors: colors,
                alignRight: false,
              ),
            ),
            Expanded(
              child: _DuelSide(
                avatar: '👻',
                avatarBg: AppColors.crimson,
                nom: mp.nomAdversaireActuel ?? AppLocalizations.of(context).mpOpponentFallback,
                manches: mp.ghostScore,
                colors: colors,
                alignRight: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 8,
            child: Row(
              children: [
                Expanded(flex: partsJoueur, child: Container(color: AppColors.gold)),
                Expanded(flex: 1000 - partsJoueur, child: Container(color: AppColors.crimson)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${eloJoueur.round()}',
                style: AppTextStyles.body(size: 11, weight: FontWeight.w700, color: AppColors.goldBright)),
            Text('${eloAdversaire.round()}',
                style: AppTextStyles.body(size: 11, weight: FontWeight.w700, color: AppColors.crimsonBright)),
          ],
        ),
      ],
    );
  }
}

class _DuelSide extends StatelessWidget {
  final String avatar;
  final Color avatarBg;
  final String nom;
  final int manches;
  final AppColors colors;
  final bool alignRight;
  const _DuelSide({
    required this.avatar,
    required this.avatarBg,
    required this.nom,
    required this.manches,
    required this.colors,
    required this.alignRight,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        CircleAvatar(radius: 18, backgroundColor: avatarBg, child: Text(avatar, style: const TextStyle(fontSize: 17))),
        const SizedBox(height: 4),
        Text(nom,
            textAlign: alignRight ? TextAlign.right : TextAlign.left,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body(size: 13, weight: FontWeight.w700, color: colors.cream)),
        Text(AppLocalizations.of(context).mpRoundsWon(manches),
            style: AppTextStyles.body(size: 11, color: colors.muted)),
      ],
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String label;
  final String value;
  final AppColors colors;
  final Color? valueColor;
  const _InfoBox({required this.label, required this.value, required this.colors, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colors.bgPanel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.gold.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(label, style: AppTextStyles.body(size: 10, color: colors.muted).copyWith(letterSpacing: 1)),
          Text(value, style: AppTextStyles.display(size: 16, color: valueColor ?? colors.cream)),
        ],
      ),
    );
  }
}

class _RoundResultView extends StatelessWidget {
  final MultiplayerState mp;
  final AppColors colors;
  const _RoundResultView({required this.mp, required this.colors});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final texte = switch (mp.roundWinner) {
      'joueur' => t.mpRoundWon,
      'fantome' => t.mpRoundLost,
      _ => t.mpRoundTie,
    };
    // Réponse surlignée selon l'issue de la manche : vert si le joueur a
    // trouvé le premier, rouge s'il a perdu, couleur neutre en cas d'égalité.
    final couleurReponse = switch (mp.roundWinner) {
      'joueur' => AppColors.greenBright,
      'fantome' => AppColors.crimsonBright,
      _ => colors.cream,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 60),
        Text(texte, textAlign: TextAlign.center, style: AppTextStyles.display(size: 20, color: AppColors.goldBright)),
        const SizedBox(height: 10),
        Text(mp.currentEnigme?.reponseFor(mp.locale) ?? '', textAlign: TextAlign.center,
            style: AppTextStyles.body(size: 15, weight: FontWeight.w700, color: couleurReponse)),
        const SizedBox(height: 16),
        Text('${mp.playerScore} - ${mp.ghostScore}', textAlign: TextAlign.center,
            style: AppTextStyles.display(size: 28, color: AppColors.goldBright)),
      ],
    );
  }
}

class _ResultView extends StatelessWidget {
  final MultiplayerState mp;
  final AppColors colors;
  final VoidCallback onRejouer;
  final VoidCallback onWatchAdMatch;
  final bool busyAdMatch;
  const _ResultView({
    required this.mp,
    required this.colors,
    required this.onRejouer,
    required this.onWatchAdMatch,
    required this.busyAdMatch,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final locale = context.watch<AppSettings>().locale;
    final avant = mp.eloAvantMatch ?? mp.eloRating;
    final apres = mp.eloApresMatch ?? mp.eloRating;
    final delta = apres - avant;
    final titreChange = titreForElo(avant, locale) != titreForElo(apres, locale);
    final texteResultat = switch (mp.matchResult) {
      'victoire' => t.mpMatchWin,
      'defaite' => t.mpMatchLoss,
      _ => t.mpMatchDraw,
    };
    final couleurResultat = switch (mp.matchResult) {
      'victoire' => AppColors.greenBright,
      'defaite' => AppColors.crimsonBright,
      _ => AppColors.goldBright,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        Text(texteResultat, textAlign: TextAlign.center, style: AppTextStyles.display(size: 24, color: couleurResultat)),
        const SizedBox(height: 6),
        Text('${mp.playerScore} - ${mp.ghostScore}', textAlign: TextAlign.center,
            style: AppTextStyles.body(size: 16, color: colors.muted)),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$avant', style: AppTextStyles.body(size: 18, color: colors.muted)),
            const SizedBox(width: 10),
            const Icon(Icons.arrow_forward, size: 16, color: AppColors.gold),
            const SizedBox(width: 10),
            Text('$apres', style: AppTextStyles.display(size: 26, color: AppColors.goldBright)),
            const SizedBox(width: 8),
            Text(delta >= 0 ? '(+$delta)' : '($delta)',
                style: AppTextStyles.body(size: 14, weight: FontWeight.w700,
                    color: delta >= 0 ? AppColors.greenBright : AppColors.crimsonBright)),
          ],
        ),
        const SizedBox(height: 8),
        Text(titreForElo(apres, locale), textAlign: TextAlign.center,
            style: AppTextStyles.body(size: 14, weight: FontWeight.w700, color: colors.cream)),
        if (titreChange) ...[
          const SizedBox(height: 4),
          Text(t.mpNewTitle, textAlign: TextAlign.center,
              style: AppTextStyles.body(size: 12, weight: FontWeight.w700, color: AppColors.goldBright)),
        ],
        const SizedBox(height: 26),
        if (mp.matchesRestantes > 0)
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.crimson),
            onPressed: onRejouer,
            child: Text(t.mpReplay, style: AppTextStyles.display(size: 16, color: colors.cream)),
          )
        else if (mp.peutRegarderPubMatch)
          OutlinedButton(
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            onPressed: busyAdMatch ? null : onWatchAdMatch,
            child: busyAdMatch
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold))
                : Text(
                    t.mpWatchAdForMatch(mp.adsWatchedForMatchesToday, kMultiplayerAdsMaxParJour),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body(size: 13, weight: FontWeight.w700, color: AppColors.goldBright),
                  ),
          )
        else
          Text(t.mpQuotaReachedFull, textAlign: TextAlign.center,
              style: AppTextStyles.body(size: 13, color: colors.muted)),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.defiBackHome, style: AppTextStyles.body(size: 13, weight: FontWeight.w700, color: AppColors.gold)),
        ),
      ],
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

/// Grille de tuiles pour la réponse à deviner — même mécanique que les
/// autres modes (mots groupés dans un Wrap, réduction automatique des mots
/// trop longs).
class _AnswerRow extends StatelessWidget {
  final MultiplayerState mp;
  final AppColors colors;
  const _AnswerRow({required this.mp, required this.colors});

  @override
  Widget build(BuildContext context) {
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

    // Une fois la manche résolue, la grille affiche le mot complet (pas
    // seulement les lettres déjà placées par le joueur) surligné en vert
    // (manche gagnée) ou rouge (perdue/égalité) pendant les 2s qui précèdent
    // l'écran de résultat de la manche.
    final Color? couleurReveal = mp.roundResolved
        ? switch (mp.roundWinner) {
            'joueur' => AppColors.greenBright,
            'fantome' => AppColors.crimsonBright,
            _ => AppColors.goldBright,
          }
        : null;

    for (var i = 0; i < mp.slots.length; i++) {
      final slot = mp.slots[i];
      if (slot.isSpace) {
        flushWord();
        continue;
      }
      if (slot.isAuto) {
        currentWord.add(_Blank(text: slot.char, colors: colors, auto: true, revealColor: couleurReveal));
        continue;
      }
      if (couleurReveal != null) {
        currentWord.add(_Blank(text: slot.char, colors: colors, filled: true, revealColor: couleurReveal));
        continue;
      }
      final tileId = mp.guess[i];
      final letter = tileId != null ? mp.pool[tileId].letter : null;
      currentWord.add(GestureDetector(
        onTap: () => context.read<MultiplayerState>().onBlankTap(i),
        child: _Blank(text: letter ?? '_', colors: colors, cursor: i == mp.cursorIndex, filled: letter != null),
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

class _Blank extends StatelessWidget {
  final String text;
  final AppColors colors;
  final bool cursor;
  final bool filled;
  final bool auto;
  final Color? revealColor;
  const _Blank({
    required this.text,
    required this.colors,
    this.cursor = false,
    this.filled = false,
    this.auto = false,
    this.revealColor,
  });

  @override
  Widget build(BuildContext context) {
    final reveal = revealColor;
    return Container(
      width: 30,
      height: 38,
      margin: const EdgeInsets.only(right: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: reveal != null ? reveal.withOpacity(0.18) : (cursor ? AppColors.gold.withOpacity(0.22) : null),
        border: Border(bottom: BorderSide(color: reveal ?? (auto ? colors.muted : AppColors.gold), width: 3)),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      ),
      child: Text(text, style: AppTextStyles.tile(size: 19, color: reveal ?? (filled || auto ? AppColors.goldBright : Colors.transparent))),
    );
  }
}

class _LetterPool extends StatelessWidget {
  final MultiplayerState mp;
  final AppColors colors;
  const _LetterPool({required this.mp, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: mp.pool.map((tile) {
        return GestureDetector(
          onTap: tile.used ? null : () => context.read<MultiplayerState>().onLetterTap(tile),
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
