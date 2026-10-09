// Adaptation parser — T4
// Parses tagged-line LLM output into an AdaptedRecipe.
// Follows PRD §17.8.

import 'models.dart';

// ---------------------------------------------------------------------------
// ParseResult
// ---------------------------------------------------------------------------

class ParseResult {
  final AdaptedRecipe? recipe;
  final List<String> errors;

  const ParseResult({this.recipe, required this.errors});

  bool get success => recipe != null && errors.isEmpty;
}

// ---------------------------------------------------------------------------
// Public entry point
// ---------------------------------------------------------------------------

ParseResult parseAdaptedRecipe(String rawOutput) {
  // Strip markdown fences (``` ... ```)
  final stripped = _stripFences(rawOutput);

  final lines = stripped
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();

  final errors = <String>[];

  String? name;
  int? minutes;
  final ingredients = <AdaptedIngredient>[];
  final steps = <String>[];
  String? notes;
  bool endReached = false;

  _Section currentSection = _Section.none;

  for (final line in lines) {
    // END marker
    if (_matchesMarker(line, 'END')) {
      endReached = true;
      break;
    }

    // NAME
    final nameVal = _extractValue(line, 'NAME');
    if (nameVal != null) {
      name = nameVal.trim();
      currentSection = _Section.none;
      continue;
    }

    // TIME
    final timeVal = _extractValue(line, 'TIME');
    if (timeVal != null) {
      final parsed = int.tryParse(timeVal.trim());
      if (parsed == null) {
        errors.add('TIME is not a valid integer: "${timeVal.trim()}"');
      } else {
        minutes = parsed;
      }
      currentSection = _Section.none;
      continue;
    }

    // INGREDIENTS section header
    if (_matchesMarker(line, 'INGREDIENTS')) {
      currentSection = _Section.ingredients;
      continue;
    }

    // STEPS section header
    if (_matchesMarker(line, 'STEPS')) {
      currentSection = _Section.steps;
      continue;
    }

    // NOTES
    final notesVal = _extractValue(line, 'NOTES');
    if (notesVal != null) {
      notes = notesVal.trim();
      currentSection = _Section.none;
      continue;
    }

    // Section-specific line parsing
    if (currentSection == _Section.ingredients) {
      if (line.startsWith('-')) {
        final result = _parseIngredientLine(line);
        if (result.error != null) {
          errors.add(result.error!);
        } else {
          ingredients.add(result.ingredient!);
        }
      }
      continue;
    }

    if (currentSection == _Section.steps) {
      // Numbered lines: "1. text", "2. text", etc.
      final stepMatch = RegExp(r'^\d+\.\s+(.+)$').firstMatch(line);
      if (stepMatch != null) {
        steps.add(stepMatch.group(1)!.trim());
      }
      continue;
    }
  }

  // Validate required sections present
  if (!endReached) {
    errors.add('Missing END marker');
  }
  if (name == null || name.isEmpty) {
    errors.add('Missing or empty NAME');
  }

  if (errors.isNotEmpty) {
    return ParseResult(errors: errors);
  }

  final recipe = AdaptedRecipe(
    name: name!,
    minutes: minutes ?? 0,
    ingredients: ingredients,
    steps: steps,
    notes: notes ?? '',
  );

  return ParseResult(recipe: recipe, errors: const []);
}

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

enum _Section { none, ingredients, steps }

/// Strip markdown code fences (``` ... ```) from the raw string.
String _stripFences(String text) {
  return text.replaceAll(RegExp(r'```[^\n]*\n?', multiLine: true), '');
}

/// Returns true when [line] matches [marker] at the start (case-insensitive),
/// followed by optional colon, dash, or end-of-string.
bool _matchesMarker(String line, String marker) {
  final pattern = RegExp(
    '^${RegExp.escape(marker)}\\s*[:\\-]?\\s*\$',
    caseSensitive: false,
  );
  return pattern.hasMatch(line.trim());
}

/// If [line] starts with [marker] followed by `:` or ` -`, return the value
/// after the separator.  Returns null if no match.
String? _extractValue(String line, String marker) {
  final pattern = RegExp(
    '^${RegExp.escape(marker)}\\s*[:\\-]\\s*(.*)',
    caseSensitive: false,
  );
  final m = pattern.firstMatch(line.trim());
  return m?.group(1);
}

class _IngredientParseResult {
  final AdaptedIngredient? ingredient;
  final String? error;
  const _IngredientParseResult({this.ingredient, this.error});
}

/// Parse a single ingredient line:
/// `- <type> | <qty text> | <ingredient id>`
/// `- <type> | <qty text> | <ingredient id> | replaces <ingredient id>`
_IngredientParseResult _parseIngredientLine(String line) {
  // Strip leading dash
  final body = line.replaceFirst(RegExp(r'^-\s*'), '');
  final parts = body.split('|').map((p) => p.trim()).toList();

  if (parts.length < 3) {
    return _IngredientParseResult(
      error: 'Malformed ingredient line (too few fields): "$line"',
    );
  }

  final typeStr = parts[0].toLowerCase();
  final qtyText = parts[1];
  final ingredientId = parts[2];

  IngredientSource? source;
  switch (typeStr) {
    case 'owned':
      source = IngredientSource.owned;
      break;
    case 'sub':
      source = IngredientSource.substituted;
      break;
    case 'buy':
      source = IngredientSource.toBuy;
      break;
    default:
      return _IngredientParseResult(
        error: 'Invalid ingredient type "$typeStr" in line: "$line"',
      );
  }

  // Optional: `| replaces <id>`
  String? replacesId;
  if (parts.length >= 4) {
    final replacesMatch =
        RegExp(r'^replaces\s+(\S+)$', caseSensitive: false).firstMatch(parts[3]);
    if (replacesMatch != null) {
      replacesId = replacesMatch.group(1);
    }
  }

  return _IngredientParseResult(
    ingredient: AdaptedIngredient(
      ingredientId: ingredientId,
      qtyText: qtyText,
      source: source,
      replacesId: replacesId,
    ),
  );
}
