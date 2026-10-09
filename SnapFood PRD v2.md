# SnapFood: Product Requirements Document

Version 2.0 | AppBuildersPH Hackathon 2026, Local AI | Flutter phone app

## 1. Summary

SnapFood helps students cook with what they already have, using only what their phone can do. The user sweeps the camera across their ingredients and a vision model on the phone recognizes them live. They pick their cooking equipment and an extra-spend limit. A small language model on the phone then adapts a Filipino recipe to those exact ingredients, equipment, and budget.

Pitch: Sweep your camera. Get a Filipino recipe that fits your rice cooker and your wallet. No signal needed.

What separates SnapFood from a plain photo-to-recipe demo is two things. The scan runs live on the device, which would be slow and costly against a cloud API. And the recipes are adapted to real dorm limits, equipment and budget, which most recipe apps ignore.

## 2. Problem and user

Primary user: a college student in a dorm or shared housing with a small food budget and limited equipment. Many dorms allow a rice cooker, an electric kettle, or a microwave, and nothing else.

Problem: the student has a few ingredients and no idea what to make. A recipe search returns dishes that need a stove, ingredients they do not own, or both. They spend more than planned or skip cooking.

Example: a student has eggs, rice, a tomato, an onion, and a rice cooker. They open SnapFood, sweep the camera over the shelf, fix one wrong label, choose rice cooker and up to 30 pesos extra, and get a rice cooker version of a Filipino dish with the one missing item clearly marked.

To validate before building too far: talk to a few dorm students and confirm which equipment they actually have and what extra budget is realistic. Treat the equipment list and the budget presets below as assumptions until then.

## 3. Why this needs to run locally

| Claim | What the demo shows |
| --- | --- |
| Live scan with no cost per frame | The camera overlay updates continuously in airplane mode. A cloud version would pay and wait for every frame. |
| Video of the user's room stays on the phone | Network off, scan still works. No upload of any frame. |
| Works with no signal | The full flow completes offline. |
| The language model does work rules cannot | The same base recipe comes out differently for different ingredients and equipment. |

What is not AI, stated plainly: recipe retrieval, equipment filtering, budget math, and price lookup are ordinary application logic. Say so in the demo and do not claim otherwise.

Honest limit: a cloud model would likely write more fluent recipes. The argument for local is real-time scanning, privacy, zero marginal cost, and offline use, not recipe quality.

## 4. Goals and non-goals

Goals

1. Recognize a defined set of ingredients live from the camera, on the device.
2. Let the user correct the detected list quickly.
3. Adapt a base Filipino recipe to the confirmed ingredients, equipment, and extra budget using a local language model.
4. Run the whole flow with the network disabled after setup.
5. Make local execution visible and provable during the demo.

Non-goals

User accounts or cloud sync, social features, grocery delivery or purchasing, nutrition or medical advice, freshness or food safety detection, meal planning, cuisines beyond Filipino, and training a model from scratch. Fine-tuning a small pretrained model on a small ingredient set is allowed.

## 5. User flow and functional requirements

### Step 1: Live scan

- FR-01: Show a camera preview with a live detection overlay. Also allow picking a saved photo as a fallback input.
- FR-02: Run detection on the device at a rate the phone can sustain. Target 1 to 2 frames per second, lower if needed.
- FR-03: Accumulate detections into a list as the user pans. Only add an ingredient when it is above a confidence threshold in several frames, to avoid flicker.
- FR-04: Show a loading state, and a clear message if the camera or model fails or camera permission is denied.

### Step 2: Review and preferences (one screen)

- FR-05: Show detected ingredients as removable chips, labeled as detected, not confirmed.
- FR-06: Let the user add ingredients manually from the supported vocabulary, searchable by Filipino or English name.
- FR-07: Let the user rescan.
- FR-08: If nothing is detected, go to manual entry. Never invent detections.
- FR-09: Equipment, multi-select: rice cooker, electric kettle, microwave, stove. First run defaults to rice cooker, later runs remember the last choice.
- FR-10: Extra budget presets: 0, 30, 50, 100 pesos. Default 30.
- FR-11: Equipment and budget are optional and need no more than one tap to accept the defaults.

### Step 3: Generate

- FR-12: Retrieval. Pick up to three base recipes from the bundled dataset that match the confirmed ingredients, the chosen equipment, and the budget, ranked by the share of ingredients the user already has.
- FR-13: Adaptation. For the selected recipe, the local language model substitutes missing items using the confirmed list where sensible, scales quantities, and rewrites the method for the chosen equipment.
- FR-14: Validate the output against the confirmed list (section 8). Any ingredient the user does not own must appear under Additional items with an estimated cost from the bundled price table, labeled as an estimate.
- FR-15: Stream the generated text to the screen as it is produced.
- FR-16: If generation fails, times out, or fails validation after one retry, show the unmodified base recipe with a clear label that the model did not adapt it.

### Step 4: View the recipe

- FR-17: Show ingredients with quantities, steps, estimated time, additional items with estimated cost, and any substitutions.
- FR-18: Visually separate owned ingredients, substitutions, and items to buy.
- FR-19: Let the user go back to the results without rescanning.
- FR-20: Show an On-device status on every screen, including whether the models are loaded.

## 6. Local AI components

| Component | Job | Type | Candidates to test |
| --- | --- | --- | --- |
| A. Ingredient recognition | Live detection of ingredients from the camera | On-device model | A small detector or classifier in TFLite format, fine-tuned on the target vocabulary if no pretrained model covers it |
| B. Recipe retrieval | Choose base recipes | Ordinary logic | Local JSON or SQLite |
| C. Recipe adaptation | Rewrite a recipe for the user's ingredients, equipment, and budget | On-device language model | A 1B to 3B instruct model, 4-bit quantized, run through a llama.cpp based Flutter binding |
| D. Fallback | Show the unmodified base recipe | Ordinary logic | Same dataset |

Vision notes

- The default ML Kit object detector returns coarse categories. Assume it cannot tell an egg from an onion until tested.
- Benchmark candidate models on photos of the real ingredient list. If no pretrained model covers the vocabulary, fine-tune a small pretrained model on photos the team takes, a few dozen per ingredient, in varied lighting.
- Check each model's license before using it in the app. Some popular detector families, for example Ultralytics YOLO weights, are AGPL-3.0.
- Build the vocabulary from the recipe dataset: 15 to 20 ingredients that appear in the recipes and look different from each other. A detected ingredient that no recipe uses is of no value.

Language model notes

- Choose the model only after testing on the actual phone. Candidate families include Qwen2.5 and Llama 3.2 instruct models at 1B to 3B. Check each license for app distribution.
- Verify that the Flutter binding supports the target operating system before committing. Android support is generally further along, but confirm.
- Prefer grammar-constrained decoding to force valid structured output if the binding supports it. Otherwise validate and retry.
- Keep outputs short, around 250 tokens, to control generation time.

Models ship inside the app or are side-loaded before the demo. Nothing is downloaded during the demo. The app distinguishes first-time setup from offline-ready operation.

## 7. Data

Recipe dataset: 12 to 20 Filipino recipes written and checked by the team. Fields: id, Filipino and English name, tags, core ingredients, optional ingredients, compatible equipment, steps, estimated time, servings. Include several recipes that already suit a rice cooker or microwave, so adaptation starts from solid ground.

Price table: an estimated price in pesos per typical portion for each ingredient, collected by the team from a local store or market. Label every figure as an estimate and record the date collected.

Ingredient vocabulary: each ingredient with its Filipino name, English name, and aliases, used for detection labels, manual entry, and matching.

## 8. Adaptation contract and validation

Input to the model: the base recipe, the confirmed ingredients, the chosen equipment, and the budget.

Output from the model, as structured fields: recipe name, ingredient list where each item is marked owned, substituted, or to buy with a quantity, steps, estimated time, and notes.

Prompt rules: use only owned ingredients unless an item is marked to buy. Use only the chosen equipment. Keep steps short and plain.

Validation after generation, done in ordinary code:

1. The output parses.
2. Every ingredient marked owned is in the confirmed list.
3. Every to-buy item exists in the price table, or is flagged as unpriced.
4. The estimated extra cost is within the budget, or is flagged as over budget.
5. No equipment outside the chosen set is mentioned.

If any check fails, retry once with the errors appended to the prompt. If it fails again, use the fallback in FR-16.

## 9. Screens

1. Home: name, one-line value, Scan button, choose-photo button, On-device status.
2. Live Scan: camera preview, detection overlay, running ingredient list, Done button.
3. Review and Preferences: ingredient chips, add and remove controls, equipment and budget selectors, Generate button.
4. Results: up to three recipe cards with title, time, how many ingredients are owned, and estimated extra cost.
5. Recipe Detail: ingredients, steps, substitutions, items to buy, back to results.

Keep the design clean and readable on a projector or screen mirror. No settings screen.

## 10. Quality and safety

- Make no claims about freshness, spoilage, contamination, or allergens from images.
- Present detections as suggestions that the user confirms.
- Each base recipe lists only the equipment combinations the team has checked for safety, for example no metal in a microwave. The model adapts only within those tags.
- Cost figures are always labeled as estimates.
- The app must not crash when nothing is detected, a model fails to load, or camera permission is denied.
- The core flow makes no network calls and needs no account. Check that no analytics or crash-reporting library sends data during the demo.

## 11. MVP acceptance criteria

1. A user can sweep the camera and see ingredients detected live, on the device.
2. The user can correct the ingredient list.
3. The user can choose equipment and an extra budget in one screen.
4. The app returns up to three relevant base recipes from the confirmed ingredients.
5. The local language model adapts a recipe, and the output passes validation or falls back with a clear label.
6. The full flow works with Wi-Fi and mobile data off.
7. Empty detection, model failure, and permission denial each show a useful message.
8. The demo repeats on the target phone with no external server.

## 12. Priorities

P0: live detection on the phone, editable ingredient list, retrieval from the recipe dataset, local language model adaptation with validation and fallback, offline end-to-end run.

P1: budget and equipment filtering polish, streaming text, polished results and detail screens, estimated cost display.

P2, only after P0 is tested: favorites, more recipes, more detailed substitutions, saved pantry.

## 13. Build order and go/no-go gates

Order: 1) vision on the phone, 2) language model on the phone, 3) dataset, retrieval, and validation logic (can run in parallel with 1 and 2 by a different person), 4) screens, 5) offline testing and demo rehearsal.

The thresholds below are suggested starting points. Adjust them after benchmarking on the real phone.

| Gate | Pass condition | If it fails |
| --- | --- | --- |
| Vision | At least 80% correct on 20 or more varied test photos for a 15-ingredient vocabulary, and live overlay at about 1 frame per second or better | Shrink the vocabulary to what works, lean on manual entry, or fall back to photo mode |
| Language model | First text in under 5 seconds, full recipe in under 40 seconds, no crash or out-of-memory across 10 runs in a row | Use a smaller or more compressed model, shorten the output, or limit the model to rewriting steps only |
| Offline | The full flow passes 5 times in a row with Wi-Fi and mobile data off | Find and remove the hidden network dependency before anything else |

If neither model runs acceptably on the phone, decide early to move the demo to a laptop with a webcam. Do not leave this decision to the end.

## 14. Demo plan

1. Show the app and the On-device status.
2. Turn on airplane mode and show it on screen.
3. Sweep the camera over a prepared set of ingredients and show the live detections.
4. Remove one wrong chip and add one missing ingredient.
5. Choose rice cooker and 30 pesos extra.
6. Generate. Let the audience watch the recipe stream in.
7. Open the recipe and point out owned items, substitutions, and items to buy.
8. Say which parts ran as AI on the phone and which were ordinary logic.

Keep a screen recording of a successful run as a backup, and label it as a recording if it is ever shown.

## 15. Risks

| Risk | Mitigation |
| --- | --- |
| Vision model cannot recognize Filipino ingredients reliably | Test first, narrow the vocabulary, fine-tune on team photos, keep manual entry |
| Language model too slow or too large for the phone | Test early on the real phone, smaller quantized model, shorter outputs, streaming text |
| Flutter plus native model bindings consume the build time | Get each model running in a bare test app before building any screens |
| Model invents ingredients or unsafe steps | Retrieval from a checked dataset, equipment tags, validation, fallback |
| Looks like a generic recipe app | Open the demo with the live scan and the equipment and budget choice |
| Hidden network use breaks the offline claim | Test with network off, audit libraries for analytics and crash reporting |

## 16. Open questions

- Which phone, how much RAM, and Android or iOS?
- How many people on the team, and who owns vision, language model, and data and UI?
- What is the deadline, and is the demo live, recorded, or both?
- Which equipment do dorm students actually have, and what extra budget is realistic?

## 17. Engineering specification for the coding agent

Sections 1 to 16 define the product. This section defines how to build it, and where the two disagree, this section wins. Work through the tasks in 17.13 in order. When something cannot be verified, write the assumption into docs/DECISIONS.md instead of guessing.

### 17.1 Ground rules

- Target: Flutter (stable channel), Dart 3, null safety. Android is the primary target and the demo device until the team says otherwise. iOS should still compile where that costs nothing extra.
- No cloud inference and no network packages. Do not add http, dio, firebase\_\* or any analytics or crash-reporting package. A unit test must fail if one appears in pubspec.yaml.
- Never invent model files, labels, recipes, prices, or benchmark numbers. If a model file is missing, show the Setup Required state. Sample data is allowed only when every file and screen that uses it is visibly labeled SAMPLE.
- Mock implementations (mock detector, mock LLM) may exist for development. They are selectable only in debug builds, and while one is active a MOCK badge shows on every screen.
- Before adding a package, confirm on pub.dev that it exists, supports Android, and is maintained. Record the package and version in docs/DECISIONS.md.
- Every task ends with flutter analyze clean and flutter test passing.

### 17.2 Stack

| Concern | Choice | Notes |
| --- | --- | --- |
| Framework | Flutter stable, Dart 3 |  |
| State | flutter\_riverpod | Providers listed in 17.9 |
| Navigation | go\_router | Routes listed in 17.9 |
| Camera | camera | Use the image stream for live scan |
| Photo picker | image\_picker | Fallback input |
| Vision inference | tflite\_flutter | Verify Android support and isolate use before committing |
| LLM inference | A llama.cpp based Flutter binding | Candidates to evaluate: llama\_cpp\_dart, fllama, flutter\_gemma. Confirm each exists and supports the target Android ABI, pick one, record it, and hide it behind LlmEngine |
| Preferences | shared\_preferences | Equipment and budget |
| File paths | path\_provider | Model directory |
| JSON | dart:convert, plain classes with fromJson | No code generation |
| Tests | flutter\_test, mocktail |  |

### 17.3 Repository layout

```
snapfood/
  lib/
    main.dart
    app/            router, theme, app shell
    core/           config loader, logger
    domain/         models, retrieval, accumulator, parser, validators, adaptation service
    data/           asset loaders, preferences store
    ml/             detector and LLM interfaces, implementations, model store, bench
    features/       home, scan, review, results, detail (screen + controller each)
  assets/
    data/           ingredients.json, recipes.json, prices.json
    models/         model_config.json, labels.txt, ingredient_classifier.tflite
    config/         app_config.json
  ml/               python training scripts (not shipped in the app)
  tool/             validate_data.dart, push_models.sh, check_offline.md
  test/
  docs/DECISIONS.md
```

### 17.4 Domain models

Immutable classes with const constructors. Data classes get fromJson.

```dart
enum Equipment { riceCooker, kettle, microwave, stove }
enum IngredientSource { owned, substituted, toBuy }
enum ResultKind { adapted, fallbackBase }

class Ingredient { String id; String nameFil; String nameEn; List<String> aliases; }
class RecipeIngredient { String ingredientId; double qty; String unit; bool core; }
class Recipe {
  String id; String nameFil; String nameEn;
  List<RecipeIngredient> ingredients;
  Set<Equipment> equipment;   // combinations the team has checked for safety
  List<String> steps; int minutes; int servings;
}
class Preferences { Set<Equipment> equipment; int extraBudgetPesos; }
class AdaptRequest { Recipe base; Set<String> ownedIds; Preferences prefs; }
class AdaptedIngredient {
  String ingredientId; String qtyText;
  IngredientSource source; String? replacesId;
}
class AdaptedRecipe {
  String name; int minutes;
  List<AdaptedIngredient> ingredients; List<String> steps; String notes;
}
class RecipeResult {
  ResultKind kind; Recipe base; AdaptedRecipe? adapted;
  int estimatedExtraPesos; List<String> flags;  // overBudget, lowMatch, unpricedItem
}
```

### 17.5 Data files

The team supplies the real content. Codex builds the loaders and the validator. The files below show the format only.

assets/data/ingredients.json is a list of objects with id, nameFil, nameEn, and aliases. The id is a lowercase ASCII slug and is the single key used everywhere, including labels.txt.

assets/data/recipes.json, format example:

```json
[
  {
    "id": "r001",
    "nameFil": "Ginisang Kamatis at Itlog",
    "nameEn": "Sauteed Tomato and Egg",
    "equipment": ["stove", "microwave"],
    "minutes": 10,
    "servings": 1,
    "ingredients": [
      {"ingredientId": "itlog", "qty": 2, "unit": "pc", "core": true},
      {"ingredientId": "kamatis", "qty": 1, "unit": "pc", "core": true},
      {"ingredientId": "sibuyas", "qty": 0.5, "unit": "pc", "core": false}
    ],
    "steps": ["Step one text.", "Step two text."]
  }
]
```

assets/data/prices.json, format example with placeholder values:

```json
{
  "collectedOn": "YYYY-MM-DD",
  "entries": [ {"ingredientId": "itlog", "pesos": 10, "portion": "1 pc"} ]
}
```

tool/validate\_data.dart, also run as a unit test, fails when: a recipe references an ingredient id missing from ingredients.json, a recipe has no core ingredient, a recipe has an empty equipment list or empty steps, a core ingredient has no price entry, or any id in labels.txt is missing from ingredients.json.

### 17.6 Vision pipeline

MVP mode is classification per frame with accumulation over time. The user sweeps the camera and each frame yields its top predictions. Bounding-box detection is P2.

Interface:

```dart
class Prediction { String ingredientId; double confidence; }
abstract class IngredientDetector {
  bool get isMock;
  Future<void> load();
  Future<List<Prediction>> predict(Frame frame);  // top-K, sorted
  Future<void> dispose();
}
```

Implementations: TfliteClassifierDetector (real) and MockDetector (debug only). The real one reads assets/models/model\_config.json and hardcodes no sizes:

```json
{
  "modelFile": "ingredient_classifier.tflite",
  "labelsFile": "labels.txt",
  "inputWidth": 224,
  "inputHeight": 224,
  "inputType": "float32",
  "normalization": "zeroToOne",
  "outputKind": "classification"
}
```

Supported normalization values: zeroToOne, minusOneToOne, none (for uint8 input). labels.txt has one ingredient id per line, in the model's output order, plus an optional line named \_none for the background class. Fail at startup with a clear message if the label count does not match the model output size.

Frame handling:

- Use the camera image stream. Keep only the latest frame and run inference only when none is in flight, so frames are dropped while busy.
- Process at most one frame per scan.intervalMs.
- Convert the camera format (YUV420 on Android) to RGB, resize, and run inference off the UI thread so the preview stays smooth. Use an isolate.
- Ignore predictions for \_none and for ids not in the vocabulary.

Accumulator (pure Dart, unit-tested): keep the last scan.windowSize frames. An ingredient becomes detected when it appears in at least scan.minHits of those frames with average confidence at least scan.minConfidence. Once detected it stays until the user removes it or rescans.

Photo fallback: image\_picker, decode, resize, one predict call, return up to topK predictions above scan.photoMinConfidence as chips.

Training helper (ml/train\_classifier.py, not shipped): transfer learning on a small pretrained image classifier such as MobileNetV3Small or MobileNetV2 from ml/dataset/\<ingredient\_id>/\*.jpg, with a \_none folder for empty shelves, hands, and backgrounds. 224 by 224 input, random flip, rotation, and brightness augmentation, an 80/20 split, and export to TFLite with float16 quantization. Write model.tflite, labels.txt, and report.md with per-class accuracy and a confusion summary. Add ml/requirements.txt and ml/README.md with photo guidance: 40 to 60 photos per ingredient, varied lighting, angles, and backgrounds, including dorm-like surroundings. Do not commit the dataset.

### 17.7 Retrieval (deterministic, not AI)

`List<RecipeResult> retrieve(recipes, prices, ownedIds, prefs, {limit})`

1. Keep recipes whose equipment set intersects prefs.equipment.
2. For each, compute ownedCoreRatio = core ingredients owned / core ingredients total, the list of missing core ingredients, and missingCost from the price table. An unpriced missing item adds the unpricedItem flag.
3. A recipe is eligible when ownedCoreRatio >= retrieval.minOwnedCoreRatio and missingCost <= prefs.extraBudgetPesos.
4. Sort eligible recipes by ownedCoreRatio descending, then missingCost ascending, then minutes ascending.
5. If fewer than limit are eligible, fill from the remaining equipment-matching recipes using the same sort, flagging each overBudget or lowMatch.
6. Return at most limit results. Never throw on empty input. If no recipe matches the equipment, return an empty list and let the UI explain why.

Required tests: exact match ranks first, equipment filter excludes a recipe, over-budget recipes are flagged and ranked after eligible ones, ties resolve in the stated order, empty owned set returns flagged results or an empty list without error, same input always gives the same output.

### 17.8 Local LLM adaptation

Separate the engine from the logic. LlmEngine only turns a prompt into a stream of text. AdaptationService owns prompts, parsing, validation, retry, and fallback.

```dart
abstract class LlmEngine {
  bool get isMock;
  Future<void> load(String modelPath);
  Stream<String> generate(String prompt,
      {required int maxTokens, required double temperature, required double topP});
  Future<void> cancel();
  Future<void> dispose();
}
```

The real implementation wraps the binding chosen in docs/DECISIONS.md. MockLlmEngine replays a canned response with delays and is debug only.

Output format. Small models produce broken JSON often, so use a tagged line format that is readable while it streams. Ingredient ids come from the vocabulary so validation can be exact:

```
NAME: <recipe name>
TIME: <minutes as an integer>
INGREDIENTS:
- owned | <quantity and unit> | <ingredient id>
- sub | <quantity and unit> | <ingredient id> | replaces <ingredient id>
- buy | <quantity and unit> | <ingredient id>
STEPS:
1. <short step>
NOTES: <one line>
END
```

Prompt. buildPrompt(AdaptRequest) is a pure function with a snapshot test.

System message: You adapt Filipino home recipes for students with limited equipment. Follow the output format exactly. Use only the ingredient ids you are given. Output nothing before NAME and nothing after END.

User message sections, in order: the base recipe name and time; the base ingredients, one per line as id, quantity and unit, and core or optional; the numbered base steps; the line USER HAS with the owned ids; the line EQUIPMENT with the chosen equipment; then these rules and the format block above:

- Mark each ingredient owned, sub, or buy.
- owned means the id is in USER HAS.
- sub means replace a base ingredient with an id from USER HAS, and name the id it replaces.
- buy means the user does not have it. Keep buy items to the minimum.
- Use only the listed equipment in the steps. Write 3 to 6 short steps.
- Do not add ingredients that are not in the base recipe unless they replace one.

Generation settings come from app\_config.json: temperature 0.3, top\_p 0.9, max tokens 400, context 2048. If the binding supports grammar-constrained decoding, use it to force the format. If not, rely on the parser.

Parser: strip markdown fences, match markers case-insensitively, accept a colon or a dash after a marker, and ignore blank lines. Return a parse error list instead of throwing.

Validation. Run all checks and collect every error:

| ID | Rule |
| --- | --- |
| V1 | NAME present, at least one ingredient, at least one step, END reached |
| V2 | Every ingredient id exists in the vocabulary |
| V3 | Every owned id is in ownedIds |
| V4 | Every buy id is absent from ownedIds and has a price entry. Unpriced becomes a flag, not an error |
| V5 | Every sub names a replaced id that exists in the base recipe, and the substitute id is in ownedIds |
| V6 | Steps do not mention equipment outside prefs.equipment. Use word-boundary keyword matching per equipment type, and always reject oven, air fryer, grill, and blender |
| V7 | Every base core ingredient appears as owned, sub, or buy, so nothing is silently dropped |
| V8 | TIME parses to an integer from 1 to 180 |

Over budget is a flag, not an error. Cost is always computed in code from prices.json, never taken from the model.

Flow, emitting events Started, Token, Parsed, Retrying, FellBack, Failed:

1. Build the prompt, stream tokens, parse, validate.
2. On validation errors, retry once with a line appended to the user message: Previous attempt had these problems: followed by the error list.
3. If the second attempt fails, the engine throws, or the hard timeout (llm.timeoutSeconds) passes, emit FellBack and return the unmodified base recipe with kind fallbackBase. The UI must label it as not adapted by the model.
4. Leaving the detail screen calls engine.cancel().

Streaming UI: show the raw lines as they arrive in a styled preview with a live token count, then replace the preview with the formatted recipe when parsing and validation pass.

### 17.9 App structure and state

Routes: / (home), /scan, /review, /results, /recipe/:id.

Providers: modelStatusProvider, preferencesProvider (persisted), scanControllerProvider, ownedIngredientsProvider, resultsProvider (calls retrieve), adaptationProvider (family keyed by recipe id).

Scan lifecycle: idle, initializing, scanning, error. Pause the camera when the app is backgrounded and dispose it when leaving the screen. Handle permission denied with a screen that offers the photo fallback.

Results screen shows the retrieved base recipes immediately, each labeled Base. Opening one starts adaptation on the detail screen, so only one generation runs at a time.

A persistent OnDeviceBadge shows Vision and LLM status: Setup required, Loading, Ready, or MOCK. UI is Material 3 with large type, high contrast, and 48dp minimum touch targets so it reads on a projector or screen mirror.

Required error states: camera permission denied, model file missing, model failed to load, nothing detected, no recipe matches the equipment, generation timed out, and fell back to the base recipe.

### 17.10 Configuration

assets/config/app\_config.json holds every tunable. The values are starting points to be tuned on the real phone:

```json
{
  "scan": {"intervalMs": 700, "windowSize": 10, "minHits": 3,
           "minConfidence": 0.6, "photoMinConfidence": 0.3, "topK": 3},
  "retrieval": {"limit": 3, "minOwnedCoreRatio": 0.5},
  "llm": {"temperature": 0.3, "topP": 0.9, "maxTokens": 400,
          "contextSize": 2048, "timeoutSeconds": 60, "maxRetries": 1},
  "budgetPresets": [0, 30, 50, 100],
  "defaultBudget": 30
}
```

### 17.11 Model files and setup

- The vision model, labels.txt, and model\_config.json are small and ship inside assets/models/.
- The LLM file (a quantized GGUF, typically a Q4 variant of a 1B to 3B instruct model) is large and is not bundled. Side-load it with tool/push\_models.sh using adb push into the app's external files directory, models subfolder, which ModelStore resolves with path\_provider.
- ModelStore reports missing, present, loading, ready, or failed with a reason. Check that the file exists and is larger than zero bytes, and verify a SHA-256 when one is given in config.
- Before the team commits to any model, confirm its license allows distribution inside an app.
- Use a placeholder applicationId (com.example.snapfood) until the team chooses one.

### 17.12 Offline and privacy verification

- The main AndroidManifest.xml declares no INTERNET permission. Flutter adds it to debug builds for tooling, so the demo uses a release build.
- After building the release APK, run aapt dump permissions on it and confirm android.permission.INTERNET is absent. If a plugin merges it in, remove it with tools:node=remove in the main manifest, then confirm every feature still works.
- A unit test reads pubspec.yaml and fails if a denylisted package appears.
- tool/check\_offline.md is a manual checklist: airplane mode on, run the full flow five times, record pass or fail for each.
- Live proof in the demo is airplane mode. The aapt output and the app's mobile data usage screen are supporting evidence.

### 17.13 Tasks for the agent, in order

| Task | Deliverable | Done when |
| --- | --- | --- |
| T0 | Scaffold: app, packages, folder layout, theme, router with placeholder screens, OnDeviceBadge | App runs, analyze clean |
| T1 | Domain models, asset loaders, SAMPLE data (3 recipes, 8 ingredients), validate\_data tool | Loader and validator tests pass |
| T2 | Retrieval with its tests | All cases in 17.7 pass |
| T3 | Accumulator with tests | Flicker case, threshold case, and reset case pass |
| T4 | Prompt builder, parser, validators V1 to V8 | Tests cover valid output and malformed output for every rule |
| T5 | ModelStore and Setup Required UI | Missing file shows the right state, present file reaches Ready |
| T6 | IngredientDetector interface, MockDetector, TfliteClassifierDetector, photo fallback | Real detector runs a bundled test image and returns labeled predictions |
| T7 | LlmEngine interface, MockLlmEngine, real binding implementation | Real engine streams tokens from a side-loaded model on the phone |
| T8 | Debug-only Bench screen | Shows and logs detector latency (median and 95th percentile) and frames per second, plus LLM first-token time, total time, and tokens per second, with the device model name |
| T9 | Live scan screen with throttling and isolate | Preview stays smooth, chips accumulate while panning |
| T10 | AdaptationService with retry, timeout, fallback, then all screens wired end to end | Full flow works with mocks and with real models |
| T11 | Offline hardening: manifest, denylist test, README run steps | Release APK has no INTERNET permission, offline checklist passes |

Run T8 as early as the real models exist. The go/no-go gates in section 13 depend on its numbers.

### 17.14 Acceptance tests

| ID | Scenario | Expected |
| --- | --- | --- |
| A1 | Sweep three known ingredients in good light | All three appear as chips within 10 seconds |
| A2 | Remove a wrong chip, add a missing one | List updates, results use the corrected list |
| A3 | Choose rice cooker only, 30 pesos | Every returned recipe lists rice cooker in its equipment |
| A4 | Generate with the real model, airplane mode on | Adapted recipe passes V1 to V8, or the labeled fallback appears |
| A5 | Model returns an ingredient the user does not own as owned | Validation rejects it, one retry happens, then fallback if it repeats |
| A6 | Kill the LLM file | Setup Required state, no crash, base recipes still viewable |
| A7 | Deny camera permission | Photo fallback is offered |
| A8 | Nothing detected | Manual entry is offered, no invented chips |
| A9 | Release build permission dump | No INTERNET permission |
| A10 | Mock enabled in a release build | Not possible. The mock selector is absent |

### 17.15 What the team supplies, which the agent cannot

- Ingredient photos and the trained classifier (run ml/train\_classifier.py, then copy the outputs into assets/models/).
- Recipes, equipment safety checks, and the price table.
- The LLM file, side-loaded onto the phone.
- Benchmark runs on the actual phone and the go/no-go decisions in section 13.

Until these exist, the agent builds against mocks and SAMPLE data, labeled as such, and keeps the real implementations behind the same interfaces.
