import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

import '../models/joker.dart';
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
  static const sourceAskFriendEnigme = 'p-aide-enigme';
  static const sourceInvite = 'p-invit';
  static const sourceEvent = 'p-halloween';

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

  // ─── Résultats façon Wordle : une grille d'émojis sans spoiler, que les
  // amis peuvent comparer (mêmes niveaux, même énigme de la semaine). ───

  /// Une ligne par validation, un carré par mot du titre (🟩 juste, 🟥 faux).
  /// Au-delà de [maxRows] validations, seules les dernières sont gardées,
  /// précédées de « … ». Chaque ligne finit par un retour à la ligne ; vide
  /// si aucune validation n'est connue (niveau rouvert après un redémarrage).
  static String attemptGrid(List<List<bool>> rows, {int maxRows = 6}) {
    if (rows.isEmpty) return '';
    final shown = rows.length > maxRows ? rows.sublist(rows.length - maxRows) : rows;
    return [
      if (rows.length > maxRows) '…',
      for (final row in shown) row.map((ok) => ok ? '🟩' : '🟥').join(),
    ].map((line) => '$line\n').join();
  }

  /// Les jokers joués, en icônes (💡✂️📖…).
  static String jokerIcons(List<JokerKind> kinds) => kinds.map((k) => k.icon).join();

  /// La fin du résultat d'un niveau : le temps, puis les jokers joués,
  /// [noJoker] s'il n'y en a aucun, ou [skipped] si le niveau a été passé.
  static String resultDetails(String time, List<JokerKind> jokers,
          {required bool skipped, required String noJoker, required String skippedLabel}) =>
      '⏱️ $time · ${skipped ? skippedLabel : jokers.isEmpty ? noJoker : '🃏 ${jokerIcons(jokers)}'}';

  /// Une case par indice du Défi du jour (🟩 trouvé du premier coup, 🟥
  /// sinon), suivie d'un retour à la ligne ; vide si rien n'est connu.
  static String defiGrid(List<bool> results) =>
      results.isEmpty ? '' : '${results.map((ok) => ok ? '🟩' : '🟥').join()}\n';

  /// Les 7 jours de l'Énigme de la semaine : ⬛ les jours d'attente, 🟩 le
  /// jour de la résolution, ⬜ les jours restants.
  static String weekBar(int solvedDay) =>
      [for (var d = 1; d <= 7; d++) d < solvedDay ? '⬛' : (d == solvedDay ? '🟩' : '⬜')].join();

  /// Numéro de l'Énigme de la semaine, le même pour tous les joueurs : 1 pour
  /// la semaine de sortie du jeu (lundi 19/10/2026, UTC).
  static int enigmeWeekNumber(DateTime weekStart) =>
      max(1, weekStart.toUtc().difference(DateTime.utc(2026, 10, 19)).inDays ~/ 7 + 1);

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

  /// Le texte de l'énigme tel qu'il est affiché (lettres cachées = espaces),
  /// avec chaque espace remplacé par une espace cadratin : les messageries
  /// ne la fusionnent pas, donc les trous restent visibles, et vraies
  /// espaces et lettres cachées restent indiscernables, comme à l'écran.
  static String revealedTextForShare(String texteRevele) => texteRevele.replaceAll(' ', ' ');
}
