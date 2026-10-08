import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/joker.dart';
import '../models/puzzle.dart';
import '../services/app_settings.dart';
import '../services/game_state.dart';
import '../theme/app_theme.dart';
import '../widgets/joker_style.dart';

const _nameColorByKey = {
  'green': NameColor.green,
  'red': NameColor.red,
  'blue': NameColor.blue,
  'orange': NameColor.orange,
  'violet': NameColor.violet,
};

/// « Comment jouer » : deux onglets, les jokers et les modes de jeu.
class InstructionsScreen extends StatefulWidget {
  const InstructionsScreen({super.key});

  @override
  State<InstructionsScreen> createState() => _InstructionsScreenState();
}

class _InstructionsScreenState extends State<InstructionsScreen> {
  int _tab = 0;

  static List<(String, String, String)> _legend(AppLocalizations t) => [
        ('green', t.instrColorGreen, t.instructionsLegendGreen),
        ('red', t.instrColorRed, t.instructionsLegendRed),
        ('blue', t.instrColorBlue, t.instructionsLegendBlue),
        ('orange', t.instrColorOrange, t.instructionsLegendOrange),
        ('violet', t.instrColorViolet, t.instructionsLegendViolet),
      ];

  static List<(String, String, String, JokerKind?)> _mineurs(AppLocalizations t) => [
        ('💡', t.instrJokerRevealLabel, t.instrJokerRevealDesc, JokerKind.reveal),
        ('✂️', t.instrJokerEliminateLabel, t.instrJokerEliminateDesc, JokerKind.eliminate),
        ('🟢', t.instrJokerCharacterLabel, t.instrJokerCharacterDesc, JokerKind.character),
      ];

  static List<(String, String, String, JokerKind?)> _majeurs(AppLocalizations t) => [
        ('🔵', t.instrJokerActorLabel, t.instrJokerActorDesc, JokerKind.actor),
        ('🎬', t.instrJokerHintLabel, t.instrJokerHintDesc, JokerKind.hint),
        ('📖', t.instrJokerRevealWordLabel, t.instrJokerRevealWordDesc, JokerKind.revealWord),
      ];

  static List<(String, String, String, JokerKind?)> _speciaux(AppLocalizations t) => [
        ('🔴', t.instrJokerRedLabel, t.instrJokerRedDesc, JokerKind.red),
        ('⏭️', t.instrJokerSkipLabel, t.instrJokerSkipDesc, null),
      ];

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final colors = AppColors(settings.isLightTheme, colorblind: settings.colorblindMode);
    final t = AppLocalizations.of(context);

    return Dialog(
      backgroundColor: colors.bgPanel2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(t.instructionsTitle, textAlign: TextAlign.center, style: AppTextStyles.display(size: 22)),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (final (i, label) in [t.instructionsTabJokers, t.instructionsTabModes].indexed) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: _TabChip(
                        label: label,
                        selected: _tab == i,
                        colors: colors,
                        onTap: () => setState(() => _tab = i),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  key: ValueKey(_tab), // chaque onglet repart en haut
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: _tab == 0 ? _jokersTab(t, colors) : _modesTab(context, t, colors, settings),
                  ),
                ),
              ),
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
    );
  }

  List<Widget> _jokersTab(AppLocalizations t, AppColors colors) => [
        _Subheader(t.instructionsMinorHeader, colors),
        ..._mineurs(t).map((j) => _JokerLine(
            icon: j.$1,
            label: j.$2,
            description: j.$3,
            accent: j.$4 == null ? null : jokerColor(j.$4!, colors),
            colors: colors)),
        const SizedBox(height: 10),
        _Subheader(t.instructionsMajorHeader, colors),
        ..._majeurs(t).map((j) => _JokerLine(
            icon: j.$1,
            label: j.$2,
            description: j.$3,
            accent: j.$4 == null ? null : jokerColor(j.$4!, colors),
            colors: colors)),
        const SizedBox(height: 10),
        _Subheader(t.instructionsSpecialHeader, colors),
        ..._speciaux(t).map((j) => _JokerLine(
            icon: j.$1,
            label: j.$2,
            description: j.$3,
            accent: j.$4 == null ? null : jokerColor(j.$4!, colors),
            colors: colors)),
        const SizedBox(height: 16),
        _Header(t.instructionsEarnHeader),
        const SizedBox(height: 4),
        for (final line in [t.instrEarnAd, t.instrEarnLevels, t.instrEarnModes, t.instrEarnShop, t.instrEarnEmpty])
          _Bullet(line, colors),
      ];

  List<Widget> _modesTab(BuildContext context, AppLocalizations t, AppColors colors, AppSettings settings) {
    final game = context.watch<GameState>();
    return [
      _ModeBlock(t.instrModeMainTitle, t.instrModeMainDesc, colors),
      const SizedBox(height: 6),
      _Header(t.instructionsColorsHeader),
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
                width: 14,
                height: 14,
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
      _ModeBlock(t.instrModeEnigmeTitle, t.instrModeEnigmeDesc, colors),
      const SizedBox(height: 16),
      _ModeBlock(t.instrModeDefiTitle, t.instrModeDefiDesc, colors),
      const SizedBox(height: 16),
      _ModeBlock(t.instrModeMpTitle, t.instrModeMpDesc, colors),
    ];
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final AppColors colors;
  final VoidCallback onTap;
  const _TabChip({required this.label, required this.selected, required this.colors, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.gold : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.gold.withOpacity(selected ? 1 : 0.4)),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label,
                style: AppTextStyles.body(
                    size: 13, weight: FontWeight.w700, color: selected ? const Color(0xFF1A1410) : AppColors.gold)),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String text;
  const _Header(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: AppTextStyles.body(size: 11, weight: FontWeight.w700, color: AppColors.gold).copyWith(letterSpacing: 1));
}

class _Subheader extends StatelessWidget {
  final String text;
  final AppColors colors;
  const _Subheader(this.text, this.colors);

  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppTextStyles.body(size: 12, weight: FontWeight.w700, color: colors.muted));
}

class _Bullet extends StatelessWidget {
  final String text;
  final AppColors colors;
  const _Bullet(this.text, this.colors);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: AppTextStyles.body(size: 12, color: AppColors.gold)),
          Expanded(child: Text(text, style: AppTextStyles.body(size: 12, color: colors.cream).copyWith(height: 1.4))),
        ],
      ),
    );
  }
}

class _ModeBlock extends StatelessWidget {
  final String title;
  final String description;
  final AppColors colors;
  const _ModeBlock(this.title, this.description, this.colors);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: AppTextStyles.body(size: 14, weight: FontWeight.w700, color: AppColors.goldBright)),
        const SizedBox(height: 4),
        Text(description, style: AppTextStyles.body(size: 12, color: colors.cream).copyWith(height: 1.45)),
      ],
    );
  }
}

class _JokerLine extends StatelessWidget {
  final String icon;
  final String label;
  final String description;
  final Color? accent;
  final AppColors colors;
  const _JokerLine(
      {required this.icon, required this.label, required this.description, this.accent, required this.colors});

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
                  TextSpan(
                      text: '$label — ',
                      style: TextStyle(color: accent ?? AppColors.goldBright, fontWeight: FontWeight.w700)),
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
