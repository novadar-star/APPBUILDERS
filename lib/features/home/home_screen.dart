// HomeScreen — T9 (curated asymmetric layout, Apple HIG pass)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snapfood/app/providers.dart';
import 'package:snapfood/app/theme.dart';
import 'package:snapfood/shared/sample_notice.dart';

// Pantry words shown in the hero mosaic — Filipino staples, dorm-friendly
const List<String> _pantryWords = [
  'Toyo', 'Bawang', 'Sibuyas', 'Kamatis', 'Asin',
  'Mantika', 'Itlog', 'Bigas', 'Paminta', 'Luya',
];

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ownedIngredients = ref.watch(ownedIngredientsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final shapes = theme.extension<SnapFoodShapes>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              // ── Upper hero zone — mosaic top-right, title bottom-left ──
              SizedBox(
                height: 200,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Ingredient mosaic — upper right
                    Positioned(
                      top: 0,
                      right: 0,
                      child: _IngredientMosaic(
                        words: _pantryWords,
                        colorScheme: colorScheme,
                        shapes: shapes,
                      ),
                    ),

                    // Title — bottom left, w700 (reserve w800 for recipe names)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 80,
                      child: Text(
                        "What's in your\nkitchen?",
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Subtitle ────────────────────────────────────────────────
              Text(
                'Sweep your camera over your ingredients and we\'ll find something to cook.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 20),

              // ── SAMPLE DATA notice ──────────────────────────────────────
              const SampleNotice(),

              // ── Ingredient count — InkWell with 44dp min target + haptic ──
              if (ownedIngredients.isNotEmpty) ...[
                const SizedBox(height: 16),
                Material(
                  color: colorScheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(shapes?.input ?? 12),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      context.go('/review');
                    },
                    borderRadius: BorderRadius.circular(shapes?.input ?? 12),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 44),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle,
                              size: 16, color: colorScheme.primary),
                          const SizedBox(width: 6),
                          Text(
                            '${ownedIngredients.length} ingredient${ownedIngredients.length == 1 ? '' : 's'} confirmed — tap to review',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],

              const Spacer(),

              // ── On-device badge — one canonical placement, bottom center ──
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.green.shade600,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'runs on your phone',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Primary CTA ─────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    context.go('/scan');
                  },
                  child: const Text(
                    'Start scanning',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── Secondary CTA — haptic added ────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    context.go('/review');
                  },
                  icon: const Icon(Icons.edit_note),
                  label: const Text(
                    'Add ingredients manually',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _IngredientMosaic — pantry word cloud, product-specific hero element
// ---------------------------------------------------------------------------

class _IngredientMosaic extends StatelessWidget {
  final List<String> words;
  final ColorScheme colorScheme;
  final SnapFoodShapes? shapes;

  const _IngredientMosaic({
    required this.words,
    required this.colorScheme,
    required this.shapes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Alternate between two tones for visual rhythm
    final colors = [
      colorScheme.primaryContainer,
      colorScheme.surfaceContainerHigh,
    ];
    final textColors = [
      colorScheme.onPrimaryContainer,
      colorScheme.onSurfaceVariant,
    ];

    return SizedBox(
      width: 160,
      height: 160,
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: words.asMap().entries.map((entry) {
          final i = entry.key;
          final word = entry.value;
          final bg = colors[i % 2];
          final fg = textColors[i % 2];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: bg,
              borderRadius:
                  BorderRadius.circular(shapes?.chip ?? 8.0),
            ),
            child: Text(
              word,
              style: theme.textTheme.labelSmall?.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
