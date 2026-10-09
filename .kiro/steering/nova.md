# Nova — SnapFood Food Wizard

Steering file for all Kiro sessions. Nova is SnapFood's mascot. Every screen
that uses Nova must stay consistent with this document.

---

## Character brief

**Object:** A cream egg-shaped chef holding a green camera on a strap.
**Personality:** Curious, enthusiastic, a little clumsy. Gets sleepy when ignored.
**Emotional job:** The friend who is excited about whatever you are about to eat.
**Voice:** Short, warm, plain sentences. No food puns in error messages.

Nova should react to what the user does, not sit in a corner as decoration.

---

## Visual design

The SVG mascot is the source of truth — see `Nova state machine.html` at the
workspace root for the finished character.

| Part | Color |
|------|-------|
| Body | cream `#F6E7C1`, stroke `#B98A55` |
| Face circle | yellow `#FFC93C` |
| Cheeks | `#FF8E72` opacity 0.75 |
| Arms / feet | cream `#F6E7C1`, stroke `#B98A55` |
| Chef hat | cream `#FFF4D6` with brim `#B98A55` |
| Leaf | green `#5E8F57`, stroke `#2F5D31` |
| Camera body | green `#5E8F57` / `#4F8A4A`, stroke `#2F5D31` |
| Camera lens | yellow `#E8B83A` outer, dark inner |
| Eyes / pupils | dark brown `#4A2C1A` |
| Mouth | dark red `#C9422A` |

Do not change these colors for dark mode. Nova's body colors stay fixed — only
background surfaces behind Nova change.

---

## Design tokens (Nova palette)

These are the app's semantic tokens derived from Nova's palette.

```
novaColor.cream        = #F6E7C1   (light surfaces, cards)
novaColor.yellow       = #FFC93C   (highlights, active states)
novaColor.orange       = #FF9F2E   (secondary accent)
novaColor.green        = #5E8F57   (primary actions)
novaColor.darkGreen    = #2F5D31   (pressed / deep green)
novaColor.brown        = #4A2C1A   (primary text)
```

Dark mode: darken surface tokens; keep nova body colors unchanged.

Typography: Nunito (already in pubspec via google_fonts).
Radii: 16–24px on cards, 99px on primary buttons.
Shadows: soft warm shadows using `novaColor.brown` at low opacity.

---

## States

Five states. Drive from app events (see `lib/shared/nova/nova_event_map.dart`),
not from screens calling animation methods directly.

| State | Trigger | Body animation | Eyes | Mouth | FX |
|-------|---------|----------------|------|-------|-----|
| **idle** | Camera waiting, home, empty lists | slow breathe (scale 1↔1.015) | blink every 4.2s, look-around pupils | gentle smile | — |
| **thinking** | Photo taken, any load > 500ms | sway −7°↔−2° | pupils shift up-left, no blink | small tongue | scanning dashes on lens, ? + dots above |
| **happy** | Dish recognized, recipe loaded, selection confirmed | hop translateY −14px | crescent/arc eyes | open smile + tongue | sparkle stars |
| **error** | Recognition failed, no network, permission denied | shake (rapid X oscillation then slump) | arrow / zigzag eyes | wobble frown | sweat drop, drooping leaf |
| **celebrating** | Recipe saved, onboarding done, streak | big jump translateY −52px × 3 | star eyes | large open mouth | hat bounce, arms wave, confetti |

**State-change pop:** On every state change, the root `#sq` group plays a
squash-and-stretch `pop` keyframe (scale .9,1.1 → 1.08,.92 → 1). This is
mandatory — it is the single most important animation in the whole system.

**Reduced motion:** When `MediaQuery.of(context).disableAnimations` is true,
skip all looping animations. Render the correct static pose for each state.

---

## Event-to-state mapping

Canonical mapping lives in `lib/shared/nova/nova_event_map.dart`.

```
AppEvent.appLaunch          → idle
AppEvent.scanStarted        → idle
AppEvent.photoTaken         → thinking
AppEvent.recognitionSuccess → happy
AppEvent.recipeLoaded       → happy
AppEvent.recognitionFailed  → error
AppEvent.noNetwork          → error
AppEvent.permissionDenied   → error
AppEvent.recipeSaved        → celebrating
AppEvent.onboardingDone     → celebrating
AppEvent.selectionConfirmed → happy
AppEvent.loading            → thinking
AppEvent.inactiveCamera60s  → (sleepy — stretch goal)
```

---

## Widget API

```dart
NovaWidget(
  state: NovaState.idle,   // required
  size: 160,               // optional, default 120
  caption: 'Point me at your plate.',  // optional
)
```

- Caption renders below Nova in `bodyMedium` Nunito, centered.
- If caption is supplied, mark the SVG as `excludeSemantics: true` and put
  the semantic label on the caption's `Text` widget instead.
- If no caption, the SVG gets `Semantics(label: 'Nova, excited chef mascot')`.

---

## Placement rules

| Screen | Nova size | State driven by |
|--------|-----------|----------------|
| Splash / onboarding welcome | 200 | idle → happy (auto after 1s) |
| Home hero (replaces icon container) | 160 | ownedIngredients.isEmpty → idle, else happy |
| Scan — inside viewfinder, idle only | 80 | idle (nothing detected yet) |
| Results — empty state | 100 | error |
| Review — zero ingredients | 80 | idle |
| Detail — adaptation banner inline | 32 | thinking / happy / error |
| Loading screens | 100 | thinking |
| Error screens | 100 | error |

Max 6 simultaneous Nova instances on screen. Prefer one.

---

## Copy voice

Short. Warm. First person as Nova. No food puns in error messages.

| Moment | Copy |
|--------|------|
| Camera waiting | "Point me at your plate." |
| Photo taken | "Hmm, let me look closer…" |
| Recipe ready | "Got it. Here's your recipe." |
| No match | "I can't work with that yet. More ingredients?" |
| Error | "Oops. I couldn't tell what that is. Try another angle?" |
| Recipe saved | "Recipe saved. Chef Nova approves." |
| Onboarding done | "Let's cook." |

---

## What Nova is NOT

- Not a loader spinner replacement for fast operations (< 500ms).
- Not decoration when a caption already explains the state.
- Not animated during scroll.
- Not displayed on more than one region of the same screen simultaneously.
- Not speaking in food puns during errors ("That dish is half-baked!" — banned).
