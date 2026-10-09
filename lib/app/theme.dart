import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ---------------------------------------------------------------------------
// SnapFoodShapes — ThemeExtension carrying shape radii
// ---------------------------------------------------------------------------

@immutable
class SnapFoodShapes extends ThemeExtension<SnapFoodShapes> {
  const SnapFoodShapes({
    this.card = 16.0,
    this.input = 12.0,
    this.chip = 8.0,
    this.actionButton = 28.0,
  });

  final double card;
  final double input;
  final double chip;
  final double actionButton;

  @override
  SnapFoodShapes copyWith({
    double? card,
    double? input,
    double? chip,
    double? actionButton,
  }) {
    return SnapFoodShapes(
      card: card ?? this.card,
      input: input ?? this.input,
      chip: chip ?? this.chip,
      actionButton: actionButton ?? this.actionButton,
    );
  }

  @override
  SnapFoodShapes lerp(SnapFoodShapes? other, double t) {
    if (other == null) return this;
    return SnapFoodShapes(
      card: lerpDouble(this.card, other.card, t)!,
      input: lerpDouble(this.input, other.input, t)!,
      chip: lerpDouble(this.chip, other.chip, t)!,
      actionButton: lerpDouble(this.actionButton, other.actionButton, t)!,
    );
  }

  static double? lerpDouble(double? a, double? b, double t) {
    if (a == null && b == null) return null;
    a ??= 0.0;
    b ??= 0.0;
    return a + (b - a) * t;
  }
}

// ---------------------------------------------------------------------------
// Light theme
// ---------------------------------------------------------------------------

ThemeData buildAppTheme() {
  const seed = Color(0xFFE07A2F);
  final colorScheme = ColorScheme.fromSeed(seedColor: seed);

  return _buildFromColorScheme(colorScheme);
}

// ---------------------------------------------------------------------------
// Dark theme
// ---------------------------------------------------------------------------

ThemeData buildDarkTheme() {
  const seed = Color(0xFFE07A2F);
  final colorScheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.dark,
  );

  return _buildFromColorScheme(colorScheme);
}

// ---------------------------------------------------------------------------
// Shared builder
// ---------------------------------------------------------------------------

ThemeData _buildFromColorScheme(ColorScheme colorScheme) {
  const shapes = SnapFoodShapes();

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
    textTheme: GoogleFonts.nunitoTextTheme(colorScheme.brightness == Brightness.dark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme),
    extensions: const [shapes],

    // Card
    cardTheme: CardThemeData(
      color: colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(shapes.card),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
    ),

    // Input
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(shapes.input),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(shapes.input),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(shapes.input),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
    ),

    // Chips
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(shapes.chip),
      ),
    ),

    // FilledButton — pill shape
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(shapes.actionButton),
        ),
      ),
    ),

    // OutlinedButton — pill shape
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(shapes.actionButton),
        ),
      ),
    ),
  );
}
