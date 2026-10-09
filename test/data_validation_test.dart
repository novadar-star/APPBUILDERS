import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';

// Pull in the pure validation function directly from the tool script.
// We use a relative import so the test runner can find it without pub.
// ignore: depend_on_referenced_packages
import '../tool/validate_data.dart' show validateData;

// ---------------------------------------------------------------------------
// Helpers to build minimal valid JSON strings
// ---------------------------------------------------------------------------

String _ingredients([List<Map<String, dynamic>>? extra]) {
  final base = <Map<String, dynamic>>[
    {
      'id': 'itlog',
      'nameFil': 'Itlog',
      'nameEn': 'Egg',
      'aliases': ['eggs'],
    },
    {
      'id': 'mantika',
      'nameFil': 'Mantika',
      'nameEn': 'Cooking oil',
      'aliases': ['oil'],
    },
  ];
  return jsonEncode([...base, ...(extra ?? [])]);
}

String _prices([List<Map<String, dynamic>>? extra]) {
  final base = <Map<String, dynamic>>[
    {'ingredientId': 'itlog', 'pesos': 12, 'portion': '1 pc'},
    {'ingredientId': 'mantika', 'pesos': 2, 'portion': '1 tsp'},
  ];
  return jsonEncode({
    'collectedOn': 'test',
    'entries': [...base, ...(extra ?? [])],
  });
}

String _recipes(List<Map<String, dynamic>> recipes) => jsonEncode(recipes);

Map<String, dynamic> _validRecipe() => {
      'id': 'r_test',
      'nameFil': 'Test',
      'nameEn': 'Test',
      'equipment': ['stove'],
      'minutes': 10,
      'servings': 1,
      'ingredients': [
        {'ingredientId': 'itlog', 'qty': 1, 'unit': 'pc', 'core': true},
        {'ingredientId': 'mantika', 'qty': 1, 'unit': 'tsp', 'core': false},
      ],
      'steps': ['Step one.'],
    };

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('validateData', () {
    test('valid data passes with no errors', () {
      final errors = validateData(
        ingredientsJson: _ingredients(),
        recipesJson: _recipes([_validRecipe()]),
        pricesJson: _prices(),
      );
      expect(errors, isEmpty);
    });

    test('recipe with unknown ingredient id fails', () {
      final recipe = _validRecipe()
        ..['ingredients'] = [
          {'ingredientId': 'ghost', 'qty': 1, 'unit': 'pc', 'core': true},
        ];
      final errors = validateData(
        ingredientsJson: _ingredients(),
        recipesJson: _recipes([recipe]),
        pricesJson: _prices(),
      );
      expect(errors.any((e) => e.contains('unknown ingredient ghost')), isTrue);
    });

    test('recipe with no core ingredient fails', () {
      final recipe = _validRecipe()
        ..['ingredients'] = [
          {'ingredientId': 'itlog', 'qty': 1, 'unit': 'pc', 'core': false},
        ];
      final errors = validateData(
        ingredientsJson: _ingredients(),
        recipesJson: _recipes([recipe]),
        pricesJson: _prices(),
      );
      expect(errors.any((e) => e.contains('no core ingredient')), isTrue);
    });

    test('recipe with empty equipment fails', () {
      final recipe = _validRecipe()..['equipment'] = <String>[];
      final errors = validateData(
        ingredientsJson: _ingredients(),
        recipesJson: _recipes([recipe]),
        pricesJson: _prices(),
      );
      expect(errors.any((e) => e.contains('no equipment')), isTrue);
    });

    test('recipe with empty steps fails', () {
      final recipe = _validRecipe()..['steps'] = <String>[];
      final errors = validateData(
        ingredientsJson: _ingredients(),
        recipesJson: _recipes([recipe]),
        pricesJson: _prices(),
      );
      expect(errors.any((e) => e.contains('no steps')), isTrue);
    });

    test('core ingredient missing from prices fails', () {
      // Use a custom ingredient not in the default prices list
      final extraIngredient = {
        'id': 'asin',
        'nameFil': 'Asin',
        'nameEn': 'Salt',
        'aliases': ['salt'],
      };
      final recipe = _validRecipe()
        ..['ingredients'] = [
          {'ingredientId': 'asin', 'qty': 1, 'unit': 'tsp', 'core': true},
        ];
      final errors = validateData(
        ingredientsJson: _ingredients([extraIngredient]),
        recipesJson: _recipes([recipe]),
        pricesJson: _prices(), // asin not in prices
      );
      expect(
        errors.any((e) => e.contains('no price for core ingredient asin')),
        isTrue,
      );
    });
  });
}
