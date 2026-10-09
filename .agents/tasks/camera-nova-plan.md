# Implementation Plan — Camera Preview + Nova Integration

## Codebase findings

- `lib/features/scan/scan_screen.dart`: Has `_MockCameraBox` (StatelessWidget, dark fill, 280h, BR16, corner bracket overlay via `_CornerPainter`). Loading gate is `_accumulatorReady` bool; shows `CircularProgressIndicator` when false. `_initScanner()` sets up the accumulator then starts the debug timer. `_onMockTick()` calls `detector.simulateFrame()`, feeds `_accumulator`, diffs `_detected`. `dispose()` cancels `_timer` only. No `CameraController` yet.
- `lib/features/review/review_screen.dart`: Loading state is `bundleAsync.when(loading: ...)` → `CircularProgressIndicator`. Empty-ingredient text is a plain `Text(...)` inside an `if (ownedIds.isEmpty)` block.
- `lib/features/results/results_screen.dart`: Loading state uses `_SkeletonColumn()` (NOT a `CircularProgressIndicator` — no Nova wrapping needed at the loading branch). Empty state is `EmptyState(icon: ..., title: ..., body: ...)` inside `if (results.isEmpty)`. `_SkeletonColumn` renders 3 `_SkeletonCard`s inside a `Column` with no Nova.
- `lib/features/detail/detail_screen.dart`: Loading state is `const Center(child: CircularProgressIndicator())` on the `body:` `.when(loading:)` branch.
- `lib/shared/nova/nova_widget.dart` + `nova_state.dart` + `nova_event_map.dart`: All exist and compile. `NovaWidget(state:, size:, caption:)` API is stable.
- `lib/ml/mock_detector.dart`: `MockDetector.predictFromFile(path)` returns top-3 `Prediction` list. `simulateFrame()` returns 1 prediction. `predictFromFile` is already on the `IngredientDetector` interface in `detector.dart`.
- `lib/ml/photo_picker_service.dart`: `PhotoPickerService.pickPhoto()` returns `Future<String?>`.
- `lib/app/providers.dart`: `photoPickerProvider` exposed as `Provider<PhotoPickerService>`. `detectorProvider` returns `MockDetector` in debug.
- `pubspec.yaml`: `camera: 0.11.0+2` and `image_picker: 1.1.2` already listed. No new packages needed.
- `test/`: `flutter test` runs all files under `test/`. Relevant existing test: `nova_event_map_test.dart` (pure unit, no widgets), `widget_test.dart` (mounts `AppShell`).

---

## Items

- [ ] 1. Add real `CameraController` + `CameraPreview` to `_ScanScreenState` in `scan_screen.dart`.

  **What:** Add camera imports, a `CameraController? _cameraController` field, a `String? _cameraError` field, and a `_initCamera()` method. Call `_initCamera()` at the end of `_initScanner()`. In `_initCamera()`:
  - Call `availableCameras()` and pick the first camera with `lensDirection == CameraLensDirection.back`; fall back to index 0 if none found.
  - Construct `CameraController(camera, ResolutionPreset.medium, enableAudio: false)`.
  - `await _cameraController!.initialize()` inside a try/catch on `CameraException`.
  - On `CameraException`, set `_cameraError` to `"Camera permission denied. Please allow camera access in Settings."` when `e.code == 'CameraAccessDenied'`, otherwise `e.description ?? 'Camera error.'`; return early.
  - On success, call `setState(() {})`.
  - If `kDebugMode` and the detector is a `MockDetector`, and `_timer == null`, restart the mock timer (reuse `intervalMs` from config — read it from `_accumulator` is not exposed, so store `intervalMs` as a field `_scanIntervalMs` set in `_initScanner()`).
  - In `dispose()`, add `_cameraController?.dispose()` before `super.dispose()`.

  **Replace `_MockCameraBox`:** Keep the widget class in the file for reference but replace its usage in `_buildBody` with an inline `_buildViewfinder()` method. The new viewfinder Container is still `height: 280, borderRadius: 16`. Inside a `Stack`:
  - When `_cameraController != null && _cameraController!.value.isInitialized`: show `ClipRRect(borderRadius: BR16, child: CameraPreview(_cameraController!))` as `Positioned.fill`.
  - When `_cameraError != null`: show `Center(child: Text(_cameraError!, textAlign: TextAlign.center))` inside the container.
  - Keep the corner bracket overlay on top (all 4 `_buildCornerBracket` calls, same as now).
  - Keep the `MOCK CAMERA` badge in `kDebugMode` at top-left.
  - Remove the dark fill background `color: colorScheme.inverseSurface` from the Container when the camera is initialized; keep it as fallback while initializing (controller null and no error).
  - Remove the semi-transparent accent overlay (the `if (detected.isNotEmpty)` fill) from inside the viewfinder — that was only in `_MockCameraBox`.
  - Add the file header comment:
    ```
    // NOTE: AndroidManifest.xml needs <uses-permission android:name="android.permission.CAMERA"/> once android/ is generated.
    ```

  **Files:** `lib/features/scan/scan_screen.dart`

  **Verify:** `flutter analyze lib/features/scan/scan_screen.dart` — zero errors. `flutter test test/widget_test.dart` — passes (AppShell mounts).

---

- [ ] 2. Add photo fallback button (FR-01) to `scan_screen.dart`.

  **What:** Directly below the `_buildViewfinder()` call in `_buildBody` (replacing the existing `_MockCameraBox` row), add a `TextButton.icon`:
  ```dart
  TextButton.icon(
    onPressed: _onPickPhoto,
    icon: const Icon(Icons.photo_library_outlined),
    label: const Text('use a photo instead'),
  )
  ```
  Add `_onPickPhoto()` async method to `_ScanScreenState`:
  - `final path = await ref.read(photoPickerProvider).pickPhoto();`
  - If `path == null`, return.
  - `final detector = ref.read(detectorProvider);` — in debug, cast to `MockDetector`.
  - `final predictions = await (detector as MockDetector).predictFromFile(path);` — wrap in a `kDebugMode` guard so the cast only happens in debug; in release, call `detector.predictFromFile(path)` directly.
  - Call `_accumulator!.addFrame(predictions)` three times.
  - `setState(() { _detected = Set<String>.from(_accumulator?.detected ?? {}); })`.

  The `TextButton.icon` goes inside the `Column` in the `SingleChildScrollView`, after the viewfinder `SizedBox(height:12)` spacer, before the debug button block. Keep the existing `if (_detected.isEmpty) Text('nothing spotted yet', ...)` below it.

  **Files:** `lib/features/scan/scan_screen.dart`

  **Verify:** `flutter analyze lib/features/scan/scan_screen.dart` — zero errors.

---

- [ ] 3. Wire `NovaWidget` into all specified screens.

  This item covers five placement changes across three files. Make all of them together since they share the same import pattern.

  **3a. `scan_screen.dart` — viewfinder idle state:**
  Add imports:
  ```dart
  import 'package:snapfood/shared/nova/nova_widget.dart';
  import 'package:snapfood/shared/nova/nova_state.dart';
  ```
  Inside `_buildViewfinder()`, add a new overlay layer to the `Stack`: when `(_cameraController == null || !_cameraController!.value.isInitialized) && _detected.isEmpty && _cameraError == null`, show `NovaWidget(state: NovaState.idle, size: 80, caption: 'Point me at your plate.')` centered (`Positioned.fill` wrapping `Center`). Remove the old `Center(child: Text('point at your ingredients', ...))` that was inside `_MockCameraBox` — that copy is replaced by Nova's caption.

  **3b. `scan_screen.dart` — accumulatorReady loading state:**
  In `build()`, the body gate `!_accumulatorReady` currently shows `const Center(child: CircularProgressIndicator())`. Replace with:
  ```dart
  Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        NovaWidget(state: NovaState.thinking, size: 100),
        const SizedBox(height: 16),
        const CircularProgressIndicator(),
      ],
    ),
  )
  ```

  **3c. `review_screen.dart`:**
  Add same two Nova imports. Replace the `if (ownedIds.isEmpty) Text(...)` block:
  ```dart
  if (ownedIds.isEmpty)
    Center(
      child: NovaWidget(
        state: NovaState.idle,
        size: 80,
        caption: 'nothing here yet — try scanning or add ingredients below',
      ),
    ),
  ```
  Replace the `loading: () => const Center(child: CircularProgressIndicator())` branch in `bundleAsync.when(loading: ...)`:
  ```dart
  loading: () => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        NovaWidget(state: NovaState.thinking, size: 100),
        const SizedBox(height: 16),
        const CircularProgressIndicator(),
      ],
    ),
  ),
  ```

  **3d. `results_screen.dart` — `_ResultsList` empty state:**
  Add same two Nova imports. Replace the `EmptyState(...)` widget inside `if (results.isEmpty)`:
  ```dart
  if (results.isEmpty)
    Center(
      child: NovaWidget(
        state: NovaState.error,
        size: 100,
        caption: "I can't work with that yet. More ingredients?",
      ),
    )
  ```
  Remove the `import 'package:snapfood/shared/empty_state.dart';` line only if `EmptyState` is no longer referenced anywhere else in `results_screen.dart` — check first. (It is only used in `_ResultsList`, so the import can be removed.)

  **3e. `results_screen.dart` — `_SkeletonColumn` Nova above cards:**
  In `_SkeletonColumn.build()`, add `NovaWidget(state: NovaState.thinking, size: 100, caption: 'Hmm, let me look closer…')` at the top of the `Column.children` list, before the first `_SkeletonCard()`, wrapped in a `Center`. Also add a `const SizedBox(height: 16)` spacer between Nova and the first skeleton card.

  **3f. `detail_screen.dart` — loading spinner:**
  Add same two Nova imports. In `DetailScreen.build()`, the `body: bundleAsync.when(loading: () => const Center(child: CircularProgressIndicator()), ...)` branch — replace with:
  ```dart
  loading: () => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        NovaWidget(state: NovaState.thinking, size: 100),
        const SizedBox(height: 16),
        const CircularProgressIndicator(),
      ],
    ),
  ),
  ```

  **Files:** `lib/features/scan/scan_screen.dart`, `lib/features/review/review_screen.dart`, `lib/features/results/results_screen.dart`, `lib/features/detail/detail_screen.dart`

  **Verify:** `flutter analyze` — zero errors across all four files. `flutter test` — all tests pass.

---

- [ ] 4. Add `_novaViewfinderState` field and camera-driven Nova overlay in `scan_screen.dart`.

  **What:**
  Add two new fields to `_ScanScreenState`:
  ```dart
  NovaState _novaViewfinderState = NovaState.idle;
  Timer? _novaTimer;
  ```

  In `_onMockTick()`, after `setState(() => _detected = newDetected)`, add:
  ```dart
  if (newDetected.length > _detected.length) {
    setState(() => _novaViewfinderState = NovaState.happy);
    _novaTimer?.cancel();
    _novaTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _novaViewfinderState = NovaState.idle);
    });
  }
  ```
  Note: the diff comparison must happen **before** `_detected` is updated — restructure `_onMockTick` so the old `_detected` length is captured before the setState, then compare after. Concretely:
  ```dart
  final oldLen = _detected.length;
  // ... existing setState to update _detected ...
  if (newDetected.length > oldLen) { ... }
  ```

  In `dispose()`, add `_novaTimer?.cancel()` alongside `_timer?.cancel()`.

  In `_buildViewfinder()`, add a second Nova overlay layer to the Stack: when `_cameraController != null && _cameraController!.value.isInitialized`, show `NovaWidget(state: _novaViewfinderState, size: 80)` at `Alignment.bottomCenter`, with 16px bottom padding:
  ```dart
  if (_cameraController != null && _cameraController!.value.isInitialized)
    Positioned(
      bottom: 16,
      left: 0,
      right: 0,
      child: Center(
        child: NovaWidget(state: _novaViewfinderState, size: 80),
      ),
    ),
  ```

  **Files:** `lib/features/scan/scan_screen.dart`

  **Verify:** `flutter analyze lib/features/scan/scan_screen.dart` — zero errors. `flutter test` — full suite passes.

---

## Final verification

After all four items are applied:

```
flutter analyze
flutter test
```

Both must exit 0 with zero errors/failures. Fix any issues before marking the plan complete.

## Order notes

- Items 1 and 2 both only touch `scan_screen.dart` and have no cross-file dependency — item 2 depends on item 1's `_buildViewfinder()` refactor existing, so do 1 before 2.
- Item 3 depends on item 1 (`_buildViewfinder()` must exist before adding Nova overlays inside it) and can be done alongside item 2 changes in the same file edit pass.
- Item 4 depends on item 1 (camera initialized state) and item 3 (Nova imports already in scan_screen).
- Recommended execution order: 1 → 2 → 3 → 4.
