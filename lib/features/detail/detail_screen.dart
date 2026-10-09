// DetailScreen — T9
// Full recipe detail + on-device adaptation.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snapfood/app/providers.dart';
import 'package:snapfood/app/theme.dart';
import 'package:snapfood/data/asset_loader.dart';
import 'package:snapfood/domain/models.dart';
import 'package:snapfood/shared/on_device_badge.dart';
import 'package:snapfood/shared/sample_notice.dart';
import 'package:snapfood/shared/tag_chip.dart';

// ---------------------------------------------------------------------------
// DetailScreen
// ---------------------------------------------------------------------------

class DetailScreen extends ConsumerStatefulWidget {
  const DetailScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends ConsumerState<DetailScreen> {
  bool _adaptationStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_adaptationStarted) {
      _adaptationStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _startAdaptation());
    }
  }

  Future<void> _startAdaptation() async {
    final bundleAsync = ref.read(appBundleProvider);
    final prefsAsync = ref.read(preferencesProvider);
    final ownedIds = ref.read(ownedIngredientsProvider);

    bundleAsync.whenData((bundle) {
      final recipe =
          bundle.recipes.where((r) => r.id == widget.id).firstOrNull;
      if (recipe == null) return;

      prefsAsync.whenData((prefs) {
        ref.read(adaptationProvider(widget.id).notifier).start(
              AdaptRequest(
                base: recipe,
                ownedIds: ownedIds,
                prefs: prefs,
              ),
            );
      });
    });
  }

  @override
  void dispose() {
    ref.read(adaptationProvider(widget.id).notifier).cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bundleAsync = ref.watch(appBundleProvider);
    final adaptState = ref.watch(adaptationProvider(widget.id));
    final ownedIds = ref.watch(ownedIngredientsProvider);

    // Compute total cost for the footer
    int totalCost = 0;
    if (adaptState.result != null) {
      bundleAsync.whenData((bundle) {
        totalCost = adaptState.result!.ingredients
            .where((ai) => ai.source == IngredientSource.toBuy)
            .fold<int>(0, (sum, ai) {
          return sum + (bundle.prices[ai.ingredientId] ?? 0);
        });
      });
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            HapticFeedback.lightImpact();
            context.go('/results');
          },
        ),
        title: const Text('Recipe'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: OnDeviceMiniConsumer(),
          ),
        ],
      ),
      bottomNavigationBar: adaptState.result != null && totalCost > 0
          ? _CostFooter(cost: totalCost)
          : null,
      body: bundleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (bundle) {
          final recipe =
              bundle.recipes.where((r) => r.id == widget.id).firstOrNull;
          if (recipe == null) {
            return Center(child: Text('Recipe "${widget.id}" not found.'));
          }
          return _DetailBody(
            recipe: recipe,
            bundle: bundle,
            ownedIds: ownedIds,
            adaptState: adaptState,
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _CostFooter
// ---------------------------------------------------------------------------

class _CostFooter extends StatelessWidget {
  final int cost;

  const _CostFooter({required this.cost});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return BottomAppBar(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
        ),
        child: Row(
          children: [
            Icon(Icons.shopping_cart_outlined,
                color: colorScheme.onPrimaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Estimated total: ₱$cost',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'SAMPLE PRICES',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onPrimaryContainer
                          .withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _DetailBody
// ---------------------------------------------------------------------------

class _DetailBody extends StatelessWidget {
  final Recipe recipe;
  final AppBundle bundle;
  final Set<String> ownedIds;
  final AdaptationState adaptState;

  const _DetailBody({
    required this.recipe,
    required this.bundle,
    required this.ownedIds,
    required this.adaptState,
  });

  String _ingredientName(String id) {
    final ing = bundle.ingredients.where((i) => i.id == id).firstOrNull;
    return ing?.nameFil ?? id;
  }

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

            // ── Recipe heading ───────────────────────────────────────────
            Text(
              recipe.nameFil,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              recipe.nameEn,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),

            // ── Tags ─────────────────────────────────────────────────────
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                TagChip(
                  text: '${recipe.minutes} min',
                  color: colorScheme.surfaceContainerHigh,
                  textColor: colorScheme.onSurfaceVariant,
                ),
                ...recipe.equipment.map((eq) => TagChip(
                      text: _equipmentLabel(eq),
                      color: colorScheme.primaryContainer,
                      textColor: colorScheme.onPrimaryContainer,
                    )),
              ],
            ),
            const SizedBox(height: 16),

            // ── Adaptation status banner ─────────────────────────────────
            _AdaptationBanner(adaptState: adaptState),
            const SizedBox(height: 16),

            // ── Recipe content ───────────────────────────────────────────
            if (adaptState.result != null)
              _AdaptedRecipeView(
                adapted: adaptState.result!,
                bundle: bundle,
                ownedIds: ownedIds,
              )
            else
              _BaseRecipeView(
                recipe: recipe,
                ownedIds: ownedIds,
                ingredientName: _ingredientName,
              ),

            const SizedBox(height: 20),

            // ── OnDevice badge ───────────────────────────────────────────
            const OnDeviceBadgeConsumer(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _equipmentLabel(Equipment e) {
    switch (e) {
      case Equipment.riceCooker:
        return 'Rice cooker';
      case Equipment.kettle:
        return 'Kettle';
      case Equipment.microwave:
        return 'Microwave';
      case Equipment.stove:
        return 'Stove';
    }
  }
}

// ---------------------------------------------------------------------------
// _AdaptationBanner
// ---------------------------------------------------------------------------

class _AdaptationBanner extends StatelessWidget {
  final AdaptationState adaptState;

  const _AdaptationBanner({required this.adaptState});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (adaptState.isRunning) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Generating recipe adaptation…',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${adaptState.tokens.length} tokens generated',
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              valueColor:
                  AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ],
        ),
      );
    }

    if (adaptState.fellBack) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline,
                color: colorScheme.onErrorContainer, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Base recipe shown — model did not adapt it',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (adaptState.result != null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle,
                color: colorScheme.primary, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Row(
                children: [
                  Text(
                    'Adapted by on-device model',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (kDebugMode)
                    TagChip(
                      text: 'MOCK',
                      color: colorScheme.tertiaryContainer,
                      textColor: colorScheme.onTertiaryContainer,
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Default — not started
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_outlined,
              color: colorScheme.onErrorContainer, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Base recipe · language model not installed',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onErrorContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _AdaptedRecipeView
// ---------------------------------------------------------------------------

class _AdaptedRecipeView extends StatelessWidget {
  final AdaptedRecipe adapted;
  final AppBundle bundle;
  final Set<String> ownedIds;

  const _AdaptedRecipeView({
    required this.adapted,
    required this.bundle,
    required this.ownedIds,
  });

  String _ingredientName(String id) {
    final ing = bundle.ingredients.where((i) => i.id == id).firstOrNull;
    return ing?.nameFil ?? id;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final owned = adapted.ingredients
        .where((ai) => ai.source == IngredientSource.owned)
        .toList();
    final substituted = adapted.ingredients
        .where((ai) => ai.source == IngredientSource.substituted)
        .toList();
    final toBuy = adapted.ingredients
        .where((ai) => ai.source == IngredientSource.toBuy)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section A — Ingredients you have
        if (owned.isNotEmpty) ...[
          _SectionHeading(
            icon: Icons.check_circle,
            label: 'You already have',
            color: colorScheme.tertiary,
          ),
          const SizedBox(height: 6),
          ...owned.map((ai) => _IngredientRow(
                name: _ingredientName(ai.ingredientId),
                qty: ai.qtyText,
                color: colorScheme.primaryContainer,
              )),
          Divider(height: 24, color: colorScheme.outlineVariant),
        ],

        // Section B — Substitutions
        if (substituted.isNotEmpty) ...[
          _SectionHeading(
            icon: Icons.swap_horiz,
            label: 'Substitutions',
            color: colorScheme.tertiary,
          ),
          const SizedBox(height: 6),
          ...substituted.map((ai) => _IngredientRow(
                name: ai.replacesId != null
                    ? '${_ingredientName(ai.ingredientId)} (instead of ${_ingredientName(ai.replacesId!)})'
                    : _ingredientName(ai.ingredientId),
                qty: ai.qtyText,
                color: colorScheme.tertiaryContainer,
              )),
          Divider(height: 24, color: colorScheme.outlineVariant),
        ],

        // Section C — Items to buy
        if (toBuy.isNotEmpty) ...[
          _SectionHeading(
            icon: Icons.shopping_cart_outlined,
            label: 'Items to buy',
            color: colorScheme.primary,
          ),
          const SizedBox(height: 6),
          ...toBuy.map((ai) {
            final price = bundle.prices[ai.ingredientId] ?? 0;
            return _IngredientRow(
              name: _ingredientName(ai.ingredientId),
              qty: ai.qtyText,
              color: colorScheme.surfaceContainerHigh,
              trailingChip: price > 0
                  ? Chip(
                      label: Text(
                        '₱$price',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      backgroundColor: colorScheme.primaryContainer,
                      padding: EdgeInsets.zero,
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                    )
                  : null,
            );
          }),
          const SizedBox(height: 12),
        ],

        const Divider(),
        const SizedBox(height: 10),

        // Steps
        Text(
          'Steps',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        ...adapted.steps.asMap().entries.map((e) => _StepRow(
              number: e.key + 1,
              text: e.value,
            )),

        // Notes
        if (adapted.notes.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Notes',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            adapted.notes,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _BaseRecipeView
// ---------------------------------------------------------------------------

class _BaseRecipeView extends StatelessWidget {
  final Recipe recipe;
  final Set<String> ownedIds;
  final String Function(String id) ingredientName;

  const _BaseRecipeView({
    required this.recipe,
    required this.ownedIds,
    required this.ingredientName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final owned = recipe.ingredients
        .where((ri) => ownedIds.contains(ri.ingredientId))
        .toList();
    final missing = recipe.ingredients
        .where((ri) => !ownedIds.contains(ri.ingredientId))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ingredients',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),

        if (owned.isNotEmpty) ...[
          _SectionHeading(
            icon: Icons.check_circle,
            label: 'You have',
            color: colorScheme.tertiary,
          ),
          const SizedBox(height: 4),
          ...owned.map((ri) => _IngredientRow(
                name: ingredientName(ri.ingredientId),
                qty: '${ri.qty} ${ri.unit}',
                color: colorScheme.primaryContainer,
              )),
          Divider(height: 24, color: colorScheme.outlineVariant),
        ],

        if (missing.isNotEmpty) ...[
          _SectionHeading(
            icon: Icons.shopping_cart_outlined,
            label: "You'll need",
            color: colorScheme.primary,
          ),
          const SizedBox(height: 4),
          ...missing.map((ri) => _IngredientRow(
                name: ingredientName(ri.ingredientId),
                qty: '${ri.qty} ${ri.unit}',
                color: colorScheme.surfaceContainerHigh,
              )),
          const SizedBox(height: 10),
        ],

        const Divider(),
        const SizedBox(height: 10),

        Text(
          'Steps',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        ...recipe.steps.asMap().entries.map((e) => _StepRow(
              number: e.key + 1,
              text: e.value,
            )),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Small helper widgets
// ---------------------------------------------------------------------------

class _SectionHeading extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SectionHeading({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _IngredientRow extends StatelessWidget {
  final String name;
  final String qty;
  final Color color;
  final Widget? trailingChip;

  const _IngredientRow({
    required this.name,
    required this.qty,
    required this.color,
    this.trailingChip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final shapes = theme.extension<SnapFoodShapes>();
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(shapes?.chip ?? 8.0),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(name, style: theme.textTheme.bodyMedium),
          ),
          if (trailingChip != null) ...[
            const SizedBox(width: 8),
            trailingChip!,
          ] else
            Text(
              qty,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final int number;
  final String text;

  const _StepRow({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$number',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
