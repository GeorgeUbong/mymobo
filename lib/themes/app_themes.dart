import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'card_themes.dart';

/// App-wide light and dark themes.
/// Each one carries the matching DigiCardTheme so cards follow the mode.
class AppTheme {
  AppTheme._();

  static const _seed = Color(0xFF001F54); // brand colour #001F54

  static ThemeData get light => _build(
        brightness: Brightness.light,
        cardTheme: DigiCardTheme.light,
      );

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        cardTheme: DigiCardTheme.dark,
      );

  static ThemeData _build({
    required Brightness brightness,
    required DigiCardTheme cardTheme,
  }) {
    final isDark = brightness == Brightness.dark;

    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
    );

    return base.copyWith(
      scaffoldBackgroundColor:
          isDark ? const Color(0xFF0F1214) : const Color(0xFFF6F8F9),
      textTheme: GoogleFonts.latoTextTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        titleTextStyle: GoogleFonts.lato(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF1A1F23) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      // Registers the card colours inside the theme.
      extensions: <ThemeExtension<dynamic>>[cardTheme],
    );
  }
}

/// Shortcut so widgets can write: context.cardTheme
extension CardThemeContext on BuildContext {
  DigiCardTheme get cardTheme => Theme.of(this).extension<DigiCardTheme>()!;
}