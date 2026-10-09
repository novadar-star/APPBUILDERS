// Tests for lib/domain/accumulator.dart — T3

import 'package:flutter_test/flutter_test.dart';
import 'package:snapfood/domain/accumulator.dart';

void main() {
  group('DetectionAccumulator', () {
    // 1. ingredient detected after minHits frames with sufficient confidence
    test('ingredient detected after minHits frames with sufficient confidence', () {
      final acc = DetectionAccumulator(
        windowSize: 5,
        minHits: 3,
        minConfidence: 0.6,
      );

      for (var i = 0; i < 3; i++) {
        acc.addFrame([Prediction(ingredientId: 'itlog', confidence: 0.8)]);
      }

      expect(acc.detected, contains('itlog'));
    });

    // 2. ingredient not detected below minHits threshold
    test('ingredient not detected below minHits threshold', () {
      final acc = DetectionAccumulator(
        windowSize: 5,
        minHits: 3,
        minConfidence: 0.6,
      );

      for (var i = 0; i < 2; i++) {
        acc.addFrame([Prediction(ingredientId: 'itlog', confidence: 0.8)]);
      }

      expect(acc.detected, isNot(contains('itlog')));
    });

    // 3. ingredient not detected below minConfidence threshold
    test('ingredient not detected below minConfidence threshold', () {
      final acc = DetectionAccumulator(
        windowSize: 5,
        minHits: 3,
        minConfidence: 0.6,
      );

      for (var i = 0; i < 3; i++) {
        acc.addFrame([Prediction(ingredientId: 'itlog', confidence: 0.4)]);
      }

      expect(acc.detected, isNot(contains('itlog')));
    });

    // 4. detected ingredient stays after panning away (flicker prevention)
    test('detected ingredient stays after panning away (flicker prevention)', () {
      final acc = DetectionAccumulator(
        windowSize: 5,
        minHits: 3,
        minConfidence: 0.6,
      );

      // Confirm 'itlog' with 3 good frames.
      for (var i = 0; i < 3; i++) {
        acc.addFrame([Prediction(ingredientId: 'itlog', confidence: 0.8)]);
      }
      expect(acc.detected, contains('itlog'));

      // Pan away — 5 empty frames.
      for (var i = 0; i < 5; i++) {
        acc.addFrame([]);
      }

      // Still confirmed because _confirmed is sticky.
      expect(acc.detected, contains('itlog'));
    });

    // 5. sliding window drops old frames
    test('sliding window drops old frames', () {
      final acc = DetectionAccumulator(
        windowSize: 3,
        minHits: 3,
        minConfidence: 0.6,
      );

      // Confirm 'kamatis' with 3 good frames.
      for (var i = 0; i < 3; i++) {
        acc.addFrame([Prediction(ingredientId: 'kamatis', confidence: 0.8)]);
      }
      expect(acc.detected, contains('kamatis'));

      // 3 empty frames — old 'kamatis' frames drop out of the window of 3.
      for (var i = 0; i < 3; i++) {
        acc.addFrame([]);
      }

      // 'kamatis' stays because it was already confirmed.
      expect(acc.detected, contains('kamatis'));

      // Add 'itlog' in only 2 of the last 3 frames (window = 3, need 3 hits).
      acc.addFrame([Prediction(ingredientId: 'itlog', confidence: 0.9)]);
      acc.addFrame([Prediction(ingredientId: 'itlog', confidence: 0.9)]);
      acc.addFrame([]); // 3rd frame has no itlog

      // 'itlog' has only 2 hits in the window of 3, needs minHits=3 → not detected.
      expect(acc.detected, isNot(contains('itlog')));
    });

    // 6. reset clears all detections and frame history
    test('reset clears all detections and frame history', () {
      final acc = DetectionAccumulator(
        windowSize: 5,
        minHits: 3,
        minConfidence: 0.6,
      );

      for (var i = 0; i < 3; i++) {
        acc.addFrame([Prediction(ingredientId: 'itlog', confidence: 0.8)]);
      }
      expect(acc.detected, contains('itlog'));

      acc.reset();

      expect(acc.detected, isEmpty);
      expect(acc.frameCount, equals(0));
    });

    // 7. _none predictions are ignored
    test('_none predictions are ignored', () {
      final acc = DetectionAccumulator(
        windowSize: 5,
        minHits: 3,
        minConfidence: 0.6,
      );

      for (var i = 0; i < 5; i++) {
        acc.addFrame([Prediction(ingredientId: '_none', confidence: 0.99)]);
      }

      expect(acc.detected, isEmpty);
    });

    // 8. multiple ingredients detected independently
    test('multiple ingredients detected independently', () {
      final acc = DetectionAccumulator(
        windowSize: 5,
        minHits: 3,
        minConfidence: 0.6,
      );

      for (var i = 0; i < 3; i++) {
        acc.addFrame([
          Prediction(ingredientId: 'itlog', confidence: 0.8),
          Prediction(ingredientId: 'kamatis', confidence: 0.7),
        ]);
      }

      expect(acc.detected, contains('itlog'));
      expect(acc.detected, contains('kamatis'));
    });

    // 9. vocabulary filter ignores unknown ids
    test('vocabulary filter ignores unknown ids', () {
      final acc = DetectionAccumulator(
        windowSize: 5,
        minHits: 3,
        minConfidence: 0.6,
        vocabulary: {'itlog'},
      );

      for (var i = 0; i < 3; i++) {
        acc.addFrame([
          Prediction(ingredientId: 'unknownIngredient', confidence: 0.9),
        ]);
      }

      expect(acc.detected, isNot(contains('unknownIngredient')));
    });

    // 10. frameCount increments correctly
    test('frameCount increments correctly', () {
      final acc = DetectionAccumulator(
        windowSize: 5,
        minHits: 3,
        minConfidence: 0.6,
      );

      for (var i = 0; i < 4; i++) {
        acc.addFrame([]);
      }
      expect(acc.frameCount, equals(4));

      acc.reset();
      expect(acc.frameCount, equals(0));
    });
  });
}
