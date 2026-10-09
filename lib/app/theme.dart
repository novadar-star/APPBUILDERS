import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ---------------------------------------------------------------------------
// Nova design tokens
// ---------------------------------------------------------------------------
// Derived from Nova's body palette. Use these everywhere in the app so the
// UI stays consistent with the mascot. Nova's body colors are FIXED — do not
// alter them for dark mode. Only surfaces behind Nova change.

abstract final class NovaColors {
  /// Cream — light surfaces, cards, Nova's body
  static const cream = Color(0xFFF6E7C1);

  /// Yellow — highlights, active states, Nova's face
  static const yellow = Color(0xFFFFC93C);

  /// Orange — secondary accent
  static const orange = Color(0xFFFF9F2E);

  /// Green — primary actions, Nova's camera / leaf
  static const green = Color(0xFF5E8F57);

  /// Dark green — pressed states, outlines on green elements
  static const darkGreen = Color(0xFF2F5D31);

  /// Brown — primary text, Nova's eyes / outlines
  static const brown = Color(0xFF4A2C1A);

  // ── Surfaces (darken in dark mode) ────────────────────────────────────────

  /// Light mode app background
  static const backgroundLight = Color(0xFFFFFBF0);

  /// Dark mode app background
  static const backgroundDark = Color(0xFF1D1913);

  /// Light mode card / panel
  static const surfaceLight = Color(0xFFFFFFFF);

  /// Dark mode card / panel
  static const surfaceDark = Color(0xFF292318);

  /// Light mode stage / tinted surface
  static const stageLight = Color(0xFFFFF3CF);

  /// Dark mode stage / tinted surface
  static const stageDark = Color(0xFF332B1B);

  /// Divider / border — light
  static const lineLight = Color(0xFFEADFC4);

  /// Divider / border — dark
  static const lineDark = Color(0xFF40372A);
}

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
    this.badge = 24.0,
  });

  final double card;
  final double input;
  final double chip;
  final double actionButton;
  /// Illustration / icon container radius (e.g. EmptyState placeholder)
  final double badge;

  @override
  SnapFoodShapes copyWith({
    double? card,
    double? input,
    double? chip,
    double? actionButton,
    double? badge,
  }) {
    return SnapFoodShapes(
      card: card ?? this.card,
      input: input ?? this.input,
      chip: chip ?? this.chip,
      actionButton: actionButton ?? this.actionButton,
      badge: badge ?? this.badge,
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
      badge: lerpDouble(this.badge, other.badge, t)!,
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
  // Primary: Nova's green. Secondary: Nova's orange. Tertiary: Nova's yellow.
  final colorScheme = ColorScheme.fromSeed(
    seedColor: NovaColors.green,
    primary: NovaColors.green,
    onPrimary: Colors.white,
    secondary: NovaColors.orange,
    onSecondary: NovaColors.brown,
    tertiary: NovaColors.yellow,
    onTertiary: NovaColors.brown,
    surface: NovaColors.surfaceLight,
    onSurface: NovaColors.brown,
    surfaceContainerHigh: NovaColors.stageLight,
    outline: NovaColors.lineLight,
    outlineVariant: NovaColors.lineLight,
  );

  return _buildFromColorScheme(colorScheme, background: NovaColors.backgroundLight);
}

// ---------------------------------------------------------------------------
// Dark theme
// ---------------------------------------------------------------------------

ThemeData buildDarkTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: NovaColors.green,
    brightness: Brightness.dark,
    primary: const Color(0xFF8DBF84), // lighter green for dark mode
    onPrimary: NovaColors.backgroundDark,
    secondary: NovaColors.orange,
    onSecondary: NovaColors.backgroundDark,
    tertiary: NovaColors.yellow,
    onTertiary: NovaColors.backgroundDark,
    surface: NovaColors.surfaceDark,
    onSurface: const Color(0xFFF4EAD2),
    surfaceContainerHigh: NovaColors.stageDark,
    outline: NovaColors.lineDark,
    outlineVariant: NovaColors.lineDark,
  );

  return _buildFromColorScheme(colorScheme, background: NovaColors.backgroundDark);
}

// ---------------------------------------------------------------------------
// Shared builder
// ---------------------------------------------------------------------------

ThemeData _buildFromColorScheme(ColorScheme colorScheme, {Color? background}) {
  const shapes = SnapFoodShapes();

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: background ?? colorScheme.surface,
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
