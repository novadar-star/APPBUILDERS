// LLM engine interface — T7

/// Events emitted by AdaptationService during generation
enum AdaptationEvent { started, token, parsed, retrying, fellBack, failed }

class AdaptationUpdate {
  final AdaptationEvent event;
  final String? token; // for AdaptationEvent.token
  final String? message; // for errors, fellBack, retrying
  const AdaptationUpdate({required this.event, this.token, this.message});
}

abstract class LlmEngine {
  bool get isMock;
  Future<void> load(String modelPath);

  /// Streams raw text tokens. Completes when generation ends or is cancelled.
  Stream<String> generate(
    String prompt, {
    required int maxTokens,
    required double temperature,
    required double topP,
  });
  Future<void> cancel();
  Future<void> dispose();
}
