// Tests for MockDetector — T6
// No real CameraImage needed: simulateFrame() and predictFromFile() are used.

import 'package:flutter_test/flutter_test.dart';
import 'package:snapfood/ml/mock_detector.dart';

void main() {
  // Vocabulary shared by most tests.
  const vocab = ['itlog', 'kamatis', 'sibuyas'];

  group('MockDetector', () {
    // 1. isMock is true
    test('isMock is true', () {
      final d = MockDetector(vocab);
      expect(d.isMock, isTrue);
    });

    // 2. load() completes without error
    test('load() completes without error', () async {
      final d = MockDetector(vocab);
      await expectLater(d.load(), completes);
    });

    // 3. predictFromFile returns predictions from vocabulary
    test('predictFromFile returns predictions from vocabulary', () async {
      final d = MockDetector(vocab);
      final results = await d.predictFromFile('/fake/path/image.jpg');
      expect(results, isNotEmpty);
      for (final p in results) {
        expect(vocab, contains(p.ingredientId));
        expect(p.confidence, greaterThan(0.0));
        expect(p.confidence, lessThanOrEqualTo(1.0));
      }
    });

    // 4. simulateFrame cycles through vocabulary across calls
    test('simulateFrame cycles through vocabulary across calls', () async {
      final d = MockDetector(vocab);
      final seen = <String>{};
      // Call enough times to visit all vocab entries.
      for (var i = 0; i < vocab.length * 2; i++) {
        final predictions = await d.simulateFrame();
        if (predictions.isNotEmpty) seen.add(predictions.first.ingredientId);
      }
      // Should have seen more than one unique ingredient.
      expect(seen.length, greaterThan(1));
    });

    // 5. returns empty list for empty vocabulary
    test('returns empty list for empty vocabulary', () async {
      final d = MockDetector([]);
      final frame = await d.simulateFrame();
      final file = await d.predictFromFile('/any/path');
      expect(frame, isEmpty);
      expect(file, isEmpty);
    });

    // 6. dispose() completes without error
    test('dispose() completes without error', () async {
      final d = MockDetector(vocab);
      await expectLater(d.dispose(), completes);
    });
  });
}
