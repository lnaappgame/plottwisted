import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../data/cinema_events_data.dart';
import '../l10n/app_localizations.dart';
import '../services/app_settings.dart';
import '../services/streak_state.dart';
import '../theme/app_theme.dart';

String _formatDate(BuildContext context, DateTime d) =>
    DateFormat.yMMMMd(AppLocalizations.of(context).localeName).format(d);

/// Calendrier de la série de jours consécutifs joués : un cycle de 28 jours
/// (4 semaines) qui se répète indéfiniment — voir [StreakState.jourDuCycle].
/// Chaque jour rapporte un bonus mineur (1 joker Indice), sauf les paliers
/// (3, 7, 14) qui rapportent un bonus majeur, le jour 28 qui marque un cycle
/// complet et rapporte ce bonus majeur multiplié par 3, et tout jour qui
/// tombe sur un grand événement du cinéma (voir [kCinemaEvents]), qui
/// rapporte un bonus supplémentaire cumulé avec celui du jour.
class StreakCalendarDialog extends StatelessWidget {
  const StreakCalendarDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final streak = context.watch<StreakState>();
    final colors = AppColors(settings.isLightTheme, colorblind: settings.colorblindMode);
    final jourActuel = streak.jourDuCycle;
    final t = AppLocalizations.of(context);

    // Pour chaque jour du cycle, l'événement du cinéma qui tombe sur sa date
    // réelle projetée, s'il y en a un (voir StreakState.dateForJourDuCycle).
    final evenementsParJour = <int, CinemaEvent>{};
    for (var jour = 1; jour <= kStreakCycleLength; jour++) {
      final date = streak.dateForJourDuCycle(jour);
      if (date == null) continue;
      for (final event in kCinemaEvents) {
        if (event.date.year == date.year && event.date.month == date.month && event.date.day == date.day) {
          evenementsParJour[jour] = event;
          break;
        }
      }
    }

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
                Text(t.streakCalendarTitle, textAlign: TextAlign.center, style: AppTextStyles.display(size: 20)),
                const SizedBox(height: 6),
                Text(
                  t.streakCalendarSubtitle(streak.currentStreak, jourActuel, kStreakCycleLength),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body(size: 12, color: colors.muted),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 7,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  children: List.generate(kStreakCycleLength, (i) {
                    final jour = i + 1;
                    return _JourCase(
                      jour: jour,
                      jourActuel: jourActuel,
                      colors: colors,
                      event: evenementsParJour[jour],
                    );
                  }),
                ),
                if (evenementsParJour.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  ...evenementsParJour.entries.map((e) {
                    final date = streak.dateForJourDuCycle(e.key)!;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        t.streakCalendarEventLine(e.value.emoji, e.key, e.value.label, _formatDate(context, date)),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body(size: 11, weight: FontWeight.w700, color: AppColors.goldBright),
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 14),
                _Legende(icon: '💡', label: t.streakLegendMinor, colors: colors),
                const SizedBox(height: 4),
                _Legende(icon: '⭐', label: t.streakLegendMajor(kStreakPaliers.take(3).join(', ')), colors: colors),
                const SizedBox(height: 4),
                _Legende(icon: '👑', label: t.streakLegendCycle(kStreakCycleLength), colors: colors),
                const SizedBox(height: 4),
                _Legende(icon: '🏆', label: t.streakLegendEvent, colors: colors),
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
    );
  }
}

class _JourCase extends StatelessWidget {
  final int jour;
  final int jourActuel;
  final AppColors colors;
  final CinemaEvent? event;
  const _JourCase({required this.jour, required this.jourActuel, required this.colors, this.event});

  @override
  Widget build(BuildContext context) {
    final estAujourdhui = jour == jourActuel;
    final estAcquis = jour <= jourActuel;
    final estCycleComplet = jour == kStreakCycleLength;
    final estPalier = kStreakPaliers.contains(jour);
    final estEvenement = event != null;

    final Color accent = estEvenement
        ? AppColors.crimsonBright
        : estCycleComplet
            ? AppColors.goldBright
            : (estPalier ? AppColors.gold : colors.muted);
    final String icon = estEvenement ? event!.emoji : (estCycleComplet ? '👑' : (estPalier ? '⭐' : '💡'));

    return Container(
      decoration: BoxDecoration(
        color: estAujourdhui ? accent.withOpacity(0.25) : colors.bgPanel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: estAujourdhui ? accent : accent.withOpacity(estEvenement ? 0.6 : 0.3),
          width: estAujourdhui ? 2 : (estEvenement ? 1.5 : 1),
        ),
      ),
      child: Opacity(
        opacity: estAcquis ? 1 : 0.35,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 13)),
            Text('$jour', style: AppTextStyles.body(size: 10, weight: FontWeight.w700, color: colors.cream)),
          ],
        ),
      ),
    );
  }
}

class _Legende extends StatelessWidget {
  final String icon;
  final String label;
  final AppColors colors;
  const _Legende({required this.icon, required this.label, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: AppTextStyles.body(size: 11, color: colors.muted))),
      ],
    );
  }
}
