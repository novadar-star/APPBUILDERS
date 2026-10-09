/// Nova's five emotional states plus the app events that drive them.
/// Screens never call setState directly — they fire an [AppEvent] and the
/// [novaStateProvider] maps it to the right [NovaState].
enum NovaState { idle, thinking, happy, error, celebrating }

/// Every meaningful app moment that Nova can react to.
enum AppEvent {
  appLaunch,
  scanStarted,
  photoTaken,
  recognitionSuccess,
  recipeLoaded,
  recognitionFailed,
  noNetwork,
  permissionDenied,
  recipeSaved,
  onboardingDone,
  selectionConfirmed,
  loading,
  // stretch goal:
  inactiveCamera60s,
}
