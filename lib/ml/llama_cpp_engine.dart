// LlamaCpp engine stub — T7
// Placeholder for the real llama.cpp Flutter binding.
// Candidates: fllama, llama_cpp_dart, flutter_gemma.
// Do NOT add any of these to pubspec.yaml yet — confirm Android ABI support
// and license compatibility first. Record the choice in docs/DECISIONS.md.

import 'llm_engine.dart';

class LlamaCppEngine implements LlmEngine {
  @override
  bool get isMock => false;

  @override
  Future<void> load(String modelPath) async {
    throw UnimplementedError(
      'LlamaCppEngine.load(): no llama.cpp Flutter binding selected yet. '
      'Evaluate fllama, llama_cpp_dart, or flutter_gemma on the target device. '
      'See PRD §17.8 and docs/DECISIONS.md.',
    );
  }

  @override
  Stream<String> generate(
    String prompt, {
    required int maxTokens,
    required double temperature,
    required double topP,
  }) {
    throw UnimplementedError('LlamaCppEngine not yet implemented.');
  }

  @override
  Future<void> cancel() async {}

  @override
  Future<void> dispose() async {}
}
