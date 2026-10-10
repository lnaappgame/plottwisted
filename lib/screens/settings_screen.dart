import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../services/app_settings.dart';
import '../services/cloud_sync_service.dart';
import '../services/defi_state.dart';
import '../services/enigme_state.dart';
import '../services/game_state.dart';
import '../services/multiplayer_state.dart';
import '../services/save_service.dart';
import '../services/streak_state.dart';
import '../theme/app_theme.dart';

// Page légale hébergée sur GitHub Pages (brouillon non relu par un juriste,
// à faire valider avant publication réelle sur les stores — source dans
// docs/index.html, contenu dans legal/cgu.md et
// legal/politique-de-confidentialite.md). Une seule page avec les deux
// documents sous onglets ; les ancres #cgu/#conf ouvrent directement le bon
// onglet. Hébergée ici (plutôt que sur claude.ai) car les robots de
// vérification de Google Play/AdMob recevaient un 403 sur les artifacts.
const String _kCguUrl = 'https://lnaappgame.github.io/plottwisted/#cgu';
const String _kPrivacyPolicyUrl = 'https://lnaappgame.github.io/plottwisted/#conf';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _syncing = false;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final colors = AppColors(settings.isLightTheme, colorblind: settings.colorblindMode);
    final cloudSync = context.read<CloudSyncService>();
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
            Text(t.settingsTitle, textAlign: TextAlign.center, style: AppTextStyles.display(size: 24)),
            const SizedBox(height: 12),
            _SettingsRow(
              label: t.settingsLightMode, colors: colors,
              value: settings.isLightTheme,
              onChanged: (_) => context.read<AppSettings>().toggleTheme(),
            ),
            _SettingsRow(
              label: t.settingsSfx, colors: colors,
              value: settings.sfxOn,
              onChanged: (_) => context.read<AppSettings>().toggleSfx(),
            ),
            _SettingsRow(
              label: t.settingsVibrations, colors: colors,
              value: settings.vibrationsOn,
              onChanged: (_) => context.read<AppSettings>().toggleVibrations(),
            ),
            _SettingsRow(
              label: t.settingsColorblind, colors: colors,
              value: settings.colorblindMode,
              onChanged: (_) => context.read<AppSettings>().toggleColorblindMode(),
            ),
            _SettingsRow(
              label: t.settingsDyslexic, colors: colors,
              value: settings.dyslexicMode,
              onChanged: (_) => context.read<AppSettings>().toggleDyslexicMode(),
            ),
            _SizeSettingsRow(
              label: t.settingsTextSize, colors: colors,
              isLarge: settings.largeText,
              smallLabel: t.settingsTextSizeSmall,
              largeLabel: t.settingsTextSizeLarge,
              onChanged: (large) => context.read<AppSettings>().setLargeText(large),
            ),
            _LanguageRow(colors: colors, settings: settings, t: t),
            _InputModeRow(colors: colors, settings: settings, t: t),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => _onShowPrivacyOptions(context),
              child: Text(t.settingsAdPrivacy,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body(size: 12, weight: FontWeight.w700, color: AppColors.gold)),
            ),
            const SizedBox(height: 6),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              children: [
                _LegalLink(
                  label: t.settingsCgu, colors: colors,
                  onTap: () => launchUrl(Uri.parse(_kCguUrl), mode: LaunchMode.externalApplication),
                ),
                Text('·', style: AppTextStyles.body(size: 11, color: colors.muted)),
                _LegalLink(
                  label: t.settingsPrivacyPolicy, colors: colors,
                  onTap: () => launchUrl(Uri.parse(_kPrivacyPolicyUrl), mode: LaunchMode.externalApplication),
                ),
              ],
            ),
            if (cloudBackupAvailable) ...[
              const SizedBox(height: 12),
              _buildAccountSection(context, colors, cloudSync, t),
            ],
            const SizedBox(height: 18),
            OutlinedButton(
              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.crimsonBright)),
              onPressed: () => _confirmReset(context),
              child: Text(t.settingsResetSave,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body(size: 12, weight: FontWeight.w700, color: AppColors.crimsonBright)),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.crimson),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(t.settingsClose, style: AppTextStyles.display(size: 15, color: colors.cream)),
            ),
          ],
        ),
        ),
        ),
      ),
    );
  }

  /// Bloc "compte" : permet de lier un compte Google à la progression
  /// anonyme actuelle (pour la retrouver sur un autre appareil), ou de
  /// déclencher une sauvegarde manuelle si déjà lié.
  Widget _buildAccountSection(BuildContext context, AppColors colors, CloudSyncService cloudSync, AppLocalizations t) {
    final linked = cloudSync.isLinked;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          linked
              ? t.settingsAccountLinked(cloudSync.linkedEmail ?? 'Google')
              : t.settingsAccountLocalOnly,
          textAlign: TextAlign.center,
          style: AppTextStyles.body(size: 12, color: colors.muted),
        ),
        const SizedBox(height: 8),
        if (_syncing)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))),
          )
        else if (!linked)
          OutlinedButton(
            onPressed: () => _onConnectGoogle(context),
            child: Text(t.settingsSaveWithGoogle,
                textAlign: TextAlign.center,
                style: AppTextStyles.body(size: 12, weight: FontWeight.w700, color: AppColors.gold)),
          )
        else
          OutlinedButton(
            onPressed: () => _onManualBackup(context),
            child: Text(t.settingsSaveNow,
                textAlign: TextAlign.center,
                style: AppTextStyles.body(size: 12, weight: FontWeight.w700, color: AppColors.gold)),
          ),
      ],
    );
  }

  /// Ouvre le sélecteur de compte Google et lie (ou restaure) la
  /// progression selon le résultat. Ne bloque jamais durablement le joueur :
  /// toute erreur réseau laisse l'app en mode local-only, comme avant.
  Future<void> _onConnectGoogle(BuildContext context) async {
    final cloudSync = context.read<CloudSyncService>();
    final saveService = context.read<SaveService>();
    final t = AppLocalizations.of(context);
    setState(() => _syncing = true);

    final result = await cloudSync.connectGoogleAccount();
    if (!context.mounted) return;

    switch (result) {
      case AccountLinkResult.linkedNew:
        final data = await saveService.readAllForBackup();
        await cloudSync.backup(data);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.settingsGoogleLinkedSnack), duration: const Duration(seconds: 3)),
        );
        break;
      case AccountLinkResult.restoredExisting:
        final backup = await cloudSync.restore();
        if (!context.mounted) return;
        if (backup != null) {
          await saveService.writeAllFromBackup(backup);
          if (!context.mounted) return;
          // Tout l'état en mémoire reprend les données restaurées tout de
          // suite : la sauvegarde automatique (fermeture de l'app, puis
          // sauvegarde cloud) ne peut plus réécrire l'ancien état par-dessus.
          await context.read<AppSettings>().reloadFromSave();
          if (!context.mounted) return;
          await Future.wait([
            context.read<GameState>().reloadFromSave(),
            context.read<EnigmeState>().reloadFromSave(),
            context.read<DefiState>().reloadFromSave(),
            context.read<MultiplayerState>().reloadFromSave(),
            context.read<StreakState>().reloadFromSave(),
          ]);
          if (!context.mounted) return;
          await _showRestoreDialog(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t.settingsGoogleLinkedNoBackupSnack), duration: const Duration(seconds: 3)),
          );
        }
        break;
      case AccountLinkResult.cancelled:
        break;
      case AccountLinkResult.error:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.settingsGoogleErrorSnack), duration: const Duration(seconds: 3)),
        );
        break;
    }
    if (mounted) setState(() => _syncing = false);
  }

  /// Sauvegarde manuelle à la demande, pour un compte déjà lié.
  Future<void> _onManualBackup(BuildContext context) async {
    final cloudSync = context.read<CloudSyncService>();
    final saveService = context.read<SaveService>();
    final t = AppLocalizations.of(context);
    setState(() => _syncing = true);

    final data = await saveService.readAllForBackup();
    final ok = await cloudSync.backup(data);
    if (!context.mounted) return;
    setState(() => _syncing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? t.settingsBackupUpToDateSnack : t.settingsBackupFailedSnack),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Prévient le joueur qu'une sauvegarde cloud vient d'être rapatriée en
  /// local et qu'un redémarrage complet de l'app est nécessaire pour la
  /// voir apparaître (choix délibéré : plus sûr qu'un rechargement à chaud
  /// des 6 états en mémoire).
  Future<void> _showRestoreDialog(BuildContext context) async {
    final settings = context.read<AppSettings>();
    final colors = AppColors(settings.isLightTheme, colorblind: settings.colorblindMode);
    final t = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: colors.bgPanel2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(t.settingsRestoreTitle, textAlign: TextAlign.center, style: AppTextStyles.display(size: 18, color: AppColors.gold)),
              const SizedBox(height: 12),
              Text(
                t.settingsRestoreBody,
                textAlign: TextAlign.center,
                style: AppTextStyles.body(size: 13, color: colors.cream).copyWith(height: 1.5),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.crimson),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(t.settingsUnderstood, style: AppTextStyles.display(size: 15, color: colors.cream)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Ouvre le formulaire RGPD de gestion des options de confidentialité des
  /// pubs (exigence Google UMP) — ou informe le joueur que ce n'est pas
  /// requis pour sa région si c'est le cas.
  Future<void> _onShowPrivacyOptions(BuildContext context) async {
    final adService = context.read<GameState>().adService;
    final required = await adService.privacyOptionsRequired;
    if (!context.mounted) return;
    if (!required) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).settingsNoPrivacyNeeded), duration: const Duration(seconds: 2)),
      );
      return;
    }
    await adService.showPrivacyOptionsForm();
  }

  /// Double confirmation avant d'effacer la progression : une action
  /// destructive et irréversible ne doit jamais dépendre d'un seul tap.
  Future<void> _confirmReset(BuildContext context) async {
    final settings = context.read<AppSettings>();
    final colors = AppColors(settings.isLightTheme, colorblind: settings.colorblindMode);
    final t = AppLocalizations.of(context);

    Future<bool> ask(String title, String body, String confirmLabel) async {
      final result = await showDialog<bool>(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: colors.bgPanel2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, textAlign: TextAlign.center, style: AppTextStyles.display(size: 18, color: AppColors.crimsonBright)),
                const SizedBox(height: 12),
                Text(body, textAlign: TextAlign.center, style: AppTextStyles.body(size: 13, color: colors.cream).copyWith(height: 1.5)),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(t.settingsCancel, style: AppTextStyles.body(size: 13, weight: FontWeight.w700, color: colors.muted)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.crimson),
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text(confirmLabel, style: AppTextStyles.body(size: 13, weight: FontWeight.w700, color: colors.cream)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      return result ?? false;
    }

    if (!context.mounted) return;
    final first = await ask(
      t.settingsResetConfirm1Title,
      t.settingsResetConfirm1Body,
      t.settingsResetConfirm1Cta,
    );
    if (!first || !context.mounted) return;

    final second = await ask(
      t.settingsResetConfirm2Title,
      t.settingsResetConfirm2Body,
      t.settingsResetConfirm2Cta,
    );
    if (!second || !context.mounted) return;

    await context.read<GameState>().resetProgress();
    if (context.mounted) Navigator.of(context).pop();
  }
}

class _LanguageRow extends StatelessWidget {
  final AppColors colors;
  final AppSettings settings;
  final AppLocalizations t;
  const _LanguageRow({required this.colors, required this.settings, required this.t});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: Text(t.settingsLanguage, style: AppTextStyles.body(size: 13, color: colors.cream))),
          const SizedBox(width: 8),
          _SizeChip(
            label: t.settingsLanguageFrench,
            selected: settings.locale == 'fr',
            colors: colors,
            onTap: () => context.read<AppSettings>().setLocale('fr'),
          ),
          const SizedBox(width: 6),
          _SizeChip(
            label: t.settingsLanguageEnglish,
            selected: settings.locale == 'en',
            colors: colors,
            onTap: () => context.read<AppSettings>().setLocale('en'),
          ),
        ],
      ),
    );
  }
}

/// Tuiles mélangées ou clavier AZERTY/QWERTY pour placer les lettres (jeu
/// principal, énigme de la semaine, multijoueur).
class _InputModeRow extends StatelessWidget {
  final AppColors colors;
  final AppSettings settings;
  final AppLocalizations t;
  const _InputModeRow({required this.colors, required this.settings, required this.t});

  @override
  Widget build(BuildContext context) {
    final modes = [
      ('tiles', t.settingsInputTiles),
      ('azerty', t.settingsInputAzerty),
      ('qwerty', t.settingsInputQwerty),
    ];
    // Titre au-dessus, trois choix en dessous : sur une seule ligne, les
    // trois boutons débordaient sur les écrans étroits.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.settingsInputMode, style: AppTextStyles.body(size: 13, color: colors.cream)),
          const SizedBox(height: 6),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final (mode, label) in modes)
                _SizeChip(
                  label: label,
                  selected: settings.inputMode == mode,
                  colors: colors,
                  onTap: () => context.read<AppSettings>().setInputMode(mode),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SizeSettingsRow extends StatelessWidget {
  final String label;
  final bool isLarge;
  final String smallLabel;
  final String largeLabel;
  final AppColors colors;
  final ValueChanged<bool> onChanged;
  const _SizeSettingsRow({
    required this.label, required this.isLarge, required this.smallLabel,
    required this.largeLabel, required this.colors, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: Text(label, style: AppTextStyles.body(size: 13, color: colors.cream))),
          const SizedBox(width: 8),
          _SizeChip(label: smallLabel, selected: !isLarge, colors: colors, onTap: () => onChanged(false)),
          const SizedBox(width: 6),
          _SizeChip(label: largeLabel, selected: isLarge, colors: colors, onTap: () => onChanged(true)),
        ],
      ),
    );
  }
}

class _SizeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final AppColors colors;
  final VoidCallback onTap;
  const _SizeChip({required this.label, required this.selected, required this.colors, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.crimson : colors.bgPanel,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? AppColors.crimson : AppColors.gold.withOpacity(0.3)),
        ),
        child: Text(label, style: AppTextStyles.body(size: 11, weight: FontWeight.w700, color: selected ? colors.cream : colors.muted)),
      ),
    );
  }
}

/// Lien texte compact (CGU / politique de confidentialité) — un TextButton
/// standard déborde sur les petits écrans à cause de son padding intégré
/// généreux (~16px de chaque côté) ; celui-ci le réduit au minimum tout en
/// gardant une zone tactile correcte.
class _LegalLink extends StatelessWidget {
  final String label;
  final AppColors colors;
  final VoidCallback onTap;
  const _LegalLink({required this.label, required this.colors, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, style: AppTextStyles.body(size: 11, color: colors.muted)),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final String label;
  final bool value;
  final AppColors colors;
  final ValueChanged<bool> onChanged;
  const _SettingsRow({required this.label, required this.value, required this.colors, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: AppTextStyles.body(size: 13, color: colors.cream))),
          Switch(value: value, onChanged: onChanged, activeColor: AppColors.crimson),
        ],
      ),
    );
  }
}
