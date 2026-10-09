# SnapFood UI Improvement Plan

## Pre-existing issues (do not fix, do not introduce new ones)
- `withOpacity` deprecation in `lib/features/home/home_screen.dart:93` — replace with `.withValues(alpha: ...)` when touching that line.
- `test/widget_test.dart:16` references `MyApp` which doesn't exist — leave untouched.

---

## Implementation Plan

- [ ] 1. Rewrite `lib/app/theme.dart` — design system foundation.
      Replace the current green seed (`0xFF1C684E`) with the warm saffron accent `0xFFE07A2F`.
      Build both light and dark `ColorScheme.fromSeed` variants. Define a `SnapFoodTheme` class
      with static `light()` and `dark()` methods. Add `ThemeExtension<SnapFoodShapes>` carrying
      the four radii constants (card 16, input 12, chip 8, actionButton 28). Update `cardTheme`
      border-radius to 16dp. Set `FilledButton`, `OutlinedButton`, and `InputChip` / `FilterChip`
      / `ChoiceChip` shape overrides with the correct radii. No hardcoded sizes anywhere — every
      value reads from the extension or `colorScheme.*`. Remove scaffoldBackgroundColor hardcode;
      use `colorScheme.surface` instead.
      
      Decision: Use `ThemeExtension` rather than a plain constants class so every widget can access
      shapes via `Theme.of(context).extension<SnapFoodShapes>()!` without importing a separate file.
      
      Files: `lib/app/theme.dart`
      Verify: `flutter analyze` — 0 new errors/warnings introduced.

- [ ] 2. Update `lib/main.dart` (or wherever `buildAppTheme()` is called) to pass both
      `theme:` and `darkTheme:` if `buildAppTheme()` is split, or rename accordingly.
      Also update any direct `Color(0xFF1C684E)` references in `lib/app/` to use
      `colorScheme.primary` / `colorScheme.secondary`.
      
      Decision: Keep the function name `buildAppTheme()` for backward compat; add a second
      `buildDarkTheme()` exported from the same file. The coder adding dark theme is trivial
      since `ColorScheme.fromSeed` generates dark automatically with `brightness: Brightness.dark`.
      
      Files: `lib/app/theme.dart`, `lib/main.dart`
      Verify: `flutter analyze` — 0 new errors.

- [ ] 3. Rewrite `lib/features/home/home_screen.dart` — food-hero composition.
      Replace the hero card's green `Color(0xFF1C684E)` hardcodes with semantic tokens
      (`colorScheme.primaryContainer`, `colorScheme.onPrimaryContainer`, etc.).
      Add a large accent-colored illustration placeholder `Container` at the top of the hero card
      (height 160, `colorScheme.primaryContainer`, `borderRadius` 12dp, centered
      `Icon(Icons.restaurant_menu, size: 64, color: colorScheme.primary)`).
      Change the app name `Text` to use `theme.textTheme.displaySmall` (not headlineSmall).
      Change the hero headline `Text` to use `theme.textTheme.titleLarge`.
      Change the subtitle `Text` to use `theme.textTheme.bodyLarge`.
      Make the "Scan ingredients" `FilledButton` full-width pill shape
      (`BorderRadius.circular(28)` via the theme shape — no inline override needed after step 1).
      Fix the deprecated `withOpacity(0.15)` → `.withValues(alpha: 0.15)`.
      Move `OnDeviceBadgeConsumer` to be visible but after the idea text section (keep current position).
      Remove any emoji characters used as iconography — use `Icon(Icons.restaurant)` (already done).
      
      Files: `lib/features/home/home_screen.dart`
      Verify: `flutter analyze` — 0 new errors; app hot-restarts without exceptions.

- [ ] 4. Rewrite `lib/features/scan/scan_screen.dart` — scan UI overhaul.
      a) Viewfinder bounding box overlay: the mock camera box currently uses a static
         green `_CornerPainter`. Change the corner bracket color from hardcoded `0xFF4CAF50`
         to the accent color `colorScheme.primary`. Add a semi-transparent accent fill to the
         mock viewfinder rectangle: `colorScheme.primary.withValues(alpha: 0.4)` as the
         viewport tint when `_detected.isNotEmpty`.
      b) Move the detected-ingredients list from its current inline position in
         `SingleChildScrollView` to a `DraggableScrollableSheet` anchored at the bottom.
         The sheet starts at `initialChildSize: 0.25`, `minChildSize: 0.15`, `maxChildSize: 0.6`.
         Inside the sheet: a drag handle pill at top, section label in `theme.textTheme.titleSmall`,
         then a `ListView.builder` of `InputChip` rows (with delete icon).
      c) Wrap each chip in `AnimatedOpacity` (duration 300 ms, curves `Curves.easeIn`) so new
         detections fade in. Track previously-visible IDs in a `Set<String> _animatedIds` in state
         to distinguish new vs existing.
      d) The Done CTA (`FilledButton`) must sit outside and below the `DraggableScrollableSheet`,
         pinned via `Stack` + `Positioned` at the bottom, inside `SafeArea`.
      e) Replace hardcoded font sizes in `_MockCameraBox` (`fontSize: 10`, `fontSize: 14`) with
         `theme.textTheme.labelSmall` and `theme.textTheme.bodySmall` respectively.
      f) Replace the `SingleChildScrollView` outer layout with a `Stack` containing the camera
         box and the `DraggableScrollableSheet`; use `Scaffold` body directly (no outer scroll).
      
      Files: `lib/features/scan/scan_screen.dart`
      Verify: `flutter analyze` — 0 new errors; debug button still present in kDebugMode; Done
      button navigates to `/review`.

- [ ] 5. Rewrite `lib/features/review/review_screen.dart` — chip and section polish.
      a) Section headers ("Cooking equipment", "Extra budget", "Confirm what you have") must
         use `theme.textTheme.titleSmall` style (not `titleMedium`). The heading
         "Confirm what you have" uses `titleLarge`.
      b) Equipment `FilterChip`: replace hardcoded `selectedColor: Color(0xFFD4EBD8)` and
         `checkmarkColor: Color(0xFF1C684E)` with `colorScheme.primaryContainer` and
         `colorScheme.primary` respectively. Wrap the `Wrap` in a horizontal `SingleChildScrollView`
         for narrow screens.
      c) Budget `ChoiceChip`: same semantic-color replacement. Presets are already `[0, 30, 50, 100]`
         — keep them. Replace `selectedColor` with `colorScheme.primaryContainer`.
      d) Confirmed ingredient `InputChip`: replace `backgroundColor: Color(0xFFE5EEE5)` with
         `colorScheme.secondaryContainer`. Replace icon color `Color(0xFF1C684E)` with
         `colorScheme.primary`.
      e) Search `TextField` border radius is already 12dp — leave it. Replace `fillColor: Colors.white`
         with `colorScheme.surface`.
      f) Add `HapticFeedback.lightImpact()` on the `FilledButton` "Find recipes" tap before
         `_saveAndNavigate(bundle)`.
      g) Replace hardcoded color `Color(0xFF0E3D2A)` on heading text with
         `colorScheme.onSurface`.
      
      Files: `lib/features/review/review_screen.dart`
      Verify: `flutter analyze` — 0 new errors; ChoiceChip selection and FilterChip selection
      still persist state correctly.

- [ ] 6. Rewrite `lib/features/results/results_screen.dart` — skeleton loader and progressive text.
      a) Add a `_SkeletonCard` widget: a `Card` with the same shape (16dp radius from theme) that
         uses `ColorFiltered` shimmer animation via an `AnimationController` looping between
         `colorScheme.surfaceContainerHigh` and `colorScheme.surfaceContainerHighest`. Three
         placeholder `Container` strips (title: height 20, subtitle: height 14, tags: height 12)
         with 8dp vertical gaps and 4–32dp horizontal padding, mimicking the real recipe card layout.
      b) Replace the two `CircularProgressIndicator` loading guards with:
         - For `bundleAsync` loading: show a `Column` of 3 `_SkeletonCard` items.
         - For `prefsAsync` loading: same skeleton column.
      c) Add a `LinearProgressIndicator` + "Adapting recipe…" label row at the top of `_ResultsList`
         (inside the `Column`) that shows while `bundleAsync.isLoading || prefsAsync.isLoading`.
         Use `theme.textTheme.bodySmall` for the label and `colorScheme.primary` as the
         `valueColor`. The indicator has no value (indeterminate). Remove once data is ready.
      d) In `_RecipeCard`: replace hardcoded `color: Color(0xFF0E3D2A)` on recipe name with
         `colorScheme.onSurface`. Replace `color: Color(0xFF1C684E)` on "See recipe" row with
         `colorScheme.primary`. Card border radius already derives from `cardTheme` set in step 1.
      e) Add `HapticFeedback.selectionClick()` inside `_RecipeCard.onTap`.
      f) Wrap `results.map((r) => _RecipeCard(...))` inside `ListView.builder` (not `.map().toList()`)
         — pass a list and use itemBuilder. The outer `SingleChildScrollView` can remain since the
         list is at most 3 items; use `shrinkWrap: true, physics: NeverScrollableScrollPhysics()`.
      
      Files: `lib/features/results/results_screen.dart`
      Verify: `flutter analyze` — 0 new errors; navigating to `/results` shows skeleton briefly
      before recipe cards appear.

- [ ] 7. Rewrite `lib/features/detail/detail_screen.dart` — three-section ingredient layout,
      step numbering, and cost footer.
      a) `_AdaptedRecipeView` already has three sections (owned / substituted / toBuy). Update:
         - "You already have" section heading: icon `Icons.check_circle`, color `Colors.green.shade600`
           (or `colorScheme.tertiary` if it resolves green under the new seed — prefer semantic;
           use `Color(0xFF388E3C)` as fallback for green since the new seed is orange).
         - "Substitutions" section heading: icon `Icons.swap_horiz`, color `Colors.amber.shade700`
           (use `Color(0xFFF9A825)`).
         - "Items to buy" section heading: icon `Icons.shopping_cart` (replace
           `Icons.shopping_bag_outlined`), color `colorScheme.primary` (accent orange).
           Add a `TagChip`-style cost chip next to each toBuy row showing `₱{price}`.
      b) Add `Divider` between each section (after owned, after substituted). These dividers should
         use `colorScheme.outlineVariant`.
      c) `_StepRow`: replace the hardcoded circle number container
         (`color: Color(0xFF1C684E), shape: BoxShape.circle, fontSize: 12`) with:
         - Outer container: `colorScheme.primaryContainer`, 32×32, `BorderRadius.circular(8)`.
         - Number text: `theme.textTheme.displaySmall!.copyWith(fontSize: 20, color: colorScheme.primary, fontWeight: FontWeight.w800)`.
           (displaySmall is the correct role per spec; size override needed since displaySmall is ~36sp by default.)
         - Step body text: `theme.textTheme.bodyMedium`.
      d) Add a total-cost summary row pinned at the bottom. Implement using a `BottomAppBar`
         (or a `Positioned` inside the `Scaffold`) that shows:
         `Icon(Icons.shopping_cart_outlined)` + `Text('Estimated total: ₱$totalCost')` in
         `theme.textTheme.titleMedium` + a small `Text('SAMPLE PRICES', style: labelSmall)`.
         This appears only when `adaptState.result != null && totalCost > 0`. Since the screen
         currently uses `Scaffold` without a `bottomNavigationBar`, add
         `bottomNavigationBar: _CostFooter(cost: totalCost)` conditionally.
      e) Replace `_AdaptationBanner` hardcoded colors with semantic equivalents:
         - Running: `colorScheme.surfaceContainerHigh` background, replace `CircularProgressIndicator`
           with `LinearProgressIndicator` (full width, `colorScheme.primary` value color).
         - FellBack / warning: `colorScheme.errorContainer` bg, `colorScheme.onErrorContainer` text.
         - Success: `colorScheme.primaryContainer` bg, `colorScheme.primary` icon/text.
      f) Replace recipe heading `headlineMedium` + hardcoded `Color(0xFF0E3D2A)` with
         `theme.textTheme.titleLarge` + `colorScheme.onSurface`.
      g) Replace `_SectionHeading` hardcoded `fontSize: 13` with `theme.textTheme.titleSmall`.
      h) Replace `_IngredientRow` hardcoded `fontSize: 14` / `fontSize: 12` with
         `theme.textTheme.bodyMedium` / `theme.textTheme.labelSmall`.
      i) Add `HapticFeedback.lightImpact()` on the back button `onPressed`.
      
      Files: `lib/features/detail/detail_screen.dart`
      Verify: `flutter analyze` — 0 new errors; cost footer visible when adapted recipe has
      toBuy items.

- [ ] 8. Rewrite `lib/shared/tag_chip.dart` — Material 3 chip.
      Replace the custom `Container`-based `TagChip` with a proper Material 3 chip approach.
      Keep `TagChip` as a display-only (non-interactive) chip since it's used in read-only
      contexts (recipe cards, detail screen tags). Use `RawChip` with `isEnabled: false` and
      `onPressed: null` — this gives Material 3 chip shape/padding without interactive state.
      Set `shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))` (8dp per spec).
      Keep `color`, `textColor` params for backward compat — map them to `backgroundColor` and
      `labelStyle` on `RawChip`. Remove the manual `_contrastText` helper; use `textColor`
      directly (callers already provide it). Add a default `textColor` fallback using
      `Theme.of(context).colorScheme.onSurface` when null.
      
      Decision: Keep `TagChip` as a lightweight display chip rather than converting to `Chip`
      (which forces an avatar slot) or `ActionChip` (which always shows as tappable). `RawChip`
      with `onPressed: null` is the correct M3 primitive for read-only labeled chips.
      
      Files: `lib/shared/tag_chip.dart`
      Verify: `flutter analyze` — 0 new errors; TagChip renders correctly in ResultsScreen and
      DetailScreen.

- [ ] 9. Rewrite `lib/shared/empty_state.dart` — illustration placeholder and CTA.
      a) Add an optional `onAction` callback and `actionLabel` string to `EmptyState`.
      b) Replace the bare `Icon` with an illustration placeholder: a `Container`
         (width 120, height 120, `colorScheme.primaryContainer`, `BorderRadius.circular(24)`)
         with the icon centered inside (`size: 56, color: colorScheme.primary`).
      c) Update title `Text` to use `theme.textTheme.titleLarge` (not `titleMedium`).
      d) Update body `Text` to use `theme.textTheme.bodyMedium` with `colorScheme.onSurfaceVariant`
         instead of `Colors.grey[600]`.
      e) If `onAction != null`, render a `FilledButton.tonal(onPressed: onAction, child: Text(actionLabel!))` below the body text with 16dp top gap.
      f) Update call sites: `results_screen.dart` passes `EmptyState(icon: Icons.no_food_outlined, ...)` — no `onAction` is needed there so no call-site change required.
      
      Files: `lib/shared/empty_state.dart`, `lib/features/results/results_screen.dart` (verify
      existing usage still compiles).
      Verify: `flutter analyze` — 0 new errors.

- [ ] 10. Rewrite `lib/shared/on_device_badge.dart` — semantic colors.
       Replace all hardcoded colors:
       - `Color(0xFFEDECE5)` container bg → `colorScheme.surfaceContainerHigh`
       - `Color(0xFFB07B3A)` mock color → `colorScheme.primary` (accent orange; mock is now
         expressed as the same accent, differentiated by label text only)
       - `Color(0xFF596357)` neutral → `colorScheme.onSurfaceVariant`
       - `Color(0xFF267450)` ready green → keep as `Color(0xFF388E3C)` (green is intentional
         semantic signal; not tied to brand accent)
       - `Color(0xFFFFE1C8)` mock tag bg → `colorScheme.primaryContainer`
       Replace all hardcoded `fontSize` values in `OnDeviceMini` (`fontSize: 9`, `fontSize: 10`)
       with `theme.textTheme.labelSmall` style (access via `Theme.of(context)` — this requires
       making `OnDeviceMini.build` context-aware, which it already is).
       Replace `_MockTag` hardcoded padding/fontSize with `labelSmall` style and
       `colorScheme.primaryContainer` bg.
       
       Files: `lib/shared/on_device_badge.dart`
       Verify: `flutter analyze` — 0 new errors.

- [ ] 11. Rewrite `lib/shared/sample_notice.dart` — semantic colors.
       Replace `Color(0xFFFFF3CD)` with `colorScheme.tertiaryContainer` and
       `Color(0xFFFFD700)` border with `colorScheme.tertiary`. Replace
       `Color(0xFF856404)` text with `colorScheme.onTertiaryContainer`.
       Replace hardcoded `fontSize: 11` with `theme.textTheme.labelSmall` style.
       Border radius stays 10dp (close enough to 8dp base unit — no change needed).
       
       Files: `lib/shared/sample_notice.dart`
       Verify: `flutter analyze` — 0 new errors.

- [ ] 12. Rewrite `lib/shared/page_scaffold.dart` — remove hardcoded padding.
       Replace `padding: EdgeInsets.all(16)` with `EdgeInsets.symmetric(horizontal: 16, vertical: 16)`
       (no change in practice, but ensures 8dp base-unit compliance is explicit).
       No other changes needed — this widget delegates everything to AppBar and children.
       
       Files: `lib/shared/page_scaffold.dart`
       Verify: `flutter analyze` — 0 new errors.

- [ ] 13. Final integration pass — fix any remaining hardcoded colors/sizes across all touched files.
       Search for remaining `Color(0xFF1C684E)`, `Color(0xFF0E3D2A)`, `Color(0xFF596357)`,
       `Color(0xFF2D5040)`, `Colors.grey[600]`, `Colors.grey[700]`, `fontSize:` outside of
       overrides that have already been replaced. Replace each with the nearest semantic token
       from the new `ColorScheme`. Do NOT change any business logic, provider reads/writes,
       routing calls, or data-layer code.
       
       Files: all files touched in steps 1–12
       Verify: `flutter analyze` reports 0 errors and 0 new warnings (the pre-existing
       `widget_test.dart` error is acceptable). `flutter build apk --debug` completes without
       compilation errors.

---

## Spacing reference (8dp base unit)
| Token | dp |
|---|---|
| xs | 4 |
| sm | 8 |
| md | 12 |
| base | 16 |
| lg | 24 |
| xl | 32 |

Use only multiples of 4dp. Avoid 5, 6, 7, 9, 10, 11, 13, 14, 15 dp gaps.

## Shape scale reference
| Role | radius |
|---|---|
| card | 16dp |
| input / container | 12dp |
| chip | 8dp |
| action button (pill) | 28dp |

## Semantic color mapping cheat-sheet (for the implementer)
| Old hardcode | Replace with |
|---|---|
| `Color(0xFF1C684E)` (brand green) | `colorScheme.primary` |
| `Color(0xFF0E3D2A)` (dark green) | `colorScheme.onSurface` |
| `Color(0xFFE5EEE5)` (light green bg) | `colorScheme.primaryContainer` |
| `Color(0xFFD4EBD8)` (chip selected bg) | `colorScheme.primaryContainer` |
| `Color(0xFF596357)` (muted green) | `colorScheme.onSurfaceVariant` |
| `Color(0xFFF7F5EF)` (warm white bg) | `colorScheme.surface` |
| `Color(0xFFF0EEE6)` (neutral chip) | `colorScheme.surfaceContainerHigh` |
| `Color(0xFFEDECE5)` (badge bg) | `colorScheme.surfaceContainerHigh` |
| `Color(0xFFE8E6DE)` (border) | `colorScheme.outlineVariant` |
| `Color(0xFFFFF3CD)` (amber bg) | `colorScheme.tertiaryContainer` |
| `Color(0xFFFFD700)` (amber border) | `colorScheme.tertiary` |
| `Color(0xFF856404)` (amber text) | `colorScheme.onTertiaryContainer` |
| `Color(0xFFFFE1C8)` (orange tint) | `colorScheme.primaryContainer` |
| `Color(0xFF7A4A1E)` (orange text) | `colorScheme.onPrimaryContainer` |
| `Color(0xFFB07B3A)` (warm brown) | `colorScheme.primary` |
| `Colors.grey[600]` | `colorScheme.onSurfaceVariant` |
| `Colors.grey[700]` | `colorScheme.onSurfaceVariant` |
| `Colors.white` (fill) | `colorScheme.surface` |
