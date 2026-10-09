import 'package:flutter/material.dart';
import 'package:snapfood/app/theme.dart';

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
    final theme = Theme.of(context);
    final shapes = theme.extension<SnapFoodShapes>();
    final radius = shapes?.chip ?? 8.0;
    final fallbackTextColor = textColor ?? theme.colorScheme.onSurface;
    return RawChip(
      isEnabled: false,
      onPressed: null,
      label: Text(
        text,
        style: (theme.textTheme.labelSmall ?? const TextStyle()).copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: fallbackTextColor,
        ),
      ),
      backgroundColor: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide.none,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
