import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapfood/core/config_loader.dart';
import 'package:snapfood/data/preferences_store.dart';
import 'package:snapfood/domain/models.dart';
import 'package:snapfood/ml/model_store.dart';

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
