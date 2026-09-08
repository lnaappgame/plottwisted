import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/puzzle.dart';
import '../services/app_settings.dart';
import '../theme/app_theme.dart';

/// Écran d'annonce de monde. Avec un seul monde dans [worlds] : simple
/// écran "COMMENCER" (tutoriel, monde 1 imposé). Avec deux mondes : le
/// joueur choisit lequel jouer ensuite (mécanique de progression par choix).
class WorldIntroOverlay extends StatelessWidget {
  final List<GameWorld> worlds;
  final AppColors colors;
  final ValueChanged<int> onChoose;
  const WorldIntroOverlay({super.key, required this.worlds, required this.colors, required this.onChoose});

  @override
  Widget build(BuildContext context) {
    final isChoice = worlds.length > 1;
    final t = AppLocalizations.of(context);
    final locale = context.watch<AppSettings>().locale;
    return Container(
      color: Colors.black.withOpacity(0.92),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [colors.bgPanel2, colors.bgPanel]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.gold.withOpacity(0.35)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (isChoice) ...[
                Text(t.worldComplete,
                    style: AppTextStyles.body(size: 11, weight: FontWeight.w700, color: colors.muted)
                        .copyWith(letterSpacing: 3)),
                const SizedBox(height: 6),
                Text(t.worldChooseNext, textAlign: TextAlign.center, style: AppTextStyles.display(size: 24)),
                const SizedBox(height: 18),
                for (final w in worlds) ...[
                  _WorldChoiceCard(world: w, colors: colors, onTap: () => onChoose(w.number)),
                  if (w != worlds.last) const SizedBox(height: 12),
                ],
              ] else ...[
                for (final w in worlds) ...[
                  Text(t.worldNumber(w.number),
                      style: AppTextStyles.body(size: 11, weight: FontWeight.w700, color: colors.muted)
                          .copyWith(letterSpacing: 3)),
                  const SizedBox(height: 6),
                  Text(w.categoryLabelFor(locale), textAlign: TextAlign.center, style: AppTextStyles.display(size: 30)),
                  const SizedBox(height: 14),
                  Text(
                    t.worldStartHint(w.puzzles.length),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body(size: 13, color: colors.cream).copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.crimson,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => onChoose(w.number),
                      child: Text(t.defiStart, style: AppTextStyles.display(size: 16, color: colors.cream)),
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
}

class _WorldChoiceCard extends StatelessWidget {
  final GameWorld world;
  final AppColors colors;
  final VoidCallback onTap;
  const _WorldChoiceCard({required this.world, required this.colors, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colors.bgPanel,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gold.withOpacity(0.4)),
        ),
        child: Column(
          children: [
            Text(AppLocalizations.of(context).worldNumber(world.number),
                style: AppTextStyles.body(size: 10, weight: FontWeight.w700, color: colors.muted).copyWith(letterSpacing: 2)),
            const SizedBox(height: 4),
            Text(world.categoryLabelFor(context.watch<AppSettings>().locale),
                style: AppTextStyles.display(size: 22, color: AppColors.goldBright)),
          ],
        ),
      ),
    );
  }
}
