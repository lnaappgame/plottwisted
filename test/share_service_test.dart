import 'package:flutter_test/flutter_test.dart';

import 'package:cine_devinette/data/puzzles_data.dart';
import 'package:cine_devinette/l10n/app_localizations_en.dart';
import 'package:cine_devinette/l10n/app_localizations_fr.dart';
import 'package:cine_devinette/models/puzzle.dart';
import 'package:cine_devinette/services/share_service.dart';

void main() {
  test('titre masqué : lettres et chiffres cachés, ponctuation visible', () {
    expect(ShareService.titleMask('IRON MAN'), '_ _ _ _   _ _ _');
    expect(ShareService.titleMask('P.S. : I LOVE YOU'), '_ . _ .   :   _   _ _ _ _   _ _ _');
    expect(ShareService.titleMask('300'), '_ _ _');
  });

  test('pitch avec pastilles de couleur après chaque nom', () {
    final p = ShareService.pitchWithColors('{p1}, milliardaire, va se faire piéger par {p2}.', 'Sherlock Holmes',
        NameColor.red, p2: 'Jeff Bridges', c2: NameColor.blue);
    expect(p, 'Sherlock Holmes 🔴, milliardaire, va se faire piéger par Jeff Bridges 🔵.');
  });

  test('durées lisibles', () {
    expect(ShareService.formatDuration(42), '42 s');
    expect(ShareService.formatDuration(65), '1:05');
    expect(ShareService.formatDuration(3750), '1:02:30');
  });

  test('chaque partage porte le lien intelligent et sa source', () {
    final fr = AppLocalizationsFr(), en = AppLocalizationsEn();
    final link = ShareService.link(ShareService.sourceLevel);
    expect(link, 'https://lnaappgame.github.io/plottwisted/go/?s=p-niveau');
    expect(fr.shareLevelText(3, 4, '42 s', link), contains(link));
    expect(en.shareLevelText(3, 4, '42 s', link), contains('World 3, level 4'));
    // La source reste dans ce que la page du lien accepte : [a-z0-9_-], 20 caractères au plus.
    for (final s in [ShareService.sourceLevel, ShareService.sourceDefi, ShareService.sourceEnigme,
        ShareService.sourceDuel, ShareService.sourceAskFriend, ShareService.sourceAskFriendEnigme,
        ShareService.sourceInvite]) {
      expect(RegExp(r'^[a-z0-9_-]{1,20}$').hasMatch(s), isTrue, reason: s);
    }
  });

  test('« Demander à un ami » ne révèle jamais le titre', () {
    final fr = AppLocalizationsFr();
    for (final world in kWorlds.take(6)) {
      for (final puzzle in world.puzzles) {
        final pitch = ShareService.pitchWithColors(puzzle.pitchTemplateFor('fr'), puzzle.p1.displayFor(puzzle.p1InitialColor),
            puzzle.p1InitialColor,
            p2: puzzle.hasP2 ? puzzle.p2.displayFor(puzzle.p2InitialColor) : null,
            c2: puzzle.hasP2 ? puzzle.p2InitialColor : null);
        final text = fr.shareAskFriendText(pitch, ShareService.titleMask(puzzle.titleFor('fr')), 'L');
        expect(text.contains('{p1}') || text.contains('{p2}'), isFalse, reason: puzzle.title);
        // Le titre complet n'apparaît nulle part (seule sa grille masquée).
        expect(text.toUpperCase().contains('\n${puzzle.title}\n'), isFalse, reason: puzzle.title);
      }
    }
  });

  test('énigme : trous visibles et indiscernables des vraies espaces', () {
    // « UN F LM » : la lettre cachée et l'espace s'affichent pareil.
    final shared = ShareService.revealedTextForShare('UN F LM');
    expect(shared, 'UN\u2002F\u2002LM');
    expect(shared.contains(' '), isFalse);
    final fr = AppLocalizationsFr();
    final text = fr.shareAskFriendEnigmeText('Film', shared, ShareService.titleMask('TITANIC'), 'L');
    expect(text, contains('🧩 Film'));
    expect(text, contains('_ _ _ _ _ _ _'));
    expect(text.contains('TITANIC'), isFalse);
  });
}
