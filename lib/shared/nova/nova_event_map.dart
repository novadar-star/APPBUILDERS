import 'package:snapfood/shared/nova/nova_state.dart';

/// Canonical mapping from every [AppEvent] to its [NovaState].
/// Change Nova's reaction to an app moment here — nowhere else.
const Map<AppEvent, NovaState> kNovaEventMap = {
  AppEvent.appLaunch: NovaState.idle,
  AppEvent.scanStarted: NovaState.idle,
  AppEvent.photoTaken: NovaState.thinking,
  AppEvent.recognitionSuccess: NovaState.happy,
  AppEvent.recipeLoaded: NovaState.happy,
  AppEvent.recognitionFailed: NovaState.error,
  AppEvent.noNetwork: NovaState.error,
  AppEvent.permissionDenied: NovaState.error,
  AppEvent.recipeSaved: NovaState.celebrating,
  AppEvent.onboardingDone: NovaState.celebrating,
  AppEvent.selectionConfirmed: NovaState.happy,
  AppEvent.loading: NovaState.thinking,
  AppEvent.inactiveCamera60s: NovaState.idle, // sleepy state — stretch goal
};

/// Resolves an [AppEvent] to the [NovaState] it should produce.
NovaState novaStateForEvent(AppEvent event) =>
    kNovaEventMap[event] ?? NovaState.idle;
