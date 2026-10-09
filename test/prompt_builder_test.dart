// Tests for lib/domain/prompt_builder.dart — T4

import 'package:flutter_test/flutter_test.dart';
import 'package:snapfood/domain/models.dart';
import 'package:snapfood/domain/prompt_builder.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Recipe _baseRecipe() => Recipe(
      id: 'sinangag',
      nameFil: 'Sinangag',
      nameEn: 'Garlic Fried Rice',
      ingredients: [
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
      steps: ['Heat oil in pan.', 'Saute garlic until golden.', 'Add rice and stir.'],
      minutes: 15,
      servings: 2,
    );

AdaptRequest _request({
  Set<String>? ownedIds,
  Set<Equipment>? equipment,
}) {
  return AdaptRequest(
    base: _baseRecipe(),
    ownedIds: ownedIds ?? {'rice', 'garlic'},
    prefs: Preferences(
      equipment: equipment ?? {Equipment.stove},
      extraBudgetPesos: 50,
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('buildPrompt()', () {
    test('buildPrompt includes system message', () {
      final prompt = buildPrompt(_request(), []);
      expect(prompt, contains('[SYSTEM]'));
      expect(prompt, contains('You adapt Filipino home recipes'));
      expect(prompt, contains('Output nothing before NAME and nothing after END'));
    });

    test('buildPrompt includes USER HAS section with owned ids', () {
      final prompt = buildPrompt(
        _request(ownedIds: {'rice', 'garlic', 'oil'}),
        [],
      );
      expect(prompt, contains('USER HAS:'));
      expect(prompt, contains('rice'));
      expect(prompt, contains('garlic'));
      expect(prompt, contains('oil'));
    });

    test('buildPrompt includes EQUIPMENT section', () {
      final prompt = buildPrompt(
        _request(equipment: {Equipment.stove, Equipment.kettle}),
        [],
      );
      expect(prompt, contains('EQUIPMENT:'));
      expect(prompt, contains('stove'));
      expect(prompt, contains('kettle'));
    });

    test('buildPrompt includes all base ingredients', () {
      final prompt = buildPrompt(_request(), []);
      expect(prompt, contains('rice'));
      expect(prompt, contains('garlic'));
      expect(prompt, contains('oil'));
      // core / optional flags
      expect(prompt, contains('core'));
      expect(prompt, contains('optional'));
    });

    test('buildPrompt includes output format block with NAME TIME INGREDIENTS STEPS NOTES END markers', () {
      final prompt = buildPrompt(_request(), []);
      expect(prompt, contains('Output format:'));
      expect(prompt, contains('NAME:'));
      expect(prompt, contains('TIME:'));
      expect(prompt, contains('INGREDIENTS:'));
      expect(prompt, contains('STEPS:'));
      expect(prompt, contains('NOTES:'));
      expect(prompt, contains('END'));
    });

    test('buildPrompt is deterministic — same input gives same output', () {
      final req = _request();
      final vocab = <Ingredient>[];
      final first = buildPrompt(req, vocab);
      final second = buildPrompt(req, vocab);
      expect(first, equals(second));
    });
  });
}
