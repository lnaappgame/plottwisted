import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/joker.dart';
import '../theme/app_theme.dart';

/// Couleur d'un joker : nuances de gris pour Révéler et Éliminer, la couleur
/// du nom pour les jokers de nom, doré pour l'Indice, argent pour Révéler un mot.
Color jokerColor(JokerKind kind, AppColors colors) {
  final light = colors.isLight;
  switch (kind) {
    case JokerKind.reveal:
      return light ? const Color(0xFF7D786F) : const Color(0xFFD6D0C5);
    case JokerKind.eliminate:
      return light ? const Color(0xFF55514B) : const Color(0xFF9C968C);
    case JokerKind.hint:
      return light ? AppColors.gold : AppColors.goldBright;
    case JokerKind.revealWord:
      return light ? const Color(0xFF66778A) : const Color(0xFFE2E8F0);
    case JokerKind.actor:
    case JokerKind.character:
    case JokerKind.red:
      return colors.forNameColor(kind.nameColor!, bright: !light);
  }
}

/// Texte lisible posé sur un aplat de [background].
Color onJokerColor(Color background) => background.computeLuminance() > 0.4 ? const Color(0xFF1A1410) : Colors.white;

String jokerName(JokerKind kind, AppLocalizations t) => switch (kind) {
      JokerKind.reveal => t.jokerReveal,
      JokerKind.eliminate => t.jokerEliminate,
      JokerKind.actor => t.jokerActor,
      JokerKind.character => t.jokerCharacter,
      JokerKind.hint => t.jokerHint,
      JokerKind.revealWord => t.jokerRevealWord,
      JokerKind.red => t.jokerRedCharacter,
    };
