// Tests for lib/ml/mock_llm_engine.dart — T7

import 'package:flutter_test/flutter_test.dart';
import 'package:snapfood/domain/adaptation_parser.dart';
import 'package:snapfood/ml/mock_llm_engine.dart';

void main() {
  group('MockLlmEngine', () {
    late MockLlmEngine engine;

    setUp(() {
      engine = MockLlmEngine();
    });

    tearDown(() async {
      await engine.dispose();
    });

    test('isMock is true', () {
      expect(engine.isMock, isTrue);
    });

    test('load() completes without error', () async {
      await expectLater(engine.load(''), completes);
    });

    test('generate() streams tokens', () async {
      final tokens = <String>[];
      await engine
          .generate('test prompt', maxTokens: 400, temperature: 0.3, topP: 0.9)
          .forEach(tokens.add);
      expect(tokens, isNotEmpty);
    });

    test('output contains NAME: marker', () async {
      final tokens = <String>[];
      await engine
          .generate('test prompt', maxTokens: 400, temperature: 0.3, topP: 0.9)
          .forEach(tokens.add);
      final full = tokens.join();
      expect(full, contains('NAME:'));
    });

    test('output contains END marker', () async {
      final tokens = <String>[];
      await engine
          .generate('test prompt', maxTokens: 400, temperature: 0.3, topP: 0.9)
          .forEach(tokens.add);
      final full = tokens.join();
      expect(full, contains('END'));
    });

    test('cancel() stops the stream', () async {
      final tokens = <String>[];
      int count = 0;
      await for (final token in engine.generate(
        'test prompt',
        maxTokens: 400,
        temperature: 0.3,
        topP: 0.9,
      )) {
        tokens.add(token);
        count++;
        if (count == 2) {
          await engine.cancel();
        }
      }
      // Should have stopped early — far fewer than the full 13 lines
      expect(tokens.length, lessThan(13));
    });

    test('full output parses successfully', () async {
      final tokens = <String>[];
      await engine
          .generate('test prompt', maxTokens: 400, temperature: 0.3, topP: 0.9)
          .forEach(tokens.add);
      final full = tokens.join();
      final result = parseAdaptedRecipe(full);
      expect(result.success, isTrue,
          reason: 'Parse errors: ${result.errors.join(', ')}');
    });
  });
}
