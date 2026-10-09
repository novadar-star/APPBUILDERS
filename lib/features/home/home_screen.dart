// HomeScreen
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snapfood/app/providers.dart';
import 'package:snapfood/shared/nova/nova_state.dart';
import 'package:snapfood/shared/nova/nova_widget.dart';
import 'package:snapfood/shared/sample_notice.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _pickPhoto(BuildContext context, WidgetRef ref) async {
    final picker = ref.read(photoPickerProvider);
    final path = await picker.pickPhoto();
    if (path == null) return;
    // Photo picked — feed through the detector (mock returns top-3)
    final detector = ref.read(detectorProvider);
    final predictions = await detector.predictFromFile(path);
    if (predictions.isNotEmpty) {
      final ids = predictions.map((p) => p.ingredientId).toSet();
      ref.read(ownedIngredientsProvider.notifier).state = ids;
    }
    if (context.mounted) context.go('/review');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ownedIngredients = ref.watch(ownedIngredientsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              // Upper hero zone
              SizedBox(
                height: 200,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Nova hero — idle until ingredients scanned, then happy
                    Positioned(
                      top: 0,
                      right: 0,
                      child: NovaWidget(
                        state: ownedIngredients.isEmpty
                            ? NovaState.idle
                            : NovaState.happy,
                        size: 160,
                      ),
                    ),

                    // Title bottom left
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 80,
                      child: Text(
                        "What's in your\nkitchen?",
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Sweep your camera over your ingredients and we\'ll find something to cook.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 20),

              const SampleNotice(),

              // Ingredient count chip if any confirmed
              if (ownedIngredients.isNotEmpty) ...[
                const SizedBox(height: 16),
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
                          '${ownedIngredients.length} ingredient${ownedIngredients.length == 1 ? '' : 's'} confirmed \u2014 tap to review',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const Spacer(),

              // Offline indicator
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
                      'runs on your phone \u00b7 works offline',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Primary CTA
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

              // Secondary CTAs — manual entry + photo picker
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: () => context.go('/review'),
                        icon: const Icon(Icons.edit_note),
                        label: const Text(
                          'Manual entry',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: () => _pickPhoto(context, ref),
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text(
                          'Choose photo',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
