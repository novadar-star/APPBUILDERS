// Mock LLM engine — T7
// Debug builds only.

import 'package:flutter/foundation.dart';
import 'llm_engine.dart';

/// A [LlmEngine] that replays a canned tagged-line response with realistic
/// delays. Only available in debug mode; presence is guarded by an assert.
class MockLlmEngine implements LlmEngine {
  bool _cancelled = false;

  MockLlmEngine() {
    assert(kDebugMode, 'MockLlmEngine must not be used in release builds');
  }

  @override
  bool get isMock => true;

  @override
  Future<void> load(String modelPath) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Stream<String> generate(
    String prompt, {
    required int maxTokens,
    required double temperature,
    required double topP,
  }) async* {
    _cancelled = false;

    // Canned response — valid tagged-line format that passes V1–V8.
    // Uses rice cooker equipment so V6 only fires if riceCooker is missing.
    const lines = [
      'NAME: Sinangag sa Rice Cooker\n',
      'TIME: 20\n',
      'INGREDIENTS:\n',
      '- owned | 1 cup | kanin\n',
      '- owned | 2 cloves | bawang\n',
      '- owned | 1 tsp | mantika\n',
      '- buy | 1 pc | itlog\n',
      'STEPS:\n',
      '1. Add cooked rice and minced garlic to the rice cooker with oil.\n',
      '2. Stir well and press cook. Stir again halfway through.\n',
      '3. Serve hot. Top with a fried egg if available.\n',
      'NOTES: Great for leftover rice. Season with toyo if you have it.\n',
      'END\n',
    ];

    for (final line in lines) {
      if (_cancelled) return;
      await Future.delayed(const Duration(milliseconds: 120));
      yield line;
    }
  }

  @override
  Future<void> cancel() async {
    _cancelled = true;
  }

  @override
  Future<void> dispose() async {}
}
