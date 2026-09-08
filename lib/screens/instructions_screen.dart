import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/puzzle.dart';
import '../services/app_settings.dart';
import '../services/game_state.dart';
import '../theme/app_theme.dart';

const _nameColorByKey = {
  'green': NameColor.green,
  'red': NameColor.red,
  'blue': NameColor.blue,
  'orange': NameColor.orange,
  'violet': NameColor.violet,
};

class InstructionsScreen extends StatelessWidget {
  const InstructionsScreen({super.key});

  static List<(String, String, String)> _legend(AppLocalizations t) => [
    ('green', t.instrColorGreen, t.instructionsLegendGreen),
    ('red', t.instrColorRed, t.instructionsLegendRed),
    ('blue', t.instrColorBlue, t.instructionsLegendBlue),
    ('orange', t.instrColorOrange, t.instructionsLegendOrange),
    ('violet', t.instrColorViolet, t.instructionsLegendViolet),
  ];

  static List<(String, String, String)> _mineurs(AppLocalizations t) => [
    ('💡', t.instrJokerRevealLabel, t.instrJokerRevealDesc),
    ('✂️', t.instrJokerEliminateLabel, t.instrJokerEliminateDesc),
    ('🟢', t.instrJokerCharacterLabel, t.instrJokerCharacterDesc),
  ];

  static List<(String, String, String)> _majeurs(AppLocalizations t) => [
    ('🔵', t.instrJokerActorLabel, t.instrJokerActorDesc),
    ('🎬', t.instrJokerHintLabel, t.instrJokerHintDesc),
    ('📖', t.instrJokerRevealWordLabel, t.instrJokerRevealWordDesc),
  ];

  static List<(String, String, String)> _speciaux(AppLocalizations t) => [
    ('🔴', t.instrJokerRedLabel, t.instrJokerRedDesc),
  ];

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final game = context.watch<GameState>();
    final colors = AppColors(settings.isLightTheme, colorblind: settings.colorblindMode);
    final t = AppLocalizations.of(context);

    return Dialog(
      backgroundColor: colors.bgPanel2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(t.instructionsTitle, textAlign: TextAlign.center, style: AppTextStyles.display(size: 22)),
                const SizedBox(height: 10),
                Text(
                  t.instructionsIntro,
                  style: AppTextStyles.body(size: 13, color: colors.cream).copyWith(height: 1.5),
                ),
                const SizedBox(height: 14),
                Text(t.instructionsColorsHeader,
                    style: AppTextStyles.body(size: 11, weight: FontWeight.w700, color: AppColors.gold)
                        .copyWith(letterSpacing: 1)),
                const SizedBox(height: 4),
                ..._legend(t).where((c) {
                  // Vert/rouge/bleu visibles dès le départ ; orange/violet
                  // seulement après leur première rencontre en jeu.
                  if (['green', 'red', 'blue'].contains(c.$1)) return true;
                  return game.colorsSeen.contains(c.$1);
                }).map((c) {
                  final nameColor = _nameColorByKey[c.$1]!;
                  final color = colors.forNameColor(nameColor);
                  final symbol = AppColors.symbolForNameColor(nameColor);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 3),
                          width: 14, height: 14,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                          child: settings.colorblindMode
                              ? Text(symbol, style: TextStyle(fontSize: 8, color: colors.bgDeep, height: 1))
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: AppTextStyles.body(size: 12, color: colors.cream),
                              children: [
                                TextSpan(
                                    text: settings.colorblindMode ? '$symbol ${c.$2} — ' : '${c.$2} — ',
                                    style: TextStyle(color: color, fontWeight: FontWeight.w700)),
                                TextSpan(text: c.$3),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),
                Text(t.instructionsJokersHeader,
                    style: AppTextStyles.body(size: 11, weight: FontWeight.w700, color: AppColors.gold)
                        .copyWith(letterSpacing: 1)),
                const SizedBox(height: 8),
                Text(t.instructionsMinorHeader, style: AppTextStyles.body(size: 12, weight: FontWeight.w700, color: colors.muted)),
                ..._mineurs(t).map((j) => _JokerLine(icon: j.$1, label: j.$2, description: j.$3, colors: colors)),
                const SizedBox(height: 10),
                Text(t.instructionsMajorHeader, style: AppTextStyles.body(size: 12, weight: FontWeight.w700, color: colors.muted)),
                ..._majeurs(t).map((j) => _JokerLine(icon: j.$1, label: j.$2, description: j.$3, colors: colors)),
                const SizedBox(height: 10),
                Text(t.instructionsSpecialHeader, style: AppTextStyles.body(size: 12, weight: FontWeight.w700, color: colors.muted)),
                ..._speciaux(t).map((j) => _JokerLine(icon: j.$1, label: j.$2, description: j.$3, colors: colors)),
                const SizedBox(height: 14),
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
    );
  }
}

class _JokerLine extends StatelessWidget {
  final String icon;
  final String label;
  final String description;
  final AppColors colors;
  const _JokerLine({required this.icon, required this.label, required this.description, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTextStyles.body(size: 12, color: colors.cream),
                children: [
                  TextSpan(text: '$label — ', style: TextStyle(color: AppColors.goldBright, fontWeight: FontWeight.w700)),
                  TextSpan(text: description),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
