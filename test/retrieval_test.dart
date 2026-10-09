// Tests for lib/domain/retrieval.dart — T2
// Covers every case from PRD §17.7.

import 'package:flutter_test/flutter_test.dart';
import 'package:snapfood/domain/models.dart';
import 'package:snapfood/domain/retrieval.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Build a minimal [Recipe] with sensible defaults.
Recipe _recipe({
  required String id,
  Set<Equipment>? equipment,
  List<RecipeIngredient>? ingredients,
  int minutes = 10,
}) {
  return Recipe(
    id: id,
    nameFil: id,
    nameEn: id,
    ingredients: ingredients ??
        [
          RecipeIngredient(
            ingredientId: 'rice',
            qty: 1,
            unit: 'cup',
            core: true,
          ),
        ],
    equipment: equipment ?? {Equipment.riceCooker},
    steps: ['Step 1.'],
    minutes: minutes,
    servings: 1,
  );
}

RecipeIngredient _ri(String id, {bool core = true}) =>
    RecipeIngredient(ingredientId: id, qty: 1, unit: 'pc', core: core);

Preferences _prefs({
  Set<Equipment>? equipment,
  int budget = 100,
}) =>
    Preferences(
      equipment: equipment ?? {Equipment.riceCooker},
      extraBudgetPesos: budget,
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('retrieve()', () {
    // 1. exact match ranks first
    test('exact match ranks first', () {
      final recipeAllOwned = _recipe(
        id: 'all_owned',
        ingredients: [_ri('rice'), _ri('egg')],
      );
      final recipeNoneOwned = _recipe(
        id: 'none_owned',
        ingredients: [_ri('chicken'), _ri('onion')],
      );

      final results = retrieve(
        [recipeNoneOwned, recipeAllOwned], // intentionally reversed
        [],
        {'rice': 10, 'egg': 5, 'chicken': 30, 'onion': 10},
        {'rice', 'egg'},
        _prefs(budget: 200),
      );

      expect(results.isNotEmpty, isTrue);
      expect(results.first.base.id, equals('all_owned'));
    });

    // 2. equipment filter excludes recipe
    test('equipment filter excludes recipe', () {
      final stoveRecipe = _recipe(
        id: 'stove_recipe',
        equipment: {Equipment.stove},
      );

      final results = retrieve(
        [stoveRecipe],
        [],
        {},
        {},
        _prefs(equipment: {Equipment.riceCooker}),
      );

      expect(results, isEmpty);
    });

    // 3. over-budget recipes are flagged and ranked after eligible
    test('over-budget recipes are flagged and ranked after eligible', () {
      // Eligible recipe: cheap missing ingredient
      final cheapRecipe = _recipe(
        id: 'cheap',
        ingredients: [_ri('rice'), _ri('salt', core: false)],
      );
      // Over-budget recipe: expensive missing ingredient
      final expensiveRecipe = _recipe(
        id: 'expensive',
        ingredients: [_ri('rice'), _ri('meat', core: false)],
      );

      final results = retrieve(
        [expensiveRecipe, cheapRecipe], // reversed order
        [],
        {'rice': 5, 'salt': 2, 'meat': 500},
        {'rice'}, // owns rice (core) so ratio = 1.0 for both
        _prefs(budget: 50),
      );

      expect(results.length, equals(2));
      // cheap comes first (eligible)
      expect(results[0].base.id, equals('cheap'));
      expect(results[0].flags, isNot(contains('overBudget')));
      // expensive is flagged
      expect(results[1].base.id, equals('expensive'));
      expect(results[1].flags, contains('overBudget'));
    });

    // 4. ties resolve by missingCost then minutes
    test('ties resolve by missingCost then minutes', () {
      // Two recipes, same ownedCoreRatio, different costs
      final costlyRecipe = _recipe(
        id: 'costly',
        ingredients: [_ri('rice'), _ri('meat', core: false)],
        minutes: 5,
      );
      final cheaperRecipe = _recipe(
        id: 'cheaper',
        ingredients: [_ri('rice'), _ri('salt', core: false)],
        minutes: 15,
      );

      final results = retrieve(
        [costlyRecipe, cheaperRecipe],
        [],
        {'rice': 5, 'meat': 40, 'salt': 2},
        {'rice'},
        _prefs(budget: 200),
      );

      // cheaper (lower missing cost) ranks first despite more minutes
      expect(results[0].base.id, equals('cheaper'));

      // Now test that equal cost resolves by minutes
      final fast = _recipe(
        id: 'fast',
        ingredients: [_ri('rice'), _ri('egg', core: false)],
        minutes: 5,
      );
      final slow = _recipe(
        id: 'slow',
        ingredients: [_ri('rice'), _ri('egg2', core: false)],
        minutes: 30,
      );

      final results2 = retrieve(
        [slow, fast],
        [],
        {'rice': 5, 'egg': 10, 'egg2': 10},
        {'rice'},
        _prefs(budget: 200),
      );

      expect(results2[0].base.id, equals('fast'));
    });

    // 5. empty owned set returns flagged results without error
    test('empty owned set returns flagged results without error', () {
      final r = _recipe(
        id: 'r1',
        ingredients: [_ri('rice'), _ri('egg')],
      );

      List<RecipeResult>? results;
      expect(
        () {
          results = retrieve(
            [r],
            [],
            {'rice': 10, 'egg': 5},
            {}, // empty owned set
            _prefs(budget: 5), // tight budget so overBudget fires
          );
        },
        returnsNormally,
      );

      expect(results, isNotNull);
      expect(results!.isNotEmpty, isTrue);
      // All ingredients are missing so lowMatch (ratio 0.0 < 0.5) fires
      expect(
        results!.first.flags.any((f) => f == 'lowMatch' || f == 'overBudget'),
        isTrue,
      );
    });

    // 6. no equipment match returns empty list
    test('no equipment match returns empty list', () {
      final stoveRecipe = _recipe(
        id: 'stove',
        equipment: {Equipment.stove},
      );

      final results = retrieve(
        [stoveRecipe],
        [],
        {},
        {},
        _prefs(equipment: {Equipment.kettle}),
      );

      expect(results, isEmpty);
    });

    // 7. same input always gives same output
    test('same input always gives same output', () {
      final recipes = [
        _recipe(id: 'a', ingredients: [_ri('rice'), _ri('egg')]),
        _recipe(id: 'b', ingredients: [_ri('chicken')]),
        _recipe(id: 'c', ingredients: [_ri('tofu')]),
      ];
      final prices = {'rice': 10, 'egg': 5, 'chicken': 30, 'tofu': 20};
      final owned = {'rice'};
      final prefs = _prefs(budget: 50);

      final r1 = retrieve(recipes, [], prices, owned, prefs);
      final r2 = retrieve(recipes, [], prices, owned, prefs);

      expect(r1.length, equals(r2.length));
      for (var i = 0; i < r1.length; i++) {
        expect(r1[i].base.id, equals(r2[i].base.id));
        expect(r1[i].estimatedExtraPesos, equals(r2[i].estimatedExtraPesos));
        expect(r1[i].flags, equals(r2[i].flags));
      }
    });

    // 8. unpriced missing ingredient adds unpricedItem flag
    test('unpriced missing ingredient adds unpricedItem flag', () {
      final r = _recipe(
        id: 'unpriced',
        ingredients: [_ri('rice'), _ri('mystery')],
      );

      final results = retrieve(
        [r],
        [],
        {'rice': 10}, // 'mystery' has no price entry
        {'rice'},     // owns rice (core), ratio = 1.0
        _prefs(budget: 200),
      );

      expect(results.isNotEmpty, isTrue);
      expect(results.first.flags, contains('unpricedItem'));
    });
  });
}
