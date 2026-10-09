# SnapFood Flutter UI — Semantic Code Review

This pass reviews the UI overhaul of the SnapFood app: a new Material 3 token-driven theme, redesigned screens for Home, Scan, Review, Results, and Detail, plus shared widgets TagChip and EmptyState. A prior fix pass addressed three blocking findings (hardcoded font sizes in `results_screen.dart`, `detail_screen.dart`, and `tag_chip.dart`). The verification note confirms `flutter analyze` exits clean.

**Watch for:** One confirmed blocking issue remains — `_MockCameraBox` in `scan_screen.dart` uses `const Color(0xFF1B2E22)` as the camera viewfinder background and `Colors.white54` as its center label color. Both are hardcoded values outside the ColorScheme. One confirmed blocking issue on shape radius: `_IngredientRow` in `detail_screen.dart` uses `BorderRadius.circular(8)` inline (matching chip radius, not card radius), and while this value happens to match the chip spec, it is not sourced from `SnapFoodShapes`, making it inconsistent with the theming contract.

**Verdict**: CHANGES_REQUESTED

---

## High-level view

The theme architecture is solid. `buildAppTheme()` and `buildDarkTheme()` both derive their `ColorScheme` from `ColorScheme.fromSeed` with brightness variants, and the `SnapFoodShapes` extension centralises all four radii (card 16, input 12, chip 8, button 28). All `ThemeData` widget themes source from this extension. The light/dark requirement is met.

The screen-level color discipline is nearly complete, but `_MockCameraBox` breaks it. The viewfinder container is hardcoded to `Color(0xFF1B2E22)` (a dark green) and the center label to `Colors.white54` — neither adapts to the active `ColorScheme`. In dark mode the viewfinder may be indistinguishable from the scaffold background, and `Colors.white54` will produce low contrast against surfaces that aren't dark.

Shape usage is consistent across card-level containers (16dp), input fields (12dp in both theme and `review_screen.dart`'s inline `TextField`), and chip widgets. The `_IngredientRow` in `detail_screen.dart` hardcodes `BorderRadius.circular(8)` rather than reading from `SnapFoodShapes`, which means a future shape change will silently miss these rows.

The `SafeArea` story is clean. Every screen with a bottom CTA wraps it in `SafeArea`, and `_SkeletonColumn` / `_ResultsList` / `_DetailBody` all use `SafeArea` at scroll content level. No hardcoded status bar heights are present.

`results_screen.dart` correctly uses `LinearProgressIndicator` for the loading state. The skeleton cards now include two chip-shaped placeholder containers, matching the real card's chip row geometry.

---

<details>
<summary>Issues (2)</summary>

1. **Hardcoded viewfinder color** — `_MockCameraBox` in `scan_screen.dart` uses `Color(0xFF1B2E22)` for the camera box background. Replace with a ColorScheme token (e.g. `colorScheme.surfaceContainerLow` or `colorScheme.inverseSurface`) so it adapts in dark mode. **Blocking.**

2. **Hardcoded text color in viewfinder** — `Colors.white54` is used for the "Point at your ingredients" label inside `_MockCameraBox`. Replace with a ColorScheme-derived color (e.g. `colorScheme.onSurface.withValues(alpha: 0.54)` against the chosen background token). **Blocking.**

3. **Unthemed shape in `_IngredientRow`** — `detail_screen.dart` hardcodes `BorderRadius.circular(8)` in `_IngredientRow`'s container decoration. Read from `Theme.of(context).extension<SnapFoodShapes>()?.chip ?? 8.0` to stay in sync with the shape system. **Non-blocking** (value currently matches chip spec, but breaks the contract).

</details>

---

<details>
<summary>Details</summary>

### Hardcoded colors in the camera viewfinder

`_MockCameraBox` (`scan_screen.dart`, the `Container` at the top of its `build` method) sets its background to `const Color(0xFF1B2E22)` — a fixed dark green. The center `Text` uses `Colors.white54`. Neither value participates in the `ColorScheme`.

In light mode this produces a dark viewfinder that contrasts correctly against the scaffold, but the contrast is accidental. In dark mode, depending on the seed color's surface tone, `Color(0xFF1B2E22)` may sit close to `colorScheme.surface`, making the viewfinder boundary invisible. `Colors.white54` is explicitly non-adaptive; against a light surface it would render nearly invisible.

The corner bracket `_CornerPainter` and the accent-fill overlay both correctly receive `accentColor` from `colorScheme.primary`, so the fix is isolated to the container background and the center label.

### Shape contract gap in `_IngredientRow`

`detail_screen.dart`'s `_IngredientRow` decorates each ingredient row container with `BorderRadius.circular(8)` (confirmed at line ~490 in the file). This matches the chip radius in `SnapFoodShapes.chip`, but the value is a magic number rather than a lookup from the extension. If the designer changes the chip token, ingredient rows won't follow.

The correct read is:

```dart
final shapes = Theme.of(context).extension<SnapFoodShapes>();
BorderRadius.circular(shapes?.chip ?? 8.0)
```

### `review_screen.dart` inline `TextField` borders

The `TextField` in `_buildBody` specifies its own `border` and `enabledBorder` with `BorderRadius.circular(12)` rather than inheriting from `InputDecorationTheme`. This duplicates the input radius but keeps it in sync only by coincidence. A change to `SnapFoodShapes.input` won't propagate here. Worth noting, though it is non-blocking as long as the theme and inline value stay at 12.

### Dark mode coverage

Both `buildAppTheme()` and `buildDarkTheme()` are defined in `theme.dart` and both delegate to `_buildFromColorScheme`. The shared builder derives every color from the passed `ColorScheme`, so all tokens adapt correctly. Dark mode is fully supported at the theme layer; the viewfinder issue above is the only surface-level escape hatch.

### `CircularProgressIndicator` audit

`results_screen.dart` uses `LinearProgressIndicator` for the loading overlay in `_ResultsList`. Two `CircularProgressIndicator` instances remain: one in `detail_screen.dart`'s `bundleAsync.when(loading:)` branch and one in `review_screen.dart`'s `bundleAsync.when(loading:)` branch. The review criteria specified replacement only on `results_screen.dart`, which is done. The remaining spinners are on full-screen data-load states where circular is contextually appropriate.

### Skeleton fidelity

`_SkeletonCard` now includes a chip row (two containers, 60×24 and 80×24, `BorderRadius.circular(8)`). The real `_RecipeCard` shows a `Wrap` of `TagChip` widgets in approximately the same row position. The geometry is a close enough match for a skeleton — the chip heights and radii align with actual `TagChip` sizing.

</details>

---

<details>
<summary>File map</summary>

| File | What changed |
|---|---|
| `lib/app/theme.dart` | New file: `SnapFoodShapes` extension + `buildAppTheme()` + `buildDarkTheme()` with shared `_buildFromColorScheme` builder |
| `lib/features/home/home_screen.dart` | Full rewrite to Material 3 tokens; SafeArea on body; haptic on primary CTA; no hardcoded colors |
| `lib/features/scan/scan_screen.dart` | Draggable sheet for detected ingredients; pinned SafeArea CTA; `_MockCameraBox` with hardcoded viewfinder color (blocking) |
| `lib/features/review/review_screen.dart` | Equipment + budget preference UI; SafeArea body; inline TextField border (non-blocking divergence) |
| `lib/features/results/results_screen.dart` | Skeleton loader with chip row; LinearProgressIndicator loading overlay; ListView.builder for results list |
| `lib/features/detail/detail_screen.dart` | `_StepRow` badge uses `titleMedium` (prior fix); `_IngredientRow` hardcodes 8dp radius (non-blocking); SafeArea on scroll body |
| `lib/shared/tag_chip.dart` | Replaced hardcoded `TextStyle(fontSize: 10)` with `textTheme.labelSmall` (prior fix) |
| `lib/shared/empty_state.dart` | New shared widget; all colors from ColorScheme; no blocking issues |

