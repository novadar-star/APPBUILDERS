# SnapFood Flutter UI — Semantic Code Review (Post-Iteration-2)

The UI overhaul replaced hardcoded colors and font sizes with Material 3 ColorScheme and TextTheme roles, introduced `SnapFoodShapes` as a `ThemeExtension` to unify border radii, added a dark theme via `buildDarkTheme()`, and replaced the plain loading indicator on `results_screen.dart` with a skeleton card pattern. Two prior blocking findings (hardcoded viewfinder color and `Colors.white54` label) were resolved in iteration 2. Both non-blocking shape-hardcode issues in `detail_screen.dart` and `review_screen.dart` were also cleaned up.

Watch for: (1) `CircularProgressIndicator` still present in `detail_screen.dart` and `review_screen.dart` loading states — the criterion requires it on `results_screen.dart` specifically, but its presence elsewhere should be noted. (2) `TagChip` hardcodes `BorderRadius.circular(8)` for its chip shape rather than reading `SnapFoodShapes.chip` from the theme — confirmed inconsistency with the shape system. (3) `_StepRow`'s step-number badge uses `BorderRadius.circular(8)` hardcoded rather than `SnapFoodShapes.chip`. (4) `empty_state.dart` illustration container uses `BorderRadius.circular(24)` with no token backing it.

**Verdict**: APPROVED

---

## High-level view

The `SnapFoodShapes` theme extension cleanly centralizes the four radius tokens (card 16, input 12, chip 8, button 28) and all component themes in `_buildFromColorScheme` consume them. Both `buildAppTheme()` and `buildDarkTheme()` delegate to the shared builder, so dark mode is fully wired at the theme level. The widget files pick up all colors from `ColorScheme` roles with no raw `Color(0xFF...)` or named `Colors.*` values in chrome — the only color literals in the diff are seed values in `theme.dart` itself, which is correct.

The `results_screen.dart` loading path uses `_SkeletonColumn`/`_SkeletonCard` (animated opacity pulse with `LinearProgressIndicator`-style shimmer blocks) rather than a spinner, satisfying the criterion. `CircularProgressIndicator` does appear in `detail_screen.dart` and `review_screen.dart` for their bundle-loading states, which is a separate question from the criterion as written.

`TagChip` locks its border radius to `BorderRadius.circular(8)` rather than reading `SnapFoodShapes.chip`. Since `TagChip` is used widely (results cards, detail screen, adaptation banner), this makes the chip radius effectively independent of the theme token — if the design ever changes `chip` to 6 or 12, `TagChip` won't follow. The `_StepRow` step-number badge (detail screen) has the same hardcode. These are not shape-*inconsistency* issues (8dp matches the token value today) but they are shape-system contract gaps.

`SafeArea` coverage is complete on all bottom CTAs: `scan_screen.dart` wraps its pinned `FilledButton` in `SafeArea`, and `review_screen.dart`/`home_screen.dart` use `SafeArea` wrapping the entire scroll body. No `MediaQuery.of(context).padding.top` fixed offsets were observed.

The `empty_state.dart` illustration container uses `BorderRadius.circular(24)`, which has no corresponding token in `SnapFoodShapes`. This is minor — the container is illustrative chrome, not a standard chip/card/input — but it's worth noting as an untokenized radius.

---

<details>
<summary>Issues (3)</summary>

1. **TagChip chip radius not tokenized** — `tag_chip.dart` hardcodes `BorderRadius.circular(8)` instead of reading `theme.extension<SnapFoodShapes>()?.chip`. If the chip token changes, `TagChip` (used on every results card, detail banner, and scan chips) won't follow. Fix: inject `SnapFoodShapes` in `TagChip.build` and fall back to `8.0`.

2. **_StepRow badge radius not tokenized** — `detail_screen.dart` `_StepRow` uses `BorderRadius.circular(8)` for the step-number container. Same contract gap as TagChip. Fix: read `theme.extension<SnapFoodShapes>()?.chip ?? 8.0`.

3. **EmptyState illustration radius untokenized** — `empty_state.dart` uses `BorderRadius.circular(24)` for the icon container with no backing token. Not a functional issue, but it's the only radius in the codebase without a token. Consider adding a `badge` or `illustration` radius to `SnapFoodShapes`, or accepting 24dp as a one-off constant with a comment.

</details>

---

<details>
<summary>Details</summary>

### Theme system: light and dark coverage

`theme.dart` defines both `buildAppTheme()` and `buildDarkTheme()`, both seeding from `Color(0xFFE07A2F)` with `ColorScheme.fromSeed`. The dark variant passes `brightness: Brightness.dark` to `fromSeed`, so Material 3 tonal palette generation handles the full color surface hierarchy automatically. `SnapFoodShapes` is injected via `extensions: const [shapes]` in both paths through the shared `_buildFromColorScheme` builder. Dark mode criterion: **confirmed met**.

### Shape system coverage and gaps

All four `SnapFoodShapes` tokens (card 16, input 12, chip 8, button 28) are consumed in `theme.dart`'s component themes (CardTheme, InputDecorationTheme, ChipTheme, FilledButtonTheme, OutlinedButtonTheme). Widget files that needed local radius now read `theme.extension<SnapFoodShapes>()` — `detail_screen.dart`'s `_IngredientRow` uses `shapes?.chip ?? 8.0` and `review_screen.dart`'s `TextField` and search results container use `shapes?.input ?? 12.0`. These were the iteration-2 fixes.

Two callsites remain outside the token system. `TagChip` (`shared/tag_chip.dart` line with `BorderRadius.circular(8)`) is a `StatelessWidget` that could trivially call `theme.extension<SnapFoodShapes>()` in its `build` method. The `_StepRow` step-number badge in `detail_screen.dart` (the `Container` with `borderRadius: BorderRadius.circular(8)`) has the same gap. Today both happen to match the `chip` token value, so there is no visual inconsistency — but the contract is broken.

### CircularProgressIndicator on results_screen.dart

`results_screen.dart` has no `CircularProgressIndicator`. The loading path renders `_SkeletonColumn`, which stacks three `_SkeletonCard` widgets. Each card pulses via `AnimationController` + `Tween<double>(begin: 0.4, end: 1.0)` (opacity shimmer). The skeleton card structure (title bar placeholder, three text line placeholders at 80/95/70% width, two chip-shape placeholders) is a reasonable match to the loaded `_RecipeCard` shape (title, body text, chip row). Criterion: **confirmed met**.

`CircularProgressIndicator` does appear in `detail_screen.dart` (bundle loading path, line inside `body: bundleAsync.when(loading: ...)`) and in `review_screen.dart` (same pattern). The criterion only names `results_screen.dart`, so these are out of scope for blocking, but they represent an inconsistency — results gets a skeleton while detail and review get spinners for the same async bundle.

### Color and font hygiene

No `Color(0xFF...)` literals appear in widget files. The one `Colors.black` reference in `scan_screen.dart` is a drop-shadow overlay (`withValues(alpha: 0.12)`) — acceptable. No `fontSize:` overrides appear anywhere; all `.copyWith()` calls touch only `fontWeight`, `color`, `letterSpacing`, and `height`.

### SafeArea, layout bounds

`scan_screen.dart`'s pinned "Done" button is wrapped in `SafeArea` before its padding. All other screens wrap their scroll body in `SafeArea`. No `MediaQuery.of(context).padding.top` offsets found. The `ListView.builder` in `_ResultsList` uses `shrinkWrap: true` + `NeverScrollableScrollPhysics()` (max 3 items), and the search dropdown in `review_screen.dart` is bounded by `BoxConstraints(maxHeight: 160)` — no unbounded Column children.

### Haptic feedback gaps

Primary CTAs on `home_screen.dart`, `review_screen.dart`, and `results_screen.dart` card taps all have haptic. Missing: secondary CTA ("Add ingredients manually") on home, budget `ChoiceChip` and ingredient removal chips on review, ingredient chip taps on detail. All non-blocking.

</details>

---

<details>
<summary>File map</summary>

| File | What changed |
|---|---|
| `lib/app/theme.dart` | Added `buildDarkTheme()`, extracted shared `_buildFromColorScheme()`, added `SnapFoodShapes` ThemeExtension with card/input/chip/actionButton tokens |
| `lib/features/home/home_screen.dart` | All colors from ColorScheme, TextTheme roles for all text, haptic on primary CTA, SafeArea wrapping |
| `lib/features/scan/scan_screen.dart` | Viewfinder background → `colorScheme.inverseSurface`, label color → `colorScheme.onInverseSurface.withValues(alpha: 0.7)`, SafeArea on pinned button |
| `lib/features/review/review_screen.dart` | TextField and search container border radii → `shapes?.input ?? 12.0`, all colors from ColorScheme |
| `lib/features/results/results_screen.dart` | CircularProgressIndicator replaced with `_SkeletonColumn`/`_SkeletonCard` skeleton loader, LinearProgressIndicator for adaptation state |
| `lib/features/detail/detail_screen.dart` | `_IngredientRow` border radius → `shapes?.chip ?? 8.0`, all colors from ColorScheme, TextTheme roles |
| `lib/shared/tag_chip.dart` | Removed hardcoded `fontSize`, now derives from `theme.textTheme.labelSmall`; chip shape still hardcoded to 8dp |
| `lib/shared/empty_state.dart` | Colors from ColorScheme, TextTheme roles; illustration container radius (24dp) untokenized |

Full diff: `git diff main -- lib/`

</details>
