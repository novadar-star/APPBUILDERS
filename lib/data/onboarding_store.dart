import 'package:shared_preferences/shared_preferences.dart';

/// Persists whether the user has completed onboarding.
/// Uses [SharedPreferences] — same backend as [PreferencesStore].
class OnboardingStore {
  static const _doneKey = 'onboarding_done';

  Future<bool> isDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_doneKey) ?? false;
  }

  Future<void> markDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_doneKey, true);
  }

  /// Resets onboarding so it shows again on next launch.
  /// Called from "Replay intro" in settings.
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_doneKey);
  }
}
