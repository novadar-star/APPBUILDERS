// HomeScreen — T9
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snapfood/app/providers.dart';
import 'package:snapfood/shared/on_device_badge.dart';
import 'package:snapfood/shared/sample_notice.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ownedIngredients = ref.watch(ownedIngredientsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Food-hero area ─────────────────────────────────────────
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Icon(
                    Icons.restaurant_menu,
                    size: 80,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── App name ───────────────────────────────────────────────
              Text(
                'snapfood',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),

              // ── Subtitle ───────────────────────────────────────────────
              Text(
                'Find a Filipino favorite for your small kitchen and your budget.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              // ── SAMPLE DATA ────────────────────────────────────────────
              const SampleNotice(),
              const SizedBox(height: 16),

              // ── Ingredient count if any are already confirmed ──────────
              if (ownedIngredients.isNotEmpty) ...[
                GestureDetector(
                  onTap: () => context.go('/review'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                const SizedBox(height: 16),
              ],

              // ── Primary CTA ────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    context.go('/scan');
                  },
                  child: const Text(
                    'Start Scanning',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Secondary CTA ──────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/review'),
                  icon: const Icon(Icons.edit_note),
                  label: const Text(
                    'Add ingredients manually',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── THE IDEA section ───────────────────────────────────────
              Text(
                'THE IDEA',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'SnapFood uses your phone\'s camera to identify what ingredients you already have. '
                'It then finds Filipino dorm-friendly recipes that match — and adapts them on-device '
                'so nothing leaves your phone.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No internet needed. No data shared. Just good food.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // ── OnDevice badge ─────────────────────────────────────────
              const OnDeviceBadgeConsumer(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
