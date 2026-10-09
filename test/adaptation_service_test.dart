// Tests for lib/domain/adaptation_service.dart — T7

import 'package:flutter_test/flutter_test.dart';
import 'package:snapfood/core/config_loader.dart';
import 'package:snapfood/domain/adaptation_service.dart';
import 'package:snapfood/domain/models.dart';
import 'package:snapfood/ml/llm_engine.dart';
import 'package:snapfood/ml/mock_llm_engine.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Minimal [LlmConfig] for tests.
const _testConfig = LlmConfig(
  temperature: 0.3,
  topP: 0.9,
  maxTokens: 400,
  contextSize: 2048,
  timeoutSeconds: 30,
  maxRetries: 1,
);

/// Vocabulary that covers every id used by [MockLlmEngine].
final _vocab = [
  const Ingredient(id: 'kanin', nameFil: 'Kanin', nameEn: 'Cooked rice', aliases: []),
  const Ingredient(id: 'bawang', nameFil: 'Bawang', nameEn: 'Garlic', aliases: []),
  const Ingredient(id: 'mantika', nameFil: 'Mantika', nameEn: 'Cooking oil', aliases: []),
  const Ingredient(id: 'itlog', nameFil: 'Itlog', nameEn: 'Egg', aliases: []),
];

/// Prices for every ingredient in the vocab.
final _prices = <String, int>{
  'kanin': 5,
  'bawang': 3,
  'mantika': 2,
  'itlog': 8,
};

/// A minimal [AdaptRequest] whose ownedIds, base recipe, and equipment prefs
/// are consistent with what [MockLlmEngine] emits.
AdaptRequest _makeRequest({Set<String>? ownedIds}) {
  final base = Recipe(
    id: 'r003',
    nameFil: 'Sinangag sa Rice Cooker',
    nameEn: 'Rice Cooker Garlic Rice',
    equipment: {Equipment.riceCooker},
    minutes: 18,
    servings: 1,
    ingredients: [
      const RecipeIngredient(ingredientId: 'kanin', qty: 1, unit: 'cup', core: true),
      const RecipeIngredient(ingredientId: 'bawang', qty: 2, unit: 'cloves', core: true),
      const RecipeIngredient(ingredientId: 'mantika', qty: 1, unit: 'tsp', core: false),
      const RecipeIngredient(ingredientId: 'itlog', qty: 1, unit: 'pc', core: false),
    ],
    steps: ['Cook rice.'],
  );

  return AdaptRequest(
    base: base,
    ownedIds: ownedIds ?? {'kanin', 'bawang', 'mantika'},
    prefs: const Preferences(
      equipment: {Equipment.riceCooker},
      extraBudgetPesos: 50,
    ),
  );
}

AdaptationService _makeService(LlmEngine engine) {
  return AdaptationService(
    engine: engine,
    vocabulary: _vocab,
    prices: _prices,
    config: _testConfig,
  );
}

// ---------------------------------------------------------------------------
// Stub engine that throws on generate()
// ---------------------------------------------------------------------------

class _ThrowingEngine implements LlmEngine {
  @override
  bool get isMock => true;

  @override
  Future<void> load(String modelPath) async {}

  @override
  Stream<String> generate(String prompt,
      {required int maxTokens,
      required double temperature,
      required double topP}) async* {
    throw Exception('engine exploded');
  }

  @override
  Future<void> cancel() async {}

  @override
  Future<void> dispose() async {}
}

// ---------------------------------------------------------------------------
// Stub engine: bad output first, good output on second call
// ---------------------------------------------------------------------------

class _BadThenGoodEngine implements LlmEngine {
  int _calls = 0;

  @override
  bool get isMock => true;

  @override
  Future<void> load(String modelPath) async {}

  @override
  Stream<String> generate(String prompt,
      {required int maxTokens,
      required double temperature,
      required double topP}) async* {
    _calls++;
    if (_calls == 1) {
      // Bad output: missing END marker — will fail parse → trigger retry
      yield 'NAME: Bad Recipe\n';
      yield 'TIME: 10\n';
      yield 'INGREDIENTS:\n';
      yield '- owned | 1 cup | kanin\n';
      yield 'STEPS:\n';
      yield '1. Cook.\n';
      // No END
    } else {
      // Good output on retry
      yield 'NAME: Sinangag sa Rice Cooker\n';
      yield 'TIME: 20\n';
      yield 'INGREDIENTS:\n';
      yield '- owned | 1 cup | kanin\n';
      yield '- owned | 2 cloves | bawang\n';
      yield '- owned | 1 tsp | mantika\n';
      yield 'STEPS:\n';
      yield '1. Add rice and garlic to rice cooker with oil.\n';
      yield '2. Press cook and stir halfway through.\n';
      yield '3. Serve hot.\n';
      yield 'NOTES: Great leftover rice dish.\n';
      yield 'END\n';
    }
  }

  @override
  Future<void> cancel() async {}

  @override
  Future<void> dispose() async {}
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('AdaptationService.adapt()', () {
    test('emits started event first', () async {
      final service = _makeService(MockLlmEngine());
      final events = <AdaptationEvent>[];
      await for (final u in service.adapt(_makeRequest())) {
        events.add(u.event);
      }
      expect(events.first, equals(AdaptationEvent.started));
    });

    test('emits token events', () async {
      final service = _makeService(MockLlmEngine());
      final events = <AdaptationEvent>[];
      await for (final u in service.adapt(_makeRequest())) {
        events.add(u.event);
      }
      expect(events, contains(AdaptationEvent.token));
    });

    test('emits parsed event on valid mock output', () async {
      final service = _makeService(MockLlmEngine());
      final events = <AdaptationEvent>[];
      await for (final u in service.adapt(_makeRequest())) {
        events.add(u.event);
      }
      expect(events, contains(AdaptationEvent.parsed));
    });

    test('result is not null after parsed event', () async {
      final service = _makeService(MockLlmEngine());
      AdaptationEvent? lastEvent;
      await for (final u in service.adapt(_makeRequest())) {
        lastEvent = u.event;
      }
      expect(lastEvent, equals(AdaptationEvent.parsed));
      expect(service.lastAdapted, isNotNull);
    });

    test('emits fellBack when engine throws', () async {
      final service = _makeService(_ThrowingEngine());
      final events = <AdaptationEvent>[];
      await for (final u in service.adapt(_makeRequest())) {
        events.add(u.event);
      }
      expect(events, contains(AdaptationEvent.fellBack));
    });

    test('emits retrying when first attempt has validation errors', () async {
      final service = _makeService(_BadThenGoodEngine());
      final events = <AdaptationEvent>[];
      await for (final u in service.adapt(_makeRequest())) {
        events.add(u.event);
      }
      expect(events, contains(AdaptationEvent.retrying),
          reason: 'Bad first output should trigger a retry');
      // After retry with good output it should end in parsed
      expect(events, contains(AdaptationEvent.parsed));
    });
  });
}
