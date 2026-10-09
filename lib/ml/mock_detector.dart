// MockDetector — debug builds only.
// ignore_for_file: avoid_print

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:snapfood/domain/accumulator.dart';
import 'package:snapfood/ml/detector.dart';

// ---------------------------------------------------------------------------
// MockDetector
// ---------------------------------------------------------------------------

/// Simulated detector for debug builds. Shows MOCK badge while active.
/// Never instantiate in release builds — an [AssertionError] will be thrown.
class MockDetector implements IngredientDetector {
  final List<String> _vocabulary;
  int _callCount = 0;

  MockDetector(this._vocabulary) {
    assert(kDebugMode, 'MockDetector must not be used in release builds');
  }

  @override
  bool get isMock => true;

  @override
  Future<void> load() async {
    assert(kDebugMode, 'MockDetector must not be used in release builds');
    // No model file to load — instant warm-up delay.
    await Future.delayed(const Duration(milliseconds: 100));
  }

  @override
  Future<List<Prediction>> predict(CameraImage image) async {
    assert(kDebugMode, 'MockDetector must not be used in release builds');
    return simulateFrame();
  }

  /// Simulate one camera frame without requiring a real [CameraImage].
  /// Cycles through the vocabulary; confidence alternates 0.85 / 0.72.
  Future<List<Prediction>> simulateFrame() async {
    await Future.delayed(const Duration(milliseconds: 50));
    if (_vocabulary.isEmpty) return [];
    _callCount++;
    final idx = _callCount % _vocabulary.length;
    final confidence = _callCount.isEven ? 0.85 : 0.72;
    return [Prediction(ingredientId: _vocabulary[idx], confidence: confidence)];
  }

  @override
  Future<List<Prediction>> predictFromFile(String imagePath) async {
    assert(kDebugMode, 'MockDetector must not be used in release builds');
    await Future.delayed(const Duration(milliseconds: 200));
    if (_vocabulary.isEmpty) return [];
    // Return top-3 from vocabulary with descending fake confidence.
    return _vocabulary
        .take(3)
        .toList()
        .asMap()
        .entries
        .map((e) => Prediction(
              ingredientId: e.value,
              confidence: 0.9 - e.key * 0.1,
            ))
        .toList();
  }

  @override
  Future<void> dispose() async {}
}
