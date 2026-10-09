// Domain models — T1
// ignore_for_file: prefer_const_constructors_in_immutables

enum Equipment { riceCooker, kettle, microwave, stove }

enum IngredientSource { owned, substituted, toBuy }

enum ResultKind { adapted, fallbackBase }

// ---------------------------------------------------------------------------
// Equipment helper
// ---------------------------------------------------------------------------
Equipment _equipmentFromJson(String value) {
  switch (value) {
    case 'riceCooker':
      return Equipment.riceCooker;
    case 'kettle':
      return Equipment.kettle;
    case 'microwave':
      return Equipment.microwave;
    case 'stove':
      return Equipment.stove;
    default:
      throw ArgumentError('Unknown equipment: $value');
  }
}

// ---------------------------------------------------------------------------
// Ingredient
// ---------------------------------------------------------------------------
class Ingredient {
  final String id;
  final String nameFil;
  final String nameEn;
  final List<String> aliases;

  const Ingredient({
    required this.id,
    required this.nameFil,
    required this.nameEn,
    required this.aliases,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id: json['id'] as String,
      nameFil: json['nameFil'] as String,
      nameEn: json['nameEn'] as String,
      aliases: (json['aliases'] as List).cast<String>(),
    );
  }
}

// ---------------------------------------------------------------------------
// RecipeIngredient
// ---------------------------------------------------------------------------
class RecipeIngredient {
  final String ingredientId;
  final double qty;
  final String unit;
  final bool core;

  const RecipeIngredient({
    required this.ingredientId,
    required this.qty,
    required this.unit,
    required this.core,
  });

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      ingredientId: json['ingredientId'] as String,
      qty: (json['qty'] as num).toDouble(),
      unit: json['unit'] as String,
      core: json['core'] as bool,
    );
  }
}

// ---------------------------------------------------------------------------
// Recipe
// ---------------------------------------------------------------------------
class Recipe {
  final String id;
  final String nameFil;
  final String nameEn;
  final List<RecipeIngredient> ingredients;
  final Set<Equipment> equipment;
  final List<String> steps;
  final int minutes;
  final int servings;

  const Recipe({
    required this.id,
    required this.nameFil,
    required this.nameEn,
    required this.ingredients,
    required this.equipment,
    required this.steps,
    required this.minutes,
    required this.servings,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] as String,
      nameFil: json['nameFil'] as String,
      nameEn: json['nameEn'] as String,
      ingredients: (json['ingredients'] as List)
          .cast<Map<String, dynamic>>()
          .map(RecipeIngredient.fromJson)
          .toList(),
      equipment: (json['equipment'] as List)
          .cast<String>()
          .map(_equipmentFromJson)
          .toSet(),
      steps: (json['steps'] as List).cast<String>(),
      minutes: json['minutes'] as int,
      servings: json['servings'] as int,
    );
  }
}

// ---------------------------------------------------------------------------
// Preferences
// ---------------------------------------------------------------------------
class Preferences {
  final Set<Equipment> equipment;
  final int extraBudgetPesos;

  const Preferences({
    required this.equipment,
    required this.extraBudgetPesos,
  });
}

// ---------------------------------------------------------------------------
// AdaptRequest
// ---------------------------------------------------------------------------
class AdaptRequest {
  final Recipe base;
  final Set<String> ownedIds;
  final Preferences prefs;

  const AdaptRequest({
    required this.base,
    required this.ownedIds,
    required this.prefs,
  });
}

// ---------------------------------------------------------------------------
// AdaptedIngredient
// ---------------------------------------------------------------------------
class AdaptedIngredient {
  final String ingredientId;
  final String qtyText;
  final IngredientSource source;
  final String? replacesId;

  const AdaptedIngredient({
    required this.ingredientId,
    required this.qtyText,
    required this.source,
    this.replacesId,
  });
}

// ---------------------------------------------------------------------------
// AdaptedRecipe
// ---------------------------------------------------------------------------
class AdaptedRecipe {
  final String name;
  final int minutes;
  final List<AdaptedIngredient> ingredients;
  final List<String> steps;
  final String notes;

  const AdaptedRecipe({
    required this.name,
    required this.minutes,
    required this.ingredients,
    required this.steps,
    required this.notes,
  });
}

// ---------------------------------------------------------------------------
// RecipeResult
// ---------------------------------------------------------------------------
class RecipeResult {
  final ResultKind kind;
  final Recipe base;
  final AdaptedRecipe? adapted;
  final int estimatedExtraPesos;
  /// Possible values: 'overBudget', 'lowMatch', 'unpricedItem'
  final List<String> flags;

  const RecipeResult({
    required this.kind,
    required this.base,
    this.adapted,
    required this.estimatedExtraPesos,
    required this.flags,
  });
}
