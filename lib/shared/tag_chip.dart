import 'package:flutter/material.dart';

/// Small rounded pill tag with bold text.
class TagChip extends StatelessWidget {
  final String text;
  final Color color;
  final Color? textColor;

  const TagChip({
    super.key,
    required this.text,
    required this.color,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: textColor ?? _contrastText(color),
        ),
      ),
    );
  }

  /// Returns black or white depending on background luminance.
  Color _contrastText(Color bg) {
    final luminance = bg.computeLuminance();
    return luminance > 0.4 ? const Color(0xFF1A1A1A) : Colors.white;
  }
}
