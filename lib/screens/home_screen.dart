import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../services/app_settings.dart';
import '../services/game_state.dart';
import '../services/streak_state.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_view.dart';
import '../widgets/clapper_transition.dart';
import '../widgets/daily_wheel_dialog.dart';
import '../widgets/scifi_background.dart';
import 'defi_screen.dart';
import 'enigme_screen.dart';
import 'halloween_event_screen.dart';
import 'multiplayer_screen.dart';
import 'settings_screen.dart';
import 'shop_screen.dart';
import 'instructions_screen.dart';
import 'streak_calendar_screen.dart';

Map<int, String> _streakRecompenses(AppLocalizations t) => {
      3: t.homeStreakReward3,
      7: t.homeStreakReward7,
      14: t.homeStreakReward14,
      28: t.homeStreakReward28,
    };

class HomeScreen extends StatefulWidget {
  final VoidCallback onPlay;
  const HomeScreen({super.key, required this.onPlay});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowStreakCelebration());
  }

  void _maybeShowStreakCelebration() {
    final streak = context.read<StreakState>();
    final palier = streak.pendingCelebration;
    if (palier == null) return;
    if (!kStreakCalendarEnabled) {
      // Calendrier en refonte : on n'affiche rien, et on ne garde pas une
      // vieille célébration pour le jour où il reviendra.
      streak.acknowledgeCelebration();
      return;
    }
    final settings = context.read<AppSettings>();
    final colors = AppColors(settings.isLightTheme);
    final t = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: colors.bgPanel2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(t.homeStreakDays(streak.currentStreak),
                  textAlign: TextAlign.center, style: AppTextStyles.display(size: 20)),
              const SizedBox(height: 10),
              Text(_streakRecompenses(t)[palier] ?? '',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body(size: 14, color: colors.cream).copyWith(height: 1.5)),
              const SizedBox(height: 18),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.crimson),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(t.homeGreat, style: AppTextStyles.display(size: 15, color: colors.cream)),
              ),
            ],
          ),
        ),
      ),
    ).then((_) => streak.acknowledgeCelebration());
  }

  /// Entrée dans un mode de jeu : clap de cinéma, puis [action] une fois la
  /// latte refermée.
  void _enterMode(VoidCallback action) {
    ClapperTransition.play(context, () {
      if (mounted) action();
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final colors = AppColors(settings.isLightTheme);
    final streak = context.watch<StreakState>();
    final onPlay = widget.onPlay;
    final t = AppLocalizations.of(context);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: SciFiBackground(baseColor: colors.bgDeep)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              // LayoutBuilder + ConstrainedBox(minHeight) + IntrinsicHeight : sur
              // un écran assez haut, le Column (avec ses Spacer) remplit l'espace
              // exactement comme avant ; sur un écran trop court pour tout
              // contenir (petits téléphones), le contenu défile au lieu de
              // déborder — trouvé en testant à 360x640dp (bas de l'écran
              // débordait de 40px derrière Shop/Help).
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () => showDialog(context: context, builder: (_) => const _ProfilDialog()),
                                child: Container(
                                  padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
                                  decoration: BoxDecoration(
                                    color: colors.bgPanel,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      AvatarView(avatar: settings.avatar, radius: 16, background: AppColors.gold),
                                      const SizedBox(width: 8),
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(maxWidth: 110),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(settings.displayPlayerName,
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                                style: AppTextStyles.body(
                                                    size: 12, weight: FontWeight.w700, color: AppColors.goldBright)),
                                            Text(settings.playerId,
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                                style: AppTextStyles.body(size: 10, color: colors.muted)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  _WheelButton(colors: colors),
                                  const SizedBox(height: 8),
                                  _IconButton(
                                    icon: Icons.settings,
                                    colors: colors,
                                    onTap: () => showDialog(context: context, builder: (_) => const SettingsScreen()),
                                  ),
                                  if (kStreakCalendarEnabled && streak.currentStreak > 0) ...[
                                    const SizedBox(height: 8),
                                    InkWell(
                                      borderRadius: BorderRadius.circular(20),
                                      onTap: () =>
                                          showDialog(context: context, builder: (_) => const StreakCalendarDialog()),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: colors.bgPanel,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                                        ),
                                        child: Text('📅 ${streak.jourDuCycle}',
                                            style: AppTextStyles.body(
                                                size: 13, weight: FontWeight.w700, color: AppColors.goldBright)),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text('PLOT TWIST(ed)', style: AppTextStyles.display(size: 42)),
                          Text(t.homeTagline,
                              style: AppTextStyles.body(size: 11, color: colors.muted).copyWith(letterSpacing: 2)),
                          const Spacer(),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.crimson,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: () => _enterMode(onPlay),
                              child: Text(t.homePlay, style: AppTextStyles.display(size: 22, color: colors.cream)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (context.watch<GameState>().halloween.isActive) ...[
                            const _HalloweenEventButton(),
                            const SizedBox(height: 12),
                          ],
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () => _enterMode(() =>
                                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EnigmeScreen()))),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: const BorderSide(color: AppColors.gold),
                              ),
                              child: Text(t.homeWeeklyPuzzle,
                                  style: AppTextStyles.body(
                                      size: 12, weight: FontWeight.w700, color: AppColors.goldBright)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () => _enterMode(() =>
                                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DefiScreen()))),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: const BorderSide(color: AppColors.gold),
                              ),
                              child: Text(t.homeDailyChallenge,
                                  style: AppTextStyles.body(
                                      size: 12, weight: FontWeight.w700, color: AppColors.goldBright)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () => _enterMode(() => Navigator.of(context)
                                  .push(MaterialPageRoute(builder: (_) => const MultiplayerScreen()))),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: const BorderSide(color: AppColors.gold),
                              ),
                              child: Text(t.homeMultiplayer,
                                  style: AppTextStyles.body(
                                      size: 12, weight: FontWeight.w700, color: AppColors.goldBright)),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _SecondaryButton(
                                label: t.homeShop,
                                colors: colors,
                                onTap: () => showDialog(context: context, builder: (_) => const ShopScreen()),
                              ),
                              const SizedBox(width: 10),
                              _SecondaryButton(
                                label: t.homeHelp,
                                colors: colors,
                                onTap: () => showDialog(context: context, builder: (_) => const InstructionsScreen()),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfilDialog extends StatefulWidget {
  const _ProfilDialog();

  @override
  State<_ProfilDialog> createState() => _ProfilDialogState();
}

class _ProfilDialogState extends State<_ProfilDialog> {
  late final TextEditingController _idController;

  @override
  void initState() {
    super.initState();
    _idController = TextEditingController(text: context.read<AppSettings>().playerId);
  }

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  void _fermer() {
    context.read<AppSettings>().setPlayerId(_idController.text);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final colors = AppColors(settings.isLightTheme, colorblind: settings.colorblindMode);
    final t = AppLocalizations.of(context);

    return Dialog(
      backgroundColor: colors.bgPanel2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.homeChooseAvatar, textAlign: TextAlign.center, style: AppTextStyles.display(size: 20)),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                // Avatars de l'event Halloween : en tête une fois gagnés.
                for (final a in kEventAvatars)
                  if (settings.isAvatarUnlocked(a))
                    InkWell(
                      key: ValueKey('avatar:$a'),
                      onTap: () => context.read<AppSettings>().setAvatar(a),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: a == settings.avatar ? AppColors.goldBright : Colors.transparent, width: 2),
                        ),
                        child: AvatarView(avatar: a, radius: 18, background: colors.bgPanel),
                      ),
                    ),
                ...kAvatarEmojis.map((a) {
                  final selected = a == settings.avatar;
                  return InkWell(
                    onTap: () => context.read<AppSettings>().setAvatar(a),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: colors.bgPanel,
                      child: CircleAvatar(
                        radius: selected ? 18 : 19,
                        backgroundColor: selected ? AppColors.gold.withOpacity(0.25) : Colors.transparent,
                        child: Text(a, style: const TextStyle(fontSize: 16)),
                      ),
                    ),
                  );
                }),
              ],
            ),
            if (kEventAvatars.any((a) => !settings.isAvatarUnlocked(a))) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final a in kEventAvatars)
                    if (!settings.isAvatarUnlocked(a))
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Opacity(opacity: 0.35, child: AvatarView(avatar: a, radius: 16, background: colors.bgPanel)),
                            Icon(Icons.lock, size: 14, color: colors.cream),
                          ],
                        ),
                      ),
                  const SizedBox(width: 6),
                  Text(t.avatarEventLocked, style: AppTextStyles.body(size: 11, color: colors.muted)),
                ],
              ),
            ],
            const SizedBox(height: 20),
            Text(t.homeYourId, textAlign: TextAlign.center, style: AppTextStyles.display(size: 20)),
            const SizedBox(height: 10),
            TextField(
              controller: _idController,
              maxLength: kPlayerIdMaxLength,
              textAlign: TextAlign.center,
              style: AppTextStyles.body(size: 14, weight: FontWeight.w700, color: colors.cream),
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: colors.bgPanel,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                hintText: t.homeYourNickname,
              ),
              onSubmitted: (_) => _fermer(),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.crimson),
              onPressed: _fermer,
              child: Text(t.commonClose, style: AppTextStyles.display(size: 15, color: colors.cream)),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final AppColors colors;
  final VoidCallback onTap;
  const _IconButton({required this.icon, required this.colors, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: colors.bgPanel,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.gold.withOpacity(0.3)),
        ),
        child: Icon(icon, color: AppColors.goldBright, size: 18),
      ),
    );
  }
}

/// Entrée de l'event Halloween (visible tant qu'il dure), avec le nombre de
/// films jouables pas encore trouvés.
class _HalloweenEventButton extends StatelessWidget {
  const _HalloweenEventButton();

  @override
  Widget build(BuildContext context) {
    final event = context.watch<GameState>().halloween;
    final t = AppLocalizations.of(context);
    final toPlay = List.generate(event.availableCount, (i) => event.progressOf(i).solved).where((s) => !s).length;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        key: const ValueKey('homeHalloweenEvent'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3A1F52),
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFFF28C28), width: 1.5),
          ),
        ),
        onPressed: () => ClapperTransition.play(context, () {
          if (context.mounted) {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HalloweenEventScreen()));
          }
        }),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(t.homeHalloweenEvent, style: AppTextStyles.display(size: 18, color: const Color(0xFFFFB347))),
            if (toPlay > 0) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFF28C28), borderRadius: BorderRadius.circular(10)),
                child: Text('$toPlay',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1B1326))),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Bouton de la bobine du jour : une mini-bobine, avec une pastille qui
/// pulse tant que le tour gratuit du jour n'a pas été pris. Se met à jour à
/// minuit (heure du téléphone) et au retour dans l'app.
class _WheelButton extends StatefulWidget {
  final AppColors colors;
  const _WheelButton({required this.colors});

  @override
  State<_WheelButton> createState() => _WheelButtonState();
}

class _WheelButtonState extends State<_WheelButton> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
  Timer? _midnight;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleMidnight();
  }

  void _scheduleMidnight() {
    final now = DateTime.now();
    final next = DateTime(now.year, now.month, now.day + 1);
    _midnight?.cancel();
    _midnight = Timer(next.difference(now) + const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {});
      _scheduleMidnight();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      setState(() {});
      _scheduleMidnight();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _midnight?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    final colors = widget.colors;
    final available = game.wheelFreeSpinAvailable;
    return Semantics(
      button: true,
      label: AppLocalizations.of(context).wheelHomeLabel,
      child: InkWell(
        key: const ValueKey('homeWheelButton'),
        onTap: () => showDialog(context: context, barrierDismissible: false, builder: (_) => const DailyWheelDialog()),
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 38,
              height: 38,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: colors.bgPanel,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.gold.withOpacity(available ? 0.9 : 0.3)),
              ),
              child: const CustomPaint(painter: ReelPainter(showPointer: false)),
            ),
            if (available)
              Positioned(
                top: -5,
                right: -5,
                child: ScaleTransition(
                  scale: Tween(begin: 0.85, end: 1.15).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
                  child: Container(
                    key: const ValueKey('homeWheelBadge'),
                    width: 16,
                    height: 16,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.crimsonBright,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.bgDeep, width: 1.5),
                    ),
                    child: const Text('1',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white, height: 1)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final AppColors colors;
  final VoidCallback onTap;
  const _SecondaryButton({required this.label, required this.colors, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
        child: Text(label, style: AppTextStyles.body(size: 12, weight: FontWeight.w700, color: AppColors.goldBright)),
      ),
    );
  }
}
