import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../services/app_settings.dart';
import '../theme/app_theme.dart';

/// Conseil « tuiles ou clavier », avec le choix du mode directement dans le
/// pop-up. Il reste affiché au moins [minOpen] avant de pouvoir être fermé :
/// il s'ouvre à la première tuile touchée, et les joueurs le refermaient
/// sans l'avoir lu en continuant de taper (boutons inactifs et retour
/// arrière bloqué pendant ce délai, une barre montre le temps restant).
class InputModeTipDialog extends StatefulWidget {
  static const minOpen = Duration(seconds: 3);
  const InputModeTipDialog({super.key});

  @override
  State<InputModeTipDialog> createState() => _InputModeTipDialogState();
}

class _InputModeTipDialogState extends State<InputModeTipDialog> with SingleTickerProviderStateMixin {
  late final AnimationController _wait = AnimationController(vsync: this, duration: InputModeTipDialog.minOpen)
    ..addStatusListener((_) => setState(() {}))
    ..forward();

  bool get _ready => _wait.isCompleted;

  @override
  void dispose() {
    _wait.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final colors = AppColors(settings.isLightTheme, colorblind: settings.colorblindMode);
    final t = AppLocalizations.of(context);
    final modes = [('tiles', t.settingsInputTiles), ('azerty', t.settingsInputAzerty), ('qwerty', t.settingsInputQwerty)];
    return PopScope(
      canPop: _ready,
      child: Dialog(
        backgroundColor: colors.bgPanel2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.gold.withOpacity(0.6)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(t.tipInputTitle,
                  textAlign: TextAlign.center, style: AppTextStyles.display(size: 20, color: AppColors.goldBright)),
              const SizedBox(height: 12),
              Text(t.tipInputBody,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body(size: 14, color: colors.cream).copyWith(height: 1.5)),
              const SizedBox(height: 14),
              AnimatedBuilder(
                animation: _wait,
                builder: (context, _) => AnimatedOpacity(
                  duration: const Duration(milliseconds: 250),
                  opacity: _ready ? 0 : 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: _wait.value,
                      minHeight: 3,
                      backgroundColor: AppColors.gold.withOpacity(0.15),
                      valueColor: const AlwaysStoppedAnimation(AppColors.gold),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              for (final (mode, label) in modes) ...[
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 250),
                  opacity: _ready ? 1 : 0.45,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: settings.inputMode == mode ? AppColors.gold.withOpacity(0.18) : null,
                      side: BorderSide(color: AppColors.gold.withOpacity(settings.inputMode == mode ? 1 : 0.4)),
                    ),
                    onPressed: _ready
                        ? () {
                            settings.setInputMode(mode);
                            Navigator.of(context).pop();
                          }
                        : null,
                    child: Text(label,
                        style: AppTextStyles.body(size: 14, weight: FontWeight.w700, color: AppColors.goldBright)),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
