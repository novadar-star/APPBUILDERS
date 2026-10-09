# fllama integration — LlamaCppEngine binding

The change replaces every `UnimplementedError` stub in `LlamaCppEngine` with a real
fllama implementation covering `load()`, `generate()`, `cancel()`, and `dispose()`.
`pubspec.yaml` adds `fllama: 0.0.1` and `DECISIONS.md` gains a T7 decision entry.
The implementation pattern — wrapping fllama's broadcast stream in a `StreamController<String>`
and filtering by `contextId` — is sound in design.

**Watch for:**
- fllama 0.0.1 is **not resolved** in `.flutter-plugins` / `.flutter-plugins-dependencies`. The package may not exist on pub.dev at that version, or `pub get` was never run after adding it. This is a build-blocking concern. (confirmed)
- `google_fonts` and `device_preview` carry `^` version constraints in `pubspec.yaml`, violating the pinning requirement. (confirmed)
- `cancel()` does not close the `StreamController`, leaving the stream hanging after cancellation. (confirmed)
- The T7 DECISIONS.md entry records version `0.0.1` but dates it `2025-07-17`, which is inconsistent with the rest of the document using `2026-xx-xx` dates; and the old "T7 — llama.cpp binding not selected" placeholder was not removed. (confirmed)

**Verdict**: CHANGES_REQUESTED

---

## High-level view

The core engine logic in `LlamaCppEngine` is structurally correct: context guard on `generate()`, null-safe contextId promotion to a local variable, and proper async microtask scheduling before returning the stream. The resource management path through `dispose()` → `cancel()` → `releaseContext()` is the right order.

However, the package itself is unresolved. fllama `0.0.1` does not appear in `.flutter-plugins` or `.flutter-plugins-dependencies`, which means `flutter pub get` either hasn't been re-run since the dependency was added, or fllama `0.0.1` does not exist on pub.dev. The API surface the implementation calls (`Fllama.instance()`, `onTokenStream`, `initContext`, `releaseContext`, `completion`, `stopCompletion`) cannot be verified against the actual package without it being resolved, so there's a real risk the call signatures are wrong.

`cancel()` stops the fllama completion and cancels the broadcast subscription, but never closes the `StreamController`. Any caller awaiting the stream's `onDone` will hang indefinitely after a cancel. All other cleanup paths close the controller correctly.

`pubspec.yaml` leaves `google_fonts` and `device_preview` with `^` constraints, which contradicts the pinning policy followed for every other package.

The DECISIONS.md T7 entry has a date regression (`2025-07-17` vs. the surrounding `2026-xx-xx` dates) and the superseded "T7 — llama.cpp binding not selected" placeholder immediately precedes it without being removed, leaving two T7 entries in the document.

---

<details>
<summary>Issues (5)</summary>

1. **fllama not resolved in plugin registry** — fllama `0.0.1` is absent from `.flutter-plugins` and `.flutter-plugins-dependencies`. Run `flutter pub get`; if the package doesn't resolve, verify the version exists on pub.dev and correct it. Nothing can build until this is resolved.

2. **`cancel()` leaves StreamController open** — `cancel()` calls `stopCompletion` and cancels the subscription but never closes the `StreamController`. Add `if (!controller.isClosed) controller.close();` in `cancel()`, or factor cleanup through the shared `_cleanup()` closure. Callers that `await stream.toList()` or `await for` will hang forever on a cancelled stream.

3. **`^` constraints on `google_fonts` and `device_preview`** — Both entries in `pubspec.yaml` use `^` rather than exact versions. Pin them to exact versions (`google_fonts: 6.2.1`, `device_preview: 1.3.1` or whatever `pub get` resolves) consistent with the policy used for all other packages.

4. **Stale T7 placeholder not removed from DECISIONS.md** — The old "T7 — llama.cpp binding not selected" block remains directly before the new T7 entry. Remove it; having two T7 headings is ambiguous and the old block still says "every method throws `UnimplementedError`" which is no longer true.

5. **T7 date in DECISIONS.md is a year behind** — The new T7 entry is dated `2025-07-17` while all other entries use `2026-xx-xx`. Correct the date to match the project's current timeline.

</details>

---

<details>
<summary>Details</summary>

### Package resolution gap

fllama `0.0.1` was added to `pubspec.yaml` but the generated `.flutter-plugins` file — which lists every native plugin after `flutter pub get` — contains no fllama entry. Either `pub get` was not run after the edit, or `0.0.1` is not a published version on pub.dev. The fllama package's earliest known pub.dev release should be verified. If the version is wrong, the build will fail at the native plugin resolution step before any Dart analysis runs.

Until fllama is present in `.flutter-plugins`, every API call in `llama_cpp_engine.dart` is unverifiable. The implementation references `Fllama.instance()`, `initContext`, `releaseContext`, `completion`, `stopCompletion`, and the `onTokenStream` broadcast stream. fllama's actual API at the resolved version may differ — particularly `instance()` returning a nullable vs. non-nullable singleton, and whether `onTokenStream` is exposed as a getter on the instance or as a static. The null-bang `!` on `Fllama.instance()!` throughout the file will throw a runtime NPE if `instance()` returns null before a context is initialized.

### `cancel()` resource gap

`_cleanup()` (defined inside `generate()`) cancels the subscription and closes the controller. `cancel()` (the public method) cancels the subscription directly but skips `controller.close()`. The two code paths are inconsistent: a stream that ends naturally or on error is closed; a stream that is explicitly cancelled is not. A `StreamController` that is never closed keeps the underlying stream active — any `async for` loop listening to it will never exit its loop body after a cancel.

The fix is one line: expose `_cleanup` at the class level (or store a reference to it), and call it from `cancel()`.

### DECISIONS.md state

The file now contains two sections with the heading "T7":

```
## T7 — llama.cpp binding not selected   ← old stub, still says UnimplementedError
## T7 — fllama selected as llama.cpp binding — 2025-07-17   ← new entry
```

The old entry contradicts the current code state and will confuse anyone reading the doc linearly. The new entry is otherwise complete (version, license, reason, next steps) — the content is correct, just the date and the duplicate need fixing.

</details>

---

<details>
<summary>File map</summary>

| File | Change |
|------|--------|
| `lib/ml/llama_cpp_engine.dart` | Full implementation replacing UnimplementedError stubs with fllama calls |
| `pubspec.yaml` | Added `fllama: 0.0.1`; `google_fonts` and `device_preview` retain `^` constraints |
| `docs/DECISIONS.md` | New T7 entry appended (old T7 placeholder not removed) |

Full diff: `git diff main -- lib/ml/llama_cpp_engine.dart pubspec.yaml docs/DECISIONS.md`

</details>
