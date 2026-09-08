import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/puzzle.dart';

class AppColors {
  final bool isLight;
  final bool colorblind;
  const AppColors(this.isLight, {this.colorblind = false});

  Color get bgDeep => isLight ? const Color(0xFFF2EDE1) : const Color(0xFF0C0906);
  Color get bgPanel => isLight ? const Color(0xFFFFFFFF) : const Color(0xFF1A1410);
  Color get bgPanel2 => isLight ? const Color(0xFFF6F1E6) : const Color(0xFF241C16);
  Color get cream => isLight ? const Color(0xFF2B2118) : const Color(0xFFECE3D2);
  Color get muted => isLight ? const Color(0xFF7A6D5C) : const Color(0xFF9C8D78);

  static const gold = Color(0xFFC9A24B);
  static const goldBright = Color(0xFFF0CF7A);
  static const crimson = Color(0xFF7A1F2B);
  static const crimsonBright = Color(0xFFA3283A);

  static const green = Color(0xFF5C8A5C);
  static const greenBright = Color(0xFF7FB37F);
  static const red = Color(0xFFA3283A);
  static const redBright = Color(0xFFC8536A);
  static const blue = Color(0xFF4D7EA8);
  static const blueBright = Color(0xFF7AA8D1);
  static const orange = Color(0xFFB06A2E);
  static const orangeBright = Color(0xFFD99B5C);
  static const violet = Color(0xFF6B4F96);
  static const violetBright = Color(0xFFA98FD1);

  // Palette "mode daltonien" (inspirée d'Okabe-Ito, pensée pour rester
  // distinguable en deutéranopie/protanopie) — utilisée en plus, jamais à la
  // place, des repères en formes (voir symbolForNameColor) : ne jamais
  // reposer sur la seule couleur pour transmettre une information.
  static const cbGreen = Color(0xFF00806B); // vert bleuté
  static const cbGreenBright = Color(0xFF1FA98F);
  static const cbRed = Color(0xFFAD4400); // vermillon
  static const cbRedBright = Color(0xFFD55E00);
  static const cbBlue = Color(0xFF00558F); // bleu franc
  static const cbBlueBright = Color(0xFF0072B2);
  static const cbOrange = Color(0xFFB8A600); // jaune profond
  static const cbOrangeBright = Color(0xFFE8D400);
  static const cbViolet = Color(0xFFA65E85); // pourpre rosé
  static const cbVioletBright = Color(0xFFCC79A7);

  Color forNameColor(NameColor c, {bool bright = true}) {
    if (colorblind) {
      switch (c) {
        case NameColor.green: return bright ? cbGreenBright : cbGreen;
        case NameColor.blue: return bright ? cbBlueBright : cbBlue;
        case NameColor.red: return bright ? cbRedBright : cbRed;
        case NameColor.orange: return bright ? cbOrangeBright : cbOrange;
        case NameColor.violet: return bright ? cbVioletBright : cbViolet;
      }
    }
    switch (c) {
      case NameColor.green: return bright ? greenBright : green;
      case NameColor.blue: return bright ? blueBright : blue;
      case NameColor.red: return bright ? redBright : red;
      case NameColor.orange: return bright ? orangeBright : orange;
      case NameColor.violet: return bright ? violetBright : violet;
    }
  }

  /// Repère en forme (indépendant de la couleur) pour chaque couleur de nom —
  /// affiché en plus de la couleur en mode daltonien, pour ne jamais reposer
  /// sur la seule perception des couleurs.
  static String symbolForNameColor(NameColor c) {
    switch (c) {
      case NameColor.green: return '●';
      case NameColor.red: return '▲';
      case NameColor.blue: return '■';
      case NameColor.orange: return '◆';
      case NameColor.violet: return '★';
    }
  }

  Color forDifficultyLabel(String label) {
    switch (label) {
      case 'Facile': return greenBright;
      case 'Moyen': return goldBright;
      case 'Difficile': return redBright;
      case 'Extrême': return redBright;
      default: return muted; // Tutoriel
    }
  }
}

class AppTextStyles {
  /// Mis à jour à chaque reconstruction de l'app (voir main.dart) plutôt que
  /// passé en paramètre à chaque appel — évite de faire transiter le
  /// paramètre à travers des dizaines de widgets pour un simple choix de
  /// police global. Lexend est une police Google Fonts pensée pour réduire
  /// la charge de lecture (utile en cas de dyslexie).
  static bool useDyslexicFont = false;

  static TextStyle display({double size = 28, Color? color}) => useDyslexicFont
      ? GoogleFonts.lexend(fontSize: size, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: color ?? AppColors.goldBright)
      : GoogleFonts.bebasNeue(fontSize: size, letterSpacing: 2, color: color ?? AppColors.goldBright);

  // Police des tuiles/cases : Libre Franklin en gras plutôt que Bebas Neue,
  // pour éviter la confusion C/G repérée en test.
  static TextStyle tile({double size = 18, Color? color}) => useDyslexicFont
      ? GoogleFonts.lexend(fontSize: size, fontWeight: FontWeight.w700, color: color ?? AppColors.goldBright)
      : GoogleFonts.libreFranklin(fontSize: size, fontWeight: FontWeight.w800, color: color ?? AppColors.goldBright);

  static TextStyle body({double size = 14, FontWeight weight = FontWeight.w400, Color? color}) => useDyslexicFont
      ? GoogleFonts.lexend(fontSize: size, fontWeight: weight, color: color)
      : GoogleFonts.libreFranklin(fontSize: size, fontWeight: weight, color: color);
}

ThemeData buildAppTheme({required bool isLight, bool dyslexicMode = false}) {
  final colors = AppColors(isLight);
  final baseTextTheme = isLight ? ThemeData.light().textTheme : ThemeData.dark().textTheme;
  return ThemeData(
    useMaterial3: true,
    brightness: isLight ? Brightness.light : Brightness.dark,
    scaffoldBackgroundColor: colors.bgDeep,
    colorScheme: ColorScheme(
      brightness: isLight ? Brightness.light : Brightness.dark,
      primary: AppColors.crimson,
      onPrimary: colors.cream,
      secondary: AppColors.gold,
      onSecondary: colors.bgDeep,
      surface: colors.bgPanel,
      onSurface: colors.cream,
      error: AppColors.crimsonBright,
      onError: colors.cream,
    ),
    textTheme: dyslexicMode
        ? GoogleFonts.lexendTextTheme(baseTextTheme)
        : GoogleFonts.libreFranklinTextTheme(baseTextTheme),
  );
}
