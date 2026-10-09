// DetailScreen — T9
// Full recipe detail + on-device adaptation.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snapfood/app/providers.dart';
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
      // Schedule adaptation start after the first build.
      WidgetsBinding.instance.addPostFrameCallback((_) => _startAdaptation());
    }
  }

  Future<void> _startAdaptation() async {
    final bundleAsync = ref.read(appBundleProvider);
    final prefsAsync = ref.read(preferencesProvider);
    final ownedIds = ref.read(ownedIngredientsProvider);

    bundleAsync.whenData((bundle) {
      final recipe = bundle.recipes
          .where((r) => r.id == widget.id)
          .firstOrNull;
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

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/results'),
        ),
        title: const Text('Recipe'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: OnDeviceMiniConsumer(),
          ),
        ],
      ),
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
    final ing =
        bundle.ingredients.where((i) => i.id == id).firstOrNull;
    return ing?.nameFil ?? id;
  }

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

            // ── Recipe heading ───────────────────────────────────────────
            Text(
              recipe.nameFil,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0E3D2A),
              ),
            ),
            Text(
              recipe.nameEn,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
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
                  color: const Color(0xFFF0EEE6),
                  textColor: const Color(0xFF596357),
                ),
                ...recipe.equipment.map((eq) => TagChip(
                      text: _equipmentLabel(eq),
                      color: const Color(0xFFE5EEE5),
                      textColor: const Color(0xFF1C684E),
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
    if (adaptState.isRunning) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF0EEE6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Generating recipe adaptation…',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${adaptState.tokens.length} tokens generated',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (adaptState.fellBack) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3CD),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFD700)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFF856404), size: 18),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Base recipe shown — model did not adapt it',
                style: TextStyle(
                  color: Color(0xFF856404),
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
          color: const Color(0xFFD4EBD8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF1C684E), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Row(
                children: [
                  const Text(
                    'Adapted by on-device model',
                    style: TextStyle(
                      color: Color(0xFF1C684E),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (kDebugMode)
                    const TagChip(
                      text: 'MOCK',
                      color: Color(0xFFFFE1C8),
                      textColor: Color(0xFF7A4A1E),
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
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD700)),
      ),
      child: Row(
        children: const [
          Icon(Icons.warning_amber_outlined,
              color: Color(0xFF856404), size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Base recipe · language model not installed',
              style: TextStyle(
                color: Color(0xFF856404),
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

  int _estimateTotalCost() {
    return adapted.ingredients
        .where((ai) => ai.source == IngredientSource.toBuy)
        .fold<int>(0, (sum, ai) {
      final price = bundle.prices[ai.ingredientId] ?? 0;
      return sum + price;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final owned = adapted.ingredients
        .where((ai) => ai.source == IngredientSource.owned)
        .toList();
    final substituted = adapted.ingredients
        .where((ai) => ai.source == IngredientSource.substituted)
        .toList();
    final toBuy = adapted.ingredients
        .where((ai) => ai.source == IngredientSource.toBuy)
        .toList();
    final totalCost = _estimateTotalCost();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ingredients grouped
        if (owned.isNotEmpty) ...[
          _SectionHeading(
            icon: Icons.check_circle,
            label: 'You already have',
            color: const Color(0xFF1C684E),
          ),
          const SizedBox(height: 6),
          ...owned.map((ai) => _IngredientRow(
                name: _ingredientName(ai.ingredientId),
                qty: ai.qtyText,
                color: const Color(0xFFE5EEE5),
              )),
          const SizedBox(height: 12),
        ],
        if (substituted.isNotEmpty) ...[
          _SectionHeading(
            icon: Icons.swap_horiz,
            label: 'Substitutions',
            color: const Color(0xFF1565C0),
          ),
          const SizedBox(height: 6),
          ...substituted.map((ai) => _IngredientRow(
                name: ai.replacesId != null
                    ? '${_ingredientName(ai.ingredientId)} (instead of ${_ingredientName(ai.replacesId!)})'
                    : _ingredientName(ai.ingredientId),
                qty: ai.qtyText,
                color: const Color(0xFFE3F2FD),
              )),
          const SizedBox(height: 12),
        ],
        if (toBuy.isNotEmpty) ...[
          _SectionHeading(
            icon: Icons.shopping_bag_outlined,
            label: 'Items to buy',
            color: const Color(0xFFB07B3A),
          ),
          const SizedBox(height: 6),
          ...toBuy.map((ai) => _IngredientRow(
                name: _ingredientName(ai.ingredientId),
                qty: ai.qtyText,
                color: const Color(0xFFFFF3CD),
              )),
          const SizedBox(height: 4),
          if (totalCost > 0)
            Text(
              '₱$totalCost · SAMPLE prices',
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF856404),
                fontWeight: FontWeight.w600,
              ),
            ),
          const SizedBox(height: 12),
        ],

        const Divider(),
        const SizedBox(height: 10),

        // Steps
        Text(
          'Steps',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0E3D2A),
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
              color: const Color(0xFF596357),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            adapted.notes,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[700],
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
            color: const Color(0xFF0E3D2A),
          ),
        ),
        const SizedBox(height: 8),

        // Owned
        if (owned.isNotEmpty) ...[
          _SectionHeading(
            icon: Icons.check_circle,
            label: 'You have',
            color: const Color(0xFF1C684E),
          ),
          const SizedBox(height: 4),
          ...owned.map((ri) => _IngredientRow(
                name: ingredientName(ri.ingredientId),
                qty: '${ri.qty} ${ri.unit}',
                color: const Color(0xFFE5EEE5),
              )),
          const SizedBox(height: 10),
        ],

        // Missing
        if (missing.isNotEmpty) ...[
          _SectionHeading(
            icon: Icons.shopping_bag_outlined,
            label: "You'll need",
            color: const Color(0xFFB07B3A),
          ),
          const SizedBox(height: 4),
          ...missing.map((ri) => _IngredientRow(
                name: ingredientName(ri.ingredientId),
                qty: '${ri.qty} ${ri.unit}',
                color: const Color(0xFFFFF3CD),
              )),
          const SizedBox(height: 10),
        ],

        const Divider(),
        const SizedBox(height: 10),

        // Steps
        Text(
          'Steps',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0E3D2A),
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
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: color,
            fontSize: 13,
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

  const _IngredientRow({
    required this.name,
    required this.qty,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(name, style: const TextStyle(fontSize: 14)),
          ),
          Text(
            qty,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: Color(0xFF1C684E),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
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
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(height: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
