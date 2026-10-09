// Detector interface — T6
import 'package:camera/camera.dart';
import 'package:snapfood/domain/accumulator.dart';

// Prediction is defined in accumulator.dart — imported above.

// ---------------------------------------------------------------------------
// IngredientDetector
// ---------------------------------------------------------------------------

abstract class IngredientDetector {
  /// True when running in mock/debug mode — UI shows a MOCK badge.
  bool get isMock;

  /// Load model into memory. Throws on failure.
  Future<void> load();

  /// Run inference on a live camera frame.
  /// Returns top-K predictions sorted by confidence descending.
  Future<List<Prediction>> predict(CameraImage image);

  /// Run inference on a file path (photo fallback).
  Future<List<Prediction>> predictFromFile(String imagePath);

  /// Release resources.
  Future<void> dispose();
}
