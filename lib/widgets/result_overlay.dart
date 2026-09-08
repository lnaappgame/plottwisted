import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../models/puzzle.dart';
import '../services/app_settings.dart';
import '../services/game_state.dart';
import '../theme/app_theme.dart';

class ResultOverlay extends StatelessWidget {
  final VoidCallback onNext;
  const ResultOverlay({super.key, required this.onNext});

  List<InlineSpan> _personRevealSpans(BuildContext context, NameColor initial, PersonRef person, AppColors colors, bool colorblindMode, String locale) {
    String parenText;
    String? filmNote;
    switch (initial) {
      case NameColor.blue:
        parenText = person.actorFor(locale); filmNote = null;
        break;
      case NameColor.red:
        parenText = person.decoyFor(locale);
        filmNote = person.decoyFilmFor(locale).isNotEmpty ? person.decoyFilmFor(locale) : null;
        break;
      case NameColor.orange:
        parenText = person.sameRoleActorFor(locale);
        filmNote = person.sameRoleFilmFor(locale).isNotEmpty ? person.sameRoleFilmFor(locale) : null;
        break;
      case NameColor.violet:
        parenText = person.violetFor(locale); filmNote = null;
        break;
      case NameColor.green:
        parenText = person.actorFor(locale); filmNote = null;
        break;
    }
    final parenColor = colors.forNameColor(initial == NameColor.green ? NameColor.blue : initial);
    if (colorblindMode) {
      parenText = '${AppColors.symbolForNameColor(initial == NameColor.green ? NameColor.blue : initial)} $parenText';
    }
    return [
      TextSpan(text: person.realFor(locale), style: TextStyle(color: colors.forNameColor(NameColor.green), fontWeight: FontWeight.w700)),
      const TextSpan(text: ' ('),
      TextSpan(text: parenText, style: TextStyle(color: parenColor, fontStyle: FontStyle.italic)),
      if (filmNote != null)
        TextSpan(text: AppLocalizations.of(context).resultInFilm(filmNote), style: TextStyle(color: parenColor, fontStyle: FontStyle.italic)),
      const TextSpan(text: ')'),
    ];
  }

  /// Reconstitue le pitch complet avec {p1}/{p2} remplacés par le vrai nom
  /// suivi du nom "de l'énigme" entre parenthèses, puis l'indice ajouté à
  /// la fin — comme sur l'écran de révélation du prototype HTML.
  List<InlineSpan> _correctedPitchSpans(BuildContext context, Puzzle puzzle, AppColors colors, bool colorblindMode, String locale) {
    final spans = <InlineSpan>[];
    var remaining = puzzle.pitchTemplateFor(locale);
    final tokens = [
      ('{p1}', puzzle.p1, puzzle.p1InitialColor),
      if (puzzle.hasP2) ('{p2}', puzzle.p2, puzzle.p2InitialColor),
    ];

    while (remaining.isNotEmpty) {
      int? nextIdx;
      String? matchToken;
      PersonRef? matchPerson;
      NameColor? matchColor;
      for (final t in tokens) {
        final idx = remaining.indexOf(t.$1);
        if (idx != -1 && (nextIdx == null || idx < nextIdx)) {
          nextIdx = idx; matchToken = t.$1; matchPerson = t.$2; matchColor = t.$3;
        }
      }
      if (nextIdx == null) { spans.add(TextSpan(text: remaining)); break; }
      if (nextIdx > 0) spans.add(TextSpan(text: remaining.substring(0, nextIdx)));
      spans.addAll(_personRevealSpans(context, matchColor!, matchPerson!, colors, colorblindMode, locale));
      remaining = remaining.substring(nextIdx + matchToken!.length);
    }

    final hint = puzzle.extraHintFor(locale);
    if (hint.isNotEmpty) {
      spans.add(TextSpan(text: ' $hint'));
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    final settings = context.watch<AppSettings>();
    final colors = AppColors(settings.isLightTheme, colorblind: settings.colorblindMode);
    final puzzle = game.currentPuzzle;
    final t = AppLocalizations.of(context);

    return Container(
      color: Colors.black.withOpacity(0.92),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [colors.bgPanel2, colors.bgPanel]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.gold.withOpacity(0.35)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(puzzle.titleFor(game.locale), textAlign: TextAlign.center, style: AppTextStyles.display(size: 28)),
              Text(puzzle.year, style: AppTextStyles.body(size: 12, color: colors.muted)),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.25), borderRadius: BorderRadius.circular(10)),
                child: RichText(
                  textAlign: TextAlign.left,
                  text: TextSpan(
                    style: AppTextStyles.body(size: 14, color: colors.cream).copyWith(height: 1.6),
                    children: _correctedPitchSpans(context, puzzle, colors, settings.colorblindMode, game.locale),
                  ),
                ),
              ),
              if (puzzle.revealNoteFor(game.locale).isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.gold.withOpacity(0.2)),
                  ),
                  child: Text(
                    puzzle.revealNoteFor(game.locale),
                    textAlign: TextAlign.left,
                    style: AppTextStyles.body(size: 12.5, color: colors.muted).copyWith(fontStyle: FontStyle.italic),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              if (puzzle.linkUrlFor(game.locale).isNotEmpty)
                TextButton.icon(
                  onPressed: () => launchUrl(Uri.parse(puzzle.linkUrlFor(game.locale)), mode: LaunchMode.externalApplication),
                  icon: const Icon(Icons.open_in_new, size: 14, color: AppColors.gold),
                  label: Text(t.resultSeeFilmSheet, style: AppTextStyles.body(size: 12, color: AppColors.gold)),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.crimson,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: onNext,
                  child: Text(t.resultNextFilm, style: AppTextStyles.display(size: 16, color: colors.cream)),
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
