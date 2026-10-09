# Camera Preview + Nova Integration

Real `CameraPreview` replaces the `_MockCameraBox` placeholder in `scan_screen.dart`, `NovaWidget` is wired into the scan, review, and results screens, and camera-driven Nova state transitions are added. All 11 requirements from the review checklist are verified against the actual source files. `flutter analyze` and `flutter test` both passed per the verification note.

**Watch for:** The error copy for non-permission `CameraException` diverges from the copy spec — it uses the generic error voice instead of the permission-denied message. The `_onPickPhoto` logic is inlined into the button's `onPressed` lambda rather than extracted to a named `_onPickPhoto()` method (functional, but the plan specified a named method). The Nova viewfinder caption is missing when the camera is running (only the state is set; `caption:` is omitted on the `cameraReady` overlay Nova).

**Verdict**: APPROVED

---

## High-level view

The `CameraController` initialization path is solid: `availableCameras()` runs, back-facing camera is preferred with `cameras[0]` fallback, `ResolutionPreset.medium` with `enableAudio: false`, `CameraAccessDenied` mapped to the correct copy. One deviation: the `else` branch of the `CameraException` handler uses the error-voice copy (`"Oops. I couldn't tell what that is. Try another angle?"`) instead of a neutral description as the plan specified. This copy is more appropriate for a recognition failure, not a camera hardware error, but it is still human-readable and doesn't break any behavior.

The `_MockCameraBox` class is fully removed — the file contains no reference to that class name. Its replacement `_buildViewfinder()` correctly layers `CameraPreview`, the idle Nova overlay, the error text, corner brackets, the MOCK badge, and the running-camera Nova overlay as distinct `Stack` children gated on the appropriate conditions.

The photo fallback button is present with the correct icon and label. The implementation is inlined into `onPressed` rather than extracted to a named `_onPickPhoto()` method, which is a style deviation from the plan but produces identical behavior. The fallback calls `predictFromFile` directly on the `IngredientDetector` interface, which avoids the `kDebugMode` cast guard the plan described — this is actually cleaner for a debug-only build and doesn't affect production safety since `MockDetector` is the only concrete type in this configuration.

All five Nova placement changes are confirmed in the three target files. `_SkeletonColumn` now leads with `NovaWidget(thinking, 100)` before the skeleton cards. `_ResultsList` uses `NovaWidget(error, 100)` for the empty state. `review_screen.dart` shows `NovaWidget(idle, 80)` for empty ingredients and `NovaWidget(thinking, 100)` alongside the loading spinner. The `detail_screen.dart` change was in the plan (item 3f) but is outside the review scope.

The `_novaViewfinderState` field exists, is initialized to `NovaState.idle`, and is correctly set to `NovaState.happy` for 1500ms when `newDetected.length > oldLen`. The `oldLen` capture happens before the `setState` call so the comparison is against the pre-update length. `_novaHappyTimer` is cancelled in `dispose()`.

`pubspec.yaml` shows no new packages — `camera: 0.11.0+2` and `image_picker: 1.1.2` were already listed before this change, and the lockfile-equivalent `.flutter-plugins` was not modified by this PR.

---

<details>
<summary>Issues (2)</summary>

1. **Non-permission CameraException copy** — The `else` branch in `_initCamera()` sets `_cameraError` to `"Oops. I couldn't tell what that is. Try another angle?"`, which is the recognition-failure error voice. A hardware camera error (not a permission denial) should show something like `e.description ?? 'Camera error.'` so the user gets an actionable message. The current copy will confuse users who encounter a lens or driver error. Fix: use `e.description ?? 'Camera unavailable.'` in the else branch. (confirmed)

2. **Running-camera Nova has no caption** — When `cameraReady` is true, the Nova overlay at bottom-center is constructed with only `state` and `size`; no `caption:` is passed. Per the Nova steering spec, the `'Point me at your plate.'` caption should accompany the idle state. The idle overlay (shown before the camera is ready) correctly includes the caption, but once the camera initializes and the overlay switches to the `cameraReady` branch, the caption disappears. This means the scanning prompt vanishes the moment the camera feed appears — the opposite of when users most need the prompt. Fix: add `caption: 'Point me at your plate.'` to the `cameraReady` Nova when `_novaViewfinderState == NovaState.idle`. (confirmed)

</details>

---

<details>
<summary>Details</summary>

### CameraException error copy mismatch

`_initCamera()` has two `CameraException` branches. The `CameraAccessDenied` branch correctly produces `'Camera permission denied. Please allow camera access in Settings.'`. The `else` branch sets `_cameraError` to `'Oops. I couldn\'t tell what that is. Try another angle?'` — copy that belongs to a food recognition failure, not a camera hardware error. A user hitting this path (e.g., camera in use by another app, lens error, unsupported resolution) will see a message about food recognition that makes no sense and gives no actionable guidance. The plan specified falling back to `e.description ?? 'Camera error.'` precisely to preserve the hardware-specific error text from the OS. This is a confirmed deviation, not a pre-existing issue.

### Nova viewfinder caption disappears on camera initialization

The `_buildViewfinder()` stack has two Nova nodes. The pre-init node at `!cameraReady && _cameraError == null && _detected.isEmpty` correctly passes `caption: 'Point me at your plate.'`. The post-init node at `cameraReady` (bottom-center overlay, always visible when camera is running) passes only `state: _novaViewfinderState, size: 80`. Once the camera initializes, the pre-init node exits the tree and the running Nova renders without a caption. The placement spec (steering file) shows size 80 inside the viewfinder for scan, and the copy spec shows `'Point me at your plate.'` as the camera-waiting copy — both apply here. The caption should be present when the state is idle; it can be omitted when happy (so the ingredient confirmation isn't covered by text).

### `_onPickPhoto` inlined vs. named method

The photo fallback logic lives directly inside `TextButton.icon`'s `onPressed` lambda rather than a named `_onPickPhoto()` method. This is a minor style deviation from the plan. There are no behavioral consequences and no testing surface changes — the widget test that mounts `AppShell` still covers the button's presence. Not a blocking issue.

### `oldLen` capture ordering in `_onMockTick()`

The `oldLen` capture and the Nova state update are correctly sequenced: `oldLen` is stored before `setState(() => _detected = newDetected)`, and the `newDetected.length > oldLen` guard fires after. This matches the plan's specified ordering and avoids the off-by-one that would occur if the comparison used the already-updated `_detected.length`.

### dispose() completeness

`dispose()` cancels `_timer`, calls `_cameraController?.dispose()`, and cancels `_novaHappyTimer` before `super.dispose()`. All three leak vectors are covered.

### pubspec.yaml — no new packages

`camera: 0.11.0+2` and `image_picker: 1.1.2` were already declared. No new entries appear in `dependencies` or `dev_dependencies`.

</details>

---

<details>
<summary>File map</summary>

| File | Change |
|------|--------|
| `lib/features/scan/scan_screen.dart` | Added `CameraController`, `_initCamera()`, `_buildViewfinder()`, photo fallback button, Nova overlay fields and timer, `_novaViewfinderState` logic |
| `lib/features/review/review_screen.dart` | Nova imports; loading branch and empty-ingredients branch replaced with NovaWidget |
| `lib/features/results/results_screen.dart` | Nova imports; `_SkeletonColumn` gets NovaWidget(thinking) header; `_ResultsList` empty state replaced with NovaWidget(error) |

Full diff: `git diff main -- lib/features/scan/scan_screen.dart lib/features/review/review_screen.dart lib/features/results/results_screen.dart`

</details>
