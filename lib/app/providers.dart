import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapfood/core/config_loader.dart';
import 'package:snapfood/data/asset_loader.dart';
import 'package:snapfood/data/preferences_store.dart';
import 'package:snapfood/domain/models.dart';
import 'package:snapfood/ml/detector.dart';
import 'package:snapfood/ml/mock_detector.dart';
import 'package:snapfood/ml/model_store.dart';
import 'package:snapfood/ml/photo_picker_service.dart';
import 'package:snapfood/ml/tflite_detector.dart';

// ---------------------------------------------------------------------------
// App-wide providers
// ---------------------------------------------------------------------------

/// Loads AppConfig once from assets/config/app_config.json.
final appConfigProvider = FutureProvider<AppConfig>((ref) => AppConfig.load());

/// ModelStore singleton.
final modelStoreProvider = Provider<ModelStore>((ref) => ModelStore());

/// Vision model file status — watched by UI.
final visionModelStatusProvider = FutureProvider<ModelFileStatus>((ref) {
  return ref.watch(modelStoreProvider).checkVisionModel();
});

/// LLM model file status — watched by UI.
final llmModelStatusProvider = FutureProvider<ModelFileStatus>((ref) {
  return ref.watch(modelStoreProvider).checkLlmModel();
});

/// Preferences — loaded once, updated on save.
final preferencesProvider = FutureProvider<Preferences>((ref) {
  return PreferencesStore().load();
});

// ---------------------------------------------------------------------------
// Bundle
// ---------------------------------------------------------------------------

/// Loads AppBundle (ingredients + recipes + prices) once from assets.
final appBundleProvider = FutureProvider<AppBundle>((ref) => AppBundle.load());

// ---------------------------------------------------------------------------
// Detector
// ---------------------------------------------------------------------------

/// The active detector.
/// - Debug: [MockDetector] using vocabulary from the loaded bundle.
/// - Release: [TfliteClassifierDetector] (throws UnimplementedError until
///   tflite_flutter is integrated — see docs/DECISIONS.md).
final detectorProvider = Provider<IngredientDetector>((ref) {
  if (kDebugMode) {
    final bundleAsync = ref.watch(appBundleProvider);
    final vocab = bundleAsync.maybeWhen(
      data: (b) => b.ingredients.map((i) => i.id).toList(),
      orElse: () => <String>[],
    );
    return MockDetector(vocab);
  }
  return TfliteClassifierDetector(ref.watch(modelStoreProvider));
});

// ---------------------------------------------------------------------------
// Photo picker
// ---------------------------------------------------------------------------

/// Singleton [PhotoPickerService] — wraps image_picker.
final photoPickerProvider = Provider<PhotoPickerService>(
  (ref) => PhotoPickerService(),
);

// ---------------------------------------------------------------------------
// Scan state
// ---------------------------------------------------------------------------

/// Owned ingredients — shared across scan and review screens.
final ownedIngredientsProvider = StateProvider<Set<String>>((ref) => {});
