// TfliteClassifierDetector — real inference stub.
// tflite_flutter is NOT added to pubspec.yaml yet.
// See docs/DECISIONS.md for rationale.
// ignore_for_file: unused_field

import 'package:camera/camera.dart';
import 'package:snapfood/domain/accumulator.dart';
import 'package:snapfood/ml/detector.dart';
import 'package:snapfood/ml/model_store.dart';

// ---------------------------------------------------------------------------
// TfliteClassifierDetector
// ---------------------------------------------------------------------------

/// Stub that throws [UnimplementedError] until tflite_flutter is integrated.
/// The team must verify Android ABI support before adding the dependency —
/// see docs/DECISIONS.md.
class TfliteClassifierDetector implements IngredientDetector {
  final ModelStore _modelStore;

  TfliteClassifierDetector(this._modelStore);

  @override
  bool get isMock => false;

  @override
  Future<void> load() async {
    throw UnimplementedError(
      'TfliteClassifierDetector.load(): tflite_flutter binding not yet '
      'integrated. Add tflite_flutter to pubspec.yaml after confirming Android '
      'ABI support, then implement this method. See PRD §17.6.',
    );
  }

  @override
  Future<List<Prediction>> predict(CameraImage image) async {
    throw UnimplementedError('TfliteClassifierDetector not yet implemented.');
  }

  @override
  Future<List<Prediction>> predictFromFile(String imagePath) async {
    throw UnimplementedError('TfliteClassifierDetector not yet implemented.');
  }

  @override
  Future<void> dispose() async {}
}
