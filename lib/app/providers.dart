import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapfood/core/config_loader.dart';
import 'package:snapfood/data/asset_loader.dart';
import 'package:snapfood/data/preferences_store.dart';
import 'package:snapfood/domain/adaptation_service.dart';
import 'package:snapfood/domain/models.dart';
import 'package:snapfood/ml/detector.dart';
import 'package:snapfood/ml/llama_cpp_engine.dart';
import 'package:snapfood/ml/llm_engine.dart';
import 'package:snapfood/ml/mock_detector.dart';
import 'package:snapfood/ml/mock_llm_engine.dart';
import 'package:snapfood/ml/model_store.dart';
import 'package:snapfood/ml/photo_picker_service.dart';
import 'package:snapfood/ml/tflite_detector.dart';
import 'package:snapfood/shared/on_device_badge.dart';

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
// On-device badge status
// ---------------------------------------------------------------------------

/// Resolved badge status for the vision model.
/// Returns [BadgeModelStatus.mock] in debug mode regardless of file presence,
/// so the demo always shows "MOCK" when running mock implementations.
final visionBadgeStatusProvider = Provider<BadgeModelStatus>((ref) {
  if (kDebugMode) return BadgeModelStatus.mock;
  final async = ref.watch(visionModelStatusProvider);
  return async.when(
    data: (s) => _mapModelStatus(s.status),
    loading: () => BadgeModelStatus.loading,
    error: (_, __) => BadgeModelStatus.setupRequired,
  );
});

/// Resolved badge status for the LLM.
/// Returns [BadgeModelStatus.mock] in debug mode.
final llmBadgeStatusProvider = Provider<BadgeModelStatus>((ref) {
  if (kDebugMode) return BadgeModelStatus.mock;
  final async = ref.watch(llmModelStatusProvider);
  return async.when(
    data: (s) => _mapModelStatus(s.status),
    loading: () => BadgeModelStatus.loading,
    error: (_, __) => BadgeModelStatus.setupRequired,
  );
});

BadgeModelStatus _mapModelStatus(ModelStatus status) {
  switch (status) {
    case ModelStatus.ready:
      return BadgeModelStatus.ready;
    case ModelStatus.loading:
      return BadgeModelStatus.loading;
    case ModelStatus.present:
      return BadgeModelStatus.ready;
    case ModelStatus.missing:
    case ModelStatus.failed:
      return BadgeModelStatus.setupRequired;
  }
}

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

// ---------------------------------------------------------------------------
// LLM
// ---------------------------------------------------------------------------

/// LLM engine — [MockLlmEngine] in debug, [LlamaCppEngine] in release.
final llmEngineProvider = Provider<LlmEngine>((ref) {
  if (kDebugMode) return MockLlmEngine();
  return LlamaCppEngine();
});

/// [AdaptationService] — one per app, null until bundle and config are loaded.
final adaptationServiceProvider = Provider<AdaptationService?>((ref) {
  final bundleAsync = ref.watch(appBundleProvider);
  final configAsync = ref.watch(appConfigProvider);
  return bundleAsync.maybeWhen(
    data: (bundle) => configAsync.maybeWhen(
      data: (config) => AdaptationService(
        engine: ref.watch(llmEngineProvider),
        vocabulary: bundle.ingredients,
        prices: bundle.prices,
        config: config.llm,
      ),
      orElse: () => null,
    ),
    orElse: () => null,
  );
});

// ---------------------------------------------------------------------------
// Adaptation state
// ---------------------------------------------------------------------------

class AdaptationState {
  final bool isRunning;
  final List<String> tokens; // raw tokens streamed so far
  final AdaptedRecipe? result; // set when Parsed event fires
  final bool fellBack; // true if FellBack event fired
  final String? error;
  final int elapsedMs; // wall-clock ms since generation started

  const AdaptationState({
    this.isRunning = false,
    this.tokens = const [],
    this.result,
    this.fellBack = false,
    this.error,
    this.elapsedMs = 0,
  });

  AdaptationState copyWith({
    bool? isRunning,
    List<String>? tokens,
    AdaptedRecipe? result,
    bool? fellBack,
    String? error,
    int? elapsedMs,
  }) {
    return AdaptationState(
      isRunning: isRunning ?? this.isRunning,
      tokens: tokens ?? this.tokens,
      result: result ?? this.result,
      fellBack: fellBack ?? this.fellBack,
      error: error ?? this.error,
      elapsedMs: elapsedMs ?? this.elapsedMs,
    );
  }
}

class AdaptationNotifier extends StateNotifier<AdaptationState> {
  final Ref _ref;

  AdaptationNotifier(this._ref) : super(const AdaptationState());

  Future<void> start(AdaptRequest request) async {
    final startTime = DateTime.now();
    state = const AdaptationState(isRunning: true);
    final service = _ref.read(adaptationServiceProvider);
    if (service == null) {
      state = state.copyWith(
        isRunning: false,
        error: 'Adaptation service not ready',
      );
      return;
    }
    await for (final update in service.adapt(request)) {
      final elapsed =
          DateTime.now().difference(startTime).inMilliseconds;
      switch (update.event) {
        case AdaptationEvent.token:
          state = state.copyWith(
            tokens: [...state.tokens, update.token ?? ''],
            elapsedMs: elapsed,
          );
          break;
        case AdaptationEvent.parsed:
          state = state.copyWith(
            isRunning: false,
            result: service.lastAdapted,
            elapsedMs: elapsed,
          );
          break;
        case AdaptationEvent.fellBack:
          state = state.copyWith(
            isRunning: false,
            fellBack: true,
            elapsedMs: elapsed,
          );
          break;
        case AdaptationEvent.failed:
          state = state.copyWith(
            isRunning: false,
            error: update.message,
            elapsedMs: elapsed,
          );
          break;
        default:
          break;
      }
    }
  }

  void cancel() {
    _ref.read(adaptationServiceProvider)?.cancel();
    state = state.copyWith(isRunning: false);
  }
}

/// Adaptation state — keyed by recipe id.
final adaptationProvider = StateNotifierProvider.family<AdaptationNotifier,
    AdaptationState, String>(
  (ref, recipeId) => AdaptationNotifier(ref),
);
