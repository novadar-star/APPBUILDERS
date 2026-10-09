// ReviewScreen — T9
// Confirm owned ingredients + set preferences.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snapfood/app/providers.dart';
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

  // Local preference state — will be initialised from provider.
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

  // ── helpers ─────────────────────────────────────────────────────────────

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
    final owned = ref.read(ownedIngredientsProvider);
    ref.read(ownedIngredientsProvider.notifier).state = owned;
    final prefs = Preferences(
      equipment: _selectedEquipment,
      extraBudgetPesos: _extraBudget,
    );
    await PreferencesStore().save(prefs);
    if (mounted) context.go('/results');
  }

  // ── build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bundleAsync = ref.watch(appBundleProvider);
    final ownedIds = ref.watch(ownedIngredientsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review'),
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
    // Search results — match against nameFil, nameEn, aliases.
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── SAMPLE DATA ──────────────────────────────────────────────
            const SampleNotice(),
            const SizedBox(height: 16),

            // ── Heading ──────────────────────────────────────────────────
            Text(
              'Confirm what you have',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0E3D2A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Detected items are suggestions. Tap × to remove, or search to add.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 14),

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
                    avatar: const Icon(Icons.check,
                        size: 16, color: Color(0xFF1C684E)),
                    label: Text(label),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () {
                      final next = Set<String>.from(ownedIds)..remove(id);
                      ref.read(ownedIngredientsProvider.notifier).state = next;
                    },
                    backgroundColor: const Color(0xFFE5EEE5),
                    labelStyle: const TextStyle(fontSize: 13),
                  );
                }).toList(),
              ),
            if (ownedIds.isEmpty)
              Text(
                'No ingredients confirmed yet. Use scan or search below.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.grey[500]),
              ),
            const SizedBox(height: 14),

            // ── Search field ─────────────────────────────────────────────
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search ingredients (Filipino or English)…',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE8E6DE)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE8E6DE)),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE8E6DE)),
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
                          style: const TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.add_circle_outline,
                          size: 20, color: Color(0xFF1C684E)),
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
                  child: const Text(
                    'Clear all',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),

            const Divider(height: 28),

            // ── Equipment section ────────────────────────────────────────
            Text(
              'Cooking equipment',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0E3D2A),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: Equipment.values.map((eq) {
                final selected = _selectedEquipment.contains(eq);
                return FilterChip(
                  label: Text(_equipmentLabel(eq)),
                  selected: selected,
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        _selectedEquipment.add(eq);
                      } else {
                        _selectedEquipment.remove(eq);
                      }
                    });
                  },
                  selectedColor: const Color(0xFFD4EBD8),
                  checkmarkColor: const Color(0xFF1C684E),
                  labelStyle: TextStyle(
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // ── Budget section ───────────────────────────────────────────
            Text(
              'Extra budget',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0E3D2A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'How much can you spend on missing ingredients?',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 10),
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
                  selectedColor: const Color(0xFFD4EBD8),
                  labelStyle: TextStyle(
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

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
                  'Find recipes',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),

            if (_selectedEquipment.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Select at least one piece of equipment to continue.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.grey[600]),
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
