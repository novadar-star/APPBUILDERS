# Offline demo checklist

Not verified: this scaffold has not been run on a phone. Once the real model bindings are integrated:

- [ ] Build a release APK and inspect its merged manifest; confirm `android.permission.INTERNET` is absent.
- [ ] Turn on airplane mode before launching the app.
- [ ] Complete scan, ingredient correction, equipment and budget selection, recipe results, and recipe detail five times.
- [ ] Record each pass/fail and device model. Do not count MOCK simulation as on-device vision or language-model inference.
- [ ] Confirm no analytics, crash reporting, or other network dependency is present.
