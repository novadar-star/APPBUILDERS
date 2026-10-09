import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapfood/ml/model_store.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('model_store_test_');
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  // Helper: create a ModelStore pointing at tempDir
  ModelStore makeStore() => ModelStore(testBasePath: tempDir.path);

  // Helper: write a non-empty file
  Future<void> writeFile(String path, String content) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
  }

  // -----------------------------------------------------------------------
  // Vision model tests
  // -----------------------------------------------------------------------

  test('vision model missing when no files exist', () async {
    final store = makeStore();
    final result = await store.checkVisionModel();
    expect(result.status, ModelStatus.missing);
  });

  test('vision model present when all three files exist', () async {
    final store = makeStore();
    final dir = await store.getModelsDirectory();

    await writeFile('$dir/ingredient_classifier.tflite', 'fake tflite data');
    await writeFile('$dir/labels.txt', 'label1\nlabel2');
    await writeFile('$dir/model_config.json', '{"version":1}');

    final result = await store.checkVisionModel();
    expect(result.status, ModelStatus.present);
  });

  test('vision model missing when tflite exists but labels.txt absent',
      () async {
    final store = makeStore();
    final dir = await store.getModelsDirectory();

    await writeFile('$dir/ingredient_classifier.tflite', 'fake tflite data');
    await writeFile('$dir/model_config.json', '{"version":1}');
    // labels.txt deliberately omitted

    final result = await store.checkVisionModel();
    expect(result.status, ModelStatus.missing);
  });

  // -----------------------------------------------------------------------
  // LLM model tests
  // -----------------------------------------------------------------------

  test('llm model missing when no gguf file', () async {
    final store = makeStore();
    final result = await store.checkLlmModel();
    expect(result.status, ModelStatus.missing);
  });

  test('llm model present when gguf file exists', () async {
    final store = makeStore();
    final dir = await store.getModelsDirectory();
    await writeFile('$dir/model.gguf', 'fake gguf data');

    final result = await store.checkLlmModel();
    expect(result.status, ModelStatus.present);
  });

  test('getLlmModelPath returns null when no gguf', () async {
    final store = makeStore();
    final path = await store.getLlmModelPath();
    expect(path, isNull);
  });

  test('getLlmModelPath returns path when gguf exists', () async {
    final store = makeStore();
    final dir = await store.getModelsDirectory();
    await writeFile('$dir/model.gguf', 'fake gguf data');

    final path = await store.getLlmModelPath();
    expect(path, isNotNull);
    expect(path, endsWith('.gguf'));
  });
}
