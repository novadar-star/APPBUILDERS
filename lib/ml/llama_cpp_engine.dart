// LlamaCppEngine — fllama binding
// Selected: fllama (MIT). See docs/DECISIONS.md.

import 'dart:async';

import 'package:fllama/fllama.dart';

import 'llm_engine.dart';

/// Real llama.cpp engine backed by the [fllama] package (pub.dev, MIT).
///
/// Call [load] once with the path to a GGUF model file before calling
/// [generate]. Tokens are streamed via fllama's [Fllama.onTokenStream]
/// broadcast stream. The [completion] call is made with
/// `emitRealtimeCompletion: true` so tokens arrive incrementally.
///
/// Threading notes:
/// - [load] and [generate] must be called from the same Dart isolate (main).
/// - [onTokenStream] is a platform-level broadcast stream; we filter by
///   contextId so concurrent callers (if any) do not cross-contaminate.
class LlamaCppEngine implements LlmEngine {
  double? _contextId;
  StreamSubscription<Map<Object?, dynamic>>? _tokenSub;

  @override
  bool get isMock => false;

  // ---------------------------------------------------------------------------
  // load
  // ---------------------------------------------------------------------------

  @override
  Future<void> load(String modelPath) async {
    // Release any previously loaded context first.
    if (_contextId != null) {
      await Fllama.instance()!.releaseContext(_contextId!);
      _contextId = null;
    }

    final result = await Fllama.instance()!.initContext(
      modelPath,
      nCtx: 2048,
      nBatch: 512,
      nThreads: 4,
      nGpuLayers: 0, // CPU-only; bump for Metal/Vulkan later
      useMlock: false,
      useMmap: true,
      emitLoadProgress: false,
    );

    if (result == null) {
      throw StateError(
        'LlamaCppEngine.load(): initContext returned null. '
        'Check that the model file exists at: $modelPath',
      );
    }

    final raw = result['contextId'];
    if (raw == null) {
      throw StateError(
        'LlamaCppEngine.load(): initContext result missing contextId key. '
        'Got: $result',
      );
    }

    _contextId = (raw as num).toDouble();
  }

  // ---------------------------------------------------------------------------
  // generate
  // ---------------------------------------------------------------------------

  @override
  Stream<String> generate(
    String prompt, {
    required int maxTokens,
    required double temperature,
    required double topP,
  }) {
    final cid = _contextId;
    if (cid == null) {
      return Stream.error(
        StateError(
          'LlamaCppEngine.generate(): model not loaded. Call load() first.',
        ),
      );
    }

    // Use a StreamController so callers get a clean Stream<String> interface
    // regardless of fllama's broadcast stream internals.
    final controller = StreamController<String>();

    // fllama emits on a single broadcast stream for all contexts.
    // We filter to our contextId and the 'completion' function events.
    StreamSubscription<Map<Object?, dynamic>>? sub;

    void _cleanup() {
      sub?.cancel();
      sub = null;
      _tokenSub = null;
      if (!controller.isClosed) controller.close();
    }

    final tokenStream = Fllama.instance()!.onTokenStream;
    if (tokenStream == null) {
      return Stream.error(
        StateError('LlamaCppEngine.generate(): onTokenStream is null.'),
      );
    }

    sub = tokenStream.listen(
      (data) {
        // Ignore events for other contexts or other function types.
        if (data['function'] != 'completion') return;

        final result = data['result'];
        if (result == null) return;

        // Check this event belongs to our context.
        final eventCid = result['contextId'];
        if (eventCid != null && (eventCid as num).toDouble() != cid) return;

        final token = result['token'];
        final stop = result['stop'];

        if (token != null && token is String && token.isNotEmpty) {
          if (!controller.isClosed) controller.add(token);
        }

        // stop == true signals the completion is finished.
        if (stop == true) {
          _cleanup();
        }
      },
      onError: (Object err, StackTrace st) {
        if (!controller.isClosed) controller.addError(err, st);
        _cleanup();
      },
      onDone: _cleanup,
    );

    _tokenSub = sub;

    // Fire the completion asynchronously so the stream is returned first.
    Future.microtask(() async {
      try {
        await Fllama.instance()!.completion(
          cid,
          prompt: prompt,
          temperature: temperature,
          topP: topP,
          nPredict: maxTokens,
          emitRealtimeCompletion: true,
        );
      } catch (err, st) {
        if (!controller.isClosed) controller.addError(err, st);
        _cleanup();
      }
    });

    return controller.stream;
  }

  // ---------------------------------------------------------------------------
  // cancel
  // ---------------------------------------------------------------------------

  @override
  Future<void> cancel() async {
    final cid = _contextId;
    if (cid == null) return;
    await Fllama.instance()!.stopCompletion(contextId: cid);
    await _tokenSub?.cancel();
    _tokenSub = null;
  }

  // ---------------------------------------------------------------------------
  // dispose
  // ---------------------------------------------------------------------------

  @override
  Future<void> dispose() async {
    await cancel();
    final cid = _contextId;
    if (cid != null) {
      await Fllama.instance()!.releaseContext(cid);
      _contextId = null;
    }
  }
}
