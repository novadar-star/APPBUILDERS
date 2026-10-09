// ResultsScreen — T9
// Shows up to 3 recipes ranked by retrieval.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snapfood/app/providers.dart';
import 'package:snapfood/domain/models.dart';
import 'package:snapfood/domain/retrieval.dart';
import 'package:snapfood/shared/empty_state.dart';
import 'package:snapfood/shared/on_device_badge.dart';
import 'package:snapfood/shared/sample_notice.dart';
import 'package:snapfood/shared/tag_chip.dart';

// ---------------------------------------------------------------------------
// ResultsScreen
// ---------------------------------------------------------------------------

class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bundleAsync = ref.watch(appBundleProvider);
    final ownedIds = ref.watch(ownedIngredientsProvider);
    final prefsAsync = ref.watch(preferencesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipes for you'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: OnDeviceMiniConsumer(),
          ),
        ],
      ),
      body: bundleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading recipes: $e')),
        data: (bundle) => prefsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) =>
              Center(child: Text('Error loading preferences: $e')),
          data: (prefs) {
            final results = retrieve(
              bundle.recipes,
              bundle.ingredients,
              bundle.prices,
              ownedIds,
              prefs,
              limit: 3,
            );
            return _ResultsList(
              results: results,
              prefs: prefs,
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ResultsList
// ---------------------------------------------------------------------------

class _ResultsList extends StatelessWidget {
  final List<RecipeResult> results;
  final Preferences prefs;

  const _ResultsList({required this.results, required this.prefs});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── SAMPLE DATA ──────────────────────────────────────────────
            const SampleNotice(),
            const SizedBox(height: 16),

            // ── Heading ──────────────────────────────────────────────────
            Text(
              'A few good matches',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0E3D2A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Ranked by ingredients you have, estimated cost, and cooking time.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),

            // ── Empty state ──────────────────────────────────────────────
            if (results.isEmpty)
              const EmptyState(
                icon: Icons.no_food_outlined,
                title: 'No recipes for that setup',
                body:
                    'Try adding another piece of equipment or ingredient.',
              )
            else
              ...results.map((r) => _RecipeCard(
                    result: r,
                    prefs: prefs,
                  )),

            const SizedBox(height: 16),

            // ── OnDevice badge ───────────────────────────────────────────
            const OnDeviceBadgeConsumer(),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _RecipeCard
// ---------------------------------------------------------------------------

class _RecipeCard extends StatelessWidget {
  final RecipeResult result;
  final Preferences prefs;

  const _RecipeCard({required this.result, required this.prefs});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recipe = result.base;
    final overBudget = result.flags.contains('overBudget');
    final lowMatch = result.flags.contains('lowMatch');

    // Core owned ratio — approximate from flags (lowMatch means <50%).
    // Compute a display %. We don't have exact here so use lowMatch flag.
    final coreTotal = recipe.ingredients.where((i) => i.core).length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => context.go('/recipe/${recipe.id}'),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top tags row
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    const TagChip(
                      text: 'SAMPLE BASE RECIPE',
                      color: Color(0xFFE5EEE5),
                      textColor: Color(0xFF1C684E),
                    ),
                    TagChip(
                      text: '${recipe.minutes} min',
                      color: const Color(0xFFF0EEE6),
                      textColor: const Color(0xFF596357),
                    ),
                    if (lowMatch)
                      const TagChip(
                        text: 'LOW INGREDIENT MATCH',
                        color: Color(0xFFFFE1C8),
                        textColor: Color(0xFF7A4A1E),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Filipino name
                Text(
                  recipe.nameFil,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0E3D2A),
                    fontSize: 22,
                  ),
                ),

                // English name
                Text(
                  recipe.nameEn,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 10),

                // Match and cost tags
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (coreTotal > 0)
                      TagChip(
                        text: lowMatch
                            ? '< 50% core ingredients owned'
                            : '≥ 50% core ingredients owned',
                        color: lowMatch
                            ? const Color(0xFFFFF3CD)
                            : const Color(0xFFD4EBD8),
                        textColor: lowMatch
                            ? const Color(0xFF856404)
                            : const Color(0xFF1C684E),
                      ),
                    TagChip(
                      text:
                          'Extra est. ₱${result.estimatedExtraPesos}',
                      color: overBudget
                          ? const Color(0xFFFFE1C8)
                          : const Color(0xFFF0EEE6),
                      textColor: overBudget
                          ? const Color(0xFF7A4A1E)
                          : const Color(0xFF596357),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // See recipe row
                Row(
                  children: [
                    Text(
                      'See recipe',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF1C684E),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward,
                        size: 16, color: Color(0xFF1C684E)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
