import 'dart:io';
import 'package:path_provider/path_provider.dart';

// ---------------------------------------------------------------------------
// ModelStatus / ModelFileStatus
// ---------------------------------------------------------------------------
enum ModelStatus { missing, present, loading, ready, failed }

class ModelFileStatus {
  final ModelStatus status;
  final String? failureReason;

  const ModelFileStatus({required this.status, this.failureReason});
}

// ---------------------------------------------------------------------------
// ModelStore
// ---------------------------------------------------------------------------
class ModelStore {
  /// If set, overrides path_provider lookups (used in tests).
  final String? testBasePath;

  ModelStore({this.testBasePath});

  // -------------------------------------------------------------------------
  // Directory helpers
  // -------------------------------------------------------------------------

  /// Returns the full path to the models directory, creating it if needed.
  Future<String> getModelsDirectory() async {
    final base = await _baseDir();
    final modelsDir = Directory('$base/models');
    if (!modelsDir.existsSync()) {
      await modelsDir.create(recursive: true);
    }
    return modelsDir.path;
  }

  Future<String> _baseDir() async {
    if (testBasePath != null) return testBasePath!;
    final dir = await getExternalStorageDirectory() ??
        await getApplicationDocumentsDirectory();
    return dir.path;
  }

  // -------------------------------------------------------------------------
  // Vision model check
  // -------------------------------------------------------------------------

  /// Checks for ingredient_classifier.tflite, labels.txt, and
  /// model_config.json in the models directory.
  /// Returns [ModelStatus.present] only if ALL three exist and are > 0 bytes.
  Future<ModelFileStatus> checkVisionModel() async {
    try {
      final dir = await getModelsDirectory();
      final tflite = File('$dir/ingredient_classifier.tflite');
      final labels = File('$dir/labels.txt');
      final config = File('$dir/model_config.json');

      if (!tflite.existsSync() ||
          !labels.existsSync() ||
          !config.existsSync()) {
        return const ModelFileStatus(status: ModelStatus.missing);
      }

      if (tflite.lengthSync() == 0 ||
          labels.lengthSync() == 0 ||
          config.lengthSync() == 0) {
        return const ModelFileStatus(status: ModelStatus.missing);
      }

      return const ModelFileStatus(status: ModelStatus.present);
    } catch (e) {
      return ModelFileStatus(
          status: ModelStatus.failed, failureReason: e.toString());
    }
  }

  // -------------------------------------------------------------------------
  // LLM model check
  // -------------------------------------------------------------------------

  /// Checks for any .gguf file in the models directory.
  /// Returns [ModelStatus.present] if at least one .gguf exists and is > 0 bytes.
  Future<ModelFileStatus> checkLlmModel() async {
    try {
      final dir = await getModelsDirectory();
      final gguf = await _findGguf(dir);

      if (gguf == null) {
        return const ModelFileStatus(status: ModelStatus.missing);
      }
      return const ModelFileStatus(status: ModelStatus.present);
    } catch (e) {
      return ModelFileStatus(
          status: ModelStatus.failed, failureReason: e.toString());
    }
  }

  /// Returns the full path to the first .gguf file found, or null if none.
  Future<String?> getLlmModelPath() async {
    try {
      final dir = await getModelsDirectory();
      return await _findGguf(dir);
    } catch (_) {
      return null;
    }
  }

  // -------------------------------------------------------------------------
  // Private helpers
  // -------------------------------------------------------------------------

  Future<String?> _findGguf(String dirPath) async {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) return null;

    final entries = dir.listSync();
    for (final entry in entries) {
      if (entry is File && entry.path.endsWith('.gguf')) {
        if (entry.lengthSync() > 0) {
          return entry.path;
        }
      }
    }
    return null;
  }
}
