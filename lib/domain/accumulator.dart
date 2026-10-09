// Detection accumulator — T3
// Converts noisy per-frame predictions into a stable detected ingredient list.

import 'dart:collection';

// ---------------------------------------------------------------------------
// Prediction
// ---------------------------------------------------------------------------

class Prediction {
  final String ingredientId;
  final double confidence;
  const Prediction({required this.ingredientId, required this.confidence});
}

// ---------------------------------------------------------------------------
// DetectionAccumulator
// ---------------------------------------------------------------------------

class DetectionAccumulator {
  final int windowSize;
  final int minHits;
  final double minConfidence;
  final Set<String>? vocabulary;

  // Sliding window: each element is one frame's predictions.
  final Queue<List<Prediction>> _window = Queue();

  // Confirmed (sticky) detections — only cleared by reset().
  final Set<String> _confirmed = {};

  int _frameCount = 0;

  DetectionAccumulator({
    required this.windowSize,
    required this.minHits,
    required this.minConfidence,
    this.vocabulary,
  });

  /// Add predictions from one camera frame.
  void addFrame(List<Prediction> predictions) {
    _window.addLast(List.unmodifiable(predictions));
    if (_window.length > windowSize) {
      _window.removeFirst();
    }
    _frameCount++;
    _updateConfirmed();
  }

  /// Returns the set of ingredient IDs currently considered detected.
  /// Once an ingredient is confirmed it remains until [reset] is called.
  Set<String> get detected => Set.unmodifiable(_confirmed);

  /// Clear all frame history and the confirmed set.
  void reset() {
    _window.clear();
    _confirmed.clear();
    _frameCount = 0;
  }

  /// Total number of frames added since last reset.
  int get frameCount => _frameCount;

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  void _updateConfirmed() {
    // Tally hits and total confidence per ingredient across the current window.
    final hits = <String, int>{};
    final totalConf = <String, double>{};

    for (final frame in _window) {
      for (final p in frame) {
        final id = p.ingredientId;

        // Ignore sentinel value.
        if (id == '_none') continue;

        // Ignore ids not in vocabulary (when vocabulary is non-empty).
        if (vocabulary != null && vocabulary!.isNotEmpty && !vocabulary!.contains(id)) {
          continue;
        }

        hits[id] = (hits[id] ?? 0) + 1;
        totalConf[id] = (totalConf[id] ?? 0.0) + p.confidence;
      }
    }

    // Promote ingredients that meet both thresholds.
    for (final id in hits.keys) {
      final hitCount = hits[id]!;
      if (hitCount < minHits) continue;

      final avgConf = totalConf[id]! / hitCount;
      if (avgConf >= minConfidence) {
        _confirmed.add(id);
      }
    }
  }
}
