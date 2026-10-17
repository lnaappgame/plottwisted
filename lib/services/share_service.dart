import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

import '../models/puzzle.dart';

/// Partage natif (la feuille de partage du téléphone : WhatsApp, Messages,
/// Instagram…) : résultat sans spoiler sur les écrans de fin, « Demander à
/// un ami » dans un niveau, invitation depuis les Paramètres.
///
/// Chaque texte se termine par le lien intelligent des stores
/// (docs/go/index.html) : il envoie un iPhone vers l'App Store et un
/// Android vers Google Play, et la source `?s=` indique à Google Play d'où
/// vient l'installation.
class ShareService {
  ShareService._();

  static const _base = 'https://lnaappgame.github.io/plottwisted/go/';

  /// Sources, une par emplacement de partage (20 caractères au plus).
  static const sourceLevel = 'p-niveau';
  static const sourceDefi = 'p-defi';
  static const sourceEnigme = 'p-enigme';
  static const sourceDuel = 'p-duel';
  static const sourceAskFriend = 'p-aide';
  static const sourceInvite = 'p-invit';

  static String link(String source) => '$_base?s=$source';

  /// Ouvre la feuille de partage. [context] sert à placer la fenêtre sur
  /// iPad (ignoré ailleurs) ; un partage annulé n'est pas une erreur.
  static Future<void> share(BuildContext context, String text) async {
    final box = context.findRenderObject();
    final origin = box is RenderBox && box.hasSize ? box.localToGlobal(Offset.zero) & box.size : null;
    try {
      await SharePlus.instance.share(ShareParams(text: text, sharePositionOrigin: origin));
    } catch (_) {
      // Pas de feuille de partage disponible (ex. tests) : rien à faire.
    }
  }

  /// Durée lisible : « 42 s », « 1:05 », « 1:02:30 ».
  static String formatDuration(int seconds) {
    if (seconds < 60) return '$seconds s';
    final h = seconds ~/ 3600, m = (seconds % 3600) ~/ 60, s = seconds % 60;
    final ss = s.toString().padLeft(2, '0');
    return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$ss' : '$m:$ss';
  }

  static String colorEmoji(NameColor c) => switch (c) {
        NameColor.green => '🟢',
        NameColor.blue => '🔵',
        NameColor.red => '🔴',
        NameColor.orange => '🟠',
        NameColor.violet => '🟣',
      };

  /// Le pitch tel que le joueur le voit, chaque nom suivi de sa pastille de
  /// couleur : « Sherlock Holmes 🔴, milliardaire de l'armement… ».
  static String pitchWithColors(String template, String p1, NameColor c1, {String? p2, NameColor? c2}) {
    var out = template.replaceAll('{p1}', '$p1 ${colorEmoji(c1)}');
    if (p2 != null && c2 != null) out = out.replaceAll('{p2}', '$p2 ${colorEmoji(c2)}');
    return out;
  }

  /// Le titre masqué : « _ _ _ _   _ _ _ » pour IRON MAN ; la ponctuation
  /// reste visible, comme dans la grille du jeu.
  static String titleMask(String title) {
    final words = title.trim().split(RegExp(r'\s+'));
    return words
        .map((w) => w.split('').map((ch) => RegExp(r'[\p{L}\p{N}]', unicode: true).hasMatch(ch) ? '_' : ch).join(' '))
        .join('   ');
  }
}
