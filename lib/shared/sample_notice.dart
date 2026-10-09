import 'package:flutter/material.dart';

/// Amber banner shown on every screen to indicate sample/fictional data.
class SampleNotice extends StatelessWidget {
  const SampleNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.tertiary, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline,
              size: 16, color: colorScheme.onTertiaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'SAMPLE DATA · fictional recipes and estimated prices',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onTertiaryContainer,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
