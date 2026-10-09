import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:snapfood/domain/models.dart';

class AppBundle {
  final List<Ingredient> ingredients;
  final List<Recipe> recipes;
  final Map<String, int> prices; // ingredientId -> pesos
  final String priceDate;

  const AppBundle({
    required this.ingredients,
    required this.recipes,
    required this.prices,
    required this.priceDate,
  });

  static Future<AppBundle> load() async {
    // Load all three JSON assets in parallel.
    final results = await Future.wait([
      rootBundle.loadString('assets/data/ingredients.json'),
      rootBundle.loadString('assets/data/recipes.json'),
      rootBundle.loadString('assets/data/prices.json'),
    ]);

    final ingredientsJson =
        (jsonDecode(results[0]) as List).cast<Map<String, dynamic>>();
    final recipesJson =
        (jsonDecode(results[1]) as List).cast<Map<String, dynamic>>();
    final pricesMap = jsonDecode(results[2]) as Map<String, dynamic>;

    final ingredients =
        ingredientsJson.map(Ingredient.fromJson).toList();
    final recipes = recipesJson.map(Recipe.fromJson).toList();

    final priceEntries =
        (pricesMap['entries'] as List).cast<Map<String, dynamic>>();
    final prices = <String, int>{
      for (final e in priceEntries)
        e['ingredientId'] as String: (e['pesos'] as num).toInt(),
    };

    return AppBundle(
      ingredients: ingredients,
      recipes: recipes,
      prices: prices,
      priceDate: pricesMap['collectedOn'] as String,
    );
  }
}
