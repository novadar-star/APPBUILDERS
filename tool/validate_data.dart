import 'dart:convert';
import 'dart:io';

// ---------------------------------------------------------------------------
// Pure validation logic — imported by tests as well as main()
// ---------------------------------------------------------------------------

/// Runs all PRD-17.5 validation rules against raw JSON strings.
/// Returns an empty list if everything passes, or a list of failure messages.
List<String> validateData({
  required String ingredientsJson,
  required String recipesJson,
  required String pricesJson,
}) {
  final errors = <String>[];

  final ingredients = (jsonDecode(ingredientsJson) as List)
      .cast<Map<String, dynamic>>();
  final recipes = (jsonDecode(recipesJson) as List)
      .cast<Map<String, dynamic>>();
  final priceData = jsonDecode(pricesJson) as Map<String, dynamic>;

  final ingredientIds =
      ingredients.map((item) => item['id'] as String).toSet();

  // Build price set: ingredientId -> true
  final pricedIds = ((priceData['entries'] as List)
          .cast<Map<String, dynamic>>())
      .map((e) => e['ingredientId'] as String)
      .toSet();

  for (final recipe in recipes) {
    final label = recipe['id'] as String;

    // Rule: non-empty equipment list
    final equipment = recipe['equipment'] as List;
    if (equipment.isEmpty) {
      errors.add('$label: no equipment');
    }

    // Rule: non-empty steps
    final steps = recipe['steps'] as List;
    if (steps.isEmpty) {
      errors.add('$label: no steps');
    }

    final items = (recipe['ingredients'] as List).cast<Map<String, dynamic>>();

    // Rule: at least one core ingredient
    if (!items.any((item) => item['core'] == true)) {
      errors.add('$label: no core ingredient');
    }

    for (final item in items) {
      final id = item['ingredientId'] as String;

      // Rule: every ingredientId exists in ingredients
      if (!ingredientIds.contains(id)) {
        errors.add('$label: unknown ingredient $id');
      }

      // Rule: every core ingredient has a price entry
      if (item['core'] == true && !pricedIds.contains(id)) {
        errors.add('$label: no price for core ingredient $id');
      }
    }
  }

  return errors;
}

// ---------------------------------------------------------------------------
// CLI entry point
// ---------------------------------------------------------------------------
void main() {
  final ingredientsJson =
      File('assets/data/ingredients.json').readAsStringSync();
  final recipesJson = File('assets/data/recipes.json').readAsStringSync();
  final pricesJson = File('assets/data/prices.json').readAsStringSync();

  final errors = validateData(
    ingredientsJson: ingredientsJson,
    recipesJson: recipesJson,
    pricesJson: pricesJson,
  );

  if (errors.isNotEmpty) {
    stderr.writeln(errors.join('\n'));
    exitCode = 1;
    return;
  }

  final ingredients =
      (jsonDecode(ingredientsJson) as List).cast<Map<String, dynamic>>();
  final recipes =
      (jsonDecode(recipesJson) as List).cast<Map<String, dynamic>>();

  stdout.writeln(
    'PASS — ${ingredients.length} ingredients, ${recipes.length} recipes.',
  );
}
