import 'package:flutter/material.dart';

import '../model/card_model.dart';

/// Two colours that make up one card template's gradient.
class CardPalette {
  final Color primary;
  final Color secondary;
  const CardPalette(this.primary, this.secondary);
}

/// Card colours as a ThemeExtension, so they live inside ThemeData and
/// switch automatically with light/dark mode (AppTheme registers one
/// light and one dark instance).
///
/// Usage in a widget:
///   final cardTheme = Theme.of(context).extension<DigiCardTheme>()!;
///   decoration: BoxDecoration(gradient: cardTheme.gradientFor(card.template, isActive: card.isActive))
@immutable
class DigiCardTheme extends ThemeExtension<DigiCardTheme> {
  final Map<CardTemplate, CardPalette> palettes;
  final Color onCard; // text/icon colour drawn on top of a card
  final Color inactiveColor; // card colour when status is inactive

  const DigiCardTheme({
    required this.palettes,
    required this.onCard,
    required this.inactiveColor,
  });

  // ---- Light mode: bright, vivid cards ----
  static const light = DigiCardTheme(
    palettes: {
      CardTemplate.teal: CardPalette(Color(0xFF26A69A), Color(0xFF00695C)),
      CardTemplate.orange: CardPalette(Color(0xFFFFA726), Color(0xFFE65100)),
      CardTemplate.navy: CardPalette(Color(0xFF3949AB), Color(0xFF1A237E)),
      CardTemplate.burgundy: CardPalette(Color(0xFFAD1457), Color(0xFF6A0F37)),
    },
    onCard: Colors.white,
    inactiveColor: Color(0xFF9E9E9E),
  );

  // ---- Dark mode: deeper, richer cards that don't glare ----
  static const dark = DigiCardTheme(
    palettes: {
      CardTemplate.teal: CardPalette(Color(0xFF00897B), Color(0xFF00332D)),
      CardTemplate.orange: CardPalette(Color(0xFFEF6C00), Color(0xFF5D2400)),
      CardTemplate.navy: CardPalette(Color(0xFF283593), Color(0xFF0A0F3D)),
      CardTemplate.burgundy: CardPalette(Color(0xFF880E4F), Color(0xFF30041A)),
    },
    onCard: Color(0xFFF5F5F5),
    inactiveColor: Color(0xFF424242),
  );

  /// Gradient for a template. Inactive cards render greyed out.
  LinearGradient gradientFor(CardTemplate template, {bool isActive = true}) {
    if (!isActive) {
      return LinearGradient(
        colors: [inactiveColor, Color.lerp(inactiveColor, Colors.black, 0.35)!],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    final p = palettes[template]!;
    return LinearGradient(
      colors: [p.primary, p.secondary],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  /// Flat colour of a template, handy for the template picker swatches.
  Color swatchFor(CardTemplate template) => palettes[template]!.primary;

  @override
  DigiCardTheme copyWith({
    Map<CardTemplate, CardPalette>? palettes,
    Color? onCard,
    Color? inactiveColor,
  }) {
    return DigiCardTheme(
      palettes: palettes ?? this.palettes,
      onCard: onCard ?? this.onCard,
      inactiveColor: inactiveColor ?? this.inactiveColor,
    );
  }

  @override
  DigiCardTheme lerp(ThemeExtension<DigiCardTheme>? other, double t) {
    if (other is! DigiCardTheme) return this;
    return DigiCardTheme(
      palettes: {
        for (final template in CardTemplate.values)
          template: CardPalette(
            Color.lerp(palettes[template]!.primary, other.palettes[template]!.primary, t)!,
            Color.lerp(palettes[template]!.secondary, other.palettes[template]!.secondary, t)!,
          ),
      },
      onCard: Color.lerp(onCard, other.onCard, t)!,
      inactiveColor: Color.lerp(inactiveColor, other.inactiveColor, t)!,
    );
  }
}