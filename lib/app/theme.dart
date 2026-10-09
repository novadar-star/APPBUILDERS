import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFF7F5EF),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF1C684E),
      surface: const Color(0xFFF7F5EF),
    ),
    fontFamily: 'Roboto',
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Color(0xFFE8E6DE)),
      ),
    ),
  );
}
