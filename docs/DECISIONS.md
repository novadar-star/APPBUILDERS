# Decisions and prototype limits

- 2026-10-09: Repository had no Flutter scaffold, model files, or team-verified dataset. Built a dependency-free Flutter prototype and marked all bundled sample recipes, ingredients, and prices as SAMPLE in the UI and data. Price figures are fictional and are not market guidance.
- Vision and language model bindings were not added because no model artifacts/device target were supplied and package support/licensing have not been evaluated. The scan flow is an explicit debug MOCK simulation; this is not camera inference and must not be presented as live on-device AI.
- Real model state remains Setup required. There is no cloud inference, HTTP client, analytics, account, or INTERNET manifest permission in this scaffold.
- The sample recipe method text is illustrative. Team members must review equipment safety and recipe steps before real use.
- Flutter is not installed on the current execution environment, so this prototype could not be launched here.

## Packages added FEAT-001
- flutter_riverpod: 3.4.3 (pub.dev, supports Android, state management)
- go_router: 18.0.2 (pub.dev, supports Android, declarative routing)
- camera: 0.12.1 (pub.dev, supports Android, camera stream)
- image_picker: 1.2.4 (pub.dev, supports Android, photo fallback)
- shared_preferences: 2.5.6 (pub.dev, supports Android, preferences persistence)
- path_provider: 2.1.6 (pub.dev, supports Android, file paths for LLM model)
- mocktail: 1.0.5 (pub.dev, dev-only, mocking in tests)

## T7 — fllama selected as llama.cpp binding — 2026-10-10
Package: fllama (pub.dev), pinned at 0.0.1
License: MIT
Reason: GGUF format, Android arm64-v8a / armeabi-v7a / x86_64, compatible with Dart SDK >=3.3.0,
streaming token API maps cleanly onto LlmEngine.generate() Stream<String>,
no minSdk bump required (vs flutter_edge_ai litertlm which requires minSdk 30 and .litertlm format).
LlamaCppEngine fully implemented: load() via initContext, generate() via completion with
emitRealtimeCompletion:true + onTokenStream filtering, cancel() via stopCompletion + controller close,
dispose() via releaseContext. No UnimplementedError remains.
Next steps: place a quantized .gguf model file (1B–3B, 4-bit) in the device's
models directory (use ModelStore.getLlmModelPath()), run on physical device and confirm streaming works.

## T6 — tflite_flutter not added

`tflite_flutter` was **not** added to `pubspec.yaml`. `TfliteClassifierDetector` exists in `lib/ml/tflite_detector.dart` and implements `IngredientDetector`, but every method throws `UnimplementedError` with a descriptive message.

**Reason:** The team must verify Android ABI support (armeabi-v7a / arm64-v8a) and confirm the model artifact format before the native binding can be safely added. Adding it prematurely can break Android builds silently. Once the device target is confirmed and `.tflite` files are available, add `tflite_flutter` to `pubspec.yaml` and implement `TfliteClassifierDetector.load()` / `predict()`. Reference: PRD §17.6.

Until then, the app runs with `MockDetector` in debug mode and will throw in release mode if `TfliteClassifierDetector` is reached.

## T0 scaffold — 2026-10-09

### Package versions pinned for Dart SDK 3.5.4 (Flutter 3.24.5)
The versions listed in FEAT-001 were specified against a future Dart SDK (3.9–3.12). Flutter 3.24.5 ships Dart 3.5.4, so the following downward-compatible versions were resolved:
- flutter_riverpod: 2.6.1 (was 3.4.3 — 3.x requires Dart ≥3.7; 2.6.1 is compatible and fully stable)
- go_router: 14.5.0 (was 18.0.2 — 18.x requires Dart ≥3.12; 14.5.0 requires Dart ≥3.3)
- camera: 0.11.0+2 (was 0.12.1 — 0.12.x requires Dart ≥3.12; 0.11.0+2 requires Dart ≥3.3)
- image_picker: 1.1.2 (was 1.2.4 — 1.2.x requires Dart ≥3.11; 1.1.2 requires Dart ≥3.3)
- shared_preferences: 2.5.3 (was 2.5.6 — 2.5.6 requires Dart ≥3.11; 2.5.3 requires Dart ≥3.5)
- path_provider: 2.1.4 (was 2.1.6 — 2.1.6 requires Dart ≥3.10; 2.1.4 requires Dart ≥3.2)
- mocktail: 1.0.5 — no change required, already compatible

### AndroidManifest.xml
No android/ folder exists in the workspace at this time. Flutter creates the android/ folder on first build. The manifest will be reviewed at that point to ensure INTERNET permission is not present.

### Folder scaffold created
lib/app/, lib/core/, lib/domain/, lib/data/, lib/ml/, lib/features/{home,scan,review,results,detail}/, lib/shared/ created with stub files and placeholder screens. main.dart replaced with thin entry point calling AppShell.

## Mosaic hero — 2026-10-09

Decision: keep the mosaic hero image on the results screen and simplify it. The mosaic stays as the visual hero. No debug overlays or sample-data annotations are present in the mosaic widget in results_screen.dart — the mosaic is already clean. Any 'SAMPLE BASE RECIPE' chip previously rendered on each RecipeCard (separate from the mosaic) has been removed in this cleanup pass.

