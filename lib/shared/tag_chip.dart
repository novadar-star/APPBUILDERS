import 'package:flutter/material.dart';

/// Small rounded display chip with bold text.
/// Uses RawChip with onPressed: null for Material 3 chip shape/padding.
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
    final fallbackTextColor =
        textColor ?? Theme.of(context).colorScheme.onSurface;
    return RawChip(
      isEnabled: false,
      onPressed: null,
      label: Text(
        text,
        style: (Theme.of(context).textTheme.labelSmall ?? const TextStyle()).copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: fallbackTextColor,
        ),
      ),
      backgroundColor: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide.none,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
