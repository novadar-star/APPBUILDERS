// Tests for lib/domain/adaptation_validator.dart — T4

import 'package:flutter_test/flutter_test.dart';
import 'package:snapfood/domain/models.dart';
import 'package:snapfood/domain/adaptation_validator.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Recipe _baseRecipe({List<RecipeIngredient>? ingredients}) => Recipe(
      id: 'sinangag',
      nameFil: 'Sinangag',
      nameEn: 'Garlic Fried Rice',
      ingredients: ingredients ??
          [
            RecipeIngredient(
              ingredientId: 'rice',
              qty: 2,
              unit: 'cups',
              core: true,
            ),
            RecipeIngredient(
              ingredientId: 'garlic',
              qty: 4,
              unit: 'cloves',
              core: true,
            ),
            RecipeIngredient(
              ingredientId: 'oil',
              qty: 1,
              unit: 'tbsp',
              core: false,
            ),
          ],
      equipment: {Equipment.stove},
      steps: ['Heat oil.', 'Saute garlic.', 'Add rice.'],
      minutes: 15,
      servings: 2,
    );

AdaptRequest _request({
  Set<String>? ownedIds,
  Set<Equipment>? equipment,
  Recipe? base,
}) =>
    AdaptRequest(
      base: base ?? _baseRecipe(),
      ownedIds: ownedIds ?? {'rice', 'garlic'},
      prefs: Preferences(
        equipment: equipment ?? {Equipment.stove},
        extraBudgetPesos: 100,
      ),
    );

AdaptedRecipe _adapted({
  String name = 'Garlic Fried Rice',
  int minutes = 15,
  List<AdaptedIngredient>? ingredients,
  List<String>? steps,
  String notes = 'Good.',
}) =>
    AdaptedRecipe(
      name: name,
      minutes: minutes,
      ingredients: ingredients ??
          [
            AdaptedIngredient(
              ingredientId: 'rice',
              qtyText: '2 cups',
              source: IngredientSource.owned,
            ),
            AdaptedIngredient(
              ingredientId: 'garlic',
              qtyText: '4 cloves',
              source: IngredientSource.owned,
            ),
            AdaptedIngredient(
              ingredientId: 'oil',
              qtyText: '1 tbsp',
              source: IngredientSource.toBuy,
            ),
          ],
      steps: steps ?? ['Cook in pan.', 'Stir fry.', 'Serve hot.'],
      notes: notes,
    );

const _vocab = {'rice', 'garlic', 'oil', 'garlic_powder', 'soy_sauce'};
const _prices = {'oil': 20, 'garlic': 5, 'rice': 10, 'garlic_powder': 15};

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('validateAdaptedRecipe()', () {
    // V1
    test('V1 fails when name is empty', () {
      final errors = validateAdaptedRecipe(
        _adapted(name: ''),
        _request(),
        _vocab,
        _prices,
      );
      expect(errors.any((e) => e.contains('V1') && e.contains('NAME')), isTrue);
    });

    test('V1 fails when no ingredients', () {
      final errors = validateAdaptedRecipe(
        _adapted(ingredients: []),
        _request(),
        _vocab,
        _prices,
      );
      expect(errors.any((e) => e.contains('V1') && e.contains('ingredient')), isTrue);
    });

    test('V1 fails when no steps', () {
      final errors = validateAdaptedRecipe(
        _adapted(steps: []),
        _request(),
        _vocab,
        _prices,
      );
      expect(errors.any((e) => e.contains('V1') && e.contains('step')), isTrue);
    });

    // V2
    test('V2 fails when ingredient id not in vocabulary', () {
      final errors = validateAdaptedRecipe(
        _adapted(ingredients: [
          AdaptedIngredient(
            ingredientId: 'unknown_thing',
            qtyText: '1 cup',
            source: IngredientSource.owned,
          ),
          AdaptedIngredient(
            ingredientId: 'garlic',
            qtyText: '4 cloves',
            source: IngredientSource.owned,
          ),
        ]),
        _request(),
        _vocab,
        _prices,
      );
      expect(errors.any((e) => e.contains('V2') && e.contains('unknown_thing')), isTrue);
    });

    // V3
    test('V3 fails when owned ingredient not in ownedIds', () {
      final errors = validateAdaptedRecipe(
        _adapted(ingredients: [
          // garlic marked owned but user only owns rice
          AdaptedIngredient(
            ingredientId: 'garlic',
            qtyText: '4 cloves',
            source: IngredientSource.owned,
          ),
          AdaptedIngredient(
            ingredientId: 'rice',
            qtyText: '2 cups',
            source: IngredientSource.owned,
          ),
        ]),
        _request(ownedIds: {'rice'}), // garlic NOT in owned
        _vocab,
        _prices,
      );
      expect(errors.any((e) => e.contains('V3') && e.contains('garlic')), isTrue);
    });

    // V4
    test('V4 adds warning when toBuy ingredient has no price', () {
      final errors = validateAdaptedRecipe(
        _adapted(ingredients: [
          AdaptedIngredient(
            ingredientId: 'rice',
            qtyText: '2 cups',
            source: IngredientSource.owned,
          ),
          AdaptedIngredient(
            ingredientId: 'garlic',
            qtyText: '4 cloves',
            source: IngredientSource.owned,
          ),
          AdaptedIngredient(
            ingredientId: 'soy_sauce', // no price in _prices
            qtyText: '2 tbsp',
            source: IngredientSource.toBuy,
          ),
        ]),
        _request(),
        _vocab,
        <String, int>{}, // empty prices map → unpriced
      );
      expect(
        errors.any((e) => e.startsWith('WARNING:') && e.contains('soy_sauce')),
        isTrue,
      );
      // must be a WARNING, not a blocking error
      expect(errors.every((e) => e.startsWith('WARNING:') || !e.contains('V4')), isTrue);
    });

    // V5
    test('V5 fails when sub replacesId not in base recipe', () {
      final errors = validateAdaptedRecipe(
        _adapted(ingredients: [
          AdaptedIngredient(
            ingredientId: 'garlic_powder',
            qtyText: '1 tsp',
            source: IngredientSource.substituted,
            replacesId: 'onion', // onion is NOT in base recipe
          ),
          AdaptedIngredient(
            ingredientId: 'rice',
            qtyText: '2 cups',
            source: IngredientSource.owned,
          ),
        ]),
        _request(ownedIds: {'rice', 'garlic_powder'}),
        _vocab,
        _prices,
      );
      expect(
        errors.any((e) => e.contains('V5') && e.contains('onion')),
        isTrue,
      );
    });

    test('V5 fails when substitute id not in ownedIds', () {
      final errors = validateAdaptedRecipe(
        _adapted(ingredients: [
          AdaptedIngredient(
            ingredientId: 'garlic_powder',
            qtyText: '1 tsp',
            source: IngredientSource.substituted,
            replacesId: 'garlic',
          ),
          AdaptedIngredient(
            ingredientId: 'rice',
            qtyText: '2 cups',
            source: IngredientSource.owned,
          ),
        ]),
        _request(ownedIds: {'rice'}), // garlic_powder NOT owned
        _vocab,
        _prices,
      );
      expect(
        errors.any((e) => e.contains('V5') && e.contains('garlic_powder')),
        isTrue,
      );
    });

    // V6
    test('V6 fails when step mentions oven', () {
      final errors = validateAdaptedRecipe(
        _adapted(steps: ['Preheat the oven.', 'Bake for 10 minutes.', 'Serve.']),
        _request(),
        _vocab,
        _prices,
      );
      expect(errors.any((e) => e.contains('V6') && e.contains('oven')), isTrue);
    });

    test('V6 fails when step mentions equipment not in prefs', () {
      final errors = validateAdaptedRecipe(
        _adapted(steps: ['Heat water in kettle.', 'Pour over rice.', 'Serve.']),
        _request(equipment: {Equipment.stove}), // kettle NOT in prefs
        _vocab,
        _prices,
      );
      expect(errors.any((e) => e.contains('V6') && e.contains('kettle')), isTrue);
    });

    // V7
    test('V7 fails when core ingredient is missing from output', () {
      final errors = validateAdaptedRecipe(
        _adapted(ingredients: [
          // rice included, but garlic (core) is missing
          AdaptedIngredient(
            ingredientId: 'rice',
            qtyText: '2 cups',
            source: IngredientSource.owned,
          ),
        ]),
        _request(),
        _vocab,
        _prices,
      );
      expect(errors.any((e) => e.contains('V7') && e.contains('garlic')), isTrue);
    });

    // V8
    test('V8 fails when TIME is 0', () {
      final errors = validateAdaptedRecipe(
        _adapted(minutes: 0),
        _request(),
        _vocab,
        _prices,
      );
      expect(errors.any((e) => e.contains('V8')), isTrue);
    });

    test('V8 fails when TIME is 181', () {
      final errors = validateAdaptedRecipe(
        _adapted(minutes: 181),
        _request(),
        _vocab,
        _prices,
      );
      expect(errors.any((e) => e.contains('V8')), isTrue);
    });

    test('valid adapted recipe passes all validators', () {
      final errors = validateAdaptedRecipe(
        _adapted(),
        _request(),
        _vocab,
        _prices,
      );
      // Only non-blocking warnings allowed (if any); no blocking errors
      final blockingErrors = errors.where((e) => !e.startsWith('WARNING:')).toList();
      expect(blockingErrors, isEmpty);
    });
  });
}
