# SnapFood

Offline-first Flutter prototype for Filipino dorm cooking. All included recipe, ingredient, and price data is **SAMPLE**. The scanner is a **MOCK** flow and there are no real on-device models yet; see [docs/DECISIONS.md](docs/DECISIONS.md).

## Run

Install Flutter stable with Dart 3 and an Android toolchain. The native Android runner is not generated in this workspace yet. From the project root, generate it once (keep the existing `lib/main.dart` if Flutter asks about replacing files), then run:

```sh
flutter create --platforms=android --project-name=snapfood .
flutter pub get
flutter run
```

The demo flow lets you add sample detections or search ingredients manually, choose equipment and a budget, browse matching recipes, and view a clearly labeled fallback base recipe. No network or account is used by the app.

## Before a real demo

Supply team-checked recipes, prices and equipment safety tags, a licensed trained ingredient model and labels, and a compatible side-loaded local language model. Implement and benchmark the camera and model interfaces on the target phone, then complete the offline release checks in the PRD. Do not claim live detection or model adaptation from this prototype.
