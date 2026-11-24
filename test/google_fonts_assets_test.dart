import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Les polices Google sont embarquées dans assets/google_fonts/ et le
/// téléchargement au lancement est coupé (main.dart). Ce test garantit que
/// chaque variante demandée par l'appli existe bien dans les assets : sinon
/// google_fonts lève une exception et le texte tombe en police de secours
/// (en 1.0.15, c'était une erreur réseau hors ligne, 17 fois chez 7 joueurs).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const poids = [FontWeight.w400, FontWeight.w500, FontWeight.w600, FontWeight.w700, FontWeight.w800];

  test('les 16 fichiers de police attendus sont dans le manifeste des assets', () async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assets = manifest.listAssets().where((a) => a.startsWith('assets/google_fonts/')).toSet();
    final attendus = <String>{
      'assets/google_fonts/BebasNeue-Regular.ttf',
      for (final p in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) ...[
        'assets/google_fonts/LibreFranklin-$p.ttf',
        'assets/google_fonts/Lexend-$p.ttf',
      ],
      for (final p in ['Italic', 'MediumItalic', 'SemiBoldItalic', 'BoldItalic', 'ExtraBoldItalic'])
        'assets/google_fonts/LibreFranklin-$p.ttf',
      for (final f in ['BebasNeue', 'LibreFranklin', 'Lexend']) 'assets/google_fonts/OFL-$f.txt',
    };
    expect(assets, containsAll(attendus));
  });

  testWidgets('toutes les variantes utilisées par le thème se chargent sans réseau', (tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    final base = ThemeData.dark().textTheme;
    final styles = <TextStyle>[
      GoogleFonts.bebasNeue(),
      for (final w in poids) ...[
        GoogleFonts.libreFranklin(fontWeight: w),
        GoogleFonts.libreFranklin(fontWeight: w, fontStyle: FontStyle.italic),
        GoogleFonts.lexend(fontWeight: w),
      ],
    ];
    // Les thèmes complets demandent aussi les graisses du thème Material par défaut.
    GoogleFonts.libreFranklinTextTheme(base);
    GoogleFonts.lexendTextTheme(base);
    // pendingFonts() échoue si une variante manque dans les assets.
    await tester.runAsync(() => GoogleFonts.pendingFonts());
    expect(styles, hasLength(16));
  });
}
