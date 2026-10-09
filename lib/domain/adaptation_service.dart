// Adaptation service — T7
// Full retry+fallback flow per PRD §17.8.

import 'dart:async';

import 'package:snapfood/core/config_loader.dart';
import 'package:snapfood/domain/adaptation_parser.dart';
import 'package:snapfood/domain/adaptation_validator.dart';
import 'package:snapfood/domain/models.dart';
import 'package:snapfood/domain/prompt_builder.dart';
import 'package:snapfood/ml/llm_engine.dart';

class AdaptationService {
  final LlmEngine _engine;
  final List<Ingredient> _vocabulary;
  final Map<String, int> _prices;
  final LlmConfig _config;

  AdaptedRecipe? _lastAdapted;

  AdaptationService({
    required LlmEngine engine,
    required List<Ingredient> vocabulary,
    required Map<String, int> prices,
    required LlmConfig config,
  })  : _engine = engine,
        _vocabulary = vocabulary,
        _prices = prices,
        _config = config;

  /// Returns the last successfully parsed [AdaptedRecipe], or null if the
  /// service fell back. Call this after the stream completes with a
  /// [AdaptationEvent.parsed] event.
  AdaptedRecipe? get lastAdapted => _lastAdapted;

  /// Cancels an in-progress generation.
  Future<void> cancel() => _engine.cancel();

  /// Streams [AdaptationUpdate] events.
  ///
  /// Flow:
  ///   started → token(s) → parsed (success path)
  ///   started → token(s) → retrying → token(s) → parsed | fellBack
  Stream<AdaptationUpdate> adapt(AdaptRequest request) async* {
    _lastAdapted = null;
    yield const AdaptationUpdate(event: AdaptationEvent.started);

    final vocabIds = _vocabulary.map((i) => i.id).toSet();
    final prompt = buildPrompt(request, _vocabulary);

    // ── Attempt 1 ──────────────────────────────────────────────────────────
    final result1 = await _runGeneration(prompt, onToken: (t) {});

    if (result1.timedOut || result1.engineError != null) {
      yield AdaptationUpdate(
        event: AdaptationEvent.fellBack,
        message: result1.engineError ?? 'timeout',
      );
      return;
    }

    for (final t in result1.tokens) {
      yield AdaptationUpdate(event: AdaptationEvent.token, token: t);
    }

    final raw1 = result1.tokens.join();
    final parsed1 = parseAdaptedRecipe(raw1);
    final errors1 = parsed1.success
        ? validateAdaptedRecipe(parsed1.recipe!, request, vocabIds, _prices)
        : parsed1.errors;

    if (errors1.isEmpty && parsed1.success) {
      _lastAdapted = parsed1.recipe;
      yield const AdaptationUpdate(event: AdaptationEvent.parsed);
      return;
    }

    // ── Retry once ─────────────────────────────────────────────────────────
    final blockingErrors1 =
        errors1.where((e) => !e.startsWith('WARNING:')).toList();
    yield AdaptationUpdate(
      event: AdaptationEvent.retrying,
      message: blockingErrors1.join('; '),
    );

    final retryPrompt =
        '$prompt\nPrevious attempt had these problems: ${blockingErrors1.join(', ')}';
    final result2 = await _runGeneration(retryPrompt, onToken: (t) {});

    if (result2.timedOut || result2.engineError != null) {
      yield AdaptationUpdate(
        event: AdaptationEvent.fellBack,
        message: result2.engineError ?? 'timeout',
      );
      return;
    }

    for (final t in result2.tokens) {
      yield AdaptationUpdate(event: AdaptationEvent.token, token: t);
    }

    final raw2 = result2.tokens.join();
    final parsed2 = parseAdaptedRecipe(raw2);
    final errors2 = parsed2.success
        ? validateAdaptedRecipe(parsed2.recipe!, request, vocabIds, _prices)
        : parsed2.errors;

    final blockingErrors2 =
        errors2.where((e) => !e.startsWith('WARNING:')).toList();

    if (blockingErrors2.isEmpty && parsed2.success) {
      _lastAdapted = parsed2.recipe;
      yield const AdaptationUpdate(event: AdaptationEvent.parsed);
    } else {
      yield AdaptationUpdate(
        event: AdaptationEvent.fellBack,
        message: blockingErrors2.join('; '),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  Future<_GenerationResult> _runGeneration(
    String prompt, {
    required void Function(String) onToken,
  }) async {
    final tokens = <String>[];
    try {
      await _engine
          .generate(
            prompt,
            maxTokens: _config.maxTokens,
            temperature: _config.temperature,
            topP: _config.topP,
          )
          .timeout(Duration(seconds: _config.timeoutSeconds))
          .forEach((token) {
        tokens.add(token);
        onToken(token);
      });
      return _GenerationResult(tokens: tokens);
    } on TimeoutException {
      return _GenerationResult(tokens: tokens, timedOut: true);
    } catch (e) {
      return _GenerationResult(tokens: tokens, engineError: e.toString());
    }
  }
}

class _GenerationResult {
  final List<String> tokens;
  final bool timedOut;
  final String? engineError;

  const _GenerationResult({
    required this.tokens,
    this.timedOut = false,
    this.engineError,
  });
}
