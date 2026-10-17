import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// Lien discret « Demander à un ami », aligné à droite sous un pitch : écrit
/// en toutes lettres, il invite bien plus à s'en servir qu'une icône seule,
/// sans alourdir l'écran comme un vrai bouton.
class AskFriendLink extends StatelessWidget {
  /// Reçoit le contexte du lien lui-même, pour ancrer la feuille de partage
  /// (iPad) sur lui.
  final void Function(BuildContext linkContext) onTap;

  const AskFriendLink({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Builder(
        builder: (linkContext) => TextButton.icon(
          onPressed: () => onTap(linkContext),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.gold,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: const Size(0, 34),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          icon: const Icon(Icons.share, size: 15),
          label: Text(AppLocalizations.of(context).shareAskFriend,
              style: AppTextStyles.body(size: 13, weight: FontWeight.w700, color: AppColors.gold)),
        ),
      ),
    );
  }
}
