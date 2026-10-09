// Prompt builder — T4
// Pure function: no side effects, no async, snapshot-testable.

import 'models.dart';

/// Builds the LLM prompt for adapting [request.base] to the user's constraints.
/// [vocabulary] is the full ingredient catalogue (used for id resolution).
///
/// Follows PRD §17.8.
String buildPrompt(AdaptRequest request, List<Ingredient> vocabulary) {
  final base = request.base;
  final buf = StringBuffer();

  // ── System message ──────────────────────────────────────────────────────
  buf.writeln('[SYSTEM]');
  buf.writeln(
    'You adapt Filipino home recipes for students with limited equipment. '
    'Follow the output format exactly. '
    'Use only the ingredient ids you are given. '
    'Output nothing before NAME and nothing after END.',
  );

  // ── User message ─────────────────────────────────────────────────────────
  buf.writeln('[USER]');

  // 1. Recipe name and time
  buf.writeln(
    'Recipe: ${base.nameFil} (${base.nameEn}), ${base.minutes} minutes',
  );

  // 2. Base ingredients
  for (final ri in base.ingredients) {
    final role = ri.core ? 'core' : 'optional';
    buf.writeln('- ${ri.ingredientId} | ${ri.qty} ${ri.unit} | $role');
  }

  // 3. Numbered base steps
  for (var i = 0; i < base.steps.length; i++) {
    buf.writeln('${i + 1}. ${base.steps[i]}');
  }

  // 4. USER HAS
  final ownedList = request.ownedIds.toList()..sort();
  buf.writeln('USER HAS: ${ownedList.join(', ')}');

  // 5. EQUIPMENT
  final equipmentStrings = request.prefs.equipment
      .map(_equipmentToString)
      .toList()
    ..sort();
  buf.writeln('EQUIPMENT: ${equipmentStrings.join(', ')}');

  // 6. Rules block
  buf.writeln('Rules:');
  buf.writeln('- Mark each ingredient owned, sub, or buy.');
  buf.writeln('- owned means the id is in USER HAS.');
  buf.writeln(
    '- sub means replace a base ingredient with an id from USER HAS, '
    'and name the id it replaces.',
  );
  buf.writeln(
    '- buy means the user does not have it. Keep buy items to the minimum.',
  );
  buf.writeln(
    '- Use only the listed equipment in the steps. '
    'Write 3 to 6 short steps.',
  );
  buf.writeln(
    '- Do not add ingredients that are not in the base recipe unless they replace one.',
  );

  // 7. Output format block
  buf.writeln('Output format:');
  buf.writeln('NAME: <recipe name>');
  buf.writeln('TIME: <minutes as integer>');
  buf.writeln('INGREDIENTS:');
  buf.writeln('- owned | <quantity and unit> | <ingredient id>');
  buf.writeln(
    '- sub | <quantity and unit> | <ingredient id> | replaces <ingredient id>',
  );
  buf.writeln('- buy | <quantity and unit> | <ingredient id>');
  buf.writeln('STEPS:');
  buf.writeln('1. <short step>');
  buf.writeln('NOTES: <one line>');
  buf.write('END');

  return buf.toString();
}

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

String _equipmentToString(Equipment e) {
  switch (e) {
    case Equipment.riceCooker:
      return 'rice_cooker';
    case Equipment.kettle:
      return 'kettle';
    case Equipment.microwave:
      return 'microwave';
    case Equipment.stove:
      return 'stove';
  }
}
