import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../services/app_settings.dart';
import '../theme/app_theme.dart';
import '../widgets/clapper_transition.dart';
import '../widgets/scifi_background.dart';
import 'defi_screen.dart';
import 'enigme_screen.dart';
import 'multiplayer_screen.dart';
import 'settings_screen.dart';
import 'shop_screen.dart';
import 'instructions_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onPlay;
  const HomeScreen({super.key, required this.onPlay});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: AppColors.gold,
                                        child: Text(settings.avatar, style: const TextStyle(fontSize: 15)),
                                      ),
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
                              _IconButton(
                                icon: Icons.settings,
                                colors: colors,
                                onTap: () => showDialog(context: context, builder: (_) => const SettingsScreen()),
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
              children: kAvatarEmojis.map((a) {
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
              }).toList(),
            ),
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
