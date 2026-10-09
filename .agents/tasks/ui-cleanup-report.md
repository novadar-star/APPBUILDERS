# UI Cleanup Report — 2026-10-09

## Files changed

### lib/features/results/results_screen.dart
- Removed `TagChip(text: 'SAMPLE BASE RECIPE', ...)` from `_RecipeCard`'s top tags row (Task 2).
- Removed dead `isLoading` variable computed in `ResultsScreen.build` (Task 5).
- Removed `isLoading: isLoading` argument from `_ResultsList(...)` constructor call (Task 5).
- Removed dead `if (isLoading) ...[ Text, SizedBox, LinearProgressIndicator, SizedBox ]` block from `_ResultsList.build` (Task 5).

### lib/features/detail/detail_screen.dart
- Removed `import 'package:flutter/foundation.dart'` (no longer needed after MOCK chip removal) (Task 4).
- Removed `Text('SAMPLE PRICES', ...)` from `_CostFooter` Column (Task 3).
- Removed `if (kDebugMode) ...[ SizedBox(width: 8), TagChip(text: 'MOCK', ...) ]` block from `_AdaptationBanner` success state (Task 4).
- Removed unconditional `const SizedBox(height: 16)` before steps section in `_AdaptedRecipeView` (Task 6).
- Removed unconditional `const SizedBox(height: 16)` before steps section in `_BaseRecipeView` (Task 6).
- Changed `context.go('/results')` to `context.pop()` in `DetailScreen` AppBar back button (Task 7).
- Updated default `_AdaptationBanner` (idle state): container color `errorContainer` → `surfaceContainerHigh`, icon `Icons.warning_amber_outlined` → `Icons.info_outline`, icon/text color `onErrorContainer` → `onSurfaceVariant`, text `'showing base recipe · language model not installed'` → `'Tap a recipe to see your personalized adaptation.'` (Task 11).

### lib/features/scan/scan_screen.dart
- Changed AppBar title `'scan ingredients'` → `'Scan Ingredients'` (Task 8).
- Changed `FilledButton` Done copy from `'looks good'` → `'Use This Photo'` (Task 9).

### lib/features/review/review_screen.dart
- Changed AppBar title `'what you\'ve got'` → `'What You\'ve Got'` (Task 8).

### docs/DECISIONS.md
- Appended `## Mosaic hero — 2026-10-09` entry documenting the decision to keep and simplify the mosaic hero (Task 10).

## Verification
- `flutter analyze`: **No issues found** (0 errors, 0 warnings introduced).
- `detail_screen.dart` AppBar title `'Recipe'` was already correctly cased — no change needed.
- `results_screen.dart` AppBar title `'Here\'s What You Can Make'` was already correct — no change needed.
- `home_screen.dart` has no AppBar (uses a `Scaffold` body with no `AppBar`) — no change needed.

## Tasks skipped
- **Task 1** (device_preview removal): confirmed already clean per workflow instructions.
