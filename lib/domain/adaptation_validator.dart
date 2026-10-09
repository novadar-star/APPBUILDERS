// Adaptation validator — T4
// Runs validators V1–V8 from PRD §17.8.

import 'models.dart';

/// Validates [adapted] against [request] and the known [vocabularyIds].
/// [prices] is used to detect unpriced toBuy items (V4).
/// [endReached] must be true for V1 to pass (signals the END marker was present).
///
/// Returns a list of strings:
///   - Plain strings are blocking errors.
///   - Strings prefixed 'WARNING:' are non-blocking flags.
List<String> validateAdaptedRecipe(
  AdaptedRecipe adapted,
  AdaptRequest request,
  Set<String> vocabularyIds,
  Map<String, int> prices, {
  bool endReached = true,
}) {
  final errors = <String>[];

  // ── V1: structural completeness ──────────────────────────────────────────
  if (adapted.name.isEmpty) {
    errors.add('V1: NAME is empty');
  }
  if (adapted.ingredients.isEmpty) {
    errors.add('V1: no ingredients in output');
  }
  if (adapted.steps.isEmpty) {
    errors.add('V1: no steps in output');
  }
  if (!endReached) {
    errors.add('V1: END marker not reached');
  }

  // ── V2: all ingredient ids exist in vocabulary ───────────────────────────
  for (final ing in adapted.ingredients) {
    if (!vocabularyIds.contains(ing.ingredientId)) {
      errors.add('V2: unknown ingredient id "${ing.ingredientId}"');
    }
  }

  // ── V3: owned ingredients are actually owned ─────────────────────────────
  for (final ing in adapted.ingredients) {
    if (ing.source == IngredientSource.owned) {
      if (!request.ownedIds.contains(ing.ingredientId)) {
        errors.add(
          'V3: ingredient "${ing.ingredientId}" marked owned but not in ownedIds',
        );
      }
    }
  }

  // ── V4: toBuy items should ideally have prices ───────────────────────────
  for (final ing in adapted.ingredients) {
    if (ing.source == IngredientSource.toBuy) {
      if (request.ownedIds.contains(ing.ingredientId)) {
        errors.add(
          'V4: ingredient "${ing.ingredientId}" marked toBuy but is in ownedIds',
        );
      }
      if (!prices.containsKey(ing.ingredientId)) {
        // WARNING — non-blocking
        errors.add('WARNING: unpricedItem:${ing.ingredientId}');
      }
    }
  }

  // ── V5: substituted ingredients ──────────────────────────────────────────
  final baseIngredientIds =
      request.base.ingredients.map((ri) => ri.ingredientId).toSet();
  for (final ing in adapted.ingredients) {
    if (ing.source == IngredientSource.substituted) {
      if (ing.replacesId == null) {
        errors.add(
          'V5: sub ingredient "${ing.ingredientId}" has no replacesId',
        );
      } else if (!baseIngredientIds.contains(ing.replacesId)) {
        errors.add(
          'V5: sub ingredient "${ing.ingredientId}" replacesId '
          '"${ing.replacesId}" not found in base recipe',
        );
      }
      if (!request.ownedIds.contains(ing.ingredientId)) {
        errors.add(
          'V5: sub ingredient "${ing.ingredientId}" is not in ownedIds',
        );
      }
    }
  }

  // ── V6: steps must not mention forbidden equipment ───────────────────────
  final allStepsText = adapted.steps.join(' ').toLowerCase();

  // Always-forbidden terms (regardless of prefs)
  const alwaysForbidden = ['oven', 'air fryer', 'grill', 'blender'];
  for (final term in alwaysForbidden) {
    if (_wordBoundaryMatch(allStepsText, term)) {
      errors.add('V6: steps mention forbidden equipment "$term"');
    }
  }

  // Equipment-specific keywords — only an error when NOT in prefs
  final equippedSet = request.prefs.equipment;

  final equipmentKeywords = <Equipment, List<String>>{
    Equipment.riceCooker: ['rice cooker', 'rice-cooker'],
    Equipment.kettle: ['kettle'],
    Equipment.microwave: ['microwave'],
    Equipment.stove: ['stove', 'stovetop', 'pan', 'frying pan', 'wok'],
  };

  for (final entry in equipmentKeywords.entries) {
    if (equippedSet.contains(entry.key)) continue; // allowed
    for (final keyword in entry.value) {
      if (_wordBoundaryMatch(allStepsText, keyword)) {
        errors.add(
          'V6: steps mention "${keyword}" but '
          '${_equipmentName(entry.key)} is not in equipment prefs',
        );
        break; // one error per equipment type is enough
      }
    }
  }

  // ── V7: every core base ingredient must appear in output ─────────────────
  final outputIds =
      adapted.ingredients.map((i) => i.ingredientId).toSet();
  final outputReplacedIds = adapted.ingredients
      .where((i) => i.replacesId != null)
      .map((i) => i.replacesId!)
      .toSet();
  final coveredIds = outputIds.union(outputReplacedIds);

  for (final ri in request.base.ingredients) {
    if (!ri.core) continue;
    if (!coveredIds.contains(ri.ingredientId)) {
      errors.add(
        'V7: core ingredient "${ri.ingredientId}" missing from output',
      );
    }
  }

  // ── V8: TIME must be an integer in [1, 180] ──────────────────────────────
  if (adapted.minutes < 1 || adapted.minutes > 180) {
    errors.add(
      'V8: TIME ${adapted.minutes} is out of range [1, 180]',
    );
  }

  return errors;
}

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

bool _wordBoundaryMatch(String text, String pattern) {
  // Escape regex special characters in the pattern
  final escaped = RegExp.escape(pattern);
  // Use word boundary where possible; for multi-word phrases use spaces/start/end
  final regex = RegExp(r'(?<![a-z])' + escaped + r'(?![a-z])', caseSensitive: false);
  return regex.hasMatch(text);
}

String _equipmentName(Equipment e) {
  switch (e) {
    case Equipment.riceCooker:
      return 'rice_cooker';
    case Equipment.kettle:
      return 'kettle';
    case Equipment.microwave:
      return 'microwave';
    case Equipment.stove:
      return 'stove';
  }
}
