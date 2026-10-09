// ResultsScreen — T9
// Shows up to 3 recipes ranked by retrieval.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

    final isLoading =
        bundleAsync.isLoading || prefsAsync.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('here\'s what you can make'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: OnDeviceMiniConsumer(),
          ),
        ],
      ),
      body: bundleAsync.when(
        loading: () => _SkeletonColumn(),
        error: (e, _) => Center(child: Text('Error loading recipes: $e')),
        data: (bundle) => prefsAsync.when(
          loading: () => _SkeletonColumn(),
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
              isLoading: isLoading,
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _SkeletonCard
// ---------------------------------------------------------------------------

class _SkeletonCard extends StatefulWidget {
  const _SkeletonCard();

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedBuilder(
        animation: _opacity,
        builder: (context, _) => Opacity(
          opacity: _opacity.value,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title bar
                  Container(
                    height: 24,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Line 1 — 80%
                  FractionallySizedBox(
                    widthFactor: 0.80,
                    child: Container(
                      height: 14,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Line 2 — 95%
                  FractionallySizedBox(
                    widthFactor: 0.95,
                    child: Container(
                      height: 14,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Line 3 — 70%
                  FractionallySizedBox(
                    widthFactor: 0.70,
                    child: Container(
                      height: 14,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Chip row — two short skeleton chips
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 24,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 80,
                        height: 24,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SkeletonColumn extends StatelessWidget {
  const _SkeletonColumn();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: const [
            _SkeletonCard(),
            _SkeletonCard(),
            _SkeletonCard(),
          ],
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
  final bool isLoading;

  const _ResultsList({
    required this.results,
    required this.prefs,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── SAMPLE DATA ──────────────────────────────────────────────
            const SampleNotice(),
            const SizedBox(height: 16),

            // ── Loading indicator ─────────────────────────────────────────
            if (isLoading) ...[
              Text(
                'cooking something up…',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                semanticsLabel: 'adapting recipe',
                valueColor:
                    AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
              const SizedBox(height: 16),
            ],

            // ── Heading ──────────────────────────────────────────────────
            Text(
              'a few good matches',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Ranked by ingredients you have, estimated cost, and cooking time.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),

            // ── Empty state ──────────────────────────────────────────────
            if (results.isEmpty)
              const EmptyState(
                icon: Icons.no_food_outlined,
                title: 'hmm, nothing matched.',
                body: 'try adding more ingredients.',
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: results.length,
                itemBuilder: (context, i) => _RecipeCard(
                  result: results[i],
                  prefs: prefs,
                ),
              ),

            const SizedBox(height: 16),
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
    final colorScheme = theme.colorScheme;
    final recipe = result.base;
    final overBudget = result.flags.contains('overBudget');
    final lowMatch = result.flags.contains('lowMatch');

    final coreTotal = recipe.ingredients.where((i) => i.core).length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.selectionClick();
            context.go('/recipe/${recipe.id}');
          },
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
                    TagChip(
                      text: 'SAMPLE BASE RECIPE',
                      color: colorScheme.primaryContainer,
                      textColor: colorScheme.onPrimaryContainer,
                    ),
                    TagChip(
                      text: '${recipe.minutes} min',
                      color: colorScheme.surfaceContainerHigh,
                      textColor: colorScheme.onSurfaceVariant,
                    ),
                    if (lowMatch)
                      TagChip(
                        text: 'LOW INGREDIENT MATCH',
                        color: colorScheme.tertiaryContainer,
                        textColor: colorScheme.onTertiaryContainer,
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Filipino name
                Text(
                  recipe.nameFil,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),

                // English name
                Text(
                  recipe.nameEn,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
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
                            ? colorScheme.tertiaryContainer
                            : colorScheme.primaryContainer,
                        textColor: lowMatch
                            ? colorScheme.onTertiaryContainer
                            : colorScheme.onPrimaryContainer,
                      ),
                    TagChip(
                      text: 'Extra est. ₱${result.estimatedExtraPesos}',
                      color: overBudget
                          ? colorScheme.errorContainer
                          : colorScheme.surfaceContainerHigh,
                      textColor: overBudget
                          ? colorScheme.onErrorContainer
                          : colorScheme.onSurfaceVariant,
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
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward,
                        size: 16, color: colorScheme.primary),
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
