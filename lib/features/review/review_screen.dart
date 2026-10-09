// ReviewScreen — T9
// Confirm owned ingredients + set preferences.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snapfood/app/providers.dart';
import 'package:snapfood/app/theme.dart';
import 'package:snapfood/data/asset_loader.dart';
import 'package:snapfood/data/preferences_store.dart';
import 'package:snapfood/domain/models.dart';
import 'package:snapfood/shared/on_device_badge.dart';
import 'package:snapfood/shared/sample_notice.dart';

// ---------------------------------------------------------------------------
// ReviewScreen
// ---------------------------------------------------------------------------

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  Set<Equipment> _selectedEquipment = {};
  int _extraBudget = 30;
  bool _prefsLoaded = false;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_prefsLoaded) {
      final prefsAsync = ref.read(preferencesProvider);
      prefsAsync.whenData((prefs) {
        if (mounted) {
          setState(() {
            _selectedEquipment = Set.from(prefs.equipment);
            _extraBudget = prefs.extraBudgetPesos;
            _prefsLoaded = true;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _equipmentLabel(Equipment e) {
    switch (e) {
      case Equipment.riceCooker:
        return 'Rice cooker';
      case Equipment.kettle:
        return 'Electric kettle';
      case Equipment.microwave:
        return 'Microwave';
      case Equipment.stove:
        return 'Stove';
    }
  }

  Future<void> _saveAndNavigate(AppBundle bundle) async {
    HapticFeedback.lightImpact();
    final owned = ref.read(ownedIngredientsProvider);
    ref.read(ownedIngredientsProvider.notifier).state = owned;
    final prefs = Preferences(
      equipment: _selectedEquipment,
      extraBudgetPesos: _extraBudget,
    );
    await PreferencesStore().save(prefs);
    if (mounted) context.go('/results');
  }

  @override
  Widget build(BuildContext context) {
    final bundleAsync = ref.watch(appBundleProvider);
    final ownedIds = ref.watch(ownedIngredientsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('what you\'ve got'),
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
        data: (bundle) => _buildBody(context, theme, bundle, ownedIds),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ThemeData theme,
    AppBundle bundle,
    Set<String> ownedIds,
  ) {
    final colorScheme = theme.colorScheme;
    final shapes = theme.extension<SnapFoodShapes>();

    final matchResults = _query.isEmpty
        ? <Ingredient>[]
        : bundle.ingredients.where((ing) {
            if (ownedIds.contains(ing.id)) return false;
            final q = _query;
            return ing.nameFil.toLowerCase().contains(q) ||
                ing.nameEn.toLowerCase().contains(q) ||
                ing.aliases.any((a) => a.toLowerCase().contains(q));
          }).toList();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── SAMPLE DATA ──────────────────────────────────────────────
            const SampleNotice(),
            const SizedBox(height: 16),

            // ── INGREDIENTS section header ────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 28, bottom: 8),
              child: Text(
                'your ingredients',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // ── Confirmed chips ──────────────────────────────────────────
            if (ownedIds.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: ownedIds.map((id) {
                  final ing = bundle.ingredients
                      .where((i) => i.id == id)
                      .firstOrNull;
                  final label = ing?.nameFil ?? id;
                  return InputChip(
                    avatar: Icon(Icons.check,
                        size: 16, color: colorScheme.primary),
                    label: Text(label),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () {
                      final next = Set<String>.from(ownedIds)..remove(id);
                      ref.read(ownedIngredientsProvider.notifier).state =
                          next;
                    },
                    backgroundColor: colorScheme.primaryContainer,
                  );
                }).toList(),
              ),
            if (ownedIds.isEmpty)
              Text(
                'nothing here yet — try scanning or add ingredients below',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant),
              ),
            const SizedBox(height: 14),

            // ── Search field ─────────────────────────────────────────────
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'add something…',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(shapes?.input ?? 12.0),
                  borderSide:
                      BorderSide(color: colorScheme.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(shapes?.input ?? 12.0),
                  borderSide:
                      BorderSide(color: colorScheme.outlineVariant),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
            ),

            // ── Search results list ──────────────────────────────────────
            if (matchResults.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 160),
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(shapes?.input ?? 12.0),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: matchResults.length,
                  itemBuilder: (context, i) {
                    final ing = matchResults[i];
                    return ListTile(
                      dense: true,
                      title: Text(ing.nameFil),
                      subtitle: Text(ing.nameEn,
                          style: theme.textTheme.labelSmall),
                      trailing: Icon(Icons.add_circle_outline,
                          size: 20, color: colorScheme.primary),
                      onTap: () {
                        final next =
                            Set<String>.from(ownedIds)..add(ing.id);
                        ref
                            .read(ownedIngredientsProvider.notifier)
                            .state = next;
                        _searchCtrl.clear();
                      },
                    );
                  },
                ),
              ),

            // ── Clear all ────────────────────────────────────────────────
            if (ownedIds.isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    ref.read(ownedIngredientsProvider.notifier).state = {};
                  },
                  child: Text(
                    'clear all',
                    style: TextStyle(color: colorScheme.error),
                  ),
                ),
              ),

            // ── Equipment section ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 28, bottom: 8),
              child: Text(
                'cooking with',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: Equipment.values.map((eq) {
                  final selected = _selectedEquipment.contains(eq);
                  return FilterChip(
                    label: Text(_equipmentLabel(eq)),
                    selected: selected,
                    onSelected: (val) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        if (val) {
                          _selectedEquipment.add(eq);
                        } else {
                          _selectedEquipment.remove(eq);
                        }
                      });
                    },
                    selectedColor: colorScheme.primaryContainer,
                    checkmarkColor: colorScheme.primary,
                    labelStyle: TextStyle(
                      fontWeight: selected
                          ? FontWeight.w700
                          : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
            ),

            // ── Budget section ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 28, bottom: 8),
              child: Text(
                'extra budget',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [0, 30, 50, 100].map((amount) {
                final selected = _extraBudget == amount;
                return ChoiceChip(
                  label: Text('₱$amount'),
                  selected: selected,
                  onSelected: (val) {
                    if (val) setState(() => _extraBudget = amount);
                  },
                  selectedColor: colorScheme.primaryContainer,
                  labelStyle: TextStyle(
                    fontWeight: selected
                        ? FontWeight.w700
                        : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // ── OnDevice badge ───────────────────────────────────────────
            const OnDeviceBadgeConsumer(),
            const SizedBox(height: 16),

            // ── Find recipes CTA ─────────────────────────────────────────
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _selectedEquipment.isEmpty
                    ? null
                    : () => _saveAndNavigate(bundle),
                child: const Text(
                  'find a recipe',
                  style:
                      TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),

            if (_selectedEquipment.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Select at least one piece of equipment to continue.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant),
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
