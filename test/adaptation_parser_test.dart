// Tests for lib/domain/adaptation_parser.dart — T4

import 'package:flutter_test/flutter_test.dart';
import 'package:snapfood/domain/models.dart';
import 'package:snapfood/domain/adaptation_parser.dart';

// ---------------------------------------------------------------------------
// Sample valid output
// ---------------------------------------------------------------------------

const _validOutput = '''
NAME: Garlic Fried Rice
TIME: 15
INGREDIENTS:
- owned | 2 cups | rice
- sub | 2 cloves | garlic_powder | replaces garlic
- buy | 1 tbsp | oil
STEPS:
1. Heat rice cooker.
2. Add rice and water.
3. Fluff and serve.
NOTES: Quick and easy dorm recipe.
END
''';

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('parseAdaptedRecipe()', () {
    test('parses valid complete output correctly', () {
      final result = parseAdaptedRecipe(_validOutput);
      expect(result.success, isTrue);
      expect(result.recipe, isNotNull);
      expect(result.recipe!.name, equals('Garlic Fried Rice'));
      expect(result.recipe!.minutes, equals(15));
      expect(result.recipe!.steps.length, equals(3));
      expect(result.recipe!.notes, equals('Quick and easy dorm recipe.'));
    });

    test('parses owned sub and buy ingredient types', () {
      final result = parseAdaptedRecipe(_validOutput);
      expect(result.success, isTrue);
      final ings = result.recipe!.ingredients;
      expect(ings.length, equals(3));
      expect(
        ings.any((i) => i.ingredientId == 'rice' && i.source == IngredientSource.owned),
        isTrue,
      );
      expect(
        ings.any((i) =>
            i.ingredientId == 'garlic_powder' &&
            i.source == IngredientSource.substituted),
        isTrue,
      );
      expect(
        ings.any((i) => i.ingredientId == 'oil' && i.source == IngredientSource.toBuy),
        isTrue,
      );
    });

    test('handles case-insensitive markers', () {
      const caseVariant = '''
name: Scrambled Eggs
time: 5
ingredients:
- OWNED | 2 pcs | egg
steps:
1. Crack eggs.
2. Cook in microwave.
3. Season.
notes: Fast and filling.
END
''';
      final result = parseAdaptedRecipe(caseVariant);
      expect(result.success, isTrue);
      expect(result.recipe!.name, equals('Scrambled Eggs'));
      expect(result.recipe!.minutes, equals(5));
    });

    test('strips markdown fences', () {
      const fenced = '''
```
NAME: Oatmeal
TIME: 5
INGREDIENTS:
- owned | 1 cup | oats
STEPS:
1. Boil water.
2. Add oats.
3. Stir.
NOTES: Simple.
END
```
''';
      final result = parseAdaptedRecipe(fenced);
      expect(result.success, isTrue);
      expect(result.recipe!.name, equals('Oatmeal'));
    });

    test('missing END returns error', () {
      const noEnd = '''
NAME: Test
TIME: 10
INGREDIENTS:
- owned | 1 cup | rice
STEPS:
1. Cook rice.
NOTES: none.
''';
      final result = parseAdaptedRecipe(noEnd);
      expect(result.success, isFalse);
      expect(result.errors.any((e) => e.contains('END')), isTrue);
    });

    test('missing NAME returns error', () {
      const noName = '''
TIME: 10
INGREDIENTS:
- owned | 1 cup | rice
STEPS:
1. Cook rice.
NOTES: none.
END
''';
      final result = parseAdaptedRecipe(noName);
      expect(result.success, isFalse);
      expect(result.errors.any((e) => e.contains('NAME')), isTrue);
    });

    test('invalid ingredient type returns error', () {
      const badType = '''
NAME: Test
TIME: 10
INGREDIENTS:
- unknown | 1 cup | rice
STEPS:
1. Cook rice.
NOTES: none.
END
''';
      final result = parseAdaptedRecipe(badType);
      expect(result.success, isFalse);
      expect(result.errors.any((e) => e.contains('unknown')), isTrue);
    });

    test('sub line with replaces parses replacesId correctly', () {
      final result = parseAdaptedRecipe(_validOutput);
      expect(result.success, isTrue);
      final subIng = result.recipe!.ingredients.firstWhere(
        (i) => i.source == IngredientSource.substituted,
      );
      expect(subIng.replacesId, equals('garlic'));
    });
  });
}
