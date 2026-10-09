// Retrieval logic — T2

import 'models.dart';

/// Returns up to [limit] [RecipeResult]s ranked by eligibility, owned-core
/// ratio, missing cost, and cooking time.
///
/// Algorithm follows PRD §17.7.
List<RecipeResult> retrieve(
  List<Recipe> recipes,
  List<Ingredient> ingredients,
  Map<String, int> prices,
  Set<String> ownedIds,
  Preferences prefs, {
  int limit = 3,
}) {
  // 1. Equipment filter — keep only recipes whose equipment set intersects
  //    the user's available equipment.
  final candidates = recipes.where((r) {
    return r.equipment.any((e) => prefs.equipment.contains(e));
  }).toList();

  if (candidates.isEmpty) return [];

  // 2. Score each candidate.
  final scored = candidates.map((recipe) => _score(recipe, prices, ownedIds, prefs)).toList();

  // 3. Sort: eligible first, then by ownedCoreRatio desc, missingCost asc,
  //    minutes asc.
  scored.sort((a, b) {
    // eligible before ineligible
    if (a.eligible != b.eligible) {
      return a.eligible ? -1 : 1;
    }
    // higher ownedCoreRatio first
    final ratioCmp = b.ownedCoreRatio.compareTo(a.ownedCoreRatio);
    if (ratioCmp != 0) return ratioCmp;
    // lower missingCost first
    final costCmp = a.missingCost.compareTo(b.missingCost);
    if (costCmp != 0) return costCmp;
    // fewer minutes first
    return a.recipe.minutes.compareTo(b.recipe.minutes);
  });

  // 4. Take at most [limit] results.
  return scored.take(limit).map((s) {
    final flags = <String>[
      if (s.overBudget) 'overBudget',
      if (s.lowMatch) 'lowMatch',
      if (s.unpricedItem) 'unpricedItem',
    ];
    return RecipeResult(
      kind: ResultKind.adapted,
      base: s.recipe,
      adapted: null,
      estimatedExtraPesos: s.missingCost,
      flags: flags,
    );
  }).toList();
}

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

class _ScoredRecipe {
  final Recipe recipe;
  final double ownedCoreRatio;
  final int missingCost;
  final bool overBudget;
  final bool lowMatch;
  final bool unpricedItem;
  final bool eligible;

  const _ScoredRecipe({
    required this.recipe,
    required this.ownedCoreRatio,
    required this.missingCost,
    required this.overBudget,
    required this.lowMatch,
    required this.unpricedItem,
    required this.eligible,
  });
}

_ScoredRecipe _score(
  Recipe recipe,
  Map<String, int> prices,
  Set<String> ownedIds,
  Preferences prefs,
) {
  // 2a. Core ingredients
  final coreIngredients =
      recipe.ingredients.where((ri) => ri.core).toList();

  // 2b. How many core ingredients does the user already own?
  final ownedCoreCount =
      coreIngredients.where((ri) => ownedIds.contains(ri.ingredientId)).length;

  // 2c. Owned-core ratio (0.0 when there are no core ingredients)
  final ownedCoreRatio = coreIngredients.isEmpty
      ? 0.0
      : ownedCoreCount / coreIngredients.length;

  // 2d. Missing ingredients (user does not own them)
  final missingIngredients =
      recipe.ingredients.where((ri) => !ownedIds.contains(ri.ingredientId)).toList();

  // 2e. Missing cost + unpriced flag
  var missingCost = 0;
  var unpricedItem = false;
  for (final ri in missingIngredients) {
    final price = prices[ri.ingredientId];
    if (price == null) {
      unpricedItem = true;
    } else {
      missingCost += price;
    }
  }

  // 2f–2h. Flags and eligibility
  final overBudget = missingCost > prefs.extraBudgetPesos;
  final lowMatch = ownedCoreRatio < 0.5;
  final eligible = !overBudget && !lowMatch;

  return _ScoredRecipe(
    recipe: recipe,
    ownedCoreRatio: ownedCoreRatio,
    missingCost: missingCost,
    overBudget: overBudget,
    lowMatch: lowMatch,
    unpricedItem: unpricedItem,
    eligible: eligible,
  );
}
